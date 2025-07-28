import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/main.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

void main() {
  testWidgets('Finds any text', (WidgetTester tester) async {
    final mockData = {
      'chartData': <TemperatureChartData>[],
      'averageTemperature': null,
      'trendSlope': null,
      'summary': '',
      'displayDate': '',
      'city': '',
    };

    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(mockData),
      ),
    ));

    await tester.pumpAndSettle();
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('App shows title', (WidgetTester tester) async {
    final mockData = {
      'chartData': <TemperatureChartData>[],
      'averageTemperature': null,
      'trendSlope': null,
      'summary': '',
      'displayDate': '',
      'city': '',
    };

    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(mockData),
      ),
    ));

    await tester.pumpAndSettle();
    expect(find.text('TempHist'), findsOneWidget);
  });

  testWidgets('Chart and summary render with data', (WidgetTester tester) async {
    // Mock chart data
    final mockData = {
      'chartData': [
        TemperatureChartData(year: '2020', temperature: 15.0, isCurrentYear: false),
        TemperatureChartData(year: '2021', temperature: 16.0, isCurrentYear: true),
      ],
      'averageTemperature': 15.5,
      'trendSlope': 0.1,
      'summary': 'Test summary',
      'displayDate': '1st January',
      'city': 'Testville',
    };

    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(mockData),
      ),
    ));

    // Wait for the FutureBuilder to complete
    await tester.pumpAndSettle();

    // Check for chart, summary, and city
    expect(find.text('Test summary'), findsOneWidget);
    expect(find.text('Testville'), findsOneWidget);
    expect(find.text('Average: 15.5°C'), findsOneWidget);
    expect(find.textContaining('Trend:'), findsOneWidget);
    // You can also check for the chart widget type if needed
    // expect(find.byType(SfCartesianChart), findsOneWidget);
  });

  testWidgets('Shows loading indicator while waiting', (WidgetTester tester) async {
    // Use a future that never completes
    final neverCompletes = Completer<Map<String, dynamic>>().future;

    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: neverCompletes,
      ),
    ));

    // The CircularProgressIndicator should be visible
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('Shows error and retry button on error', (WidgetTester tester) async {
    // Create a completer that we can control
    final completer = Completer<Map<String, dynamic>>();

    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: completer.future,
      ),
    ));

    // Complete the future with an error
    completer.completeError('Test error');

    // Wait for the error to be displayed
    await tester.pumpAndSettle();

    // Verify that error message and retry button are shown
    expect(find.textContaining('Error loading data'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);
  });
} 