import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/period_temperature_data.dart';
import '../utils/debug_utils.dart';

/// Hive-backed disk cache for all period temperature responses
/// (daily, week, month, year).
///
/// Key format: `{period}:{lat:.3f}:{lon:.3f}:{identifier}`
///   - daily  → identifier is `yyyy-MM-dd`
///   - others → identifier is `MM-dd`
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
    String identifier,
  ) {
    final raw = _box?.get(_key(period, lat, lon, identifier));
    if (raw == null) return false;
    final map = Map<String, dynamic>.from(raw as Map);
    final cachedAt =
        DateTime.fromMillisecondsSinceEpoch(map['_cachedAt'] as int);
    return DateTime.now().difference(cachedAt) <= _ttl;
  }

  /// Returns cached data, or `null` on miss or expiry.
  /// Expired entries are deleted automatically.
  static Future<PeriodTemperatureData?> get(
    String period,
    double lat,
    double lon,
    String identifier,
  ) async {
    final box = _box;
    if (box == null) return null;

    final key = _key(period, lat, lon, identifier);
    final raw = box.get(key);
    if (raw == null) return null;

    final map = Map<String, dynamic>.from(raw as Map);
    final cachedAt =
        DateTime.fromMillisecondsSinceEpoch(map['_cachedAt'] as int);

    if (DateTime.now().difference(cachedAt) > _ttl) {
      await box.delete(key);
      DebugUtils.logLazy(() => 'PeriodCacheService: expired → deleted ($key)');
      return null;
    }

    DebugUtils.logLazy(() => 'PeriodCacheService: hit ($key)');
    return PeriodTemperatureData.fromJson(
      jsonDecode(map['data'] as String) as Map<String, dynamic>,
    );
  }

  /// Write [data] to the cache. Existing entries for the same key are
  /// overwritten (write-through on miss means this is always fresh data).
  ///
  /// [cachedAt] defaults to now; supply a different value in tests to
  /// simulate expired entries.
  static Future<void> put(
    String period,
    double lat,
    double lon,
    String identifier,
    PeriodTemperatureData data, {
    DateTime? cachedAt,
  }) async {
    final box = _box;
    if (box == null) return;

    final key = _key(period, lat, lon, identifier);
    await box.put(key, {
      '_cachedAt': (cachedAt ?? DateTime.now()).millisecondsSinceEpoch,
      'data': jsonEncode(_toJson(data)),
    });
    DebugUtils.logLazy(() => 'PeriodCacheService: stored ($key)');
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static String _key(
    String period,
    double lat,
    double lon,
    String identifier,
  ) =>
      '$period:${lat.toStringAsFixed(3)}:${lon.toStringAsFixed(3)}:$identifier';

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
                })
            .toList(),
        'average': {'mean': d.average.mean},
        'trend': {'slope': d.trend.slope, 'unit': d.trend.unit},
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
