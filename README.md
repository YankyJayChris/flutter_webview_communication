# flutter_webview_communication

A Flutter plugin for creating WebViews with bi-directional communication capabilities between Flutter and JavaScript, based on the `webview_flutter` package.

![Demo of flutter_webview_communication in action](demo.gif)

## Features
- Load custom HTML content or URLs
- Optional CSS styling (for HTML content)
- Custom JavaScript code injection (for HTML content)
- JSON-based bi-directional communication
- Action-based message handling
- Platform-specific WebView configurations (Android, iOS, macOS)

## Platform Support
This package supports the following platforms:
- **Android**: Fully supported with `webview_flutter_android`.
- **iOS**: Fully supported with `webview_flutter_wkwebview`.
- **macOS**: Supported with `webview_flutter_wkwebview`, but some features (e.g., background color) are not available.
- **Web, Windows, Linux**: Not supported due to reliance on native WebView implementations. Attempting to use the plugin on these platforms will throw an `Exception`.

## Installation
Add this to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_webview_communication: ^0.1.0
```
# Usage
## Basic Example (HTML Content)
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late WebViewPlugin webViewPlugin;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    try {
      webViewPlugin = WebViewPlugin(
        actionHandlers: {
          'update': (payload) {
            print('Received: ${payload['text']}');
          },
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: errorMessage != null
          ? Center(child: Text(errorMessage!))
          : webViewPlugin.buildWebView(
              content: '<h1>Hello</h1><button onclick="sendToFlutter(\'update\', {text: \'Hi\'})">Click</button>',
              cssContent: '<style>h1 { color: blue; }</style>',
              scriptContent: '''
                window.addEventListener('flutterData', (e) => {
                  document.querySelector('h1').innerText = e.detail.payload.text;
                });
              ''',
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: errorMessage != null
            ? null
            : () => webViewPlugin.sendToWebView(
                  action: 'update',
                  payload: {'text': 'Hello from Flutter'},
                ),
        child: Icon(Icons.send),
      ),
    );
  }
}
```

## Basic Example (URL)
```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late WebViewPlugin webViewPlugin;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    try {
      webViewPlugin = WebViewPlugin(
        actionHandlers: {
          'update': (payload) {
            print('Received: ${payload['text']}');
          },
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: errorMessage != null
          ? Center(child: Text(errorMessage!))
          : webViewPlugin.buildWebView(
              content: 'https://flutter.dev',
              isUrl: true,
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: errorMessage != null
            ? null
            : () => webViewPlugin.sendToWebView(
                  action: 'update',
                  payload: {'text': 'Hello from Flutter'},
                ),
        child: Icon(Icons.send),
      ),
    );
  }
}
```

## Alternative Simple Example
```dart
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

final plugin = WebViewPlugin(
  actionHandlers: {
    'update': (payload) => print(payload),
  },
);

Widget webView = plugin.buildWebView(
  htmlContent: '<h1>Hello</h1>',
  cssContent: '<style>h1 { color: blue; }</style>',
  scriptContent: 'console.log("Loaded");',
);

plugin.sendToWebView(action: 'update', payload: {'text': 'Hello'});
```

# API
## WebViewPlugin
- `WebViewPlugin({Map<String, Function(Map<String, dynamic>)?>? actionHandlers})`
  - Constructor with optional action handlers for WebView messages. Throws `Exception` on unsupported platforms.
- `buildWebView({required String content, bool isUrl = false, String? cssContent, String? scriptContent, double? height, double? width, Color? backgroundColor})`
  - Builds the WebView widget with the specified content (HTML or URL).
- `sendToWebView({required dynamic payload, String? action})`
  - Sends data to the WebView with an optional action identifier.

## JavaScript API
- `sendToFlutter(action, payload)` - Sends a message to Flutter.
- `receiveFromFlutter(data)` - Receives data from Flutter (dispatched as 'flutterData' event).
