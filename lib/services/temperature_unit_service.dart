import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/debug_utils.dart';

/// Manages the user's preferred temperature unit (Celsius vs Fahrenheit).
///
/// Persists the choice in SharedPreferences and exposes a [ValueNotifier]
/// so the UI can rebuild when the preference changes.
class TemperatureUnitService {
  static const _key = 'temperature_unit_fahrenheit';

  // Written by AppDelegate before the Flutter engine starts (iOS only).
  // Reflects MeasurementFormatter, which honours the iOS 16+ explicit
  // Temperature setting and falls back to the region default on iOS 15.
  static const _iosSystemKey = 'ios_system_temperature_fahrenheit';

  /// `true` when the user prefers Fahrenheit; `false` for Celsius.
  final ValueNotifier<bool> isFahrenheit = ValueNotifier(false);

  /// Load the stored preference, or auto-detect on first launch.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_key);
      if (stored != null) {
        isFahrenheit.value = stored;
      } else {
        // First launch — use the iOS system preference written to UserDefaults
        // by native code (null on Android), then fall back to locale country code.
        final systemPref = prefs.getBool(_iosSystemKey);
        final locale = PlatformDispatcher.instance.locale;
        isFahrenheit.value = systemPref ?? (locale.countryCode == 'US');
        DebugUtils.logLazy(() =>
            '🌡️ No stored unit preference — auto-detected '
            '${isFahrenheit.value ? "Fahrenheit" : "Celsius"} '
            '(systemPref: $systemPref, locale: ${locale.toLanguageTag()})');
      }
    } catch (e) {
      DebugUtils.logLazy(() => '🌡️ Failed to load unit preference: $e');
      // Default to Celsius on error.
    }
  }

  /// Update the preference and persist it.
  Future<void> setFahrenheit(bool value) async {
    isFahrenheit.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_key, value);
      DebugUtils.logLazy(() =>
          '🌡️ Unit preference saved: ${value ? "Fahrenheit" : "Celsius"}');
    } catch (e) {
      DebugUtils.logLazy(() => '🌡️ Failed to save unit preference: $e');
    }
  }
}
