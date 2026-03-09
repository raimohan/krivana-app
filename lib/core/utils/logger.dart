import 'package:flutter/foundation.dart';

class AppLogger {
  static void info(String message) {
    debugPrint('[INFO] $message');
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('[ERROR] $message');
    if (error != null) debugPrint('  → $error');
    if (stack != null) debugPrint('  → $stack');
  }

  static void warning(String message) {
    debugPrint('[WARN] $message');
  }
}
