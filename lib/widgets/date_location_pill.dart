import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A pill-shaped widget that displays the current date and location
/// Format: EEE d MMM • {city}
class DateLocationPill extends StatefulWidget {
  final DateTime date;
  final String? city;
  final bool isLoading;
  final VoidCallback? onLocationChange;

  const DateLocationPill({
    super.key,
    required this.date,
    this.city,
    this.isLoading = false,
    this.onLocationChange,
  });

  @override
  State<DateLocationPill> createState() => _DateLocationPillState();
}

class _DateLocationPillState extends State<DateLocationPill>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = IntTween(begin: 1, end: 4).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    if (widget.isLoading) {
      _animationController.repeat();
    }
  }

  @override
  void didUpdateWidget(DateLocationPill oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isLoading && !oldWidget.isLoading) {
      _animationController.repeat();
    } else if (!widget.isLoading && oldWidget.isLoading) {
      _animationController.stop();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final day = widget.date.day;
    final month = DateFormat('MMMM').format(widget.date);
    final formattedDate = '$day${_getOrdinalSuffix(day)} $month';
    
    // Create accessible semantics label
    final fullWeekday = DateFormat('EEEE').format(widget.date);
    final fullMonth = DateFormat('MMMM').format(widget.date);
    final semanticsLabel = widget.isLoading 
        ? '$fullWeekday $day $fullMonth, determining location'
        : '$fullWeekday $day $fullMonth, ${widget.city ?? 'Current location'}';

    return Semantics(
      label: semanticsLabel,
      button: widget.onLocationChange != null,
      onTap: widget.onLocationChange,
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
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            final ellipsisCount = _animation.value;
            final ellipsis = '.' * ellipsisCount;
            final displayCity = widget.isLoading 
                ? '$ellipsis'
                : (widget.city ?? 'Current location');
            
            return Text(
              '$formattedDate • $displayCity',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              textScaler: MediaQuery.textScalerOf(context),
            );
          },
        ),
      ),
    );
  }

  /// Get the ordinal suffix for a day number (1st, 2nd, 3rd, 4th, etc.)
  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }
}
