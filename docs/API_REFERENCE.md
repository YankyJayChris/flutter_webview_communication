# 📚 API Reference - flutter_webview_communication v0.3.0

Complete API documentation for all 70+ methods available in the package.

---

## Table of Contents

1. [Core Communication](#core-communication)
2. [Local Storage](#local-storage)
3. [Navigation Controls](#navigation-controls)
4. [Zoom Controls](#zoom-controls)
5. [Cookie Management](#cookie-management)
6. [Scroll Controls](#scroll-controls)
7. [Find in Page](#find-in-page)
8. [File Handling](#file-handling)
9. [JavaScript Channels](#javascript-channels)
10. [Console Capture](#console-capture)
11. [Page Metadata](#page-metadata)
12. [Element Interaction](#element-interaction)
13. [Security & URL Filtering](#security--url-filtering)
14. [Performance Monitoring](#performance-monitoring)
15. [Network Monitoring](#network-monitoring)
16. [Lifecycle Management](#lifecycle-management)

---

## Core Communication

### `sendToWebView({required String action, Map<String, dynamic>? payload})`

Send data from Flutter to WebView.

**Parameters:**

- `action` (String, required): Action identifier
- `payload` (Map, optional): Data to send

**Example:**

```dart
webViewPlugin.sendToWebView(
  action: 'updateContent',
  payload: {'text': 'Hello from Flutter'},
);
```

### `buildWebView({...})`

Build the WebView widget with configuration.

**Parameters:**

- `content` (String, required): HTML content or URL
- `isUrl` (bool, optional): Whether content is a URL (default: false)
- `cssContent` (String, optional): CSS to inject
- `scriptContent` (String, optional): JavaScript to inject
- `userAgent` (String, optional): Custom user agent
- `csp` (String, optional): Content Security Policy
- `onLoadingStateChanged` (Function, optional): Loading state callback

**Example:**

```dart
webViewPlugin.buildWebView(
  content: 'https://flutter.dev',
  isUrl: true,
  userAgent: 'MyApp/1.0',
  onLoadingStateChanged: (state, progress, error) {
    print('State: $state, Progress: $progress');
  },
);
```

### `reload()`

Reload the current page.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.reload();
```

---

## Local Storage

### `saveToLocalStorage({required String key, required String value})`

Save data to WebView's localStorage.

**Parameters:**

- `key` (String, required): Storage key
- `value` (String, required): Value to store

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.saveToLocalStorage(
  key: 'userData',
  value: 'John Doe',
);
```

### `getFromLocalStorage({required String key})`

Retrieve data from localStorage.

**Parameters:**

- `key` (String, required): Storage key

**Returns:** `Future<String?>` - Value or null if not found

**Example:**

```dart
final value = await webViewPlugin.getFromLocalStorage(key: 'userData');
print('Value: $value');
```

### `removeFromLocalStorage({required String key})`

Remove item from localStorage.

**Parameters:**

- `key` (String, required): Storage key

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.removeFromLocalStorage(key: 'userData');
```

### `getLocalStorage()`

Get all localStorage data.

**Returns:** `Future<Map<String, dynamic>>` - All key-value pairs

**Example:**

```dart
final storage = await webViewPlugin.getLocalStorage();
print('All storage: $storage');
```

---

## Navigation Controls

### `goBack()`

Navigate to previous page in history.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.goBack();
```

### `goForward()`

Navigate to next page in history.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.goForward();
```

### `canGoBack()`

Check if can navigate back.

**Returns:** `Future<bool>`

**Example:**

```dart
final canBack = await webViewPlugin.canGoBack();
if (canBack) {
  await webViewPlugin.goBack();
}
```

### `canGoForward()`

Check if can navigate forward.

**Returns:** `Future<bool>`

**Example:**

```dart
final canForward = await webViewPlugin.canGoForward();
```

### `getCurrentUrl()`

Get current page URL.

**Returns:** `Future<String?>` - Current URL or null

**Example:**

```dart
final url = await webViewPlugin.getCurrentUrl();
print('Current URL: $url');
```

### `getTitle()`

Get current page title.

**Returns:** `Future<String?>` - Page title or null

**Example:**

```dart
final title = await webViewPlugin.getTitle();
print('Page title: $title');
```

### `stopLoading()`

Stop loading the current page.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.stopLoading();
```

---

## Zoom Controls

### `setZoomEnabled(bool enabled)`

Enable or disable zoom functionality.

**Parameters:**

- `enabled` (bool, required): Whether to enable zoom

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setZoomEnabled(true);
```

### `zoomIn()`

Zoom in by 10%.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.zoomIn();
```

### `zoomOut()`

Zoom out by 10%.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.zoomOut();
```

### `setZoomLevel(double level)`

Set specific zoom level.

**Parameters:**

- `level` (double, required): Zoom level (0.5 to 3.0)

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setZoomLevel(1.5); // 150% zoom
```

### `getZoomLevel()`

Get current zoom level.

**Returns:** `Future<double>` - Current zoom level

**Example:**

```dart
final zoom = await webViewPlugin.getZoomLevel();
print('Zoom level: $zoom');
```

---

## Cookie Management

### `getCookie({required String name})`

Get specific cookie value.

**Parameters:**

- `name` (String, required): Cookie name

**Returns:** `Future<String?>` - Cookie value or null

**Example:**

```dart
final sessionId = await webViewPlugin.getCookie(name: 'sessionId');
```

### `setCookie({required String name, required String value, String? domain, String? path, int? maxAge})`

Set a cookie.

**Parameters:**

- `name` (String, required): Cookie name
- `value` (String, required): Cookie value
- `domain` (String, optional): Cookie domain
- `path` (String, optional): Cookie path
- `maxAge` (int, optional): Max age in seconds

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setCookie(
  name: 'sessionId',
  value: 'abc123',
  domain: '.example.com',
  path: '/',
  maxAge: 3600,
);
```

### `hasCookies()`

Check if any cookies exist.

**Returns:** `Future<bool>`

**Example:**

```dart
final hasCookies = await webViewPlugin.hasCookies();
```

### `getAllCookies()`

Get all cookies.

**Returns:** `Future<List<Map<String, String>>>` - List of cookies

**Example:**

```dart
final cookies = await webViewPlugin.getAllCookies();
for (var cookie in cookies) {
  print('${cookie['name']}: ${cookie['value']}');
}
```

### `clearCookies()`

Clear all cookies.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.clearCookies();
```

---

## Scroll Controls

### `scrollTo({required int x, required int y})`

Scroll to absolute position.

**Parameters:**

- `x` (int, required): Horizontal position
- `y` (int, required): Vertical position

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.scrollTo(x: 0, y: 500);
```

### `scrollBy({required int x, required int y})`

Scroll by relative amount.

**Parameters:**

- `x` (int, required): Horizontal offset
- `y` (int, required): Vertical offset

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.scrollBy(x: 0, y: 100); // Scroll down 100px
```

### `scrollToTop()`

Scroll to top of page.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.scrollToTop();
```

### `scrollToBottom()`

Scroll to bottom of page.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.scrollToBottom();
```

### `getScrollPosition()`

Get current scroll position.

**Returns:** `Future<Map<String, int>>` - Map with 'x' and 'y' keys

**Example:**

```dart
final position = await webViewPlugin.getScrollPosition();
print('X: ${position['x']}, Y: ${position['y']}');
```

---

## Find in Page

### `findInPage(String searchText)`

Search for text in page.

**Parameters:**

- `searchText` (String, required): Text to search

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.findInPage('Flutter');
```

### `findNext()`

Find next match.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.findNext();
```

### `findPrevious()`

Find previous match.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.findPrevious();
```

### `clearFindMatches()`

Clear find highlights.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.clearFindMatches();
```

### `getFindMatchInfo()`

Get find match information.

**Returns:** `Future<Map<String, int>>` - Map with 'currentMatch' and 'totalMatches'

**Example:**

```dart
final info = await webViewPlugin.getFindMatchInfo();
print('Match ${info['currentMatch']} of ${info['totalMatches']}');
```

---

## File Handling

### `downloadFile(String url, String savePath, {OnDownloadProgress? onProgress, String? filename})`

Downloads a file from a URL to the specified save path with optional progress tracking.

**Parameters:**

- `url` (String, required) - The URL of the file to download
- `savePath` (String, required) - The local directory path where the file should be saved
- `onProgress` (OnDownloadProgress?, optional) - Callback for download progress updates
- `filename` (String?, optional) - Custom filename (if not provided, extracted from URL)

**Returns:** `Future<String>` - The full path to the downloaded file

**Example:**

```dart
final downloadsPath = await webViewPlugin.getDownloadsDirectoryPath();
if (downloadsPath != null) {
  final path = await webViewPlugin.downloadFile(
    'https://example.com/document.pdf',
    downloadsPath,
    filename: 'my_document.pdf',
    onProgress: (received, total) {
      if (total != -1) {
        final progress = (received / total * 100).toInt();
        print('Download progress: $progress%');
      }
    },
  );
  print('Downloaded to: $path');
}
```

### `cancelDownload(String url)`

Cancels an active download.

**Parameters:**

- `url` (String, required) - The URL of the download to cancel

**Returns:** `Future<bool>` - True if the download was cancelled, false if no active download was found

**Example:**

```dart
final cancelled = await webViewPlugin.cancelDownload('https://example.com/file.pdf');
print('Download cancelled: $cancelled');
```

### `getActiveDownloads()`

Gets the list of currently active download URLs.

**Returns:** `List<String>` - List of URLs that are currently being downloaded

**Example:**

```dart
final downloads = webViewPlugin.getActiveDownloads();
print('Active downloads: ${downloads.length}');
```

### `pickFiles({bool allowMultiple = false, List<String>? acceptTypes})`

Opens a file picker for the user to select files.

**Parameters:**

- `allowMultiple` (bool, optional) - Whether to allow multiple file selection (default: false)
- `acceptTypes` (List<String>?, optional) - List of accepted MIME types or file extensions

**Returns:** `Future<List<String>>` - List of selected file paths, or empty list if cancelled

**Example:**

```dart
// Pick single file
final files = await webViewPlugin.pickFiles();

// Pick multiple images
final images = await webViewPlugin.pickFiles(
  allowMultiple: true,
  acceptTypes: ['jpg', 'jpeg', 'png', 'gif'],
);

// Pick PDFs only
final pdfs = await webViewPlugin.pickFiles(
  acceptTypes: ['pdf'],
);
```

### `getDownloadsDirectoryPath()`

Gets the platform-specific downloads directory path.

**Returns:** `Future<String?>` - The path to the downloads directory, or null if unavailable

**Example:**

```dart
final path = await webViewPlugin.getDownloadsDirectoryPath();
if (path != null) {
  print('Downloads directory: $path');
}
```

### `handleFileDownload(String url, String suggestedFilename, String? mimeType)`

Triggers the file download callback if set. This method should be called when the WebView detects a file download request.

**Parameters:**

- `url` (String, required) - The URL of the file to download
- `suggestedFilename` (String, required) - The suggested filename from the server
- `mimeType` (String?, optional) - The MIME type of the file

**Example:**

```dart
webViewPlugin.handleFileDownload(
  'https://example.com/file.pdf',
  'document.pdf',
  'application/pdf',
);
```

### `handleFileUpload({bool allowMultiple = false, List<String>? acceptTypes})`

Triggers the file upload callback or uses the default file picker.

**Parameters:**

- `allowMultiple` (bool, optional) - Whether multiple files can be selected
- `acceptTypes` (List<String>?, optional) - List of accepted MIME types or file extensions

**Returns:** `Future<List<String>>` - List of selected file paths

**Example:**

```dart
final files = await webViewPlugin.handleFileUpload(
  allowMultiple: true,
  acceptTypes: ['image/*', 'pdf'],
);
```

### `getMimeType(String filename)`

Gets the MIME type for a file based on its extension.

**Parameters:**

- `filename` (String, required) - The filename or path

**Returns:** `String` - The MIME type, or 'application/octet-stream' if unknown

**Example:**

```dart
final mimeType = webViewPlugin.getMimeType('document.pdf');
print(mimeType); // 'application/pdf'

final imageMime = webViewPlugin.getMimeType('photo.jpg');
print(imageMime); // 'image/jpeg'
```

### File Handling Callbacks

**OnFileDownload**

Callback for file download requests from the WebView.

```dart
typedef OnFileDownload = void Function(
  String url,
  String suggestedFilename,
  String? mimeType,
);
```

**OnFileUploadRequest**

Callback for file upload requests from the WebView.

```dart
typedef OnFileUploadRequest = Future<List<String>> Function(
  bool allowMultiple,
  List<String>? acceptTypes,
);
```

**OnDownloadProgress**

Callback for download progress updates.

```dart
typedef OnDownloadProgress = void Function(int received, int total);
```

**Example with callbacks:**

```dart
final webViewPlugin = WebViewPlugin(
  onFileDownload: (url, filename, mimeType) {
    print('Download requested: $filename from $url');
    // Handle download
  },
  onFileUploadRequest: (allowMultiple, acceptTypes) async {
    // Custom file picker logic
    return await customFilePicker(allowMultiple, acceptTypes);
  },
);
```

---

## JavaScript Channels

### `addJavaScriptChannel(String channelName, Function(dynamic) callback)`

Add a JavaScript channel.

**Parameters:**

- `channelName` (String, required): Channel name
- `callback` (Function, required): Callback function

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.addJavaScriptChannel(
  'MyChannel',
  (message) {
    print('Received: $message');
  },
);
```

### `removeJavaScriptChannel(String channelName)`

Remove a JavaScript channel.

**Parameters:**

- `channelName` (String, required): Channel name

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.removeJavaScriptChannel('MyChannel');
```

### `listJavaScriptChannels()`

List all registered channels.

**Returns:** `Future<List<String>>` - List of channel names

**Example:**

```dart
final channels = await webViewPlugin.listJavaScriptChannels();
print('Channels: $channels');
```

### `hasJavaScriptChannel(String channelName)`

Check if channel exists.

**Parameters:**

- `channelName` (String, required): Channel name

**Returns:** `Future<bool>`

**Example:**

```dart
final exists = await webViewPlugin.hasJavaScriptChannel('MyChannel');
```

---

## Console Capture

### `enableConsoleCapture(bool enabled)`

Enable or disable console message capture.

**Parameters:**

- `enabled` (bool, required): Whether to capture console messages

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.enableConsoleCapture(true);
```

### `getConsoleMessages()`

Get captured console messages.

**Returns:** `Future<List<Map<String, dynamic>>>` - List of console messages

**Example:**

```dart
final messages = await webViewPlugin.getConsoleMessages();
for (var msg in messages) {
  print('[${msg['level']}] ${msg['message']}');
}
```

### `clearConsoleMessages()`

Clear captured console messages.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.clearConsoleMessages();
```

---

## Page Metadata

### `getPageMetadata()`

Get page metadata (title, description, keywords, etc.).

**Returns:** `Future<Map<String, dynamic>>` - Metadata map

**Example:**

```dart
final metadata = await webViewPlugin.getPageMetadata();
print('Title: ${metadata['title']}');
print('Description: ${metadata['description']}');
print('Links: ${metadata['linkCount']}');
print('Images: ${metadata['imageCount']}');
```

### `getPageLinks()`

Get all links on page.

**Returns:** `Future<List<Map<String, String>>>` - List of links with 'href' and 'text'

**Example:**

```dart
final links = await webViewPlugin.getPageLinks();
for (var link in links) {
  print('${link['text']}: ${link['href']}');
}
```

### `getPageImages()`

Get all images on page.

**Returns:** `Future<List<Map<String, String>>>` - List of images with 'src' and 'alt'

**Example:**

```dart
final images = await webViewPlugin.getPageImages();
for (var img in images) {
  print('${img['alt']}: ${img['src']}');
}
```

### `getPageHtml()`

Get page HTML source.

**Returns:** `Future<String>` - HTML source

**Example:**

```dart
final html = await webViewPlugin.getPageHtml();
print('HTML length: ${html.length}');
```

### `getPageText()`

Get page text content (without HTML tags).

**Returns:** `Future<String>` - Text content

**Example:**

```dart
final text = await webViewPlugin.getPageText();
print('Text: $text');
```

---

## Element Interaction

### `injectCSS(String css)`

Inject CSS into page.

**Parameters:**

- `css` (String, required): CSS code

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.injectCSS('body { background: #f0f0f0; }');
```

### `removeInjectedCSS()`

Remove all injected CSS.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.removeInjectedCSS();
```

### `clickElement(String selector)`

Click an element.

**Parameters:**

- `selector` (String, required): CSS selector

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.clickElement('#submitButton');
```

### `setInputValue(String selector, String value)`

Set input field value.

**Parameters:**

- `selector` (String, required): CSS selector
- `value` (String, required): Value to set

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setInputValue('#username', 'john_doe');
```

### `getInputValue(String selector)`

Get input field value.

**Parameters:**

- `selector` (String, required): CSS selector

**Returns:** `Future<String?>` - Input value or null

**Example:**

```dart
final value = await webViewPlugin.getInputValue('#username');
```

### `elementExists(String selector)`

Check if element exists.

**Parameters:**

- `selector` (String, required): CSS selector

**Returns:** `Future<bool>`

**Example:**

```dart
final exists = await webViewPlugin.elementExists('#myElement');
```

### `countElements(String selector)`

Count matching elements.

**Parameters:**

- `selector` (String, required): CSS selector

**Returns:** `Future<int>` - Element count

**Example:**

```dart
final count = await webViewPlugin.countElements('.item');
print('Found $count items');
```

### `scrollElementIntoView(String selector)`

Scroll element into view.

**Parameters:**

- `selector` (String, required): CSS selector

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.scrollElementIntoView('#targetSection');
```

---

## Security & URL Filtering

### `setAllowedUrls(List<String> patterns)`

Set allowed URL patterns (whitelist).

**Parameters:**

- `patterns` (List<String>, required): URL patterns (supports wildcards)

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setAllowedUrls([
  'https://flutter.dev/*',
  'https://dart.dev/*',
]);
```

### `setBlockedUrls(List<String> patterns)`

Set blocked URL patterns (blacklist).

**Parameters:**

- `patterns` (List<String>, required): URL patterns (supports wildcards)

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setBlockedUrls([
  'https://ads.example.com/*',
  'https://tracker.example.com/*',
]);
```

### `setUrlValidator(bool Function(String) validator)`

Set custom URL validator function.

**Parameters:**

- `validator` (Function, required): Validation function

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.setUrlValidator((url) {
  return url.startsWith('https://');
});
```

### `isUrlAllowed(String url)`

Check if URL is allowed.

**Parameters:**

- `url` (String, required): URL to check

**Returns:** `Future<bool>`

**Example:**

```dart
final allowed = await webViewPlugin.isUrlAllowed('https://example.com');
```

### `clearUrlRestrictions()`

Clear all URL restrictions.

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.clearUrlRestrictions();
```

---

## Performance Monitoring

### `getPerformanceMetrics()`

Get page performance metrics.

**Returns:** `Future<Map<String, dynamic>>` - Performance data

**Example:**

```dart
final metrics = await webViewPlugin.getPerformanceMetrics();
print('Load time: ${metrics['loadTime']}ms');
print('DOM ready: ${metrics['domContentLoaded']}ms');
print('First paint: ${metrics['firstPaint']}ms');
```

### `getMemoryUsage()`

Get JavaScript memory usage.

**Returns:** `Future<Map<String, dynamic>>` - Memory data

**Example:**

```dart
final memory = await webViewPlugin.getMemoryUsage();
print('Used: ${memory['usedJSHeapSize']} bytes');
print('Total: ${memory['totalJSHeapSize']} bytes');
```

### `getResourceCount()`

Get number of loaded resources.

**Returns:** `Future<int>` - Resource count

**Example:**

```dart
final count = await webViewPlugin.getResourceCount();
print('Loaded $count resources');
```

---

## Network Monitoring

### `enableNetworkMonitoring(bool enabled)`

Enable or disable network request monitoring.

**Parameters:**

- `enabled` (bool, required): Whether to monitor network requests

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.enableNetworkMonitoring(true);
```

---

## Lifecycle Management

### `dispose()`

Dispose of WebView resources.

**Returns:** `void`

**Example:**

```dart
@override
void dispose() {
  webViewPlugin.dispose();
  super.dispose();
}
```

### `clearWebViewData()`

Clear all WebView data (cache, cookies, storage).

**Returns:** `Future<void>`

**Example:**

```dart
await webViewPlugin.clearWebViewData();
```

---

## Error Handling

All methods include comprehensive error handling. Errors are logged with debug information and thrown as exceptions.

**Example:**

```dart
try {
  await webViewPlugin.goBack();
} catch (e) {
  print('Error: $e');
}
```

---

## Best Practices

1. **Always dispose**: Call `dispose()` in your widget's dispose method
2. **Check capabilities**: Use `canGoBack()` before `goBack()`
3. **Handle errors**: Wrap async calls in try-catch blocks
4. **Security first**: Use URL filtering for production apps
5. **Monitor performance**: Use performance metrics to optimize
6. **Clean up**: Clear data when appropriate

---

## Version History

- **v0.3.0** - Added 60+ methods (navigation, security, monitoring, etc.)
- **v0.1.6** - Initial release with basic communication

---

**For more examples, see the [example app](../example/lib/main.dart).**
