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