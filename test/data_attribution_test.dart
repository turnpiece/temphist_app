import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/constants/app_constants.dart';
import 'package:temphist_app/widgets/data_attribution.dart';

void main() {
  group('DataAttribution', () {
    testWidgets('shows the Open-Meteo credit as a link', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: DataAttribution())),
      );

      expect(find.text('Weather data by Open-Meteo.com'), findsOneWidget);
      expect(kOpenMeteoUrl, 'https://open-meteo.com/');
      expect(
        tester.getSemantics(find.byType(InkWell)),
        matchesSemantics(
          isLink: true,
          hasTapAction: true,
          hasFocusAction: true,
          isFocusable: true,
          label: 'Weather data by Open-Meteo.com',
        ),
      );
      handle.dispose();
    });

    testWidgets('ignores the system text size so it never outgrows the stats',
        (tester) async {
      Future<Size> creditSizeAt(double scale) async {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(scale)),
              child: child!,
            ),
            home: const Scaffold(body: DataAttribution()),
          ),
        );
        return tester.getSize(find.text('Weather data by Open-Meteo.com'));
      }

      final normal = await creditSizeAt(1.0);
      final large = await creditSizeAt(2.5);

      expect(large, normal);
    });

    testWidgets('does not overflow on a narrow screen at large text',
        (tester) async {
      tester.view.physicalSize = const Size(200 * 2, 400 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2.5)),
            child: child!,
          ),
          home: const Scaffold(body: DataAttribution()),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Weather data by Open-Meteo.com'), findsOneWidget);
    });
  });
}
