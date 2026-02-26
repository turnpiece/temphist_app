import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

/// Helper function to get current date and location for API calls
/// Returns a map with 'date', 'mmdd', and 'city' keys
Map<String, String> getCurrentDateAndLocation(String determinedLocation) {
  final now = DateTime.now();
  final useYesterday = now.hour < kUseYesterdayHourThreshold;
  final dateToUse = useYesterday ? now.subtract(Duration(days: 1)) : now;
  final mmdd = DateFormat('MM-dd').format(dateToUse);
  final city = determinedLocation.isNotEmpty ? determinedLocation : kDefaultLocation;

  return {
    'date': DateFormat('yyyy-MM-dd').format(dateToUse),
    'mmdd': mmdd,
    'city': city,
  };
}

/// Format a date with ordinal suffix (1st, 2nd, 3rd, etc.)
String formatDateWithOrdinal(DateTime date) {
  final day = date.day;
  String suffix;
  if (day >= 11 && day <= 13) {
    suffix = 'th';
  } else {
    switch (day % 10) {
      case 1:
        suffix = 'st';
      case 2:
        suffix = 'nd';
      case 3:
        suffix = 'rd';
      default:
        suffix = 'th';
    }
  }
  final month = DateFormat('MMMM').format(date);
  return '$day$suffix $month';
}
