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

  /// Print verbose message using lazy evaluation
  /// Uses verboseLogs constant for production builds
  static void verboseLazy(Object? Function() messageBuilder) {
    if (isVerboseEnabled) {
      // ignore: avoid_print
      print('VERBOSE: ${messageBuilder()}');
    }
  }

  /// Print verbose message with context using lazy evaluation
  static void verboseWithContextLazy(
      String context, Object? Function() messageBuilder) {
    if (isVerboseEnabled) {
      // ignore: avoid_print
      print('VERBOSE [$context]: ${messageBuilder()}');
    }
  }

  static bool get isEnabled => kDebugMode;
  static bool get isVerboseEnabled => verboseLogs;
}
