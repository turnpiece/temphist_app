import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../utils/debug_utils.dart';
import '../utils/location_utils.dart' as location_utils;
import 'location_history_service.dart';

/// Encapsulates all device-location concerns: GPS, reverse-geocoding,
/// caching, and continuous background monitoring.
///
/// Notifies listeners via [ChangeNotifier] whenever location state changes
/// so the UI can rebuild.
class LocationService extends ChangeNotifier {
  // ---------------------------------------------------------------------------
  // Public, observable state
  // ---------------------------------------------------------------------------

  /// Full location string for API calls (e.g. "London, UK").
  String get determinedLocation => _determinedLocation;
  String _determinedLocation = '';

  /// The physical GPS-detected location, unaffected by manual selection.
  /// Empty until GPS has resolved at least once.
  String get gpsLocation => _gpsLocation;
  String _gpsLocation = '';

  /// Short location for display (e.g. "London").
  String get displayLocation => _displayLocation;
  String _displayLocation = '';

  /// Whether a valid location has been determined at least once.
  bool get isLocationDetermined => _isLocationDetermined;
  bool _isLocationDetermined = false;

  /// Timestamp of last successful location determination.
  DateTime? get locationDeterminedAt => _locationDeterminedAt;
  DateTime? _locationDeterminedAt;

  /// Most recent GPS position (may be null if GPS hasn't been used).
  geo.Position? get lastPosition => _lastPosition;
  geo.Position? _lastPosition;

  /// True while a location determination is in progress.
  bool get isLocating => _isLocating;
  bool _isLocating = false;

  // ---------------------------------------------------------------------------
  // Private state
  // ---------------------------------------------------------------------------

  StreamSubscription<geo.Position>? _positionStreamSubscription;

  static const Duration _locationCacheExpiration = Duration(minutes: 30);

  /// SharedPreferences key for the GPS-detected location.
  /// Only written by [determineLocation] — never by [setManualLocation] —
  /// so it always reflects the device's physical location, not a manual pick.
  static const String _kGpsLocationKey = 'gpsLocationPersisted';

  /// Optional callback invoked when continuous monitoring detects a
  /// significant city change (>1 km moved AND city name differs).
  /// The widget should hook this up to trigger data reloading.
  VoidCallback? onSignificantLocationChange;

  // ---------------------------------------------------------------------------
  // Core API
  // ---------------------------------------------------------------------------

