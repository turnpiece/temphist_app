import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/date_utils.dart' as date_utils;
import '../onboarding_page.dart';
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
    return _buildPortrait(date, year);
  }

  Widget _buildPortrait(String date, int year) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 500;
          final isMedium = constraints.maxHeight < 700;
          final illustrationHeight = isSmall ? 110.0 : (isMedium ? 150.0 : 180.0);
          final illustrationGap = isSmall ? 16.0 : (isMedium ? 20.0 : 24.0);
          final titleGap = isSmall ? 8.0 : (isMedium ? 10.0 : 12.0);
          return OnboardingScrollBody(
            constraints: constraints,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: _content(date, year,
                  illustrationHeight: illustrationHeight,
                  illustrationGap: illustrationGap,
                  titleGap: titleGap,
                  isSmall: isSmall),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(
    String date,
    int year, {
    required double illustrationHeight,
    required double illustrationGap,
    required double titleGap,
    required bool isSmall,
  }) =>
      [
        DayChartIllustration(height: illustrationHeight),
        SizedBox(height: illustrationGap),
        ..._textContent(date, year, isSmall: isSmall, titleGap: titleGap),
      ];

  List<Widget> _textContent(
    String date,
    int year, {
    required bool isSmall,
    required double titleGap,
  }) {
    final titleSize = isSmall ? 20.0 : 22.0;
    final bodySize = isSmall ? 15.0 : kFontSizeBody;
    return [
      Text(
        'Today in history',
        style: TextStyle(
          color: kHeadingColour,
          fontSize: titleSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      SizedBox(height: titleGap),
      Text(
        'The first screen shows today\'s date across multiple years — '
        'so on $date you\'ll see $date $year, $date ${year - 1}, '
        '$date ${year - 2} and so on. Each bar represents the mean temperature for that date.',
        style: TextStyle(
          color: kTextPrimaryColour,
          fontSize: bodySize,
          height: 1.5,
        ),
      ),
    ];
  }
}
