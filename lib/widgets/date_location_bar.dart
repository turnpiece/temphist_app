import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/date_labels.dart';
import '../state/app_state.dart';
import '../models/explore_state.dart';

/// A horizontal bar containing DatePill and LocationPill components
/// Used as the top bar in the Weather-style navigation
class DateLocationBar extends StatelessWidget {
  final AppState appState;
  final VoidCallback? onTapLocation;
  final VoidCallback? onTapDate;

  const DateLocationBar({
    super.key,
    required this.appState,
    this.onTapLocation,
    this.onTapDate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // DatePill
          DatePill(
            date: appState.currentDate,
            period: appState.currentPeriod,
            onTap: onTapDate,
          ),
          const SizedBox(width: 12),
          // LocationPill
          LocationPill(
            city: appState.currentCityName,
            hasMultipleLocations: appState.hasMultipleLocations,
            onTap: appState.hasMultipleLocations ? onTapLocation : null,
          ),
        ],
      ),
    );
  }
}

/// A pill-shaped widget that displays the current date based on period
class DatePill extends StatelessWidget {
  final DateTime date;
  final ExplorePeriod period;
  final VoidCallback? onTap;

  const DatePill({
    super.key,
    required this.date,
    required this.period,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _getDateLabel();
    final semanticsLabel = _getSemanticsLabel();

    return Semantics(
      label: semanticsLabel,
      button: onTap != null,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textScaler: MediaQuery.textScalerOf(context),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
    );
  }

  String _getDateLabel() {
    switch (period) {
      case ExplorePeriod.day:
        return DateLabels.formatDayLabel(date);
      case ExplorePeriod.week:
        return DateLabels.formatWeekToLabel(date);
      case ExplorePeriod.month:
        return DateLabels.formatMonthToLabel(date);
    }
  }

  String _getSemanticsLabel() {
    final fullDate = DateFormat('EEEE, MMMM d, y').format(date);
    switch (period) {
      case ExplorePeriod.day:
        return 'Day view for $fullDate';
      case ExplorePeriod.week:
        return 'Week view ending $fullDate';
      case ExplorePeriod.month:
        return 'Month view ending $fullDate';
    }
  }
}

/// A pill-shaped widget that displays the current city name
class LocationPill extends StatelessWidget {
  final String city;
  final bool hasMultipleLocations;
  final VoidCallback? onTap;

  const LocationPill({
    super.key,
    required this.city,
    required this.hasMultipleLocations,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Location: $city${hasMultipleLocations ? ', tap to change location' : ''}',
      button: onTap != null,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  city,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  textScaler: MediaQuery.textScalerOf(context),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              if (hasMultipleLocations) ...[
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
