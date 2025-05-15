# Changelog

## 0.1.5
- bug fix

## 0.1.4
- Added `getLocalStorage` to retrieve all key-value pairs from WebView local storage using JavaScript.
- Simplified `clearWebViewData` to use cross-platform `WebViewCookieManager` for cookie clearing and `WebViewController.clearCache` for cache clearing, removing platform-specific dependencies (`AndroidCookieManager`, `WebKitWebsiteDataStore`, `WebKitWebsiteDataType`).
- Removed platform-specific imports (`webview_flutter_android`, `webview_flutter_wkwebview`, `webview_flutter_platform_interface`) to reduce dependency complexity.
- Removed `setMediaPlaybackRequiresUserGesture` to eliminate the need for `webview_flutter_android`, making the plugin more lightweight.
- Added getScrollPosition to retrieve the WebView's scroll position.
- Updated example (`main.dart`) to demonstrate `getLocalStorage`, `clearWebViewData`, `reload`, `onLoadingStateChanged`, and `onJavaScriptError` with an enhanced UI, including loading state display, additional action buttons, and improved error handling.
- Improved documentation in `README.md` to reflect new `getLocalStorage` method, updated platform support details, and simplified usage examples.

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