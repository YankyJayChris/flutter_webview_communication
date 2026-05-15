# Release Notes - v0.3.0

**Release Date:** May 15, 2026  
**Status:** Ready for Release  
**Breaking Changes:** None

---

## 🎉 Major Highlights

### 1. **Full Cross-Platform Support** 🌍

We're excited to announce that `flutter_webview_communication` now supports **ALL major platforms**!

| Platform       | Status                   | Notes                             |
| -------------- | ------------------------ | --------------------------------- |
| ✅ Android     | Fully supported          | Requires minSdkVersion 19         |
| ✅ iOS         | Fully supported          | No additional config needed       |
| ✅ macOS       | Fully supported          | Background color via CSS fallback |
| ✅ **Web**     | **NEW!** Fully supported | Uses IFrameElement (built-in)     |
| ✅ **Windows** | **NEW!** Fully supported | Uses webview_windows package      |
| ✅ **Linux**   | **NEW!** Fully supported | Uses WebKitGTK                    |

**What this means:**

- Write once, run everywhere - truly cross-platform WebView solution
- Consistent API across all platforms
- Platform-specific optimizations where needed
- Automatic fallbacks for unsupported native features

---

### 2. **File Handling** 📁

Complete file handling capabilities with download and upload support:

**Download Features:**

- `downloadFile()` - Download files with progress tracking
- `cancelDownload()` - Cancel active downloads
- `getActiveDownloads()` - Monitor active downloads
- Progress callbacks for real-time updates
- Automatic MIME type detection

**Upload Features:**

- `pickFiles()` - Native file picker integration
- Support for single/multiple file selection
- File type filtering (images, PDFs, videos, etc.)
- Custom file upload callbacks
- `getDownloadsDirectoryPath()` - Platform-specific paths

**Utilities:**

- `getMimeType()` - Get MIME type from filename
- `handleFileDownload()` - Custom download handling
- `handleFileUpload()` - Custom upload handling

**Example:**

```dart
// Download with progress
final path = await webViewPlugin.downloadFile(
  'https://example.com/document.pdf',
  downloadsPath,
  onProgress: (received, total) {
    print('Progress: ${(received / total * 100).toInt()}%');
  },
);

// Pick files
final files = await webViewPlugin.pickFiles(
  allowMultiple: true,
  acceptTypes: ['pdf', 'jpg', 'png'],
);
```

---

### 3. **Permission Handling** 🔐

Comprehensive permission management for sensitive features:

**Supported Permissions:**

- 📍 Geolocation
- 📷 Camera
- 🎤 Microphone
- 📂 Storage/Photos

**Methods (12 total):**

- `requestGeolocationPermission()` / `hasGeolocationPermission()`
- `requestCameraPermission()` / `hasCameraPermission()`
- `requestMicrophonePermission()` / `hasMicrophonePermission()`
- `requestStoragePermission()` / `hasStoragePermission()`
- `requestMultiplePermissions()` - Request multiple at once
- `checkMultiplePermissions()` - Check multiple at once
- `openAppSettings()` - Open system settings
- `isPermissionPermanentlyDenied()` - Check denial status

**Example:**

```dart
// Request single permission
final status = await webViewPlugin.requestCameraPermission();

// Request multiple permissions
final results = await webViewPlugin.requestMultiplePermissions([
  'camera',
  'microphone',
  'storage',
]);
```

---

## � Complete Feature Set

### Total: 84+ Methods Across 16 Categories

#### 1. Core Communication (13 methods)

- `buildWebView()`, `sendToWebView()`, `saveToLocalStorage()`, `removeFromLocalStorage()`, `getLocalStorage()`, `clearWebViewData()`, `reload()`, `getScrollPosition()`, `dispose()`, `evaluateJavaScript()`, `runJavaScript()`, `loadUrl()`, `loadHtmlString()`

#### 2. Navigation Controls (7 methods)

- `goBack()`, `goForward()`, `canGoBack()`, `canGoForward()`, `getCurrentUrl()`, `getTitle()`, `stopLoading()`

#### 3. Zoom Controls (5 methods)

- `setZoomEnabled()`, `zoomIn()`, `zoomOut()`, `setZoomLevel()`, `getZoomLevel()`

#### 4. Cookie Management (4 methods)

- `getCookie()`, `setCookie()`, `hasCookies()`, `getAllCookies()`

#### 5. Scroll Controls (5 methods)

- `scrollTo()`, `scrollBy()`, `scrollToTop()`, `scrollToBottom()`, enhanced `getScrollPosition()`

#### 6. Find in Page (5 methods)

- `findInPage()`, `findNext()`, `findPrevious()`, `clearFindMatches()`, `getFindMatchInfo()`

#### 7. **File Handling (9 methods) - NEW!**

- `downloadFile()`, `cancelDownload()`, `getActiveDownloads()`, `pickFiles()`, `getDownloadsDirectoryPath()`, `handleFileDownload()`, `handleFileUpload()`, `getMimeType()`

