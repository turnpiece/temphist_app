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
    final date = _dateLabel();
    return OrientationBuilder(
      builder: (context, orientation) =>
          orientation == Orientation.landscape
              ? _buildLandscape(date)
              : _buildPortrait(date),
    );
  }

  Widget _buildPortrait(String date) {
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
                  children: [
                    _titleWidget(),
                    const SizedBox(height: 32),
                    const SwipeGestureIndicator(),
                    const SizedBox(height: 32),
                    ..._rowWidgets(date),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandscape(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleWidget(),
                  const SizedBox(height: 20),
                  const SwipeGestureIndicator(),
                ],
              ),
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _rowWidgets(date),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _titleWidget() => const Text(
        'Swipe to see more',
        style: TextStyle(
          color: kAccentColour,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  List<Widget> _rowWidgets(String date) => [
        _buildRow(Icons.today_outlined, 'Day', '$date in each year'),
        _buildRow(Icons.date_range_outlined, 'Week', 'The week ending $date in each year'),
        _buildRow(Icons.calendar_month_outlined, 'Month', 'The month ending $date in each year'),
        _buildRow(Icons.calendar_today_outlined, 'Year', 'The year ending $date in each year'),
      ];

  Widget _buildRow(IconData icon, String label, String description) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
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
