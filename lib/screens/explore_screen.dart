import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/explore_state.dart';
import '../models/temperature_data.dart';
import '../services/temperature_service.dart';
import '../services/visited_locations_service.dart';
import '../services/explore_cache_service.dart';
import '../utils/debug_utils.dart';
import '../widgets/date_location_pill.dart';
import 'dart:async';

/// Main Explore screen widget
class ExploreScreen extends StatefulWidget {
  final String? currentLocation;
  final String? displayLocation;
  final double? currentLatitude;
  final double? currentLongitude;
  
  const ExploreScreen({
    super.key,
    this.currentLocation,
    this.displayLocation,
    this.currentLatitude,
    this.currentLongitude,
  });

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  late ExploreState _state;
  late TemperatureService _temperatureService;
  late VisitedLocationsService _visitedLocationsService;
  late ExploreCacheService _cacheService;
  
  Timer? _debounceTimer;
  bool _isSwipeInProgress = false;
  

  @override
  void initState() {
    super.initState();
    _temperatureService = TemperatureService();
    _visitedLocationsService = VisitedLocationsService();
    _cacheService = ExploreCacheService();
    
    // Initialize with today's date and current location
    _state = ExploreState(
      anchorDate: DateTime.now(),
      period: ExplorePeriod.day,
      isLoading: true,
    );
    
    
    _initializeExplore();
  }

