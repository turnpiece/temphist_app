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

/// Scrolls the help list so [finder] is on screen.
///
/// The page builds every section up front (so linking to a section works),
/// which means widgets outside the viewport exist but count as offstage:
/// finders here use `skipOffstage: false` and this brings the match into view.
Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
}

void main() {
  group('HelpPage data source sections', () {
    testWidgets('explains where the data comes from and credits Open-Meteo',
        (tester) async {
      await tester.pumpWidget(_helpPage());

      await _scrollTo(
          tester, find.text('Where the data comes from', skipOffstage: false));

      expect(find.text('Where the data comes from', skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('ERA5 reanalysis', skipOffstage: false),
          findsOneWidget);
      expect(
          find.textContaining('not a reading from a single weather station',
              skipOffstage: false),
          findsOneWidget);

      await _scrollTo(
          tester,
          find.textContaining('Weather data by',
              findRichText: true, skipOffstage: false));
      expect(
        find.textContaining('Weather data by Open-Meteo.com',
            findRichText: true, skipOffstage: false),
        findsOneWidget,
      );
      expect(
        find.textContaining('Copernicus Climate Change Service information',
            findRichText: true, skipOffstage: false),
        findsOneWidget,
      );
    });

    testWidgets('explains how the numbers are made', (tester) async {
      await tester.pumpWidget(_helpPage());

      await _scrollTo(
          tester, find.text('How the numbers are made', skipOffstage: false));

      expect(find.text('How the numbers are made', skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('last 51 years', skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('31 days for Month', skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('straight-line fit', skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('states the provenance of the series', (tester) async {
      await tester.pumpWidget(_helpPage());

      await _scrollTo(
          tester, find.text('Where the data comes from', skipOffstage: false));
      for (final text in [
        'same ERA5 grid cell',
        'same pinned model version',
        'The newest week comes from',
        'also counts as a point in the trend',
        'neighbouring location within about 30 km',
        'rather than a homogenised station record',
      ]) {
        await _scrollTo(tester, find.textContaining(text, skipOffstage: false));
        expect(find.textContaining(text, skipOffstage: false), findsOneWidget,
            reason: text);
      }

      await _scrollTo(
          tester,
          find.textContaining('Both use the same 51 values',
              skipOffstage: false));
      expect(
          find.textContaining('Both use the same 51 values',
              skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('newest few days', skipOffstage: false),
          findsNothing);
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
        await _scrollTo(tester, find.text(title, skipOffstage: false));
        expect(find.text(title, skipOffstage: false), findsOneWidget);
      }
      await _scrollTo(
          tester,
          find.textContaining('. ECMWF.',
              findRichText: true, skipOffstage: false));

      expect(tester.takeException(), isNull);
    });
  });

  group('HelpPage trend certainty', () {
    testWidgets('explains the ± as a standard error', (tester) async {
      await tester.pumpWidget(_helpPage());

      await _scrollTo(
          tester, find.text('How certain is the trend?', skipOffstage: false));
      expect(find.text('How certain is the trend?', skipOffstage: false),
          findsOneWidget);
      expect(find.textContaining('is its standard error', skipOffstage: false),
          findsOneWidget);
      expect(
          find.textContaining('double it for roughly 95%', skipOffstage: false),
          findsOneWidget);
      expect(
          find.textContaining('compare each trend against its ±',
              skipOffstage: false),
          findsOneWidget);
      expect(
          find.textContaining('Past year is the steadiest view',
              skipOffstage: false),
          findsOneWidget);
    });

    testWidgets('no longer mentions an error margin', (tester) async {
      await tester.pumpWidget(_helpPage());
      await _scrollTo(tester, find.text('Time periods', skipOffstage: false));

      expect(find.textContaining('error margin', skipOffstage: false),
          findsNothing);
      expect(find.textContaining('standard error (±)', skipOffstage: false),
          findsWidgets);
    });

    testWidgets('opens scrolled to the section when asked', (tester) async {
      tester.view.physicalSize = const Size(390 * 2, 844 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: const HelpPage(section: HelpSection.trendCertainty),
      ));
      await tester.pumpAndSettle();

      final title = find.text('How certain is the trend?', skipOffstage: false);
      expect(title, findsOneWidget);
      final top = tester.getTopLeft(title).dy;
      expect(top, greaterThanOrEqualTo(0));
      expect(top, lessThan(844 / 2));
    });
  });
}
