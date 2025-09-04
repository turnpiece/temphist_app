import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Debug utility functions that are only active in debug mode
/// Uses kDebugMode for zero-cost production builds
class DebugUtils {
  /// Legacy: keep this if you still want to pass a string.
  /// Note: String building still happens even in production builds.
  static void log(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: $message');
    }
  }

  /// Preferred: pass a closure so expensive string building only runs if enabled.
  /// This is zero-cost in production builds - the closure is never called.
  static void logLazy(Object? Function() messageBuilder) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG: ${messageBuilder()}');
    }
  }
  
  /// Print debug message with timestamp
  static void logWithTimestamp(String message) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: $message');
    }
  }
  
  /// Print debug message with timestamp using lazy evaluation
  static void logWithTimestampLazy(Object? Function() messageBuilder) {
    if (kDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: ${messageBuilder()}');
    }
  }
  
  /// Print debug message with context
  static void logWithContext(String context, String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG [$context]: $message');
    }
  }
  
  /// Print debug message with context using lazy evaluation
  static void logWithContextLazy(String context, Object? Function() messageBuilder) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('DEBUG [$context]: ${messageBuilder()}');
    }
  }
  
  /// Print debug message only in verbose mode (for future use)
  static void verbose(String message) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('VERBOSE: $message');
    }
  }
  
  /// Print verbose message using lazy evaluation
  static void verboseLazy(Object? Function() messageBuilder) {
    if (kDebugMode) {
      // ignore: avoid_print
      print('VERBOSE: ${messageBuilder()}');
    }
  }
  
  /// Check if debug mode is enabled (uses kDebugMode for zero-cost)
  static bool get isEnabled => kDebugMode;
  
  /// Check if debug UI should be shown (still uses AppConfig for app-specific settings)
  static bool get shouldShowDebugUI => AppConfig.shouldShowDebugFeatures;
}
