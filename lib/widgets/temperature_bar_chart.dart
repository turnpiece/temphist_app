import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../constants/app_constants.dart';

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

  const TemperatureBarChart({
    super.key,
    required this.chartData,
    this.averageTemperature,
    this.trendSlope,
    this.isLoading = false,
    this.height = 600,
  });

  @override
  Widget build(BuildContext context) {
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
          final isTablet = screenWidth >= 768;
          final availableWidth = isTablet ? 600.0 : screenWidth;
          final contentPadding = kScreenPadding + kContentHorizontalMargin;
          final chartWidth = availableWidth - kChartRightMargin - (contentPadding * 2);

          final chart = SfCartesianChart(
            isTransposed: true,
            margin: const EdgeInsets.only(
              left: kChartHorizontalMargin,
              right: kChartRightMargin,
            ),
            tooltipBehavior: TooltipBehavior(
              enable: true,
              color: Colors.black87,
              format: 'point.x: point.y°C',
              canShowMarker: false,
              header: '',
              textStyle: const TextStyle(fontSize: kFontSizeBody),
              builder: (data, point, series, pointIndex, seriesIndex) {
                final d = data as TemperatureChartData;
                return Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${d.year}: ${d.temperature.toStringAsFixed(1)}°C',
                    style: const TextStyle(
                        color: Colors.white, fontSize: kFontSizeBody - 4),
                  ),
                );
              },
            ),
            series: _buildSeries(yAxisMin),
            primaryXAxis: NumericAxis(
              labelStyle: const TextStyle(fontSize: kFontSizeAxisLabel, color: kGreyLabelColour),
              majorGridLines: MajorGridLines(width: 0.5, color: kAxisGridColour.withValues(alpha: 0.3)),
              labelIntersectAction: AxisLabelIntersectAction.hide,
              minimum: 1975.0,
              maximum: DateTime.now().year.toDouble(),
              interval: 5,
              labelFormat: '{value}',
              plotOffset: 20,
              axisLine: const AxisLine(width: 1, color: kAxisLabelColour),
            ),
            primaryYAxis: NumericAxis(
              labelFormat: '{value}°C',
              numberFormat: NumberFormat('0'),
              minimum: yAxisMin,
              maximum: yAxisMax,
              majorGridLines: MajorGridLines(width: 0.5, color: kAxisGridColour.withValues(alpha: 0.3)),
              labelStyle: const TextStyle(fontSize: kFontSizeAxisLabel, color: kGreyLabelColour),
              plotOffset: 0,
              desiredIntervals: 5,
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

  List<CartesianSeries<TemperatureChartData, int>> _buildSeries(double baseline) {
    return [
      RangeColumnSeries<TemperatureChartData, int>(
        dataSource: chartData,
        xValueMapper: (TemperatureChartData data, _) => int.parse(data.year),
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
      if (averageTemperature != null && !isLoading)
        LineSeries<TemperatureChartData, int>(
          dataSource: generateAverageData(chartData, averageTemperature!),
          xValueMapper: (TemperatureChartData data, _) => int.parse(data.year),
          yValueMapper: (TemperatureChartData data, _) => data.temperature,
          color: kAverageColour,
          width: 2,
          animationDuration: 0,
          name: 'Average Temperature',
          markerSettings: const MarkerSettings(isVisible: false),
          enableTooltip: false,
        ),
      if (trendSlope != null && !isLoading)
        LineSeries<TemperatureChartData, int>(
          dataSource: generateTrendData(chartData, trendSlope!),
          xValueMapper: (TemperatureChartData data, _) => int.parse(data.year),
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

  final yearsWithData = chartData
      .where((d) => d.hasData)
      .map((d) => int.parse(d.year))
      .toList();
  if (yearsWithData.isEmpty) return [];

  yearsWithData.sort();
  final middleYear = yearsWithData[yearsWithData.length ~/ 2];

  final tempsWithData =
      chartData.where((d) => d.hasData).map((d) => d.temperature).toList();
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
      .map((d) => int.parse(d.year))
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
