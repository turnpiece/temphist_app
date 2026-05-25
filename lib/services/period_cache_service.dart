import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/period_temperature_data.dart';
import '../utils/debug_utils.dart';

/// Hive-backed disk cache for all period temperature responses
/// (daily, week, month, year).
///
/// Key format: `{period}:{lat:.3f}:{lon:.3f}:{identifier}[:{unitGroup}]`
///   - daily  → identifier is `yyyy-MM-dd`
///   - others → identifier is `MM-dd`
///   - unitGroup is appended only when non-Celsius (e.g. `:fahrenheit`)
///
/// TTL: 7 days.
///
/// All methods are no-ops (return null/false) if [init] has not been called.
class PeriodCacheService {
  static const _boxName = 'period_cache';
  static const _ttl = Duration(days: 7);

  static Box? _box;

  /// Initialise the Hive box. Call once in [main] before [runApp].
  ///
  /// Pass [path] in tests to use a temporary directory instead of the
  /// app documents directory.
  static Future<void> init({String? path}) async {
    if (path != null) {
      Hive.init(path);
    } else {
      await Hive.initFlutter();
    }
    _box = await Hive.openBox(_boxName);
    DebugUtils.logLazy(
      () => 'PeriodCacheService: opened (${_box!.length} entries)',
    );
  }

  /// Close the box. Used in tests; also safe to call on app detach.
  static Future<void> close() async {
    await _box?.close();
    _box = null;
  }

  /// Returns `true` if a non-expired entry exists for [period], [lat], [lon],
  /// [identifier].
  static bool exists(
    String period,
    double lat,
    double lon,
    String identifier, {
    String? unitGroup,
    String? localToday,
  }) {
    try {
      final raw = _box?.get(_key(period, lat, lon, identifier,
          unitGroup: unitGroup, localToday: localToday));
      if (raw == null || raw is! Map) return false;
      final map = Map<String, dynamic>.from(raw);
      return !_isExpired(map);
    } catch (_) {
      return false;
    }
  }

  /// Returns cached data, or `null` on miss or expiry.
  /// Expired entries are deleted automatically.
  static Future<PeriodTemperatureData?> get(
    String period,
    double lat,
    double lon,
    String identifier, {
    String? unitGroup,
    String? localToday,
  }) async {
    final box = _box;
    if (box == null) return null;

    final key = _key(period, lat, lon, identifier,
        unitGroup: unitGroup, localToday: localToday);
    try {
      final raw = box.get(key);
      if (raw == null || raw is! Map) return null;

      final map = Map<String, dynamic>.from(raw);
      final cachedAtValue = map['_cachedAt'];
      if (cachedAtValue is! int) {
        await box.delete(key);
        return null;
      }

      if (_isExpired(map)) {
        await box.delete(key);
        DebugUtils.logLazy(() => 'PeriodCacheService: expired → deleted ($key)');
        return null;
      }

      final dataStr = map['data'];
      if (dataStr is! String) {
        await box.delete(key);
        return null;
      }

      DebugUtils.logLazy(() => 'PeriodCacheService: hit ($key)');
      return PeriodTemperatureData.fromJson(
        jsonDecode(dataStr) as Map<String, dynamic>,
      );
    } catch (e) {
      DebugUtils.logLazy(() => 'PeriodCacheService: corrupted entry ($key), deleting: $e');
      await box.delete(key);
      return null;
    }
  }

  /// Write [data] to the cache. Existing entries for the same key are
  /// overwritten (write-through on miss means this is always fresh data).
  ///
  /// [cachedAt] defaults to now; supply a different value in tests to
  /// simulate expired entries.
  ///
  /// [expiresAt] overrides the default 7-day TTL. Pass the location's next
  /// local midnight to cap daily summaries that reference "today".
  static Future<void> put(
    String period,
    double lat,
    double lon,
    String identifier,
    PeriodTemperatureData data, {
    String? unitGroup,
    String? localToday,
    DateTime? cachedAt,
    DateTime? expiresAt,
  }) async {
    final box = _box;
    if (box == null) return;

    final key = _key(period, lat, lon, identifier,
        unitGroup: unitGroup, localToday: localToday);
    final now = cachedAt ?? DateTime.now();
    final entry = <String, dynamic>{
      '_cachedAt': now.millisecondsSinceEpoch,
      'data': jsonEncode(_toJson(data)),
    };
    if (expiresAt != null) {
      entry['_expiresAt'] = expiresAt.millisecondsSinceEpoch;
    }
    await box.put(key, entry);
    DebugUtils.logLazy(() => 'PeriodCacheService: stored ($key)');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  /// Returns true if the stored entry has expired.
  /// Prefers the explicit `_expiresAt` timestamp when present; falls back to
  /// `_cachedAt + _ttl` for entries written before this field was added.
  static bool _isExpired(Map<String, dynamic> map) {
    final expiresAtValue = map['_expiresAt'];
    if (expiresAtValue is int) {
      return DateTime.now().millisecondsSinceEpoch >= expiresAtValue;
    }
    final cachedAtValue = map['_cachedAt'];
    if (cachedAtValue is! int) return true;
    final cachedAt = DateTime.fromMillisecondsSinceEpoch(cachedAtValue);
    return DateTime.now().difference(cachedAt) > _ttl;
  }

  static String _key(
    String period,
    double lat,
    double lon,
    String identifier, {
    String? unitGroup,
    String? localToday,
  }) {
    final todaySegment = localToday ?? '';
    final base = '$period:${lat.toStringAsFixed(3)}:${lon.toStringAsFixed(3)}:$identifier:$todaySegment';
    if (unitGroup != null && unitGroup != 'celsius') {
      return '$base:$unitGroup';
    }
    return base;
  }

  static Map<String, dynamic> _toJson(PeriodTemperatureData d) => {
        'period': d.period,
        'location': d.location,
        'identifier': d.identifier,
        'range': {
          'start': d.range.start,
          'end': d.range.end,
          'years': d.range.years,
        },
        'unit_group': d.unitGroup,
        'values': d.values
            .map((v) => {
                  'date': v.date,
                  'year': v.year,
                  'temperature': v.temperature,
                  if (v.anomaly != null) 'anomaly': v.anomaly,
                })
            .toList(),
        'average': {
          'mean': d.average.mean,
          if (d.standardDeviation != null)
            'standard_deviation': d.standardDeviation,
        },
        'trend': {
          'slope': d.trend.slope,
          'unit': d.trend.unit,
          if (d.trend.slopeError != null) 'slope_error': d.trend.slopeError,
        },
        'summary': d.summary,
        if (d.metadata != null)
          'metadata': {
            'total_years': d.metadata!.totalYears,
            'available_years': d.metadata!.availableYears,
            'missing_years': d.metadata!.missingYears
                .map((m) => {'year': m.year, 'reason': m.reason})
                .toList(),
            'completeness': d.metadata!.completeness,
            'period_days': d.metadata!.periodDays,
            'end_date': d.metadata!.endDate,
          },
      };
}
