// Copyright (c) 2025 [IGIHOZO Jean Christian]. All rights reserved.
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
  String loadingState = 'idle';
  int? loadingProgress;
  bool useUrl = false;
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _valueController = TextEditingController();
  final _urlController = TextEditingController(text: 'https://example.com');
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  final String sampleHtml = '''
    <div class="container">
      <h1>WebView Demo</h1>
      <p id="message">Waiting for data...</p>
      <button onclick="sendToFlutter('updateText', {text: 'Hello from WebView'})">
        Send to Flutter
      </button>
      <button onclick="sendToFlutter('getStorage', {key: 'userData'})">
        Get Local Storage
      </button>
    </div>
  ''';

  final String sampleCss = '''
    <style>
      .container {
        padding: 20px;
        text-align: center;
        overflow-y: auto;
        scroll-behavior: smooth;
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
        margin: 5px;
      }
    </style>
  ''';

  final String sampleScript = '''
    window.addEventListener('flutterData', (event) => {
      const data = event.detail;
      if (data.action === 'updateContent') {
        const p = document.createElement('p');
        p.textContent = data.payload.text || 'No text provided';
        document.body.appendChild(p);
      }
    });
    window.addEventListener('flutterData', (event) => {
      const data = event.detail;
      if (data.action === 'saveResponse') {
        const storedData = localStorage.getItem(data.payload.key) || 'No data';
        const p = document.createElement('p');
        p.textContent = 'Stored: ' + storedData;
        document.body.appendChild(p);
      }
    });
    window.addEventListener('flutterData', (event) => {
      const data = event.detail;
      if (data.action === 'removeResponse') {
        const p = document.createElement('p');
        p.textContent = 'Removed key: ' + data.payload.key;
        document.body.appendChild(p);
      }
    });
  ''';

  String get currentUrl => _urlController.text;

  @override
  void initState() {
    super.initState();
    try {
      webViewPlugin = WebViewPlugin(
        enableCommunication: true,
        actionHandlers: {
          'updateText': (payload) {
            _scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Received: ${payload['text']}')),
            );
            webViewPlugin.sendToWebView(
              action: 'updateContent',
              payload: {'text': 'Updated from Flutter: ${payload['text']}'},
            );
          },
          'getStorage': (payload) async {
            await webViewPlugin.saveToLocalStorage(
              key: payload['key'],
              value: 'Sample Data at ${DateTime.now()}',
            );
            webViewPlugin.sendToWebView(
              action: 'saveResponse',
              payload: {'key': payload['key']},
            );
          },
        },
        onJavaScriptError: (error) {
          setState(() {
            errorMessage = error;
          });
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('JavaScript Error: $error')),
          );
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _valueController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  void _loadUrl() {
    setState(() {
      useUrl = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: SizedBox(
            height: 40,
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Enter URL',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _loadUrl,
                  tooltip: 'Load URL',
                ),
              ),
              onSubmitted: (value) => _loadUrl(),
              enabled: errorMessage == null,
            ),
          ),
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
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Text(
                            'Loading State: $loadingState${loadingProgress != null ? ' ($loadingProgress%)' : ''}'),
                        const SizedBox(height: 10),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _keyController,
                                decoration: const InputDecoration(
                                  labelText: 'Key',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a key';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _valueController,
                                decoration: const InputDecoration(
                                  labelText: 'Value',
                                  border: OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a value';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_formKey.currentState!.validate()) {
                                        await webViewPlugin.saveToLocalStorage(
                                          key: _keyController.text,
                                          value: _valueController.text,
                                        );
                                        _scaffoldMessengerKey.currentState
                                            ?.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Saved: ${_keyController.text} = ${_valueController.text}'),
                                          ),
                                        );
                                        _keyController.clear();
                                        _valueController.clear();
                                      }
                                    },
                                    child: const Text('Save to Local Storage'),
                                  ),
                                  ElevatedButton(
                                    onPressed: () async {
                                      if (_keyController.text.isNotEmpty) {
                                        await webViewPlugin
                                            .removeFromLocalStorage(
                                          key: _keyController.text,
                                        );
                                        webViewPlugin.sendToWebView(
                                          action: 'removeResponse',
                                          payload: {'key': _keyController.text},
                                        );
                                        _scaffoldMessengerKey.currentState
                                            ?.showSnackBar(
                                          SnackBar(
                                            content: Text(
                                                'Removed: ${_keyController.text}'),
                                          ),
                                        );
                                        _keyController.clear();
                                        _valueController.clear();
                                      } else {
                                        _scaffoldMessengerKey.currentState
                                            ?.showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Please enter a key to remove'),
                                          ),
                                        );
                                      }
                                    },
                                    child:
                                        const Text('Remove from Local Storage'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: webViewPlugin.buildWebView(
                      content: useUrl ? currentUrl : sampleHtml,
                      isUrl: useUrl,
                      cssContent: useUrl ? null : sampleCss,
                      scriptContent: sampleScript,
                      userAgent: 'WebViewDemo/1.0',
                      csp: useUrl
                          ? null
                          : "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
                      onLoadingStateChanged: (state, progress, error) {
                        setState(() {
                          loadingState = state;
                          loadingProgress = progress;
                          if (error != null) {
                            errorMessage = error;
                          }
                        });
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Wrap(
                      spacing: 8.0,
                      runSpacing: 8.0,
                      alignment: WrapAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            webViewPlugin.sendToWebView(
                              action: 'updateContent',
                              payload: {
                                'text':
                                    'Hello from Flutter at ${DateTime.now()}',
                              },
                            );
                          },
                          child: const Text('Send to WebView'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final storage =
                                await webViewPlugin.getLocalStorage();
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Local Storage: ${storage.toString()}'),
                              ),
                            );
                          },
                          child: const Text('Get Local Storage'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await webViewPlugin.clearWebViewData();
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(
                                content: Text('Cleared WebView data'),
                              ),
                            );
                          },
                          child: const Text('Clear WebView Data'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            await webViewPlugin.reload();
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(
                                content: Text('Reloaded WebView'),
                              ),
                            );
                          },
                          child: const Text('Reload WebView'),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            final position =
                                await webViewPlugin.getScrollPosition();
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              SnackBar(
                                content: Text(
                                    'Scroll Position: x=${position['x']}, y=${position['y']}'),
                              ),
                            );
                          },
                          child: const Text('Get Scroll Position'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
