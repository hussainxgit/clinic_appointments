// lib/core/utils/logger.dart
import 'package:flutter/foundation.dart';

class AppLogger {
  final String tag;
  
  AppLogger({required this.tag});
  
  void info(String message) {
    _log('INFO', message);
  }
  
  void warning(String message) {
    _log('WARNING', message);
  }
  
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log('ERROR', message);
    if (error != null) {
      debugPrint('ERROR: $error');
      if (stackTrace != null) {
        debugPrint('STACKTRACE: $stackTrace');
      }
    }
  }
  
  void _log(String level, String message) {
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] $level [$tag]: $message');
  }
}