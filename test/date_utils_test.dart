import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/utils/date_utils.dart' as date_utils;

void main() {
  group('formatDateWithOrdinal', () {
    test('1st, 2nd, 3rd use correct suffixes', () {
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 1)),  contains('1st'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 2)),  contains('2nd'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 3)),  contains('3rd'));
    });

    test('4th–10th use "th"', () {
      for (final day in [4, 5, 6, 7, 8, 9, 10]) {
        expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, day)),
            contains('${day}th'), reason: 'day $day');
      }
    });

    test('11th, 12th, 13th use "th" (not st/nd/rd)', () {
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 11)), contains('11th'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 12)), contains('12th'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 13)), contains('13th'));
    });

    test('21st, 22nd, 23rd use correct suffixes', () {
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 21)), contains('21st'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 22)), contains('22nd'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 23)), contains('23rd'));
    });

    test('31st uses "st"', () {
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 3, 31)), contains('31st'));
    });

    test('includes the month name', () {
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 6, 15)), contains('June'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 1, 1)),  contains('January'));
      expect(date_utils.formatDateWithOrdinal(DateTime(2024, 12, 31)), contains('December'));
    });
  });

  group('getCurrentDateAndLocation', () {
    test('returns the city when a location is provided', () {
      final result = date_utils.getCurrentDateAndLocation('Auckland, New Zealand');
      expect(result['city'], equals('Auckland, New Zealand'));
    });

    test('falls back to default location when location is empty', () {
      final result = date_utils.getCurrentDateAndLocation('');
      expect(result['city'], isNotEmpty);
    });

    test('returns a date in yyyy-MM-dd format', () {
      final result = date_utils.getCurrentDateAndLocation('London');
      final date = result['date']!;
      expect(RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date), isTrue,
          reason: 'date "$date" should match yyyy-MM-dd');
    });

    test('returns an mmdd in MM-dd format', () {
      final result = date_utils.getCurrentDateAndLocation('London');
      final mmdd = result['mmdd']!;
      expect(RegExp(r'^\d{2}-\d{2}$').hasMatch(mmdd), isTrue,
          reason: 'mmdd "$mmdd" should match MM-dd');
    });
  });
}
