import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:geocoding/geocoding.dart';

import 'services/temperature_service.dart';

// App color constants
const kBackgroundColour = Color(0xFF242456);
const kAccentColour = Color(0xFFFF6B6B);
const kTextPrimaryColour = Color(0xFFECECEC);
const kSummaryColour = Color(0xFF51CF66);
const kAverageColour = Color(0xFF4DABF7);
const kTrendColour = Color(0xFFAAAA00);
const kTrendLineColour = kTrendColour;
const kBarOtherYearColour = kAccentColour;
const kBarCurrentYearColour = kSummaryColour;
const kAxisLabelColour = Color(0xFFECECEC);
const kAxisGridColour = kAxisLabelColour;
const kGreyLabelColour = Color(0xFFB0B0B0);

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
    String city = 'London';
    // Try to get user's city via geolocation
    try {
      bool serviceEnabled = await geo.Geolocator.isLocationServiceEnabled();
      if (serviceEnabled) {
        geo.LocationPermission permission = await geo.Geolocator.checkPermission();
        if (permission == geo.LocationPermission.denied) {
          permission = await geo.Geolocator.requestPermission();
        }
        if (permission == geo.LocationPermission.whileInUse || permission == geo.LocationPermission.always) {
          geo.Position position = await geo.Geolocator.getCurrentPosition(desiredAccuracy: geo.LocationAccuracy.low);
          List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
          if (placemarks.isNotEmpty && placemarks.first.locality != null && placemarks.first.locality!.isNotEmpty) {
            city = placemarks.first.locality!;
          }
        }
      }
    } catch (_) {
      // Ignore and fall back to London
    }
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
      backgroundColor: kBackgroundColour,
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

          // Calculate minimum and maximum temperature for Y-axis
          final minTemp = chartData.map((data) => data.temperature).reduce((a, b) => a < b ? a : b);
          final maxTemp = chartData.map((data) => data.temperature).reduce((a, b) => a > b ? a : b);
          final yAxisMin = (minTemp - 2).floorToDouble(); // Start 2 degrees below minimum
          final yAxisMax = (maxTemp + 2).ceilToDouble(); // End 2 degrees above maximum

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minWidth: 350, maxWidth: 800),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title/logo row moved here from AppBar
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 40),
                            child: Row(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(right: 12.0),
                                  child: SvgPicture.asset(
                                    'assets/logo.svg',
                                    width: 40,
                                    height: 40,
                                  ),
                                ),
                                Text(
                                  'TempHist',
                                  style: TextStyle(
                                    color: kAccentColour,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Date and location above summary
                      if (displayDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                displayDate,
                                style: const TextStyle(color: kTextPrimaryColour, fontSize: 16, fontWeight: FontWeight.w400),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      if (city != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                city,
                                style: const TextStyle(color: kTextPrimaryColour, fontSize: 16, fontWeight: FontWeight.w400),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      if (summaryText?.isNotEmpty == true)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                summaryText!,
                                style: TextStyle(color: kSummaryColour, fontSize: 16, fontWeight: FontWeight.w400),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      SizedBox(
                        height: chartHeight,
                        child: SfCartesianChart(
                          margin: EdgeInsets.symmetric(horizontal: 40),
                          tooltipBehavior: TooltipBehavior(
                            enable: true,
                            format: 'point.x: point.y',
                            canShowMarker: false,
                            header: '',
                            textStyle: TextStyle(fontSize: 16),
                          ),
                          series: [
                            BarSeries<TemperatureChartData, String>(
                              dataSource: chartData,
                              xValueMapper: (TemperatureChartData data, int index) => data.year,
                              yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                              pointColorMapper: (TemperatureChartData data, int index) =>
                                  data.isCurrentYear ? kBarCurrentYearColour : kBarOtherYearColour,
                              width: 0.8,
                              name: 'Yearly Temperature',
                              enableTooltip: true,
                            ),
                            if (averageTemperature != null)
                              LineSeries<TemperatureChartData, String>(
                                dataSource: _generateAverageData(chartData, averageTemperature!),
                                xValueMapper: (TemperatureChartData data, int index) => data.year,
                                yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                                color: kAverageColour,
                                width: 2,
                                name: 'Average Temperature',
                                markerSettings: MarkerSettings(isVisible: false),
                              ),
                            if (trendSlope != null)
                              LineSeries<TemperatureChartData, String>(
                                dataSource: _generateTrendData(chartData, trendSlope!),
                                xValueMapper: (TemperatureChartData data, int index) => data.year,
                                yValueMapper: (TemperatureChartData data, int index) => data.temperature,
                                color: kTrendColour,
                                width: 2,
                                name: 'Trend',
                                markerSettings: MarkerSettings(isVisible: false),
                              ),
                          ],
                          primaryXAxis: CategoryAxis(
                            labelStyle: TextStyle(fontSize: 12, color: kGreyLabelColour),
                            majorGridLines: MajorGridLines(width: 0),
                            labelIntersectAction: AxisLabelIntersectAction.hide,
                          ),
                          primaryYAxis: NumericAxis(
                            labelFormat: '{value}°C',
                            numberFormat: NumberFormat('0'),
                            minimum: yAxisMin,
                            maximum: yAxisMax,
                            majorGridLines: MajorGridLines(width: 0),
                            labelStyle: TextStyle(fontSize: 12, color: kGreyLabelColour),
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
                                style: TextStyle(color: kAverageColour, fontSize: 16, fontWeight: FontWeight.w400),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
                      if (trendSlope != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                (trendSlope.abs() < 0.01)
                                  ? 'Trend: stable'
                                  : 'Trend: ${trendSlope > 0 ? 'rising' : 'falling'} at ${trendSlope.abs().toStringAsFixed(2)}°C/decade',
                                style: TextStyle(color: kTrendColour, fontSize: 16, fontWeight: FontWeight.w400),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                        ),
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
