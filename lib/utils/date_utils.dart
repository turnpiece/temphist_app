import 'package:intl/intl.dart';
import 'package:timezone/timezone.dart' as tz;
import '../constants/app_constants.dart';

/// Helper function to get current date and location for API calls.
///
/// When [locationTimezone] is an IANA timezone string (e.g. "America/Los_Angeles"),
/// the cutoff check uses the location's local hour so a user in London who picks
/// LA at 2am LA-time still sees yesterday's data.  Falls back to the device
/// clock when no timezone is supplied.
///
/// Returns a map with 'date', 'mmdd', and 'city' keys.
Map<String, String> getCurrentDateAndLocation(
  String determinedLocation, {
  String? locationTimezone,
}) {
  DateTime dateRef = DateTime.now();
  if (locationTimezone != null) {
    try {
      final location = tz.getLocation(locationTimezone);
      dateRef = tz.TZDateTime.now(location);
    } catch (_) {
      // Unknown timezone — fall back to device clock.
    }
  }

  final useYesterday = dateRef.hour < kUseYesterdayHourThreshold;
  final dateToUse = useYesterday ? dateRef.subtract(const Duration(days: 1)) : dateRef;
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
