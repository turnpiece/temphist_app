import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../constants/app_constants.dart';
import '../utils/temperature_utils.dart';

// Re-export so existing code can import from here
class TemperatureChartData {
  final String year;
  final double temperature;
  final bool isCurrentYear;
  final bool hasData;

  /// API-supplied anomaly (`temperature - series mean`) for this year.
  /// When provided alongside a series-level standard deviation, the chart
  /// colors bars by Z-score instead of normalizing to the largest anomaly.
  final double? anomaly;

  final Color? barFillColor;
  final Color? barBorderColor;

  TemperatureChartData({
    required this.year,
    required this.temperature,
    required this.isCurrentYear,
    this.hasData = true,
    this.anomaly,
    this.barFillColor,
    this.barBorderColor,
  });
}

class TemperatureChartPresentation {
  final List<TemperatureChartData> styledChartData;
  final List<TemperatureChartData> validData;
  final double yAxisMin;
  final double yAxisMax;
  final double yAxisInterval;
  final String unitLabel;
  final bool shouldConvert;

  const TemperatureChartPresentation({
    required this.styledChartData,
    required this.validData,
    required this.yAxisMin,
    required this.yAxisMax,
    required this.yAxisInterval,
    required this.unitLabel,
    required this.shouldConvert,
  });

  List<double> get axisTicks {
    final ticks = <double>[];
    var value = yAxisMin;
    while (value <= yAxisMax + 0.0001) {
      ticks.add(value);
      value += yAxisInterval;
    }
    return ticks;
  }

  String formatAxisLabel(double rawValue) {
    final display = shouldConvert ? celsiusToFahrenheit(rawValue) : rawValue;
    return '${display.toStringAsFixed(0)}$unitLabel';
  }
}

const double kTemperatureChartTopAxisHeight = 22.0;

double computeTemperatureChartWidth(BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= kTabletBreakpointWidth;
  final availableWidth = isTablet ? kTabletMaxContentWidth : screenWidth;
  final contentPadding = kScreenPadding + kContentHorizontalMargin;
  return availableWidth - kChartRightMargin - (contentPadding * 2);
}

TemperatureChartPresentation? buildTemperatureChartPresentation({
  required BuildContext context,
  required List<TemperatureChartData> chartData,
  required double? averageTemperature,
  required bool isFahrenheit,
  required bool needsConversion,
  double? standardDeviation,
}) {
  final shouldConvert = isFahrenheit && needsConversion;
  final unitLabel = temperatureUnitLabel(isFahrenheit: isFahrenheit);
  final styledChartData = _styleChartDataForPresentation(
    chartData,
    averageTemperature,
    standardDeviation,
  );
  final validData = styledChartData.where((d) => d.hasData).toList();

  if (validData.isEmpty) {
    return null;
  }

  final minTemp = validData.map((d) => d.temperature).reduce(math.min);
  final maxTemp = validData.map((d) => d.temperature).reduce(math.max);

  double yAxisMin = (minTemp - 2).floorToDouble();
  double yAxisMax = (maxTemp + 2).ceilToDouble();

  final range = maxTemp - minTemp;
  if (range < 5) {
    final midPoint = (maxTemp + minTemp) / 2;
    yAxisMin = (midPoint - 2.5).floorToDouble();
    yAxisMax = (midPoint + 2.5).ceilToDouble();
  }

  final screenWidth = MediaQuery.of(context).size.width;
  final isTablet = screenWidth >= kTabletBreakpointWidth;
  final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
  final maxLabels = (!isTablet && isPortrait) ? 5 : 7;
  final maxIntervals = maxLabels - 1;
  final yRange = yAxisMax - yAxisMin;

  final double yAxisInterval;
  if (yRange / 1 <= maxIntervals) {
    yAxisInterval = 1;
  } else if (yRange / 2 <= maxIntervals) {
    yAxisInterval = 2;
  } else if (yRange / 3 <= maxIntervals) {
    yAxisInterval = 3;
  } else if (yRange / 5 <= maxIntervals) {
    yAxisInterval = 5;
  } else if (yRange / 10 <= maxIntervals) {
    yAxisInterval = 10;
  } else {
    yAxisInterval = 20;
  }

  yAxisMin = (minTemp / yAxisInterval).floor() * yAxisInterval;
  if (yAxisMin >= minTemp) {
    yAxisMin -= yAxisInterval;
  }

  const double kUpperTickThreshold = 1.0 / 3.0;
  final lastTickBeforeMax = (maxTemp / yAxisInterval).floor() * yAxisInterval;
  final fractionIntoNextStep = (maxTemp - lastTickBeforeMax) / yAxisInterval;
  if (fractionIntoNextStep > kUpperTickThreshold) {
    yAxisMax = lastTickBeforeMax + yAxisInterval;
  } else {
    yAxisMax = maxTemp + yAxisInterval * 0.2;
  }

  const double kMinBarFraction = 0.05;
  if ((minTemp - yAxisMin) / (yAxisMax - yAxisMin) < kMinBarFraction) {
    yAxisMin -= yAxisInterval;
  }

  return TemperatureChartPresentation(
    styledChartData: styledChartData,
    validData: validData,
    yAxisMin: yAxisMin,
    yAxisMax: yAxisMax,
    yAxisInterval: yAxisInterval,
    unitLabel: unitLabel,
    shouldConvert: shouldConvert,
  );
}

