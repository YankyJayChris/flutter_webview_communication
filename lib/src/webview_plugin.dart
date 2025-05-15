// Copyright (c) 2025 [IGIHOZO Jean Christian]. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A plugin for creating WebViews with bi-directional communication capabilities.
class WebViewPlugin {
  late WebViewController _controller;
  final Map<String, Function(Map<String, dynamic>)> _actionHandlers;
  final bool _enableCommunication;
  final Function(String)? _onJavaScriptError;
  String? _currentContent;
  bool _isCurrentContentUrl = false;

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
  /// [actionHandlers] - A map of action names to their handler functions that process
  /// messages received from the WebView. The handler receives a JSON payload.
  /// [enableCommunication] - If true, enables injection of communication scripts for URLs
  /// and includes them in custom HTML (default: false for URLs, true for HTML).
  /// [onJavaScriptError] - Optional callback to handle JavaScript console errors.
  /// Throws [Exception] if the platform is not supported.
  WebViewPlugin({
    Map<String, Function(Map<String, dynamic>)?>? actionHandlers,
    bool enableCommunication = false,
    Function(String)? onJavaScriptError,
  })  : _actionHandlers = actionHandlers?.map(
              (key, value) => MapEntry(key, value ?? ((_) {})),
            ) ??
            {},
        _enableCommunication = enableCommunication,
        _onJavaScriptError = onJavaScriptError {
    _initializePlatform();
    _initializeController();
  }

  /// Builds and returns a WebView widget.
  ///
  /// [content] - The content to display: either an HTML string or a URL (required).
  /// [isUrl] - If true, treats [content] as a URL; if false, treats it as HTML (default: false).
  /// [cssContent] - Optional CSS styles to include in the <head> (only applies if [isUrl] is false).
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

    // Store content for reload
    _currentContent = content;
    _isCurrentContentUrl = isUrl;

    if (isUrl) {
      _loadUrlContent(content, scriptContent);
    } else {
      final String finalHtml = _buildHtml(
        content,
        cssContent,
        scriptContent,
        enableCommunication: shouldEnableCommunication,
        csp: csp,
      );
      _loadHtmlContent(finalHtml);
    }

    if (backgroundColor != null && !Platform.isMacOS) {
      _controller.setBackgroundColor(backgroundColor);
    }

    if (userAgent != null) {
      _controller.setUserAgent(userAgent);
    }

    // Update navigation delegate to handle loading states
    _controller.setNavigationDelegate(
      NavigationDelegate(
        onPageStarted: (String url) {
          onLoadingStateChanged?.call('started', null, null);
          if (url == _currentContent) {
            _injectJavaScript();
          }
        },
        onProgress: (int progress) {
          onLoadingStateChanged?.call('progress', progress, null);
        },
        onPageFinished: (String url) {
          onLoadingStateChanged?.call('finished', null, null);
          if (url == _currentContent) {
            _injectJavaScript();
          }
        },
        onWebResourceError: (WebResourceError error) {
          onLoadingStateChanged?.call('error', null, error.description);
        },
        onHttpError: (HttpResponseError error) {
          onLoadingStateChanged?.call(
              'error', null, 'HTTP ${error.toString()}');
        },
        onNavigationRequest: (NavigationRequest request) {
          return NavigationDecision.navigate;
        },
      ),
    );

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
      final String jsCode = 'localStorage.setItem("$escapedKey", $jsValue);';
      await _controller.runJavaScript(jsCode);
      debugPrint('Saved to localStorage: $escapedKey = $jsValue');
    } catch (e) {
      debugPrint('Error saving to localStorage: key=$key, error=$e');
      _onJavaScriptError
          ?.call('Error saving to localStorage: key=$key, error=$e');
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
      final String jsCode = 'localStorage.removeItem("$escapedKey");';
      await _controller.runJavaScript(jsCode);
      debugPrint('Removed from localStorage: $escapedKey');
    } catch (e) {
      debugPrint('Error removing from localStorage: key=$key, error=$e');
      _onJavaScriptError
          ?.call('Error removing from localStorage: key=$key, error=$e');
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
          const items = {};
          for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            items[key] = localStorage.getItem(key);
          }
          return JSON.stringify(items);
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
      _onJavaScriptError?.call('Error retrieving localStorage: $e');
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
      _onJavaScriptError?.call('Error clearing WebView data: $e');
      rethrow;
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

  /// Initializes the WebView platform implementation.
  void _initializePlatform() {
    if (kIsWeb) {
      throw Exception(
        'Web platform is not supported by flutter_webview_communication.',
      );
    }
  }

  /// Initializes the WebViewController with platform-specific configurations.
  void _initializeController() {
    const params = PlatformWebViewControllerCreationParams();

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
      await _controller.loadHtmlString(html);
    } catch (e) {
      debugPrint('Error loading HTML content: $e');
      _onJavaScriptError?.call('Error loading HTML content: $e');
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
      _onJavaScriptError?.call('Error loading URL content: $e');
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
}
