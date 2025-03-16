// Copyright (c) 2025 [Your Name]. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

/// A plugin for creating WebViews with bi-directional communication capabilities.
class WebViewPlugin {
  late WebViewController _controller;
  final Map<String, Function(Map<String, dynamic>)> _actionHandlers;

  /// Creates a WebViewPlugin instance.
  ///
  /// [actionHandlers] - A map of action names to their handler functions that process
  /// messages received from the WebView. The handler receives a JSON payload.
  WebViewPlugin({
    Map<String, Function(Map<String, dynamic>)?>? actionHandlers,
  }) : _actionHandlers = actionHandlers?.map(
              (key, value) => MapEntry(key, value ?? ((_) {})),
            ) ??
            {} {
    _initializeController();
  }

  /// Builds and returns a WebView widget.
  ///
  /// [htmlContent] - The HTML content to display (required).
  /// [cssContent] - Optional CSS styles to include in the <head>.
  /// [scriptContent] - Optional JavaScript code to include in the page.
  /// [height] - Optional height of the WebView widget.
  /// [width] - Optional width of the WebView widget.
  /// [backgroundColor] - Optional background color for the WebView.
  Widget buildWebView({
    required String htmlContent,
    String? cssContent,
    String? scriptContent,
    double? height,
    double? width,
    Color? backgroundColor,
  }) {
    final String finalHtml = _buildHtml(htmlContent, cssContent, scriptContent);
    _loadHtmlContent(finalHtml);

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

  /// Initializes the WebViewController with platform-specific configurations.
  void _initializeController() {
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
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

    if (_controller.platform is AndroidWebViewController) {
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

  /// Loads the HTML content into the WebView.
  Future<void> _loadHtmlContent(String html) async {
    try {
      await _controller.loadHtmlString(html);
    } catch (e) {
      debugPrint('Error loading HTML content: $e');
    }
  }
}
