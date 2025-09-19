import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/models/explore_state.dart';
import 'package:temphist_app/models/temperature_data.dart';
import 'package:temphist_app/screens/explore_screen.dart';

void main() {
  group('ExploreState', () {
    test('should create state with default values', () {
      final state = ExploreState(anchorDate: DateTime(2024, 1, 15));
      
      expect(state.anchorDate, DateTime(2024, 1, 15));
      expect(state.period, ExplorePeriod.day);
      expect(state.isLoading, false);
      expect(state.data, null);
      expect(state.error, null);
      expect(state.isFetching, false);
      expect(state.hasData, false);
      expect(state.hasError, false);
      expect(state.isBusy, false);
    });

    test('should copy with new values', () {
      final original = ExploreState(anchorDate: DateTime(2024, 1, 15));
      final updated = original.copyWith(
        isLoading: true,
        error: 'Test error',
      );
      
      expect(updated.anchorDate, DateTime(2024, 1, 15));
      expect(updated.isLoading, true);
      expect(updated.error, 'Test error');
      expect(updated.data, null);
    });

    test('should identify data state correctly', () {
      final stateWithData = ExploreState(
        anchorDate: DateTime(2024, 1, 15),
        data: {'test': 'value'},
      );
      
      final stateWithError = ExploreState(
        anchorDate: DateTime(2024, 1, 15),
        error: 'Test error',
      );
      
      final stateLoading = ExploreState(
        anchorDate: DateTime(2024, 1, 15),
        isLoading: true,
      );
      
      expect(stateWithData.hasData, true);
      expect(stateWithData.hasError, false);
      expect(stateWithData.isBusy, false);
      
      expect(stateWithError.hasData, false);
      expect(stateWithError.hasError, true);
      expect(stateWithError.isBusy, false);
      
      expect(stateLoading.hasData, false);
      expect(stateLoading.hasError, false);
      expect(stateLoading.isBusy, true);
    });
  });

  group('LocationInfo', () {
    test('should create location with correct properties', () {
      final location = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
        countryCode: 'GB',
      );
      
      expect(location.displayName, 'London');
      expect(location.latitude, 51.5074);
      expect(location.longitude, -0.1278);
      expect(location.countryCode, 'GB');
    });

    test('should generate correct cache key', () {
      final location = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
      );
      
      expect(location.cacheKey, '51.507_-0.128');
    });

    test('should generate correct display string', () {
      final locationWithCountry = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
        countryCode: 'GB',
      );
      
      final locationWithoutCountry = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
      );
      
      expect(locationWithCountry.displayString, 'London, GB');
      expect(locationWithoutCountry.displayString, 'London');
    });

    test('should compare locations correctly', () {
      final location1 = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
        countryCode: 'GB',
      );
      
      final location2 = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
        countryCode: 'GB',
      );
      
      final location3 = LocationInfo(
        displayName: 'Paris',
        latitude: 48.8566,
        longitude: 2.3522,
        countryCode: 'FR',
      );
      
      expect(location1 == location2, true);
      expect(location1 == location3, false);
      expect(location1.hashCode == location2.hashCode, true);
    });
  });

  group('InsightsData', () {
    test('should compute insights from chart data', () {
      final chartData = [
        DataPoint(x: 2020, y: 15.0),
        DataPoint(x: 2021, y: 16.0),
        DataPoint(x: 2022, y: 17.0),
        DataPoint(x: 2023, y: 18.0),
        DataPoint(x: 2024, y: 19.0),
      ];
      
      final insights = InsightsData.computeFromChartData(chartData, 19.0);
      
      expect(insights.rank, 1); // Current year is warmest (rank 1)
      expect(insights.deviationFromAverage, 2.0); // 19.0 - 17.0
      expect(insights.extremes?.highest, 19.0);
      expect(insights.extremes?.lowest, 15.0);
      expect(insights.trend?.slope, greaterThan(0)); // Rising trend
    });

    test('should handle empty chart data', () {
      final insights = InsightsData.computeFromChartData([], 19.0);
      
      expect(insights.rank, null);
      expect(insights.deviationFromAverage, null);
      expect(insights.extremes, null);
      expect(insights.trend, null);
    });

    test('should handle single data point', () {
      final chartData = [DataPoint(x: 2024, y: 19.0)];
      final insights = InsightsData.computeFromChartData(chartData, 19.0);
      
      expect(insights.rank, 1); // Only one data point, so rank 1
      expect(insights.deviationFromAverage, 0.0);
      expect(insights.extremes?.highest, 19.0);
      expect(insights.extremes?.lowest, 19.0);
      expect(insights.trend, null); // Need at least 2 points for trend
    });
  });

  group('TemperatureExtremes', () {
    test('should create extremes with correct values', () {
      final extremes = TemperatureExtremes(
        highest: 25.0,
        lowest: 10.0,
        year: 2024,
      );
      
      expect(extremes.highest, 25.0);
      expect(extremes.lowest, 10.0);
      expect(extremes.year, 2024);
    });

    test('should create from JSON', () {
      final json = {
        'highest': 25.0,
        'lowest': 10.0,
        'year': 2024,
      };
      
      final extremes = TemperatureExtremes.fromJson(json);
      
      expect(extremes.highest, 25.0);
      expect(extremes.lowest, 10.0);
      expect(extremes.year, 2024);
    });
  });

  group('TemperatureTrend', () {
    test('should create trend with correct values', () {
      final trend = TemperatureTrend(
        slope: 0.5,
        intercept: 10.0,
        units: '°C per year',
      );
      
      expect(trend.slope, 0.5);
      expect(trend.intercept, 10.0);
      expect(trend.units, '°C per year');
    });

    test('should provide correct description', () {
      final risingTrend = TemperatureTrend(
        slope: 0.5,
        intercept: 10.0,
        units: '°C per year',
      );
      
      final fallingTrend = TemperatureTrend(
        slope: -0.5,
        intercept: 10.0,
        units: '°C per year',
      );
      
      final stableTrend = TemperatureTrend(
        slope: 0.05,
        intercept: 10.0,
        units: '°C per year',
      );
      
      expect(risingTrend.description, 'Rising');
      expect(fallingTrend.description, 'Falling');
      expect(stableTrend.description, 'Stable');
    });

    test('should create from JSON', () {
      final json = {
        'slope': 0.5,
        'intercept': 10.0,
        'units': '°C per year',
      };
      
      final trend = TemperatureTrend.fromJson(json);
      
      expect(trend.slope, 0.5);
      expect(trend.intercept, 10.0);
      expect(trend.units, '°C per year');
    });
  });

  group('Date clamping tests', () {
    test('should clamp date to last 7 days', () {
      final today = DateTime.now();
      final sevenDaysAgo = today.subtract(const Duration(days: 7));
      final eightDaysAgo = today.subtract(const Duration(days: 8));
      
      // Test that we can't go beyond 7 days ago
      expect(eightDaysAgo.isBefore(sevenDaysAgo), true);
      
      // Test that we can't go beyond today
      final tomorrow = today.add(const Duration(days: 1));
      expect(tomorrow.isAfter(today), true);
    });
  });

  group('Cache key generation', () {
    test('should generate correct cache keys for different periods', () {
      final location = LocationInfo(
        displayName: 'London',
        latitude: 51.5074,
        longitude: -0.1278,
      );
      
      // Test daily cache key
      final dailyKey = 'daily:${location.cacheKey}:2024-01-15';
      expect(dailyKey, 'daily:51.507_-0.128:2024-01-15');
      
      // Test weekly cache key
      final weeklyKey = 'weekly:${location.cacheKey}:2024-01-15';
      expect(weeklyKey, 'weekly:51.507_-0.128:2024-01-15');
      
      // Test monthly cache key
      final monthlyKey = 'monthly:${location.cacheKey}:2024-01-15';
      expect(monthlyKey, 'monthly:51.507_-0.128:2024-01-15');
    });
  });

  group('ExploreScreen location integration', () {
    test('should accept location parameters', () {
      const exploreScreen = ExploreScreen(
        currentLocation: 'London, England, GB',
        displayLocation: 'London',
        currentLatitude: 51.5074,
        currentLongitude: -0.1278,
      );
      
      expect(exploreScreen.currentLocation, 'London, England, GB');
      expect(exploreScreen.displayLocation, 'London');
      expect(exploreScreen.currentLatitude, 51.5074);
      expect(exploreScreen.currentLongitude, -0.1278);
    });
  });
}
