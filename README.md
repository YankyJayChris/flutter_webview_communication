# flutter_webview_communication

A Flutter plugin for creating WebViews with bi-directional communication capabilities between Flutter and JavaScript, based on the `webview_flutter` package.

## Features
- Custom HTML content rendering
- Optional CSS styling
- Custom JavaScript code injection
- JSON-based bi-directional communication
- Action-based message handling
- Platform-specific WebView configurations (Android & iOS)

## Installation
Add this to your `pubspec.yaml`:
```yaml
dependencies:
  flutter_webview_communication: ^0.1.0

# Usage
##Basic Example
```dart
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

class MyWidget extends StatefulWidget {
  @override
  _MyWidgetState createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late WebViewPlugin webViewPlugin;

  @override
  void initState() {
    super.initState();
    webViewPlugin = WebViewPlugin(
      actionHandlers: {
        'update': (payload) {
          print('Received: ${payload['text']}');
        },
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: webViewPlugin.buildWebView(
        htmlContent: '<h1>Hello</h1><button onclick="sendToFlutter(\'update\', {text: \'Hi\'})">Click</button>',
        cssContent: '<style>h1 { color: blue; }</style>',
        scriptContent: '''
          window.addEventListener('flutterData', (e) => {
            document.querySelector('h1').innerText = e.detail.payload.text;
          });
        ''',
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => webViewPlugin.sendToWebView(
          action: 'update',
          payload: {'text': 'Hello from Flutter'},
        ),
        child: Icon(Icons.send),
      ),
    );
  }
}

##Alternative Simple Example
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

#API
##WebViewPlugin
- **WebViewPlugin({Map<String, Function(Map<String, dynamic>)?>? actionHandlers})
 - Constructor with optional action handlers for WebView messages.
- **buildWebView({required String htmlContent, String? cssContent, String? scriptContent, double? height, double? width, Color? backgroundColor})
 - Builds the WebView widget with the specified content.
- **sendToWebView({required dynamic payload, String? action})
 - Sends data to the WebView with an optional action identifier.

##JavaScript API
- **sendToFlutter(action, payload) - Sends a message to Flutter.
- **receiveFromFlutter(data) - Receives data from Flutter (dispatched as 'flutterData' event).
