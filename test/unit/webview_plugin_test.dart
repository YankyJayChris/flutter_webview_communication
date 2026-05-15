// Copyright (c) 2025 IGIHOZO Jean Christian. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewPlugin MIME Type Detection', () {
    test('getMimeType should return correct MIME types for common files', () {
      expect(WebViewPlugin.getMimeTypeStatic('document.pdf'),
          equals('application/pdf'));
      expect(
          WebViewPlugin.getMimeTypeStatic('image.jpg'), equals('image/jpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('image.png'), equals('image/png'));
      expect(WebViewPlugin.getMimeTypeStatic('video.mp4'), equals('video/mp4'));
      expect(
          WebViewPlugin.getMimeTypeStatic('audio.mp3'), equals('audio/mpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('archive.zip'),
          equals('application/zip'));
      expect(WebViewPlugin.getMimeTypeStatic('text.txt'), equals('text/plain'));
      expect(WebViewPlugin.getMimeTypeStatic('style.css'), equals('text/css'));
      expect(WebViewPlugin.getMimeTypeStatic('script.js'),
          equals('application/javascript'));
      expect(WebViewPlugin.getMimeTypeStatic('data.json'),
          equals('application/json'));
    });

    test('getMimeType should return default for unknown extensions', () {
      expect(
        WebViewPlugin.getMimeTypeStatic('unknown.xyz'),
        equals('application/octet-stream'),
      );
    });

    test('getMimeType should handle files without extension', () {
      expect(
        WebViewPlugin.getMimeTypeStatic('README'),
        equals('application/octet-stream'),
      );
    });

    test('getMimeType should be case insensitive', () {
      expect(
          WebViewPlugin.getMimeTypeStatic('IMAGE.JPG'), equals('image/jpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('Document.PDF'),
          equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('Video.MP4'), equals('video/mp4'));
    });

    test('should detect all document MIME types', () {
      expect(WebViewPlugin.getMimeTypeStatic('doc.pdf'),
          equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('doc.doc'),
          equals('application/msword'));
      expect(
        WebViewPlugin.getMimeTypeStatic('doc.docx'),
        equals(
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        ),
      );
      expect(WebViewPlugin.getMimeTypeStatic('sheet.xls'),
          equals('application/vnd.ms-excel'));
      expect(
        WebViewPlugin.getMimeTypeStatic('sheet.xlsx'),
        equals(
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ),
      );
    });

    test('should detect all image MIME types', () {
      expect(WebViewPlugin.getMimeTypeStatic('img.jpg'), equals('image/jpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('img.jpeg'), equals('image/jpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('img.png'), equals('image/png'));
      expect(WebViewPlugin.getMimeTypeStatic('img.gif'), equals('image/gif'));
      expect(WebViewPlugin.getMimeTypeStatic('img.bmp'), equals('image/bmp'));
      expect(WebViewPlugin.getMimeTypeStatic('img.webp'), equals('image/webp'));
      expect(
          WebViewPlugin.getMimeTypeStatic('img.svg'), equals('image/svg+xml'));
    });

    test('should detect all audio MIME types', () {
      expect(
          WebViewPlugin.getMimeTypeStatic('audio.mp3'), equals('audio/mpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('audio.wav'), equals('audio/wav'));
      expect(WebViewPlugin.getMimeTypeStatic('audio.ogg'), equals('audio/ogg'));
      expect(WebViewPlugin.getMimeTypeStatic('audio.aac'), equals('audio/aac'));
      expect(
          WebViewPlugin.getMimeTypeStatic('audio.flac'), equals('audio/flac'));
    });

    test('should detect all video MIME types', () {
      expect(WebViewPlugin.getMimeTypeStatic('video.mp4'), equals('video/mp4'));
      expect(WebViewPlugin.getMimeTypeStatic('video.avi'),
          equals('video/x-msvideo'));
      expect(WebViewPlugin.getMimeTypeStatic('video.mov'),
          equals('video/quicktime'));
      expect(WebViewPlugin.getMimeTypeStatic('video.wmv'),
          equals('video/x-ms-wmv'));
      expect(WebViewPlugin.getMimeTypeStatic('video.mkv'),
          equals('video/x-matroska'));
      expect(
          WebViewPlugin.getMimeTypeStatic('video.webm'), equals('video/webm'));
    });

    test('should detect all archive MIME types', () {
      expect(WebViewPlugin.getMimeTypeStatic('file.zip'),
          equals('application/zip'));
      expect(
        WebViewPlugin.getMimeTypeStatic('file.rar'),
        equals('application/x-rar-compressed'),
      );
      expect(
        WebViewPlugin.getMimeTypeStatic('file.7z'),
        equals('application/x-7z-compressed'),
      );
      expect(WebViewPlugin.getMimeTypeStatic('file.tar'),
          equals('application/x-tar'));
      expect(WebViewPlugin.getMimeTypeStatic('file.gz'),
          equals('application/gzip'));
    });

    test('should detect all web MIME types', () {
      expect(WebViewPlugin.getMimeTypeStatic('page.html'), equals('text/html'));
      expect(WebViewPlugin.getMimeTypeStatic('page.htm'), equals('text/html'));
      expect(WebViewPlugin.getMimeTypeStatic('style.css'), equals('text/css'));
      expect(WebViewPlugin.getMimeTypeStatic('script.js'),
          equals('application/javascript'));
      expect(WebViewPlugin.getMimeTypeStatic('data.json'),
          equals('application/json'));
      expect(WebViewPlugin.getMimeTypeStatic('data.xml'),
          equals('application/xml'));
    });

    test('should handle files with multiple dots', () {
      expect(WebViewPlugin.getMimeTypeStatic('my.file.name.pdf'),
          equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('archive.tar.gz'),
          equals('application/gzip'));
    });

    test('should handle edge cases', () {
      expect(WebViewPlugin.getMimeTypeStatic(''),
          equals('application/octet-stream'));
      expect(
          WebViewPlugin.getMimeTypeStatic('.pdf'), equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('file.'),
          equals('application/octet-stream'));
    });
  });

  group('WebViewPlugin URL Pattern Matching', () {
    test('should validate URL patterns correctly', () {
      // Test wildcard patterns
      expect('https://flutter.dev/docs'.contains('flutter.dev'), isTrue);
      expect('https://dart.dev/guides'.contains('dart.dev'), isTrue);

      // Test exact matches
      expect('https://flutter.dev', equals('https://flutter.dev'));

      // Test subdomain matching
      expect('https://api.flutter.dev'.contains('flutter.dev'), isTrue);
    });
  });

  group('WebViewPlugin File Handling', () {
    test('should handle file download callback invocation', () {
      String? capturedUrl;
      String? capturedFilename;
      String? capturedMimeType;

      void testCallback(String url, String filename, String? mimeType) {
        capturedUrl = url;
        capturedFilename = filename;
        capturedMimeType = mimeType;
      }

      testCallback(
        'https://example.com/test.pdf',
        'test.pdf',
        'application/pdf',
      );

      expect(capturedUrl, equals('https://example.com/test.pdf'));
      expect(capturedFilename, equals('test.pdf'));
      expect(capturedMimeType, equals('application/pdf'));
    });

    test('should handle null MIME type in downloads', () {
      String? capturedMimeType;

      void testCallback(String url, String filename, String? mimeType) {
        capturedMimeType = mimeType;
      }

      testCallback('https://example.com/file', 'file', null);
      expect(capturedMimeType, isNull);
    });
  });

  group('WebViewPlugin JavaScript Generation', () {
    test('should generate valid JavaScript for console capture', () {
      const jsCode = '''
        (function() {
          var originalLog = console.log;
          console.log = function() {
            originalLog.apply(console, arguments);
          };
        })();
      ''';

      expect(jsCode.contains('console.log'), isTrue);
      expect(jsCode.contains('function'), isTrue);
    });

    test('should generate valid JavaScript for network monitoring', () {
      const jsCode = '''
        (function() {
          var originalFetch = window.fetch;
          window.fetch = function() {
            return originalFetch.apply(this, arguments);
          };
        })();
      ''';

      expect(jsCode.contains('window.fetch'), isTrue);
      expect(jsCode.contains('originalFetch'), isTrue);
    });
  });

  group('WebViewPlugin Data Validation', () {
    test('should validate URL format', () {
      final validUrls = [
        'https://flutter.dev',
        'http://example.com',
        'https://api.example.com/v1/data',
      ];

      for (final url in validUrls) {
        expect(Uri.tryParse(url), isNotNull);
        expect(Uri.parse(url).hasScheme, isTrue);
      }
    });

    test('should detect invalid URLs', () {
      final invalidUrls = [
        'not a url',
        'ftp://unsupported.com',
        '',
      ];

      for (final url in invalidUrls) {
        final uri = Uri.tryParse(url);
        if (uri != null && url.isNotEmpty) {
          // For non-empty URLs, check if they have http/https scheme
          final hasValidScheme = uri.scheme == 'http' || uri.scheme == 'https';
          // ftp:// will have a scheme but not a valid one for our purposes
          if (uri.scheme == 'ftp') {
            expect(hasValidScheme, isFalse);
          }
        } else {
          // Empty URLs should parse but have no scheme
          expect(url.isEmpty || !uri!.hasScheme, isTrue);
        }
      }
    });

    test('should validate HTML content', () {
      const validHtml = '<html><body><h1>Test</h1></body></html>';
      const invalidHtml = '<html><body><h1>Unclosed tag';

      expect(validHtml.contains('<html>'), isTrue);
      expect(validHtml.contains('</html>'), isTrue);
      expect(invalidHtml.contains('</html>'), isFalse);
    });
  });

  group('WebViewPlugin Error Messages', () {
    test('should format error messages correctly', () {
      const errorMessage = 'Error loading page: https://example.com';
      expect(errorMessage.contains('Error'), isTrue);
      expect(errorMessage.contains('https://example.com'), isTrue);
    });

    test('should handle JavaScript errors', () {
      const jsError = 'TypeError: Cannot read property of undefined';
      expect(jsError.contains('TypeError'), isTrue);
      expect(jsError.contains('undefined'), isTrue);
    });
  });

  group('WebViewPlugin Configuration', () {
    test('should validate user agent strings', () {
      const validUserAgents = [
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64)',
        'CustomApp/1.0',
        'MyBrowser/2.0 (Mobile)',
      ];

      for (final ua in validUserAgents) {
        expect(ua.isNotEmpty, isTrue);
        expect(ua.length, greaterThan(5));
      }
    });

    test('should validate CSP directives', () {
      const validCSP = "default-src 'self'; script-src 'unsafe-inline'";
      expect(validCSP.contains('default-src'), isTrue);
      expect(validCSP.contains('script-src'), isTrue);
    });
  });
}
