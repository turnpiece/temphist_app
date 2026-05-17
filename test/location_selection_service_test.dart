import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:temphist_app/models/location_selection.dart';
import 'package:temphist_app/services/location_selection_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationSelection model', () {
    final selection = LocationSelection(
      location: 'London, United Kingdom',
      displayLocation: 'London',
      selectedAt: DateTime(2024, 3, 15, 10, 30),
      count: 3,
    );

    test('toJson / fromJson round-trip is lossless', () {
      final restored = LocationSelection.fromJson(selection.toJson());
      expect(restored.location, selection.location);
      expect(restored.displayLocation, selection.displayLocation);
      expect(restored.selectedAt, selection.selectedAt);
      expect(restored.count, selection.count);
    });

    test('fromJson defaults count to 1 when field is absent', () {
      final json = selection.toJson()..remove('count');
      expect(LocationSelection.fromJson(json).count, 1);
    });

    test('increment returns copy with count+1 and updated selectedAt', () {
      final later = DateTime(2024, 4, 1);
      final next = selection.increment(later);
      expect(next.count, 4);
      expect(next.selectedAt, later);
      expect(next.location, selection.location);
    });
  });

  group('LocationSelectionService', () {
    test('getAll returns empty list when nothing stored', () async {
      expect(await LocationSelectionService.getAll(), isEmpty);
    });

    test('record stores a selection with count 1', () async {
      await LocationSelectionService.record('London, United Kingdom');
      final result = await LocationSelectionService.getAll();
      expect(result.length, 1);
      expect(result.first.location, 'London, United Kingdom');
      expect(result.first.displayLocation, 'London');
      expect(result.first.count, 1);
    });

    test('record ignores empty location', () async {
      await LocationSelectionService.record('');
      expect(await LocationSelectionService.getAll(), isEmpty);
    });

    test('record increments count on repeated selection', () async {
      await LocationSelectionService.record('Tokyo, Japan');
      await LocationSelectionService.record('Tokyo, Japan');
      await LocationSelectionService.record('Tokyo, Japan');
      final result = await LocationSelectionService.getAll();
      expect(result.length, 1);
      expect(result.first.count, 3);
    });

    test('record updates selectedAt on increment', () async {
      await LocationSelectionService.record('Tokyo, Japan');
      final before = (await LocationSelectionService.getAll()).first.selectedAt;
      await Future.delayed(const Duration(milliseconds: 5));
      await LocationSelectionService.record('Tokyo, Japan');
      final after = (await LocationSelectionService.getAll()).first.selectedAt;
      expect(after.isAfter(before), isTrue);
    });

    test('getAll returns entries sorted by count descending', () async {
      await LocationSelectionService.record('London, United Kingdom');
      await LocationSelectionService.record('Tokyo, Japan');
      await LocationSelectionService.record('Tokyo, Japan');
      await LocationSelectionService.record('Paris, France');
      await LocationSelectionService.record('Paris, France');
      await LocationSelectionService.record('Paris, France');
      final result = await LocationSelectionService.getAll();
      expect(result.map((e) => e.location).toList(), [
        'Paris, France',    // count 3
        'Tokyo, Japan',     // count 2
        'London, United Kingdom', // count 1
      ]);
    });

    test('record caps at 100 entries, evicting lowest-count entries', () async {
      // Fill 100 entries each selected once.
      for (var i = 1; i <= 100; i++) {
        await LocationSelectionService.record('City $i, Country');
      }
      expect((await LocationSelectionService.getAll()).length, 100);

      // Select a new location — should push out the weakest entry.
      await LocationSelectionService.record('New City, Country');
      final result = await LocationSelectionService.getAll();
      expect(result.length, 100);
      // The new location is present.
      expect(result.any((e) => e.location == 'New City, Country'), isTrue);
    });

    test('record promotes a location above others when its count grows', () async {
      await LocationSelectionService.record('London, United Kingdom');
      await LocationSelectionService.record('Tokyo, Japan');
      // Select London a second time — it should overtake Tokyo.
      await LocationSelectionService.record('London, United Kingdom');
      final result = await LocationSelectionService.getAll();
      expect(result.first.location, 'London, United Kingdom');
      expect(result.first.count, 2);
    });

    test('clear removes all stored selections', () async {
      await LocationSelectionService.record('London, United Kingdom');
      await LocationSelectionService.record('Tokyo, Japan');
      await LocationSelectionService.clear();
      expect(await LocationSelectionService.getAll(), isEmpty);
    });
  });
}
