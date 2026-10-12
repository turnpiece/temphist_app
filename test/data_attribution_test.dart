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

    testWidgets('wraps rather than overflows at large text on a narrow screen',
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
