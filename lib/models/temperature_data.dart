class TemperatureData {
  final Average? average;
  final Trend? trend;
  final String? summary;
  final dynamic currentWeather;
  final Series? series;
  final double? temperature; // For simple API responses

  TemperatureData({
    this.average,
    this.trend,
    this.summary,
    this.currentWeather,
    this.series,
    this.temperature,
  });

  // Constructor for simple API responses like {"days":[{"temp":19.8}]}
  factory TemperatureData.simple(double temp) {
    return TemperatureData(temperature: temp);
  }

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    // Check if this is a simple response with days array
    if (json.containsKey('days') && json['days'] is List) {
      final days = json['days'] as List;
      if (days.isNotEmpty && days[0] is Map && days[0]['temp'] != null) {
        return TemperatureData.simple(days[0]['temp'].toDouble());
      }
    }
    
    // Handle complex response structure
    return TemperatureData(
      average: json['average'] != null ? Average.fromJson(json['average']) : null,
      trend: json['trend'] != null ? Trend.fromJson(json['trend']) : null,
      summary: json['summary'],
      currentWeather: json['current_weather'],
      series: json['weather'] != null ? Series.fromJson(json['weather']) : null,
    );
  }
}

class Average {
  final double? temperature;
  final String unit;
  final int dataPoints;
  final YearRange yearRange;
  final List<dynamic> missingYears;
  final double? completeness;

  Average({
    required this.temperature,
    required this.unit,
    required this.dataPoints,
    required this.yearRange,
    required this.missingYears,
    required this.completeness,
  });

  factory Average.fromJson(Map<String, dynamic> json) {
    final temp = json['average'];
    final completeness = json['completeness'];
    return Average(
      temperature: temp != null ? (temp as num).toDouble() : null,
      unit: json['unit'] ?? '',
      dataPoints: json['data_points'] ?? 0,
      yearRange: json['year_range'] != null ? YearRange.fromJson(json['year_range']) : YearRange(start: 0, end: 0),
      missingYears: json['missing_years'] ?? [],
      completeness: completeness != null ? (completeness as num).toDouble() : null,
    );
  }
}

class YearRange {
  final int start;
  final int end;

  YearRange({required this.start, required this.end});

  factory YearRange.fromJson(Map<String, dynamic> json) {
    return YearRange(
      start: json['start'],
      end: json['end'],
    );
  }
}

class Trend {
  final double? slope;
  final String units;

  Trend({required this.slope, required this.units});

  factory Trend.fromJson(Map<String, dynamic> json) {
    final slope = json['slope'];
    return Trend(
      slope: slope != null ? (slope as num).toDouble() : null,
      units: json['units'] ?? '',
    );
  }
}

class Series {
  final List<DataPoint> data;
  final Metadata metadata;

  Series({required this.data, required this.metadata});

  factory Series.fromJson(Map<String, dynamic> json) {
    return Series(
      data: (json['data'] as List)
          .map((point) => DataPoint.fromJson(point))
          .toList(),
      metadata: Metadata.fromJson(json['metadata']),
    );
  }
}

class DataPoint {
  final int x;
  final double? y;

  DataPoint({required this.x, required this.y});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    final y = json['y'];
    return DataPoint(
      x: json['x'] ?? 0,
      y: y != null ? (y as num).toDouble() : null,
    );
  }
}

class Metadata {
  final int totalYears;
  final int availableYears;

  Metadata({
    required this.totalYears,
    required this.availableYears,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      totalYears: json['total_years'],
      availableYears: json['available_years'],
    );
  }
} 