class TemperatureChartTopAxis extends StatelessWidget {
  final TemperatureChartPresentation presentation;

  const TemperatureChartTopAxis({
    super.key,
    required this.presentation,
  });

  @override
  Widget build(BuildContext context) {
    final chartWidth = computeTemperatureChartWidth(context);

    return Center(
      child: SizedBox(
        width: chartWidth,
        height: kTemperatureChartTopAxisHeight,
        child: SfCartesianChart(
          isTransposed: true,
          margin: const EdgeInsets.only(
            left: kChartHorizontalMargin,
            right: kChartRightMargin,
          ),
          primaryXAxis: NumericAxis(
            labelStyle: const TextStyle(
              fontSize: kFontSizeAxisLabel,
              color: Colors.transparent,
              fontFamilyFallback: kChartAxisFontFamilyFallback,
            ),
            majorGridLines: const MajorGridLines(width: 0),
            majorTickLines: const MajorTickLines(width: 0, size: 0),
            labelIntersectAction: AxisLabelIntersectAction.hide,
            minimum: kChartStartYear.toDouble(),
            maximum: DateTime.now().year.toDouble(),
            interval: 5,
            labelFormat: '{value}',
            plotOffset: 20,
            axisLine: const AxisLine(width: 0),
          ),
          primaryYAxis: NumericAxis(
            opposedPosition: true,
            axisLabelFormatter: (AxisLabelRenderDetails details) {
              return ChartAxisLabel(
                presentation.formatAxisLabel(details.value.toDouble()),
                details.textStyle,
              );
            },
            minimum: presentation.yAxisMin,
            maximum: presentation.yAxisMax,
            majorGridLines: const MajorGridLines(width: 0),
            labelStyle: const TextStyle(
              fontSize: kFontSizeAxisLabel,
              color: kGreyLabelColour,
              fontFamilyFallback: kChartAxisFontFamilyFallback,
            ),
            plotOffset: 0,
            interval: presentation.yAxisInterval,
            labelPosition: ChartDataLabelPosition.outside,
            majorTickLines: const MajorTickLines(
              size: 4,
              width: 1,
              color: kAxisLabelColour,
            ),
            axisLine: const AxisLine(width: 1, color: kAxisLabelColour),
          ),
          plotAreaBorderWidth: 0,
          enableAxisAnimation: false,
          series: const <CartesianSeries<dynamic, dynamic>>[],
        ),
      ),
    );
  }
}

/// |Z| at which a bar is fully saturated red (warm) or blue (cool).
/// Roughly the 95th percentile of a normal distribution (|Z| >= 2 covers ~5%
/// of years), so most years sit somewhere in the diverging gradient.
const double _kColorSaturationZ = 2.0;

/// |Z| at which a bar still reads as neutral grey. Anything closer to the
/// mean than this gets no warm/cool tint, so "about average" years don't
/// look faintly red or blue.
const double _kNeutralZBand = 0.25;

