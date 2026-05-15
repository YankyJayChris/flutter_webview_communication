// Copyright (c) 2025 IGIHOZO Jean Christian. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.
// SPDX-License-Identifier: MIT

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';

// Conditional imports for platform-specific features
import 'package:webview_flutter_android/webview_flutter_android.dart'
    if (dart.library.io) 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'
    if (dart.library.io) 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// Callback for file download requests from the WebView.
///
/// [url] - The URL of the file to download.
/// [suggestedFilename] - The suggested filename from the server.
/// [mimeType] - The MIME type of the file.
typedef OnFileDownload = void Function(
  String url,
  String suggestedFilename,
  String? mimeType,
);

/// Callback for file upload requests from the WebView.
///
/// [allowMultiple] - Whether multiple files can be selected.
/// [acceptTypes] - List of accepted MIME types or file extensions.
/// Returns a list of file paths selected by the user.
typedef OnFileUploadRequest = Future<List<String>> Function(
  bool allowMultiple,
  List<String>? acceptTypes,
);

/// Callback for download progress updates.
///
/// [received] - Number of bytes received so far.
/// [total] - Total number of bytes to download (-1 if unknown).
typedef OnDownloadProgress = void Function(int received, int total);

/// Helper class to store JavaScript channel parameters
class _JavaScriptChannelParams {
  final String name;
  final void Function(JavaScriptMessage) onMessageReceived;

  _JavaScriptChannelParams({
    required this.name,
    required this.onMessageReceived,
  });
}

/// A plugin for creating WebViews with bi-directional communication capabilities.
class WebViewPlugin {
  late WebViewController _controller;
  final Map<String, Function(Map<String, dynamic>)> _actionHandlers;
  final bool _enableCommunication;
  final Function(String)? _onJavaScriptError;
  String? _currentContent;
  bool _isCurrentContentUrl = false;
  String?
      _lastLoadedContent; // Track last loaded content to prevent unnecessary reloads
  final Map<String, _JavaScriptChannelParams> _customChannels = {};
  final List<String> _consoleMessages = [];
  List<String>? _allowedUrls;
  List<String>? _blockedUrls;
  bool Function(String)? _urlValidator;

  // File handling callbacks
  final OnFileDownload? _onFileDownload;
  final OnFileUploadRequest? _onFileUploadRequest;

  // Download tracking
  final Map<String, CancelToken> _activeDownloads = {};

  /// JavaScript code for communication between Flutter and WebView.
  static const String _communicationScript = '''
    function receiveFromFlutter(data) {
      try {
        if (typeof data === 'string') {
          data = JSON.parse(data);
        }
        const event = new CustomEvent('flutterData', { detail: data });
        window.dispatchEvent(event);
      } catch (e) {
        console.error('Error processing received data:', e);
      }
    }

    function sendToFlutter(action, payload) {
      if (window.FlutterBridge) {
        const data = { action: action, payload: payload || {} };
        window.FlutterBridge.postMessage(JSON.stringify(data));
      }
    }
  ''';

  /// Creates a WebViewPlugin instance.
  ///
  /// `actionHandlers` - A map of action names to their handler functions that process
  /// messages received from the WebView. The handler receives a JSON payload.
  /// `enableCommunication` - If true, enables injection of communication scripts for URLs
  /// and includes them in custom HTML (default: false for URLs, true for HTML).
  /// `onJavaScriptError` - Optional callback to handle JavaScript console errors.
  /// `onFileDownload` - Optional callback for handling file download requests.
  /// `onFileUploadRequest` - Optional callback for handling file upload requests.
  /// Throws `Exception` if the platform is not supported.
  WebViewPlugin({
    Map<String, Function(Map<String, dynamic>)?>? actionHandlers,
    bool enableCommunication = false,
    Function(String)? onJavaScriptError,
    OnFileDownload? onFileDownload,
    OnFileUploadRequest? onFileUploadRequest,
  })  : _actionHandlers = actionHandlers?.map(
              (key, value) => MapEntry(key, value ?? ((_) {})),
            ) ??
            {},
        _enableCommunication = enableCommunication,
        _onJavaScriptError = onJavaScriptError,
        _onFileDownload = onFileDownload,
        _onFileUploadRequest = onFileUploadRequest {
    _initializePlatform();
    _initializeController();
  }

