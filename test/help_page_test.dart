import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/widgets/help_page.dart';

Widget _helpPage({double textScale = 1.0}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: TextScaler.linear(textScale),
      ),
      child: child!,
    ),
    home: const HelpPage(),
  );
}

/// Scrolls the help list until [finder] is on screen.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(
    finder,
    200,
    scrollable: find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    ),
  );
}

void main() {
  group('HelpPage data source sections', () {
    testWidgets('explains where the data comes from and credits Open-Meteo',
        (tester) async {
      await tester.pumpWidget(_helpPage());

      await _scrollTo(tester, find.text('Where the data comes from'));

      expect(find.text('Where the data comes from'), findsOneWidget);
      expect(find.textContaining('ERA5 reanalysis'), findsOneWidget);
      expect(find.textContaining('not a reading from a single weather station'),
          findsOneWidget);

      await _scrollTo(
          tester, find.textContaining('Weather data by', findRichText: true));
      expect(
        find.textContaining('Weather data by Open-Meteo.com',
            findRichText: true),
        findsOneWidget,
      );
      expect(
        find.textContaining('Copernicus Climate Change Service information',
            findRichText: true),
        findsOneWidget,
      );
    });

    testWidgets('explains how the numbers are made', (tester) async {
      await tester.pumpWidget(_helpPage());

      await _scrollTo(tester, find.text('How the numbers are made'));

      expect(find.text('How the numbers are made'), findsOneWidget);
      expect(find.textContaining('last 51 years'), findsOneWidget);
      expect(find.textContaining('31 days for Month'), findsOneWidget);
      expect(find.textContaining('straight-line fit'), findsOneWidget);
    });

    testWidgets('renders without overflow at large text on a small phone',
        (tester) async {
      tester.view.physicalSize = const Size(320 * 2, 568 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(_helpPage(textScale: 2.0));

      for (final title in [
        'Where the data comes from',
        'How the numbers are made',
      ]) {
        await _scrollTo(tester, find.text(title));
        expect(find.text(title), findsOneWidget);
      }
      await _scrollTo(
          tester, find.textContaining('. ECMWF.', findRichText: true));

      expect(tester.takeException(), isNull);
    });
  });
}
