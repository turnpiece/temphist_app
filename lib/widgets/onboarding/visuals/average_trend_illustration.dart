import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Illustrative chart showing faded bars with the average (blue) and
/// trend (yellow) lines emphasised, matching what users see in the app.
/// Year labels shown every 5 years only, like the actual chart.
class AverageTrendIllustration extends StatelessWidget {
  const AverageTrendIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      width: double.infinity,
      child: CustomPaint(
        painter: _AverageTrendPainter(),
      ),
    );
  }
}

class _AverageTrendPainter extends CustomPainter {
  // 20 years, most recent at top — matches actual app layout
  static const List<int> _years = [
    2025, 2024, 2023, 2022, 2021,
    2020, 2019, 2018, 2017, 2016,
    2015, 2014, 2013, 2012, 2011,
    2010, 2009, 2008, 2007, 2006,
  ];

  // Bar widths as fraction of chart area — general warming trend with variation
  static const List<double> _widths = [
    0.74, 0.65, 0.70, 0.56, 0.68,
    0.61, 0.64, 0.59, 0.72, 0.58,
    0.63, 0.55, 0.60, 0.53, 0.52,
    0.65, 0.50, 0.54, 0.48, 0.46,
  ];

  // Average vertical line at ~61% of chart width
  static const double _avgFraction = 0.61;

  // Trend line end-points as fractions of chart width (top = recent, bottom = older)
  static const double _trendTopFraction = 0.72;
  static const double _trendBottomFraction = 0.44;

  @override
  void paint(Canvas canvas, Size size) {
    const double yearLabelWidth = 36.0;
    const double barSpacing = 2.0;
    final int barCount = _years.length;
    final double barHeight =
        (size.height - barSpacing * (barCount - 1)) / barCount;
    const double chartStart = yearLabelWidth + 8.0;
    final double chartWidth = size.width - chartStart;

    final barPaint = Paint()
      ..color = kBarOtherYearColour.withValues(alpha: 0.20)
      ..style = PaintingStyle.fill;

    // --- Bars + year labels (every 5 years) ---
    for (int i = 0; i < barCount; i++) {
      final double y = i * (barHeight + barSpacing);
      final double barW = _widths[i] * chartWidth;

      // Label only on multiples of 5
      if (_years[i] % 5 == 0) {
        final tp = TextPainter(
          text: TextSpan(
            text: '${_years[i]}',
            style: const TextStyle(color: kGreyLabelColour, fontSize: 10),
          ),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: yearLabelWidth);
        tp.paint(canvas, Offset(0, y + (barHeight - tp.height) / 2));
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(chartStart, y, barW, barHeight),
          const Radius.circular(2),
        ),
        barPaint,
      );
    }

    final double avgX = chartStart + _avgFraction * chartWidth;
    final double trendTopX = chartStart + _trendTopFraction * chartWidth;
    final double trendBottomX = chartStart + _trendBottomFraction * chartWidth;

    // --- Average line (blue, vertical) ---
    final avgPaint = Paint()
      ..color = kAverageColour
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(avgX, 0), Offset(avgX, size.height), avgPaint);

    // "average" label near the top, to the LEFT of the average line
    final avgLabel = TextPainter(
      text: const TextSpan(
        text: 'average',
        style: TextStyle(
          color: kAverageColour,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    avgLabel.paint(canvas, Offset(avgX - avgLabel.width - 4, 2));

    // --- Trend line (yellow, diagonal) ---
    final trendPaint = Paint()
      ..color = kTrendLineColour
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(trendTopX, 0),
      Offset(trendBottomX, size.height),
      trendPaint,
    );

    // "trend" label near the bottom, to the LEFT of the trend line
    final trendLabel = TextPainter(
      text: const TextSpan(
        text: 'trend',
        style: TextStyle(
          color: kTrendLineColour,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    trendLabel.paint(
      canvas,
      Offset(trendBottomX - trendLabel.width - 4, size.height - trendLabel.height - 2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
