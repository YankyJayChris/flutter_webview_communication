# Changelog

## 0.3.0 (Unreleased)

### Added

- **Full Platform Support (NEW!):**
  - ✅ **Web** - Now fully supported using IFrameElement
  - ✅ **Windows** - Now fully supported using webview_windows package
  - ✅ **Linux** - Now fully supported using WebKitGTK
  - ✅ **macOS** - Background color now supported via CSS fallback
  - All 84+ methods work across all platforms
  - Platform-specific optimizations and fallbacks

- **File Handling (NEW!):**
  - `downloadFile()` - Download files from URLs with progress tracking
  - `cancelDownload()` - Cancel active downloads
  - `getActiveDownloads()` - Get list of active downloads
  - `pickFiles()` - Open file picker for file selection
  - `getDownloadsDirectoryPath()` - Get platform-specific downloads directory
  - `handleFileDownload()` - Trigger file download callback
  - `handleFileUpload()` - Trigger file upload callback
  - `getMimeType()` - Get MIME type from filename
  - `OnFileDownload` callback typedef for download requests
  - `OnFileUploadRequest` callback typedef for upload requests
  - `OnDownloadProgress` callback typedef for progress updates
  - Added `file_picker: ^8.1.6` dependency
  - Added `path_provider: ^2.1.5` dependency
  - Added `dio: ^5.7.0` dependency for downloads

- **Permission Handling (NEW!):**
  - `requestGeolocationPermission()` - Request location permission
  - `hasGeolocationPermission()` - Check location permission status
  - `requestCameraPermission()` - Request camera permission
  - `hasCameraPermission()` - Check camera permission status
  - `requestMicrophonePermission()` - Request microphone permission
  - `hasMicrophonePermission()` - Check microphone permission status
  - `requestStoragePermission()` - Request storage/photos permission
  - `hasStoragePermission()` - Check storage permission status
  - `requestMultiplePermissions()` - Request multiple permissions at once
  - `checkMultiplePermissions()` - Check multiple permissions at once
  - `openAppSettings()` - Open app settings for manual permission grant
  - `isPermissionPermanentlyDenied()` - Check if permission is permanently denied

- **JavaScript Channel Management:**
  - `addJavaScriptChannel()` - Add custom JavaScript channels
  - `removeJavaScriptChannel()` - Remove JavaScript channels
  - `listJavaScriptChannels()` - List all registered channels
  - `hasJavaScriptChannel()` - Check if channel exists

- **Console Message Capture:**
  - `enableConsoleCapture()` - Capture console.log, console.error, etc.
  - `getConsoleMessages()` - Get all captured console messages
  - `clearConsoleMessages()` - Clear console message history

- **Page Metadata & Information:**
  - `getPageMetadata()` - Get comprehensive page metadata
  - `getPageLinks()` - Get all links on the page
  - `getPageImages()` - Get all images on the page
  - `getPageHtml()` - Get page HTML content
  - `getPageText()` - Get page text content (without HTML tags)

- **Element Interaction:**
  - `injectCSS()` - Inject custom CSS into the page
  - `removeInjectedCSS()` - Remove injected CSS by ID
  - `clickElement()` - Click an element by CSS selector
  - `setInputValue()` - Set input element value
  - `getInputValue()` - Get input element value
  - `elementExists()` - Check if element exists
  - `countElements()` - Count elements matching selector
  - `scrollElementIntoView()` - Scroll element into view

- **Security & URL Filtering:**
  - `setAllowedUrls()` - Set URL whitelist
  - `setBlockedUrls()` - Set URL blacklist
  - `setUrlValidator()` - Set custom URL validator
  - `isUrlAllowed()` - Check if URL is allowed
  - `clearUrlRestrictions()` - Clear all URL restrictions

- **Performance Monitoring:**
  - `getPerformanceMetrics()` - Get page load performance metrics
  - `getMemoryUsage()` - Get JavaScript memory usage
  - `getResourceCount()` - Get count of loaded resources by type

- **Network Monitoring:**
  - `enableNetworkMonitoring()` - Monitor XHR and Fetch requests

### Dependencies

- Added `permission_handler: ^11.3.1` for native permission handling

### Platform Configuration

- **Android:** Added permission declarations in AndroidManifest.xml
  - Location (fine and coarse)
  - Camera
  - Microphone
  - Storage (legacy and granular media permissions for Android 13+)

