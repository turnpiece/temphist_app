import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:graphic/graphic.dart' as graphic;

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
  late Future<List<Map<String, dynamic>>> futureChartData;

  @override
  void initState() {
    super.initState();
    futureChartData = _loadChartData();
  }

  Future<List<Map<String, dynamic>>> _loadChartData() async {
    final now = DateTime.now();
    final useYesterday = now.hour < 1;
    final dateToUse = useYesterday ? now.subtract(Duration(days: 1)) : now;
    final formattedDate = DateFormat('yyyy-MM-dd').format(dateToUse);

    final service = TemperatureService();
    final city = 'London';
    final currentYear = dateToUse.year;

    final List<Map<String, dynamic>> chartData = [];

    for (int year = currentYear - 49; year <= currentYear; year++) {
      final dateForYear = '$year-${formattedDate.substring(5)}';
      try {
        final tempData = await service.fetchTemperature(city, dateForYear);
        chartData.add({
          'year': year.toString(),
          'temp': tempData.temperature ?? tempData.average?.temperature ?? 0.0,
          'color': year == currentYear ? 'highlight' : 'normal',
        });
      } catch (e) {
        debugPrint('Failed to fetch data for $year: $e');
      }
    }

    return chartData;
  }

  @override
  Widget build(BuildContext context) {
    final double chartHeight = 800;

    return Scaffold(
      appBar: AppBar(title: Text('Temperature Trends')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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

          return SingleChildScrollView(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  height: chartHeight,
                  child: graphic.Chart(
                    data: chartData,
                    variables: {
                      'year': graphic.Variable(
                        accessor: (row) => (row as Map<String, dynamic>)['year'] as String,
                      ),
                      'temp': graphic.Variable(
                        accessor: (row) => (row as Map<String, dynamic>)['temp'] as num,
                      ),
                      'color': graphic.Variable(
                        accessor: (row) => (row as Map<String, dynamic>)['color'] as String,
                      ),
                    },
                    marks: [
                      graphic.IntervalMark(
                        size: graphic.SizeEncode(value: 18),
                        color: graphic.ColorEncode(
                          variable: 'color',
                          values: [
                            const Color(0xFFFF6B6B),
                            const Color(0xFF51CF66),
                          ],
                        ),
                      )
                    ],
                    coord: graphic.RectCoord(
                      transposed: true,
                      horizontalRange: [0.05, 0.95],
                    ),
                    axes: [
                      graphic.Defaults.horizontalAxis,
                      graphic.Defaults.verticalAxis,
                    ],
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