List<TemperatureChartData> _styleChartDataForPresentation(
  List<TemperatureChartData> data,
  double? averageTemperature,
  double? standardDeviation,
) {
  if (data.isEmpty) {
    return data;
  }

  final validValues = data.where((d) => d.hasData).toList();
  if (validValues.isEmpty) {
    return data;
  }

  final baseline = averageTemperature;
  if (baseline == null) {
    return data
        .map(
          (d) => TemperatureChartData(
            year: d.year,
            temperature: d.temperature,
            isCurrentYear: d.isCurrentYear,
            hasData: d.hasData,
            anomaly: d.anomaly,
            barFillColor:
                d.isCurrentYear ? kBarCurrentYearColour : kBarNeutralColour,
            barBorderColor:
                d.isCurrentYear ? kBarCurrentYearColour : kBarNeutralColour,
          ),
        )
        .toList();
  }

  // Prefer the API's series-level standard deviation. When it's missing or
  // zero we fall back to normalizing each bar's anomaly against the largest
  // observed anomaly so the chart still has meaningful contrast.
  final useZScore =
      standardDeviation != null && standardDeviation > 0;

  double maxWarmAnomaly = 0;
  double maxCoolAnomaly = 0;
  if (!useZScore) {
    for (final d in validValues) {
      final a = d.anomaly ?? (d.temperature - baseline);
      if (a > maxWarmAnomaly) maxWarmAnomaly = a;
      if (a < 0 && a.abs() > maxCoolAnomaly) maxCoolAnomaly = a.abs();
    }
  }

  return data.map((d) {
    final anomaly = d.anomaly ?? (d.temperature - baseline);
    final fillColor = d.isCurrentYear
        ? kBarCurrentYearColour
        : useZScore
            ? _barColorForZScore(anomaly / standardDeviation)
            : _barColorForAnomaly(anomaly, maxWarmAnomaly, maxCoolAnomaly);
    return TemperatureChartData(
      year: d.year,
      temperature: d.temperature,
      isCurrentYear: d.isCurrentYear,
      hasData: d.hasData,
      anomaly: anomaly,
      barFillColor: fillColor,
      barBorderColor: fillColor,
    );
  }).toList();
}

/// Map a Z-score to a diverging blue → grey → red color.
Color _barColorForZScore(double z) {
  final magnitude = z.abs();
  if (magnitude <= _kNeutralZBand) {
    return kBarNeutralColour;
  }
  final blend = ((magnitude - _kNeutralZBand) /
          (_kColorSaturationZ - _kNeutralZBand))
      .clamp(0.0, 1.0);
  return Color.lerp(
        kBarNeutralColour,
        z >= 0 ? kBarWarmColour : kBarCoolColour,
        blend,
      ) ??
      kBarNeutralColour;
}

/// Fallback coloring used when the series has no standard deviation (e.g.
/// a single-year cache from before the API exposed it). Normalizes each
/// anomaly against the largest observed warm/cool anomaly in the series.
Color _barColorForAnomaly(
  double anomaly,
  double maxWarmAnomaly,
  double maxCoolAnomaly,
) {
  const double neutralBand = 0.12;
  double normalized;
  if (anomaly > 0) {
    normalized = maxWarmAnomaly == 0 ? 0 : anomaly / maxWarmAnomaly;
  } else if (anomaly < 0) {
    normalized = maxCoolAnomaly == 0 ? 0 : anomaly.abs() / maxCoolAnomaly;
  } else {
    normalized = 0;
  }

  if (normalized <= neutralBand) {
    return kBarNeutralColour;
  }

  final blend =
      ((normalized - neutralBand) / (1 - neutralBand)).clamp(0.0, 1.0);
  return Color.lerp(
        kBarNeutralColour,
        anomaly >= 0 ? kBarWarmColour : kBarCoolColour,
        blend,
      ) ??
      kBarNeutralColour;
}

/// A reusable horizontal bar chart showing temperature data across years.
///
/// Used by both the daily view (progressive loading) and period views
/// (weekly, monthly, yearly) which load all data in one API call.
class TemperatureBarChart extends StatelessWidget {
  final List<TemperatureChartData> chartData;
  final double? averageTemperature;
  final double? trendSlope;
  final bool isLoading;
  final double height;
  final bool isFahrenheit;

  /// Whether the chart values need client-side Celsius→Fahrenheit conversion.
  ///
  /// When the API already returns Fahrenheit data this should be `false`
  /// (data is pre-converted).  Defaults to `true` to preserve the existing
  /// behaviour where the app always converts from Celsius.
  final bool needsConversion;
  final bool showTemperatureAxis;

  /// Series-level standard deviation (matches [chartData] units). When
  /// provided, bars are colored by Z-score (`anomaly / standardDeviation`)
  /// so coloring is statistically meaningful and consistent across periods.
  final double? standardDeviation;

  const TemperatureBarChart({
    super.key,
    required this.chartData,
    this.averageTemperature,
    this.trendSlope,
    this.isLoading = false,
    this.height = 600,
    this.isFahrenheit = false,
    this.needsConversion = true,
    this.showTemperatureAxis = true,
    this.standardDeviation,
  });

