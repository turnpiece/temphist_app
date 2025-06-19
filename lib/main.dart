import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'services/temperature_service.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Temperature Trends',
      home: TemperatureScreen(),
    );
  }
}

class TemperatureScreen extends StatefulWidget {
  @override
  _TemperatureScreenState createState() => _TemperatureScreenState();
}

class _TemperatureScreenState extends State<TemperatureScreen> {
  late Future<Map<String, dynamic>> futureChartData;

  @override
  void initState() {
    super.initState();
    futureChartData = _loadChartData();
  }

  Future<Map<String, dynamic>> _loadChartData() async {
    final now = DateTime.now();
    final useYesterday = now.hour < 1;
    final dateToUse = useYesterday ? now.subtract(Duration(days: 1)) : now;
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateToUse);

    final service = TemperatureService();
    final city = 'London';
    final currentYear = dateToUse.year;

    List<TemperatureChartData> chartData = [];
    double? averageTemperature;
    double? trendSlope;
    String? summaryText;
    int startYear = currentYear - 50;
    int endYear = currentYear;

    // Helper to fetch year-by-year data
    Future<void> fetchYearlyData(int start, int end) async {
      for (int year = start; year <= end; year++) {
        final dateForYear = '$year-${formattedDate.substring(5)}';
        try {
          final tempData = await service.fetchTemperature(city, dateForYear);
          chartData.add(TemperatureChartData(
            year: year.toString(),
            temperature: tempData.temperature ?? tempData.average?.temperature ?? 0.0,
            isCurrentYear: year == currentYear,
          ));
        } catch (_) {}
      }
    }

