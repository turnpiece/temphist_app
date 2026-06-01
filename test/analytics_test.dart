import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/models/selection_method.dart';

void main() {
  group('SelectionMethod.apiValue', () {
    test('maps every case to the correct API string', () {
      expect(SelectionMethod.ownLocation.apiValue, 'own_location');
      expect(SelectionMethod.carousel.apiValue, 'carousel');
      expect(SelectionMethod.recent.apiValue, 'recent');
      expect(SelectionMethod.popular.apiValue, 'popular');
      expect(SelectionMethod.search.apiValue, 'search');
    });

    test('covers all enum values', () {
      for (final method in SelectionMethod.values) {
        expect(method.apiValue, isNotEmpty,
            reason: '$method has no apiValue mapping');
      }
    });
  });
}
