import 'package:flutter/foundation.dart';

import 'package:flutter/foundation.dart';

class CustomDebugFunction {
  static void log(dynamic message) {
    if (kDebugMode) {
      _printFull(message.toString());
    }
  }

  static void error(dynamic message, [Object? error]) {
    if (kDebugMode) {
      _printFull('❌ $message');
      if (error != null) {
        _printFull(error.toString());
      }
    }
  }

  static void _printFull(String text) {
    const int chunkSize = 800; // safe limit
    for (int i = 0; i < text.length; i += chunkSize) {
      debugPrint(
        text.substring(
          i,
          i + chunkSize > text.length ? text.length : i + chunkSize,
        ),
      );
    }
  }
}