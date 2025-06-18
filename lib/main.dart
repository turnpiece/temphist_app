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
  late Future<List<TemperatureChartData>> futureChartData;

  @override
  void initState() {
    super.initState();
    futureChartData = _loadChartData();
  }

  Future<List<TemperatureChartData>> _loadChartData() async {
    final now = DateTime.now();
    final useYesterday = now.hour < 1;
    final dateToUse = useYesterday ? now.subtract(Duration(days: 1)) : now;
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateToUse);

    final service = TemperatureService();
    final city = 'London';
    final currentYear = dateToUse.year;

    final List<TemperatureChartData> chartData = [];

    // First, get the year range from a sample API call
    try {
      final sampleTempData = await service.fetchTemperature(city, '$currentYear-${formattedDate.substring(5)}');
      
      // Get year range from the API response
      int startYear = currentYear - 50; // fallback
      int endYear = currentYear;
      
      if (sampleTempData.average?.yearRange != null) {
        startYear = sampleTempData.average!.yearRange.start;
        endYear = sampleTempData.average!.yearRange.end;
      } else if (sampleTempData.series?.data.isNotEmpty == true) {
        // Extract year range from series data
        final years = sampleTempData.series!.data.map((point) => point.x).toList();
        years.sort();
        startYear = years.first;
        endYear = years.last;
      }
      
      debugPrint('Year range from API: $startYear to $endYear');

      // Fetch data for all years in the range
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
    } catch (e) {
      debugPrint('Failed to get year range: $e');
      // Fallback to current approach if we can't get the year range
      for (int year = currentYear - 50; year <= currentYear; year++) {
        final dateForYear = '$year-${formattedDate.substring(5)}';
        try {
          final tempData = await service.fetchTemperature(city, dateForYear);
          chartData.add(TemperatureChartData(
            year: year.toString(),
            temperature: tempData.temperature ?? tempData.average?.temperature ?? 0.0,
            isCurrentYear: year == currentYear,
          ));
        } catch (e) {
          debugPrint('Failed to fetch data for $year: $e');
        }
      }
    }

    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    final double chartHeight = 800;

    return Scaffold(
      appBar: AppBar(title: Text('Temperature Trends')),
      body: FutureBuilder<List<TemperatureChartData>>(
        future: futureChartData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading data: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No temperature data available.'));
          }

          final chartData = snapshot.data!;

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
                    series: [
                      BarSeries<TemperatureChartData, String>(
                        dataSource: chartData,
                        xValueMapper: (TemperatureChartData data, int index) => data.year,
                        yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                        pointColorMapper: (TemperatureChartData data, int index) =>
                            data.isCurrentYear ? Colors.green : Colors.red,
                        width: 0.8,
                      ),
                    ],
                    primaryXAxis: CategoryAxis(
                      labelStyle: TextStyle(fontSize: 12),
                      majorGridLines: MajorGridLines(width: 0),
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
