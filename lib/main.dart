import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

void main() => runApp(TempHistApp());

class TempHistApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TempHist',
      home: TempChartScreen(),
    );
  }
}

class TempChartScreen extends StatelessWidget {
  final List<_ChartData> data = [
    _ChartData('1975', 9.2),
    _ChartData('1980', 9.5),
    _ChartData('1985', 9.3),
    _ChartData('1990', 9.7),
    _ChartData('1995', 10.1),
    _ChartData('2000', 10.3),
    _ChartData('2005', 10.6),
    _ChartData('2010', 10.8),
    _ChartData('2015', 11.2),
    _ChartData('2020', 11.5),
  ];

  @override
  Widget build(BuildContext context) {
    final double avg =
        data.map((d) => d.y).reduce((a, b) => a + b) / data.length;

    return Scaffold(
      appBar: AppBar(title: Text('Historical Avg Temps in London')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: SfCartesianChart(
                title: ChartTitle(text: 'Average Temperature by Year'),
                primaryXAxis: CategoryAxis(
                  title: AxisTitle(text: 'Year'),
                  isInversed: true,
                ),
                primaryYAxis: NumericAxis(
                  title: AxisTitle(text: 'Temperature (°C)'),
                  minimum: avg - 2,
                  maximum: avg + 2,
                ),
                series: <CartesianSeries<_ChartData, String>>[
                  BarSeries<_ChartData, String>(
                    dataSource: data,
                    xValueMapper: (_ChartData data, _) => data.x,
                    yValueMapper: (_ChartData data, _) => data.y,
                    dataLabelSettings: DataLabelSettings(isVisible: true),
                    color: Colors.blueAccent,
                  ),
                ],
              ),
            ),
            Text(
              'Average Temp: ${avg.toStringAsFixed(1)}°C',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }
}

class _ChartData {
  final String x;
  final double y;
  _ChartData(this.x, this.y);
}
