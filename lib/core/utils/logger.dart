// lib/core/utils/logger.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLogger {
  final String tag;
  
  AppLogger({required this.tag});
  
  void info(String message) => print('INFO [$tag]: $message');
  void warning(String message) => print('WARNING [$tag]: $message');
  void error(String message, [Object? error, StackTrace? stackTrace]) {
    print('ERROR [$tag]: $message');
    if (error != null) print('ERROR: $error');
  }
}

// Riverpod provider for logger
final loggerProvider = Provider.family<AppLogger, String>((ref, tag) => AppLogger(tag: tag));