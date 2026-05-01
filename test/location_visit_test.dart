import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/models/location_visit.dart';

void main() {
  group('LocationVisit', () {
    final visit = LocationVisit(
      location: 'London, United Kingdom',
      displayLocation: 'London',
      visitedAt: DateTime(2024, 3, 15, 10, 30),
    );

    test('toJson produces expected map', () {
      final json = visit.toJson();
      expect(json['location'], 'London, United Kingdom');
      expect(json['displayLocation'], 'London');
      expect(json['visitedAt'],
          DateTime(2024, 3, 15, 10, 30).millisecondsSinceEpoch);
    });

    test('fromJson reconstructs the visit', () {
      final json = visit.toJson();
      final restored = LocationVisit.fromJson(json);
      expect(restored.location, visit.location);
      expect(restored.displayLocation, visit.displayLocation);
      expect(restored.visitedAt, visit.visitedAt);
    });

    test('round-trip through toJson/fromJson is lossless', () {
      final restored = LocationVisit.fromJson(visit.toJson());
      expect(restored.location, visit.location);
      expect(restored.displayLocation, visit.displayLocation);
      expect(restored.visitedAt.millisecondsSinceEpoch,
          visit.visitedAt.millisecondsSinceEpoch);
    });
  });
}
