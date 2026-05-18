import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/services/temperature_service.dart';

/// Tests for the location-id caching and lookup logic added for issue #65
/// (submit location selections to API).
///
/// The HTTP call in submitLocationSelection() requires a live Firebase token;
/// that path is covered by integration/manual testing. These unit tests cover
/// the pure-logic layers: cache lookup and city-name fuzzy-match fallback.
void main() {
  setUp(() {
    // Each test gets a clean cache and reset session-dedup state.
    TemperatureService.seedLocationIdCacheForTesting({});
  });

  group('canonicalIdFor — exact match', () {
    test('returns id when display string is in cache', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'London, United Kingdom': 'london',
        'Amsterdam, Netherlands': 'amsterdam',
      });

      expect(TemperatureService.canonicalIdFor('London, United Kingdom'),
          equals('london'));
      expect(TemperatureService.canonicalIdFor('Amsterdam, Netherlands'),
          equals('amsterdam'));
    });

    test('returns null when cache is empty', () {
      expect(TemperatureService.canonicalIdFor('London, United Kingdom'),
          isNull);
    });

    test('returns null when key is not in cache', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'Amsterdam, Netherlands': 'amsterdam',
      });

      expect(TemperatureService.canonicalIdFor('Paris, France'), isNull);
    });
  });

  group('canonicalIdFor — city-name fuzzy match', () {
    test('GPS string resolves via first-segment match', () {
      // The API returns "London, United Kingdom" with id "london".
      // The GPS geocoder produces "London, Greater London, United Kingdom".
      // The fuzzy match should resolve both to the same id.
      TemperatureService.seedLocationIdCacheForTesting({
        'London, United Kingdom': 'london',
      });

      expect(
        TemperatureService.canonicalIdFor(
            'London, Greater London, United Kingdom'),
        equals('london'),
      );
    });

    test('fuzzy match is case-insensitive on city segment', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'Paris, France': 'paris',
      });

      expect(TemperatureService.canonicalIdFor('paris, France'), equals('paris'));
    });

    test('fuzzy match does not cross to a different city', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'New York, United States': 'new-york',
      });

      // "Newark" starts differently — must not match "New York".
      expect(TemperatureService.canonicalIdFor('Newark, United States'), isNull);
    });

    test('fuzzy hit is written back to cache for O(1) future lookups', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'Berlin, Germany': 'berlin',
      });

      // First call — fuzzy lookup.
      final first = TemperatureService.canonicalIdFor(
          'Berlin, Brandenburg, Germany');
      expect(first, equals('berlin'));

      // Second call — must hit exact-match branch (cache was updated).
      // We verify this indirectly: still returns the same id.
      final second = TemperatureService.canonicalIdFor(
          'Berlin, Brandenburg, Germany');
      expect(second, equals('berlin'));
    });

    test('returns null when no city-segment match exists', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'Tokyo, Japan': 'tokyo',
      });

      expect(TemperatureService.canonicalIdFor('Sydney, Australia'), isNull);
    });
  });

  group('seedLocationIdCacheForTesting', () {
    test('replaces existing cache contents', () {
      TemperatureService.seedLocationIdCacheForTesting({
        'London, United Kingdom': 'london',
      });
      TemperatureService.seedLocationIdCacheForTesting({
        'Tokyo, Japan': 'tokyo',
      });

      expect(TemperatureService.canonicalIdFor('London, United Kingdom'),
          isNull);
      expect(TemperatureService.canonicalIdFor('Tokyo, Japan'),
          equals('tokyo'));
    });
  });
}
