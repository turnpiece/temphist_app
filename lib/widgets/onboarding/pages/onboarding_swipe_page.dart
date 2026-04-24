import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../../../utils/date_utils.dart' as date_utils;
import '../visuals/swipe_gesture_indicator.dart';

class OnboardingSwipePage extends StatelessWidget {
  const OnboardingSwipePage({super.key});

  /// Returns the display date string, respecting the early-morning yesterday threshold.
  String _dateLabel() {
    final now = DateTime.now();
    final useYesterday = now.hour < kUseYesterdayHourThreshold;
    final date = useYesterday ? now.subtract(const Duration(days: 1)) : now;
    return date_utils.formatDateWithOrdinal(date);
  }

  @override
  Widget build(BuildContext context) {
    // Always use the stacked portrait layout — the side-by-side landscape
    // layout gives the swipe indicator too little horizontal room and triggers
    // an overflow warning on narrow devices / constrained columns.
    return _buildContent(_dateLabel());
  }

  Widget _buildContent(String date) {
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
                  children: [
                    _titleWidget(fontSize: isSmall ? 20.0 : 24.0),
                    SizedBox(height: isSmall ? 20 : 32),
                    const SwipeGestureIndicator(),
                    SizedBox(height: isSmall ? 20 : 32),
                    ..._rowWidgets(date, isSmall: isSmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleWidget({double fontSize = 24.0}) => Text(
        'Swipe to see more',
        style: TextStyle(
          color: kAccentColour,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  List<Widget> _rowWidgets(String date, {required bool isSmall}) => [
        _buildRow(Icons.today_outlined, 'Day', '$date in each year', isSmall: isSmall),
        _buildRow(Icons.date_range_outlined, 'Week', 'The week ending $date in each year', isSmall: isSmall),
        _buildRow(Icons.calendar_month_outlined, 'Month', 'The month ending $date in each year', isSmall: isSmall),
        _buildRow(Icons.calendar_today_outlined, 'Year', 'The year ending $date in each year', isSmall: isSmall),
      ];

  Widget _buildRow(IconData icon, String label, String description, {required bool isSmall}) {
    final rowPadding = isSmall ? 6.0 : 10.0;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2.0),
            child: Icon(icon, color: kAccentColour, size: kIconSize + 2),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextPrimaryColour,
                    fontSize: kFontSizeBody,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    color: kGreyLabelColour,
                    fontSize: 14,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
