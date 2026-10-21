import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show OrdinalSortKey;
import 'package:syncfusion_flutter_charts/charts.dart';

import '../constants/app_constants.dart';
import '../utils/temperature_utils.dart';
import 'gradient_spinner.dart';

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

  String formatAxisLabel(double rawValue) {
    final display = shouldConvert ? celsiusToFahrenheit(rawValue) : rawValue;
    return '${display.toStringAsFixed(0)}$unitLabel';
  }
}

/// Decimal places for a temperature or anomaly shown to the user.
///
/// Fahrenheit values and daily records come from 1dp source data, so the
/// second digit would be noise; weekly/monthly/yearly Celsius averages keep two.
int chartTemperatureDecimals(
  TemperatureChartPresentation presentation, {
  required bool isDailyPeriod,
}) {
  final isFahrenheit = presentation.unitLabel == '°F';
  return (isFahrenheit || isDailyPeriod) ? 1 : 2;
}

/// "14.2°C" for a data point, converted and rounded the way the chart shows it.
String formatChartTemperature(
  TemperatureChartData d,
  TemperatureChartPresentation presentation, {
  required bool isDailyPeriod,
}) {
  final display = presentation.shouldConvert
      ? celsiusToFahrenheit(d.temperature)
      : d.temperature;
  final decimals =
      chartTemperatureDecimals(presentation, isDailyPeriod: isDailyPeriod);
  return '${display.toStringAsFixed(decimals)}${presentation.unitLabel}';
}

/// "+1.1°C above average" for a data point, or null when it has no anomaly.
///
/// [spoken] drops the +/− sign (a screen reader would read it out loud on top
/// of "above"/"below") and says "same as average" instead of "at the average".
String? formatChartAnomaly(
  TemperatureChartData d,
  TemperatureChartPresentation presentation, {
  required bool isDailyPeriod,
  bool spoken = false,
}) {
  final anomaly = d.anomaly;
  if (anomaly == null) return null;

  final decimals =
      chartTemperatureDecimals(presentation, isDailyPeriod: isDailyPeriod);
  final rawAnomaly = presentation.shouldConvert ? anomaly * 9 / 5 : anomaly;
  final displayAnomaly = double.parse(rawAnomaly.toStringAsFixed(decimals));
  final magnitude =
      '${displayAnomaly.abs().toStringAsFixed(decimals)}${presentation.unitLabel}';

  if (displayAnomaly > 0) {
    return '${spoken ? '' : '+'}$magnitude above average';
  }
  if (displayAnomaly < 0) {
    return '${spoken ? '' : '−'}$magnitude below average';
  }
  return spoken ? 'same as average' : '$magnitude at the average';
}

/// One spoken sentence per bar, e.g. "2019: 14.8°C, 1.9°C above average".
String describeChartPoint(
  TemperatureChartData d,
  TemperatureChartPresentation presentation, {
  required bool isDailyPeriod,
}) {
  final temp = formatChartTemperature(d, presentation,
      isDailyPeriod: isDailyPeriod);
  final anomaly = formatChartAnomaly(d, presentation,
      isDailyPeriod: isDailyPeriod, spoken: true);
  return anomaly == null ? '${d.year}: $temp' : '${d.year}: $temp, $anomaly';
}

