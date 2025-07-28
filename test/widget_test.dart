// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // Create a simple mock data for testing
    final mockData = {
      'chartData': <TemperatureChartData>[],
      'averageTemperature': null,
      'trendSlope': null,
      'summary': '',
      'displayDate': '',
      'city': '',
    };

    // Build our app and trigger a frame.
    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(mockData),
      ),
    ));

    // Verify that the app loads without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
