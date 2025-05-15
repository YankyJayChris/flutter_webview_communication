# flutter_webview_communication

A Flutter plugin for creating WebViews with seamless bi-directional communication between Flutter and JavaScript, built on top of the `webview_flutter` package (version 4.8.0).

![Demo of flutter_webview_communication in action](demo.gif)

## Table of Contents
- [Features](#features)
- [Platform Support](#platform-support)
- [Installation](#installation)
- [Usage](#usage)
  - [Basic Example (HTML Content with Local Storage)](#basic-example-html-content-with-local-storage)
  - [URL Example with JavaScript Injection](#url-example-with-javascript-injection)
  - [Simple Example](#simple-example)
- [API](#api)
  - [WebViewPlugin](#webviewplugin)
  - [JavaScript API](#javascript-api)
- [Platform-Specific Features](#platform-specific-features)
- [Debugging Tips](#debugging-tips)

## Features
- Load custom HTML content or external URLs.
- Inject custom CSS (for HTML content) and JavaScript (embedded for HTML, injected post-load for URLs).
- Bi-directional JSON-based communication between Flutter and WebView with action-based message handling.
- Manage WebView local storage: save, retrieve, remove, and clear key-value pairs.
- Apply Content Security Policy (CSP) to custom HTML for enhanced security.
- Set custom user agent strings for WebView requests.
- Monitor loading states (started, progress, finished, error) with progress percentages and HTTP error details.
- Retrieve the current scroll position of the WebView using JavaScript.
- Clear cookies, cache, and local storage with a single method.
- Reload the current WebView content (HTML or URL).
- Comprehensive JavaScript error handling via a callback.
- Cross-platform support with minimal dependencies.

## Platform Support
| Platform | Support Status | Notes |
|----------|----------------|-------|
| Android  | Fully supported | Requires `minSdkVersion 19` and `INTERNET` permission. |
| iOS      | Fully supported | No additional configuration required. |
| macOS    | Partially supported | Background color not supported. |
| Web      | Not supported  | Throws `Exception` due to lack of native WebView. |
| Windows  | Not supported  | |
| Linux    | Not supported  | |

## Installation
Add the following to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_webview_communication: ^0.1.4
```

Run `flutter pub get` to install the package.

### Platform Setup
- **Android**: Ensure the minimum SDK version is set in `android/app/build.gradle`:
  ```yaml
  android {
      defaultConfig {
          minSdkVersion 19
      }
  }
  ```
  Add the `INTERNET` permission in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" />
  ```
- **iOS**: No additional configuration required.
- **macOS**: Ensure macOS is enabled in your Flutter project (e.g., via `flutter create --platforms=macos`).

## Usage

### Basic Example (HTML Content with Local Storage)
This example loads HTML content, handles messages, manages local storage, retrieves scroll position, and monitors loading states.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late WebViewPlugin webViewPlugin;
  String? errorMessage;
  String loadingState = 'idle';
  int? loadingProgress;

  @override
  void initState() {
    super.initState();
    try {
      webViewPlugin = WebViewPlugin(
        enableCommunication: true,
        actionHandlers: {
          'update': (payload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received: ${payload['text']}')),
            );
          },
        },
        onJavaScriptError: (error) {
          setState(() {
            errorMessage = error;
          });
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Loading: $loadingState${loadingProgress != null ? ' ($loadingProgress%)' : ''}'),
                ),
                Expanded(
                  child: webViewPlugin.buildWebView(
                    content: '''
                      <h1>Hello</h1>
                      <button onclick="sendToFlutter('update', {text: 'Hi'})">Click</button>
                    ''',
                    cssContent: '<style>h1 { color: blue; }</style>',
                    scriptContent: '''
                      window.addEventListener('flutterData', (e) => {
                        document.querySelector('h1').innerText = e.detail.payload.text;
                      });
                    ''',
                    csp: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'",
                    userAgent: 'MyApp/1.0',
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
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.sendToWebView(
                      action: 'update',
                      payload: {'text': 'Hello from Flutter'},
                    ),
            child: const Icon(Icons.send),
            tooltip: 'Send to WebView',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.saveToLocalStorage(
                      key: 'userData',
                      value: 'Saved from Flutter',
                    ),
            child: const Icon(Icons.save),
            tooltip: 'Save to Local Storage',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.removeFromLocalStorage(key: 'userData'),
            child: const Icon(Icons.delete),
            tooltip: 'Remove from Local Storage',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () async {
                    final storage = await webViewPlugin.getLocalStorage();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Storage: $storage')),
                      );
                    }
                  },
            child: const Icon(Icons.storage),
            tooltip: 'Get Local Storage',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () async {
                    final position = await webViewPlugin.getScrollPosition();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scroll: x=${position['x']}, y=${position['y']}')),
                      );
                    }
                  },
            child: const Icon(Icons.arrow_downward),
            tooltip: 'Get Scroll Position',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.clearWebViewData(),
            child: const Icon(Icons.clear),
            tooltip: 'Clear WebView Data',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.reload(),
            child: const Icon(Icons.refresh),
            tooltip: 'Reload WebView',
          ),
        ],
      ),
    );
  }
}
```

### URL Example with JavaScript Injection
This example loads a URL and injects JavaScript.

```dart
import 'package:flutter/material.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

class MyWidget extends StatefulWidget {
  const MyWidget({super.key});

  @override
  State<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends State<MyWidget> {
  late WebViewPlugin webViewPlugin;
  String? errorMessage;
  String loadingState = 'idle';
  int? loadingProgress;

  @override
  void initState() {
    super.initState();
    try {
      webViewPlugin = WebViewPlugin(
        enableCommunication: true,
        actionHandlers: {
          'update': (payload) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Received: ${payload['text']}')),
            );
          },
        },
        onJavaScriptError: (error) {
          setState(() {
            errorMessage = error;
          });
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
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('Loading: $loadingState${loadingProgress != null ? ' ($loadingProgress%)' : ''}'),
                ),
                Expanded(
                  child: webViewPlugin.buildWebView(
                    content: 'https://example.com',
                    isUrl: true,
                    scriptContent: '''
                      window.addEventListener('flutterData', (e) => {
                        const p = document.createElement('p');
                        p.textContent = e.detail.payload.text;
                        document.body.appendChild(p);
                      });
                      document.addEventListener('DOMContentLoaded', () => {
                        const btn = document.createElement('button');
                        btn.textContent = 'Send to Flutter';
                        btn.onclick = () => sendToFlutter('update', {text: 'From Web'});
                        document.body.appendChild(btn);
                      });
                    ''',
                    userAgent: 'MyApp/1.0',
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
              ],
            ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.sendToWebView(
                      action: 'update',
                      payload: {'text': 'Hello from Flutter'},
                    ),
            child: const Icon(Icons.send),
            tooltip: 'Send to WebView',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.saveToLocalStorage(
                      key: 'userData',
                      value: 'Saved at ${DateTime.now()}',
                    ),
            child: const Icon(Icons.save),
            tooltip: 'Save to Local Storage',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.removeFromLocalStorage(key: 'userData'),
            child: const Icon(Icons.delete),
            tooltip: 'Remove from Local Storage',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () async {
                    final storage = await webViewPlugin.getLocalStorage();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Storage: $storage')),
                      );
                    }
                  },
            child: const Icon(Icons.storage),
            tooltip: 'Get Local Storage',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () async {
                    final position = await webViewPlugin.getScrollPosition();
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Scroll: x=${position['x']}, y=${position['y']}')),
                      );
                    }
                  },
            child: const Icon(Icons.arrow_downward),
            tooltip: 'Get Scroll Position',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.clearWebViewData(),
            child: const Icon(Icons.clear),
            tooltip: 'Clear WebView Data',
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            onPressed: errorMessage != null
                ? null
                : () => webViewPlugin.reload(),
            child: const Icon(Icons.refresh),
            tooltip: 'Reload WebView',
          ),
        ],
      ),
    );
  }
}
```

### Simple Example
A minimal setup for quick integration.

```dart
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

