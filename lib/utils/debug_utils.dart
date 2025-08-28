import '../config/app_config.dart';

/// Debug utility functions that are only active in debug mode
class DebugUtils {
  /// Print debug message only if debug mode is enabled
  static void log(String message) {
    if (AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG: $message');
    }
  }
  
  /// Print debug message with timestamp
  static void logWithTimestamp(String message) {
    if (AppConfig.isDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: $message');
    }
  }
  
  /// Print debug message with context
  static void logWithContext(String context, String message) {
    if (AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG [$context]: $message');
    }
  }
  
  /// Print debug message only in verbose mode (for future use)
  static void verbose(String message) {
    if (AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('VERBOSE: $message');
    }
  }
  
  /// Check if debug mode is enabled
  static bool get isEnabled => AppConfig.isDebugMode;
  
  /// Check if debug UI should be shown
  static bool get shouldShowDebugUI => AppConfig.shouldShowDebugFeatures;
}
