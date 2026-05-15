# Migration Guide

This guide helps you migrate from older versions of flutter_webview_communication to the latest version.

---

## Migrating from v0.1.x to v0.3.0

### Overview

Version 0.3.0 introduces **60+ new methods** and significantly expands the package's capabilities. The good news: **all existing code remains compatible!** This is a non-breaking update with only additions.

### What's New

- **26 new methods** in v0.2.0 (navigation, zoom, cookies, scroll, find)
- **33 new methods** in v0.3.0 (channels, console, metadata, interaction, security, monitoring)
- Enhanced error handling
- Better debugging capabilities
- Comprehensive documentation

### Breaking Changes

**None!** All v0.1.x code will continue to work without modifications.

---

## New Features You Can Adopt

### 1. Navigation Controls (v0.2.0+)

**Before (v0.1.x):**

```dart
// No built-in navigation controls
// Had to reload entire page or use JavaScript
```

**After (v0.2.0+):**

```dart
// Navigate back/forward
await webViewPlugin.goBack();
await webViewPlugin.goForward();

// Check navigation state
bool canGoBack = await webViewPlugin.canGoBack();

// Get current URL and title
String? url = await webViewPlugin.getCurrentUrl();
String? title = await webViewPlugin.getTitle();
```

---

### 2. Zoom Controls (v0.2.0+)

**Before (v0.1.x):**

```dart
// No zoom control
```

**After (v0.2.0+):**

```dart
// Enable/disable zoom
await webViewPlugin.setZoomEnabled(true);

// Zoom in/out
await webViewPlugin.zoomIn();
await webViewPlugin.zoomOut();

// Set specific zoom level
await webViewPlugin.setZoomLevel(1.5); // 150%
```

---

### 3. Enhanced Cookie Management (v0.2.0+)

**Before (v0.1.x):**

```dart
// Only clearWebViewData() available
await webViewPlugin.clearWebViewData();
```

**After (v0.2.0+):**

```dart
// Get specific cookie
String? value = await webViewPlugin.getCookie('session', 'https://example.com');

// Set cookie with options
await webViewPlugin.setCookie(
  name: 'user',
  value: 'john',
  domain: 'example.com',
  path: '/',
);

// Check if cookies exist
bool hasCookies = await webViewPlugin.hasCookies();

// Get all cookies
Map<String, String> cookies = await webViewPlugin.getAllCookies();
```

---

### 4. Advanced Scroll Controls (v0.2.0+)

**Before (v0.1.x):**

```dart
// Only getScrollPosition() available
Map<String, double> pos = await webViewPlugin.getScrollPosition();
```

**After (v0.2.0+):**

```dart
// Scroll to specific position
await webViewPlugin.scrollTo(0, 500, smooth: true);

// Scroll by offset
await webViewPlugin.scrollBy(0, 100, smooth: true);

// Convenience methods
await webViewPlugin.scrollToTop();
await webViewPlugin.scrollToBottom();
```

---

### 5. Find in Page (v0.2.0+)

**New Feature:**

```dart
// Find text in page
int matches = await webViewPlugin.findInPage('search term');

// Navigate through matches
await webViewPlugin.findNext();
await webViewPlugin.findPrevious();

// Get match info
Map<String, int> info = webViewPlugin.getFindMatchInfo();
print('Match ${info['current']} of ${info['total']}');

// Clear highlights
await webViewPlugin.clearFindMatches();
```

---

### 6. JavaScript Channel Management (v0.3.0+)

**Before (v0.1.x):**

```dart
// Channels set up in constructor only
WebViewPlugin(
  actionHandlers: {
    'myAction': (payload) => print(payload),
  },
);
```

**After (v0.3.0+):**

```dart
// Add channels dynamically
webViewPlugin.addJavaScriptChannel('MyChannel', (message) {
  print('Received: ${message.message}');
});

// Remove channels
webViewPlugin.removeJavaScriptChannel('MyChannel');

// List all channels
List<String> channels = webViewPlugin.listJavaScriptChannels();

// Check if channel exists
bool exists = webViewPlugin.hasJavaScriptChannel('MyChannel');
```

---

### 7. Console Message Capture (v0.3.0+)

**New Feature:**

```dart
// Enable console capture
webViewPlugin.enableConsoleCapture();

// Get captured messages
List<String> messages = webViewPlugin.getConsoleMessages();
messages.forEach(print);

// Clear messages
webViewPlugin.clearConsoleMessages();
```

---

### 8. Page Metadata Extraction (v0.3.0+)

**New Feature:**

