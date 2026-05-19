import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../models/location_selection.dart';
import '../utils/debug_utils.dart';

/// Persists a list of manually-selected locations with selection counts.
///
/// Only locations chosen explicitly by the user are stored here; GPS-detected
/// locations are tracked separately by LocationHistoryService. Entries are
/// sorted by count descending so the most-selected cities surface first in the
/// Popular section of the location selector.
class LocationSelectionService {
  static const String _kKey = 'locationSelectionHistory';
  static const int _kMaxEntries = kLocationSelectionHistoryMaxEntries;

  /// Record that [apiLocation] was manually selected.
  ///
  /// If the location already exists its count is incremented and [selectedAt]
  /// is updated to now. Otherwise a new entry with count=1 is added. The list
  /// is sorted by count desc and capped at [_kMaxEntries] (least-selected
  /// entries are dropped when the cap is hit).
  static Future<void> record(String apiLocation) async {
    if (apiLocation.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _decode(prefs.getString(_kKey));
      final now = DateTime.now();
      final displayLocation = apiLocation.split(',').first.trim();

      final idx = entries.indexWhere((e) => e.location == apiLocation);
      if (idx >= 0) {
        if (now.difference(entries[idx].selectedAt).inHours < 24) return;
        entries[idx] = entries[idx].increment(now);
      } else {
        entries.add(LocationSelection(
          location: apiLocation,
          displayLocation: displayLocation,
          selectedAt: now,
          count: 1,
        ));
      }

      entries.sort((a, b) => b.count.compareTo(a.count));
      if (entries.length > _kMaxEntries) {
        entries.removeRange(_kMaxEntries, entries.length);
      }

      await prefs.setString(
          _kKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
      DebugUtils.logLazy(() {
        final count = entries
            .firstWhere((e) => e.location == apiLocation,
                orElse: () => entries.first)
            .count;
        return 'LocationSelectionService: recorded $apiLocation (count=$count)';
      });
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationSelectionService.record failed: $e');
    }
  }

  /// Returns all entries sorted by count descending. Empty list on any error.
  static Future<List<LocationSelection>> getAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final entries = _decode(prefs.getString(_kKey));
      entries.sort((a, b) => b.count.compareTo(a.count));
      return entries;
    } catch (e) {
      DebugUtils.logLazy(
          () => 'LocationSelectionService.getAll failed: $e');
      return [];
    }
  }

  /// Clears all stored selection history.
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kKey);
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationSelectionService.clear failed: $e');
    }
  }

  static List<LocationSelection> _decode(String? raw) {
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return [];
      return decoded
          .map((item) =>
              LocationSelection.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      DebugUtils.logLazy(
          () => 'LocationSelectionService._decode failed: $e');
      return [];
    }
  }
}