/// Summary read out for the whole chart, which a screen-reader user cannot
/// otherwise get at: the per-year values only appear in a tap-only tooltip.
///
/// e.g. "Bar chart of temperature by year for the past week, 1976 to 2026.
/// Latest, 2026: 14.2°C, 1.1°C above average. Warmest, 2022: 16.0°C.
/// Coolest, 1986: 9.8°C. Average 12.9°C. Trend: Rising at 0.40°C/decade."
String temperatureChartSemanticsLabel({
  required TemperatureChartPresentation presentation,
  required bool isDailyPeriod,
  String? periodDescription,
  double? averageTemperature,
  double? trendSlope,
}) {
  final points = presentation.validData
      .where((d) => int.tryParse(d.year) != null)
      .toList()
    ..sort((a, b) => int.parse(a.year).compareTo(int.parse(b.year)));
  if (points.isEmpty) return 'Temperature chart, no data';

  final latest = points.last;
  final warmest = points.reduce((a, b) => b.temperature > a.temperature ? b : a);
  final coolest = points.reduce((a, b) => b.temperature < a.temperature ? b : a);

  String temp(TemperatureChartData d) =>
      formatChartTemperature(d, presentation, isDailyPeriod: isDailyPeriod);

  final forPeriod = periodDescription == null ? '' : ' for $periodDescription';
  final isFahrenheit = presentation.unitLabel == '°F';

  final parts = <String>[
    'Bar chart of temperature by year$forPeriod, ${points.first.year} to ${latest.year}',
    'Latest, ${describeChartPoint(latest, presentation, isDailyPeriod: isDailyPeriod)}',
    if (points.length > 1) ...[
      'Warmest, ${warmest.year}: ${temp(warmest)}',
      'Coolest, ${coolest.year}: ${temp(coolest)}',
    ],
    if (averageTemperature != null)
      'Average ${formatTemperature(averageTemperature, isFahrenheit: isFahrenheit, convert: presentation.shouldConvert)}',
    if (trendSlope != null)
      'Trend: ${formatTrendValue(trendSlope, isFahrenheit: isFahrenheit, convert: presentation.shouldConvert)}',
  ];
  return '${parts.join('. ')}.';
}

/// Grows each bar's rect into a full-width row so it is a usable touch target
/// for screen-reader exploration: a bar can be only a few points tall and as
/// short as the data. [bars] must be sorted top to bottom; adjacent rows meet
/// halfway across the gap between their bars.
List<Rect> expandBarRowRects(
  List<Rect> bars, {
  required double left,
  required double right,
}) {
  return [
    for (var i = 0; i < bars.length; i++)
      Rect.fromLTRB(
        left,
        i == 0 ? bars[i].top : (bars[i - 1].bottom + bars[i].top) / 2,
        right,
        i == bars.length - 1
            ? bars[i].bottom
            : (bars[i].bottom + bars[i + 1].top) / 2,
      ),
  ];
}

const double kTemperatureChartTopAxisHeight = 22.0;
const double kChartXAxisPlotOffsetStart = 8.0;
const double kChartXAxisPlotOffsetEnd = 8.0;

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

    // Decoration for screen readers: the chart below speaks every value.
    return ExcludeSemantics(
      child: Center(
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
              plotOffsetStart: kChartXAxisPlotOffsetStart,
              plotOffsetEnd: kChartXAxisPlotOffsetEnd,
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
      ),
    );
  }
}

/// Neutral-band threshold for the fallback anomaly normalisation path (no SD).
/// Expressed as a fraction of the largest observed warm/cool anomaly in the
/// series; values below this fraction are rendered as neutral grey.
const double _kFallbackNeutralBand = 0.12;

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
    double maxWarmAnomaly = 0;
    double maxCoolAnomaly = 0;
    for (final d in validValues) {
      final a = d.anomaly;
      if (a == null) continue;
      if (a > maxWarmAnomaly) maxWarmAnomaly = a;
      if (a < 0 && a.abs() > maxCoolAnomaly) maxCoolAnomaly = a.abs();
    }
    return data
        .map(
          (d) {
            final a = d.anomaly;
            final fill = a == null
                ? kBarNeutralColour
                : _barColorForAnomaly(a, maxWarmAnomaly, maxCoolAnomaly);
            return TemperatureChartData(
              year: d.year,
              temperature: d.temperature,
              isCurrentYear: d.isCurrentYear,
              hasData: d.hasData,
              anomaly: d.anomaly,
              barFillColor: fill,
              barBorderColor: fill,
            );
          },
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
    final fillColor = useZScore
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
  double normalized;
  if (anomaly > 0) {
    normalized = maxWarmAnomaly == 0 ? 0 : anomaly / maxWarmAnomaly;
  } else if (anomaly < 0) {
    normalized = maxCoolAnomaly == 0 ? 0 : anomaly.abs() / maxCoolAnomaly;
  } else {
    normalized = 0;
  }

  if (normalized <= _kFallbackNeutralBand) {
    return kBarNeutralColour;
  }

  final blend = ((normalized - _kFallbackNeutralBand) /
          (1 - _kFallbackNeutralBand))
      .clamp(0.0, 1.0);
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
class TemperatureBarChart extends StatefulWidget {
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

  /// Pre-built presentation from a parent widget. When provided, skips the
  /// call to [buildTemperatureChartPresentation] so the Z-score styling pass
  /// only runs once per build.
  final TemperatureChartPresentation? presentation;

  /// When true, tooltip temperatures and anomalies render at one decimal place
  /// instead of two. Daily records come from 1dp source data, so the second
  /// digit is noise; weekly/monthly/yearly are averages where it's meaningful.
  final bool isDailyPeriod;

  /// Spoken in the chart's screen-reader summary, e.g. "the past week" or
  /// "this day". Omitted from the summary when null.
  final String? periodDescription;

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
    this.presentation,
    this.isDailyPeriod = false,
    this.periodDescription,
  });

  @override
  State<TemperatureBarChart> createState() => _TemperatureBarChartState();
}

