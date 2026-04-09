import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_constants.dart';
import '../models/app_exceptions.dart';
import '../utils/debug_utils.dart';

/// Shared Firebase anonymous authentication with retry and exponential backoff.
///
/// Used by both app startup ([rethrowOnFailure] = false, so the app can
/// continue in a degraded state) and service-level auth ([rethrowOnFailure]
/// = true, so API calls fail fast with a typed exception).
class AuthService {
  AuthService._();

  static Future<void> signInAnonymously({
    int maxRetries = 3,
    bool rethrowOnFailure = true,
  }) async {
    int attempts = 0;

    while (attempts < maxRetries) {
      try {
        attempts++;
        DebugUtils.logLazy(
            () => '🔐 Firebase auth attempt $attempts/$maxRetries');

        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: kFirebaseAuthTimeoutSeconds),
          onTimeout: () {
            throw TimeoutException(
              'Firebase authentication timed out',
              const Duration(seconds: kFirebaseAuthTimeoutSeconds),
            );
          },
        );

        DebugUtils.logLazy(() => '✅ Firebase authentication successful');
        return;
      } catch (e) {
        DebugUtils.logLazy(
            () => '❌ Firebase auth attempt $attempts failed: $e');

        if (attempts >= maxRetries) {
          if (rethrowOnFailure) {
            throw AuthException('all $maxRetries auth attempts failed', e);
          }
          DebugUtils.logLazy(
              () => '⚠️ All auth attempts failed, continuing without authentication');
          return;
        }

        // Exponential backoff: 2 s, 4 s, 6 s, …
        final delay = Duration(seconds: attempts * 2);
        DebugUtils.logLazy(
            () => '⏳ Waiting ${delay.inSeconds}s before retry...');
        await Future.delayed(delay);
      }
    }
  }
}
