import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/date_utils.dart' as date_utils;
import '../visuals/day_chart_illustration.dart';

class OnboardingDayPage extends StatelessWidget {
  const OnboardingDayPage({super.key});

  String _dateLabel() {
    final now = DateTime.now();
    final useYesterday = now.hour < kUseYesterdayHourThreshold;
    final date = useYesterday ? now.subtract(const Duration(days: 1)) : now;
    return date_utils.formatDateWithOrdinal(date);
  }

  @override
  Widget build(BuildContext context) {
    final date = _dateLabel();
    final year = DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DayChartIllustration(),
          const SizedBox(height: 24),
          const Text(
            'Today in history',
            style: TextStyle(
              color: kAccentColour,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'The main screen shows today\'s date across multiple years — '
            'so on $date you\'ll see $date $year, $date ${year - 1}, '
            '$date ${year - 2} and so on.',
            style: const TextStyle(
              color: kTextPrimaryColour,
              fontSize: kFontSizeBody,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Green bar = this year.',
            style: TextStyle(color: kBarCurrentYearColour, fontSize: kFontSizeBody),
          ),
          const Text(
            'Red bars = previous years.',
            style: TextStyle(color: kBarOtherYearColour, fontSize: kFontSizeBody),
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Bar pushed down so the tooltip triangle overlaps its top edge
              Padding(
                padding: const EdgeInsets.only(top: 38),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: kBarOtherYearColour,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'Tap a bar to view the exact temperature.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: kFontSizeBody,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Tooltip sits on top; its triangle's bottom half overlaps the bar
              const _TooltipMockup(),
            ],
          ),
        ],
      ),
    );
  }
}

/// Replica of the in-app bar tap tooltip.
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
              '1994: 4.3°C',
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
