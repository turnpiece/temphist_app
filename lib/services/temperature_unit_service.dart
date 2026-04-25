import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/debug_utils.dart';

/// Manages the user's preferred temperature unit (Celsius vs Fahrenheit).
///
/// Persists the choice in SharedPreferences and exposes a [ValueNotifier]
/// so the UI can rebuild when the preference changes.
class TemperatureUnitService {
  static const _key = 'temperature_unit_fahrenheit';
  static const _channel = MethodChannel('com.turnpiece.temphist/system_prefs');

  static Future<bool?> _systemPrefersFahrenheit() async {
    try {
      return await _channel.invokeMethod<bool>('getTemperatureUnitIsFahrenheit');
    } catch (_) {
      return null; // Android, or any channel failure — caller falls back to locale
    }
  }

  /// `true` when the user prefers Fahrenheit; `false` for Celsius.
  final ValueNotifier<bool> isFahrenheit = ValueNotifier(false);

  /// Load the stored preference, or auto-detect from the platform locale
  /// on first launch (Fahrenheit for US, Celsius otherwise).
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getBool(_key);
      if (stored != null) {
        isFahrenheit.value = stored;
      } else {
        // First launch — try iOS system preference (MeasurementFormatter respects
        // the explicit iOS 16+ toggle; on iOS 15 it falls back to region default).
        // On Android the channel call returns null and we fall back to country code.
        final systemPref = await _systemPrefersFahrenheit();
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
