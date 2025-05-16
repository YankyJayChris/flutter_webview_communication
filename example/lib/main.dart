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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      themeMode: ThemeMode.system,
      home: const WebViewDemo(),
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
            _showSnackBar('Received: ${payload['text']}');
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
          _showSnackBar('JavaScript Error: $error');
        },
      );
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    }
  }

  void _showSnackBar(String message) {
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(8),
      ),
    );
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

  void _saveToLocalStorage() async {
    if (_formKey.currentState!.validate()) {
      await webViewPlugin.saveToLocalStorage(
        key: _keyController.text,
        value: _valueController.text,
      );
      _showSnackBar('Saved: ${_keyController.text} = ${_valueController.text}');
      _keyController.clear();
      _valueController.clear();
    }
  }

  void _removeFromLocalStorage() async {
    if (_keyController.text.isNotEmpty) {
      await webViewPlugin.removeFromLocalStorage(
        key: _keyController.text,
      );
      webViewPlugin.sendToWebView(
        action: 'removeResponse',
        payload: {'key': _keyController.text},
      );
      _showSnackBar('Removed: ${_keyController.text}');
      _keyController.clear();
      _valueController.clear();
    } else {
      _showSnackBar('Please enter a key to remove');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('WebView Communication'),
          centerTitle: true,
          elevation: 0,
          actions: [
            Switch(
              value: useUrl,
              onChanged: (value) {
                setState(() {
                  useUrl = value;
                });
              },
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(useUrl ? 'URL' : 'HTML'),
            ),
          ],
        ),
        body: errorMessage != null ? _buildErrorView() : _buildMainContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                'Error',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    return Column(
      children: [
        _buildUrlInput(),
        _buildLoadingIndicator(),
        Expanded(
          child: Stack(
            children: [
              webViewPlugin.buildWebView(
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
              if (loadingState == 'loading' && loadingProgress != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withOpacity(0.2),
                    child: Center(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                value: loadingProgress! / 100,
                              ),
                              const SizedBox(height: 16),
                              Text('Loading: $loadingProgress%'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        _buildControlPanel(),
      ],
    );
  }

  Widget _buildUrlInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _urlController,
        decoration: InputDecoration(
          hintText: 'Enter URL',
          prefixIcon: const Icon(Icons.link),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          filled: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          suffixIcon: IconButton(
            icon: const Icon(Icons.send),
            onPressed: _loadUrl,
            tooltip: 'Load URL',
          ),
        ),
        onSubmitted: (value) => _loadUrl(),
        enabled: errorMessage == null,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(
                _getLoadingStateIcon(),
                color: _getLoadingStateColor(),
              ),
              const SizedBox(width: 12),
              Text(
                'Status: ${_getFormattedLoadingState()}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getLoadingStateColor(),
                ),
              ),
              const Spacer(),
              if (loadingProgress != null && loadingState == 'loading')
                Text('$loadingProgress%'),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getLoadingStateIcon() {
    switch (loadingState) {
      case 'loading':
        return Icons.hourglass_top;
      case 'success':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getLoadingStateColor() {
    switch (loadingState) {
      case 'loading':
        return Colors.orange;
      case 'success':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getFormattedLoadingState() {
    switch (loadingState) {
      case 'loading':
        return 'Loading';
      case 'success':
        return 'Loaded';
      case 'error':
        return 'Error';
      default:
        return 'Idle';
    }
  }

  Widget _buildControlPanel() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.storage), text: 'Local Storage'),
                Tab(icon: Icon(Icons.web), text: 'WebView Controls'),
              ],
              labelStyle: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  _buildLocalStorageTab(),
                  _buildWebViewControlsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalStorageTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            TextFormField(
              controller: _keyController,
              decoration: InputDecoration(
                labelText: 'Key',
                prefixIcon: const Icon(Icons.key),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a key';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                prefixIcon: const Icon(Icons.text_fields),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a value';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveToLocalStorage,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _removeFromLocalStorage,
                    icon: const Icon(Icons.delete),
                    label: const Text('Remove'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                final storage = await webViewPlugin.getLocalStorage();
                _showSnackBar('Local Storage: ${storage.toString()}');
              },
              icon: const Icon(Icons.list),
              label: const Text('Show All Storage'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                minimumSize: const Size(double.infinity, 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebViewControlsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildControlButton(
            'Send Message to WebView',
            Icons.send,
            () {
              webViewPlugin.sendToWebView(
                action: 'updateContent',
                payload: {
                  'text': 'Hello from Flutter at ${DateTime.now()}',
                },
              );
            },
          ),
          _buildControlButton(
            'Get Scroll Position',
            Icons.straighten,
            () async {
              final position = await webViewPlugin.getScrollPosition();
              _showSnackBar(
                  'Scroll Position: x=${position['x']}, y=${position['y']}');
            },
          ),
          _buildControlButton(
            'Reload WebView',
            Icons.refresh,
            () async {
              await webViewPlugin.reload();
              _showSnackBar('Reloaded WebView');
            },
          ),
          _buildControlButton(
            'Clear WebView Data',
            Icons.cleaning_services,
            () async {
              await webViewPlugin.clearWebViewData();
              _showSnackBar('Cleared WebView data');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
      String label, IconData icon, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        minimumSize: const Size(double.infinity, 0),
      ),
    );
  }
}
