import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/constants/app_constants.dart';
import 'package:temphist_app/models/period_temperature_data.dart';
import 'package:temphist_app/services/period_cache_service.dart';
import 'package:temphist_app/utils/temperature_utils.dart';
import 'package:temphist_app/widgets/completeness_section.dart';
import 'package:temphist_app/widgets/period_page.dart';

/// Wraps [child] so the system text scale is [scale], as Dynamic Type would.
Widget _scaled(double scale, Widget child) => MaterialApp(
      builder: (context, c) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(scale)),
        child: c!,
      ),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

/// The stats row whose text starts with [label] (they are RichText widgets).
Finder _statRow(String label) => find.byWidgetPredicate(
      (w) => w is RichText && w.text.toPlainText().startsWith(label),
    );

void main() {
  group('CompletenessSection text scaling', () {
    Future<double> noteHeightAt(WidgetTester tester, double scale) async {
      await tester.pumpWidget(
        _scaled(
          scale,
          CompletenessSection(
            allMissing: const [1990, 1991],
            completeness: 60,
            onRetry: () {},
          ),
        ),
      );
      return tester
          .getSize(find.text('Data completeness: 60%'))
          .height;
    }

    testWidgets('follows the system text size', (tester) async {
      final normal = await noteHeightAt(tester, 1.0);
      final large = await noteHeightAt(tester, 1.3);

      expect(large, greaterThan(normal * 1.2));
    });

    testWidgets('Retry button text follows the system text size',
        (tester) async {
      Future<double> retryHeightAt(double scale) async {
        await tester.pumpWidget(
          _scaled(
            scale,
            CompletenessSection(
              allMissing: const [1990],
              completeness: 90,
              onRetry: () {},
            ),
          ),
        );
        return tester.getSize(find.text('Retry')).height;
      }

      final normal = await retryHeightAt(1.0);
      final large = await retryHeightAt(1.3);

      expect(large, greaterThan(normal * 1.2));
    });
  });

  group('PeriodPage stats rows text scaling', () {
    const lat = 51.509;
    const lon = -0.118;
    const periodKey = 'month';
    late Directory tempDir;

    // Mirrors PeriodPageState._identifier when no timezone is supplied.
    String identifierNow() {
      final now = DateTime.now();
      final ref = now.hour < kUseYesterdayHourThreshold
          ? now.subtract(const Duration(days: 1))
          : now;
      return dateIdentifier(ref);
    }

    setUpAll(() async {
      tempDir = await Directory.systemTemp.createTemp('text_scaling_test_');
      await PeriodCacheService.init(path: tempDir.path);

      final year = DateTime.now().year;
      final identifier = identifierNow();
      await PeriodCacheService.put(
        periodKey,
        lat,
        lon,
        identifier,
        PeriodTemperatureData(
          period: periodKey,
          location: 'London, UK',
          identifier: identifier,
          range: PeriodRange(
              start: '${year - 49}-01-01', end: '$year-12-31', years: 50),
          unitGroup: 'celsius',
          values: [
            for (var y = year - 49; y <= year; y++)
              PeriodDataPoint(
                date: '$y-06-01',
                year: y,
                temperature: 10.0 + (y % 5),
                anomaly: (y % 5) - 2.0,
              ),
          ],
          average: PeriodAverage(mean: 12.0),
          trend: PeriodTrend(slope: 0.3, unit: '°C/decade'),
          summary: 'A typical month.',
          standardDeviation: 1.2,
        ),
      );
    });

    tearDownAll(() async {
      await PeriodCacheService.close();
      await tempDir.delete(recursive: true);
    });

    Widget page(double scale) => _scaled(
          scale,
          const SizedBox(
            height: 2000,
            child: PeriodPage(
              periodKey: periodKey,
              periodLabel: 'Month',
              location: 'London, UK',
              latitude: lat,
              longitude: lon,
            ),
          ),
        );

    testWidgets('Average, Standard deviation and Trend rows follow the '
        'system text size', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      Future<Map<String, double>> rowHeightsAt(double scale) async {
        await tester.pumpWidget(page(scale));
        await tester.pump(const Duration(milliseconds: 100));
        return {
          for (final label in ['Average', 'Standard deviation', 'Trend'])
            label: tester.getSize(_statRow(label).first).height,
        };
      }

      final normal = await rowHeightsAt(1.0);
      final large = await rowHeightsAt(1.3);

      for (final label in normal.keys) {
        expect(large[label], greaterThan(normal[label]! * 1.2),
            reason: '$label row did not grow with the system text size');
      }
    });

    testWidgets('rows are the same size as a plain RichText at the default '
        'text size (no theme line height or letter spacing leaks in)',
        (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 2400 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(page(1.0));
      await tester.pump(const Duration(milliseconds: 100));

      const label = 'Standard deviation  ';
      final rowFinder = _statRow('Standard deviation').first;
      final rowSize = tester.getSize(rowFinder);
      final value = tester
          .widget<RichText>(rowFinder)
          .text
          .toPlainText()
          .substring(label.length);

      // Built only from constants (not from the widget under test, whose
      // style tree would carry any inherited theme style with it): a plain,
      // unscaled RichText at the same width.
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: rowSize.width,
                child: RichText(
                  key: const Key('reference'),
                  text: TextSpan(
                    style: const TextStyle(fontSize: kStatsFontSize),
                    children: [
                      const TextSpan(
                        text: label,
                        style: TextStyle(fontWeight: FontWeight.w400),
                      ),
                      TextSpan(
                        text: value,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      final referenceSize = tester.getSize(find.byKey(const Key('reference')));

      expect(rowSize.height, closeTo(referenceSize.height, 0.5));
      expect(rowSize.width, closeTo(referenceSize.width, 0.5));
    });
  });
}