```dart
// Get comprehensive metadata
Map<String, String?> metadata = await webViewPlugin.getPageMetadata();
print('Title: ${metadata['title']}');
print('Description: ${metadata['description']}');

// Get all links
List<Map<String, String>> links = await webViewPlugin.getPageLinks();
for (var link in links) {
  print('${link['text']}: ${link['href']}');
}

// Get all images
List<Map<String, String>> images = await webViewPlugin.getPageImages();

// Get HTML content
String html = await webViewPlugin.getPageHtml();

// Get text content (no HTML)
String text = await webViewPlugin.getPageText();
```

---

### 9. Element Interaction (v0.3.0+)

**New Feature:**

```dart
// Inject custom CSS
await webViewPlugin.injectCSS('body { background: red; }', id: 'my-style');

// Remove injected CSS
await webViewPlugin.removeInjectedCSS('my-style');

// Click element
bool clicked = await webViewPlugin.clickElement('#submit-button');

// Set input value
await webViewPlugin.setInputValue('#username', 'john');

// Get input value
String? value = await webViewPlugin.getInputValue('#username');

// Check if element exists
bool exists = await webViewPlugin.elementExists('.my-class');

// Count elements
int count = await webViewPlugin.countElements('div');

// Scroll element into view
await webViewPlugin.scrollElementIntoView('#target', smooth: true);
```

---

### 10. Security & URL Filtering (v0.3.0+)

**New Feature:**

```dart
// Set URL whitelist
webViewPlugin.setAllowedUrls([
  'https://example.com/*',
  'https://trusted-site.com/*',
]);

// Set URL blacklist
webViewPlugin.setBlockedUrls([
  'https://malicious-site.com/*',
  '*/ads/*',
]);

// Custom validator
webViewPlugin.setUrlValidator((url) {
  return url.startsWith('https://');
});

// Check if URL is allowed
bool allowed = webViewPlugin.isUrlAllowed('https://example.com/page');

// Clear restrictions
webViewPlugin.clearUrlRestrictions();
```

---

### 11. Performance Monitoring (v0.3.0+)

**New Feature:**

```dart
// Get performance metrics
Map<String, dynamic> metrics = await webViewPlugin.getPerformanceMetrics();
print('Total load time: ${metrics['totalLoadTime']}ms');
print('DNS time: ${metrics['dnsTime']}ms');

// Get memory usage
Map<String, int>? memory = await webViewPlugin.getMemoryUsage();
if (memory != null) {
  print('Used: ${memory['usedJSHeapSize']} bytes');
}

// Get resource count
Map<String, int> resources = await webViewPlugin.getResourceCount();
print('Total resources: ${resources['total']}');
print('Scripts: ${resources['script']}');
print('Images: ${resources['img']}');
```

---

### 12. Network Monitoring (v0.3.0+)

**New Feature:**

```dart
// Enable network monitoring
webViewPlugin.enableNetworkMonitoring();

// Network requests will be logged to console
// Check console messages for network activity
```

---

### 13. Lifecycle Management (v0.2.0+)

**Before (v0.1.x):**

```dart
// No explicit disposal
```

**After (v0.2.0+):**

```dart
@override
void dispose() {
  webViewPlugin.dispose(); // Clean up resources
  super.dispose();
}
```

---

## Recommended Migration Path

### Step 1: Update Dependencies

Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter_webview_communication: ^0.3.0
```

Run:

```bash
flutter pub get
```

### Step 2: Test Existing Code

Your existing code should work without changes. Test thoroughly:

```bash
flutter test
flutter run
```

### Step 3: Adopt New Features Gradually

Start with the most useful features for your use case:

1. **Navigation controls** - If users need back/forward
2. **Find in page** - If users need to search content
3. **Console capture** - For debugging
4. **Performance monitoring** - For optimization
5. **Security filtering** - For production apps

### Step 4: Add Disposal

Add proper cleanup in your widgets:

```dart
@override
void dispose() {
  webViewPlugin.dispose();
  super.dispose();
}
```

---

## Common Migration Scenarios

### Scenario 1: Adding Navigation

**Before:**

```dart
// No navigation controls
```

**After:**

```dart
AppBar(
  actions: [
    IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () async {
        if (await webViewPlugin.canGoBack()) {
          await webViewPlugin.goBack();
        }
      },
    ),
    IconButton(
      icon: Icon(Icons.arrow_forward),
      onPressed: () async {
        if (await webViewPlugin.canGoForward()) {
          await webViewPlugin.goForward();
        }
      },
    ),
  ],
)
```

---

### Scenario 2: Adding Search

**Before:**

```dart
// No search functionality
```

**After:**

```dart
TextField(
  onSubmitted: (query) async {
    int matches = await webViewPlugin.findInPage(query);
    setState(() {
      _searchResults = 'Found $matches matches';
    });
  },
)

