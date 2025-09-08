import 'package:flutter/foundation.dart';
import '../config/app_config.dart';
import '../constants.dart';

/// Centralized debug utility functions that are only active in debug mode
/// Uses kDebugMode for zero-cost production builds
class DebugUtils {
  /// Legacy: keep this if you still want to pass a string.
  /// Note: String building still happens even in production builds.
  @Deprecated('Use DebugUtils.logLazy(() => ...) instead for zero-cost when disabled.')
  static void log(String message) {
    if (kDebugMode && AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG: $message');
    }
  }

  /// Main debug logging method - pass a closure so expensive string building only runs if enabled.
  /// This is zero-cost in production builds - the closure is never called.
  /// Use this for all new debug logging.
  static void logLazy(Object? Function() messageBuilder) {
    if (kDebugMode && AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG: ${messageBuilder()}');
    }
  }

  /// Convenience method for simple string messages
  /// Use logLazy() for better performance with complex string building
  static void logSimple(String message) {
    if (kDebugMode && AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG: $message');
    }
  }
  
  /// Print debug message with timestamp
  static void logWithTimestamp(String message) {
    if (kDebugMode && AppConfig.isDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: $message');
    }
  }
  
  /// Print debug message with timestamp using lazy evaluation
  static void logWithTimestampLazy(Object? Function() messageBuilder) {
    if (kDebugMode && AppConfig.isDebugMode) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: ${messageBuilder()}');
    }
  }
  
  /// Print debug message with context
  static void logWithContext(String context, String message) {
    if (kDebugMode && AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG [$context]: $message');
    }
  }
  
  /// Print debug message with context using lazy evaluation
  static void logWithContextLazy(String context, Object? Function() messageBuilder) {
    if (kDebugMode && AppConfig.isDebugMode) {
      // ignore: avoid_print
      print('DEBUG [$context]: ${messageBuilder()}');
    }
  }
  
  /// Print debug message only in verbose mode
  /// Uses verboseLogs constant for production builds
  static void verbose(String message) {
    if ((kDebugMode && AppConfig.isDebugMode) || verboseLogs) {
      // ignore: avoid_print
      print('VERBOSE: $message');
    }
  }
  
  /// Print verbose message using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseLazy(Object? Function() messageBuilder) {
    if ((kDebugMode && AppConfig.isDebugMode) || verboseLogs) {
      // ignore: avoid_print
      print('VERBOSE: ${messageBuilder()}');
    }
  }
  
  /// Print verbose message with timestamp
  /// Uses verboseLogs constant for production builds
  static void verboseWithTimestamp(String message) {
    if ((kDebugMode && AppConfig.isDebugMode) || verboseLogs) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('VERBOSE [$timestamp]: $message');
    }
  }
  
  /// Print verbose message with timestamp using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseWithTimestampLazy(Object? Function() messageBuilder) {
    if ((kDebugMode && AppConfig.isDebugMode) || verboseLogs) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('VERBOSE [$timestamp]: ${messageBuilder()}');
    }
  }
  
  /// Print verbose message with context
  /// Uses verboseLogs constant for production builds
  static void verboseWithContext(String context, String message) {
    if ((kDebugMode && AppConfig.isDebugMode) || verboseLogs) {
      // ignore: avoid_print
      print('VERBOSE [$context]: $message');
    }
  }
  
  /// Print verbose message with context using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseWithContextLazy(String context, Object? Function() messageBuilder) {
    if ((kDebugMode && AppConfig.isDebugMode) || verboseLogs) {
      // ignore: avoid_print
      print('VERBOSE [$context]: ${messageBuilder()}');
    }
  }
  
  /// Check if debug mode is enabled (uses kDebugMode and custom config for zero-cost)
  static bool get isEnabled => kDebugMode && AppConfig.isDebugMode;
  
  /// Check if verbose logging is enabled (uses verboseLogs constant)
  static bool get isVerboseEnabled => (kDebugMode && AppConfig.isDebugMode) || verboseLogs;
  
  /// Check if debug UI should be shown (still uses AppConfig for app-specific settings)
  static bool get shouldShowDebugUI => AppConfig.shouldShowDebugFeatures;
}
