import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum LogLevel { debug, info, warning, error, fatal }

class AppLogger {
  // Simple constructor
  AppLogger();

  void debug(String tag, String message) {
    print('[DEBUG] $tag: $message');
  }

  void info(String tag, String message) {
    print('[INFO] $tag: $message');
  }

  void warning(String tag, String message) {
    print('[WARNING] $tag: $message');
  }

  void error(String tag, String message, [StackTrace? stackTrace]) {
    print('[ERROR] $tag: $message');
    if (stackTrace != null) {
      print('Stack trace: $stackTrace');
    }
  }

  void performance(String operation, int milliseconds, [Map<String, dynamic>? metadata]) {
    info('PERFORMANCE', '$operation completed in ${milliseconds}ms${metadata != null ? ' - $metadata' : ''}');
  }

  void mapEvent(String event, Map<String, dynamic> data) {
    debug('MAP_EVENT', '$event: $data');
  }

  // Navigation events - Takes event name and data map
  void navigationEvent(String event, Map<String, dynamic> data) {
    info('NAVIGATION', '$event: $data');
  }

  // Auth events (missing method - added)
  void authEvent(String event, String message) {
    info('AUTH', '$event: $message');
  }

  void userEvent(String event, Map<String, dynamic> data) {
    info('USER_EVENT', '$event: $data');
  }

  void systemEvent(String event, Map<String, dynamic> data) {
    info('SYSTEM', '$event: $data');
  }

  void analyticsEvent(String event, Map<String, dynamic> data) {
    info('ANALYTICS', '$event: $data');
  }
}