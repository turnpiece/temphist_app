import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

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

    final List<TemperatureChartData> chartData = [];
    double? averageTemperature;
    double? trendSlope;

    // Get the complete data from the API
    try {
      final tempData = await service.fetchCompleteData(city, '$currentYear-${formattedDate.substring(5)}');
      
      // Get the average temperature from the API response
      averageTemperature = tempData.average?.temperature;
      debugPrint('Average temperature from API: $averageTemperature°C');
      
      // Get the trend slope from the API response
      trendSlope = tempData.trend?.slope;
      debugPrint('Trend slope from API: $trendSlope°C/decade');
      
      // Use the series data if available
      if (tempData.series?.data.isNotEmpty == true) {
        final seriesData = tempData.series!.data;
        final currentYear = dateToUse.year;
        
        for (final dataPoint in seriesData) {
          chartData.add(TemperatureChartData(
            year: dataPoint.x.toString(),
            temperature: dataPoint.y,
            isCurrentYear: dataPoint.x == currentYear,
          ));
        }
        
        debugPrint('Loaded ${chartData.length} years from series data');
      } else {
        // Fallback to individual API calls if series data not available
        debugPrint('No series data available, falling back to individual calls');
        
        // Get year range from the API response
        int startYear = currentYear - 50; // fallback
        int endYear = currentYear;
        
        if (tempData.average?.yearRange != null) {
          startYear = tempData.average!.yearRange.start;
          endYear = tempData.average!.yearRange.end;
        }
        
        debugPrint('Year range from API: $startYear to $endYear');

        // Fetch data for all years in the range
        for (int year = startYear; year <= endYear; year++) {
          final dateForYear = '$year-${formattedDate.substring(5)}';
          try {
            final yearTempData = await service.fetchTemperature(city, dateForYear);
            chartData.add(TemperatureChartData(
              year: year.toString(),
              temperature: yearTempData.temperature ?? yearTempData.average?.temperature ?? 0.0,
              isCurrentYear: year == currentYear,
            ));
            debugPrint('Successfully fetched data for $year: ${yearTempData.temperature ?? yearTempData.average?.temperature ?? 0.0}°C');
          } catch (e) {
            debugPrint('Failed to fetch data for $year: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to get complete data from API: $e');
      
      // Try to get average data as fallback
      try {
        final averageData = await service.fetchAverageData(city, '$currentYear-${formattedDate.substring(5)}');
        averageTemperature = averageData['average']?.toDouble();
        debugPrint('Average temperature from average endpoint: $averageTemperature°C');
        
        // Try to get trend data as well
        try {
          final trendData = await service.fetchTrendData(city, '$currentYear-${formattedDate.substring(5)}');
          trendSlope = trendData['slope']?.toDouble();
          debugPrint('Trend slope from trend endpoint: $trendSlope°C/decade');
        } catch (trendError) {
          debugPrint('Failed to get trend data: $trendError');
        }
        
        // Get year range from average data
        int startYear = currentYear - 50; // fallback
        int endYear = currentYear;
        
        if (averageData['year_range'] != null) {
          startYear = averageData['year_range']['start'];
          endYear = averageData['year_range']['end'];
        }
        
        debugPrint('Year range from average API: $startYear to $endYear');
        
        // Fetch individual year data
        for (int year = startYear; year <= endYear; year++) {
          final dateForYear = '$year-${formattedDate.substring(5)}';
          try {
            final tempData = await service.fetchTemperature(city, dateForYear);
            chartData.add(TemperatureChartData(
              year: year.toString(),
              temperature: tempData.temperature ?? tempData.average?.temperature ?? 0.0,
              isCurrentYear: year == currentYear,
            ));
            debugPrint('Successfully fetched data for $year: ${tempData.temperature ?? tempData.average?.temperature ?? 0.0}°C');
          } catch (e) {
            debugPrint('Failed to fetch data for $year: $e');
          }
        }
      } catch (averageError) {
        debugPrint('Failed to get average data: $averageError');
        // Final fallback to current approach
        for (int year = currentYear - 50; year <= currentYear; year++) {
          final dateForYear = '$year-${formattedDate.substring(5)}';
          try {
            final tempData = await service.fetchTemperature(city, dateForYear);
            chartData.add(TemperatureChartData(
              year: year.toString(),
              temperature: tempData.temperature ?? tempData.average?.temperature ?? 0.0,
              isCurrentYear: year == currentYear,
            ));
            debugPrint('Fallback: Successfully fetched data for $year: ${tempData.temperature ?? tempData.average?.temperature ?? 0.0}°C');
          } catch (e) {
            debugPrint('Failed to fetch data for $year: $e');
          }
        }
      }
    }

    return {
      'chartData': chartData,
      'averageTemperature': averageTemperature,
      'trendSlope': trendSlope,
    };
  }

  @override
  Widget build(BuildContext context) {
    final double chartHeight = 800;

    return Scaffold(
      appBar: AppBar(title: Text('Temperature Trends')),
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
          
          debugPrint('Average temperature for plot band: $averageTemperature°C');

          // Calculate minimum temperature for Y-axis
          final minTemp = chartData.map((data) => data.temperature).reduce((a, b) => a < b ? a : b);
          final yAxisMin = (minTemp - 2).floorToDouble(); // Start 2 degrees below minimum

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
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
                      labelStyle: TextStyle(fontSize: 12),
                      majorGridLines: MajorGridLines(width: 0),
                      labelIntersectAction: AxisLabelIntersectAction.hide,
                    ),
                    primaryYAxis: NumericAxis(
                      labelFormat: '{value}°C',
                      numberFormat: NumberFormat('0'),
                      minimum: yAxisMin,
                      majorGridLines: MajorGridLines(width: 0),
                    ),
                    plotAreaBorderWidth: 0,
                  ),
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
