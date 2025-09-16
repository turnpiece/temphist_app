import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A pill-shaped widget that displays the current date and location
/// Format: EEE d MMM • {city}
class DateLocationPill extends StatelessWidget {
  final DateTime date;
  final String? city;
  final VoidCallback? onLocationChange;

  const DateLocationPill({
    super.key,
    required this.date,
    this.city,
    this.onLocationChange,
  });

  @override
  Widget build(BuildContext context) {
    final displayCity = city ?? 'Current location';
    final dateFormat = DateFormat('EEE d MMM');
    final formattedDate = dateFormat.format(date);
    
    // Create accessible semantics label
    final fullWeekday = DateFormat('EEEE').format(date);
    final fullMonth = DateFormat('MMMM').format(date);
    final day = date.day;
    final semanticsLabel = '$fullWeekday $day $fullMonth, $displayCity';

    return Semantics(
      label: semanticsLabel,
      button: onLocationChange != null,
      onTap: onLocationChange,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Text(
          '$formattedDate • $displayCity',
          style: TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textScaler: MediaQuery.textScalerOf(context),
        ),
      ),
    );
  }
}
