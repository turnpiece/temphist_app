import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../utils/debug_utils.dart';

/// Persists a list of GPS-detected locations visited by the user.
///
/// Only locations resolved via GPS are stored here. Manually selected
/// locations (from the location selector) are never added.
class LocationHistoryService {
  static const String _kHistoryKey = 'locationHistory';
  static const int _kMaxEntries = 10;

  /// Add [location] (API string, e.g. "London, UK") to the front of the
  /// history list, deduplicating and capping at [_kMaxEntries].
  static Future<void> add(String location) async {
    if (location.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = _decode(prefs.getString(_kHistoryKey));
      current.remove(location); // deduplicate
      current.insert(0, location);
      if (current.length > _kMaxEntries) {
        current.removeRange(_kMaxEntries, current.length);
      }
      await prefs.setString(_kHistoryKey, jsonEncode(current));
      DebugUtils.logLazy(() => 'Location history updated: ${current.length} entries');
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationHistoryService.add failed: $e');
    }
  }

  /// Returns all stored locations, newest first. Empty list on any error.
  static Future<List<String>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _decode(prefs.getString(_kHistoryKey));
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationHistoryService.getAll failed: $e');
      return [];
    }
  }

  /// Clears all stored location history.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kHistoryKey);
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationHistoryService.clear failed: $e');
    }
  }

  static List<String> _decode(String? raw) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) return decoded.cast<String>();
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationHistoryService._decode failed: $e');
    }
    return [];
  }
}
