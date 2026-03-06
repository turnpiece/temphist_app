import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/models/period_temperature_data.dart';
import 'package:temphist_app/services/period_cache_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PeriodTemperatureData _stub({String location = 'London, UK'}) =>
    PeriodTemperatureData(
      period: 'daily',
      location: location,
      identifier: '03-06',
      range: PeriodRange(start: '1970', end: '2025', years: 55),
      unitGroup: 'metric',
      values: [
        PeriodDataPoint(date: '2025-03-06', year: 2025, temperature: 8.5),
      ],
      average: PeriodAverage(mean: 7.2),
      trend: PeriodTrend(slope: 0.03, unit: '°C/decade'),
      summary: 'Cool spring day.',
    );

const double _lat = 51.509;
const double _lon = -0.118;
const String _date = '2026-03-06';
const String _mmdd = '03-06';

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('period_cache_test_');
    await PeriodCacheService.init(path: tempDir.path);
  });

  tearDown(() async {
    await PeriodCacheService.close();
    await tempDir.delete(recursive: true);
  });

  group('exists', () {
    test('returns false when nothing cached', () {
      expect(PeriodCacheService.exists('daily', _lat, _lon, _date), isFalse);
    });

    test('returns true after put', () async {
      await PeriodCacheService.put('daily', _lat, _lon, _date, _stub());
      expect(PeriodCacheService.exists('daily', _lat, _lon, _date), isTrue);
    });

    test('returns false for expired entry', () async {
      final expired = DateTime.now().subtract(const Duration(days: 8));
      await PeriodCacheService.put(
        'daily', _lat, _lon, _date, _stub(),
        cachedAt: expired,
      );
      expect(PeriodCacheService.exists('daily', _lat, _lon, _date), isFalse);
    });
  });

  group('get', () {
    test('miss returns null', () async {
      final result = await PeriodCacheService.get('daily', _lat, _lon, _date);
      expect(result, isNull);
    });

    test('returns data after put', () async {
      await PeriodCacheService.put('daily', _lat, _lon, _date, _stub());

      final result = await PeriodCacheService.get('daily', _lat, _lon, _date);
      expect(result, isNotNull);
      expect(result!.location, 'London, UK');
      expect(result.values.first.temperature, 8.5);
      expect(result.summary, 'Cool spring day.');
    });

    test('relaunch same day: box survives close and reopen', () async {
      await PeriodCacheService.put('year', _lat, _lon, _mmdd, _stub());

      await PeriodCacheService.close();
      await PeriodCacheService.init(path: tempDir.path);

      final result = await PeriodCacheService.get('year', _lat, _lon, _mmdd);
      expect(result, isNotNull);
      expect(result!.summary, 'Cool spring day.');
    });

    test('after TTL: returns null and removes entry', () async {
      final expired = DateTime.now().subtract(const Duration(days: 8));
      await PeriodCacheService.put(
        'week', _lat, _lon, _mmdd, _stub(),
        cachedAt: expired,
      );

      final result = await PeriodCacheService.get('week', _lat, _lon, _mmdd);
      expect(result, isNull);
      expect(PeriodCacheService.exists('week', _lat, _lon, _mmdd), isFalse);
    });
  });

  group('key isolation', () {
    test('different periods produce different cache entries', () async {
      await PeriodCacheService.put('week', _lat, _lon, _mmdd, _stub(location: 'weekly'));
      await PeriodCacheService.put('year', _lat, _lon, _mmdd, _stub(location: 'yearly'));

      final week = await PeriodCacheService.get('week', _lat, _lon, _mmdd);
      final year = await PeriodCacheService.get('year', _lat, _lon, _mmdd);

      expect(week!.location, 'weekly');
      expect(year!.location, 'yearly');
    });

    test('different coordinates produce different cache entries', () async {
      await PeriodCacheService.put('daily', _lat, _lon, _date, _stub(location: 'A'));
      await PeriodCacheService.put('daily', 52.0, 0.0, _date, _stub(location: 'B'));

      final a = await PeriodCacheService.get('daily', _lat, _lon, _date);
      final b = await PeriodCacheService.get('daily', 52.0, 0.0, _date);

      expect(a!.location, 'A');
      expect(b!.location, 'B');
    });

    test('different identifiers produce different cache entries', () async {
      await PeriodCacheService.put('daily', _lat, _lon, '2026-03-06', _stub(location: 'today'));
      await PeriodCacheService.put('daily', _lat, _lon, '2026-03-05', _stub(location: 'yesterday'));

      final today = await PeriodCacheService.get('daily', _lat, _lon, '2026-03-06');
      final yesterday = await PeriodCacheService.get('daily', _lat, _lon, '2026-03-05');

      expect(today!.location, 'today');
      expect(yesterday!.location, 'yesterday');
    });
  });
}