    // Try main /data/ endpoint first
    try {
      final tempData = await service.fetchCompleteData(city, '$currentYear-${formattedDate.substring(5)}');
      averageTemperature = tempData.average?.temperature;
      trendSlope = tempData.trend?.slope;
      summaryText = tempData.summary;

      if (tempData.series?.data.isNotEmpty == true) {
        final seriesData = tempData.series!.data;
        for (final dataPoint in seriesData) {
          chartData.add(TemperatureChartData(
            year: dataPoint.x.toString(),
            temperature: dataPoint.y,
            isCurrentYear: dataPoint.x == currentYear,
          ));
        }
        if (tempData.average?.yearRange != null) {
          startYear = tempData.average!.yearRange.start;
          endYear = tempData.average!.yearRange.end;
        }
        return {
          'chartData': chartData,
          'averageTemperature': averageTemperature,
          'trendSlope': trendSlope,
          'summary': summaryText,
          'displayDate': _formatDayMonth(dateToUse),
          'city': city,
        };
      } else {
        if (tempData.average?.yearRange != null) {
          startYear = tempData.average!.yearRange.start;
          endYear = tempData.average!.yearRange.end;
        }
        await fetchYearlyData(startYear, endYear);
        return {
          'chartData': chartData,
          'averageTemperature': averageTemperature,
          'trendSlope': trendSlope,
          'summary': summaryText,
          'displayDate': _formatDayMonth(dateToUse),
          'city': city,
        };
      }
    } catch (_) {
      // Fallback: try /average/, /trend/, /summary/ endpoints
      try {
        final averageData = await service.fetchAverageData(city, '$currentYear-${formattedDate.substring(5)}');
        averageTemperature = averageData['average']?.toDouble();
        if (averageData['year_range'] != null) {
          startYear = averageData['year_range']['start'];
          endYear = averageData['year_range']['end'];
        }
        try {
          final trendData = await service.fetchTrendData(city, '$currentYear-${formattedDate.substring(5)}');
          trendSlope = trendData['slope']?.toDouble();
        } catch (_) {}
        try {
          final summaryData = await service.fetchSummaryData(city, '$currentYear-${formattedDate.substring(5)}');
          summaryText = summaryData['summary'] as String?;
        } catch (_) {}
        await fetchYearlyData(startYear, endYear);
        return {
          'chartData': chartData,
          'averageTemperature': averageTemperature,
          'trendSlope': trendSlope,
          'summary': summaryText,
          'displayDate': _formatDayMonth(dateToUse),
          'city': city,
        };
      } catch (_) {
        // Final fallback: just fetch year-by-year
        await fetchYearlyData(startYear, endYear);
        return {
          'chartData': chartData,
          'averageTemperature': averageTemperature,
          'trendSlope': trendSlope,
          'summary': summaryText,
          'displayDate': _formatDayMonth(dateToUse),
          'city': city,
        };
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double chartHeight = 800;

    return Scaffold(
      backgroundColor: const Color(0xFF242456),
      appBar: AppBar(
        backgroundColor: const Color(0xFF242456),
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0, right: 12.0),
              child: SvgPicture.asset(
                'logo.svg',
                width: 40,
                height: 40,
              ),
            ),
            Text(
              'TempHist',
              style: TextStyle(
                color: Color(0xFFFF6B6B),
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureChartData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No temperature data available.'));
          }

          final data = snapshot.data!;
          final chartData = data['chartData'] as List<TemperatureChartData>;
          final averageTemperature = data['averageTemperature'] as double?;
          final trendSlope = data['trendSlope'] as double?;
          final summaryText = data['summary'] as String?;
          final displayDate = data['displayDate'] as String?;
          final city = data['city'] as String?;
          
          debugPrint('Average temperature for plot band: $averageTemperature°C');

          // Calculate minimum temperature for Y-axis
          final minTemp = chartData.map((data) => data.temperature).reduce((a, b) => a < b ? a : b);
          final yAxisMin = (minTemp - 2).floorToDouble(); // Start 2 degrees below minimum

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // Date and location above summary
                    if (displayDate != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              displayDate,
                              style: const TextStyle(color: Color(0xFFECECEC), fontSize: 16, fontWeight: FontWeight.w400),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                    if (city != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              city,
                              style: const TextStyle(color: Color(0xFFECECEC), fontSize: 16, fontWeight: FontWeight.w400),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                    if (summaryText != null && summaryText.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              summaryText,
                              style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                    SizedBox(
                      height: chartHeight,
                      child: SfCartesianChart(
                        margin: EdgeInsets.symmetric(horizontal: 40),
                        series: [
                          BarSeries<TemperatureChartData, String>(
                            dataSource: chartData,
                            xValueMapper: (TemperatureChartData data, int index) => data.year,
                            yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                            pointColorMapper: (TemperatureChartData data, int index) =>
                                data.isCurrentYear ? Colors.green : Colors.red,
                            width: 0.8,
                            name: 'Yearly Temperature',
                          ),
                          if (averageTemperature != null)
                            LineSeries<TemperatureChartData, String>(
                              dataSource: _generateAverageData(chartData, averageTemperature!),
                              xValueMapper: (TemperatureChartData data, int index) => data.year,
                              yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                              color: Colors.blue,
                              width: 2,
                              name: 'Average Temperature',
                              markerSettings: MarkerSettings(isVisible: false),
                            ),
                          if (trendSlope != null)
                            LineSeries<TemperatureChartData, String>(
                              dataSource: _generateTrendData(chartData, trendSlope!),
                              xValueMapper: (TemperatureChartData data, int index) => data.year,
                              yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                              color: Colors.yellow,
                              width: 2,
                              name: 'Trend',
                              markerSettings: MarkerSettings(isVisible: false),
                            ),
                        ],
                        primaryXAxis: CategoryAxis(
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[300]),
                          majorGridLines: MajorGridLines(width: 0),
                          labelIntersectAction: AxisLabelIntersectAction.hide,
                        ),
                        primaryYAxis: NumericAxis(
                          labelFormat: '{value}°C',
                          numberFormat: NumberFormat('0'),
                          minimum: yAxisMin,
                          majorGridLines: MajorGridLines(width: 0),
                          labelStyle: TextStyle(fontSize: 12, color: Colors.grey[300]),
                        ),
                        plotAreaBorderWidth: 0,
                      ),
                    ),
                    // Add average and trend info below the chart
                    if (averageTemperature != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Average: ${averageTemperature.toStringAsFixed(1)}°C',
                              style: TextStyle(color: Colors.blue, fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      ),
                    if (trendSlope != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'Trend: ${trendSlope > 0 ? 'rising' : 'falling'} at ${trendSlope.abs().toStringAsFixed(2)}°C/decade',
                              style: TextStyle(color: Colors.yellow[700], fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.left,
                            ),
                          ),
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
}

class TemperatureChartData {
  final String year;
  final double temperature;
  final bool isCurrentYear;

  TemperatureChartData({
    required this.year,
    required this.temperature,
    required this.isCurrentYear,
  });
}

List<TemperatureChartData> _generateTrendData(List<TemperatureChartData> chartData, double slope) {
  if (chartData.isEmpty) return [];
  
  // Find the middle year to use as reference point
  final years = chartData.map((data) => int.parse(data.year)).toList();
  years.sort();
  final middleYear = years[years.length ~/ 2];
  
  // Calculate the middle temperature (average of all temperatures)
  final middleTemp = chartData.map((data) => data.temperature).reduce((a, b) => a + b) / chartData.length;
  
  // Generate trend line points using only the actual years from chart data
  return chartData.map((data) {
    final year = int.parse(data.year);
    final yearsFromMiddle = year - middleYear;
    final trendTemp = middleTemp + (slope * yearsFromMiddle / 10); // Convert decade slope to yearly
    
    return TemperatureChartData(
      year: data.year,
      temperature: trendTemp,
      isCurrentYear: data.isCurrentYear,
    );
  }).toList();
}

List<TemperatureChartData> _generateAverageData(List<TemperatureChartData> chartData, double averageTemp) {
  if (chartData.isEmpty) return [];
  
  // Generate average line points using only the actual years from chart data
  return chartData.map((data) {
    return TemperatureChartData(
      year: data.year,
      temperature: averageTemp,
      isCurrentYear: data.isCurrentYear,
    );
  }).toList();
}

String _formatDayMonth(DateTime date) {
  final day = date.day;
  final month = DateFormat('MMMM').format(date);
  String suffix;
  if (day >= 11 && day <= 13) {
    suffix = 'th';
  } else {
    switch (day % 10) {
      case 1:
        suffix = 'st';
        break;
      case 2:
        suffix = 'nd';
        break;
      case 3:
        suffix = 'rd';
        break;
      default:
        suffix = 'th';
    }
  }
  return '$day$suffix $month';
}