  /// Builds and returns a WebView widget.
  ///
  /// [content] - The content to display: either an HTML string or a URL (required).
  /// [isUrl] - If true, treats [content] as a URL; if false, treats it as HTML (default: false).
  /// [cssContent] - Optional CSS styles to include in the head element (only applies if [isUrl] is false).
  /// [scriptContent] - Optional JavaScript code to include in the page (injected after load for URLs).
  /// [height] - Optional height of the WebView widget.
  /// [width] - Optional width of the WebView widget.
  /// [backgroundColor] - Optional background color for the WebView (not supported on macOS).
  /// [enableCommunication] - If specified, overrides the constructor's setting for injecting
  /// communication scripts (default: null, uses constructor's value).
  /// [userAgent] - Optional custom user agent string for the WebView.
  /// [csp] - Optional Content Security Policy for custom HTML.
  /// [onLoadingStateChanged] - Optional callback for loading state changes (started, progress, finished, error).
  Widget buildWebView({
    required String content,
    bool isUrl = false,
    String? cssContent,
    String? scriptContent,
    double? height,
    double? width,
    Color? backgroundColor,
    bool? enableCommunication,
    String? userAgent,
    String? csp,
    Function(String state, int? progress, String? error)? onLoadingStateChanged,
  }) {
    final bool shouldEnableCommunication =
        enableCommunication ?? _enableCommunication;

    // Build the final content string for comparison
    final String contentToLoad = isUrl
        ? content
        : _buildHtml(
            content,
            cssContent,
            scriptContent,
            enableCommunication: shouldEnableCommunication,
            csp: csp,
          );

    // Only load if content has changed
    if (_lastLoadedContent != contentToLoad) {
      debugPrint(
          'Loading new content (isUrl: $isUrl, length: ${contentToLoad.length})');
      _lastLoadedContent = contentToLoad;
      _currentContent = content;
      _isCurrentContentUrl = isUrl;

      // Update navigation delegate with loading callbacks
      _controller.setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            onLoadingStateChanged?.call('started', null, null);
            _onPageStarted?.call(url);
            if (url == _currentContent) {
              _injectJavaScript();
            }
          },
          onProgress: (int progress) {
            onLoadingStateChanged?.call('progress', progress, null);
            _onProgress?.call(progress);
          },
          onPageFinished: (String url) {
            onLoadingStateChanged?.call('finished', null, null);
            _onPageFinished?.call(url);
            if (url == _currentContent) {
              _injectJavaScript();
            }
          },
          onWebResourceError: (WebResourceError error) {
            onLoadingStateChanged?.call('error', null, error.description);
            _onError?.call(error.description);
          },
          onHttpError: (HttpResponseError error) {
            final errorMsg = 'HTTP ${error.toString()}';
            onLoadingStateChanged?.call('error', null, errorMsg);
            _onError?.call(errorMsg);
          },
          onNavigationRequest: (NavigationRequest request) {
            _onUrlChanged?.call(request.url);
            // Check URL restrictions
            if (!isUrlAllowed(request.url)) {
              debugPrint('Navigation blocked: ${request.url}');
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

      if (isUrl) {
        _loadUrlContent(content, scriptContent);
      } else {
        _loadHtmlContent(contentToLoad);
      }
    } else {
      debugPrint('Content unchanged, skipping reload');
    }

    if (backgroundColor != null) {
      if (kIsWeb || Platform.isWindows || Platform.isLinux) {
        // Use CSS for web and desktop platforms
        final r = (backgroundColor.r * 255.0).round() & 0xff;
        final g = (backgroundColor.g * 255.0).round() & 0xff;
        final b = (backgroundColor.b * 255.0).round() & 0xff;
        final a = backgroundColor.a;
        _controller.runJavaScript('''
          document.body.style.backgroundColor = 'rgba($r, $g, $b, $a)';
        ''');
      } else if (!Platform.isMacOS) {
        _controller.setBackgroundColor(backgroundColor);
      }
    }

    if (userAgent != null) {
      _controller.setUserAgent(userAgent);
    }

    return SizedBox(
      height: height ?? double.infinity,
      width: width ?? double.infinity,
      child: WebViewWidget(controller: _controller),
    );
  }

  /// Sends data to the WebView.
  ///
  /// [payload] - The data to send, which can be any JSON-serializable object.
  /// [action] - An optional action identifier to specify the type of message.
  Future<void> sendToWebView({
    required dynamic payload,
    String? action,
  }) async {
    try {
      final data = {
        'action': action,
        'payload': payload,
      };
      final String jsData = jsonEncode(data);
      await _controller.runJavaScript('receiveFromFlutter($jsData)');
    } catch (e) {
      debugPrint('Error sending data to WebView: $e');
      _onJavaScriptError?.call('Error sending data to WebView: $e');
    }
  }

  /// Saves a key-value pair to the WebView's local storage.
  ///
  /// [key] - The key under which to store the value.
  /// [value] - The value to store, which will be JSON-stringified.
  Future<void> saveToLocalStorage({
    required String key,
    required dynamic value,
  }) async {
    try {
      if (key.isEmpty) {
        throw ArgumentError('Key cannot be empty');
      }
      final String jsValue = jsonEncode(value);
      final String escapedKey = key.replaceAll('"', '\\"');

      // Check if localStorage is available before attempting to use it
      final String jsCode = '''
        (function() {
          try {
            if (typeof localStorage !== 'undefined') {
              localStorage.setItem("$escapedKey", $jsValue);
              return true;
            }
            return false;
          } catch (e) {
            return false;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      if (result == true) {
        debugPrint('Saved to localStorage: $escapedKey = $jsValue');
      } else {
        throw Exception('localStorage is not available or operation failed');
      }
    } catch (e) {
      debugPrint('Error saving to localStorage: key=$key, error=$e');
      // Don't call _onJavaScriptError here - let callers handle the error
      rethrow;
    }
  }

  /// Removes a key from the WebView's local storage.
  ///
  /// [key] - The key to remove from local storage.
  Future<void> removeFromLocalStorage({
    required String key,
  }) async {
    try {
      if (key.isEmpty) {
        throw ArgumentError('Key cannot be empty');
      }
      final String escapedKey = key.replaceAll('"', '\\"');

      // Check if localStorage is available before attempting to use it
      final String jsCode = '''
        (function() {
          try {
            if (typeof localStorage !== 'undefined') {
              localStorage.removeItem("$escapedKey");
              return true;
            }
            return false;
          } catch (e) {
            return false;
          }
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      if (result == true) {
        debugPrint('Removed from localStorage: $escapedKey');
      } else {
        throw Exception('localStorage is not available or operation failed');
      }
    } catch (e) {
      debugPrint('Error removing from localStorage: key=$key, error=$e');
      // Don't call _onJavaScriptError here - let callers handle the error
      rethrow;
    }
  }

  /// Retrieves all key-value pairs from the WebView's local storage.
  ///
  /// Returns a map of key-value pairs. Values are JSON-decoded where possible.
  Future<Map<String, dynamic>> getLocalStorage() async {
    try {
      const String jsCode = '''
        (function() {
          try {
            if (typeof localStorage === 'undefined') {
              return JSON.stringify({});
            }
            const items = {};
            for (let i = 0; i < localStorage.length; i++) {
              const key = localStorage.key(i);
              items[key] = localStorage.getItem(key);
            }
            return JSON.stringify(items);
          } catch (e) {
            return JSON.stringify({});
          }
        })();
      ''';
      final String? localStorageJson =
          (await _controller.runJavaScriptReturningResult(jsCode)) as String?;
      if (localStorageJson != null) {
        final Map<String, dynamic> rawData = jsonDecode(localStorageJson);
        final Map<String, dynamic> result = {};
        rawData.forEach((key, value) {
          try {
            result[key] = jsonDecode(value);
          } catch (_) {
            result[key] = value;
          }
        });
        debugPrint('Retrieved localStorage: $result');
        return result;
      }
      return {};
    } catch (e) {
      debugPrint('Error retrieving localStorage: $e');
      // Don't call _onJavaScriptError here - let callers handle the error
      rethrow;
    }
  }

  /// Clears all data (cookies, cache, and local storage) associated with the WebView.
  Future<void> clearWebViewData() async {
    try {
      await _controller.runJavaScript('localStorage.clear();');
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
      await _controller.clearCache();
      debugPrint('Cleared cookies, cache, and local storage for WebView');
    } catch (e) {
      debugPrint('Error clearing WebView data: $e');
      // Don't call _onJavaScriptError or rethrow - this is not critical
    }
  }

  /// Reloads the current WebView content.
  Future<void> reload() async {
    try {
      if (_currentContent != null) {
        if (_isCurrentContentUrl) {
          await _controller.loadRequest(Uri.parse(_currentContent!));
        } else {
          await _controller.loadHtmlString(_currentContent!);
        }
        debugPrint('Reloaded WebView content');
      } else {
        debugPrint('No content to reload');
      }
    } catch (e) {
      debugPrint('Error reloading WebView: $e');
      _onJavaScriptError?.call('Error reloading WebView: $e');
      rethrow;
    }
  }

  /// Retrieves the current scroll position of the WebView using JavaScript.
  ///
  /// Returns a map with 'x' and 'y' coordinates of the scroll position.
  Future<Map<String, double>> getScrollPosition() async {
    try {
      const String jsCode = '''
        JSON.stringify({
          x: window.scrollX || window.pageXOffset || 0,
          y: window.scrollY || window.pageYOffset || 0
        });
      ''';
      final String? result =
          (await _controller.runJavaScriptReturningResult(jsCode)) as String?;
      if (result != null) {
        final Map<String, dynamic> position = jsonDecode(result);
        debugPrint('Scroll position: x=${position['x']}, y=${position['y']}');
        return {'x': position['x'].toDouble(), 'y': position['y'].toDouble()};
      }
      return {'x': 0.0, 'y': 0.0};
    } catch (e) {
      debugPrint('Error retrieving scroll position: $e');
      _onJavaScriptError?.call('Error retrieving scroll position: $e');
      rethrow;
    }
  }

  /// Disposes of the WebViewPlugin and cleans up resources.
  ///
  /// This method should be called when the WebView is no longer needed
  /// to prevent memory leaks and free up resources.
  void dispose() {
    try {
      // Clear any cached data
      _controller.clearCache();
      // Clear custom script reference
      _customScript = null;
      // Clear current content reference
      _currentContent = null;
      _lastLoadedContent = null;
      debugPrint('WebViewPlugin disposed successfully');
    } catch (e) {
      debugPrint('Error disposing WebViewPlugin: $e');
      // Don't call _onJavaScriptError during disposal
    }
  }

  // ============================================================================
  // NAVIGATION CONTROLS
  // ============================================================================

  /// Navigates back in the WebView history.
  ///
  /// Returns true if navigation was successful, false if there's no history to go back to.
  Future<bool> goBack() async {
    try {
      if (await _controller.canGoBack()) {
        await _controller.goBack();
        debugPrint('Navigated back in WebView history');
        return true;
      }
      debugPrint('Cannot go back - no history available');
      return false;
    } catch (e) {
      debugPrint('Error navigating back: $e');
      _onJavaScriptError?.call('Error navigating back: $e');
      rethrow;
    }
  }

  /// Navigates forward in the WebView history.
  ///
  /// Returns true if navigation was successful, false if there's no forward history.
  Future<bool> goForward() async {
    try {
      if (await _controller.canGoForward()) {
        await _controller.goForward();
        debugPrint('Navigated forward in WebView history');
        return true;
      }
      debugPrint('Cannot go forward - no forward history available');
      return false;
    } catch (e) {
      debugPrint('Error navigating forward: $e');
      _onJavaScriptError?.call('Error navigating forward: $e');
      rethrow;
    }
  }

  /// Checks if the WebView can navigate back in history.
  ///
  /// Returns true if there is history to go back to, false otherwise.
  Future<bool> canGoBack() async {
    try {
      return await _controller.canGoBack();
    } catch (e) {
      debugPrint('Error checking canGoBack: $e');
      _onJavaScriptError?.call('Error checking canGoBack: $e');
      return false;
    }
  }

  /// Checks if the WebView can navigate forward in history.
  ///
  /// Returns true if there is forward history, false otherwise.
  Future<bool> canGoForward() async {
    try {
      return await _controller.canGoForward();
    } catch (e) {
      debugPrint('Error checking canGoForward: $e');
      _onJavaScriptError?.call('Error checking canGoForward: $e');
      return false;
    }
  }

  /// Gets the current URL of the WebView.
  ///
  /// Returns the current URL as a string, or null if unavailable.
  Future<String?> getCurrentUrl() async {
    try {
      final url = await _controller.currentUrl();
      debugPrint('Current URL: $url');
      return url;
    } catch (e) {
      debugPrint('Error getting current URL: $e');
      _onJavaScriptError?.call('Error getting current URL: $e');
      return null;
    }
  }

  /// Gets the title of the current page in the WebView.
  ///
  /// Returns the page title as a string, or null if unavailable.
  Future<String?> getTitle() async {
    try {
      final title = await _controller.getTitle();
      debugPrint('Page title: $title');
      return title;
    } catch (e) {
      debugPrint('Error getting page title: $e');
      _onJavaScriptError?.call('Error getting page title: $e');
      return null;
    }
  }

  /// Stops the current page load.
  Future<void> stopLoading() async {
    try {
      // Note: webview_flutter doesn't have a direct stopLoading method
      // We can implement this by loading about:blank or using platform-specific code
      await _controller.loadRequest(Uri.parse('about:blank'));
      debugPrint('Stopped loading current page');
    } catch (e) {
      debugPrint('Error stopping page load: $e');
      _onJavaScriptError?.call('Error stopping page load: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ZOOM CONTROLS
  // ============================================================================

  /// Enables or disables zoom functionality in the WebView.
  ///
  /// [enabled] - If true, enables zoom; if false, disables zoom.
  /// Note: This uses JavaScript to control zoom behavior.
  Future<void> setZoomEnabled(bool enabled) async {
    try {
      final String jsCode = '''
        var meta = document.querySelector('meta[name="viewport"]');
        if (!meta) {
          meta = document.createElement('meta');
          meta.name = 'viewport';
          document.head.appendChild(meta);
        }
        meta.content = 'width=device-width, initial-scale=1.0, ${enabled ? 'user-scalable=yes' : 'user-scalable=no, maximum-scale=1.0, minimum-scale=1.0'}';
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Zoom ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting zoom enabled: $e');
      _onJavaScriptError?.call('Error setting zoom enabled: $e');
      rethrow;
    }
  }

  /// Zooms in on the WebView content.
  ///
  /// Increases the zoom level by 20%.
  Future<void> zoomIn() async {
    try {
      final currentZoom = await getZoomLevel();
      await setZoomLevel(currentZoom + 0.2);
      debugPrint('Zoomed in to ${currentZoom + 0.2}');
    } catch (e) {
      debugPrint('Error zooming in: $e');
      _onJavaScriptError?.call('Error zooming in: $e');
      rethrow;
    }
  }

  /// Zooms out on the WebView content.
  ///
  /// Decreases the zoom level by 20%, with a minimum of 0.5.
  Future<void> zoomOut() async {
    try {
      final currentZoom = await getZoomLevel();
      final newZoom = (currentZoom - 0.2).clamp(0.5, 5.0);
      await setZoomLevel(newZoom);
      debugPrint('Zoomed out to $newZoom');
    } catch (e) {
      debugPrint('Error zooming out: $e');
      _onJavaScriptError?.call('Error zooming out: $e');
      rethrow;
    }
  }

  /// Sets the zoom level of the WebView.
  ///
  /// [level] - The zoom level (1.0 = 100%, 2.0 = 200%, etc.)
  /// Valid range is 0.5 to 5.0.
  Future<void> setZoomLevel(double level) async {
    try {
      final clampedLevel = level.clamp(0.5, 5.0);
      final String jsCode = '''
        document.body.style.zoom = '$clampedLevel';
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Set zoom level to $clampedLevel');
    } catch (e) {
      debugPrint('Error setting zoom level: $e');
      _onJavaScriptError?.call('Error setting zoom level: $e');
      rethrow;
    }
  }

  /// Gets the current zoom level of the WebView.
  ///
  /// Returns the current zoom level (1.0 = 100%).
  Future<double> getZoomLevel() async {
    try {
      const String jsCode = '''
        (function() {
          var zoom = document.body.style.zoom || '1';
          return parseFloat(zoom);
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final zoomLevel = double.tryParse(result.toString()) ?? 1.0;
      debugPrint('Current zoom level: $zoomLevel');
      return zoomLevel;
    } catch (e) {
      debugPrint('Error getting zoom level: $e');
      _onJavaScriptError?.call('Error getting zoom level: $e');
      return 1.0;
    }
  }

  // ============================================================================
  // ENHANCED COOKIE MANAGEMENT
  // ============================================================================

  /// Gets a specific cookie value by name for a given URL.
  ///
  /// [name] - The name of the cookie to retrieve.
  /// [url] - The URL associated with the cookie.
  /// Returns the cookie value as a string, or null if not found.
  Future<String?> getCookie(String name, String url) async {
    try {
      // Note: webview_flutter doesn't provide a direct way to get a specific cookie
      // We'll use JavaScript to retrieve it
      final String jsCode = '''
        (function() {
          var cookies = document.cookie.split(';');
          for (var i = 0; i < cookies.length; i++) {
            var cookie = cookies[i].trim();
            if (cookie.startsWith('$name=')) {
              return cookie.substring('$name='.length);
            }
          }
          return null;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      debugPrint('Retrieved cookie $name: $result');
      return result.toString();
    } catch (e) {
      debugPrint('Error getting cookie: $e');
      _onJavaScriptError?.call('Error getting cookie: $e');
      return null;
    }
  }

  /// Sets a cookie for the WebView.
  ///
  /// [name] - The name of the cookie.
  /// [value] - The value of the cookie.
  /// [domain] - The domain for the cookie.
  /// [path] - The path for the cookie (default: '/').
  /// [expiresDate] - Optional expiration date for the cookie.
  Future<void> setCookie({
    required String name,
    required String value,
    required String domain,
    String path = '/',
    DateTime? expiresDate,
  }) async {
    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.setCookie(
        WebViewCookie(
          name: name,
          value: value,
          domain: domain,
          path: path,
        ),
      );
      debugPrint('Set cookie: $name=$value for domain $domain');
    } catch (e) {
      debugPrint('Error setting cookie: $e');
      _onJavaScriptError?.call('Error setting cookie: $e');
      rethrow;
    }
  }

  /// Checks if the WebView has any cookies.
  ///
  /// Returns true if cookies exist, false otherwise.
  Future<bool> hasCookies() async {
    try {
      const String jsCode = '''
        (function() {
          return document.cookie.length > 0;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final hasCookies = result.toString().toLowerCase() == 'true';
      debugPrint('Has cookies: $hasCookies');
      return hasCookies;
    } catch (e) {
      debugPrint('Error checking for cookies: $e');
      _onJavaScriptError?.call('Error checking for cookies: $e');
      return false;
    }
  }

  /// Gets all cookies as a map.
  ///
  /// Returns a map of cookie names to values.
  Future<Map<String, String>> getAllCookies() async {
    try {
      const String jsCode = '''
        (function() {
          var cookies = {};
          document.cookie.split(';').forEach(function(cookie) {
            var parts = cookie.trim().split('=');
            if (parts.length === 2) {
              cookies[parts[0]] = parts[1];
            }
          });
          return JSON.stringify(cookies);
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final Map<String, dynamic> cookiesJson = jsonDecode(result.toString());
      final Map<String, String> cookies = cookiesJson.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      debugPrint('Retrieved all cookies: $cookies');
      return cookies;
    } catch (e) {
      debugPrint('Error getting all cookies: $e');
      _onJavaScriptError?.call('Error getting all cookies: $e');
      return {};
    }
  }

  // ============================================================================
  // SCROLL CONTROLS
  // ============================================================================

  /// Scrolls the WebView to a specific position.
  ///
  /// [x] - The horizontal scroll position in pixels.
  /// [y] - The vertical scroll position in pixels.
  /// [smooth] - If true, uses smooth scrolling animation.
  Future<void> scrollTo(double x, double y, {bool smooth = false}) async {
    try {
      final String behavior = smooth ? 'smooth' : 'auto';
      final String jsCode = '''
        window.scrollTo({
          left: $x,
          top: $y,
          behavior: '$behavior'
        });
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Scrolled to position: x=$x, y=$y');
    } catch (e) {
      debugPrint('Error scrolling to position: $e');
      _onJavaScriptError?.call('Error scrolling to position: $e');
      rethrow;
    }
  }

  /// Scrolls the WebView by a specific offset.
  ///
  /// [x] - The horizontal scroll offset in pixels.
  /// [y] - The vertical scroll offset in pixels.
  /// [smooth] - If true, uses smooth scrolling animation.
  Future<void> scrollBy(double x, double y, {bool smooth = false}) async {
    try {
      final String behavior = smooth ? 'smooth' : 'auto';
      final String jsCode = '''
        window.scrollBy({
          left: $x,
          top: $y,
          behavior: '$behavior'
        });
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Scrolled by offset: x=$x, y=$y');
    } catch (e) {
      debugPrint('Error scrolling by offset: $e');
      _onJavaScriptError?.call('Error scrolling by offset: $e');
      rethrow;
    }
  }

  /// Scrolls to the top of the page.
  ///
  /// [smooth] - If true, uses smooth scrolling animation.
  Future<void> scrollToTop({bool smooth = true}) async {
    await scrollTo(0, 0, smooth: smooth);
  }

  /// Scrolls to the bottom of the page.
  ///
  /// [smooth] - If true, uses smooth scrolling animation.
  Future<void> scrollToBottom({bool smooth = true}) async {
    try {
      final String behavior = smooth ? 'smooth' : 'auto';
      final String jsCode = '''
        window.scrollTo({
          left: 0,
          top: document.body.scrollHeight,
          behavior: '$behavior'
        });
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Scrolled to bottom of page');
    } catch (e) {
      debugPrint('Error scrolling to bottom: $e');
      _onJavaScriptError?.call('Error scrolling to bottom: $e');
      rethrow;
    }
  }

  // ============================================================================
  // FIND IN PAGE
  // ============================================================================

  int _currentFindIndex = 0;
  int _totalFindMatches = 0;

  /// Finds all occurrences of the search text in the page.
  ///
  /// [searchText] - The text to search for.
  /// [caseSensitive] - If true, performs case-sensitive search.
  /// Returns the number of matches found.
  Future<int> findInPage(String searchText,
      {bool caseSensitive = false}) async {
    try {
      // Escape special characters for JavaScript string and regex
      final escapedText = searchText
          .replaceAll('\\', '\\\\')
          .replaceAll("'", "\\'")
          .replaceAll('"', '\\"')
          .replaceAll('\n', '\\n')
          .replaceAll('\r', '\\r');

      // Escape regex special characters
      final regexEscaped = escapedText
          .replaceAll(r'$', r'\$')
          .replaceAll(r'^', r'\^')
          .replaceAll(r'*', r'\*')
          .replaceAll(r'+', r'\+')
          .replaceAll(r'?', r'\?')
          .replaceAll(r'.', r'\.')
          .replaceAll(r'(', r'\(')
          .replaceAll(r')', r'\)')
          .replaceAll(r'[', r'\[')
          .replaceAll(r']', r'\]')
          .replaceAll(r'{', r'\{')
          .replaceAll(r'}', r'\}')
          .replaceAll(r'|', r'\|');

      final String jsCode = '''
        (function() {
          try {
            // Remove previous highlights
            var oldHighlights = document.querySelectorAll('.webview-find-highlight');
            oldHighlights.forEach(function(el) {
              var parent = el.parentNode;
              if (parent) {
                parent.replaceChild(document.createTextNode(el.textContent), el);
                parent.normalize();
              }
            });
            
            if ('$escapedText' === '') return 0;
            
            var searchText = '$regexEscaped';
            var flags = '${caseSensitive ? 'g' : 'gi'}';
            var regex = new RegExp(searchText, flags);
            var count = 0;
            
            // Use TreeWalker to find text nodes
            var walker = document.createTreeWalker(
              document.body,
              NodeFilter.SHOW_TEXT,
              null,
              false
            );
            
            var nodesToProcess = [];
            var node;
            while (node = walker.nextNode()) {
              // Skip script and style elements
              if (node.parentElement && 
                  (node.parentElement.tagName === 'SCRIPT' || 
                   node.parentElement.tagName === 'STYLE')) {
                continue;
              }
              if (regex.test(node.textContent)) {
                nodesToProcess.push(node);
              }
            }
            
            // Process nodes
            nodesToProcess.forEach(function(textNode) {
              var text = textNode.textContent;
              var fragment = document.createDocumentFragment();
              var lastIndex = 0;
              var match;
              regex.lastIndex = 0; // Reset regex
              
              while ((match = regex.exec(text)) !== null) {
                count++;
                // Add text before match
                if (match.index > lastIndex) {
                  fragment.appendChild(document.createTextNode(text.substring(lastIndex, match.index)));
                }
                // Add highlighted match
                var span = document.createElement('span');
                span.className = 'webview-find-highlight';
                span.style.backgroundColor = 'yellow';
                span.style.color = 'black';
                span.textContent = match[0];
                fragment.appendChild(span);
                lastIndex = match.index + match[0].length;
              }
              
              // Add remaining text
              if (lastIndex < text.length) {
                fragment.appendChild(document.createTextNode(text.substring(lastIndex)));
              }
              
              if (fragment.childNodes.length > 0) {
                textNode.parentNode.replaceChild(fragment, textNode);
              }
            });
            
            // Highlight first match
            if (count > 0) {
              var firstHighlight = document.querySelector('.webview-find-highlight');
              if (firstHighlight) {
                firstHighlight.style.backgroundColor = 'orange';
                firstHighlight.scrollIntoView({behavior: 'smooth', block: 'center'});
              }
            }
            
            return count;
          } catch (e) {
            console.error('Find error:', e);
            return 0;
          }
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      debugPrint(
          'Find result from JavaScript: $result (type: ${result.runtimeType})');
      _totalFindMatches = int.tryParse(result.toString()) ?? 0;
      _currentFindIndex = _totalFindMatches > 0 ? 1 : 0;
      debugPrint('Found $_totalFindMatches matches for "$searchText"');
      return _totalFindMatches;
    } catch (e) {
      debugPrint('Error finding in page: $e');
      return 0;
    }
  }

  /// Navigates to the next match in the find results.
  Future<void> findNext() async {
    try {
      if (_totalFindMatches == 0) return;

      _currentFindIndex = (_currentFindIndex % _totalFindMatches) + 1;

      final String jsCode = '''
        (function() {
          var highlights = document.querySelectorAll('.webview-find-highlight');
          highlights.forEach(function(el, index) {
            el.style.backgroundColor = index === ${_currentFindIndex - 1} ? 'orange' : 'yellow';
          });
          if (highlights[${_currentFindIndex - 1}]) {
            highlights[${_currentFindIndex - 1}].scrollIntoView({behavior: 'smooth', block: 'center'});
          }
        })();
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Navigated to match $_currentFindIndex of $_totalFindMatches');
    } catch (e) {
      debugPrint('Error navigating to next match: $e');
      _onJavaScriptError?.call('Error navigating to next match: $e');
    }
  }

  /// Navigates to the previous match in the find results.
  Future<void> findPrevious() async {
    try {
      if (_totalFindMatches == 0) return;

      _currentFindIndex =
          _currentFindIndex <= 1 ? _totalFindMatches : _currentFindIndex - 1;

      final String jsCode = '''
        (function() {
          var highlights = document.querySelectorAll('.webview-find-highlight');
          highlights.forEach(function(el, index) {
            el.style.backgroundColor = index === ${_currentFindIndex - 1} ? 'orange' : 'yellow';
          });
          if (highlights[${_currentFindIndex - 1}]) {
            highlights[${_currentFindIndex - 1}].scrollIntoView({behavior: 'smooth', block: 'center'});
          }
        })();
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Navigated to match $_currentFindIndex of $_totalFindMatches');
    } catch (e) {
      debugPrint('Error navigating to previous match: $e');
      _onJavaScriptError?.call('Error navigating to previous match: $e');
    }
  }

  /// Clears all find-in-page highlights.
  Future<void> clearFindMatches() async {
    try {
      const String jsCode = '''
        (function() {
          var highlights = document.querySelectorAll('.webview-find-highlight');
          highlights.forEach(function(el) {
            var parent = el.parentNode;
            parent.replaceChild(document.createTextNode(el.textContent), el);
            parent.normalize();
          });
        })();
      ''';
      await _controller.runJavaScript(jsCode);
      _currentFindIndex = 0;
      _totalFindMatches = 0;
      debugPrint('Cleared all find matches');
    } catch (e) {
      debugPrint('Error clearing find matches: $e');
      _onJavaScriptError?.call('Error clearing find matches: $e');
    }
  }

  /// Gets the current find match information.
  ///
  /// Returns a map with 'currentMatch' and 'totalMatches' counts.
  Map<String, int> getFindMatchInfo() {
    return {
      'currentMatch': _currentFindIndex,
      'totalMatches': _totalFindMatches,
    };
  }

  // ============================================================================
  // JAVASCRIPT CHANNEL MANAGEMENT
  // ============================================================================

  /// Adds a custom JavaScript channel to the WebView.
  ///
  /// [name] - The name of the channel (must be unique).
  /// [onMessageReceived] - Callback function when messages are received.
  ///
  /// The channel can be called from JavaScript using:
  /// ```javascript
  /// window.channelName.postMessage('your message');
  /// ```
  void addJavaScriptChannel(
    String name,
    void Function(JavaScriptMessage) onMessageReceived,
  ) {
    try {
      if (_customChannels.containsKey(name)) {
        debugPrint('JavaScript channel "$name" already exists, replacing...');
      }

      _controller.addJavaScriptChannel(
        name,
        onMessageReceived: onMessageReceived,
      );

      _customChannels[name] = _JavaScriptChannelParams(
        name: name,
        onMessageReceived: onMessageReceived,
      );

      debugPrint('Added JavaScript channel: $name');
    } catch (e) {
      debugPrint('Error adding JavaScript channel: $e');
      _onJavaScriptError?.call('Error adding JavaScript channel: $e');
      rethrow;
    }
  }

  /// Removes a custom JavaScript channel from the WebView.
  ///
  /// [name] - The name of the channel to remove.
  /// Returns true if the channel was removed, false if it didn't exist.
  bool removeJavaScriptChannel(String name) {
    try {
      if (!_customChannels.containsKey(name)) {
        debugPrint('JavaScript channel "$name" does not exist');
        return false;
      }

      _controller.removeJavaScriptChannel(name);
      _customChannels.remove(name);

      debugPrint('Removed JavaScript channel: $name');
      return true;
    } catch (e) {
      debugPrint('Error removing JavaScript channel: $e');
      _onJavaScriptError?.call('Error removing JavaScript channel: $e');
      return false;
    }
  }

  /// Lists all registered JavaScript channels.
  ///
  /// Returns a list of channel names.
  List<String> listJavaScriptChannels() {
    return _customChannels.keys.toList();
  }

  /// Checks if a JavaScript channel exists.
  ///
  /// [name] - The name of the channel to check.
  /// Returns true if the channel exists, false otherwise.
  bool hasJavaScriptChannel(String name) {
    return _customChannels.containsKey(name);
  }

  // ============================================================================
  // CONSOLE MESSAGE CAPTURE & DEBUGGING
  // ============================================================================

  /// Enables console message capture from the WebView.
  ///
  /// This sets up a JavaScript channel to capture console.log, console.error, etc.
  void enableConsoleCapture() {
    try {
      // Add a channel to capture console messages
      addJavaScriptChannel('ConsoleCapture', (JavaScriptMessage message) {
        _consoleMessages.add(message.message);
        debugPrint('[WebView Console] ${message.message}');
      });

      // Inject JavaScript to override console methods
      const String consoleOverrideScript = '''
        (function() {
          var originalLog = console.log;
          var originalError = console.error;
          var originalWarn = console.warn;
          var originalInfo = console.info;
          
          console.log = function() {
            var message = Array.prototype.slice.call(arguments).join(' ');
            if (window.ConsoleCapture) {
              window.ConsoleCapture.postMessage('LOG: ' + message);
            }
            originalLog.apply(console, arguments);
          };
          
          console.error = function() {
            var message = Array.prototype.slice.call(arguments).join(' ');
            if (window.ConsoleCapture) {
              window.ConsoleCapture.postMessage('ERROR: ' + message);
            }
            originalError.apply(console, arguments);
          };
          
          console.warn = function() {
            var message = Array.prototype.slice.call(arguments).join(' ');
            if (window.ConsoleCapture) {
              window.ConsoleCapture.postMessage('WARN: ' + message);
            }
            originalWarn.apply(console, arguments);
          };
          
          console.info = function() {
            var message = Array.prototype.slice.call(arguments).join(' ');
            if (window.ConsoleCapture) {
              window.ConsoleCapture.postMessage('INFO: ' + message);
            }
            originalInfo.apply(console, arguments);
          };
        })();
      ''';

      _controller.runJavaScript(consoleOverrideScript);
      debugPrint('Console capture enabled');
    } catch (e) {
      debugPrint('Error enabling console capture: $e');
      _onJavaScriptError?.call('Error enabling console capture: $e');
    }
  }

  /// Gets all captured console messages.
  ///
  /// Returns a list of console messages.
  List<String> getConsoleMessages() {
    return List.unmodifiable(_consoleMessages);
  }

  /// Clears all captured console messages.
  void clearConsoleMessages() {
    _consoleMessages.clear();
    debugPrint('Console messages cleared');
  }

  // ============================================================================
  // PAGE METADATA & INFORMATION
  // ============================================================================

  /// Gets comprehensive page metadata.
  ///
  /// Returns a map containing url, title, description, keywords, author, viewport, charset.
  Future<Map<String, String?>> getPageMetadata() async {
    try {
      const String jsCode = '''
        (function() {
          var metadata = {
            url: window.location.href,
            title: document.title,
            description: '',
            keywords: '',
            author: '',
            viewport: '',
            charset: document.characterSet || document.charset
          };
          
          var metas = document.getElementsByTagName('meta');
          for (var i = 0; i < metas.length; i++) {
            var name = metas[i].getAttribute('name') || metas[i].getAttribute('property');
            var content = metas[i].getAttribute('content');
            
            if (name === 'description') metadata.description = content;
            if (name === 'keywords') metadata.keywords = content;
            if (name === 'author') metadata.author = content;
            if (name === 'viewport') metadata.viewport = content;
          }
          
          return JSON.stringify(metadata);
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final Map<String, dynamic> metadata = jsonDecode(result.toString());

      return metadata.map((key, value) => MapEntry(key, value?.toString()));
    } catch (e) {
      debugPrint('Error getting page metadata: $e');
      _onJavaScriptError?.call('Error getting page metadata: $e');
      return {};
    }
  }

  /// Gets all links on the current page.
  ///
  /// Returns a list of maps containing 'href' and 'text' for each link.
  Future<List<Map<String, String>>> getPageLinks() async {
    try {
      const String jsCode = '''
        (function() {
          var links = [];
          var anchors = document.getElementsByTagName('a');
          
          for (var i = 0; i < anchors.length; i++) {
            links.push({
              href: anchors[i].href || '',
              text: anchors[i].textContent || anchors[i].innerText || ''
            });
          }
          
          return JSON.stringify(links);
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final List<dynamic> linksJson = jsonDecode(result.toString());

      return linksJson
          .map((link) => {
                'href': link['href']?.toString() ?? '',
                'text': link['text']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting page links: $e');
      _onJavaScriptError?.call('Error getting page links: $e');
      return [];
    }
  }

  /// Gets all images on the current page.
  ///
  /// Returns a list of maps containing 'src', 'alt', 'width', and 'height' for each image.
  Future<List<Map<String, String>>> getPageImages() async {
    try {
      const String jsCode = '''
        (function() {
          var images = [];
          var imgs = document.getElementsByTagName('img');
          
          for (var i = 0; i < imgs.length; i++) {
            images.push({
              src: imgs[i].src || '',
              alt: imgs[i].alt || '',
              width: imgs[i].width.toString(),
              height: imgs[i].height.toString()
            });
          }
          
          return JSON.stringify(images);
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final List<dynamic> imagesJson = jsonDecode(result.toString());

      return imagesJson
          .map((img) => {
                'src': img['src']?.toString() ?? '',
                'alt': img['alt']?.toString() ?? '',
                'width': img['width']?.toString() ?? '',
                'height': img['height']?.toString() ?? '',
              })
          .toList();
    } catch (e) {
      debugPrint('Error getting page images: $e');
      _onJavaScriptError?.call('Error getting page images: $e');
      return [];
    }
  }

  /// Gets the page's HTML content.
  ///
  /// `includeHead` - If true, includes the head section.
  /// Returns the HTML content as a string.
  Future<String> getPageHtml({bool includeHead = false}) async {
    try {
      final String jsCode = includeHead
          ? 'document.documentElement.outerHTML;'
          : 'document.body.innerHTML;';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      return result.toString();
    } catch (e) {
      debugPrint('Error getting page HTML: $e');
      _onJavaScriptError?.call('Error getting page HTML: $e');
      return '';
    }
  }

  /// Gets the page's text content (without HTML tags).
  ///
  /// Returns the text content as a string.
  Future<String> getPageText() async {
    try {
      const String jsCode =
          'document.body.innerText || document.body.textContent;';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      return result.toString();
    } catch (e) {
      debugPrint('Error getting page text: $e');
      _onJavaScriptError?.call('Error getting page text: $e');
      return '';
    }
  }

  // ============================================================================
  // ELEMENT INTERACTION & INJECTION
  // ============================================================================

  /// Injects custom CSS into the page.
  ///
  /// `css` - The CSS code to inject.
  /// `id` - Optional ID for the style element (for later removal).
  Future<void> injectCSS(String css, {String? id}) async {
    try {
      final styleId =
          id ?? 'injected-style-${DateTime.now().millisecondsSinceEpoch}';
      final String jsCode = '''
        (function() {
          var style = document.createElement('style');
          style.id = '$styleId';
          style.textContent = `$css`;
          document.head.appendChild(style);
          return '$styleId';
        })();
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Injected CSS with ID: $styleId');
    } catch (e) {
      debugPrint('Error injecting CSS: $e');
      _onJavaScriptError?.call('Error injecting CSS: $e');
      rethrow;
    }
  }

  /// Removes injected CSS by ID.
  ///
  /// `id` - The ID of the style element to remove.
  Future<void> removeInjectedCSS(String id) async {
    try {
      final String jsCode = '''
        (function() {
          var style = document.getElementById('$id');
          if (style) {
            style.remove();
            return true;
          }
          return false;
        })();
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Removed CSS with ID: $id');
    } catch (e) {
      debugPrint('Error removing CSS: $e');
      _onJavaScriptError?.call('Error removing CSS: $e');
    }
  }

  /// Clicks an element by CSS selector.
  ///
  /// `selector` - The CSS selector of the element to click.
  /// Returns true if the element was found and clicked, false otherwise.
  Future<bool> clickElement(String selector) async {
    try {
      final String jsCode = '''
        (function() {
          var element = document.querySelector('$selector');
          if (element) {
            element.click();
            return true;
          }
          return false;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final clicked = result.toString().toLowerCase() == 'true';
      debugPrint('Click element "$selector": $clicked');
      return clicked;
    } catch (e) {
      debugPrint('Error clicking element: $e');
      _onJavaScriptError?.call('Error clicking element: $e');
      return false;
    }
  }

  /// Sets the value of an input element.
  ///
  /// `selector` - The CSS selector of the input element.
  /// `value` - The value to set.
  /// Returns true if successful, false otherwise.
  Future<bool> setInputValue(String selector, String value) async {
    try {
      final String jsCode = '''
        (function() {
          var element = document.querySelector('$selector');
          if (element) {
            element.value = '$value';
            element.dispatchEvent(new Event('input', { bubbles: true }));
            element.dispatchEvent(new Event('change', { bubbles: true }));
            return true;
          }
          return false;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final success = result.toString().toLowerCase() == 'true';
      debugPrint('Set input value "$selector": $success');
      return success;
    } catch (e) {
      debugPrint('Error setting input value: $e');
      _onJavaScriptError?.call('Error setting input value: $e');
      return false;
    }
  }

  /// Gets the value of an input element.
  ///
  /// `selector` - The CSS selector of the input element.
  /// Returns the input value, or null if not found.
  Future<String?> getInputValue(String selector) async {
    try {
      final String jsCode = '''
        (function() {
          var element = document.querySelector('$selector');
          return element ? element.value : null;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      return result.toString();
    } catch (e) {
      debugPrint('Error getting input value: $e');
      _onJavaScriptError?.call('Error getting input value: $e');
      return null;
    }
  }

  /// Checks if an element exists on the page.
  ///
  /// `selector` - The CSS selector to check.
  /// Returns true if the element exists, false otherwise.
  Future<bool> elementExists(String selector) async {
    try {
      final String jsCode = '''
        (function() {
          return document.querySelector('$selector') !== null;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      return result.toString().toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error checking element existence: $e');
      _onJavaScriptError?.call('Error checking element existence: $e');
      return false;
    }
  }

  /// Counts elements matching a CSS selector.
  ///
  /// `selector` - The CSS selector to count.
  /// Returns the number of matching elements.
  Future<int> countElements(String selector) async {
    try {
      final String jsCode = '''
        (function() {
          return document.querySelectorAll('$selector').length;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      return int.tryParse(result.toString()) ?? 0;
    } catch (e) {
      debugPrint('Error counting elements: $e');
      _onJavaScriptError?.call('Error counting elements: $e');
      return 0;
    }
  }

  /// Scrolls an element into view.
  ///
  /// `selector` - The CSS selector of the element.
  /// `smooth` - If true, uses smooth scrolling.
  /// Returns true if successful, false otherwise.
  Future<bool> scrollElementIntoView(String selector,
      {bool smooth = true}) async {
    try {
      final behavior = smooth ? 'smooth' : 'auto';
      final String jsCode = '''
        (function() {
          var element = document.querySelector('$selector');
          if (element) {
            element.scrollIntoView({ behavior: '$behavior', block: 'center' });
            return true;
          }
          return false;
        })();
      ''';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      return result.toString().toLowerCase() == 'true';
    } catch (e) {
      debugPrint('Error scrolling element into view: $e');
      _onJavaScriptError?.call('Error scrolling element into view: $e');
      return false;
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  // ============================================================================
  // SECURITY & URL FILTERING
  // ============================================================================

  /// Sets allowed URLs (whitelist).
  ///
  /// Only URLs matching these patterns will be allowed to load.
  /// Supports wildcards (*) and regex patterns.
  void setAllowedUrls(List<String> urls) {
    _allowedUrls = urls;
    debugPrint('Set allowed URLs: $urls');
  }

  /// Sets blocked URLs (blacklist).
  ///
  /// URLs matching these patterns will be blocked from loading.
  /// Supports wildcards (*) and regex patterns.
  void setBlockedUrls(List<String> urls) {
    _blockedUrls = urls;
    debugPrint('Set blocked URLs: $urls');
  }

  /// Sets a custom URL validator function.
  ///
  /// This function will be called for each navigation request.
  /// Return true to allow, false to block.
  void setUrlValidator(bool Function(String url) validator) {
    _urlValidator = validator;
    debugPrint('Custom URL validator set');
  }

  /// Checks if a URL is allowed based on whitelist/blacklist/validator.
  ///
  /// Returns true if the URL should be allowed, false otherwise.
  bool isUrlAllowed(String url) {
    // Check custom validator first
    if (_urlValidator != null) {
      return _urlValidator!(url);
    }

    // Check blacklist
    if (_blockedUrls != null) {
      for (final pattern in _blockedUrls!) {
        if (_matchesPattern(url, pattern)) {
          debugPrint('URL blocked by blacklist: $url');
          return false;
        }
      }
    }

    // Check whitelist (if set, only whitelisted URLs are allowed)
    if (_allowedUrls != null) {
      for (final pattern in _allowedUrls!) {
        if (_matchesPattern(url, pattern)) {
          return true;
        }
      }
      debugPrint('URL not in whitelist: $url');
      return false;
    }

    // If no restrictions, allow
    return true;
  }

  /// Matches a URL against a pattern (supports wildcards).
  bool _matchesPattern(String url, String pattern) {
    // Convert wildcard pattern to regex
    final regexPattern = pattern
        .replaceAll('.', '\\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.');

    try {
      return RegExp('^$regexPattern\$').hasMatch(url);
    } catch (e) {
      debugPrint('Invalid pattern: $pattern');
      return false;
    }
  }

  /// Clears all URL restrictions.
  void clearUrlRestrictions() {
    _allowedUrls = null;
    _blockedUrls = null;
    _urlValidator = null;
    debugPrint('Cleared all URL restrictions');
  }

  // ============================================================================
  // PERFORMANCE MONITORING
  // ============================================================================

  /// Gets performance metrics from the WebView.
  ///
  /// Returns a map containing timing information about page load.
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      const String jsCode = '''
        (function() {
          if (!window.performance || !window.performance.timing) {
            return JSON.stringify({error: 'Performance API not available'});
          }
          
          var timing = window.performance.timing;
          var navigation = window.performance.navigation;
          
          return JSON.stringify({
            // Navigation timing
            navigationStart: timing.navigationStart,
            redirectTime: timing.redirectEnd - timing.redirectStart,
            dnsTime: timing.domainLookupEnd - timing.domainLookupStart,
            tcpTime: timing.connectEnd - timing.connectStart,
            requestTime: timing.responseStart - timing.requestStart,
            responseTime: timing.responseEnd - timing.responseStart,
            domProcessingTime: timing.domComplete - timing.domLoading,
            domContentLoadedTime: timing.domContentLoadedEventEnd - timing.domContentLoadedEventStart,
            loadEventTime: timing.loadEventEnd - timing.loadEventStart,
            totalLoadTime: timing.loadEventEnd - timing.navigationStart,
            
            // Navigation type
            navigationType: navigation.type,
            redirectCount: navigation.redirectCount,
            
            // Memory (if available)
            memory: window.performance.memory ? {
              usedJSHeapSize: window.performance.memory.usedJSHeapSize,
              totalJSHeapSize: window.performance.memory.totalJSHeapSize,
              jsHeapSizeLimit: window.performance.memory.jsHeapSizeLimit
            } : null
          });
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final Map<String, dynamic> metrics = jsonDecode(result.toString());
      debugPrint('Performance metrics: $metrics');
      return metrics;
    } catch (e) {
      debugPrint('Error getting performance metrics: $e');
      _onJavaScriptError?.call('Error getting performance metrics: $e');
      return {'error': e.toString()};
    }
  }

  /// Gets memory usage information.
  ///
  /// Returns a map with memory usage details (if available).
  Future<Map<String, int>?> getMemoryUsage() async {
    try {
      const String jsCode = '''
        (function() {
          if (window.performance && window.performance.memory) {
            return JSON.stringify({
              usedJSHeapSize: window.performance.memory.usedJSHeapSize,
              totalJSHeapSize: window.performance.memory.totalJSHeapSize,
              jsHeapSizeLimit: window.performance.memory.jsHeapSizeLimit
            });
          }
          return null;
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      if (result.toString() == 'null') {
        debugPrint('Memory API not available');
        return null;
      }

      final Map<String, dynamic> memory = jsonDecode(result.toString());
      return memory.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      debugPrint('Error getting memory usage: $e');
      _onJavaScriptError?.call('Error getting memory usage: $e');
      return null;
    }
  }

  /// Gets the number of resources loaded on the page.
  ///
  /// Returns a map with counts of different resource types.
  Future<Map<String, int>> getResourceCount() async {
    try {
      const String jsCode = '''
        (function() {
          if (!window.performance || !window.performance.getEntriesByType) {
            return JSON.stringify({error: 'Resource Timing API not available'});
          }
          
          var resources = window.performance.getEntriesByType('resource');
          var counts = {
            total: resources.length,
            script: 0,
            css: 0,
            img: 0,
            xmlhttprequest: 0,
            fetch: 0,
            other: 0
          };
          
          resources.forEach(function(resource) {
            var type = resource.initiatorType || 'other';
            if (counts[type] !== undefined) {
              counts[type]++;
            } else {
              counts.other++;
            }
          });
          
          return JSON.stringify(counts);
        })();
      ''';

      final result = await _controller.runJavaScriptReturningResult(jsCode);
      final Map<String, dynamic> counts = jsonDecode(result.toString());
      return counts.map((key, value) => MapEntry(key, value as int));
    } catch (e) {
      debugPrint('Error getting resource count: $e');
      _onJavaScriptError?.call('Error getting resource count: $e');
      return {'error': -1};
    }
  }

  // ============================================================================
  // NETWORK MONITORING
  // ============================================================================

  /// Enables network request monitoring.
  ///
  /// Captures XHR and Fetch requests made by the page.
  void enableNetworkMonitoring() {
    try {
      const String networkMonitorScript = '''
        (function() {
          // Monitor XMLHttpRequest
          var originalXHROpen = XMLHttpRequest.prototype.open;
          var originalXHRSend = XMLHttpRequest.prototype.send;
          
          XMLHttpRequest.prototype.open = function(method, url) {
            this._method = method;
            this._url = url;
            return originalXHROpen.apply(this, arguments);
          };
          
          XMLHttpRequest.prototype.send = function() {
            var xhr = this;
            var startTime = Date.now();
            
            this.addEventListener('load', function() {
              if (window.NetworkMonitor) {
                window.NetworkMonitor.postMessage(JSON.stringify({
                  type: 'xhr',
                  method: xhr._method,
                  url: xhr._url,
                  status: xhr.status,
                  duration: Date.now() - startTime
                }));
              }
            });
            
            return originalXHRSend.apply(this, arguments);
          };
          
          // Monitor Fetch
          if (window.fetch) {
            var originalFetch = window.fetch;
            window.fetch = function() {
              var startTime = Date.now();
              var url = arguments[0];
              var options = arguments[1] || {};
              
              return originalFetch.apply(this, arguments).then(function(response) {
                if (window.NetworkMonitor) {
                  window.NetworkMonitor.postMessage(JSON.stringify({
                    type: 'fetch',
                    method: options.method || 'GET',
                    url: url,
                    status: response.status,
                    duration: Date.now() - startTime
                  }));
                }
                return response;
              });
            };
          }
        })();
      ''';

      // Add channel to receive network events
      addJavaScriptChannel('NetworkMonitor', (JavaScriptMessage message) {
        debugPrint('[Network] ${message.message}');
      });

      _controller.runJavaScript(networkMonitorScript);
      debugPrint('Network monitoring enabled');
    } catch (e) {
      debugPrint('Error enabling network monitoring: $e');
      _onJavaScriptError?.call('Error enabling network monitoring: $e');
    }
  }

  // ============================================================================
  // PRIVATE METHODS
  // ============================================================================

  /// Initializes the WebView platform implementation.
  void _initializePlatform() {
    if (kIsWeb) {
      // Web platform uses HtmlElementView with IFrameElement
      // No need to set WebViewPlatform.instance for web
      debugPrint('Initializing WebView for Web platform (using IFrame)');
    } else if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
      debugPrint('Initializing WebView for Android platform');
    } else if (Platform.isIOS || Platform.isMacOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
      debugPrint('Initializing WebView for iOS/macOS platform');
    } else if (Platform.isWindows) {
      // Windows uses webview_windows package
      debugPrint('Initializing WebView for Windows platform');
    } else if (Platform.isLinux) {
      // Linux support through webview_flutter (uses WebKitGTK)
      debugPrint('Initializing WebView for Linux platform');
    } else {
      debugPrint(
        'Warning: Platform ${Platform.operatingSystem} may have limited support',
      );
    }
  }

  /// Initializes the WebViewController with platform-specific configurations.
  void _initializeController() {
    late PlatformWebViewControllerCreationParams params;

    if (kIsWeb) {
      // Web platform uses default params
      params = const PlatformWebViewControllerCreationParams();
    } else if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else if (Platform.isIOS || Platform.isMacOS) {
      params = WebKitWebViewControllerCreationParams();
    } else if (Platform.isWindows || Platform.isLinux) {
      // Windows and Linux use default params
      params = const PlatformWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _injectJavaScript();
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterBridge',
        onMessageReceived: (JavaScriptMessage message) {
          try {
            final data = jsonDecode(message.message) as Map<String, dynamic>;
            final action = data['action'] as String?;
            final payload = data['payload'] as Map<String, dynamic>? ?? {};

            if (action != null && _actionHandlers.containsKey(action)) {
              _actionHandlers[action]!(payload);
            }
          } catch (e) {
            debugPrint('Error processing message: $e');
            _onJavaScriptError?.call('Error processing message: $e');
          }
        },
      );

    if (Platform.isAndroid &&
        _controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(true);
      (_controller.platform as AndroidWebViewController)
          .setMediaPlaybackRequiresUserGesture(false);
    }
  }

  /// Builds the complete HTML string with embedded CSS and JavaScript.
  String _buildHtml(
    String htmlContent,
    String? cssContent,
    String? scriptContent, {
    bool enableCommunication = true,
    String? csp,
  }) {
    final String css = cssContent ??
        '''
      <style>
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
      </style>
    ''';

    final String cspMeta = csp != null
        ? '<meta http-equiv="Content-Security-Policy" content="$csp">'
        : '';

    final String script = scriptContent ?? '';

    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          $cspMeta
          $css
        </head>
        <body>
          $htmlContent
          <script>
            ${enableCommunication ? _communicationScript : ''}
            $script
          </script>
        </body>
      </html>
    ''';
  }

  /// Loads HTML content into the WebView.
  Future<void> _loadHtmlContent(String html) async {
    try {
      debugPrint('Loading HTML content (${html.length} chars)');
      await _controller.loadHtmlString(html);
      debugPrint('HTML content loaded successfully');
    } catch (e) {
      debugPrint('Error loading HTML content: $e');
      // Don't call _onJavaScriptError during normal loading operations
    }
  }

  String? _customScript;

  /// Loads a URL into the WebView and stores custom JavaScript for injection.
  Future<void> _loadUrlContent(String url, String? scriptContent) async {
    _customScript = scriptContent;
    try {
      await _controller.loadRequest(Uri.parse(url));
    } catch (e) {
      debugPrint('Error loading URL content: $e');
      // Don't call _onJavaScriptError during normal loading operations
    }
  }

  /// Injects communication and custom JavaScript into the loaded page.
  Future<void> _injectJavaScript() async {
    try {
      if (_enableCommunication) {
        await _controller.runJavaScript(_communicationScript);
      }
      if (_customScript != null) {
        await _controller.runJavaScript(_customScript!);
      }
    } catch (e) {
      debugPrint('Error injecting JavaScript: $e');
      _onJavaScriptError?.call('Error injecting JavaScript: $e');
    }
  }

  // ============================================================================
  // PERMISSION HANDLING
  // ============================================================================

  /// Requests geolocation permission from the user.
  ///
  /// Returns a [PermissionStatus] indicating the result.
  ///
  /// Example:
  /// ```dart
  /// final status = await webViewPlugin.requestGeolocationPermission();
  /// if (status.isGranted) {
  ///   print('Geolocation permission granted');
  /// }
  /// ```
  Future<PermissionStatus> requestGeolocationPermission() async {
    try {
      debugPrint('Requesting geolocation permission');
      final status = await Permission.location.request();
      debugPrint('Geolocation permission status: $status');
      return status;
    } catch (e) {
      debugPrint('Error requesting geolocation permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Checks if geolocation permission is granted.
  ///
  /// Returns true if permission is granted, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hasPermission = await webViewPlugin.hasGeolocationPermission();
  /// ```
  Future<bool> hasGeolocationPermission() async {
    try {
      final status = await Permission.location.status;
      debugPrint('Geolocation permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking geolocation permission: $e');
      return false;
    }
  }

  /// Requests camera permission from the user.
  ///
  /// Returns a [PermissionStatus] indicating the result.
  ///
  /// Example:
  /// ```dart
  /// final status = await webViewPlugin.requestCameraPermission();
  /// if (status.isGranted) {
  ///   print('Camera permission granted');
  /// }
  /// ```
  Future<PermissionStatus> requestCameraPermission() async {
    try {
      debugPrint('Requesting camera permission');
      final status = await Permission.camera.request();
      debugPrint('Camera permission status: $status');
      return status;
    } catch (e) {
      debugPrint('Error requesting camera permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Checks if camera permission is granted.
  ///
  /// Returns true if permission is granted, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hasPermission = await webViewPlugin.hasCameraPermission();
  /// ```
  Future<bool> hasCameraPermission() async {
    try {
      final status = await Permission.camera.status;
      debugPrint('Camera permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking camera permission: $e');
      return false;
    }
  }

  /// Requests microphone permission from the user.
  ///
  /// Returns a [PermissionStatus] indicating the result.
  ///
  /// Example:
  /// ```dart
  /// final status = await webViewPlugin.requestMicrophonePermission();
  /// if (status.isGranted) {
  ///   print('Microphone permission granted');
  /// }
  /// ```
  Future<PermissionStatus> requestMicrophonePermission() async {
    try {
      debugPrint('Requesting microphone permission');
      final status = await Permission.microphone.request();
      debugPrint('Microphone permission status: $status');
      return status;
    } catch (e) {
      debugPrint('Error requesting microphone permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Checks if microphone permission is granted.
  ///
  /// Returns true if permission is granted, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hasPermission = await webViewPlugin.hasMicrophonePermission();
  /// ```
  Future<bool> hasMicrophonePermission() async {
    try {
      final status = await Permission.microphone.status;
      debugPrint('Microphone permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking microphone permission: $e');
      return false;
    }
  }

  /// Requests storage permission from the user.
  ///
  /// Returns a [PermissionStatus] indicating the result.
  ///
  /// Note: On Android 13+ (API 33+), this uses the new photo/video/audio permissions.
  /// On older Android versions, it uses the legacy storage permission.
  ///
  /// Example:
  /// ```dart
  /// final status = await webViewPlugin.requestStoragePermission();
  /// if (status.isGranted) {
  ///   print('Storage permission granted');
  /// }
  /// ```
  Future<PermissionStatus> requestStoragePermission() async {
    try {
      debugPrint('Requesting storage permission');

      // For Android 13+ (API 33+), use granular media permissions
      if (Platform.isAndroid) {
        final status = await Permission.photos.request();
        debugPrint('Storage permission status: $status');
        return status;
      } else {
        // For iOS, use photos permission
        final status = await Permission.photos.request();
        debugPrint('Storage permission status: $status');
        return status;
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return PermissionStatus.denied;
    }
  }

  /// Checks if storage permission is granted.
  ///
  /// Returns true if permission is granted, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final hasPermission = await webViewPlugin.hasStoragePermission();
  /// ```
  Future<bool> hasStoragePermission() async {
    try {
      final status = await Permission.photos.status;
      debugPrint('Storage permission status: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('Error checking storage permission: $e');
      return false;
    }
  }

  /// Requests multiple permissions at once.
  ///
  /// [permissions] - List of permissions to request (e.g., ['location', 'camera', 'microphone', 'storage'])
  ///
  /// Returns a map of permission names to their status.
  ///
  /// Example:
  /// ```dart
  /// final results = await webViewPlugin.requestMultiplePermissions([
  ///   'location',
  ///   'camera',
  ///   'microphone',
  /// ]);
  ///
  /// if (results['location']?.isGranted == true) {
  ///   print('Location permission granted');
  /// }
  /// ```
  Future<Map<String, PermissionStatus>> requestMultiplePermissions(
      List<String> permissions) async {
    try {
      debugPrint('Requesting multiple permissions: $permissions');

      final Map<String, PermissionStatus> results = {};

      for (final permission in permissions) {
        switch (permission.toLowerCase()) {
          case 'location':
          case 'geolocation':
            results['location'] = await requestGeolocationPermission();
            break;
          case 'camera':
            results['camera'] = await requestCameraPermission();
            break;
          case 'microphone':
          case 'audio':
            results['microphone'] = await requestMicrophonePermission();
            break;
          case 'storage':
          case 'photos':
            results['storage'] = await requestStoragePermission();
            break;
          default:
            debugPrint('Unknown permission: $permission');
            results[permission] = PermissionStatus.denied;
        }
      }

      debugPrint('Multiple permissions results: $results');
      return results;
    } catch (e) {
      debugPrint('Error requesting multiple permissions: $e');
      return {};
    }
  }

  /// Checks the status of multiple permissions at once.
  ///
  /// [permissions] - List of permissions to check (e.g., ['location', 'camera', 'microphone', 'storage'])
  ///
  /// Returns a map of permission names to their granted status (true/false).
  ///
  /// Example:
  /// ```dart
  /// final results = await webViewPlugin.checkMultiplePermissions([
  ///   'location',
  ///   'camera',
  /// ]);
  ///
  /// if (results['location'] == true) {
  ///   print('Location permission is granted');
  /// }
  /// ```
  Future<Map<String, bool>> checkMultiplePermissions(
      List<String> permissions) async {
    try {
      debugPrint('Checking multiple permissions: $permissions');

      final Map<String, bool> results = {};

      for (final permission in permissions) {
        switch (permission.toLowerCase()) {
          case 'location':
          case 'geolocation':
            results['location'] = await hasGeolocationPermission();
            break;
          case 'camera':
            results['camera'] = await hasCameraPermission();
            break;
          case 'microphone':
          case 'audio':
            results['microphone'] = await hasMicrophonePermission();
            break;
          case 'storage':
          case 'photos':
            results['storage'] = await hasStoragePermission();
            break;
          default:
            debugPrint('Unknown permission: $permission');
            results[permission] = false;
        }
      }

      debugPrint('Multiple permissions check results: $results');
      return results;
    } catch (e) {
      debugPrint('Error checking multiple permissions: $e');
      return {};
    }
  }

  /// Opens the app settings page where the user can manually grant permissions.
  ///
  /// Returns true if settings were opened successfully, false otherwise.
  ///
  /// Example:
  /// ```dart
  /// final opened = await webViewPlugin.openAppSettings();
  /// if (opened) {
  ///   print('Settings opened');
  /// }
  /// ```
  Future<bool> openAppSettings() async {
    try {
      debugPrint('Opening app settings');
      final opened = await openAppSettings();
      debugPrint('App settings opened: $opened');
      return opened;
    } catch (e) {
      debugPrint('Error opening app settings: $e');
      return false;
    }
  }

  /// Gets the permanent denial status of a permission.
  ///
  /// Returns true if the permission has been permanently denied (user selected "Don't ask again").
  ///
  /// [permissionType] - The type of permission ('location', 'camera', 'microphone', 'storage')
  ///
  /// Example:
  /// ```dart
  /// final isPermanentlyDenied = await webViewPlugin.isPermissionPermanentlyDenied('camera');
  /// if (isPermanentlyDenied) {
  ///   // Show dialog to open settings
  ///   await webViewPlugin.openAppSettings();
  /// }
  /// ```
  Future<bool> isPermissionPermanentlyDenied(String permissionType) async {
    try {
      debugPrint(
          'Checking if permission is permanently denied: $permissionType');

      PermissionStatus status;

      switch (permissionType.toLowerCase()) {
        case 'location':
        case 'geolocation':
          status = await Permission.location.status;
          break;
        case 'camera':
          status = await Permission.camera.status;
          break;
        case 'microphone':
        case 'audio':
          status = await Permission.microphone.status;
          break;
        case 'storage':
        case 'photos':
          status = await Permission.photos.status;
          break;
        default:
          debugPrint('Unknown permission type: $permissionType');
          return false;
      }

      final isPermanentlyDenied = status.isPermanentlyDenied;
      debugPrint(
          'Permission $permissionType permanently denied: $isPermanentlyDenied');
      return isPermanentlyDenied;
    } catch (e) {
      debugPrint('Error checking permanent denial: $e');
      return false;
    }
  }

  // ============================================================================
  // SCREENSHOT & CAPTURE (Platform-specific - requires native implementation)
  // ============================================================================

  /// Takes a screenshot of the current WebView content.
  ///
  /// Note: This feature requires platform-specific implementation.
  /// Currently returns null as it needs native platform channels.
  ///
  /// Returns the screenshot as bytes, or null if not supported.
  ///
  /// Example:
  /// ```dart
  /// final screenshot = await webViewPlugin.takeScreenshot();
  /// if (screenshot != null) {
  ///   // Save or display the screenshot
  /// }
  /// ```
  Future<Uint8List?> takeScreenshot() async {
    debugPrint('Screenshot feature requires native platform implementation');
    _onJavaScriptError?.call(
        'Screenshot feature is not yet implemented. Requires native platform channels.');
    return null;
  }

  // ============================================================================
  // PRINT & PDF GENERATION (Platform-specific)
  // ============================================================================

  /// Prints the current WebView content.
  ///
  /// Note: This feature requires platform-specific implementation.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.print();
  /// ```
  Future<void> print() async {
    debugPrint('Print feature requires native platform implementation');
    _onJavaScriptError?.call(
        'Print feature is not yet implemented. Requires native platform channels.');
  }

  /// Generates a PDF from the current WebView content.
  ///
  /// Note: This feature requires platform-specific implementation.
  ///
  /// Returns the PDF as bytes, or null if not supported.
  ///
  /// Example:
  /// ```dart
  /// final pdf = await webViewPlugin.generatePDF();
  /// if (pdf != null) {
  ///   // Save the PDF
  /// }
  /// ```
  Future<Uint8List?> generatePDF() async {
    debugPrint('PDF generation requires native platform implementation');
    _onJavaScriptError?.call(
        'PDF generation is not yet implemented. Requires native platform channels.');
    return null;
  }

  // ============================================================================
  // ENHANCED LIFECYCLE CALLBACKS
  // ============================================================================

  /// Callback types for WebView lifecycle events
  Function(String url)? _onPageStarted;
  Function(String url)? _onPageFinished;
  Function(int progress)? _onProgress;
  Function(String error)? _onError;
  Function(String url)? _onUrlChanged;

  /// Sets a callback for when a page starts loading.
  ///
  /// Example:
  /// ```dart
  /// webViewPlugin.setOnPageStarted((url) {
  ///   print('Page started loading: $url');
  /// });
  /// ```
  void setOnPageStarted(Function(String url) callback) {
    _onPageStarted = callback;
    debugPrint('Page started callback set');
  }

  /// Sets a callback for when a page finishes loading.
  ///
  /// Example:
  /// ```dart
  /// webViewPlugin.setOnPageFinished((url) {
  ///   print('Page finished loading: $url');
  /// });
  /// ```
  void setOnPageFinished(Function(String url) callback) {
    _onPageFinished = callback;
    debugPrint('Page finished callback set');
  }

  /// Sets a callback for page loading progress.
  ///
  /// Example:
  /// ```dart
  /// webViewPlugin.setOnProgress((progress) {
  ///   print('Loading progress: $progress%');
  /// });
  /// ```
  void setOnProgress(Function(int progress) callback) {
    _onProgress = callback;
    debugPrint('Progress callback set');
  }

  /// Sets a callback for errors.
  ///
  /// Example:
  /// ```dart
  /// webViewPlugin.setOnError((error) {
  ///   print('Error occurred: $error');
  /// });
  /// ```
  void setOnError(Function(String error) callback) {
    _onError = callback;
    debugPrint('Error callback set');
  }

  /// Sets a callback for URL changes.
  ///
  /// Example:
  /// ```dart
  /// webViewPlugin.setOnUrlChanged((url) {
  ///   print('URL changed to: $url');
  /// });
  /// ```
  void setOnUrlChanged(Function(String url) callback) {
    _onUrlChanged = callback;
    debugPrint('URL changed callback set');
  }

  // ============================================================================
  // CONTEXT MENU CUSTOMIZATION (Platform-specific)
  // ============================================================================

  /// Disables the context menu (long-press menu) in the WebView.
  ///
  /// This uses JavaScript to prevent the default context menu behavior.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.disableContextMenu();
  /// ```
  Future<void> disableContextMenu() async {
    try {
      const String jsCode = '''
        document.addEventListener('contextmenu', function(e) {
          e.preventDefault();
          return false;
        }, false);
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Context menu disabled');
    } catch (e) {
      debugPrint('Error disabling context menu: $e');
      _onJavaScriptError?.call('Error disabling context menu: $e');
    }
  }

  /// Enables the context menu (long-press menu) in the WebView.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.enableContextMenu();
  /// ```
  Future<void> enableContextMenu() async {
    try {
      const String jsCode = '''
        document.removeEventListener('contextmenu', function(e) {
          e.preventDefault();
          return false;
        }, false);
      ''';
      await _controller.runJavaScript(jsCode);
      debugPrint('Context menu enabled');
    } catch (e) {
      debugPrint('Error enabling context menu: $e');
      _onJavaScriptError?.call('Error enabling context menu: $e');
    }
  }

  // ============================================================================
  // SECURE STORAGE INTEGRATION
  // ============================================================================

  /// Clears all cookies for the WebView.
  ///
  /// This is useful for logout functionality or clearing session data.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.clearCookies();
  /// ```
  Future<void> clearCookies() async {
    try {
      final cookieManager = WebViewCookieManager();
      await cookieManager.clearCookies();
      debugPrint('Cleared all cookies');
    } catch (e) {
      debugPrint('Error clearing cookies: $e');
      _onJavaScriptError?.call('Error clearing cookies: $e');
      rethrow;
    }
  }

  /// Clears the WebView cache.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.clearCache();
  /// ```
  Future<void> clearCache() async {
    try {
      await _controller.clearCache();
      debugPrint('Cleared WebView cache');
    } catch (e) {
      debugPrint('Error clearing cache: $e');
      _onJavaScriptError?.call('Error clearing cache: $e');
      rethrow;
    }
  }

  // ============================================================================
  // ADDITIONAL UTILITY METHODS
  // ============================================================================

  /// Evaluates JavaScript code and returns the result.
  ///
  /// This is a more flexible alternative to runJavaScript that returns the result.
  ///
  /// [code] - The JavaScript code to evaluate.
  /// Returns the result of the JavaScript execution.
  ///
  /// Example:
  /// ```dart
  /// final result = await webViewPlugin.evaluateJavaScript('2 + 2');
  /// print('Result: $result'); // Result: 4
  /// ```
  Future<dynamic> evaluateJavaScript(String code) async {
    try {
      final result = await _controller.runJavaScriptReturningResult(code);
      debugPrint('JavaScript evaluation result: $result');
      return result;
    } catch (e) {
      debugPrint('Error evaluating JavaScript: $e');
      _onJavaScriptError?.call('Error evaluating JavaScript: $e');
      rethrow;
    }
  }

  /// Runs JavaScript code without returning a result.
  ///
  /// [code] - The JavaScript code to run.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.runJavaScript('console.log("Hello from Flutter")');
  /// ```
  Future<void> runJavaScript(String code) async {
    try {
      await _controller.runJavaScript(code);
      debugPrint('JavaScript executed successfully');
    } catch (e) {
      debugPrint('Error running JavaScript: $e');
      _onJavaScriptError?.call('Error running JavaScript: $e');
      rethrow;
    }
  }

  /// Gets the user agent string of the WebView.
  ///
  /// Returns the current user agent string.
  ///
  /// Example:
  /// ```dart
  /// final userAgent = await webViewPlugin.getUserAgent();
  /// print('User Agent: $userAgent');
  /// ```
  Future<String?> getUserAgent() async {
    try {
      const String jsCode = 'navigator.userAgent;';
      final result = await _controller.runJavaScriptReturningResult(jsCode);
      debugPrint('User Agent: $result');
      return result.toString();
    } catch (e) {
      debugPrint('Error getting user agent: $e');
      _onJavaScriptError?.call('Error getting user agent: $e');
      return null;
    }
  }

  /// Sets a custom user agent for the WebView.
  ///
  /// [userAgent] - The custom user agent string.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.setUserAgent('MyApp/1.0');
  /// ```
  Future<void> setUserAgent(String userAgent) async {
    try {
      await _controller.setUserAgent(userAgent);
      debugPrint('Set user agent: $userAgent');
    } catch (e) {
      debugPrint('Error setting user agent: $e');
      _onJavaScriptError?.call('Error setting user agent: $e');
      rethrow;
    }
  }

  /// Enables or disables JavaScript execution in the WebView.
  ///
  /// [enabled] - If true, enables JavaScript; if false, disables it.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.setJavaScriptEnabled(true);
  /// ```
  Future<void> setJavaScriptEnabled(bool enabled) async {
    try {
      await _controller.setJavaScriptMode(
        enabled ? JavaScriptMode.unrestricted : JavaScriptMode.disabled,
      );
      debugPrint('JavaScript ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting JavaScript mode: $e');
      _onJavaScriptError?.call('Error setting JavaScript mode: $e');
      rethrow;
    }
  }

  /// Sets the background color of the WebView.
  ///
  /// [color] - The background color to set.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.setBackgroundColor(Colors.white);
  /// ```
  Future<void> setBackgroundColor(Color color) async {
    try {
      if (kIsWeb) {
        debugPrint('Background color setting via CSS for Web platform');
        // For web, we can inject CSS to set background
        final r = (color.r * 255.0).round() & 0xff;
        final g = (color.g * 255.0).round() & 0xff;
        final b = (color.b * 255.0).round() & 0xff;
        final a = color.a;
        await _controller.runJavaScript('''
          document.body.style.backgroundColor = 'rgba($r, $g, $b, $a)';
        ''');
      } else if (!Platform.isMacOS) {
        await _controller.setBackgroundColor(color);
        debugPrint('Set background color: $color');
      } else {
        debugPrint('Background color not fully supported on macOS');
        // Try CSS fallback for macOS
        final r = (color.r * 255.0).round() & 0xff;
        final g = (color.g * 255.0).round() & 0xff;
        final b = (color.b * 255.0).round() & 0xff;
        final a = color.a;
        await _controller.runJavaScript('''
          document.body.style.backgroundColor = 'rgba($r, $g, $b, $a)';
        ''');
      }
    } catch (e) {
      debugPrint('Error setting background color: $e');
      _onJavaScriptError?.call('Error setting background color: $e');
    }
  }

  /// Loads a URL in the WebView.
  ///
  /// [url] - The URL to load.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.loadUrl('https://flutter.dev');
  /// ```
  Future<void> loadUrl(String url) async {
    try {
      await _controller.loadRequest(Uri.parse(url));
      _currentContent = url;
      _isCurrentContentUrl = true;
      debugPrint('Loaded URL: $url');
    } catch (e) {
      debugPrint('Error loading URL: $e');
      _onJavaScriptError?.call('Error loading URL: $e');
      rethrow;
    }
  }

  /// Loads HTML string in the WebView.
  ///
  /// [html] - The HTML string to load.
  /// [baseUrl] - Optional base URL for resolving relative URLs.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.loadHtmlString('<h1>Hello World</h1>');
  /// ```
  Future<void> loadHtmlString(String html, {String? baseUrl}) async {
    try {
      if (baseUrl != null) {
        await _controller.loadHtmlString(html, baseUrl: baseUrl);
      } else {
        await _controller.loadHtmlString(html);
      }
      _currentContent = html;
      _isCurrentContentUrl = false;
      debugPrint('Loaded HTML string');
    } catch (e) {
      debugPrint('Error loading HTML string: $e');
      _onJavaScriptError?.call('Error loading HTML string: $e');
      rethrow;
    }
  }

  // ============================================================================
  // FILE HANDLING
  // ============================================================================

  /// Downloads a file from the given URL to the specified save path.
  ///
  /// [url] - The URL of the file to download.
  /// [savePath] - The local path where the file should be saved.
  /// [onProgress] - Optional callback for download progress updates.
  /// [filename] - Optional custom filename (if not provided, extracted from URL).
  ///
  /// Returns the full path to the downloaded file.
  ///
  /// Example:
  /// ```dart
  /// final path = await webViewPlugin.downloadFile(
  ///   'https://example.com/file.pdf',
  ///   '/path/to/save',
  ///   onProgress: (received, total) {
  ///     print('Progress: ${(received / total * 100).toStringAsFixed(0)}%');
  ///   },
  /// );
  /// ```
  Future<String> downloadFile(
    String url,
    String savePath, {
    OnDownloadProgress? onProgress,
    String? filename,
  }) async {
    try {
      // Extract filename from URL if not provided
      final String finalFilename = filename ?? url.split('/').last;
      final String fullPath = '$savePath/$finalFilename';

      // Create Dio instance for download
      final dio = Dio();
      final cancelToken = CancelToken();
      _activeDownloads[url] = cancelToken;

      debugPrint('Starting download: $url -> $fullPath');

      // Download the file
      await dio.download(
        url,
        fullPath,
        onReceiveProgress: (received, total) {
          onProgress?.call(received, total);
          if (total != -1) {
            final progress = (received / total * 100).toStringAsFixed(0);
            debugPrint('Download progress: $progress%');
          }
        },
        cancelToken: cancelToken,
      );

      // Remove from active downloads
      _activeDownloads.remove(url);

      debugPrint('Download completed: $fullPath');
      return fullPath;
    } catch (e) {
      _activeDownloads.remove(url);
      debugPrint('Error downloading file: $e');
      // Don't call _onJavaScriptError - let callers handle download errors
      rethrow;
    }
  }

  /// Cancels an active download.
  ///
  /// [url] - The URL of the download to cancel.
  ///
  /// Returns true if the download was cancelled, false if no active download was found.
  ///
  /// Example:
  /// ```dart
  /// await webViewPlugin.cancelDownload('https://example.com/file.pdf');
  /// ```
  Future<bool> cancelDownload(String url) async {
    try {
      final cancelToken = _activeDownloads[url];
      if (cancelToken != null) {
        cancelToken.cancel('Download cancelled by user');
        _activeDownloads.remove(url);
        debugPrint('Cancelled download: $url');
        return true;
      }
      debugPrint('No active download found for: $url');
      return false;
    } catch (e) {
      debugPrint('Error cancelling download: $e');
      _onJavaScriptError?.call('Error cancelling download: $e');
      return false;
    }
  }

  /// Gets the list of currently active downloads.
  ///
  /// Returns a list of URLs that are currently being downloaded.
  ///
  /// Example:
  /// ```dart
  /// final activeDownloads = webViewPlugin.getActiveDownloads();
  /// print('Active downloads: $activeDownloads');
  /// ```
  List<String> getActiveDownloads() {
    return _activeDownloads.keys.toList();
  }

  /// Opens a file picker for the user to select files for upload.
  ///
  /// [allowMultiple] - Whether to allow multiple file selection.
  /// [acceptTypes] - List of accepted MIME types or file extensions (e.g., ['pdf', 'image/*']).
  ///
  /// Returns a list of selected file paths, or an empty list if cancelled.
  ///
  /// Example:
  /// ```dart
  /// final files = await webViewPlugin.pickFiles(
  ///   allowMultiple: true,
  ///   acceptTypes: ['pdf', 'jpg', 'png'],
  /// );
  /// ```
  Future<List<String>> pickFiles({
    bool allowMultiple = false,
    List<String>? acceptTypes,
  }) async {
    try {
      // Convert MIME types to FileType
      FileType fileType = FileType.any;
      List<String>? allowedExtensions;

      if (acceptTypes != null && acceptTypes.isNotEmpty) {
        // Check if all types are image types
        if (acceptTypes.every((type) =>
            type.startsWith('image/') ||
            ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                .contains(type.toLowerCase()))) {
          fileType = FileType.image;
        }
        // Check if all types are video types
        else if (acceptTypes.every((type) =>
            type.startsWith('video/') ||
            ['mp4', 'mov', 'avi', 'mkv'].contains(type.toLowerCase()))) {
          fileType = FileType.video;
        }
        // Check if all types are audio types
        else if (acceptTypes.every((type) =>
            type.startsWith('audio/') ||
            ['mp3', 'wav', 'aac', 'flac'].contains(type.toLowerCase()))) {
          fileType = FileType.audio;
        }
        // Otherwise use custom with extensions
        else {
          fileType = FileType.custom;
          allowedExtensions = acceptTypes
              .where((type) => !type.contains('/'))
              .map((ext) => ext.replaceAll('.', ''))
              .toList();
        }
      }

      final result = await FilePicker.platform.pickFiles(
        allowMultiple: allowMultiple,
        type: fileType,
        allowedExtensions: allowedExtensions,
      );

      if (result != null) {
        final paths = result.paths.whereType<String>().toList();
        debugPrint('Selected ${paths.length} file(s): $paths');
        return paths;
      }

      debugPrint('File picker cancelled');
      return [];
    } catch (e) {
      debugPrint('Error picking files: $e');
      _onJavaScriptError?.call('Error picking files: $e');
      return [];
    }
  }

  /// Gets the downloads directory path for the current platform.
  ///
  /// Returns the path to the downloads directory, or null if unavailable.
  ///
  /// Example:
  /// ```dart
  /// final downloadsPath = await webViewPlugin.getDownloadsDirectoryPath();
  /// ```
  Future<String?> getDownloadsDirectoryPath() async {
    try {
      if (Platform.isAndroid) {
        // On Android, use external storage directory
        final directory = await getExternalStorageDirectory();
        if (directory != null) {
          // Navigate to Downloads folder
          final downloadsPath = '${directory.path.split('Android')[0]}Download';
          debugPrint('Downloads directory: $downloadsPath');
          return downloadsPath;
        }
      } else if (Platform.isIOS) {
        // On iOS, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        debugPrint('Documents directory: ${directory.path}');
        return directory.path;
      } else if (Platform.isMacOS || Platform.isLinux || Platform.isWindows) {
        // On desktop platforms, use downloads directory
        final directory = await getDownloadsDirectory();
        if (directory != null) {
          debugPrint('Downloads directory: ${directory.path}');
          return directory.path;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting downloads directory: $e');
      _onJavaScriptError?.call('Error getting downloads directory: $e');
      return null;
    }
  }

  /// Triggers the file download callback if set.
  ///
  /// This method should be called when the WebView detects a file download request.
  ///
  /// [url] - The URL of the file to download.
  /// [suggestedFilename] - The suggested filename from the server.
  /// [mimeType] - The MIME type of the file.
  ///
  /// Example:
  /// ```dart
  /// webViewPlugin.handleFileDownload(
  ///   'https://example.com/file.pdf',
  ///   'document.pdf',
  ///   'application/pdf',
  /// );
  /// ```
  void handleFileDownload(
    String url,
    String suggestedFilename,
    String? mimeType,
  ) {
    try {
      if (_onFileDownload != null) {
        _onFileDownload(url, suggestedFilename, mimeType);
        debugPrint('File download callback triggered: $url');
      } else {
        debugPrint('No file download callback set');
      }
    } catch (e) {
      debugPrint('Error handling file download: $e');
      _onJavaScriptError?.call('Error handling file download: $e');
    }
  }

  /// Triggers the file upload callback if set.
  ///
  /// This method should be called when the WebView detects a file upload request.
  ///
  /// [allowMultiple] - Whether multiple files can be selected.
  /// [acceptTypes] - List of accepted MIME types or file extensions.
  ///
  /// Returns a list of selected file paths.
  ///
  /// Example:
  /// ```dart
  /// final files = await webViewPlugin.handleFileUpload(
  ///   allowMultiple: true,
  ///   acceptTypes: ['image/*', 'pdf'],
  /// );
  /// ```
  Future<List<String>> handleFileUpload({
    bool allowMultiple = false,
    List<String>? acceptTypes,
  }) async {
    try {
      if (_onFileUploadRequest != null) {
        final files = await _onFileUploadRequest(allowMultiple, acceptTypes);
        debugPrint('File upload callback returned ${files.length} file(s)');
        return files;
      } else {
        debugPrint('No file upload callback set, using default picker');
        return await pickFiles(
          allowMultiple: allowMultiple,
          acceptTypes: acceptTypes,
        );
      }
    } catch (e) {
      debugPrint('Error handling file upload: $e');
      _onJavaScriptError?.call('Error handling file upload: $e');
      return [];
    }
  }

  /// Gets the MIME type for a file based on its extension (static version).
  ///
  /// [filename] - The filename or path.
  ///
  /// Returns the MIME type, or 'application/octet-stream' if unknown.
  ///
  /// Example:
  /// ```dart
  /// final mimeType = WebViewPlugin.getMimeTypeStatic('document.pdf');
  /// print(mimeType); // 'application/pdf'
  /// ```
  static String getMimeTypeStatic(String filename) {
    final extension = filename.split('.').last.toLowerCase();

    // Common MIME types
    const mimeTypes = {
      // Documents
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'xls': 'application/vnd.ms-excel',
      'xlsx':
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      'ppt': 'application/vnd.ms-powerpoint',
      'pptx':
          'application/vnd.openxmlformats-officedocument.presentationml.presentation',
      'txt': 'text/plain',
      'csv': 'text/csv',

      // Images
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'bmp': 'image/bmp',
      'webp': 'image/webp',
      'svg': 'image/svg+xml',
      'ico': 'image/x-icon',

      // Audio
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'ogg': 'audio/ogg',
      'aac': 'audio/aac',
      'flac': 'audio/flac',

      // Video
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo',
      'mov': 'video/quicktime',
      'wmv': 'video/x-ms-wmv',
      'flv': 'video/x-flv',
      'mkv': 'video/x-matroska',
      'webm': 'video/webm',

      // Archives
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
      '7z': 'application/x-7z-compressed',
      'tar': 'application/x-tar',
      'gz': 'application/gzip',

      // Web
      'html': 'text/html',
      'htm': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'xml': 'application/xml',

      // Other
      'apk': 'application/vnd.android.package-archive',
      'exe': 'application/x-msdownload',
      'dmg': 'application/x-apple-diskimage',
    };

    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Gets the MIME type for a file based on its extension.
  ///
  /// [filename] - The filename or path.
  ///
  /// Returns the MIME type, or 'application/octet-stream' if unknown.
  ///
  /// Example:
  /// ```dart
  /// final mimeType = webViewPlugin.getMimeType('document.pdf');
  /// print(mimeType); // 'application/pdf'
  /// ```
  String getMimeType(String filename) {
    return getMimeTypeStatic(filename);
  }
}