  @override
  void didUpdateWidget(ExploreScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Check if location has changed
    if (widget.currentLocation != oldWidget.currentLocation ||
        widget.currentLatitude != oldWidget.currentLatitude ||
        widget.currentLongitude != oldWidget.currentLongitude) {
      
      // Debug logging
      DebugUtils.logWithContextLazy('ExploreScreen', () => 'Location changed');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  currentLocation: ${widget.currentLocation}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  displayLocation: ${widget.displayLocation}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  latitude: ${widget.currentLatitude}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  longitude: ${widget.currentLongitude}');
      
      // Re-initialize with new location
      _initializeExplore();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Initialize the explore screen with data
  Future<void> _initializeExplore() async {
    try {
      DebugUtils.logWithContextLazy('ExploreScreen', () => '_initializeExplore called');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  currentLocation: ${widget.currentLocation}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  displayLocation: ${widget.displayLocation}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  latitude: ${widget.currentLatitude}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => '  longitude: ${widget.currentLongitude}');
      
      // Clean up any duplicate locations and invalid entries first
      await _visitedLocationsService.cleanupDuplicates();
      await _visitedLocationsService.forceCleanupInvalidLocations();
      
      // Always use the current location if available, otherwise use most recent visited location
      LocationInfo locationToUse;
      
      if (widget.currentLocation != null && 
          widget.currentLocation!.isNotEmpty &&
          widget.currentLatitude != null && 
          widget.currentLongitude != null) {
        // Use current location
        final displayName = widget.displayLocation ?? _extractDisplayLocation(widget.currentLocation!);
        
        // Skip if display name is empty, just coordinates, or if currentLocation is coordinates
        if (displayName.isNotEmpty && 
            !_isCoordinateString(displayName) && 
            !_isCoordinateString(widget.currentLocation!)) {
          locationToUse = LocationInfo(
            displayName: displayName,
            latitude: widget.currentLatitude!,
            longitude: widget.currentLongitude!,
            countryCode: _extractCountryCode(widget.currentLocation!),
          );
          
          // Add current location to visited locations (this will check for duplicates)
          await _visitedLocationsService.addVisitedLocation(locationToUse);
        } else {
          // If we only have coordinates or empty names, skip adding to visited locations
          // and use a fallback location
          locationToUse = LocationInfo(
            displayName: 'Unknown Location',
            latitude: widget.currentLatitude!,
            longitude: widget.currentLongitude!,
            countryCode: null,
          );
        }
      } else {
        // Get visited locations
        final visitedLocations = await _visitedLocationsService.getVisitedLocations();
        
        if (visitedLocations.isNotEmpty) {
          // Use the most recent visited location
          locationToUse = visitedLocations.last;
        } else {
          // Fallback to London if no location data
          locationToUse = LocationInfo(
            displayName: 'London',
            latitude: 51.5074,
            longitude: -0.1278,
            countryCode: 'GB',
          );
        }
      }
      
      setState(() {
        _state = _state.copyWith(
          location: locationToUse,
          isLoading: false,
        );
      });
      
      // Debug logging for state update
      DebugUtils.logWithContextLazy('ExploreScreen', () => 'State updated with location: ${locationToUse.displayName}');
      DebugUtils.logWithContextLazy('ExploreScreen', () => 'Location displayString: ${locationToUse.displayString}');
      
      await _loadExploreData();
    } catch (e) {
      // Error initializing explore
      setState(() {
        _state = _state.copyWith(
          error: 'Failed to initialize explore screen',
          isLoading: false,
        );
      });
    }
  }

  /// Load explore data for current state
  Future<void> _loadExploreData() async {
    if (_state.location == null) return;
    
    setState(() {
      _state = _state.copyWith(isFetching: true, error: null);
    });

    try {
      // Try to load from cache first
      final cachedData = await _cacheService.loadCachedExploreData(
        _state.location!,
        _state.anchorDate,
        _state.period,
      );

      if (cachedData != null) {
        setState(() {
          _state = _state.copyWith(
            data: cachedData,
            isFetching: false,
          );
        });
        return;
      }

      // Fetch fresh data from API
      final dateStr = DateFormat('yyyy-MM-dd').format(_state.anchorDate);
      // Use the full location string for API calls, not just the display name
      final locationForApi = _getLocationForApi(_state.location!);
      final temperatureData = await _temperatureService.fetchTemperature(
        locationForApi,
        dateStr,
      );

      // Convert to explore data format
      final exploreData = _convertToExploreData(temperatureData);
      
      // Cache the data
      await _cacheService.cacheExploreData(
        _state.location!,
        _state.anchorDate,
        _state.period,
        exploreData,
      );

      setState(() {
        _state = _state.copyWith(
          data: exploreData,
          isFetching: false,
        );
      });
    } catch (e) {
      // Error loading explore data
      setState(() {
        _state = _state.copyWith(
          error: 'Failed to load data: ${e.toString()}',
          isFetching: false,
        );
      });
    }
  }

  /// Convert TemperatureData to explore data format
  Map<String, dynamic> _convertToExploreData(TemperatureData temperatureData) {
    final chartData = <Map<String, dynamic>>[];
    
    // Convert series data to chart format
    if (temperatureData.series?.data != null) {
      for (final point in temperatureData.series!.data) {
        chartData.add({
          'year': point.x,
          'temperature': point.y,
        });
      }
    }

    // Calculate insights
    final insights = _calculateInsights(temperatureData);

    return {
      'chartData': chartData,
      'insights': insights,
      'currentTemperature': temperatureData.temperature,
      'average': temperatureData.average?.temperature,
      'trend': temperatureData.trend?.slope,
    };
  }

  /// Calculate insights from temperature data
  Map<String, dynamic> _calculateInsights(TemperatureData temperatureData) {
    final currentTemp = temperatureData.temperature ?? 0.0;
    final chartData = temperatureData.series?.data ?? [];
    
    // Calculate rank (how many years were warmer)
    final warmerYears = chartData.where((point) => 
        point.y != null && point.y! > currentTemp).length;
    final rank = chartData.length - warmerYears + 1;

    // Calculate deviation from average
    final validTemps = chartData.where((point) => point.y != null).map((point) => point.y!).toList();
    double deviation = 0.0;
    if (validTemps.isNotEmpty) {
      final average = validTemps.reduce((a, b) => a + b) / validTemps.length;
      deviation = currentTemp - average;
    }

    // Find extremes
    double highest = currentTemp;
    double lowest = currentTemp;
    if (validTemps.isNotEmpty) {
      highest = validTemps.reduce((a, b) => a > b ? a : b);
      lowest = validTemps.reduce((a, b) => a < b ? a : b);
    }

    // Calculate trend (simple linear regression)
    double trend = 0.0;
    if (chartData.length >= 2) {
      final validPoints = chartData.where((point) => point.y != null).toList();
      if (validPoints.length >= 2) {
        final n = validPoints.length;
        final sumX = validPoints.map((p) => p.x.toDouble()).reduce((a, b) => a + b);
        final sumY = validPoints.map((p) => p.y!).reduce((a, b) => a + b);
        final sumXY = validPoints.map((p) => p.x * p.y!).reduce((a, b) => a + b);
        final sumXX = validPoints.map((p) => p.x * p.x).reduce((a, b) => a + b);
        
        trend = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
      }
    }

    return {
      'rank': rank,
      'deviation': deviation,
      'extremes': {
        'highest': highest,
        'lowest': lowest,
      },
      'trend': trend,
    };
  }

  /// Handle date change with debouncing
  void _onDateChanged(DateTime newDate) {
    if (_isSwipeInProgress) return;
    
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _state = _state.copyWith(anchorDate: newDate);
        });
        _loadExploreData();
      }
    });
  }

  /// Handle location change
  void _onLocationChanged(LocationInfo newLocation) async {
    // Don't add to visited locations here - it's already handled in _initializeExplore
    // This prevents duplicate additions
    
    setState(() {
      _state = _state.copyWith(location: newLocation);
    });
    
    await _loadExploreData();
  }

  /// Handle period change (for Phase 2)
  void _onPeriodChanged(ExplorePeriod newPeriod) {
    if (newPeriod == ExplorePeriod.day) {
      setState(() {
        _state = _state.copyWith(period: newPeriod);
      });
      _loadExploreData();
    }
    // TODO: Implement week/month periods in Phase 2
  }

  /// Handle swipe gesture
  void _onSwipeLeft() {
    if (_isSwipeInProgress) return;
    
    final today = DateTime.now();
    final newDate = _state.anchorDate.add(const Duration(days: 1));
    
    if (newDate.isBefore(today) || newDate.isAtSameMomentAs(today)) {
      _isSwipeInProgress = true;
      _onDateChanged(newDate);
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSwipeInProgress = false;
      });
    }
  }

  void _onSwipeRight() {
    if (_isSwipeInProgress) return;
    
    final newDate = _state.anchorDate.subtract(const Duration(days: 1));
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
    
    if (newDate.isAfter(sevenDaysAgo) || newDate.isAtSameMomentAs(sevenDaysAgo)) {
      _isSwipeInProgress = true;
      _onDateChanged(newDate);
      Future.delayed(const Duration(milliseconds: 500), () {
        _isSwipeInProgress = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF242456),
            Color(0xFF343499),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header with date/location pill and segmented control
            _buildHeader(),
            
            // Chart area with swipe gestures
            Expanded(
              child: GestureDetector(
                onPanEnd: (details) {
                  if (details.velocity.pixelsPerSecond.dx > 100) {
                    _onSwipeRight();
                  } else if (details.velocity.pixelsPerSecond.dx < -100) {
                    _onSwipeLeft();
                  }
                },
                child: _buildChartArea(),
              ),
            ),
            
            // Dots indicator
            _buildDotsIndicator(),
            
            // Insights row
            _buildInsightsRow(),
            
            // Visited locations chips
            _buildVisitedLocationsChips(),
          ],
        ),
      ),
    );
  }

  /// Build header with pill and segmented control
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Date/Location pill
          GestureDetector(
            onTap: _state.location != null ? _showLocationPicker : null,
            child: Builder(
              builder: (context) {
                // Debug logging for pill data
                DebugUtils.logWithContextLazy('ExploreScreen', () => 'Building pill with location: ${_state.location?.displayName}');
                DebugUtils.logWithContextLazy('ExploreScreen', () => 'Pill city string: ${_state.location?.displayString}');
                
                return DateLocationPill(
                  date: _state.anchorDate,
                  city: _state.location?.displayString,
                  isLoading: _state.isLoading,
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Segmented control
          _buildSegmentedControl(),
        ],
      ),
    );
  }

  /// Build segmented control for period selection
  Widget _buildSegmentedControl() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          _buildPeriodButton('Day', ExplorePeriod.day, true),
          _buildPeriodButton('Week', ExplorePeriod.week, false),
          _buildPeriodButton('Month', ExplorePeriod.month, false),
        ],
      ),
    );
  }

  /// Build individual period button
  Widget _buildPeriodButton(String label, ExplorePeriod period, bool enabled) {
    final isSelected = _state.period == period;
    final isEnabled = enabled;
    
    return Expanded(
      child: GestureDetector(
        onTap: isEnabled ? () => _onPeriodChanged(period) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isEnabled ? Colors.white : Colors.white54,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              if (!isEnabled) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'soon',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Build chart area
  Widget _buildChartArea() {
    if (_state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6B6B)),
      );
    }

    if (_state.hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.white54, size: 48),
            const SizedBox(height: 16),
            Text(
              _state.error!,
              style: const TextStyle(color: Colors.white54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExploreData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (!_state.hasData) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    // TODO: Implement chart widget
    return const Center(
      child: Text(
        'Chart will be implemented here',
        style: TextStyle(color: Colors.white),
      ),
    );
  }

  /// Build dots indicator for last 7 days
  Widget _buildDotsIndicator() {
    final today = DateTime.now();
    final dots = <Widget>[];
    
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final isSelected = _state.anchorDate.day == date.day && 
                        _state.anchorDate.month == date.month &&
                        _state.anchorDate.year == date.year;
      
      dots.add(
        GestureDetector(
          onTap: () => _onDateChanged(date),
          child: Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: isSelected ? Colors.white : Colors.white54,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: dots,
      ),
    );
  }

  /// Build insights row
  Widget _buildInsightsRow() {
    if (!_state.hasData || _state.data!['insights'] == null) {
      return const SizedBox.shrink();
    }

    final insights = _state.data!['insights'] as Map<String, dynamic>;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          _buildInsightCard('Rank', '#${insights['rank'] ?? 'N/A'}'),
          const SizedBox(width: 8),
          _buildInsightCard('Deviation', '${insights['deviation']?.toStringAsFixed(1) ?? 'N/A'}°C'),
          const SizedBox(width: 8),
          _buildInsightCard('High', '${insights['extremes']?['highest']?.toStringAsFixed(1) ?? 'N/A'}°C'),
          const SizedBox(width: 8),
          _buildInsightCard('Trend', _getTrendDescription(insights['trend'])),
        ],
      ),
    );
  }

  /// Build individual insight card
  Widget _buildInsightCard(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Get trend description
  String _getTrendDescription(double? trend) {
    if (trend == null) return 'N/A';
    if (trend > 0.1) return 'Rising';
    if (trend < -0.1) return 'Falling';
    return 'Stable';
  }

  /// Extract country code from location string
  String? _extractCountryCode(String location) {
    // Try to extract country code from location string like "London, England, GB"
    final parts = location.split(',');
    if (parts.length >= 3) {
      final lastPart = parts.last.trim();
      if (lastPart.length == 2) {
        return lastPart.toUpperCase();
      }
    }
    return null;
  }

  /// Extract display location (city name) from full location string
  String _extractDisplayLocation(String fullLocation) {
    if (fullLocation.isEmpty) return '';
    
    // Split by comma and take the first part (city)
    final parts = fullLocation.split(',');
    if (parts.isNotEmpty) {
      return parts.first.trim();
    }
    
    return fullLocation;
  }

  /// Get location string formatted for API calls
  String _getLocationForApi(LocationInfo location) {
    // If we have a country code, format as "City, Country"
    if (location.countryCode != null) {
      return '${location.displayName}, ${location.countryCode}';
    }
    
    // Otherwise, just use the display name
    return location.displayName;
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

  /// Clear all visited locations and reinitialize
  Future<void> _clearAndReinitialize() async {
    await _visitedLocationsService.clearVisitedLocations();
    await _initializeExplore();
  }

  /// Force cleanup duplicates and refresh
  Future<void> _cleanupAndRefresh() async {
    await _visitedLocationsService.cleanupDuplicates();
    // Refresh the visited locations display
    setState(() {});
  }

  /// Force cleanup invalid locations and refresh
  Future<void> _forceCleanupInvalid() async {
    await _visitedLocationsService.forceCleanupInvalidLocations();
    // Refresh the visited locations display
    setState(() {});
  }

  /// Build visited locations chips
  Widget _buildVisitedLocationsChips() {
    return FutureBuilder<List<LocationInfo>>(
      future: _visitedLocationsService.getVisitedLocations(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'No visited locations yet',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _clearAndReinitialize,
                          child: Text('Clear Cache'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _cleanupAndRefresh,
                          child: Text('Cleanup Duplicates'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.2),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _forceCleanupInvalid,
                      child: Text('Remove Invalid Locations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Filter out invalid locations before displaying
        final validLocations = snapshot.data!.where((location) => 
          location.displayName.isNotEmpty && 
          location.displayName.trim().isNotEmpty &&
          !_isCoordinateString(location.displayName) &&
          !location.displayName.toLowerCase().contains('unknown')
        ).toList();

        if (validLocations.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'No valid visited locations found',
                  style: TextStyle(color: Colors.white54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                          onPressed: _clearAndReinitialize,
                          child: Text('Clear Cache'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.2),
                            foregroundColor: Colors.red,
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _cleanupAndRefresh,
                          child: Text('Cleanup Duplicates'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.withValues(alpha: 0.2),
                            foregroundColor: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _forceCleanupInvalid,
                      child: Text('Remove Invalid Locations'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple.withValues(alpha: 0.2),
                        foregroundColor: Colors.purple,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        final locations = validLocations;
        
        return Column(
          children: [
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: locations.length,
            itemBuilder: (context, index) {
              final location = locations[index];
              final isSelected = _state.location == location;
              
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => _onLocationChanged(location),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Colors.white.withValues(alpha: 0.2)
                          : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white54,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      location.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _clearAndReinitialize,
                  child: Text('Clear Cache'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.withValues(alpha: 0.2),
                    foregroundColor: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _cleanupAndRefresh,
                  child: Text('Cleanup Duplicates'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.withValues(alpha: 0.2),
                    foregroundColor: Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  /// Show location picker bottom sheet
  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildLocationPickerSheet(),
    );
  }

  /// Build location picker bottom sheet
  Widget _buildLocationPickerSheet() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF242456),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Select Location',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          FutureBuilder<List<LocationInfo>>(
            future: _visitedLocationsService.getVisitedLocations(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No visited locations yet',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              // Filter out invalid locations before displaying
              final validLocations = snapshot.data!.where((location) => 
                location.displayName.isNotEmpty && 
                location.displayName.trim().isNotEmpty &&
                !_isCoordinateString(location.displayName) &&
                !location.displayName.toLowerCase().contains('unknown')
              ).toList();

              if (validLocations.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(32),
                  child: Text(
                    'No valid visited locations found',
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              final locations = validLocations;
              
              return ListView.builder(
                shrinkWrap: true,
                itemCount: locations.length,
                itemBuilder: (context, index) {
                  final location = locations[index];
                  final isSelected = _state.location == location;
                  
                  return ListTile(
                    title: Text(
                      location.displayName,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    subtitle: Text(
                      '${location.latitude.toStringAsFixed(3)}, ${location.longitude.toStringAsFixed(3)}',
                      style: const TextStyle(color: Colors.white54),
                    ),
                    trailing: isSelected 
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                    onTap: () {
                      _onLocationChanged(location);
                      Navigator.pop(context);
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