  @override
  Widget build(BuildContext context) {
    final presentation = buildTemperatureChartPresentation(
      context: context,
      chartData: chartData,
      averageTemperature: averageTemperature,
      isFahrenheit: isFahrenheit,
      needsConversion: needsConversion,
      standardDeviation: standardDeviation,
    );

    if (presentation == null) {
      return SizedBox(
        height: height,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: kGreyLabelColour,
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Loading temperature data...',
              style:
                  TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth >= kTabletBreakpointWidth;
          final chartWidth = computeTemperatureChartWidth(context);

          final chart = SfCartesianChart(
            key: ValueKey('${isFahrenheit}_$showTemperatureAxis'),
            isTransposed: true,
            margin: const EdgeInsets.only(
              left: kChartHorizontalMargin,
              right: kChartRightMargin,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: Colors.black87,
              format: 'point.x: point.y${presentation.unitLabel}',
              canShowMarker: false,
              header: '',
              textStyle: const TextStyle(fontSize: kFontSizeBody),
              builder: (data, point, series, pointIndex, seriesIndex) {
                final d = data as TemperatureChartData;
                final displayTemp = presentation.shouldConvert
                    ? celsiusToFahrenheit(d.temperature)
                    : d.temperature;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${d.year}: ${displayTemp.toStringAsFixed(1)}${presentation.unitLabel}',
                    style: const TextStyle(
                        color: Colors.white, fontSize: kFontSizeBody - 4),
                  ),
                );
              },
            ),
            series: _buildSeries(
              presentation.yAxisMin,
              presentation.styledChartData,
              averageTemperature,
              trendSlope,
            ),
            primaryXAxis: NumericAxis(
              labelStyle: const TextStyle(
                fontSize: kFontSizeAxisLabel,
                color: kGreyLabelColour,
                fontFamilyFallback: kChartAxisFontFamilyFallback,
              ),
              majorGridLines: MajorGridLines(
                  width: 0.5, color: kAxisGridColour.withValues(alpha: 0.3)),
              labelIntersectAction: AxisLabelIntersectAction.hide,
              minimum: kChartStartYear.toDouble(),
              maximum: DateTime.now().year.toDouble(),
              interval: 5,
              labelFormat: '{value}',
              plotOffset: 20,
              axisLine: const AxisLine(width: 1, color: kAxisLabelColour),
            ),
            primaryYAxis: NumericAxis(
              opposedPosition: true,
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                return ChartAxisLabel(
                  presentation.formatAxisLabel(details.value.toDouble()),
                  details.textStyle,
                );
              },
              minimum: presentation.yAxisMin,
              maximum: presentation.yAxisMax,
              majorGridLines: MajorGridLines(
                  width: 0.5, color: kAxisGridColour.withValues(alpha: 0.3)),
              labelStyle: TextStyle(
                fontSize: showTemperatureAxis ? kFontSizeAxisLabel : 1,
                color:
                    showTemperatureAxis ? kGreyLabelColour : Colors.transparent,
                fontFamilyFallback: kChartAxisFontFamilyFallback,
              ),
              plotOffset: 0,
              interval: presentation.yAxisInterval,
              labelPosition: ChartDataLabelPosition.outside,
              majorTickLines: MajorTickLines(
                size: showTemperatureAxis ? 4 : 0,
                width: showTemperatureAxis ? 1 : 0,
                color: kAxisLabelColour,
              ),
              axisLine: AxisLine(
                width: showTemperatureAxis ? 1 : 0,
                color: kAxisLabelColour,
              ),
            ),
            plotAreaBorderWidth: 0,
            enableAxisAnimation: false,
          );

