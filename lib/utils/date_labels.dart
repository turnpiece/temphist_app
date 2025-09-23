import 'package:intl/intl.dart';

/// Utility functions for formatting date labels in different contexts
class DateLabels {
  /// Format a day label as "DD MMM" (e.g. "22 Sep")
  static String formatDayLabel(DateTime date) {
    final day = date.day;
    final month = DateFormat('MMM').format(date);
    return '$day $month';
  }

  /// Format a week label as "Week to DD MMM" (e.g. "Week to 22 Sep")
  static String formatWeekToLabel(DateTime endDate) {
    final day = endDate.day;
    final month = DateFormat('MMM').format(endDate);
    return 'Week to $day $month';
  }

  /// Format a month label as "Month to DD MMM" (e.g. "Month to 22 Sep")
  static String formatMonthToLabel(DateTime endDate) {
    final day = endDate.day;
    final month = DateFormat('MMM').format(endDate);
    return 'Month to $day $month';
  }

  /// Get the start date of the week containing the given date
  static DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Get the end date of the week containing the given date
  static DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }

  /// Get the start date of the month containing the given date
  static DateTime getMonthStart(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get the end date of the month containing the given date
  static DateTime getMonthEnd(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }
}
