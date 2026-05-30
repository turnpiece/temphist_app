import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Static bar chart illustration showing the same date across multiple years.
/// Horizontal bars, years listed top-to-bottom with the most recent at the top,
/// matching the actual app layout.
class DayChartIllustration extends StatelessWidget {
  final double height;
  const DayChartIllustration({super.key, this.height = 150});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _DayChartPainter(),
      ),
    );
  }
}

class _DayChartPainter extends CustomPainter {
  // 14 years (2026–2013), most recent at top.
  // Labels shown only for multiples of 5 (2025, 2020, 2015),
  // matching the actual app's axis style.
  static const List<int> _years = [
    2026, 2025, 2024, 2023, 2022, 2021, 2020,
    2019, 2018, 2017, 2016, 2015, 2014, 2013,
  ];

  // Bar widths as a fraction of chart area — natural year-to-year variation,
  // no directional trend.
  static const List<double> _widths = [
    0.70, 0.55, 0.80, 0.60, 0.75, 0.45, 0.65,
    0.70, 0.50, 0.60, 0.78, 0.55, 0.68, 0.48,
  ];

  static const _labelStyle = TextStyle(
    color: kGreyLabelColour,
    fontSize: 10,
    fontFamilyFallback: kChartAxisFontFamilyFallback,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final int barCount = _years.length;
    const double yearLabelWidth = 36.0;
    const double barSpacing = 3.0;
    final double barHeight =
        (size.height - barSpacing * (barCount - 1)) / barCount;
    final double chartWidth = size.width - yearLabelWidth - 8.0;
    final averageWidth = _widths.reduce((a, b) => a + b) / _widths.length;
    final maxWarmDelta = _widths
        .map((w) => w - averageWidth)
        .where((d) => d > 0)
        .fold<double>(0, (max, d) => d > max ? d : max);
    final maxCoolDelta = _widths
        .map((w) => averageWidth - w)
        .where((d) => d > 0)
        .fold<double>(0, (max, d) => d > max ? d : max);

    for (int i = 0; i < barCount; i++) {
      final double y = i * (barHeight + barSpacing);
      final double barW = _widths[i] * chartWidth;
      final int year = _years[i];

      final fillColour = _barColourForWidth(
        _widths[i], averageWidth, maxWarmDelta, maxCoolDelta,
      ).withValues(alpha: 0.9);

      final fillPaint = Paint()
        ..color = fillColour
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = fillColour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(yearLabelWidth + 8, y, barW, barHeight),
        topRight: const Radius.circular(2),
        bottomRight: const Radius.circular(2),
      );

      // Year label — only for multiples of 5, matching the real app axis.
      if (year % 5 == 0) {
        final yearTp = TextPainter(
          text: TextSpan(text: year.toString(), style: _labelStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: yearLabelWidth);
        yearTp.paint(canvas, Offset(0, y + (barHeight - yearTp.height) / 2));
      }

      canvas.drawRRect(barRect, fillPaint);
      canvas.drawRRect(barRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

Color _barColourForWidth(
  double width,
  double averageWidth,
  double maxWarmDelta,
  double maxCoolDelta,
) {
  const double neutralBand = 0.12;
  final delta = width - averageWidth;

  double normalized;
  if (delta > 0) {
    normalized = maxWarmDelta == 0 ? 0 : delta / maxWarmDelta;
  } else if (delta < 0) {
    normalized = maxCoolDelta == 0 ? 0 : delta.abs() / maxCoolDelta;
  } else {
    normalized = 0;
  }

  if (normalized <= neutralBand) {
    return kBarNeutralColour;
  }

  final blend =
      ((normalized - neutralBand) / (1 - neutralBand)).clamp(0.0, 1.0);
  return Color.lerp(
        kBarNeutralColour,
        delta >= 0 ? kBarWarmColour : kBarCoolColour,
        blend,
      ) ??
      kBarNeutralColour;
}
