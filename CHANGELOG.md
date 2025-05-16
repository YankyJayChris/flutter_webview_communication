# Changelog

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