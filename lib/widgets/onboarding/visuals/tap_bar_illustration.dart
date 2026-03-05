import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Illustration for the "tap a bar" onboarding page.
/// Shows a small horizontal bar chart with a tooltip floating above one
/// of the bars to demonstrate the tap-to-inspect interaction.
class TapBarIllustration extends StatelessWidget {
  const TapBarIllustration({super.key});

  static const List<String> _years = ['2026', '2025', '2024', '2023', '2022'];
  static const List<double> _widths = [0.85, 0.65, 0.50, 0.78, 0.42];
  static const int _tappedIndex = 2; // 2024

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double yearLabelWidth = 36.0;
        const double gap = 8.0;
        const double barHeight = 15.0;
        const double barVerticalPadding = 3.0;
        final double maxBarWidth = constraints.maxWidth - yearLabelWidth - gap;

        final List<Widget> rows = [];

        for (int i = 0; i < _years.length; i++) {
          final bool isCurrent = i == 0;
          final bool isTapped = i == _tappedIndex;

          if (isTapped) {
            // Insert tooltip directly above this bar
            rows.add(
              Padding(
                padding: const EdgeInsets.only(left: yearLabelWidth + gap),
                child: const _TooltipMockup(),
              ),
            );
          }

          rows.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: barVerticalPadding),
              child: Row(
                children: [
                  SizedBox(
                    width: yearLabelWidth,
                    child: Text(
                      _years[i],
                      style: const TextStyle(
                        color: kGreyLabelColour,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: gap),
                  Container(
                    width: _widths[i] * maxBarWidth,
                    height: barHeight,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? kBarCurrentYearColour.withOpacity(0.9)
                          : kBarOtherYearColour.withOpacity(isTapped ? 1.0 : 0.85),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
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
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1C1C3A),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              '2024: 7.1°C',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w500,
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
      ..color = const Color(0xFF1C1C3A)
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
