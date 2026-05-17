import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:temphist_app/models/location_visit.dart';
import 'package:temphist_app/services/location_history_service.dart';

LocationVisit _visit(String location, {DateTime? date}) => LocationVisit(
      location: location,
      displayLocation: location.split(',').first.trim(),
      visitedAt: date ?? DateTime(2024, 3, 15),
    );

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

    test('add stores a visit', () async {
      await LocationHistoryService.add(_visit('London, United Kingdom'));
      final result = await LocationHistoryService.getAll();
      expect(result.length, 1);
      expect(result.first.location, 'London, United Kingdom');
      expect(result.first.displayLocation, 'London');
    });

    test('add ignores empty location', () async {
      await LocationHistoryService.add(_visit(''));
      expect(await LocationHistoryService.getAll(), isEmpty);
    });

    test('add stores multiple visits newest-first', () async {
      await LocationHistoryService.add(_visit('London, United Kingdom', date: DateTime(2024, 1, 1)));
      await LocationHistoryService.add(_visit('Paris, France', date: DateTime(2024, 2, 1)));
      await LocationHistoryService.add(_visit('Tokyo, Japan', date: DateTime(2024, 3, 1)));
      final result = await LocationHistoryService.getAll();
      expect(result.map((v) => v.location).toList(), [
        'Tokyo, Japan',
        'Paris, France',
        'London, United Kingdom',
      ]);
    });

    test('add skips duplicate location on same calendar day', () async {
      final day = DateTime(2024, 3, 15);
      await LocationHistoryService.add(_visit('London, United Kingdom', date: day));
      await LocationHistoryService.add(_visit('London, United Kingdom', date: day));
      final result = await LocationHistoryService.getAll();
      expect(result.length, 1);
    });

    test('add allows same location on different calendar days', () async {
      await LocationHistoryService.add(_visit('London, United Kingdom', date: DateTime(2024, 3, 15)));
      await LocationHistoryService.add(_visit('London, United Kingdom', date: DateTime(2024, 3, 16)));
      final result = await LocationHistoryService.getAll();
      expect(result.length, 2);
      expect(result.first.visitedAt.day, 16);
    });

    test('add caps history at 500 entries, dropping oldest', () async {
      for (var i = 1; i <= 502; i++) {
        await LocationHistoryService.add(
          _visit('City $i, Country', date: DateTime(2024, 1, 1).add(Duration(days: i))),
        );
      }
      final result = await LocationHistoryService.getAll();
      expect(result.length, 500);
      expect(result.first.location, 'City 502, Country');
      expect(result.last.location, 'City 3, Country');
    });

    test('clear removes all stored history', () async {
      await LocationHistoryService.add(_visit('London, United Kingdom'));
      await LocationHistoryService.add(_visit('Paris, France', date: DateTime(2024, 4, 1)));
      await LocationHistoryService.clear();
      expect(await LocationHistoryService.getAll(), isEmpty);
    });
  });
}
