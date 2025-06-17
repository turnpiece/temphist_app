import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // from FlutterFire CLI

// Color constants
const backgroundColor = Color(0xFF121234);
const textColor = Color(0xFFECECEC);
const secondaryTextColor = Color(0xFF808080); // Darker color for grid and axis text

void main() => runApp(TempHistApp());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

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
    _ChartData('1976', 11.1),
    _ChartData('1977', 9.8),
    _ChartData('1978', 10.3),
    _ChartData('1979', 9.5),
    _ChartData('1980', 10.7),
    _ChartData('1981', 9.3),
    _ChartData('1982', 11.2),
    _ChartData('1983', 9.7),
    _ChartData('1984', 10.1),
    _ChartData('1985', 11.4),
    _ChartData('1986', 9.9),
    _ChartData('1987', 10.5),
    _ChartData('1988', 9.4),
    _ChartData('1989', 11.3),
    _ChartData('1990', 10.2),
    _ChartData('1991', 9.6),
    _ChartData('1992', 11.0),
    _ChartData('1993', 10.4),
    _ChartData('1994', 9.8),
    _ChartData('1995', 11.5),
    _ChartData('1996', 10.0),
    _ChartData('1997', 9.7),
    _ChartData('1998', 11.2),
    _ChartData('1999', 10.3),
    _ChartData('2000', 9.5),
    _ChartData('2001', 11.4),
    _ChartData('2002', 10.1),
    _ChartData('2003', 9.9),
    _ChartData('2004', 11.0),
    _ChartData('2005', 10.6),
    _ChartData('2006', 9.4),
    _ChartData('2007', 11.3),
    _ChartData('2008', 10.2),
    _ChartData('2009', 9.8),
    _ChartData('2010', 11.1),
    _ChartData('2011', 10.4),
    _ChartData('2012', 9.6),
    _ChartData('2013', 11.5),
    _ChartData('2014', 10.0),
    _ChartData('2015', 9.7),
    _ChartData('2016', 11.2),
    _ChartData('2017', 10.3),
    _ChartData('2018', 9.5),
    _ChartData('2019', 11.4),
    _ChartData('2020', 10.1),
    _ChartData('2021', 9.9),
    _ChartData('2022', 11.0),
    _ChartData('2023', 10.5),
    _ChartData('2024', 9.6),
    _ChartData('2025', 11.3),
  ];

  @override
  Widget build(BuildContext context) {
    final double avg =
        data.map((d) => d.y).reduce((a, b) => a + b) / data.length;
    
    // Calculate the range and determine appropriate interval
    final double minTemp = data.map((d) => d.y).reduce((a, b) => a < b ? a : b);
    final double maxTemp = data.map((d) => d.y).reduce((a, b) => a > b ? a : b);
    final double range = maxTemp - minTemp;
    final double interval = (range / 4).ceilToDouble();

    // Get the year range from the data
    final int startYear = int.parse(data.first.x);
    final int endYear = int.parse(data.last.x);
    
    // Calculate trend line
    final int n = data.length;
    final List<double> xValues = List.generate(n, (i) => i.toDouble());
    final List<double> yValues = data.map((d) => d.y).toList();
    
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    for (int i = 0; i < n; i++) {
      sumX += xValues[i];
      sumY += yValues[i];
      sumXY += xValues[i] * yValues[i];
      sumX2 += xValues[i] * xValues[i];
    }
    
    final double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    final double intercept = (sumY - slope * sumX) / n;

    // Create trend line data points
    final List<_ChartData> trendData = [
      _ChartData((startYear - 1).toString(), slope * -1 + intercept),  // Start point
      _ChartData((endYear + 1).toString(), slope * (n - 1) + intercept),  // End point
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('TempHist'),
        backgroundColor: backgroundColor,
        foregroundColor: textColor,
      ),
      backgroundColor: backgroundColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              SizedBox(
                height: 800, // Minimum height for the chart
                child: SfCartesianChart(
                  title: ChartTitle(
                    text: 'Temperature on this day each year',
                    textStyle: TextStyle(color: secondaryTextColor),
                  ),
                  borderWidth: 0,
                  plotAreaBorderWidth: 0,
                  primaryXAxis: CategoryAxis(
                    isInversed: false,
                    interval: 5,
                    labelStyle: TextStyle(color: secondaryTextColor),
                    majorGridLines: MajorGridLines(color: secondaryTextColor),
                    arrangeByIndex: true,
                  ),
                  primaryYAxis: NumericAxis(
                    title: AxisTitle(
                      text: 'Temperature (°C)',
                      textStyle: TextStyle(color: secondaryTextColor),
                    ),
                    minimum: minTemp.floorToDouble(),
                    maximum: maxTemp.ceilToDouble(),
                    numberFormat: NumberFormat('#', 'en_US'),
                    interval: interval,
                    labelStyle: TextStyle(color: secondaryTextColor),
                    majorGridLines: MajorGridLines(color: secondaryTextColor),
                  ),
                  series: <CartesianSeries<_ChartData, String>>[
                    BarSeries<_ChartData, String>(
                      dataSource: data,
                      xValueMapper: (_ChartData data, _) => data.x,
                      yValueMapper: (_ChartData data, _) => data.y,
                      dataLabelSettings: DataLabelSettings(isVisible: false),
                      color: Colors.blueAccent,
                      spacing: 0.2,
                      width: 1,
                      trendlines: <Trendline>[
                        Trendline(
                          type: TrendlineType.linear,
                          color: Colors.red,
                          width: 2,
                          forwardForecast: 1,
                          backwardForecast: 1,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                'Average: ${avg.toStringAsFixed(1)}°C',
                style: TextStyle(
                  fontSize: 16,
                  color: textColor,
                ),
              )
            ],
          ),
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
