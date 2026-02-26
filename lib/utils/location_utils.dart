import '../constants/app_constants.dart';

/// Clean up and validate location strings for better API compatibility
String cleanupLocationString(String location) {
  if (location.isEmpty) return kDefaultLocation;

  // Remove extra whitespace and normalize commas
  String cleaned = location.trim();

  // Replace multiple spaces with single space
  cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ');

  // Normalize comma spacing (ensure space after comma)
  cleaned = cleaned.replaceAll(RegExp(r',\s*'), ', ');

  // Remove trailing comma if present
  cleaned = cleaned.replaceAll(RegExp(r',\s*$'), '');

  // Ensure we have at least a city and country
  if (!cleaned.contains(',')) {
    // If no comma, assume it's just a city, add default country
    cleaned = '$cleaned, UK';
  }

  return cleaned;
}

/// Detect suspicious or obviously incorrect location strings
/// This is very conservative since location data comes from device GPS/geocoding
bool isLocationSuspicious(String location) {
  if (location.isEmpty) return true;

  // Check for very short or very long location strings (indicates API issues)
  if (location.length < 2 || location.length > 200) {
    return true;
  }

  // Check for pure numeric strings (postal codes without city names)
  if (RegExp(r'^\d+$').hasMatch(location.trim())) {
    return true;
  }

  return false;
}
