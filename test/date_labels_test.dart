import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/utils/date_labels.dart';

void main() {
  group('DateLabels', () {
    test('formatDayLabel formats correctly', () {
      final date = DateTime(2024, 9, 22);
      final result = DateLabels.formatDayLabel(date);
      expect(result, equals('22 Sep'));
    });

    test('formatWeekToLabel formats correctly', () {
      final date = DateTime(2024, 9, 22);
      final result = DateLabels.formatWeekToLabel(date);
      expect(result, equals('Week to 22 Sep'));
    });

    test('formatMonthToLabel formats correctly', () {
      final date = DateTime(2024, 9, 22);
      final result = DateLabels.formatMonthToLabel(date);
      expect(result, equals('Month to 22 Sep'));
    });

    test('formatDayLabel handles different months', () {
      final january = DateTime(2024, 1, 15);
      final december = DateTime(2024, 12, 31);
      
      expect(DateLabels.formatDayLabel(january), equals('15 Jan'));
      expect(DateLabels.formatDayLabel(december), equals('31 Dec'));
    });

    test('formatWeekToLabel handles different months', () {
      final january = DateTime(2024, 1, 15);
      final december = DateTime(2024, 12, 31);
      
      expect(DateLabels.formatWeekToLabel(january), equals('Week to 15 Jan'));
      expect(DateLabels.formatWeekToLabel(december), equals('Week to 31 Dec'));
    });

    test('formatMonthToLabel handles different months', () {
      final january = DateTime(2024, 1, 15);
      final december = DateTime(2024, 12, 31);
      
      expect(DateLabels.formatMonthToLabel(january), equals('Month to 15 Jan'));
      expect(DateLabels.formatMonthToLabel(december), equals('Month to 31 Dec'));
    });

    test('getWeekStart returns correct start of week', () {
      // Monday (weekday 1)
      final monday = DateTime(2024, 9, 23); // Monday
      final weekStart = DateLabels.getWeekStart(monday);
      expect(weekStart.weekday, equals(1)); // Should be Monday
      expect(weekStart.day, equals(23)); // Same day for Monday
      
      // Sunday (weekday 7)
      final sunday = DateTime(2024, 9, 29); // Sunday
      final weekStartSunday = DateLabels.getWeekStart(sunday);
      expect(weekStartSunday.weekday, equals(1)); // Should be Monday
      expect(weekStartSunday.day, equals(23)); // Previous Monday
    });

    test('getWeekEnd returns correct end of week', () {
      // Monday (weekday 1)
      final monday = DateTime(2024, 9, 23); // Monday
      final weekEnd = DateLabels.getWeekEnd(monday);
      expect(weekEnd.weekday, equals(7)); // Should be Sunday
      expect(weekEnd.day, equals(29)); // Same week Sunday
      
      // Sunday (weekday 7)
      final sunday = DateTime(2024, 9, 29); // Sunday
      final weekEndSunday = DateLabels.getWeekEnd(sunday);
      expect(weekEndSunday.weekday, equals(7)); // Should be Sunday
      expect(weekEndSunday.day, equals(29)); // Same day for Sunday
    });

    test('getMonthStart returns correct start of month', () {
      final date = DateTime(2024, 9, 15);
      final monthStart = DateLabels.getMonthStart(date);
      expect(monthStart.year, equals(2024));
      expect(monthStart.month, equals(9));
      expect(monthStart.day, equals(1));
    });

    test('getMonthEnd returns correct end of month', () {
      final date = DateTime(2024, 9, 15);
      final monthEnd = DateLabels.getMonthEnd(date);
      expect(monthEnd.year, equals(2024));
      expect(monthEnd.month, equals(9));
      expect(monthEnd.day, equals(30)); // September has 30 days
      
      // Test February in leap year
      final febLeap = DateTime(2024, 2, 15);
      final febEnd = DateLabels.getMonthEnd(febLeap);
      expect(febEnd.day, equals(29)); // Leap year February
      
      // Test February in non-leap year
      final febNonLeap = DateTime(2023, 2, 15);
      final febEndNonLeap = DateLabels.getMonthEnd(febNonLeap);
      expect(febEndNonLeap.day, equals(28)); // Non-leap year February
    });
  });
}
