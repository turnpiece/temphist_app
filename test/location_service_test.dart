import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:temphist_app/services/location_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationService — gpsLocation vs selectedLocation separation', () {
    test('gpsLocation is empty initially', () {
      expect(LocationService().gpsLocation, '');
    });

    test('determinedLocation is empty initially', () {
      expect(LocationService().determinedLocation, '');
    });

    test('isLocationDetermined is false initially', () {
      expect(LocationService().isLocationDetermined, isFalse);
    });

    test('setManualLocation updates determinedLocation', () async {
      final service = LocationService();
      await service.setManualLocation('Belfast, United Kingdom');
      expect(service.determinedLocation, 'Belfast, United Kingdom');
    });

    test('setManualLocation does NOT update gpsLocation', () async {
      final service = LocationService();
      await service.setManualLocation('Belfast, United Kingdom');
      // gpsLocation should remain empty — only GPS resolution sets it
      expect(service.gpsLocation, '');
    });

    test('setManualLocation sets isLocationDetermined to true', () async {
      final service = LocationService();
      await service.setManualLocation('Belfast, United Kingdom');
      expect(service.isLocationDetermined, isTrue);
    });

    test('setManualLocation updates displayLocation to city name only', () async {
      final service = LocationService();
      await service.setManualLocation('Belfast, United Kingdom');
      expect(service.displayLocation, 'Belfast');
    });

    test('reset clears determinedLocation', () async {
      final service = LocationService();
      await service.setManualLocation('Belfast, United Kingdom');
      service.reset();
      expect(service.determinedLocation, '');
    });

    test('reset clears gpsLocation', () async {
      final service = LocationService();
      service.reset();
      expect(service.gpsLocation, '');
    });

    test('reset sets isLocationDetermined to false', () async {
      final service = LocationService();
      await service.setManualLocation('Belfast, United Kingdom');
      service.reset();
      expect(service.isLocationDetermined, isFalse);
    });

    test('switching manual location does not pollute gpsLocation', () async {
      final service = LocationService();
      await service.setManualLocation('Sydney, Australia');
      await service.setManualLocation('Belfast, United Kingdom');
      expect(service.gpsLocation, '');
      expect(service.determinedLocation, 'Belfast, United Kingdom');
    });
  });

  group('LocationService — timezone persistence across cold starts', () {
    test('setManualLocation records the given timezone', () async {
      final service = LocationService();
      await service.setManualLocation('London, United Kingdom',
          timezone: 'Europe/London');
      expect(service.determinedLocationTimezone, 'Europe/London');
    });

    test('setManualLocation with no timezone leaves it null', () async {
      final service = LocationService();
      await service.setManualLocation('London, United Kingdom');
      expect(service.determinedLocationTimezone, isNull);
    });

    test('reset clears determinedLocationTimezone', () async {
      final service = LocationService();
      await service.setManualLocation('London, United Kingdom',
          timezone: 'Europe/London');
      service.reset();
      expect(service.determinedLocationTimezone, isNull);
    });

    test(
        'a fresh LocationService instance restores the persisted timezone '
        'from a manual selection made in a previous session', () async {
      final first = LocationService();
      await first.setManualLocation('London, United Kingdom',
          timezone: 'Europe/London');

      // Simulate a cold restart: a brand-new instance reads the same
      // SharedPreferences-backed cache the first instance wrote to.
      final second = LocationService();
      await second.determineLocation();

      expect(second.determinedLocation, 'London, United Kingdom');
      expect(second.determinedLocationTimezone, 'Europe/London');
    });
  });
}
