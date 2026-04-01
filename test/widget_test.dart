import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/main.dart';

void main() {
  testWidgets('App loads without crashing', (WidgetTester tester) async {
    // testFuture skips async initialization (location, network) so the
    // widget can be pumped in a unit test without real services.
    await tester.pumpWidget(MaterialApp(
      home: TemperatureScreen(
        testFuture: Future.value(<String, dynamic>{}),
      ),
    ));

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