final plugin = WebViewPlugin(
  enableCommunication: true,
  actionHandlers: {
    'update': (payload) => debugPrint('Received: $payload'),
  },
  onJavaScriptError: (error) => debugPrint('JS Error: $error'),
);

Widget webView = plugin.buildWebView(
  content: '<h1>Hello</h1>',
  cssContent: '<style>h1 { color: blue; }</style>',
  scriptContent: 'console.log("Loaded");',
  csp: "default-src 'self'; script-src 'self' 'unsafe-inline'",
  userAgent: 'MyApp/1.0',
  onLoadingStateChanged: (state, progress, error) => debugPrint('$state: $error'),
);

plugin.sendToWebView(action: 'update', payload: {'text': 'Hello'});
plugin.saveToLocalStorage(key: 'test', value: 'Simple data');
plugin.getLocalStorage().then((data) => debugPrint('Storage: $data'));
plugin.removeFromLocalStorage(key: 'test');
plugin.clearWebViewData();
plugin.getScrollPosition().then((pos) => debugPrint('Scroll: x=${pos['x']}, y=${pos['y']}'));
plugin.reload();
```

## API

### WebViewPlugin
- `WebViewPlugin({Map<String, Function(Map<String, dynamic>)?>? actionHandlers, bool enableCommunication = false, Function(String)? onJavaScriptError})`
  - Initializes the plugin with optional action handlers, communication script injection, and JavaScript error callback. Throws `Exception` on unsupported platforms (e.g., Web, Windows, Linux).
  - Parameters:
    - `actionHandlers`: Map of action names to handler functions for WebView messages.
    - `enableCommunication`: Enables injection of `sendToFlutter` and `receiveFromFlutter` scripts (default: `false`).
    - `onJavaScriptError`: Callback for JavaScript errors.
- `buildWebView({required String content, bool isUrl = false, String? cssContent, String? scriptContent, double? height, double? width, Color? backgroundColor, bool? enableCommunication, String? userAgent, String? csp, Function(String state, int? progress, String? error)? onLoadingStateChanged})`
  - Creates a WebView widget with the specified content (HTML or URL).
  - Parameters:
    - `content`: HTML string or URL.
    - `isUrl`: Treat `content` as a URL if `true` (default: `false`).
    - `cssContent`: CSS to include in `<head>` (HTML only).
    - `scriptContent`: JavaScript to embed (HTML) or inject post-load (URL).
    - `height`, `width`: Optional dimensions for the WebView.
    - `backgroundColor`: Background color (not supported on macOS).
    - `enableCommunication`: Overrides constructor’s setting for communication scripts.
    - `userAgent`: Custom user agent string.
    - `csp`: Content Security Policy for HTML content.
    - `onLoadingStateChanged`: Callback for loading states (`started`, `progress`, `finished`, `error`) with progress and error details.
- `sendToWebView({required dynamic payload, String? action})`
  - Sends JSON-serializable data to the WebView with an optional action identifier.
- `saveToLocalStorage({required String key, required dynamic value})`
  - Saves a key-value pair to the WebView’s local storage. The value is JSON-stringified.
- `removeFromLocalStorage({required String key})`
  - Removes a key from the WebView’s local storage.
- `getLocalStorage()`
  - Retrieves all key-value pairs from local storage, with JSON-decoded values where possible.
- `clearWebViewData()`
  - Clears cookies, cache, and local storage.
- `reload()`
  - Reloads the current WebView content (HTML or URL).
- `getScrollPosition()`
  - Returns the current scroll position as a `Map<String, double>` with `x` and `y` coordinates, using JavaScript.

### JavaScript API
- `sendToFlutter(action, payload)`
  - Sends a message to Flutter with an action string and payload object.
  - Example:
    ```javascript
    sendToFlutter('update', {text: 'Hello from Web'});
    ```
- `receiveFromFlutter(data)`
  - Handles data from Flutter, dispatched as a `flutterData` event.
  - Example:
    ```javascript
    window.addEventListener('flutterData', (e) => {
      console.log(e.detail); // {action: 'update', payload: {text: 'Hello'}}
    });
    ```

## Platform-Specific Features
For advanced features like auto-playing media, add platform-specific dependencies to `pubspec.yaml`:

```yaml
dependencies:
  webview_flutter_android: ^3.16.4
  webview_flutter_wkwebview: ^3.14.0
```

Configure platform-specific settings:

```dart
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

void configureWebView(WebViewPlugin plugin) {
  final controller = plugin.buildWebView(content: 'https://example.com', isUrl: true);
  if (controller.platform is AndroidWebViewController) {
    (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
  } else if (controller.platform is WebKitWebViewController) {
    (controller.platform as WebKitWebViewController).setAllowsInlineMediaPlayback(true);
  }
}
```

## Debugging Tips
- **Local Storage**: Use WebView developer tools (if available) to inspect `localStorage` and verify saved, retrieved, or cleared data.
- **Loading States**: Monitor `onLoadingStateChanged` outputs to track progress percentages and errors (e.g., HTTP or resource errors).
- **Scroll Position**: Verify `getScrollPosition` returns accurate `x`/`y` coordinates after scrolling.
- **JavaScript Errors**: Check `onJavaScriptError` logs for issues in injected scripts or communication.
- **Logs**: Review `debugPrint` outputs in the Flutter console for operation success or errors.
- **Platform Issues**: Ensure Android `INTERNET` permission is set and `minSdkVersion` is 19 or higher.

## Contributing
Contributions are welcome! Please submit issues or pull requests to the [GitHub repository](https://github.com/YankyJayChris/flutter_webview_communication).