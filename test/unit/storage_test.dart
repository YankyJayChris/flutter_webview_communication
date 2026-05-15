// Copyright (c) 2025 IGIHOZO Jean Christian. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.
// SPDX-License-Identifier: MIT

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WebViewPlugin MIME Type Categories', () {
    test('should detect all document types', () {
      final documents = {
        'file.pdf': 'application/pdf',
        'file.doc': 'application/msword',
        'file.docx':
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
        'file.xls': 'application/vnd.ms-excel',
        'file.xlsx':
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        'file.ppt': 'application/vnd.ms-powerpoint',
        'file.pptx':
            'application/vnd.openxmlformats-officedocument.presentationml.presentation',
        'file.txt': 'text/plain',
        'file.csv': 'text/csv',
      };

      documents.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should detect all image types', () {
      final images = {
        'img.jpg': 'image/jpeg',
        'img.jpeg': 'image/jpeg',
        'img.png': 'image/png',
        'img.gif': 'image/gif',
        'img.bmp': 'image/bmp',
        'img.webp': 'image/webp',
        'img.svg': 'image/svg+xml',
        'img.ico': 'image/x-icon',
      };

      images.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should detect all audio types', () {
      final audio = {
        'sound.mp3': 'audio/mpeg',
        'sound.wav': 'audio/wav',
        'sound.ogg': 'audio/ogg',
        'sound.aac': 'audio/aac',
        'sound.flac': 'audio/flac',
      };

      audio.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should detect all video types', () {
      final videos = {
        'video.mp4': 'video/mp4',
        'video.avi': 'video/x-msvideo',
        'video.mov': 'video/quicktime',
        'video.wmv': 'video/x-ms-wmv',
        'video.flv': 'video/x-flv',
        'video.mkv': 'video/x-matroska',
        'video.webm': 'video/webm',
      };

      videos.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should detect all archive types', () {
      final archives = {
        'file.zip': 'application/zip',
        'file.rar': 'application/x-rar-compressed',
        'file.7z': 'application/x-7z-compressed',
        'file.tar': 'application/x-tar',
        'file.gz': 'application/gzip',
      };

      archives.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should detect all web types', () {
      final web = {
        'page.html': 'text/html',
        'page.htm': 'text/html',
        'style.css': 'text/css',
        'script.js': 'application/javascript',
        'data.json': 'application/json',
        'data.xml': 'application/xml',
      };

      web.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should detect other types', () {
      final others = {
        'app.apk': 'application/vnd.android.package-archive',
        'installer.exe': 'application/x-msdownload',
        'disk.dmg': 'application/x-apple-diskimage',
      };

      others.forEach((filename, expectedMime) {
        expect(WebViewPlugin.getMimeTypeStatic(filename), equals(expectedMime));
      });
    });

    test('should handle case-insensitive file extensions', () {
      expect(WebViewPlugin.getMimeTypeStatic('FILE.PDF'),
          equals('application/pdf'));
      expect(
          WebViewPlugin.getMimeTypeStatic('Image.JPG'), equals('image/jpeg'));
      expect(WebViewPlugin.getMimeTypeStatic('VIDEO.MP4'), equals('video/mp4'));
    });

    test('should handle files with multiple dots', () {
      expect(WebViewPlugin.getMimeTypeStatic('my.file.name.pdf'),
          equals('application/pdf'));
      expect(WebViewPlugin.getMimeTypeStatic('archive.tar.gz'),
          equals('application/gzip'));
    });

    test('should handle files without extension', () {
      expect(
        WebViewPlugin.getMimeTypeStatic('README'),
        equals('application/octet-stream'),
      );
      expect(
        WebViewPlugin.getMimeTypeStatic('Makefile'),
        equals('application/octet-stream'),
      );
    });
  });

  group('WebViewPlugin File Path Handling', () {
    test('should extract file extension correctly', () {
      expect('document.pdf'.split('.').last, equals('pdf'));
      expect('image.jpg'.split('.').last, equals('jpg'));
      expect('archive.tar.gz'.split('.').last, equals('gz'));
    });

    test('should handle paths with directories', () {
      expect('/path/to/file.pdf'.split('.').last, equals('pdf'));
      expect('C:\\Users\\file.docx'.split('.').last, equals('docx'));
    });

    test('should handle URLs', () {
      expect('https://example.com/file.pdf'.split('.').last, equals('pdf'));
      expect('http://test.com/download.zip'.split('.').last, equals('zip'));
    });
  });
}
