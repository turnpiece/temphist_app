import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';
import '../models/explore_state.dart';

/// Service for managing visited locations based on check-ins
class VisitedLocationsService {
  static const String _cacheKey = 'visited_locations';
  static const Duration _cacheExpiration = Duration(days: 30);

  /// Get all visited locations
  Future<List<LocationInfo>> getVisitedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString(_cacheKey);
      
      if (cachedData == null) {
        return [];
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      final age = DateTime.now().difference(timestamp);

      if (age > _cacheExpiration) {
        await prefs.remove(_cacheKey);
        return [];
      }

      final locations = (data['locations'] as List)
          .map((loc) => LocationInfo(
                displayName: loc['displayName'],
                latitude: loc['latitude'].toDouble(),
                longitude: loc['longitude'].toDouble(),
                countryCode: loc['countryCode'],
              ))
          .toList();

      return locations;
    } catch (e) {
      return [];
    }
  }

  /// Add a new location to visited locations
  Future<void> addVisitedLocation(LocationInfo location) async {
    try {
      final locations = await getVisitedLocations();
      
      // Check if location already exists (within 1km tolerance)
      final exists = locations.any((existing) => 
          _distanceBetween(existing, location) < 1000);
      
      if (exists) {
        // Location already exists, don't add it
        return;
      }

      // Also check for very similar display names (case-insensitive)
      final similarName = locations.any((existing) => 
          existing.displayName.toLowerCase().trim() == location.displayName.toLowerCase().trim());
      
      if (similarName) {
        // Very similar name already exists, don't add it
        return;
      }

      locations.add(location);
      await _saveVisitedLocations(locations);
    } catch (e) {
      // Error adding visited location
    }
  }

  /// Remove a location from visited locations
  Future<void> removeVisitedLocation(LocationInfo location) async {
    try {
      final locations = await getVisitedLocations();
      locations.removeWhere((existing) => 
          _distanceBetween(existing, location) < 1000);
      await _saveVisitedLocations(locations);
    } catch (e) {
      // Error removing visited location
    }
  }

  /// Clear all visited locations
  Future<void> clearVisitedLocations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
    } catch (e) {
      // Error clearing visited locations
    }
  }

  /// Save visited locations to cache
  Future<void> _saveVisitedLocations(List<LocationInfo> locations) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'locations': locations.map((loc) => {
          'displayName': loc.displayName,
          'latitude': loc.latitude,
          'longitude': loc.longitude,
          'countryCode': loc.countryCode,
        }).toList(),
      };
      await prefs.setString(_cacheKey, jsonEncode(data));
    } catch (e) {
      // Error saving visited locations
    }
  }

  /// Calculate distance between two locations in meters
  double _distanceBetween(LocationInfo a, LocationInfo b) {
    // Haversine formula for calculating distance between two points
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final lat1Rad = a.latitude * (pi / 180);
    final lat2Rad = b.latitude * (pi / 180);
    final deltaLatRad = (b.latitude - a.latitude) * (pi / 180);
    final deltaLonRad = (b.longitude - a.longitude) * (pi / 180);

    final a1 = sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) * cos(lat2Rad) *
        sin(deltaLonRad / 2) * sin(deltaLonRad / 2);
    final c = 2 * asin(sqrt(a1));

    return earthRadius * c;
  }

  /// Get the most recently visited location
  Future<LocationInfo?> getMostRecentLocation() async {
    final locations = await getVisitedLocations();
    return locations.isNotEmpty ? locations.last : null;
  }

  /// Check if a location has been visited
  Future<bool> hasVisitedLocation(LocationInfo location) async {
    final locations = await getVisitedLocations();
    return locations.any((existing) => 
        _distanceBetween(existing, location) < 1000);
  }

  /// Clean up duplicate locations and invalid entries (keep the most recent one)
  Future<void> cleanupDuplicates() async {
    try {
      final locations = await getVisitedLocations();
      final uniqueLocations = <LocationInfo>[];
      
      for (final location in locations) {
        // Skip locations with invalid names
        if (location.displayName.isEmpty || 
            location.displayName.trim().isEmpty ||
            _isCoordinateString(location.displayName) ||
            location.displayName.toLowerCase().contains('unknown')) {
          continue; // Skip invalid locations
        }
        
        // Check if we already have a location within 1km
        final existsByDistance = uniqueLocations.any((existing) => 
            _distanceBetween(existing, location) < 1000);
        
        // Also check for very similar display names
        final existsByName = uniqueLocations.any((existing) => 
            existing.displayName.toLowerCase().trim() == location.displayName.toLowerCase().trim());
        
        if (!existsByDistance && !existsByName) {
          uniqueLocations.add(location);
        }
      }
      
      // Save the cleaned up list
      await _saveVisitedLocations(uniqueLocations);
    } catch (e) {
      // Error cleaning up duplicates
    }
  }

  /// Check if a string looks like coordinates (e.g., "40.7128, -74.0060")
  bool _isCoordinateString(String str) {
    if (str.isEmpty) return false;
    
    // Check if string contains two numbers separated by comma and space
    final coordinatePattern = RegExp(r'^-?\d+\.?\d*,\s*-?\d+\.?\d*$');
    final isCoordinate = coordinatePattern.hasMatch(str.trim());
    
    // Also check if it's just a single number (latitude only)
    final singleNumberPattern = RegExp(r'^-?\d+\.?\d*$');
    final isSingleNumber = singleNumberPattern.hasMatch(str.trim());
    
    return isCoordinate || isSingleNumber;
  }

  /// Force cleanup of all invalid locations
  Future<void> forceCleanupInvalidLocations() async {
    try {
      final locations = await getVisitedLocations();
      final validLocations = locations.where((location) => 
        location.displayName.isNotEmpty && 
        location.displayName.trim().isNotEmpty &&
        !_isCoordinateString(location.displayName) &&
        !location.displayName.toLowerCase().contains('unknown')
      ).toList();
      
      // Save only valid locations
      await _saveVisitedLocations(validLocations);
    } catch (e) {
      // Error cleaning up invalid locations
    }
  }
}