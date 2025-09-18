import 'package:shared_preferences/shared_preferences.dart';

class OnboardingService {
  static const String _onboardingSeenKey = 'onboarding_seen';

  /// Check if the user has completed onboarding
  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_onboardingSeenKey) ?? false;
  }

  /// Mark onboarding as completed
  static Future<void> markOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, true);
  }

  /// Reset onboarding status (useful for testing)
  static Future<void> resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_onboardingSeenKey);
  }

  /// Force show onboarding (useful for testing)
  static Future<void> forceShowOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_onboardingSeenKey, false);
  }
}
