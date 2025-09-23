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
  
  // Time context management
  int _timeContextIndex = 0; // 0 = Today, 1 = D-1, ..., 7 = PastWeek, 8 = PastMonth

  // Getters
  LocationInfo? get currentLocation => _currentLocation;
  DateTime get currentDate => _currentDate;
  ExplorePeriod get currentPeriod => _currentPeriod;
  List<LocationInfo> get visitedLocations => List.unmodifiable(_visitedLocations);
  bool get isLoading => _isLoading;
  bool get hasMultipleLocations => _visitedLocations.length >= 2;
  
  // Time context getters
  int get timeContextIndex => _timeContextIndex;
  int get maxTimeContextIndex => 8; // PastMonth is the last index
  bool get canSwipeRight => _timeContextIndex < maxTimeContextIndex;
  bool get canSwipeLeft => _timeContextIndex > 0;

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
      debugPrint('AppState: Adding visited location: ${location.displayName}');
      await VisitedLocationsService().addVisitedLocation(location);
      await _refreshVisitedLocations();
      debugPrint('AppState: Visited locations count: ${_visitedLocations.length}');
      debugPrint('AppState: Has multiple locations: $hasMultipleLocations');
    } catch (e) {
      debugPrint('AppState: Error adding visited location: $e');
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

  /// Clear all visited locations (for testing)
  Future<void> clearVisitedLocations() async {
    try {
      debugPrint('AppState: Clearing all visited locations');
      await VisitedLocationsService().clearVisitedLocations();
      await _refreshVisitedLocations();
      debugPrint('AppState: Visited locations cleared');
    } catch (e) {
      debugPrint('AppState: Error clearing visited locations: $e');
    }
  }

  /// Refresh visited locations from the service
  Future<void> _refreshVisitedLocations() async {
    try {
      final visited = await VisitedLocationsService().getVisitedLocations();
      debugPrint('AppState: Refreshed visited locations: ${visited.length} locations');
      for (final loc in visited) {
        debugPrint('  - ${loc.displayName}');
      }
      _visitedLocations = visited;
      notifyListeners();
    } catch (e) {
      debugPrint('AppState: Error refreshing visited locations: $e');
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
    _timeContextIndex = 0;
    notifyListeners();
  }

  /// Set the time context index
  void setTimeContextIndex(int index) {
    if (index >= 0 && index <= maxTimeContextIndex && index != _timeContextIndex) {
      _timeContextIndex = index;
      _updateDateAndPeriodFromIndex();
      notifyListeners();
    }
  }

  /// Move to the next time context (swipe right - forward in time)
  void moveToNextContext() {
    if (canSwipeRight) {
      setTimeContextIndex(_timeContextIndex + 1);
    }
  }

  /// Move to the previous time context (swipe left - backward in time)
  void moveToPreviousContext() {
    if (canSwipeLeft) {
      setTimeContextIndex(_timeContextIndex - 1);
    }
  }

  /// Update date and period based on current time context index
  void _updateDateAndPeriodFromIndex() {
    final now = DateTime.now();
    
    switch (_timeContextIndex) {
      case 0: // Today
        _currentDate = now;
        _currentPeriod = ExplorePeriod.day;
        break;
      case 1: // D-1
        _currentDate = now.subtract(const Duration(days: 1));
        _currentPeriod = ExplorePeriod.day;
        break;
      case 2: // D-2
        _currentDate = now.subtract(const Duration(days: 2));
        _currentPeriod = ExplorePeriod.day;
        break;
      case 3: // D-3
        _currentDate = now.subtract(const Duration(days: 3));
        _currentPeriod = ExplorePeriod.day;
        break;
      case 4: // D-4
        _currentDate = now.subtract(const Duration(days: 4));
        _currentPeriod = ExplorePeriod.day;
        break;
      case 5: // D-5
        _currentDate = now.subtract(const Duration(days: 5));
        _currentPeriod = ExplorePeriod.day;
        break;
      case 6: // D-6
        _currentDate = now.subtract(const Duration(days: 6));
        _currentPeriod = ExplorePeriod.day;
        break;
      case 7: // PastWeek
        _currentDate = now; // Show "Week to [today's date]"
        _currentPeriod = ExplorePeriod.week;
        break;
      case 8: // PastMonth
        _currentDate = now; // Show "Month to [today's date]"
        _currentPeriod = ExplorePeriod.month;
        break;
    }
  }

  /// Get the display name for the current time context
  String get currentTimeContextName {
    switch (_timeContextIndex) {
      case 0: return 'Today';
      case 1: return 'D-1';
      case 2: return 'D-2';
      case 3: return 'D-3';
      case 4: return 'D-4';
      case 5: return 'D-5';
      case 6: return 'D-6';
      case 7: return 'PastWeek';
      case 8: return 'PastMonth';
      default: return 'Unknown';
    }
  }

  /// Check if the current context is an aggregate page (PastWeek/PastMonth)
  bool get isAggregateContext => _timeContextIndex >= 7;

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
