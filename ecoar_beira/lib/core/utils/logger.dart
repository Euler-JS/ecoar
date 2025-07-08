import 'package:logger/logger.dart';

class AppLogger {
  static Logger? _logger;
  
  static void init() {
    _logger = Logger(
      printer: PrettyPrinter(
        methodCount: 2,
        errorMethodCount: 8,
        lineLength: 120,
        colors: true,
        printEmojis: true,
        printTime: true,
      ),
    );
  }
  
  static void d(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.d(message, error: error, stackTrace: stackTrace);
  }
  
  static void i(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.i(message, error: error, stackTrace: stackTrace);
  }
  
  static void w(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.w(message, error: error, stackTrace: stackTrace);
  }
  
  static void e(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger?.e(message, error: error, stackTrace: stackTrace);
  }
  
  static void logUserAction(String action, Map<String, dynamic>? data) {
    i('USER_ACTION: $action', data);
  }
  
  static void logApiCall(String endpoint, Map<String, dynamic>? data) {
    i('API_CALL: $endpoint', data);
  }
  
  static void logError(String context, dynamic error, StackTrace? stackTrace) {
    e('ERROR in $context', error, stackTrace);
  }
}