- **iOS:** Added permission descriptions in Info.plist
  - Location (when in use and always)
  - Camera
  - Microphone
  - Photo Library (read and write)

### Improved

- Better error handling for all new methods
- Enhanced debugging capabilities
- More comprehensive page inspection tools
- Automatic URL filtering in navigation delegate

## 0.2.0 (Unreleased)

### Breaking Changes

- Updated minimum dependencies to support new features

### Added

- **Navigation Controls:**
  - `goBack()` - Navigate back in history
  - `goForward()` - Navigate forward in history
  - `canGoBack()` - Check if can navigate back
  - `canGoForward()` - Check if can navigate forward
  - `getCurrentUrl()` - Get current page URL
  - `getTitle()` - Get current page title
  - `stopLoading()` - Stop current page load

- **Zoom Controls:**
  - `setZoomEnabled(bool)` - Enable/disable zoom
  - `zoomIn()` - Zoom in by 20%
  - `zoomOut()` - Zoom out by 20%
  - `setZoomLevel(double)` - Set specific zoom level
  - `getZoomLevel()` - Get current zoom level

- **Enhanced Cookie Management:**
  - `getCookie(String name, String url)` - Get specific cookie
  - `setCookie()` - Set cookie with domain and expiration
  - `hasCookies()` - Check if cookies exist
  - `getAllCookies()` - Get all cookies as map

- **Scroll Controls:**
  - `scrollTo(double x, double y)` - Scroll to position
  - `scrollBy(double x, double y)` - Scroll by offset
  - `scrollToTop()` - Scroll to top of page
  - `scrollToBottom()` - Scroll to bottom of page
  - Smooth scrolling support for all scroll methods

- **Find in Page:**
  - `findInPage(String searchText)` - Find text in page
  - `findNext()` - Navigate to next match
  - `findPrevious()` - Navigate to previous match
  - `clearFindMatches()` - Clear all highlights
  - `getFindMatchInfo()` - Get current match info

- **Lifecycle Management:**
  - `dispose()` - Properly dispose WebView resources

### Improved

- Updated dependencies to latest compatible versions
- Enhanced error handling across all methods
- Better debug logging for all operations
- Improved documentation with detailed examples

### Fixed

- Copyright headers standardized across all files
- Deprecated test matchers replaced

## 0.1.6

- Added `enableCommunication` flag to control injection of communication scripts for URLs and HTML.
- Added `onJavaScriptError` callback to handle JavaScript errors across all operations.
- Enhanced `buildWebView` with new parameters:
  - `enableCommunication`: Overrides constructor’s setting for communication scripts.
  - `userAgent`: Sets a custom user agent string.
  - `csp`: Adds Content Security Policy for custom HTML.
  - `onLoadingStateChanged`: Provides callbacks for page loading states (`started`, `progress`, `finished`, `error`).
- Added `removeFromLocalStorage` method to remove a specific key from WebView local storage.
- Added `getLocalStorage` method to retrieve all key-value pairs from WebView local storage.
- Added `clearWebViewData` method to clear cookies, cache, and local storage.
- Added `reload` method to refresh the current WebView content (HTML or URL).
- Improved error handling with detailed debug messages and `rethrow` for all async methods.

## 0.1.3

- Bug fix.
- Implemented removal of existing local storage data before saving new data.
- Improved error handling with silent logging for local storage operations.
- Updated documentation and comments for better clarity.

## 0.1.2

- Added support for injecting custom JavaScript into URL-loaded pages.
- Added `saveToLocalStorage` method to store data in the WebView's local storage for both HTML and URL content.
- Updated documentation and example to demonstrate HTML, URL usage with JavaScript injection, and local storage.

## 0.1.1

- Fixed platform support issues by implementing conditional imports for `webview_flutter_android` and `webview_flutter_wkwebview`.
- Added explicit platform initialization and support for Android, iOS, and macOS.
- Added error handling for unsupported platforms (Web, Windows, Linux) with `Exception`.
- Updated example to handle unsupported platforms gracefully.
- Added support for loading URLs in addition to HTML content in `buildWebView` with the `isUrl` parameter.
- Updated documentation and example to demonstrate both HTML and URL usage.

## 0.1.0

- Initial release
- Bi-directional communication between Flutter and WebView
- Support for custom HTML, CSS, and JavaScript
- Platform-specific configurations for Android and iOS
