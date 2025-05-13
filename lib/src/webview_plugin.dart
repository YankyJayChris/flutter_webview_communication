// Copyright (c) 2025 [IGIHOZO Jean Christian]. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

// Conditional imports for platform-specific features
import 'package:webview_flutter_android/webview_flutter_android.dart'
    if (dart.library.io) 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart'
    if (dart.library.io) 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// A plugin for creating WebViews with bi-directional communication capabilities.
class WebViewPlugin {
  late WebViewController _controller;
  final Map<String, Function(Map<String, dynamic>)> _actionHandlers;

  /// Creates a WebViewPlugin instance.
  ///
  /// [actionHandlers] - A map of action names to their handler functions that process
  /// messages received from the WebView. The handler receives a JSON payload.
  /// Throws [Exception] if the platform is not supported.
  WebViewPlugin({
    Map<String, Function(Map<String, dynamic>)?>? actionHandlers,
  }) : _actionHandlers = actionHandlers?.map(
              (key, value) => MapEntry(key, value ?? ((_) {})),
            ) ??
            {} {
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
  Widget buildWebView({
    required String content,
    bool isUrl = false,
    String? cssContent,
    String? scriptContent,
    double? height,
    double? width,
    Color? backgroundColor,
  }) {
    if (isUrl) {
      _loadUrlContent(content, scriptContent);
    } else {
      final String finalHtml = _buildHtml(content, cssContent, scriptContent);
      _loadHtmlContent(finalHtml);
    }

    if (backgroundColor != null && !Platform.isMacOS) {
      _controller.setBackgroundColor(backgroundColor);
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
      // Validate key
      if (key.isEmpty) {
        throw ArgumentError('Key cannot be empty');
      }
      // Attempt to JSON-encode the value to ensure it's serializable
      final String jsValue = jsonEncode(value);
      // Escape the key to prevent JavaScript injection
      final String escapedKey = key.replaceAll('"', '\\"');
      final String jsCode = 'localStorage.setItem("$escapedKey", $jsValue);';
      await _controller.runJavaScript(jsCode);
      debugPrint('Saved to localStorage: $escapedKey = $jsValue');
    } catch (e) {
      debugPrint('Error saving to localStorage: key=$key, error=$e');
      rethrow; // Rethrow to allow caller to handle the error
    }
  }

  /// Removes a key from the WebView's local storage.
  ///
  /// [key] - The key to remove from local storage.
  Future<void> removeFromLocalStorage({
    required String key,
  }) async {
    try {
      // Validate key
      if (key.isEmpty) {
        throw ArgumentError('Key cannot be empty');
      }
      // Escape the key to prevent JavaScript injection
      final String escapedKey = key.replaceAll('"', '\\"');
      final String jsCode = 'localStorage.removeItem("$escapedKey");';
      await _controller.runJavaScript(jsCode);
      debugPrint('Removed from localStorage: $escapedKey');
    } catch (e) {
      debugPrint('Error removing from localStorage: key=$key, error=$e');
      rethrow; // Rethrow to allow caller to handle the error
    }
  }

  /// Initializes the WebView platform implementation.
  void _initializePlatform() {
    if (kIsWeb) {
      throw Exception(
        'Web platform is not supported by flutter_webview_communication.',
      );
    } else if (Platform.isAndroid) {
      WebViewPlatform.instance = AndroidWebViewPlatform();
    } else if (Platform.isIOS || Platform.isMacOS) {
      WebViewPlatform.instance = WebKitWebViewPlatform();
    } else {
      throw Exception(
        'This platform (${Platform.operatingSystem}) is not supported by flutter_webview_communication.',
      );
    }
  }

  /// Initializes the WebViewController with platform-specific configurations.
  void _initializeController() {
    late final PlatformWebViewControllerCreationParams params;

    if (Platform.isIOS || Platform.isMacOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (Platform.isAndroid) {
      params = const PlatformWebViewControllerCreationParams();
    } else {
      // This should not be reached due to _initializePlatform check
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            // Inject custom JavaScript after the page finishes loading (for URLs)
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
      String htmlContent, String? cssContent, String? scriptContent) {
    final String css = cssContent ??
        '''
      <style>
        body { margin: 0; padding: 0; font-family: Arial, sans-serif; }
      </style>
    ''';

    final String script = scriptContent ?? '';

    return '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          $css
        </head>
        <body>
          $htmlContent
          <script>
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
    }
  }

  /// Injects custom JavaScript into the loaded page.
  Future<void> _injectJavaScript() async {
    if (_customScript != null) {
      try {
        await _controller.runJavaScript(_customScript!);
      } catch (e) {
        debugPrint('Error injecting JavaScript: $e');
      }
    }
  }
}
