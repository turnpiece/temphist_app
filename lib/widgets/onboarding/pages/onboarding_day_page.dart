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
    return OrientationBuilder(
      builder: (context, orientation) =>
          orientation == Orientation.landscape
              ? _buildLandscape(date, year)
              : _buildPortrait(date, year),
    );
  }

  Widget _buildPortrait(String date, int year) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _content(date, year),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandscape(String date, int year) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: DayChartIllustration(),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _textContent(date, year),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(String date, int year) => [
        const DayChartIllustration(),
        const SizedBox(height: 24),
        ..._textContent(date, year),
      ];

  List<Widget> _textContent(String date, int year) => [
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
      ];
}
