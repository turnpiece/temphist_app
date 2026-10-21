import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/widgets/temperature_bar_chart.dart';

TemperatureChartData _point(String year, double temp, {double? anomaly}) =>
    TemperatureChartData(
      year: year,
      temperature: temp,
      isCurrentYear: false,
      anomaly: anomaly,
    );

TemperatureChartPresentation _presentation(
  List<TemperatureChartData> data, {
  bool fahrenheit = false,
}) =>
    TemperatureChartPresentation(
      styledChartData: data,
      validData: data.where((d) => d.hasData).toList(),
      yAxisMin: 0,
      yAxisMax: 30,
      yAxisInterval: 5,
      unitLabel: fahrenheit ? '°F' : '°C',
      shouldConvert: fahrenheit,
    );

void main() {
  final data = [
    _point('2026', 14.2, anomaly: 1.3),
    _point('1986', 9.8, anomaly: -3.1),
    _point('2022', 16.0, anomaly: 3.1),
  ];

  group('formatChartAnomaly', () {
    test('signed text for the tooltip', () {
      final p = _presentation(data);
      expect(formatChartAnomaly(data[0], p, isDailyPeriod: false),
          '+1.30°C above average');
      expect(formatChartAnomaly(data[1], p, isDailyPeriod: false),
          '−3.10°C below average');
    });

    test('spoken text drops the sign', () {
      final p = _presentation(data);
      expect(formatChartAnomaly(data[1], p, isDailyPeriod: false, spoken: true),
          '3.10°C below average');
    });

    test('zero anomaly', () {
      final p = _presentation(data);
      final flat = _point('2000', 12, anomaly: 0.001);
      expect(formatChartAnomaly(flat, p, isDailyPeriod: false),
          '0.00°C at the average');
      expect(formatChartAnomaly(flat, p, isDailyPeriod: false, spoken: true),
          'same as average');
    });

    test('null when the point has no anomaly', () {
      final p = _presentation(data);
      expect(formatChartAnomaly(_point('2000', 12), p, isDailyPeriod: false),
          isNull);
    });

    test('Fahrenheit converts the anomaly as a difference, one decimal', () {
      final p = _presentation(data, fahrenheit: true);
      expect(formatChartAnomaly(data[0], p, isDailyPeriod: false, spoken: true),
          '2.3°F above average');
    });
  });

  group('temperatureChartSemanticsLabel', () {
    test('summarises latest, warmest, coolest, average and trend (°C)', () {
      final label = temperatureChartSemanticsLabel(
        presentation: _presentation(data),
        isDailyPeriod: false,
        periodDescription: 'the past week',
        averageTemperature: 12.9,
        trendSlope: 0.4,
      );
      expect(
        label,
        'Bar chart of temperature by year for the past week, 1986 to 2026. '
        'Latest, 2026: 14.20°C, 1.30°C above average. '
        'Warmest, 2022: 16.00°C. '
        'Coolest, 1986: 9.80°C. '
        'Average 12.90°C. '
        'Trend: Rising at 0.40°C/decade.',
      );
    });

    test('converts to Fahrenheit and uses one decimal', () {
      final label = temperatureChartSemanticsLabel(
        presentation: _presentation(data, fahrenheit: true),
        isDailyPeriod: false,
        averageTemperature: 12.9,
        trendSlope: -0.4,
      );
      expect(label, contains('Latest, 2026: 57.6°F, 2.3°F above average.'));
      expect(label, contains('Average 55.2°F.'));
      expect(label, contains('Trend: Falling at 0.7°F/decade.'));
      expect(label, isNot(contains(' for ')));
    });

    test('daily periods use one decimal in Celsius', () {
      final label = temperatureChartSemanticsLabel(
        presentation: _presentation(data),
        isDailyPeriod: true,
        periodDescription: 'this day',
      );
      expect(label, contains('Latest, 2026: 14.2°C, 1.3°C above average.'));
    });

    test('single point omits warmest/coolest, missing optionals are skipped',
        () {
      final label = temperatureChartSemanticsLabel(
        presentation: _presentation([_point('2026', 14.2)]),
        isDailyPeriod: false,
      );
      expect(label,
          'Bar chart of temperature by year, 2026 to 2026. Latest, 2026: 14.20°C.');
    });

    test('ignores points without data', () {
      final withGap = [
        _point('2026', 14.2),
        TemperatureChartData(
            year: '2025', temperature: 0, isCurrentYear: false, hasData: false),
      ];
      final label = temperatureChartSemanticsLabel(
        presentation: _presentation(withGap),
        isDailyPeriod: false,
      );
      expect(label, isNot(contains('2025')));
    });

    test('empty data', () {
      expect(
        temperatureChartSemanticsLabel(
          presentation: _presentation([]),
          isDailyPeriod: false,
        ),
        'Temperature chart, no data',
      );
    });
  });

  testWidgets('chart exposes one labelled image node to screen readers',
      (tester) async {
    final handle = tester.ensureSemantics();
    final p = _presentation(data);

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: TemperatureBarChart(
          chartData: data,
          presentation: p,
          averageTemperature: 12.9,
          trendSlope: 0.4,
          height: 300,
          periodDescription: 'the past week',
        ),
      ),
    ));
    await tester.pump();

    final expected = temperatureChartSemanticsLabel(
      presentation: p,
      isDailyPeriod: false,
      periodDescription: 'the past week',
      averageTemperature: 12.9,
      trendSlope: 0.4,
    );
    expect(find.bySemanticsLabel(expected), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel(expected)),
      matchesSemantics(label: expected, isImage: true),
    );
    handle.dispose();
  });
}
