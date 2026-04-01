import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/main.dart';

void main() {
  testWidgets('Finds any text', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(<String, dynamic>{}),
      ),
    ));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(Text), findsWidgets);
  });

  testWidgets('App shows location header placeholder', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(<String, dynamic>{}),
      ),
    ));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Loading location...'), findsAtLeastNWidgets(1));
  });

  testWidgets('PeriodPage shows determining location when location is empty', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(<String, dynamic>{}),
      ),
    ));

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // With testFuture set and no location resolved, the PeriodPage shows
    // "Determining location..." since the location prop is empty.
    expect(find.text('Determining location...'), findsWidgets);
  });

  testWidgets('App renders TemperatureScreen widget', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(<String, dynamic>{}),
      ),
    ));

    expect(find.byType(TemperatureScreen), findsOneWidget);
  });
}