// Navigation buttons
Row(
  children: [
    IconButton(
      icon: Icon(Icons.arrow_upward),
      onPressed: () => webViewPlugin.findPrevious(),
    ),
    IconButton(
      icon: Icon(Icons.arrow_downward),
      onPressed: () => webViewPlugin.findNext(),
    ),
  ],
)
```

---

### Scenario 3: Adding Security

**Before:**

```dart
// No URL filtering
```

**After:**

```dart
@override
void initState() {
  super.initState();

  webViewPlugin = WebViewPlugin(
    enableCommunication: true,
    actionHandlers: {...},
  );

  // Set up security
  webViewPlugin.setAllowedUrls([
    'https://myapp.com/*',
    'https://api.myapp.com/*',
  ]);
}
```

---

### Scenario 4: Adding Debugging

**Before:**

```dart
// Limited debugging
```

**After:**

```dart
@override
void initState() {
  super.initState();

  webViewPlugin = WebViewPlugin(
    enableCommunication: true,
    actionHandlers: {...},
    onJavaScriptError: (error) {
      print('JS Error: $error');
    },
  );

  // Enable console capture
  webViewPlugin.enableConsoleCapture();

  // Enable network monitoring
  webViewPlugin.enableNetworkMonitoring();
}

// View captured messages
void _showDebugInfo() {
  List<String> messages = webViewPlugin.getConsoleMessages();
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Console Messages'),
      content: SingleChildScrollView(
        child: Text(messages.join('\n')),
      ),
    ),
  );
}
```

---

## Performance Considerations

### Memory Management

**Always dispose:**

```dart
@override
void dispose() {
  webViewPlugin.dispose();
  super.dispose();
}
```

### Monitoring Performance

```dart
// Check performance periodically
Timer.periodic(Duration(seconds: 30), (timer) async {
  Map<String, int>? memory = await webViewPlugin.getMemoryUsage();
  if (memory != null && memory['usedJSHeapSize']! > 100000000) {
    print('Warning: High memory usage');
  }
});
```

---

## Troubleshooting

### Issue: Methods not available

**Solution:** Ensure you're using v0.3.0+

```bash
flutter pub get
flutter clean
flutter pub get
```

### Issue: Navigation not working

**Solution:** Check if navigation is possible

```dart
bool canGoBack = await webViewPlugin.canGoBack();
if (canGoBack) {
  await webViewPlugin.goBack();
} else {
  print('Cannot go back');
}
```

### Issue: Console capture not working

**Solution:** Enable it after WebView is created

```dart
webViewPlugin.buildWebView(...);
webViewPlugin.enableConsoleCapture();
```

### Issue: URL filtering not working

**Solution:** Set up before loading content

```dart
webViewPlugin.setAllowedUrls([...]);
// Then load content
webViewPlugin.buildWebView(...);
```

---

## Best Practices

### 1. Always Dispose

```dart
@override
void dispose() {
  webViewPlugin.dispose();
  super.dispose();
}
```

### 2. Handle Errors

```dart
try {
  await webViewPlugin.goBack();
} catch (e) {
  print('Navigation error: $e');
}
```

### 3. Check Capabilities

```dart
if (await webViewPlugin.canGoBack()) {
  await webViewPlugin.goBack();
}
```

### 4. Use Security Features

```dart
webViewPlugin.setAllowedUrls([
  'https://trusted-domain.com/*',
]);
```

### 5. Monitor Performance

```dart
Map<String, dynamic> metrics = await webViewPlugin.getPerformanceMetrics();
if (metrics['totalLoadTime'] > 5000) {
  print('Slow page load detected');
}
```

---

## Getting Help

- **Documentation:** [README.md](../README.md)
- **API Reference:** [Full API documentation](../README.md#api)
- **Examples:** [example/](../example/)
- **Issues:** [GitHub Issues](https://github.com/YankyJayChris/flutter_webview_communication/issues)

---

## Summary

- ✅ **No breaking changes** - existing code works as-is
- ✅ **60+ new methods** available to adopt
- ✅ **Gradual migration** - adopt features as needed
- ✅ **Backward compatible** - v0.1.x code runs on v0.3.0

**Recommendation:** Update to v0.3.0 and gradually adopt new features that benefit your use case.

---

**Happy migrating!** 🚀
