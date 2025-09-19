import 'temperature_data.dart';

/// Represents the current state of the Explore screen
class ExploreState {
  final LocationInfo? location;
  final DateTime anchorDate;
  final ExplorePeriod period;
  final bool isLoading;
  final Map<String, dynamic>? data;
  final String? error;
  final bool isFetching;

  const ExploreState({
    this.location,
    required this.anchorDate,
    this.period = ExplorePeriod.day,
    this.isLoading = false,
    this.data,
    this.error,
    this.isFetching = false,
  });

  ExploreState copyWith({
    LocationInfo? location,
    DateTime? anchorDate,
    ExplorePeriod? period,
    bool? isLoading,
    Map<String, dynamic>? data,
    String? error,
    bool? isFetching,
  }) {
    return ExploreState(
      location: location ?? this.location,
      anchorDate: anchorDate ?? this.anchorDate,
      period: period ?? this.period,
      isLoading: isLoading ?? this.isLoading,
      data: data ?? this.data,
      error: error ?? this.error,
      isFetching: isFetching ?? this.isFetching,
    );
  }

  /// Whether the current state has valid data
  bool get hasData => data != null && error == null;

  /// Whether the current state is in an error state
  bool get hasError => error != null;

  /// Whether the current state is loading or fetching
  bool get isBusy => isLoading || isFetching;
}

/// Represents a location with coordinates and display name
class LocationInfo {
  final String displayName;
  final double latitude;
  final double longitude;
  final String? countryCode;

  const LocationInfo({
    required this.displayName,
    required this.latitude,
    required this.longitude,
    this.countryCode,
  });

  /// Create a cache key for this location rounded to 3 decimal places
  String get cacheKey {
    final latRounded = (latitude * 1000).round() / 1000;
    final lonRounded = (longitude * 1000).round() / 1000;
    return '${latRounded.toStringAsFixed(3)}_${lonRounded.toStringAsFixed(3)}';
  }

  /// Create a display string for the location
  String get displayString {
    if (countryCode != null) {
      return '$displayName, $countryCode';
    }
    return displayName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationInfo &&
        other.displayName == displayName &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.countryCode == countryCode;
  }

  @override
  int get hashCode {
    return displayName.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        countryCode.hashCode;
  }
}

/// Represents the time period for exploration
enum ExplorePeriod {
  day,
  week,
  month,
}

/// Represents insights data for the current location and date
class InsightsData {
  final int? rank;
  final double? deviationFromAverage;
  final TemperatureExtremes? extremes;
  final TemperatureTrend? trend;

  const InsightsData({
    this.rank,
    this.deviationFromAverage,
    this.extremes,
    this.trend,
  });

  factory InsightsData.fromApiData(Map<String, dynamic> data) {
    return InsightsData(
      rank: data['rank'] as int?,
      deviationFromAverage: data['deviation']?.toDouble(),
      extremes: data['extremes'] != null 
          ? TemperatureExtremes.fromJson(data['extremes'])
          : null,
      trend: data['trend'] != null 
          ? TemperatureTrend.fromJson(data['trend'])
          : null,
    );
  }

  /// Compute insights from chart data if not provided by API
  factory InsightsData.computeFromChartData(List<DataPoint> chartData, double currentTemp) {
    if (chartData.isEmpty) {
      return const InsightsData();
    }

    // Calculate rank (how many years were warmer)
    final warmerYears = chartData.where((point) => 
        point.y != null && point.y! > currentTemp).length;
    final rank = warmerYears + 1;

    // Calculate deviation from average
    final validTemps = chartData.where((point) => point.y != null).map((point) => point.y!).toList();
    if (validTemps.isEmpty) {
      return InsightsData(rank: rank);
    }
    
    final average = validTemps.reduce((a, b) => a + b) / validTemps.length;
    final deviation = currentTemp - average;

    // Find extremes
    final sortedTemps = List<double>.from(validTemps)..sort();
    final extremes = TemperatureExtremes(
      highest: sortedTemps.last,
      lowest: sortedTemps.first,
      year: chartData.first.x,
    );

    // Calculate linear trend (simple linear regression)
    final trend = _calculateLinearTrend(chartData);

    return InsightsData(
      rank: rank,
      deviationFromAverage: deviation,
      extremes: extremes,
      trend: trend,
    );
  }

  static TemperatureTrend? _calculateLinearTrend(List<DataPoint> chartData) {
    if (chartData.length < 2) return null;

    final validPoints = chartData.where((point) => point.y != null).toList();
    if (validPoints.length < 2) return null;

    // Simple linear regression: y = mx + b
    final n = validPoints.length;
    final sumX = validPoints.map((p) => p.x.toDouble()).reduce((a, b) => a + b);
    final sumY = validPoints.map((p) => p.y!).reduce((a, b) => a + b);
    final sumXY = validPoints.map((p) => p.x * p.y!).reduce((a, b) => a + b);
    final sumXX = validPoints.map((p) => p.x * p.x).reduce((a, b) => a + b);

    final slope = (n * sumXY - sumX * sumY) / (n * sumXX - sumX * sumX);
    final intercept = (sumY - slope * sumX) / n;

    return TemperatureTrend(
      slope: slope,
      intercept: intercept,
      units: '°C per year',
    );
  }
}

/// Represents temperature extremes for a location
class TemperatureExtremes {
  final double highest;
  final double lowest;
  final int year;

  const TemperatureExtremes({
    required this.highest,
    required this.lowest,
    required this.year,
  });

  factory TemperatureExtremes.fromJson(Map<String, dynamic> json) {
    return TemperatureExtremes(
      highest: json['highest']?.toDouble() ?? 0.0,
      lowest: json['lowest']?.toDouble() ?? 0.0,
      year: json['year'] ?? 0,
    );
  }
}

/// Represents temperature trend data
class TemperatureTrend {
  final double slope;
  final double intercept;
  final String units;

  const TemperatureTrend({
    required this.slope,
    required this.intercept,
    required this.units,
  });

  factory TemperatureTrend.fromJson(Map<String, dynamic> json) {
    return TemperatureTrend(
      slope: json['slope']?.toDouble() ?? 0.0,
      intercept: json['intercept']?.toDouble() ?? 0.0,
      units: json['units'] ?? '°C per year',
    );
  }

  /// Get the trend description
  String get description {
    if (slope > 0.1) return 'Rising';
    if (slope < -0.1) return 'Falling';
    return 'Stable';
  }
}