#### 8. JavaScript Channels (4 methods)

- `addJavaScriptChannel()`, `removeJavaScriptChannel()`, `listJavaScriptChannels()`, `hasJavaScriptChannel()`

#### 9. Console Capture (3 methods)

- `enableConsoleCapture()`, `getConsoleMessages()`, `clearConsoleMessages()`

#### 10. Page Metadata (5 methods)

- `getPageMetadata()`, `getPageLinks()`, `getPageImages()`, `getPageHtml()`, `getPageText()`

#### 11. Element Interaction (8 methods)

- `injectCSS()`, `removeInjectedCSS()`, `clickElement()`, `setInputValue()`, `getInputValue()`, `elementExists()`, `countElements()`, `scrollElementIntoView()`

#### 12. Security & URL Filtering (5 methods)

- `setAllowedUrls()`, `setBlockedUrls()`, `setUrlValidator()`, `isUrlAllowed()`, `clearUrlRestrictions()`

#### 13. Performance Monitoring (3 methods)

- `getPerformanceMetrics()`, `getMemoryUsage()`, `getResourceCount()`

#### 14. Network Monitoring (1 method)

- `enableNetworkMonitoring()`

#### 15. **Permission Handling (12 methods) - NEW!**

- `requestGeolocationPermission()`, `hasGeolocationPermission()`, `requestCameraPermission()`, `hasCameraPermission()`, `requestMicrophonePermission()`, `hasMicrophonePermission()`, `requestStoragePermission()`, `hasStoragePermission()`, `requestMultiplePermissions()`, `checkMultiplePermissions()`, `openAppSettings()`, `isPermissionPermanentlyDenied()`

#### 16. Additional Utilities (10+ methods)

- `takeScreenshot()`, `print()`, `generatePDF()`, `disableContextMenu()`, `enableContextMenu()`, `clearCookies()`, `clearCache()`, `getUserAgent()`, `setUserAgent()`, `setJavaScriptEnabled()`, `setBackgroundColor()`

---

## 🔧 Technical Improvements

### Dependencies Added

- `file_picker: ^8.1.6` - File picker integration
- `path_provider: ^2.1.5` - Platform-specific paths
- `dio: ^5.7.0` - HTTP client for downloads
- `webview_windows: ^0.4.0` - Windows WebView support

### Code Quality

- ✅ **0 errors, 0 warnings** in static analysis
- ✅ Fixed deprecated Color API usage
- ✅ Platform-specific optimizations
- ✅ Comprehensive error handling
- ✅ Extensive documentation

### Documentation

- 📚 Complete API Reference (~40KB)
- 📚 Troubleshooting Guide (~25KB)
- 📚 Best Practices Guide (~30KB)
- 📚 Migration Guide (~15KB)
- 📚 Implementation Status
- 📚 Updated README with all features

### Example App

- 🎨 8 feature tabs (Storage, Navigation, Find, Elements, Security, Monitoring, Permissions, **Files**)
- 🎨 Material 3 design
- 🎨 Comprehensive demonstrations
- 🎨 Production-ready UI/UX

---

## 🚀 Migration Guide

### From v0.2.x to v0.3.0

**No breaking changes!** All existing code will continue to work.

**New Features to Adopt:**

1. **File Handling:**

```dart
// Add callbacks to constructor
final webViewPlugin = WebViewPlugin(
  onFileDownload: (url, filename, mimeType) {
    // Handle downloads
  },
  onFileUploadRequest: (allowMultiple, acceptTypes) async {
    // Handle uploads
    return await pickFiles();
  },
);
```

2. **Permission Handling:**

```dart
// Request permissions before using features
await webViewPlugin.requestCameraPermission();
await webViewPlugin.requestMicrophonePermission();
```

3. **Cross-Platform Support:**

```dart
// Your code now works on Web, Windows, and Linux!
// No changes needed - just deploy to new platforms
```

---

## 📦 Installation

```yaml
dependencies:
  flutter_webview_communication: ^0.3.0
```

Then run:

```bash
flutter pub get
```

---

## 🎯 What's Next?

### Planned for v1.0.0

- [ ] Native screenshot implementation
- [ ] Native PDF generation
- [ ] SSL error handling
- [ ] HTTP authentication
- [ ] Certificate pinning
- [ ] Video tutorials
- [ ] More examples (OAuth, PDF viewer, Multi-WebView)

---

## 🙏 Acknowledgments

Thank you to all contributors and users who provided feedback and suggestions!

---

## 📞 Support

- **GitHub Issues:** https://github.com/YankyJayChris/flutter_webview_communication/issues
- **Documentation:** See `/docs` folder
- **Examples:** See `/example` folder

---

## � License

MIT License - See LICENSE file for details

---

**Enjoy building amazing cross-platform WebView applications! 🎉**
