import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

// Layout constants shared between the widget and painter
const double _barHeight = 10.0;
const double _barGap = 4.0;
const double _rowHeight = _barHeight + _barGap;
const double _yearLabelWidth = 32.0;
const double _labelBarGap = 8.0;
const int _startYear = 2026;
const int _barCount = 10; // 2026 → 2017
const int _tappedIndex = 7; // 2019 — near the bottom, not a multiple of 5

const List<double> _barWidths = [
  0.88,
  0.72,
  0.61,
  0.79,
  0.53,
  0.68,
  0.75,
  0.48,
  0.63,
  0.57,
];

/// Bar chart illustration for the "tap a bar" onboarding page.
/// Shows ~10 bars with a floating tooltip overlaid on one of them,
/// demonstrating the tap-to-inspect interaction.
class TapBarIllustration extends StatelessWidget {
  const TapBarIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    const double totalHeight = _barCount * _rowHeight;
    // Top of the tapped bar — the tooltip's bottom (triangle tip) sits here.
    const double tappedBarTop = _tappedIndex * _rowHeight;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxBarWidth =
            constraints.maxWidth - _yearLabelWidth - _labelBarGap;

        return SizedBox(
          height: totalHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // All bars drawn via CustomPaint — no gaps in the flow
              Positioned.fill(
                child: CustomPaint(
                  painter: _BarsPainter(maxBarWidth: maxBarWidth),
                ),
              ),
              // Tooltip overlaid on top of the bars.
              // bottom: totalHeight - tappedBarTop  →  bottom of tooltip widget
              // is at y = tappedBarTop, so the triangle tip touches the bar.
              Positioned(
                left: _yearLabelWidth + _labelBarGap + 20,
                bottom: totalHeight - tappedBarTop,
                child: const _TooltipMockup(),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  final double maxBarWidth;
  const _BarsPainter({required this.maxBarWidth});

  static const _labelStyle = TextStyle(
    color: kGreyLabelColour,
    fontSize: 10,
    fontFamilyFallback: kChartAxisFontFamilyFallback,
  );

  @override
  void paint(Canvas canvas, Size size) {
    final averageWidth = _barWidths.reduce((a, b) => a + b) / _barWidths.length;
    final maxWarmDelta = _barWidths
        .map((width) => width - averageWidth)
        .where((delta) => delta > 0)
        .fold<double>(0, (max, delta) => delta > max ? delta : max);
    final maxCoolDelta = _barWidths
        .map((width) => averageWidth - width)
        .where((delta) => delta > 0)
        .fold<double>(0, (max, delta) => delta > max ? delta : max);

    for (int i = 0; i < _barCount; i++) {
      final int year = _startYear - i;
      final double y = i * _rowHeight;
      final bool isTapped = i == _tappedIndex;
      final fillColour = _barColourForWidth(
        _barWidths[i],
        averageWidth,
        maxWarmDelta,
        maxCoolDelta,
      ).withValues(alpha: isTapped ? 0.95 : 0.85);
      final fillPaint = Paint()
        ..color = fillColour
        ..style = PaintingStyle.fill;
      final borderPaint = Paint()
        ..color = fillColour
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      // Year label — only for multiples of 5, matching the real app
      if (year % 5 == 0) {
        final tp = TextPainter(
          text: TextSpan(text: year.toString(), style: _labelStyle),
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: _yearLabelWidth);
        tp.paint(canvas, Offset(0, y + (_barHeight - tp.height) / 2));
      }

      final barRect = RRect.fromRectAndCorners(
        Rect.fromLTWH(
          _yearLabelWidth + _labelBarGap,
          y,
          _barWidths[i] * maxBarWidth,
          _barHeight,
        ),
        topRight: const Radius.circular(4),
        bottomRight: const Radius.circular(4),
      );
      canvas.drawRRect(barRect, fillPaint);
      canvas.drawRRect(barRect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BarsPainter oldDelegate) =>
      oldDelegate.maxBarWidth != maxBarWidth;
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

class _TooltipMockup extends StatelessWidget {
  const _TooltipMockup();

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              '2019: 5.8°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: kFontSizeBody - 4,
              ),
            ),
          ),
          CustomPaint(
            size: const Size(14, 7),
            painter: _DownTrianglePainter(),
          ),
        ],
      ),
    );
  }
}

class _DownTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
