// Copyright (c) 2025 [Your Name]. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter/material.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: WebViewDemo(),
    );
  }
}

class WebViewDemo extends StatefulWidget {
  const WebViewDemo({super.key});

  @override
  _WebViewDemoState createState() => _WebViewDemoState();
}

class _WebViewDemoState extends State<WebViewDemo> {
  late WebViewPlugin webViewPlugin;
  String? errorMessage;
  bool useUrl = false; // Toggle between URL and HTML

  final String sampleHtml = '''
    <div class="container">
      <h1>WebView Demo</h1>
      <p id="message">Waiting for data...</p>
      <button onclick="sendToFlutter('updateText', {text: 'Hello from WebView'})">
        Send to Flutter
      </button>
    </div>
  ''';

  final String sampleCss = '''
    <style>
      .container {
        padding: 20px;
        text-align: center;
      }
      h1 {
        color: #333;
      }
      button {
        padding: 10px 20px;
        background-color: #007bff;
        color: white;
        border: none;
        border-radius: 5px;
        cursor: pointer;
      }
    </style>
  ''';

  final String sampleScript = '''
    window.addEventListener('flutterData', (event) => {
      const data = event.detail;
      if (data.action === 'updateContent') {
        document.getElementById('message').innerText = 
          data.payload.text || 'No text provided';
      }
    });
  ''';

  final String sampleUrl = 'https://flutter.dev';

  @override
  void initState() {
    super.initState();
    try {
      webViewPlugin = WebViewPlugin(
        actionHandlers: {
          'updateText': (payload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received: ${payload['text']}')),
            );
            webViewPlugin.sendToWebView(
              action: 'updateContent',
              payload: {'text': 'Updated from Flutter: ${payload['text']}'},
            );
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
      appBar: AppBar(
        title: const Text('WebView Plugin Demo'),
        actions: [
          IconButton(
            icon: Icon(useUrl ? Icons.code : Icons.web),
            onPressed: () {
              setState(() {
                useUrl = !useUrl;
              });
            },
            tooltip: 'Toggle URL/HTML',
          ),
        ],
      ),
      body: errorMessage != null
          ? Center(child: Text(errorMessage!))
          : Column(
              children: [
                Expanded(
                  child: webViewPlugin.buildWebView(
                    content: useUrl ? sampleUrl : sampleHtml,
                    isUrl: useUrl,
                    cssContent: useUrl ? null : sampleCss,
                    scriptContent: useUrl ? null : sampleScript,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () {
                      webViewPlugin.sendToWebView(
                        action: 'updateContent',
                        payload: {
                          'text': 'Hello from Flutter at ${DateTime.now()}',
                        },
                      );
                    },
                    child: const Text('Send to WebView'),
                  ),
                ),
              ],
            ),
    );
  }
}