  /// Determine the user's current location.
  ///
  /// Tries a SharedPreferences cache first (30-min TTL), then falls back to
  /// GPS + reverse-geocoding.  Always resolves — uses [kDefaultLocation] as
  /// the ultimate fallback.
  Future<void> determineLocation() async {
    if (_isLocating) return;
    _isLocating = true;
    _notify();

    try {
      String city = kDefaultLocation;

      // Restore the last GPS-detected location from previous sessions so it is
      // available immediately — even if we return early from the cache below.
      if (_gpsLocation.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getString(_kGpsLocationKey);
        if (saved != null && saved.isNotEmpty) {
          _gpsLocation = saved;
        }
      }

      // Try cached location first
      final cached = await _loadCachedLocation();
      if (cached != null) {
        DebugUtils.logLazy(() => 'Using cached location: ${cached['location']}');
        _determinedLocation = cached['location']!;
        _displayLocation = cached['displayLocation']!;
        _isLocationDetermined = true;
        _locationDeterminedAt = DateTime.now();

        // If the persisted GPS key hasn't been written yet (e.g. first run
        // after this feature was added), fall back to the most recent entry
        // in location history, which only ever contains GPS-detected cities.
        if (_gpsLocation.isEmpty) {
          try {
            final history = await LocationHistoryService.getAll();
            if (history.isNotEmpty) _gpsLocation = history.first;
          } catch (e) {
            DebugUtils.logLazy(() => 'Failed to load location history: $e');
          }
        }

        _notify();
        return;
      }

      // Try GPS + reverse-geocoding
      var gpsResolved = false;
      try {
        DebugUtils.logLazy(() => 'LocationService: starting geolocation');

        final serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
        if (serviceEnabled) {
          var permission = await geo.Geolocator.checkPermission();
          if (permission == geo.LocationPermission.denied) {
            permission = await geo.Geolocator.requestPermission();
          }
          if (permission == geo.LocationPermission.whileInUse ||
              permission == geo.LocationPermission.always) {
            try {
              final position = await geo.Geolocator.getCurrentPosition(
                locationSettings: const geo.LocationSettings(
                  accuracy: geo.LocationAccuracy.low,
                ),
              ).timeout(const Duration(seconds: kLocationTimeoutSeconds));

              DebugUtils.logLazy(() =>
                  'LocationService: position ${position.latitude}, ${position.longitude}');
              _lastPosition = position;

              final placemarks = await placemarkFromCoordinates(
                position.latitude,
                position.longitude,
              ).timeout(const Duration(seconds: kLocationTimeoutSeconds));

              if (placemarks.isNotEmpty) {
                city = location_utils.buildLocationFromPlacemark(placemarks.first);
                gpsResolved = true;
                DebugUtils.logLazy(() => 'Geolocation result: $city');
              }
            } catch (e) {
              DebugUtils.logLazy(() => 'Geolocation timeout or error: $e');
            }
          }
        }
      } catch (e) {
        DebugUtils.logLazy(() => 'Geolocation failed, falling back to $city: $e');
      }

      // Validate — if the resolved city looks suspicious, discard it and fall
      // back to the default, treating this the same as a GPS failure.
      city = location_utils.cleanupLocationString(city);
      if (location_utils.isLocationSuspicious(city)) {
        DebugUtils.logLazy(() => 'Suspicious location: $city, falling back to default');
        city = kDefaultLocation;
        gpsResolved = false;
      }

      DebugUtils.logLazy(() => 'LocationService: final city: $city (gpsResolved: $gpsResolved)');
      DebugUtils.verboseWithContextLazy(
        'Location',
        () => 'Determined location: $city (display: ${_extractDisplayLocation(city)})',
      );

      _determinedLocation = city;
      // Only record a GPS location when the device actually resolved one.
      // If permission was denied or GPS failed we use the default fallback but
      // must not pretend it is a real device location — that would cause the
      // location header to show green and the selector to show it as "Current
      // location".
      if (gpsResolved) {
        _gpsLocation = city;
      }
      _displayLocation = _extractDisplayLocation(city);
      _isLocationDetermined = true;
      _locationDeterminedAt = DateTime.now();
      _notify();

      // Only add to GPS history and persist the GPS key when a real position
      // was obtained — manual selections and default fallbacks are excluded.
      if (gpsResolved) {
        await LocationHistoryService.add(city);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_kGpsLocationKey, city);
      }
      await _cacheLocation(city, _displayLocation);
    } catch (e) {
      DebugUtils.logLazy(() => 'LocationService.determineLocation failed: $e');
      _determinedLocation = kDefaultLocation;
      // Do NOT set _gpsLocation here — it should only reflect actual GPS results
      // so the "Return to GPS location" option remains accurate.
      _displayLocation = _extractDisplayLocation(kDefaultLocation);
      _isLocationDetermined = true;
      _locationDeterminedAt = DateTime.now();
      _notify();
    } finally {
      _isLocating = false;
    }
  }

  /// Begin continuous GPS monitoring. Calls [onSignificantLocationChange]
  /// when the user moves to a different city.
  void startListeningToLocationChanges({
    required bool Function() isLoadingGuard,
  }) {
    _positionStreamSubscription = geo.Geolocator.getPositionStream(
      locationSettings: const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.low,
        distanceFilter: kLocationDistanceFilterMeters,
      ),
    ).listen((geo.Position position) async {
      if (_lastPosition == null ||
          _distanceBetween(_lastPosition!, position) >
              kLocationSignificantChangeMeters) {
        _lastPosition = position;

        // Skip if the widget is currently loading data
        if (isLoadingGuard() || !_isLocationDetermined) {
          DebugUtils.logLazy(() =>
              'Skipping location change — loading or not determined yet');
          return;
        }

        DebugUtils.logLazy(() => 'Significant location change detected');

        try {
          final placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          ).timeout(const Duration(seconds: kConnectivityTestTimeoutSeconds));

          if (placemarks.isNotEmpty) {
            var newCity =
                location_utils.buildLocationFromPlacemark(placemarks.first);
            newCity = location_utils.cleanupLocationString(newCity);

            if (newCity != _determinedLocation) {
              DebugUtils.logLazy(
                  () => 'City changed: $_determinedLocation → $newCity');
              onSignificantLocationChange?.call();
            } else {
              DebugUtils.logLazy(
                  () => 'Location moved but city unchanged, no refresh');
            }
          }
        } catch (e) {
          DebugUtils.logLazy(() => 'Error checking location change: $e');
        }
      }
    }, onError: (error) {
      DebugUtils.logLazy(() => 'Location stream error: $error');
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
    });
  }

  /// Returns `true` if the cached location is stale (>1 hour) and the caller
  /// should trigger a full location + data refresh.
  bool isLocationStale() {
    if (!_isLocationDetermined || _locationDeterminedAt == null) return false;
    final age = DateTime.now().difference(_locationDeterminedAt!);
    if (age.inHours >= 1) {
      DebugUtils.logLazy(
          () => 'Location is ${age.inHours} hours old — stale');
      return true;
    }
    DebugUtils.logLazy(
        () => 'Location is ${age.inMinutes} minutes old — fresh');
    return false;
  }

  /// Mark the location as "undetermined" without clearing the location string,
  /// so period pages can keep showing cached data while a refresh is in flight.
  void markRefreshing() {
    _isLocationDetermined = false;
    _locationDeterminedAt = null;
    _notify();
  }

  /// Fully reset all location state (e.g. before a fresh re-initialisation).
  void reset() {
    _isLocationDetermined = false;
    _determinedLocation = '';
    _gpsLocation = '';
    _displayLocation = '';
    _locationDeterminedAt = null;
    _notify();
  }

  /// Override the current location with a manually chosen value.
  ///
  /// Caches the selection with the standard 30-min TTL so it survives a
  /// foreground/background cycle. Does NOT add to GPS location history.
  Future<void> setManualLocation(String apiLocation) async {
    _determinedLocation = apiLocation;
    _displayLocation = _extractDisplayLocation(apiLocation);
    _isLocationDetermined = true;
    _locationDeterminedAt = DateTime.now();
    _notify();
    await _cacheLocation(apiLocation, _displayLocation);
  }

  /// Stop continuous GPS monitoring and release resources.
  void stopListening() {
    _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
  }

  @override
  void dispose() {
    stopListening();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  double _distanceBetween(geo.Position a, geo.Position b) {
    return geo.Geolocator.distanceBetween(
      a.latitude, a.longitude, b.latitude, b.longitude,
    );
  }

  String _extractDisplayLocation(String fullLocation) {
    if (fullLocation.isEmpty) return '';
    final parts = fullLocation.split(',');
    return parts.isNotEmpty ? parts.first.trim() : fullLocation;
  }

  void _notify() {
    // Guard against notifying after dispose.
    try {
      notifyListeners();
    } catch (_) {}
  }

  // ---------------------------------------------------------------------------
  // SharedPreferences cache
  // ---------------------------------------------------------------------------

  Future<void> _cacheLocation(String location, String displayLoc) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = {
        'location': location,
        'displayLocation': displayLoc,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('cachedLocation', jsonEncode(data));
      DebugUtils.logLazy(() => '📍 Location cached: $location');
    } catch (e) {
      DebugUtils.logLazy(() => '❌ Failed to cache location: $e');
    }
  }

  Future<Map<String, String>?> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('cachedLocation');
      if (raw == null) return null;

      final data = jsonDecode(raw) as Map<String, dynamic>;
      final timestamp =
          DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      final age = DateTime.now().difference(timestamp);

      if (age > _locationCacheExpiration) {
        DebugUtils.logLazy(
            () => '📍 Cached location expired (${age.inMinutes} min old)');
        await prefs.remove('cachedLocation');
        return null;
      }

      DebugUtils.logLazy(
          () => '📍 Using cached location: ${data['location']} (${age.inMinutes} min old)');
      return {
        'location': data['location'] as String,
        'displayLocation': data['displayLocation'] as String,
      };
    } catch (e) {
      DebugUtils.logLazy(() => '❌ Failed to load cached location: $e');
      return null;
    }
  }

  /// Clear cached location (e.g. for testing with different locations).
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cachedLocation');
      DebugUtils.logLazy(() => 'Location cache cleared');
    } catch (e) {
      DebugUtils.logLazy(() => '❌ Failed to clear location cache: $e');
    }
  }
}
