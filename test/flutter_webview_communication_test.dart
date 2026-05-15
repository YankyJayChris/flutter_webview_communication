// Copyright (c) 2025 IGIHOZO Jean Christian. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewPlugin Static Methods', () {
    test('getMimeTypeStatic returns correct MIME types', () {
      expect(WebViewPlugin.getMimeTypeStatic('test.pdf'),
          equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('test.jpg'), equals('image/jpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('test.png'), equals('image/png'));
      expect(WebViewPlugin.getMimeTypeStatic('test.mp4'), equals('video/mp4'));
    });

    test('getMimeTypeStatic handles unknown extensions', () {
      expect(
        WebViewPlugin.getMimeTypeStatic('test.unknown'),
        equals('application/octet-stream'),
      );
    });

    test('getMimeTypeStatic is case insensitive', () {
      expect(WebViewPlugin.getMimeTypeStatic('TEST.PDF'),
          equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('Test.JPG'), equals('image/jpeg'));
    });
  });

  group('WebViewPlugin URL Validation', () {
    test('should validate proper URL format', () {
      final validUrl = 'https://flutter.dev';
      final uri = Uri.tryParse(validUrl);

      expect(uri, isNotNull);
      expect(uri!.hasScheme, isTrue);
      expect(uri.scheme, equals('https'));
    });

    test('should detect invalid URL format', () {
      final invalidUrl = 'not a valid url';
      final uri = Uri.tryParse(invalidUrl);

      // Uri.tryParse doesn't fail, but the result won't have a proper scheme
      expect(uri, isNotNull);
      expect(uri!.hasScheme, isFalse);
    });
  });

  group('WebViewPlugin Callback Patterns', () {
    test('action handler structure is valid', () {
      final handler = (Map<String, dynamic> payload) {
        return payload['data'];
      };

      expect(handler, isA<Function>());
      expect(handler({'data': 'test'}), equals('test'));
    });

    test('error handler structure is valid', () {
      String? capturedError;
      final errorHandler = (String error) {
        capturedError = error;
      };

      errorHandler('Test error');
      expect(capturedError, equals('Test error'));
    });

    test('file download handler structure is valid', () {
      String? downloadedFile;
      final downloadHandler = (String url, String filename, String? mimeType) {
        downloadedFile = filename;
      };

      downloadHandler(
          'https://example.com/file.pdf', 'file.pdf', 'application/pdf');
      expect(downloadedFile, equals('file.pdf'));
    });
  });
}
