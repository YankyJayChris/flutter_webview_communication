# 🌟 Best Practices Guide

Guidelines for using flutter_webview_communication effectively and securely.

---

## Table of Contents

1. [Security Best Practices](#security-best-practices)
2. [Performance Optimization](#performance-optimization)
3. [Error Handling](#error-handling)
4. [Memory Management](#memory-management)
5. [Communication Patterns](#communication-patterns)
6. [Testing Strategies](#testing-strategies)
7. [Production Checklist](#production-checklist)

---

## Security Best Practices

### 1. Always Use HTTPS in Production

❌ **Bad:**

```dart
webViewPlugin.buildWebView(
  content: 'http://example.com',  // Insecure!
  isUrl: true,
);
```

✅ **Good:**

```dart
webViewPlugin.buildWebView(
  content: 'https://example.com',  // Secure
  isUrl: true,
);
```

### 2. Implement URL Filtering

✅ **Whitelist approach (recommended):**

```dart
await webViewPlugin.setAllowedUrls([
  'https://myapp.com/*',
  'https://api.myapp.com/*',
]);
```

✅ **Blacklist approach:**

```dart
await webViewPlugin.setBlockedUrls([
  'https://ads.example.com/*',
  'https://tracker.example.com/*',
]);
```

✅ **Custom validator:**

```dart
await webViewPlugin.setUrlValidator((url) {
  // Only allow HTTPS
  if (!url.startsWith('https://')) return false;

  // Block specific domains
  if (url.contains('malicious.com')) return false;

  // Allow specific domains
  return url.contains('myapp.com') || url.contains('trusted.com');
});
```

### 3. Sanitize User Input

❌ **Bad:**

```dart
final html = '<div>${userInput}</div>';  // XSS vulnerability!
```

✅ **Good:**

```dart
String sanitizeHtml(String input) {
  return input
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;')
      .replaceAll('/', '&#x2F;');
}

final html = '<div>${sanitizeHtml(userInput)}</div>';
```

### 4. Use Content Security Policy

✅ **Strict CSP:**

```dart
webViewPlugin.buildWebView(
  content: html,
  isUrl: false,
  csp: "default-src 'self'; "
       "script-src 'self' 'unsafe-inline'; "
       "style-src 'self' 'unsafe-inline'; "
       "img-src 'self' https: data:; "
       "connect-src 'self' https://api.myapp.com;",
);
```

### 5. Validate Data from WebView

❌ **Bad:**

```dart
actionHandlers: {
  'updateUser': (payload) {
    // Directly use payload without validation
    updateUser(payload['id'], payload['name']);
  },
}
```

✅ **Good:**

```dart
actionHandlers: {
  'updateUser': (payload) {
    // Validate payload
    if (payload == null ||
        payload['id'] == null ||
        payload['name'] == null) {
      print('Invalid payload');
      return;
    }

    // Validate types
    if (payload['id'] is! int || payload['name'] is! String) {
      print('Invalid data types');
      return;
    }

    // Validate values
    if (payload['name'].toString().isEmpty) {
      print('Name cannot be empty');
      return;
    }

    updateUser(payload['id'], payload['name']);
  },
}
```

### 6. Clear Sensitive Data

✅ **Clear data on logout:**

```dart
Future<void> logout() async {
  await webViewPlugin.clearWebViewData();
  await webViewPlugin.clearCookies();
  await webViewPlugin.removeFromLocalStorage(key: 'authToken');
}
```

---

## Performance Optimization

### 1. Monitor Performance Metrics

✅ **Track performance:**

```dart
Future<void> checkPerformance() async {
  final metrics = await webViewPlugin.getPerformanceMetrics();
  final memory = await webViewPlugin.getMemoryUsage();

  print('Load time: ${metrics['loadTime']}ms');
  print('Memory: ${memory['usedJSHeapSize']} bytes');

  // Alert if performance is poor
  if (metrics['loadTime'] > 3000) {
    print('Warning: Slow page load');
  }

  if (memory['usedJSHeapSize'] > 50000000) {  // 50MB
    print('Warning: High memory usage');
  }
}
```

### 2. Lazy Load Content

✅ **Load content on demand:**

```dart
class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewPlugin webViewPlugin;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize only when needed
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    webViewPlugin = WebViewPlugin(enableCommunication: true);
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return CircularProgressIndicator();
    }
    return webViewPlugin.buildWebView(...);
  }
}
```

### 3. Optimize JavaScript Execution

❌ **Bad:**

```dart
// Executing multiple separate JavaScript calls
await webViewPlugin.clickElement('#button1');
await webViewPlugin.clickElement('#button2');
await webViewPlugin.clickElement('#button3');
```

✅ **Good:**

```dart
// Batch operations in single JavaScript execution
await webViewPlugin.runJavaScript('''
  document.querySelector('#button1').click();
  document.querySelector('#button2').click();
  document.querySelector('#button3').click();
''');
```

### 4. Cache Static Content

✅ **Use caching:**

```dart
class WebViewCache {
  static final Map<String, String> _cache = {};

  static Future<String> getContent(String key, Future<String> Function() loader) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }

    final content = await loader();
    _cache[key] = content;
    return content;
  }

  static void clear() {
    _cache.clear();
  }
}

// Usage
final html = await WebViewCache.getContent('homepage', () async {
  return await fetchHtmlFromServer();
});
```

### 5. Minimize DOM Manipulation

❌ **Bad:**

```javascript
// Multiple DOM updates
for (let i = 0; i < 100; i++) {
  document.body.appendChild(createDiv(i));
}
```

✅ **Good:**

```javascript
// Batch DOM updates
const fragment = document.createDocumentFragment();
for (let i = 0; i < 100; i++) {
  fragment.appendChild(createDiv(i));
}
document.body.appendChild(fragment);
```

---

## Error Handling

### 1. Always Use Try-Catch

❌ **Bad:**

```dart
await webViewPlugin.goBack();
```

✅ **Good:**

```dart
try {
  await webViewPlugin.goBack();
} catch (e) {
  print('Error going back: $e');
  // Handle error appropriately
  showErrorDialog('Cannot go back');
}
```

### 2. Implement Error Callbacks

✅ **Handle JavaScript errors:**

```dart
WebViewPlugin(
  enableCommunication: true,
  onJavaScriptError: (error) {
    print('JavaScript error: $error');

    // Log to analytics
    logError('webview_js_error', error);

    // Show user-friendly message
    showSnackBar('An error occurred. Please try again.');
  },
);
```

### 3. Validate Before Execution

✅ **Check state before actions:**

```dart
Future<void> navigateBack() async {
  try {
    final canBack = await webViewPlugin.canGoBack();
    if (canBack) {
      await webViewPlugin.goBack();
    } else {
      // Handle case where can't go back
      Navigator.pop(context);
    }
  } catch (e) {
    print('Navigation error: $e');
  }
}
```

### 4. Implement Retry Logic

✅ **Retry failed operations:**

```dart
Future<T?> retryOperation<T>(
  Future<T> Function() operation, {
  int maxAttempts = 3,
  Duration delay = const Duration(seconds: 1),
}) async {
  for (int i = 0; i < maxAttempts; i++) {
    try {
      return await operation();
    } catch (e) {
      if (i == maxAttempts - 1) {
        print('Operation failed after $maxAttempts attempts: $e');
        return null;
      }
      await Future.delayed(delay);
    }
  }
  return null;
}

// Usage
final url = await retryOperation(() => webViewPlugin.getCurrentUrl());
```

---

## Memory Management

### 1. Always Dispose

✅ **Proper disposal:**

```dart
class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late WebViewPlugin webViewPlugin;

  @override
  void initState() {
    super.initState();
    webViewPlugin = WebViewPlugin(enableCommunication: true);
  }

  @override
  void dispose() {
    webViewPlugin.dispose();  // Always dispose!
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return webViewPlugin.buildWebView(...);
  }
}
```

### 2. Clear Data Periodically

✅ **Scheduled cleanup:**

```dart
class WebViewManager {
  Timer? _cleanupTimer;

  void startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(Duration(hours: 1), (_) async {
      await webViewPlugin.clearConsoleMessages();

      // Clear old cookies
      final cookies = await webViewPlugin.getAllCookies();
      // Remove expired cookies
    });
  }

  void dispose() {
    _cleanupTimer?.cancel();
    webViewPlugin.dispose();
  }
}
```

### 3. Limit Console Message Storage

✅ **Prevent memory bloat:**

```dart
Future<void> manageConsoleMessages() async {
  final messages = await webViewPlugin.getConsoleMessages();

  // Keep only recent messages
  if (messages.length > 100) {
    await webViewPlugin.clearConsoleMessages();
  }
}
```

---

## Communication Patterns

### 1. Use Type-Safe Messages

✅ **Define message types:**

```dart
enum MessageAction {
  updateUser,
  fetchData,
  navigate,
}

class Message {
  final MessageAction action;
  final Map<String, dynamic> payload;

  Message(this.action, this.payload);

  Map<String, dynamic> toJson() => {
    'action': action.toString().split('.').last,
    'payload': payload,
  };
}

// Usage
webViewPlugin.sendToWebView(
  action: MessageAction.updateUser.toString().split('.').last,
  payload: {'id': 1, 'name': 'John'},
);
```

### 2. Implement Request-Response Pattern

✅ **Track requests:**

```dart
class WebViewCommunicator {
  final Map<String, Completer<dynamic>> _pendingRequests = {};
  int _requestId = 0;

  Future<dynamic> request(String action, Map<String, dynamic> payload) {
    final id = (_requestId++).toString();
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    webViewPlugin.sendToWebView(
      action: action,
      payload: {'requestId': id, ...payload},
    );

    return completer.future.timeout(
      Duration(seconds: 10),
      onTimeout: () {
        _pendingRequests.remove(id);
        throw TimeoutException('Request timeout');
      },
    );
  }

  void handleResponse(String requestId, dynamic data) {
    final completer = _pendingRequests.remove(requestId);
    completer?.complete(data);
  }
}
```

### 3. Use Event Emitters

✅ **Implement pub-sub pattern:**

```dart
class WebViewEventBus {
  final Map<String, List<Function(dynamic)>> _listeners = {};

  void on(String event, Function(dynamic) callback) {
    _listeners.putIfAbsent(event, () => []).add(callback);
  }

  void off(String event, Function(dynamic) callback) {
    _listeners[event]?.remove(callback);
  }

  void emit(String event, dynamic data) {
    _listeners[event]?.forEach((callback) => callback(data));
  }
}

// Usage
final eventBus = WebViewEventBus();

eventBus.on('userUpdated', (data) {
  print('User updated: $data');
});

eventBus.emit('userUpdated', {'id': 1, 'name': 'John'});
```

---

## Testing Strategies

### 1. Unit Test Communication

✅ **Test message handling:**

```dart
void main() {
  test('WebView handles messages correctly', () async {
    bool messageReceived = false;

    final plugin = WebViewPlugin(
      enableCommunication: true,
      actionHandlers: {
        'test': (payload) {
          messageReceived = true;
          expect(payload['data'], equals('test'));
        },
      },
    );

    // Simulate message
    plugin.sendToWebView(
      action: 'test',
      payload: {'data': 'test'},
    );

    await Future.delayed(Duration(milliseconds: 100));
    expect(messageReceived, isTrue);
  });
}
```

### 2. Integration Testing

✅ **Test full flow:**

```dart
testWidgets('WebView loads and communicates', (tester) async {
  await tester.pumpWidget(MyApp());

  // Wait for WebView to load
  await tester.pumpAndSettle();

  // Find and tap button
  await tester.tap(find.byKey(Key('sendButton')));
  await tester.pump();

  // Verify message was sent
  expect(find.text('Message sent'), findsOneWidget);
});
```

### 3. Mock WebView for Testing

✅ **Create mock:**

```dart
class MockWebViewPlugin extends Mock implements WebViewPlugin {
  @override
  Future<String?> getCurrentUrl() async {
    return 'https://example.com';
  }

  @override
  Future<void> goBack() async {
    // Mock implementation
  }
}

// Usage in tests
final mockPlugin = MockWebViewPlugin();
when(mockPlugin.getCurrentUrl()).thenAnswer((_) async => 'https://test.com');
```

---

## Production Checklist

### Before Release

- [ ] **Security**
  - [ ] All URLs use HTTPS
  - [ ] URL filtering implemented
  - [ ] User input sanitized
  - [ ] CSP configured
  - [ ] Sensitive data cleared on logout

- [ ] **Performance**
  - [ ] Performance metrics monitored
  - [ ] Memory usage optimized
  - [ ] Lazy loading implemented
  - [ ] Cache strategy in place

- [ ] **Error Handling**
  - [ ] Try-catch blocks added
  - [ ] Error callbacks implemented
  - [ ] User-friendly error messages
  - [ ] Error logging configured

- [ ] **Memory Management**
  - [ ] Dispose called properly
  - [ ] Periodic cleanup scheduled
  - [ ] Memory leaks checked

- [ ] **Testing**
  - [ ] Unit tests written
  - [ ] Integration tests passed
  - [ ] Tested on iOS
  - [ ] Tested on Android
  - [ ] Edge cases covered

- [ ] **Documentation**
  - [ ] Code commented
  - [ ] README updated
  - [ ] API documented
  - [ ] Examples provided

---

## Code Review Checklist

When reviewing WebView code, check for:

1. ✅ Proper disposal in `dispose()` method
2. ✅ Error handling with try-catch
3. ✅ Input validation and sanitization
4. ✅ HTTPS usage in production
5. ✅ URL filtering configured
6. ✅ Performance monitoring
7. ✅ Memory management
8. ✅ Proper state management
9. ✅ User-friendly error messages
10. ✅ Security best practices followed

---

## Additional Resources

- [API Reference](API_REFERENCE.md)
- [Troubleshooting Guide](TROUBLESHOOTING.md)
- [Migration Guide](MIGRATION_GUIDE.md)
- [Quick Start](QUICK_START.md)

---

**Remember:** Security and performance should always be top priorities when working with WebViews!
