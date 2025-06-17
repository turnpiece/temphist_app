class TemperatureData {
  final Average average;
  final Trend trend;
  final String summary;
  final dynamic currentWeather;
  final Series series;

  TemperatureData({
    required this.average,
    required this.trend,
    required this.summary,
    this.currentWeather,
    required this.series,
  });

  factory TemperatureData.fromJson(Map<String, dynamic> json) {
    return TemperatureData(
      average: Average.fromJson(json['average']),
      trend: Trend.fromJson(json['trend']),
      summary: json['summary'],
      currentWeather: json['current_weather'],
      series: Series.fromJson(json['series']),
    );
  }
}

class Average {
  final double temperature;
  final String unit;
  final int dataPoints;
  final YearRange yearRange;
  final List<dynamic> missingYears;
  final double completeness;

  Average({
    required this.temperature,
    required this.unit,
    required this.dataPoints,
    required this.yearRange,
    required this.missingYears,
    required this.completeness,
  });

  factory Average.fromJson(Map<String, dynamic> json) {
    return Average(
      temperature: json['temperature'].toDouble(),
      unit: json['unit'],
      dataPoints: json['data_points'],
      yearRange: YearRange.fromJson(json['year_range']),
      missingYears: json['missing_years'],
      completeness: json['completeness'].toDouble(),
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
  final double slope;
  final String units;

  Trend({required this.slope, required this.units});

  factory Trend.fromJson(Map<String, dynamic> json) {
    return Trend(
      slope: json['slope'].toDouble(),
      units: json['units'],
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
  final double y;

  DataPoint({required this.x, required this.y});

  factory DataPoint.fromJson(Map<String, dynamic> json) {
    return DataPoint(
      x: json['x'],
      y: json['y'].toDouble(),
    );
  }
}

class Metadata {
  final String location;
  final String date;
  final int totalYears;
  final int availableYears;

  Metadata({
    required this.location,
    required this.date,
    required this.totalYears,
    required this.availableYears,
  });

  factory Metadata.fromJson(Map<String, dynamic> json) {
    return Metadata(
      location: json['location'],
      date: json['date'],
      totalYears: json['total_years'],
      availableYears: json['available_years'],
    );
  }
} 