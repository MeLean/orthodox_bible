import 'package:flutter/foundation.dart';

class AppLogger {
  static const String _tag = "[BIBLE_APP_LOGGING]";

  /// Logs info messages (Firebase Analytics + Debug Console)
  static void info(String message) {
    debugPrint("$_tag $message");
  }

  /// Logs error messages (Firebase Crashlytics)
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint("$_tag ❌ ERROR: $message");
    debugPrint("$_tag ${stackTrace?.toString() ?? ""}");
  }
}
