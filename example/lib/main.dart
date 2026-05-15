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
  final _urlController = TextEditingController(text: 'https://flutter.dev');
  final _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  String _currentUrl = '';
  String _pageTitle = '';
  bool _canGoBack = false;
  bool _canGoForward = false;

  final String sampleHtml = '''
    <div class="container">
      <h1>WebView Communication Demo</h1>
      <p id="message">Waiting for data...</p>
      
      <div class="section">
        <h2>Communication</h2>
        <button onclick="sendToFlutter('updateText', {text: 'Hello from WebView'})">
          Send to Flutter
        </button>
        <button onclick="sendToFlutter('getStorage', {key: 'userData'})">
          Get Local Storage
        </button>
      </div>
      
      <div class="section">
        <h2>Test Elements</h2>
        <input type="text" id="testInput" placeholder="Test input field" />
        <button id="testButton">Click Me</button>
        <p class="test-paragraph">Paragraph 1</p>
        <p class="test-paragraph">Paragraph 2</p>
        <p class="test-paragraph">Paragraph 3</p>
      </div>
      
      <div class="section">
        <h2>Images</h2>
        <img src="https://via.placeholder.com/150" alt="Test Image 1" />
        <img src="https://via.placeholder.com/150" alt="Test Image 2" />
      </div>
      
      <div class="section">
        <h2>Links</h2>
        <a href="https://flutter.dev">Flutter</a>
        <a href="https://dart.dev">Dart</a>
      </div>
      
      <div class="section" style="height: 500px;">
        <h2>Scroll Test Area</h2>
        <p>Scroll down to test scroll features...</p>
        <div style="height: 400px; background: linear-gradient(to bottom, #e3f2fd, #bbdefb);"></div>
      </div>
    </div>
  ''';

  final String sampleCss = '''
    <style>
      * {
        box-sizing: border-box;
      }
      body {
        margin: 0;
        padding: 0;
        font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      }
      .container {
        padding: 20px;
        max-width: 800px;
        margin: 0 auto;
      }
      .section {
        margin: 20px 0;
        padding: 15px;
        background: #f5f5f5;
        border-radius: 8px;
      }
      h1 {
        color: #1976d2;
        margin-top: 0;
      }
      h2 {
        color: #424242;
        font-size: 1.2em;
        margin-top: 0;
      }
      button {
        padding: 10px 20px;
        background-color: #1976d2;
        color: white;
        border: none;
        border-radius: 5px;
        cursor: pointer;
        margin: 5px;
        font-size: 14px;
      }
      button:hover {
        background-color: #1565c0;
      }
      input[type="text"] {
        padding: 8px 12px;
        border: 1px solid #ccc;
        border-radius: 4px;
        margin: 5px;
        font-size: 14px;
      }
      a {
        color: #1976d2;
        text-decoration: none;
        margin: 0 10px;
        font-weight: 500;
      }
      a:hover {
        text-decoration: underline;
      }
      img {
        margin: 10px;
        border-radius: 8px;
      }
      .test-paragraph {
        padding: 8px;
        margin: 5px 0;
        background: white;
        border-left: 3px solid #1976d2;
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
            try {
              await webViewPlugin.saveToLocalStorage(
                key: payload['key'],
                value: 'Sample Data at ${DateTime.now()}',
              );
              webViewPlugin.sendToWebView(
                action: 'saveResponse',
                payload: {'key': payload['key']},
              );
            } catch (e) {
              _showSnackBar('Storage error: Please load content first');
            }
          },
        },
        onJavaScriptError: (error) {
          setState(() {
            errorMessage = error;
          });
          _showSnackBar('JavaScript Error: $error');
        },
      );

      // Set up URL filtering for security demo
      webViewPlugin.setAllowedUrls([
        'about:blank',
        'https://flutter.dev/*',
        'https://dart.dev/*',
        'https://pub.dev/*',
        'https://flutter.dev/*',
      ]);

      // Enable console capture
      webViewPlugin.enableConsoleCapture();

      // Enable network monitoring
      webViewPlugin.enableNetworkMonitoring();
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
    webViewPlugin.dispose();
    super.dispose();
  }

  void _loadUrl() {
    setState(() {
      useUrl = true;
    });
    _updateNavigationState();
  }

  Future<void> _updateNavigationState() async {
    try {
      final url = await webViewPlugin.getCurrentUrl();
      final title = await webViewPlugin.getTitle();
      final canBack = await webViewPlugin.canGoBack();
      final canForward = await webViewPlugin.canGoForward();

      setState(() {
        _currentUrl = url ?? '';
        _pageTitle = title ?? '';
        _canGoBack = canBack;
        _canGoForward = canForward;
      });
    } catch (e) {
      // Ignore errors during state update
    }
  }

  void _saveToLocalStorage() async {
    if (_formKey.currentState!.validate()) {
      try {
        await webViewPlugin.saveToLocalStorage(
          key: _keyController.text,
          value: _valueController.text,
        );
        _showSnackBar(
            'Saved: ${_keyController.text} = ${_valueController.text}');
        _keyController.clear();
        _valueController.clear();
      } catch (e) {
        _showSnackBar('Error: Please load content first (HTML or URL)');
      }
    }
  }

  void _removeFromLocalStorage() async {
    if (_keyController.text.isNotEmpty) {
      try {
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
      } catch (e) {
        _showSnackBar('Error: Please load content first (HTML or URL)');
      }
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
                    : null, // Remove CSP for HTML content to allow inline scripts/styles
                onLoadingStateChanged: (state, progress, error) {
                  setState(() {
                    loadingState = state;
                    loadingProgress = progress;
                    if (error != null) {
                      errorMessage = error;
                    }
                  });
                  if (state == 'finished') {
                    _updateNavigationState();
                  }
                },
              ),
              if ((loadingState == 'started' || loadingState == 'progress') &&
                  loadingProgress != null)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.2),
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
      case 'started':
      case 'progress':
        return Icons.hourglass_top;
      case 'finished':
        return Icons.check_circle;
      case 'error':
        return Icons.error;
      default:
        return Icons.info;
    }
  }

  Color _getLoadingStateColor() {
    switch (loadingState) {
      case 'started':
      case 'progress':
        return Colors.orange;
      case 'finished':
        return Colors.green;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  String _getFormattedLoadingState() {
    switch (loadingState) {
      case 'started':
        return 'Starting';
      case 'progress':
        return 'Loading';
      case 'finished':
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
        length: 8,
        child: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabs: [
                Tab(icon: Icon(Icons.storage), text: 'Storage'),
                Tab(icon: Icon(Icons.navigation), text: 'Navigation'),
                Tab(icon: Icon(Icons.search), text: 'Find'),
                Tab(icon: Icon(Icons.code), text: 'Elements'),
                Tab(icon: Icon(Icons.security), text: 'Security'),
                Tab(icon: Icon(Icons.analytics), text: 'Monitoring'),
                Tab(icon: Icon(Icons.lock), text: 'Permissions'),
                Tab(icon: Icon(Icons.file_download), text: 'Files'),
              ],
              labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
            SizedBox(
              height: 280,
              child: TabBarView(
                children: [
                  _buildLocalStorageTab(),
                  _buildNavigationTab(),
                  _buildFindTab(),
                  _buildElementsTab(),
                  _buildSecurityTab(),
                  _buildMonitoringTab(),
                  _buildPermissionsTab(),
                  _buildFileHandlingTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocalStorageTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            if (loadingState != 'finished')
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Load HTML or URL content first',
                        style: TextStyle(color: Colors.blue[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
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
                try {
                  final storage = await webViewPlugin.getLocalStorage();
                  if (storage.isEmpty) {
                    _showSnackBar('Local Storage is empty');
                  } else {
                    _showSnackBar('Local Storage: ${storage.toString()}');
                  }
                } catch (e) {
                  _showSnackBar(
                      'Error: Please load content first (HTML or URL)');
                }
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

  Widget _buildNavigationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_pageTitle.isNotEmpty)
            Text(
              _pageTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (_currentUrl.isNotEmpty)
            Text(
              _currentUrl,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canGoBack
                      ? () async {
                          await webViewPlugin.goBack();
                          _updateNavigationState();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _canGoForward
                      ? () async {
                          await webViewPlugin.goForward();
                          _updateNavigationState();
                        }
                      : null,
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Forward'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await webViewPlugin.reload();
                    _showSnackBar('Reloaded');
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reload'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await webViewPlugin.stopLoading();
                    _showSnackBar('Stopped loading');
                  },
                  icon: const Icon(Icons.stop),
                  label: const Text('Stop'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await webViewPlugin.scrollToTop();
                    _showSnackBar('Scrolled to top');
                  },
                  icon: const Icon(Icons.vertical_align_top),
                  label: const Text('Top'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await webViewPlugin.scrollToBottom();
                    _showSnackBar('Scrolled to bottom');
                  },
                  icon: const Icon(Icons.vertical_align_bottom),
                  label: const Text('Bottom'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFindTab() {
    final searchController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              labelText: 'Search text',
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              suffixIcon: IconButton(
                icon: const Icon(Icons.search),
                onPressed: () async {
                  if (searchController.text.isNotEmpty) {
                    final count =
                        await webViewPlugin.findInPage(searchController.text);
                    final info = webViewPlugin.getFindMatchInfo();
                    if (count > 0) {
                      _showSnackBar(
                          'Found ${info['totalMatches']} matches (${info['currentMatch']}/${info['totalMatches']})');
                    } else {
                      _showSnackBar(
                          'No matches found for "${searchController.text}"');
                    }
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await webViewPlugin.findPrevious();
                    final info = webViewPlugin.getFindMatchInfo();
                    _showSnackBar(
                        'Match ${info['currentMatch']}/${info['totalMatches']}');
                  },
                  icon: const Icon(Icons.arrow_upward),
                  label: const Text('Previous'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await webViewPlugin.findNext();
                    final info = webViewPlugin.getFindMatchInfo();
                    _showSnackBar(
                        'Match ${info['currentMatch']}/${info['totalMatches']}');
                  },
                  icon: const Icon(Icons.arrow_downward),
                  label: const Text('Next'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: () async {
              await webViewPlugin.clearFindMatches();
              _showSnackBar('Cleared find matches');
            },
            icon: const Icon(Icons.clear),
            label: const Text('Clear'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () async {
              final metadata = await webViewPlugin.getPageMetadata();
              final links = await webViewPlugin.getPageLinks();
              final images = await webViewPlugin.getPageImages();
              final title = metadata['title'] ?? 'No title';
              _showSnackBar(
                  'Title: $title\nLinks: ${links.length}\nImages: ${images.length}');
            },
            icon: const Icon(Icons.info),
            label: const Text('Page Info'),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildElementsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildControlButton(
            'Click Test Button',
            Icons.touch_app,
            () async {
              await webViewPlugin.clickElement('#testButton');
              _showSnackBar('Clicked test button');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Set Input Value',
            Icons.edit,
            () async {
              await webViewPlugin.setInputValue(
                  '#testInput', 'Hello from Flutter!');
              _showSnackBar('Set input value');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Get Input Value',
            Icons.text_fields,
            () async {
              final value = await webViewPlugin.getInputValue('#testInput');
              _showSnackBar('Input value: $value');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Count Paragraphs',
            Icons.format_list_numbered,
            () async {
              final count =
                  await webViewPlugin.countElements('.test-paragraph');
              _showSnackBar('Found $count paragraphs');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Inject Custom CSS',
            Icons.style,
            () async {
              await webViewPlugin.injectCSS(
                  '.test-paragraph { background: #ffeb3b !important; }');
              _showSnackBar('Injected CSS');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Get Page Links',
            Icons.link,
            () async {
              final links = await webViewPlugin.getPageLinks();
              _showSnackBar('Found ${links.length} links');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildControlButton(
            'Check URL Allowed',
            Icons.check_circle,
            () {
              final url = _urlController.text;
              final allowed = webViewPlugin.isUrlAllowed(url);
              _showSnackBar('URL ${allowed ? 'allowed' : 'blocked'}: $url');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Block Example.com',
            Icons.block,
            () {
              webViewPlugin.setBlockedUrls(['https://example.com/*']);
              _showSnackBar('Blocked example.com');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Clear Restrictions',
            Icons.lock_open,
            () {
              webViewPlugin.clearUrlRestrictions();
              _showSnackBar('Cleared URL restrictions');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Get All Cookies',
            Icons.cookie,
            () async {
              final cookies = await webViewPlugin.getAllCookies();
              _showSnackBar('Found ${cookies.keys.length} cookies');
            },
          ),
          const SizedBox(height: 8),
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

  Widget _buildMonitoringTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildControlButton(
            'Performance Metrics',
            Icons.speed,
            () async {
              final metrics = await webViewPlugin.getPerformanceMetrics();
              final loadTime =
                  metrics['loadTime'] ?? metrics['totalLoadTime'] ?? 'N/A';
              final domReady = metrics['domContentLoaded'] ??
                  metrics['domContentLoadedTime'] ??
                  'N/A';
              _showSnackBar(
                  'Load Time: ${loadTime}ms\nDOM Ready: ${domReady}ms');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Memory Usage',
            Icons.memory,
            () async {
              final memory = await webViewPlugin.getMemoryUsage();
              if (memory != null) {
                _showSnackBar('Memory: ${memory['usedJSHeapSize'] ?? 0} bytes');
              } else {
                _showSnackBar('Memory info not available');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Resource Count',
            Icons.inventory,
            () async {
              final count = await webViewPlugin.getResourceCount();
              _showSnackBar('Resources loaded: $count');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Console Messages',
            Icons.terminal,
            () {
              final messages = webViewPlugin.getConsoleMessages();
              _showSnackBar('Console: ${messages.length} messages');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Clear Console',
            Icons.clear_all,
            () {
              webViewPlugin.clearConsoleMessages();
              _showSnackBar('Cleared console messages');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildControlButton(
            'Request Location',
            Icons.location_on,
            () async {
              final status = await webViewPlugin.requestGeolocationPermission();
              _showSnackBar('Location permission: ${status.name}');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Request Camera',
            Icons.camera_alt,
            () async {
              final status = await webViewPlugin.requestCameraPermission();
              _showSnackBar('Camera permission: ${status.name}');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Request Microphone',
            Icons.mic,
            () async {
              final status = await webViewPlugin.requestMicrophonePermission();
              _showSnackBar('Microphone permission: ${status.name}');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Request Storage',
            Icons.folder,
            () async {
              final status = await webViewPlugin.requestStoragePermission();
              _showSnackBar('Storage permission: ${status.name}');
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Check All Permissions',
            Icons.checklist,
            () async {
              final results = await webViewPlugin.checkMultiplePermissions([
                'location',
                'camera',
                'microphone',
                'storage',
              ]);
              final summary = results.entries
                  .map((e) => '${e.key}: ${e.value ? "✓" : "✗"}')
                  .join('\n');
              _showSnackBar('Permissions:\n$summary');
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

  Widget _buildFileHandlingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'File Handling',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Download Files',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Download Sample PDF',
            Icons.download,
            () async {
              try {
                final downloadsPath =
                    await webViewPlugin.getDownloadsDirectoryPath();
                if (downloadsPath != null) {
                  _showSnackBar('Starting download...');
                  final path = await webViewPlugin.downloadFile(
                    'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                    downloadsPath,
                    filename: 'sample.pdf',
                    onProgress: (received, total) {
                      if (total != -1) {
                        final progress = (received / total * 100).toInt();
                        debugPrint('Download progress: $progress%');
                      }
                    },
                  );
                  _showSnackBar('Downloaded to: $path');
                } else {
                  _showSnackBar('Could not get downloads directory');
                }
              } catch (e) {
                _showSnackBar('Download error: $e');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Download Sample Image',
            Icons.image,
            () async {
              try {
                final downloadsPath =
                    await webViewPlugin.getDownloadsDirectoryPath();
                if (downloadsPath != null) {
                  _showSnackBar('Starting download...');
                  final path = await webViewPlugin.downloadFile(
                    'https://via.placeholder.com/600',
                    downloadsPath,
                    filename: 'sample_image.png',
                    onProgress: (received, total) {
                      if (total != -1) {
                        final progress = (received / total * 100).toInt();
                        debugPrint('Download progress: $progress%');
                      }
                    },
                  );
                  _showSnackBar('Downloaded to: $path');
                } else {
                  _showSnackBar('Could not get downloads directory');
                }
              } catch (e) {
                _showSnackBar('Download error: $e');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Get Active Downloads',
            Icons.list,
            () {
              final downloads = webViewPlugin.getActiveDownloads();
              if (downloads.isEmpty) {
                _showSnackBar('No active downloads');
              } else {
                _showSnackBar('Active downloads:\n${downloads.join('\n')}');
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'Upload Files',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Pick Single File',
            Icons.file_upload,
            () async {
              final files = await webViewPlugin.pickFiles(allowMultiple: false);
              if (files.isEmpty) {
                _showSnackBar('No file selected');
              } else {
                _showSnackBar('Selected: ${files.first}');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Pick Multiple Files',
            Icons.file_copy,
            () async {
              final files = await webViewPlugin.pickFiles(allowMultiple: true);
              if (files.isEmpty) {
                _showSnackBar('No files selected');
              } else {
                _showSnackBar(
                    'Selected ${files.length} file(s):\n${files.join('\n')}');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Pick Images Only',
            Icons.photo_library,
            () async {
              final files = await webViewPlugin.pickFiles(
                allowMultiple: true,
                acceptTypes: ['jpg', 'jpeg', 'png', 'gif'],
              );
              if (files.isEmpty) {
                _showSnackBar('No images selected');
              } else {
                _showSnackBar('Selected ${files.length} image(s)');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Pick PDFs Only',
            Icons.picture_as_pdf,
            () async {
              final files = await webViewPlugin.pickFiles(
                allowMultiple: false,
                acceptTypes: ['pdf'],
              );
              if (files.isEmpty) {
                _showSnackBar('No PDF selected');
              } else {
                _showSnackBar('Selected: ${files.first}');
              }
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'File Information',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Get Downloads Directory',
            Icons.folder,
            () async {
              final path = await webViewPlugin.getDownloadsDirectoryPath();
              if (path != null) {
                _showSnackBar('Downloads directory:\n$path');
              } else {
                _showSnackBar('Could not get downloads directory');
              }
            },
          ),
          const SizedBox(height: 8),
          _buildControlButton(
            'Get MIME Types',
            Icons.info,
            () {
              final examples = {
                'document.pdf': webViewPlugin.getMimeType('document.pdf'),
                'image.jpg': webViewPlugin.getMimeType('image.jpg'),
                'video.mp4': webViewPlugin.getMimeType('video.mp4'),
                'audio.mp3': webViewPlugin.getMimeType('audio.mp3'),
                'archive.zip': webViewPlugin.getMimeType('archive.zip'),
              };
              final info = examples.entries
                  .map((e) => '${e.key}: ${e.value}')
                  .join('\n');
              _showSnackBar('MIME Types:\n$info');
            },
          ),
        ],
      ),
    );
  }
}
