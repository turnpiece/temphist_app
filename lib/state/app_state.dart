import 'package:flutter/foundation.dart';
import '../models/explore_state.dart';
import '../services/visited_locations_service.dart';

/// Central state management for the app's navigation and context
class AppState extends ChangeNotifier {
  LocationInfo? _currentLocation;
  DateTime _currentDate = DateTime.now();
  ExplorePeriod _currentPeriod = ExplorePeriod.day;
  List<LocationInfo> _visitedLocations = [];
  bool _isLoading = false;

  // Getters
  LocationInfo? get currentLocation => _currentLocation;
  DateTime get currentDate => _currentDate;
  ExplorePeriod get currentPeriod => _currentPeriod;
  List<LocationInfo> get visitedLocations => List.unmodifiable(_visitedLocations);
  bool get isLoading => _isLoading;
  bool get hasMultipleLocations => _visitedLocations.length >= 2;

  /// Initialize the app state with current location and visited locations
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // Load visited locations
      final visited = await VisitedLocationsService().getVisitedLocations();
      _visitedLocations = visited;
      
      // Set current location to most recent or default
      if (_visitedLocations.isNotEmpty) {
        _currentLocation = _visitedLocations.last;
      } else {
        // Use default location if no visited locations
        _currentLocation = const LocationInfo(
          displayName: 'London, UK',
          latitude: 51.5074,
          longitude: -0.1278,
          countryCode: 'GB',
        );
      }
    } catch (e) {
      // Handle error - could set a default location or show error state
      _currentLocation = const LocationInfo(
        displayName: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
        countryCode: 'GB',
      );
    } finally {
      _setLoading(false);
    }
  }

  /// Set the current location
  void setCurrentLocation(LocationInfo location) {
    if (_currentLocation != location) {
      _currentLocation = location;
      notifyListeners();
    }
  }

  /// Set the current date
  void setCurrentDate(DateTime date) {
    if (_currentDate != date) {
      _currentDate = date;
      notifyListeners();
    }
  }

  /// Set the current period
  void setCurrentPeriod(ExplorePeriod period) {
    if (_currentPeriod != period) {
      _currentPeriod = period;
      notifyListeners();
    }
  }

  /// Add a new visited location
  Future<void> addVisitedLocation(LocationInfo location) async {
    try {
      await VisitedLocationsService().addVisitedLocation(location);
      await _refreshVisitedLocations();
    } catch (e) {
      // Handle error
    }
  }

  /// Remove a visited location
  Future<void> removeVisitedLocation(LocationInfo location) async {
    try {
      await VisitedLocationsService().removeVisitedLocation(location);
      await _refreshVisitedLocations();
      
      // If we removed the current location, switch to another one
      if (_currentLocation == location && _visitedLocations.isNotEmpty) {
        _currentLocation = _visitedLocations.last;
        notifyListeners();
      }
    } catch (e) {
      // Handle error
    }
  }

  /// Refresh visited locations from the service
  Future<void> _refreshVisitedLocations() async {
    try {
      final visited = await VisitedLocationsService().getVisitedLocations();
      _visitedLocations = visited;
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }

  /// Set loading state
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  /// Reset to today's date and day period
  void resetToToday() {
    _currentDate = DateTime.now();
    _currentPeriod = ExplorePeriod.day;
    notifyListeners();
  }

  /// Get the display name for the current location
  String get currentLocationDisplayName {
    return _currentLocation?.displayName ?? 'Unknown Location';
  }

  /// Get the city name from the current location (without country code)
  String get currentCityName {
    final displayName = _currentLocation?.displayName ?? 'Unknown';
    // Extract city name before comma (e.g., "London, UK" -> "London")
    final commaIndex = displayName.indexOf(',');
    if (commaIndex > 0) {
      return displayName.substring(0, commaIndex).trim();
    }
    return displayName;
  }
}
