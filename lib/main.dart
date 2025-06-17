
import 'package:flutter/material.dart';
import 'package:graphic/graphic.dart' as graphic;
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(TempHistApp());

class TempHistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempHist Graphic Chart',
      home: TempChartScreen(),
    );
  }
}

class TempChartScreen extends StatefulWidget {
  @override
  _TempChartScreenState createState() => _TempChartScreenState();
}

class _TempChartScreenState extends State<TempChartScreen> {
  List<Map<String, dynamic>> chartData = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    final now = DateTime.now();
    final location = 'london';
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final url = Uri.parse('https://api.temphist.com/data/$location/$month-$day');

    try {
      final response = await http.get(url, headers: {'X-API-Token': 'testing'});
      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        final series = jsonBody['series']['data'] as List;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            chartData = series.map((e) => {
              'year': e['x'].toString(),
              'temp': e['y'],
              'color': e['x'] == now.year ? 'current' : 'past',
            }).toList();
            loading = false;
          });
        });
      } else {
        setState(() {
          error = 'HTTP error: ${response.statusCode}';
          loading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Failed to fetch data: $e';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text('Temperature Trends')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text('Temperature Trends')),
        body: Center(child: Text(error!)),
      );
    }

    if (chartData.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text('Temperature Trends')),
        body: Center(child: Text('No data available')),
      );
    }

    final barCount = chartData.length;
    final barHeight = 34.0;
    final minHeight = 300.0;
    final maxHeight = 900.0;
    final chartHeight = (barCount * barHeight).clamp(minHeight, maxHeight);

    return Scaffold(
      appBar: AppBar(title: Text('Temperature Trends')),
      body: SingleChildScrollView(
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
      ),
    );
  }
}
