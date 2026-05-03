// Data models for the v1 records API responses.
//
// The v1 API returns all years' data in a single response, unlike the legacy
// API which requires year-by-year fetching. Used for daily, weekly, monthly,
// and yearly period views.

class PeriodTemperatureData {
  final String period;
  final String location;
  final String identifier;
  final PeriodRange range;
  final String unitGroup;
  final List<PeriodDataPoint> values;
  final PeriodAverage average;
  final PeriodTrend trend;
  final String summary;
  final PeriodMetadata? metadata;

  /// Population standard deviation of all temperatures in the series, in the
  /// same unit as [values]. Used to compute per-year Z-scores for chart
  /// coloring. May be null for very short series or when the API omits it.
  final double? standardDeviation;

  PeriodTemperatureData({
    required this.period,
    required this.location,
    required this.identifier,
    required this.range,
    required this.unitGroup,
    required this.values,
    required this.average,
    required this.trend,
    required this.summary,
    this.metadata,
    this.standardDeviation,
  });

  /// Whether the API returned data already converted to Fahrenheit.
  bool get isFahrenheit => unitGroup == 'fahrenheit';

  factory PeriodTemperatureData.fromJson(Map<String, dynamic> json) {
    final stdDev = json['standard_deviation'];
    return PeriodTemperatureData(
      period: json['period'] ?? '',
      location: json['location'] ?? '',
      identifier: json['identifier'] ?? '',
      range: PeriodRange.fromJson(json['range'] ?? {}),
      unitGroup: json['unit_group'] ?? 'metric',
      values: (json['values'] as List? ?? [])
          .map((v) => PeriodDataPoint.fromJson(v))
          .toList(),
      average: PeriodAverage.fromJson(json['average'] ?? {}),
      trend: PeriodTrend.fromJson(json['trend'] ?? {}),
      summary: json['summary'] ?? '',
      metadata: json['metadata'] != null
          ? PeriodMetadata.fromJson(json['metadata'])
          : null,
      standardDeviation: stdDev is num ? stdDev.toDouble() : null,
    );
  }
}

class PeriodRange {
  final String start;
  final String end;
  final int years;

  PeriodRange({
    required this.start,
    required this.end,
    required this.years,
  });

  factory PeriodRange.fromJson(Map<String, dynamic> json) {
    return PeriodRange(
      start: json['start'] ?? '',
      end: json['end'] ?? '',
      years: json['years'] ?? 0,
    );
  }
}

class PeriodDataPoint {
  final String date;
  final int year;
  final double temperature;

  /// Deviation from the series mean (`temperature - mean`), in the same unit
  /// as [temperature]. May be null when the API omits it.
  final double? anomaly;

  PeriodDataPoint({
    required this.date,
    required this.year,
    required this.temperature,
    this.anomaly,
  });

  factory PeriodDataPoint.fromJson(Map<String, dynamic> json) {
    final temp = json['temperature'];
    final anom = json['anomaly'];
    return PeriodDataPoint(
      date: json['date'] ?? '',
      year: json['year'] ?? 0,
      temperature: temp != null ? (temp as num).toDouble() : 0.0,
      anomaly: anom is num ? anom.toDouble() : null,
    );
  }
}

class PeriodAverage {
  final double mean;

  PeriodAverage({required this.mean});

  factory PeriodAverage.fromJson(Map<String, dynamic> json) {
    final m = json['mean'];
    return PeriodAverage(
      mean: m != null ? (m as num).toDouble() : 0.0,
    );
  }
}

class PeriodTrend {
  final double slope;
  final String unit;

  PeriodTrend({required this.slope, required this.unit});

  factory PeriodTrend.fromJson(Map<String, dynamic> json) {
    final s = json['slope'];
    return PeriodTrend(
      slope: s != null ? (s as num).toDouble() : 0.0,
      unit: json['unit'] ?? '',
    );
  }
}

class PeriodMissingYear {
  final int year;
  final String reason;

  PeriodMissingYear({required this.year, required this.reason});

  factory PeriodMissingYear.fromJson(Map<String, dynamic> json) {
    return PeriodMissingYear(
      year: json['year'] ?? 0,
      reason: json['reason'] ?? '',
    );
  }
}

class PeriodMetadata {
  final int totalYears;
  final int availableYears;
  final List<PeriodMissingYear> missingYears;
  final double completeness;
  final int periodDays;
  final String endDate;

  PeriodMetadata({
    required this.totalYears,
    required this.availableYears,
    required this.missingYears,
    required this.completeness,
    required this.periodDays,
    required this.endDate,
  });

  factory PeriodMetadata.fromJson(Map<String, dynamic> json) {
    final comp = json['completeness'];
    return PeriodMetadata(
      totalYears: json['total_years'] ?? 0,
      availableYears: json['available_years'] ?? 0,
      missingYears: (json['missing_years'] as List? ?? [])
          .map((m) => PeriodMissingYear.fromJson(m))
          .toList(),
      completeness: comp != null ? (comp as num).toDouble() : 0.0,
      periodDays: json['period_days'] ?? 0,
      endDate: json['end_date'] ?? '',
    );
  }
}

/// Wrapper for async job results from the v1 API.
class JobResult {
  final String cacheKey;
  final String etag;
  final PeriodTemperatureData data;
  final String computedAt;

  JobResult({
    required this.cacheKey,
    required this.etag,
    required this.data,
    required this.computedAt,
  });

  factory JobResult.fromJson(Map<String, dynamic> json) {
    return JobResult(
      cacheKey: json['cache_key'] ?? '',
      etag: json['etag'] ?? '',
      data: PeriodTemperatureData.fromJson(json['data'] ?? {}),
      computedAt: json['computed_at'] ?? '',
    );
  }
}

/// Status response when polling an async job.
class AsyncJobStatus {
  final String jobId;
  final String status; // 'pending', 'processing', 'ready', 'error'
  final JobResult? result;
  final String? error;
  final String? message;

  AsyncJobStatus({
    required this.jobId,
    required this.status,
    this.result,
    this.error,
    this.message,
  });

  factory AsyncJobStatus.fromJson(Map<String, dynamic> json) {
    return AsyncJobStatus(
      jobId: json['job_id'] ?? '',
      status: json['status'] ?? 'error',
      result: json['result'] != null
          ? JobResult.fromJson(json['result'])
          : null,
      error: json['error'],
      message: json['message'],
    );
  }

  bool get isReady => status == 'ready' && result != null;
  bool get isError => status == 'error';
  bool get isPending => status == 'pending' || status == 'processing';
}