class _TemperatureBarChartState extends State<TemperatureBarChart> {
  late final TooltipBehavior _tooltipBehavior;

  // Updated during build so the tooltip builder always sees current data.
  TemperatureChartPresentation? _presentation;

  final GlobalKey _chartBoxKey = GlobalKey();

  /// Where each bar was last painted, keyed by data index and expressed in the
  /// chart box's coordinates. The chart gives us no semantics of its own, so
  /// these rects position the per-bar `Semantics` nodes laid over it.
  Map<int, Rect> _barRects = const {};

  /// Called from the series renderer's paint with the bars' rects in its own
  /// coordinates. Sets state only when something moved, and only after the
  /// frame, because this runs mid-paint.
  void _reportBarRects(RenderBox series, Map<int, Rect> local) {
    final box = _chartBoxKey.currentContext?.findRenderObject();
    if (box is! RenderBox || !box.attached || !series.attached) return;

    final transform = series.getTransformTo(box);
    final mapped = {
      for (final e in local.entries)
        e.key: MatrixUtils.transformRect(transform, e.value),
    };
    if (mapEquals(mapped, _barRects)) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _barRects = mapped);
    });
  }

  @override
  void initState() {
    super.initState();
    _tooltipBehavior = TooltipBehavior(
      enable: true,
      color: Colors.black87,
      canShowMarker: false,
      header: '',
      duration: 6000,
      textStyle: const TextStyle(fontSize: kFontSizeBody),
      builder: (data, point, series, pointIndex, seriesIndex) {
        final presentation = _presentation;
        if (presentation == null) return const SizedBox.shrink();

        final d = data as TemperatureChartData;

        Widget? anomalyWidget;
        final anomalyText = formatChartAnomaly(d, presentation,
            isDailyPeriod: widget.isDailyPeriod);
        if (anomalyText != null) {
          final baseColor = d.barFillColor ?? Colors.white;
          final hsl = HSLColor.fromColor(baseColor);
          final anomalyColor =
              hsl.withLightness(hsl.lightness.clamp(0.8, 1.0)).toColor();
          anomalyWidget = Text(
            anomalyText,
            style: TextStyle(
              color: anomalyColor,
              fontSize: kFontSizeBody - 2,
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: const BorderRadius.all(Radius.circular(4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                d.year,
                style: const TextStyle(
                    color: Colors.white, fontSize: kFontSizeBody - 2),
              ),
              Text(
                formatChartTemperature(d, presentation,
                    isDailyPeriod: widget.isDailyPeriod),
                style: const TextStyle(
                    color: Colors.white, fontSize: kFontSizeBody - 2),
              ),
              if (anomalyWidget != null) anomalyWidget,
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _presentation = widget.presentation ??
        buildTemperatureChartPresentation(
          context: context,
          chartData: widget.chartData,
          averageTemperature: widget.averageTemperature,
          isFahrenheit: widget.isFahrenheit,
          needsConversion: widget.needsConversion,
          standardDeviation: widget.standardDeviation,
        );

    final presentation = _presentation;

    if (presentation == null) {
      return SizedBox(
        height: widget.height,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GradientSpinner.data(),
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
          final chartWidth = computeTemperatureChartWidth(context);

          final chart = SfCartesianChart(
            key: ValueKey('${widget.isFahrenheit}_${widget.showTemperatureAxis}'),
            isTransposed: true,
            margin: const EdgeInsets.only(
              left: kChartHorizontalMargin,
              right: kChartRightMargin,
            ),
            tooltipBehavior: _tooltipBehavior,
            onChartTouchInteractionDown: (_) {
              _tooltipBehavior.hide();
            },
            series: _buildSeries(
              presentation.yAxisMin,
              presentation.styledChartData,
              widget.averageTemperature,
              widget.trendSlope,
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
              plotOffsetStart: kChartXAxisPlotOffsetStart,
              plotOffsetEnd: kChartXAxisPlotOffsetEnd,
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
                fontSize: widget.showTemperatureAxis ? kFontSizeAxisLabel : 1,
                color: widget.showTemperatureAxis
                    ? kGreyLabelColour
                    : Colors.transparent,
                fontFamilyFallback: kChartAxisFontFamilyFallback,
              ),
              plotOffset: 0,
              interval: presentation.yAxisInterval,
              labelPosition: ChartDataLabelPosition.outside,
              majorTickLines: MajorTickLines(
                size: 4,
                width: 1,
                color: widget.showTemperatureAxis
                    ? kAxisLabelColour
                    : Colors.transparent,
              ),
              axisLine: AxisLine(
                width: 1,
                color: widget.showTemperatureAxis
                    ? kAxisLabelColour
                    : Colors.transparent,
              ),
            ),
            plotAreaBorderWidth: 0,
            enableAxisAnimation: false,
          );

          final summary = temperatureChartSemanticsLabel(
            presentation: presentation,
            isDailyPeriod: widget.isDailyPeriod,
            periodDescription: widget.periodDescription,
            averageTemperature: widget.averageTemperature,
            trendSlope: widget.trendSlope,
          );

          // Rows are ordered top to bottom, which is the order a sighted
          // reader would take them in; the summary always comes first.
          final bars = _barRects.entries
              .where((e) =>
                  e.key < presentation.styledChartData.length &&
                  presentation.styledChartData[e.key].hasData)
              .toList()
            ..sort((a, b) => a.value.top.compareTo(b.value.top));
          final rows = expandBarRowRects(
            [for (final b in bars) b.value],
            left: 0,
            right: chartWidth,
          );

          return Center(
            child: SizedBox(
              key: _chartBoxKey,
              height: widget.height,
              width: chartWidth,
              // Not a leaf: the summary and every bar are siblings so each
              // one is separately focusable.
              child: Semantics(
                container: true,
                explicitChildNodes: true,
                child: Stack(
                  children: [
                    // The chart's own nodes are just unlabelled paint. The
                    // summary sits underneath and covers the whole chart so a
                    // touch that misses every bar still finds it.
                    Semantics(
                      label: summary,
                      image: true,
                      container: true,
                      sortKey: const OrdinalSortKey(0),
                      child: ExcludeSemantics(child: chart),
                    ),
                    for (var i = 0; i < bars.length; i++)
                      Positioned.fromRect(
                        rect: rows[i],
                        child: Semantics(
                          label: describeChartPoint(
                            presentation.styledChartData[bars[i].key],
                            presentation,
                            isDailyPeriod: widget.isDailyPeriod,
                          ),
                          container: true,
                          sortKey: OrdinalSortKey(i + 1.0),
                          child: const SizedBox.expand(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
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
          return _TemperatureBarSeriesRenderer(_reportBarRects);
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
      if (avg != null && !widget.isLoading)
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
      if (slope != null && !widget.isLoading)
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
  _TemperatureBarSeriesRenderer(this.onBarRects);

  final void Function(RenderBox series, Map<int, Rect> rects) onBarRects;

  @override
  void onPaint(PaintingContext context, Offset offset) {
    super.onPaint(context, offset);

    final rects = <int, Rect>{};
    for (final segment in segments) {
      if (segment is RangeColumnSegment<TemperatureChartData, int>) {
        final rect = segment.segmentRect;
        if (rect != null) rects[segment.currentSegmentIndex] = rect.outerRect;
      }
    }
    onBarRects(this, rects);
  }

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
