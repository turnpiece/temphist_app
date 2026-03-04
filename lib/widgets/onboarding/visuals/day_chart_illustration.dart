import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Static bar chart illustration showing the same date across multiple years.
/// Horizontal bars, years listed top-to-bottom with the most recent at the top,
/// matching the actual app layout.
class DayChartIllustration extends StatelessWidget {
  const DayChartIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      width: double.infinity,
      child: CustomPaint(
        painter: _DayChartPainter(),
      ),
    );
  }
}

class _DayChartPainter extends CustomPainter {
  // Most recent year at the top; 2026 shown in green
  static const List<String> _years = ['2026', '2025', '2024', '2023', '2022', '2021', '2020'];
  static const List<double> _widths = [0.90, 0.75, 0.60, 0.80, 0.45, 0.70, 0.55];

  static const _labelStyle = TextStyle(
    color: kGreyLabelColour,
    fontSize: 10,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final int barCount = _years.length;
    const double yearLabelWidth = 36.0;
    const double barSpacing = 3.0;
    final double barHeight = (size.height - barSpacing * (barCount - 1)) / barCount;
    final double chartWidth = size.width - yearLabelWidth - 8.0;

    final paintOther = Paint()
      ..color = kBarOtherYearColour.withOpacity(0.85)
      ..style = PaintingStyle.fill;
    final paintCurrent = Paint()
      ..color = kBarCurrentYearColour.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < barCount; i++) {
      final double y = i * (barHeight + barSpacing);
      final double barW = _widths[i] * chartWidth;
      final bool isCurrent = i == 0;

      // Year label — consistent style for all years
      final yearTp = TextPainter(
        text: TextSpan(text: _years[i], style: _labelStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: yearLabelWidth);
      yearTp.paint(canvas, Offset(0, y + (barHeight - yearTp.height) / 2));

      // Horizontal bar
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(yearLabelWidth + 8, y, barW, barHeight),
          const Radius.circular(3),
        ),
        isCurrent ? paintCurrent : paintOther,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
