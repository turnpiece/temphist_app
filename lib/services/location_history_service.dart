import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/location_visit.dart';
import '../utils/debug_utils.dart';

/// Persists a list of GPS-detected location visits (location + timestamp).
///
/// Only locations resolved via GPS are stored here. Manually selected
/// locations (from the location selector) are never added.
class LocationHistoryService {
  static const String _kHistoryKey = 'locationHistory';
  static const int _kMaxEntries = 50;

  /// Add [visit] to the front of the history list.
  ///
  /// Skips silently if the same location was already recorded today (same
  /// calendar day in local time), to avoid duplicate entries for a single
  /// session. Caps the list at [_kMaxEntries].
  static Future<void> add(LocationVisit visit) async {
    if (visit.location.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await _decode(prefs.getString(_kHistoryKey));

      // Deduplicate: skip if this location was already recorded today.
      final today = _calendarDay(visit.visitedAt);
      final alreadyToday = current.any(
        (v) =>
            v.location == visit.location && _calendarDay(v.visitedAt) == today,
      );
      if (alreadyToday) {
        DebugUtils.logLazy(() =>
            'LocationHistoryService: skipping duplicate for today: ${visit.location}');
        return;
      }

      current.insert(0, visit);
      if (current.length > _kMaxEntries) {
        current.removeRange(_kMaxEntries, current.length);
      }
      await prefs.setString(
          _kHistoryKey, jsonEncode(current.map((v) => v.toJson()).toList()));
      DebugUtils.logLazy(
          () => 'Location history updated: ${current.length} entries');
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationHistoryService.add failed: $e');
    }
  }

  /// Returns all stored visits, newest first. Empty list on any error.
  static Future<List<LocationVisit>> getAll() async {
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

  /// Parses stored JSON into a list of [LocationVisit].
  ///
  /// Handles the legacy format (a JSON array of plain strings) by converting
  /// each string into a [LocationVisit] with [DateTime.now()] as a fallback
  /// timestamp, so existing users don't lose their history on upgrade.
  static Future<List<LocationVisit>> _decode(String? raw) async {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];

      return decoded.map<LocationVisit>((item) {
        if (item is String) {
          // Legacy format: plain location string with no timestamp.
          return LocationVisit(
            location: item,
            displayLocation: item.split(',').first.trim(),
            visitedAt: DateTime.now(),
          );
        }
        return LocationVisit.fromJson(item as Map<String, dynamic>);
      }).toList();
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationHistoryService._decode failed: $e');
      return [];
    }
  }

  /// Returns a comparable string for the calendar day of [dt] in local time.
  static String _calendarDay(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
}
