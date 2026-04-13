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

  TemperatureChartData({
    required this.year,
    required this.temperature,
    required this.isCurrentYear,
    this.hasData = true,
  });
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

  const TemperatureBarChart({
    super.key,
    required this.chartData,
    this.averageTemperature,
    this.trendSlope,
    this.isLoading = false,
    this.height = 600,
    this.isFahrenheit = false,
    this.needsConversion = true,
  });

  @override
  Widget build(BuildContext context) {
    // The chart always plots raw values (Celsius or pre-converted Fahrenheit
    // from the API) so that bar proportions stay visually identical regardless
    // of the selected unit.  Only axis labels and tooltips are converted for
    // display when the user selects a different unit.
    final shouldConvert = isFahrenheit && needsConversion;
    double convLabel(double v) => shouldConvert ? celsiusToFahrenheit(v) : v;
    final unitLabel = temperatureUnitLabel(isFahrenheit: isFahrenheit);

    final validData = chartData.where((d) => d.hasData).toList();
    if (validData.isEmpty) {
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
              style: TextStyle(color: kGreyLabelColour, fontSize: kFontSizeBody),
            ),
          ],
        ),
      );
    }

    // Calculate Y-axis range
    final minTemp = validData.map((d) => d.temperature).reduce((a, b) => a < b ? a : b);
    final maxTemp = validData.map((d) => d.temperature).reduce((a, b) => a > b ? a : b);

    double yAxisMin = (minTemp - 2).floorToDouble();
    double yAxisMax = (maxTemp + 2).ceilToDouble();

    final range = maxTemp - minTemp;
    if (range < 5) {
      final midPoint = (maxTemp + minTemp) / 2;
      yAxisMin = (midPoint - 2.5).floorToDouble();
      yAxisMax = (midPoint + 2.5).ceilToDouble();
    }

    return Padding(
      padding: EdgeInsets.zero,
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth >= kTabletBreakpointWidth;

          // On portrait phones, cap at 5 labels to avoid crowding.
          // Tablets and landscape views allow up to 7.
          final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
          final maxLabels = (!isTablet && isPortrait) ? 5 : 7;
          final maxIntervals = maxLabels - 1;

          // Choose a whole-number interval that stays within maxLabels.
          // The axis always uses raw (Celsius) values — labels are converted
          // for display — so these thresholds only need to work for Celsius ranges.
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
          } else {
            yAxisInterval = 10;
          }

          // Snap bounds to the interval so there are no lone ticks past the last step.
          yAxisMin = (yAxisMin / yAxisInterval).floor() * yAxisInterval;
          yAxisMax = (yAxisMax / yAxisInterval).ceil() * yAxisInterval;
          // Guarantee at least one full step of headroom on each side.
          if (yAxisMax <= maxTemp) yAxisMax += yAxisInterval;
          if (yAxisMin >= minTemp) yAxisMin -= yAxisInterval;

          final availableWidth = isTablet ? kTabletMaxContentWidth : screenWidth;
          final contentPadding = kScreenPadding + kContentHorizontalMargin;
          final chartWidth = availableWidth - kChartRightMargin - (contentPadding * 2);

          final chart = SfCartesianChart(
            key: ValueKey(isFahrenheit),
            isTransposed: true,
            margin: const EdgeInsets.only(
              left: kChartHorizontalMargin,
              right: kChartRightMargin,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: Colors.black87,
              format: 'point.x: point.y$unitLabel',
              canShowMarker: false,
              header: '',
              textStyle: const TextStyle(fontSize: kFontSizeBody),
              builder: (data, point, series, pointIndex, seriesIndex) {
                final d = data as TemperatureChartData;
                final displayTemp = convLabel(d.temperature);
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${d.year}: ${displayTemp.toStringAsFixed(isFahrenheit ? 0 : 1)}$unitLabel',
                    style: const TextStyle(
                        color: Colors.white, fontSize: kFontSizeBody - 4),
                  ),
                );
              },
            ),
            series: _buildSeries(yAxisMin, chartData, averageTemperature, trendSlope),
            primaryXAxis: NumericAxis(
              labelStyle: const TextStyle(fontSize: kFontSizeAxisLabel, color: kGreyLabelColour),
              majorGridLines: MajorGridLines(width: 0.5, color: kAxisGridColour.withValues(alpha: 0.3)),
              labelIntersectAction: AxisLabelIntersectAction.hide,
              minimum: kChartStartYear.toDouble(),
              maximum: DateTime.now().year.toDouble(),
              interval: 5,
              labelFormat: '{value}',
              plotOffset: 20,
              axisLine: const AxisLine(width: 1, color: kAxisLabelColour),
            ),
            primaryYAxis: NumericAxis(
              axisLabelFormatter: (AxisLabelRenderDetails details) {
                final raw = details.value.toDouble();
                final display = convLabel(raw);
                final text = '${display.toStringAsFixed(0)}$unitLabel';
                return ChartAxisLabel(text, details.textStyle);
              },
              minimum: yAxisMin,
              maximum: yAxisMax,
              majorGridLines: MajorGridLines(width: 0.5, color: kAxisGridColour.withValues(alpha: 0.3)),
              labelStyle: const TextStyle(fontSize: kFontSizeAxisLabel, color: kGreyLabelColour),
              plotOffset: 0,
              interval: yAxisInterval,
              labelPosition: ChartDataLabelPosition.outside,
              axisLine: const AxisLine(width: 1, color: kAxisLabelColour),
            ),
            plotAreaBorderWidth: 0,
            enableAxisAnimation: false,
          );

          return isTablet
              ? SizedBox(height: height, width: chartWidth, child: chart)
              : Center(
                  child: SizedBox(height: height, width: chartWidth, child: chart),
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
        dataSource: data,
        xValueMapper: (TemperatureChartData data, _) => int.tryParse(data.year) ?? 0,
        lowValueMapper: (TemperatureChartData data, _) => baseline,
        highValueMapper: (TemperatureChartData data, _) => data.temperature,
        pointColorMapper: (TemperatureChartData data, _) =>
            data.isCurrentYear ? kBarCurrentYearColour : kBarOtherYearColour,
        width: 0.8,
        animationDuration: 0,
        name: 'Temperature',
        enableTooltip: true,
        spacing: 0.1,
        borderRadius: BorderRadius.circular(2),
      ),
      if (avg != null && !isLoading)
        LineSeries<TemperatureChartData, int>(
          dataSource: generateAverageData(data, avg),
          xValueMapper: (TemperatureChartData data, _) => int.tryParse(data.year) ?? 0,
          yValueMapper: (TemperatureChartData data, _) => data.temperature,
          color: kAverageColour,
          width: 2,
          animationDuration: 0,
          name: 'Average Temperature',
          markerSettings: const MarkerSettings(isVisible: false),
          enableTooltip: false,
        ),
      if (slope != null && !isLoading)
        LineSeries<TemperatureChartData, int>(
          dataSource: generateTrendData(data, slope),
          xValueMapper: (TemperatureChartData data, _) => int.tryParse(data.year) ?? 0,
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
  final middleTemp = tempsWithData.reduce((a, b) => a + b) / tempsWithData.length;

  final minYear = yearsWithData.first;
  final maxYear = yearsWithData.last;

  final List<TemperatureChartData> trendData = [];
  final currentYear = DateTime.now().year;
  for (int year = minYear; year <= maxYear; year++) {
    final yearsFromMiddle = year - middleYear;
    final trendTemp = middleTemp + (slope * yearsFromMiddle / 10);
    trendData.add(TemperatureChartData(
      year: year.toString(),
      temperature: trendTemp,
      isCurrentYear: year == currentYear,
      hasData: true,
    ));
  }
  return trendData;
}

/// Generate a horizontal average line across the year range.
List<TemperatureChartData> generateAverageData(
  List<TemperatureChartData> chartData,
  double averageTemp,
) {
  if (chartData.isEmpty) return [];

  final yearsWithData = chartData
      .where((d) => d.hasData)
      .map((d) => int.tryParse(d.year) ?? 0)
      .where((y) => y > 0)
      .toList();
  if (yearsWithData.isEmpty) return [];

  yearsWithData.sort();
  final minYear = yearsWithData.first;
  final maxYear = yearsWithData.last;

  final List<TemperatureChartData> averageData = [];
  final currentYear = DateTime.now().year;
  for (int year = minYear; year <= maxYear; year++) {
    averageData.add(TemperatureChartData(
      year: year.toString(),
      temperature: averageTemp,
      isCurrentYear: year == currentYear,
      hasData: true,
    ));
  }
  return averageData;
}
