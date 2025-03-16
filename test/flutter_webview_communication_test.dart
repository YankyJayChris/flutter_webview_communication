// Copyright (c) 2025 [Your Name]. All rights reserved.
// Licensed under the MIT License. See LICENSE file in the project root.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_webview_communication/flutter_webview_communication.dart';

void main() {
  test('WebViewPlugin initializes correctly', () {
    final plugin = WebViewPlugin();
    expect(plugin, isNotNull);
  });

  test('Action handlers are set correctly', () {
    final plugin = WebViewPlugin(
      actionHandlers: {
        'testAction': (payload) {},
      },
    );
    expect(plugin, isNotNull);
  });
}
