# 🔧 Troubleshooting Guide

Common issues and solutions for flutter_webview_communication.

---

## Table of Contents

1. [Installation Issues](#installation-issues)
2. [WebView Not Loading](#webview-not-loading)
3. [Communication Issues](#communication-issues)
4. [JavaScript Errors](#javascript-errors)
5. [Navigation Issues](#navigation-issues)
6. [Performance Issues](#performance-issues)
7. [Platform-Specific Issues](#platform-specific-issues)
8. [Security Issues](#security-issues)

---

## Installation Issues

### Problem: Package not found

**Solution:**

```bash
flutter pub get
flutter pub upgrade
```

### Problem: Version conflict

**Error:** `Because flutter_webview_communication depends on webview_flutter ^4.9.0...`

**Solution:**
Update your `pubspec.yaml`:

```yaml
dependencies:
  flutter_webview_communication: ^0.3.0
  webview_flutter: ^4.9.0
```

Then run:

```bash
flutter pub upgrade
```

### Problem: Build fails after installation

**Solution:**

1. Clean build cache:

```bash
flutter clean
flutter pub get
```

2. For iOS, update pods:

```bash
cd ios
pod install
cd ..
```

3. For Android, sync Gradle:

```bash
cd android
./gradlew clean
cd ..
```

---

## WebView Not Loading

### Problem: WebView shows blank screen

**Possible causes:**

1. Invalid HTML content
2. Missing internet permission (for URLs)
3. Content Security Policy blocking resources

**Solutions:**

**1. Check HTML validity:**

```dart
final html = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
</head>
<body>
  <h1>Test</h1>
</body>
</html>
''';

webViewPlugin.buildWebView(
  content: html,
  isUrl: false,
);
```

**2. Add internet permission (Android):**

In `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
```

**3. Adjust CSP:**

```dart
webViewPlugin.buildWebView(
  content: html,
  isUrl: false,
  csp: "default-src 'self' 'unsafe-inline' 'unsafe-eval'; img-src * data:;",
);
```

### Problem: URL not loading

**Error:** `net::ERR_CLEARTEXT_NOT_PERMITTED`

**Solution (Android):**

In `android/app/src/main/AndroidManifest.xml`:

```xml
<application
    android:usesCleartextTraffic="true"
    ...>
```

**Note:** Only use for development. Production apps should use HTTPS.

### Problem: Loading state stuck

**Solution:**
Add timeout and error handling:

```dart
webViewPlugin.buildWebView(
  content: url,
  isUrl: true,
  onLoadingStateChanged: (state, progress, error) {
    if (error != null) {
      print('Loading error: $error');
      // Handle error
    }
    if (state == 'error') {
      // Retry or show error message
    }
  },
);
```

---

## Communication Issues

### Problem: Messages not received in WebView

**Check:**

1. Communication is enabled
2. Event listener is set up correctly
3. Action names match

**Solution:**

```dart
// Flutter side
WebViewPlugin(
  enableCommunication: true,
  actionHandlers: {
    'myAction': (payload) {
      print('Received: $payload');
    },
  },
);

webViewPlugin.sendToWebView(
  action: 'myAction',
  payload: {'data': 'test'},
);
```

```javascript
// JavaScript side
window.addEventListener("flutterData", (event) => {
  const { action, payload } = event.detail;
  console.log("Received:", action, payload);
});
```

### Problem: Messages not received in Flutter

**Check:**

1. `sendToFlutter` function is defined
2. Action handler is registered
3. Payload is JSON-serializable

**Solution:**

```javascript
// Make sure this is in your script
function sendToFlutter(action, payload) {
  window.dispatchEvent(
    new CustomEvent("webViewMessage", {
      detail: { action, payload },
    }),
  );
}

// Then use it
sendToFlutter("myAction", { data: "test" });
```

### Problem: LocalStorage not working

**Check:**

1. WebView is fully loaded
2. Key names are correct
3. Values are strings

**Solution:**

```dart
// Wait for page to load
webViewPlugin.buildWebView(
  content: html,
  isUrl: false,
  onLoadingStateChanged: (state, progress, error) {
    if (state == 'success') {
      // Now safe to use localStorage
      webViewPlugin.saveToLocalStorage(
        key: 'myKey',
        value: 'myValue',
      );
    }
  },
);
```

---

## JavaScript Errors

### Problem: JavaScript execution fails

**Error:** `JavaScript execution returned null`

**Causes:**

1. Syntax error in JavaScript
2. Element not found
3. Timing issue (DOM not ready)

**Solutions:**

**1. Check syntax:**

```dart
try {
  await webViewPlugin.clickElement('#myButton');
} catch (e) {
  print('Error: $e');
  // Check if element exists first
  final exists = await webViewPlugin.elementExists('#myButton');
  print('Element exists: $exists');
}
```

**2. Wait for DOM:**

```dart
// Wait for page load
await Future.delayed(Duration(milliseconds: 500));
await webViewPlugin.clickElement('#myButton');
```

**3. Use error callback:**

```dart
WebViewPlugin(
  enableCommunication: true,
  onJavaScriptError: (error) {
    print('JS Error: $error');
    // Handle error
  },
);
```

### Problem: Console messages not captured

**Solution:**

```dart
// Enable console capture
await webViewPlugin.enableConsoleCapture(true);

// Get messages
final messages = await webViewPlugin.getConsoleMessages();
for (var msg in messages) {
  print('[${msg['level']}] ${msg['message']}');
}
```

---

## Navigation Issues

### Problem: Back button doesn't work

**Solution:**

```dart
// Check if can go back first
final canBack = await webViewPlugin.canGoBack();
if (canBack) {
  await webViewPlugin.goBack();
} else {
  // Exit app or show message
  Navigator.pop(context);
}
```

### Problem: URL changes not detected

**Solution:**
Use navigation delegate:

```dart
webViewPlugin.buildWebView(
  content: url,
  isUrl: true,
  onLoadingStateChanged: (state, progress, error) async {
    if (state == 'success') {
      final currentUrl = await webViewPlugin.getCurrentUrl();
      print('Current URL: $currentUrl');
    }
  },
);
```

### Problem: External links open in WebView

**Solution:**
Use URL filtering:

```dart
// Only allow specific domains
await webViewPlugin.setAllowedUrls([
  'https://myapp.com/*',
]);

// Or use custom validator
await webViewPlugin.setUrlValidator((url) {
  if (url.startsWith('https://external.com')) {
    // Open in external browser
    launchUrl(Uri.parse(url));
    return false;
  }
  return true;
});
```

---

## Performance Issues

### Problem: WebView is slow

**Solutions:**

**1. Monitor performance:**

```dart
final metrics = await webViewPlugin.getPerformanceMetrics();
print('Load time: ${metrics['loadTime']}ms');

final memory = await webViewPlugin.getMemoryUsage();
print('Memory: ${memory['usedJSHeapSize']} bytes');
```

**2. Optimize content:**

- Minimize JavaScript
- Compress images
- Use lazy loading
- Remove unused CSS

**3. Clear cache periodically:**

```dart
await webViewPlugin.clearWebViewData();
```

### Problem: Memory leaks

**Solution:**
Always dispose:

```dart
@override
void dispose() {
  webViewPlugin.dispose();
  super.dispose();
}
```

### Problem: Slow scrolling

**Solution:**

```dart
// Enable hardware acceleration (Android)
// In android/app/src/main/AndroidManifest.xml
<application
    android:hardwareAccelerated="true"
    ...>
```

---

## Platform-Specific Issues

### iOS Issues

#### Problem: WebView not loading on iOS

**Solution:**
Add to `ios/Runner/Info.plist`:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

**Note:** Only for development. Production should use HTTPS.

#### Problem: Keyboard covers input

**Solution:**

```dart
Scaffold(
  resizeToAvoidBottomInset: true,
  body: webViewPlugin.buildWebView(...),
);
```

### Android Issues

#### Problem: WebView crashes on Android

**Solution:**

1. Update WebView:

```bash
# On device/emulator
adb shell pm list packages | grep webview
```

2. Add to `android/app/build.gradle`:

```gradle
android {
    defaultConfig {
        minSdkVersion 21  // Minimum for WebView
    }
}
```

#### Problem: File upload not working

**Solution:**
Add permissions to `AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

---

## Security Issues

### Problem: Mixed content blocked

**Error:** `Mixed Content: The page was loaded over HTTPS, but requested an insecure resource`

**Solution:**

1. Use HTTPS for all resources
2. Or adjust CSP:

```dart
webViewPlugin.buildWebView(
  content: html,
  csp: "default-src 'self' https: data:;",
);
```

### Problem: CORS errors

**Error:** `Access to fetch at '...' from origin '...' has been blocked by CORS policy`

**Solution:**

1. Configure server to allow CORS
2. Or use proxy
3. Or load content as HTML instead of URL

### Problem: XSS vulnerability

**Solution:**
Always sanitize user input:

```dart
String sanitize(String input) {
  return input
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#x27;');
}

final safeContent = sanitize(userInput);
```

---

## Debugging Tips

### Enable Debug Logging

```dart
// Check debug logs in console
// All methods log their execution
```

### Inspect WebView Content

**Android:**

```bash
# Enable WebView debugging
chrome://inspect/#devices
```

**iOS:**

```
Safari > Develop > [Device] > [App]
```

### Test in Isolation

```dart
// Create minimal test case
void main() {
  runApp(MaterialApp(
    home: Scaffold(
      body: WebViewPlugin(
        enableCommunication: true,
      ).buildWebView(
        content: '<h1>Test</h1>',
        isUrl: false,
      ),
    ),
  ));
}
```

---

## Common Error Messages

### `MissingPluginException`

**Cause:** Plugin not registered

**Solution:**

```bash
flutter clean
flutter pub get
# Restart IDE
```

### `PlatformException`

**Cause:** Platform-specific error

**Solution:**
Check platform logs:

```bash
# Android
adb logcat

# iOS
# Check Xcode console
```

### `Null check operator used on a null value`

**Cause:** WebView not initialized

**Solution:**

```dart
late WebViewPlugin webViewPlugin;

@override
void initState() {
  super.initState();
  webViewPlugin = WebViewPlugin(
    enableCommunication: true,
  );
}
```

---

## Getting Help

If you're still experiencing issues:

1. **Check documentation:** [README.md](../README.md), [API_REFERENCE.md](API_REFERENCE.md)
2. **Search issues:** [GitHub Issues](https://github.com/YankyJayChris/flutter_webview_communication/issues)
3. **Create issue:** Include:
   - Flutter version (`flutter --version`)
   - Package version
   - Platform (iOS/Android)
   - Minimal reproduction code
   - Error messages
   - Steps to reproduce

---

## Best Practices to Avoid Issues

1. **Always dispose:** Call `dispose()` in widget's dispose method
2. **Check state:** Use `canGoBack()` before `goBack()`
3. **Handle errors:** Wrap async calls in try-catch
4. **Wait for load:** Check loading state before executing JavaScript
5. **Test on both platforms:** iOS and Android may behave differently
6. **Use HTTPS:** Avoid cleartext traffic in production
7. **Sanitize input:** Prevent XSS attacks
8. **Monitor performance:** Use performance metrics
9. **Clear data:** Periodically clear cache and cookies
10. **Update regularly:** Keep package and dependencies updated

---

**For more help, see [QUICK_START.md](QUICK_START.md) and [MIGRATION_GUIDE.md](MIGRATION_GUIDE.md).**