          return isTablet
              ? SizedBox(height: height, width: chartWidth, child: chart)
              : Center(
                  child:
                      SizedBox(height: height, width: chartWidth, child: chart),
                );
        },
      ),
    );
  }

  List<CartesianSeries<TemperatureChartData, int>> _buildSeries(
    double baseline,
    List<TemperatureChartData> data,
    double? avg,
    double? slope,
  ) {
    return [
      RangeColumnSeries<TemperatureChartData, int>(
        onCreateRenderer: (ChartSeries<TemperatureChartData, int> series) {
          return _TemperatureBarSeriesRenderer();
        },
        dataSource: data,
        xValueMapper: (TemperatureChartData data, _) =>
            int.tryParse(data.year) ?? 0,
        lowValueMapper: (TemperatureChartData data, _) => baseline,
        highValueMapper: (TemperatureChartData data, _) => data.temperature,
        pointColorMapper: (TemperatureChartData data, _) =>
            data.barFillColor ?? kBarNeutralColour,
        width: 0.8,
        animationDuration: 0,
        name: 'Temperature',
        enableTooltip: true,
        spacing: 0.1,
        borderColor: Colors.transparent,
        borderWidth: 2,
        borderRadius: const BorderRadius.horizontal(
          right: Radius.circular(4),
        ),
      ),
      if (avg != null && !isLoading)
        LineSeries<TemperatureChartData, int>(
          dataSource: generateAverageData(data, avg),
          xValueMapper: (TemperatureChartData data, _) =>
              int.tryParse(data.year) ?? 0,
          yValueMapper: (TemperatureChartData data, _) => data.temperature,
          color: kAverageColour,
          width: 2,
          dashArray: const <double>[4, 4],
          animationDuration: 0,
          name: 'Average Temperature',
          markerSettings: const MarkerSettings(isVisible: false),
          enableTooltip: false,
        ),
      if (slope != null && !isLoading)
        LineSeries<TemperatureChartData, int>(
          dataSource: generateTrendData(data, slope),
          xValueMapper: (TemperatureChartData data, _) =>
              int.tryParse(data.year) ?? 0,
          yValueMapper: (TemperatureChartData data, _) => data.temperature,
          color: kTrendColour,
          width: 2,
          animationDuration: 0,
          name: 'Trend',
          markerSettings: const MarkerSettings(isVisible: false),
          enableTooltip: false,
        ),
    ];
  }
}

class _TemperatureBarSeriesRenderer
    extends RangeColumnSeriesRenderer<TemperatureChartData, int> {
  @override
  RangeColumnSegment<TemperatureChartData, int> createSegment() {
    return _TemperatureBarSegment();
  }
}

class _TemperatureBarSegment
    extends RangeColumnSegment<TemperatureChartData, int> {
  @override
  Paint getStrokePaint() {
    final data = series.dataSource![currentSegmentIndex];
    return Paint()
      ..color = data.barBorderColor ?? data.barFillColor ?? Colors.transparent
      ..strokeWidth = series.borderWidth
      ..style = PaintingStyle.stroke
      ..isAntiAlias = true;
  }
}

/// Generate trend line data points from a slope (°C per decade).
List<TemperatureChartData> generateTrendData(
  List<TemperatureChartData> chartData,
  double slope,
) {
  if (chartData.isEmpty) return [];

  final dataWithValues = chartData.where((d) => d.hasData).toList();
  if (dataWithValues.isEmpty) return [];

  final yearsWithData = dataWithValues
      .map((d) => int.tryParse(d.year) ?? 0)
      .where((y) => y > 0)
      .toList();
  if (yearsWithData.isEmpty) return [];

  yearsWithData.sort();
  final middleYear = yearsWithData[yearsWithData.length ~/ 2];

  final tempsWithData = dataWithValues.map((d) => d.temperature).toList();
  final middleTemp =
      tempsWithData.reduce((a, b) => a + b) / tempsWithData.length;

  final currentYear = DateTime.now().year;
  final extendedYear = currentYear + 5;
  return [
    TemperatureChartData(
      year: kChartStartYear.toString(),
      temperature: middleTemp + (slope * (kChartStartYear - middleYear) / 10),
      isCurrentYear: false,
      hasData: true,
    ),
    TemperatureChartData(
      year: extendedYear.toString(),
      temperature: middleTemp + (slope * (extendedYear - middleYear) / 10),
      isCurrentYear: false,
      hasData: true,
    ),
  ];
}

/// Generate a horizontal average line spanning the full chart axis range.
List<TemperatureChartData> generateAverageData(
  List<TemperatureChartData> chartData,
  double averageTemp,
) {
  if (chartData.isEmpty || !chartData.any((d) => d.hasData)) return [];

  final extendedYear = DateTime.now().year + 5;
  return [
    TemperatureChartData(
      year: kChartStartYear.toString(),
      temperature: averageTemp,
      isCurrentYear: false,
      hasData: true,
    ),
    TemperatureChartData(
      year: extendedYear.toString(),
      temperature: averageTemp,
      isCurrentYear: false,
      hasData: true,
    ),
  ];
}
