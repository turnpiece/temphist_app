import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'debug_utils.dart';

/// Sends diagnostically useful client-side events to Firebase Crashlytics so
/// they're visible in production/TestFlight builds, not just in a debug
/// console. Unlike [DebugUtils], these calls are active in all build modes.
///
/// Failures here are always swallowed — logging must never affect the core
/// app experience.
class RemoteLogger {
  /// Records that the async job pipeline failed and the app fell back to the
  /// synchronous endpoint. Logged as a non-fatal error so it shows up
  /// (with breadcrumbs and a stack trace) in the Crashlytics dashboard.
  static Future<void> logAsyncFallback({
    required String period,
    required String location,
    required Object exception,
    StackTrace? stackTrace,
  }) async {
    await _recordNonFatal(
      'Async fallback: period=$period location=$location exceptionType=${exception.runtimeType}',
      exception,
      stackTrace,
      reason: 'async_fallback',
    );
  }

  /// Records an API error that was surfaced to the user as an error message.
  static Future<void> logApiError({
    required String period,
    required String location,
    required Object exception,
    StackTrace? stackTrace,
  }) async {
    await _recordNonFatal(
      'API error: period=$period location=$location exceptionType=${exception.runtimeType}',
      exception,
      stackTrace,
      reason: 'api_error',
    );
  }

  static Future<void> _recordNonFatal(
      String breadcrumb, Object exception, StackTrace? stackTrace,
      {required String reason}) async {
    try {
      final crashlytics = FirebaseCrashlytics.instance;
      crashlytics.log(breadcrumb);
      await crashlytics.recordError(
        exception,
        stackTrace,
        reason: reason,
        fatal: false,
      );
    } catch (e) {
      DebugUtils.logLazy(
          () => 'RemoteLogger: recordError failed (swallowed): $e');
    }
  }
}
