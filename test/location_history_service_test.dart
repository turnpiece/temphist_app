import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:temphist_app/services/location_history_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationHistoryService', () {
    test('getAll returns empty list when nothing stored', () async {
      expect(await LocationHistoryService.getAll(), isEmpty);
    });

    test('add stores a location', () async {
      await LocationHistoryService.add('London, United Kingdom');
      expect(await LocationHistoryService.getAll(), ['London, United Kingdom']);
    });

    test('add ignores empty string', () async {
      await LocationHistoryService.add('');
      expect(await LocationHistoryService.getAll(), isEmpty);
    });

    test('add stores multiple locations newest-first', () async {
      await LocationHistoryService.add('London, United Kingdom');
      await LocationHistoryService.add('Paris, France');
      await LocationHistoryService.add('Tokyo, Japan');
      expect(await LocationHistoryService.getAll(), [
        'Tokyo, Japan',
        'Paris, France',
        'London, United Kingdom',
      ]);
    });

    test('add deduplicates — re-adding a city moves it to front', () async {
      await LocationHistoryService.add('London, United Kingdom');
      await LocationHistoryService.add('Paris, France');
      await LocationHistoryService.add('London, United Kingdom');
      final result = await LocationHistoryService.getAll();
      expect(result, ['London, United Kingdom', 'Paris, France']);
      expect(result.length, 2);
    });

    test('add caps history at 10 entries, dropping oldest', () async {
      for (var i = 1; i <= 12; i++) {
        await LocationHistoryService.add('City $i, Country');
      }
      final result = await LocationHistoryService.getAll();
      expect(result.length, 10);
      expect(result.first, 'City 12, Country');
      expect(result.last, 'City 3, Country');
    });

    test('clear removes all stored history', () async {
      await LocationHistoryService.add('London, United Kingdom');
      await LocationHistoryService.add('Paris, France');
      await LocationHistoryService.clear();
      expect(await LocationHistoryService.getAll(), isEmpty);
    });
  });
}
