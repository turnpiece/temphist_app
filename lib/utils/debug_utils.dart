import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

/// Centralized debug utility functions that are only active in debug mode
/// Uses kDebugMode for zero-cost production builds
class DebugUtils {
  /// Main debug logging method - pass a closure so expensive string building only runs if enabled.
  /// This is zero-cost in production builds - the closure is never called.
  /// Use this for all new debug logging.
  static void logLazy(Object? Function() messageBuilder) {
    if (isEnabled) {
      // ignore: avoid_print
      print('DEBUG: ${messageBuilder()}');
    }
  }

  /// Print debug message with timestamp
  static void logWithTimestamp(String message) {
    if (isEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: $message');
    }
  }
  
  /// Print debug message with timestamp using lazy evaluation
  static void logWithTimestampLazy(Object? Function() messageBuilder) {
    if (isEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('DEBUG [$timestamp]: ${messageBuilder()}');
    }
  }
  
  /// Print debug message with context
  static void logWithContext(String context, String message) {
    if (isEnabled) {
      // ignore: avoid_print
      print('DEBUG [$context]: $message');
    }
  }
  
  /// Print debug message with context using lazy evaluation
  static void logWithContextLazy(String context, Object? Function() messageBuilder) {
    if (isEnabled) {
      // ignore: avoid_print
      print('DEBUG [$context]: ${messageBuilder()}');
    }
  }
  
  /// Print debug message only in verbose mode
  /// Uses verboseLogs constant for production builds
  static void verbose(String message) {
    if (isVerboseEnabled) {
      // ignore: avoid_print
      print('VERBOSE: $message');
    }
  }
  
  /// Print verbose message using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseLazy(Object? Function() messageBuilder) {
    if (isVerboseEnabled) {
      // ignore: avoid_print
      print('VERBOSE: ${messageBuilder()}');
    }
  }
  
  /// Print verbose message with timestamp
  /// Uses verboseLogs constant for production builds
  static void verboseWithTimestamp(String message) {
    if (isVerboseEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('VERBOSE [$timestamp]: $message');
    }
  }
  
  /// Print verbose message with timestamp using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseWithTimestampLazy(Object? Function() messageBuilder) {
    if (isVerboseEnabled) {
      final timestamp = DateTime.now().toIso8601String();
      // ignore: avoid_print
      print('VERBOSE [$timestamp]: ${messageBuilder()}');
    }
  }
  
  /// Print verbose message with context
  /// Uses verboseLogs constant for production builds
  static void verboseWithContext(String context, String message) {
    if (isVerboseEnabled) {
      // ignore: avoid_print
      print('VERBOSE [$context]: $message');
    }
  }
  
  /// Print verbose message with context using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseWithContextLazy(String context, Object? Function() messageBuilder) {
    if (isVerboseEnabled) {
      // ignore: avoid_print
      print('VERBOSE [$context]: ${messageBuilder()}');
    }
  }
  
  static bool get isEnabled => kDebugMode;
  static bool get isVerboseEnabled => kDebugMode || verboseLogs;
}
