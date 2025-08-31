import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

enum LogLevel { debug, info, warning, error, fatal }

class AppLogger {
  static AppLogger? _instance;
  static AppLogger get instance => _instance ??= AppLogger._();
  
  AppLogger._();

  static const int maxFileSizeBytes = 1024 * 1024; // 1MB
  static const int maxLogFiles = 5; // Keep 5 log files (current + 4 backups)
  static const String logFileName = 'offline_map_app.log';
  
  File? _currentLogFile;
  bool _isInitialized = false;

  /// Initialize the logger
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      final directory = await getApplicationDocumentsDirectory();
      final logDir = Directory(path.join(directory.path, 'logs'));
      
      // Create logs directory if it doesn't exist
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      _currentLogFile = File(path.join(logDir.path, logFileName));
      
      // Create log file if it doesn't exist
      if (!await _currentLogFile!.exists()) {
        await _currentLogFile!.create();
      }
      
      _isInitialized = true;
      
      // Log initialization
      await _writeLog(LogLevel.info, 'Logger', 'Logger initialized successfully');
      await _writeLog(LogLevel.info, 'Logger', 'Log file path: ${_currentLogFile!.path}');
      
    } catch (e) {
      print('Failed to initialize logger: $e');
      // Fallback: continue without file logging
      _isInitialized = false;
    }
  }

  /// Get the current log file path
  String? get logFilePath => _currentLogFile?.path;

  /// Get all log files
  Future<List<File>> getLogFiles() async {
    if (!_isInitialized || _currentLogFile == null) return [];
    
    try {
      final logDir = _currentLogFile!.parent;
      final files = await logDir.list().toList();
      
      return files
          .whereType<File>()
          .where((file) => path.basename(file.path).startsWith('offline_map_app'))
          .toList()
        ..sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    } catch (e) {
      print('Error getting log files: $e');
      return [];
    }
  }

  /// Debug level logging
  Future<void> debug(String tag, String message) async {
    await _writeLog(LogLevel.debug, tag, message);
  }

  /// Info level logging
  Future<void> info(String tag, String message) async {
    await _writeLog(LogLevel.info, tag, message);
  }

  /// Warning level logging
  Future<void> warning(String tag, String message) async {
    await _writeLog(LogLevel.warning, tag, message);
  }

  /// Error level logging
  Future<void> error(String tag, String message, [Object? error, StackTrace? stackTrace]) async {
    String fullMessage = message;
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    await _writeLog(LogLevel.error, tag, fullMessage);
  }

  /// Fatal level logging
  Future<void> fatal(String tag, String message, [Object? error, StackTrace? stackTrace]) async {
    String fullMessage = message;
    if (error != null) {
      fullMessage += '\nError: $error';
    }
    if (stackTrace != null) {
      fullMessage += '\nStackTrace: $stackTrace';
    }
    await _writeLog(LogLevel.fatal, tag, fullMessage);
  }

  /// Log map events specifically
  Future<void> mapEvent(String event, Map<String, dynamic> data) async {
    final dataStr = jsonEncode(data);
    await info('MAP_EVENT', '$event: $dataStr');
  }

  /// Log authentication events
  Future<void> authEvent(String event, String details) async {
    await info('AUTH', '$event: $details');
  }

  /// Log layer events
  Future<void> layerEvent(String event, String layerName, bool isVisible) async {
    await info('LAYER', '$event: $layerName (visible: $isVisible)');
  }

  /// Log navigation events
  Future<void> navigationEvent(String from, String to, String level) async {
    await info('NAVIGATION', 'Navigate from $from to $to (level: $level)');
  }

  /// Log performance metrics
  Future<void> performance(String operation, int durationMs, Map<String, dynamic>? metadata) async {
    String message = '$operation completed in ${durationMs}ms';
    if (metadata != null) {
      message += ' - ${jsonEncode(metadata)}';
    }
    await info('PERFORMANCE', message);
  }

  /// Write log entry to file
  Future<void> _writeLog(LogLevel level, String tag, String message) async {
    try {
      // Also print to console for immediate debugging
      final timestamp = DateTime.now().toIso8601String();
      final levelStr = level.name.toUpperCase().padRight(7);
      final tagStr = tag.padRight(15);
      final logEntry = '$timestamp [$levelStr] $tagStr: $message';
      
      print(logEntry); // Console output
      
      if (!_isInitialized || _currentLogFile == null) return;
      
      // Check if rotation is needed
      await _rotateLogIfNeeded();
      
      // Write to file
      await _currentLogFile!.writeAsString(
        '$logEntry\n',
        mode: FileMode.append,
        encoding: utf8,
      );
      
    } catch (e) {
      print('Error writing log: $e');
    }
  }

  /// Rotate log file if it exceeds size limit
  Future<void> _rotateLogIfNeeded() async {
    if (_currentLogFile == null || !await _currentLogFile!.exists()) return;
    
    try {
      final fileSize = await _currentLogFile!.length();
      
      if (fileSize >= maxFileSizeBytes) {
        await _rotateLogFiles();
      }
    } catch (e) {
      print('Error checking log file size: $e');
    }
  }

  /// Rotate log files (rename current to backup, create new current)
  Future<void> _rotateLogFiles() async {
    if (_currentLogFile == null) return;
    
    try {
      final logDir = _currentLogFile!.parent;
      final baseName = 'offline_map_app';
      
      // Remove oldest backup if it exists
      final oldestBackup = File(path.join(logDir.path, '$baseName.${maxLogFiles - 1}.log'));
      if (await oldestBackup.exists()) {
        await oldestBackup.delete();
      }
      
      // Shift existing backups
      for (int i = maxLogFiles - 2; i >= 1; i--) {
        final currentBackup = File(path.join(logDir.path, '$baseName.$i.log'));
        if (await currentBackup.exists()) {
          final newBackup = File(path.join(logDir.path, '$baseName.${i + 1}.log'));
          await currentBackup.rename(newBackup.path);
        }
      }
      
      // Move current log to .1 backup
      final firstBackup = File(path.join(logDir.path, '$baseName.1.log'));
      await _currentLogFile!.rename(firstBackup.path);
      
      // Create new current log file
      _currentLogFile = File(path.join(logDir.path, logFileName));
      await _currentLogFile!.create();
      
      await _writeLog(LogLevel.info, 'Logger', 'Log file rotated');
      
    } catch (e) {
      print('Error rotating log files: $e');
    }
  }

  /// Clear all log files
  Future<void> clearLogs() async {
    try {
      final files = await getLogFiles();
      for (final file in files) {
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      // Recreate current log file
      if (_currentLogFile != null) {
        await _currentLogFile!.create();
        await _writeLog(LogLevel.info, 'Logger', 'All logs cleared');
      }
    } catch (e) {
      print('Error clearing logs: $e');
    }
  }

  /// Get log file content as string
  Future<String> getLogContent([File? logFile]) async {
    try {
      final file = logFile ?? _currentLogFile;
      if (file == null || !await file.exists()) return '';
      
      return await file.readAsString();
    } catch (e) {
      print('Error reading log content: $e');
      return 'Error reading log file: $e';
    }
  }

  /// Get formatted log statistics
  Future<Map<String, dynamic>> getLogStats() async {
    try {
      final files = await getLogFiles();
      int totalSize = 0;
      int totalLines = 0;
      
      for (final file in files) {
        if (await file.exists()) {
          totalSize += await file.length();
          final content = await file.readAsString();
          totalLines += content.split('\n').length - 1;
        }
      }
      
      return {
        'totalFiles': files.length,
        'totalSizeBytes': totalSize,
        'totalSizeKB': (totalSize / 1024).round(),
        'totalLines': totalLines,
        'currentLogFile': path.basename(_currentLogFile?.path ?? 'Unknown'),
        'isInitialized': _isInitialized,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }
}