import 'package:geocoding/geocoding.dart';

import '../constants/app_constants.dart';

// Pre-compiled RegExps for performance
final _multipleSpaces = RegExp(r'\s+');
final _commaSpacing = RegExp(r',\s*');
final _trailingComma = RegExp(r',\s*$');
final _pureNumeric = RegExp(r'^\d+$');

/// Clean up and validate location strings for better API compatibility
String cleanupLocationString(String location) {
  if (location.isEmpty) return kDefaultLocation;

  // Remove extra whitespace and normalize commas
  String cleaned = location.trim();

  // Replace multiple spaces with single space
  cleaned = cleaned.replaceAll(_multipleSpaces, ' ');

  // Normalize comma spacing (ensure space after comma)
  cleaned = cleaned.replaceAll(_commaSpacing, ', ');

  // Remove trailing comma if present
  cleaned = cleaned.replaceAll(_trailingComma, '');

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
  if (_pureNumeric.hasMatch(location.trim())) {
    return true;
  }

  return false;
}

/// Build a location string from a [Placemark], combining locality,
/// administrative area, and country as available.
///
/// Returns [kDefaultLocation] if the placemark has no usable fields.
String buildLocationFromPlacemark(Placemark placemark) {
  final locality = placemark.locality;
  final country = placemark.country;
  final admin = placemark.administrativeArea;

  if (locality != null && locality.isNotEmpty) {
    if (country != null && country.isNotEmpty) {
      if (admin != null && admin.isNotEmpty) {
        return '$locality, $admin, $country';
      }
      return '$locality, $country';
    }
    if (admin != null && admin.isNotEmpty) {
      return '$locality, $admin';
    }
    return locality;
  }

  // No locality — try administrative area + country
  if (admin != null && admin.isNotEmpty) {
    if (country != null && country.isNotEmpty) {
      return '$admin, $country';
    }
    return admin;
  }
  if (country != null && country.isNotEmpty) {
    return country;
  }

  return kDefaultLocation;
}
