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
    return _buildPortrait(date, year);
  }

  Widget _buildPortrait(String date, int year) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 500;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _content(date, year, isSmall: isSmall),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _content(String date, int year, {required bool isSmall}) => [
        DayChartIllustration(height: isSmall ? 100.0 : 120.0),
        SizedBox(height: isSmall ? 16 : 24),
        ..._textContent(date, year, isSmall: isSmall),
      ];

  List<Widget> _textContent(String date, int year, {required bool isSmall}) {
    final titleSize = isSmall ? 20.0 : 24.0;
    final bodySize = isSmall ? 15.0 : kFontSizeBody;
    final gap = isSmall ? 8.0 : 12.0;
    return [
      Text(
        'Today in history',
        style: TextStyle(
          color: kAccentColour,
          fontSize: titleSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
      SizedBox(height: gap),
      Text(
        'The main screen shows today\'s date across multiple years — '
        'so on $date you\'ll see $date $year, $date ${year - 1}, '
        '$date ${year - 2} and so on.',
        style: TextStyle(
          color: kTextPrimaryColour,
          fontSize: bodySize,
          height: 1.5,
        ),
      ),
      SizedBox(height: gap),
      Text(
        'Green bar = this year.',
        style: TextStyle(color: kBarCurrentYearColour, fontSize: bodySize),
      ),
      Text(
        'Red bars = previous years.',
        style: TextStyle(color: kBarOtherYearColour, fontSize: bodySize),
      ),
    ];
  }
}
