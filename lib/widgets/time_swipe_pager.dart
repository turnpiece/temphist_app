import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../state/app_state.dart';

/// A horizontal pager for controlling time contexts
/// Supports swiping between Today, D-1, D-2, ..., D-6, PastWeek, PastMonth
class TimeSwipePager extends StatefulWidget {
  final AppState appState;
  final Widget Function(BuildContext context, int index) pageBuilder;

  const TimeSwipePager({
    super.key,
    required this.appState,
    required this.pageBuilder,
  });

  @override
  State<TimeSwipePager> createState() => _TimeSwipePagerState();
}

class _TimeSwipePagerState extends State<TimeSwipePager> {
  late PageController _pageController;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.appState.timeContextIndex);
    _previousIndex = widget.appState.timeContextIndex;
  }

  @override
  void didUpdateWidget(TimeSwipePager oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Sync page controller with app state changes
    if (widget.appState.timeContextIndex != _previousIndex) {
      _pageController.animateToPage(
        widget.appState.timeContextIndex,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _previousIndex = widget.appState.timeContextIndex;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _pageController,
      onPageChanged: _onPageChanged,
      itemCount: widget.appState.maxTimeContextIndex + 1,
      reverse: true, // Reverse the PageView so swipe right goes forward in time
      itemBuilder: (context, index) {
        return widget.pageBuilder(context, index);
      },
    );
  }

  void _onPageChanged(int index) {
    // Prevent swiping left beyond Today (index 0)
    if (index < 0) {
      _pageController.animateToPage(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }

    // Prevent swiping right beyond PastMonth (max index)
    if (index > widget.appState.maxTimeContextIndex) {
      _pageController.animateToPage(
        widget.appState.maxTimeContextIndex,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
      return;
    }

    // Check if we're entering an aggregate page (PastWeek/PastMonth)
    final isEnteringAggregate = index >= 7 && _previousIndex < 7;
    
    // Update app state
    widget.appState.setTimeContextIndex(index);
    
    // Trigger haptic feedback for aggregate pages
    if (isEnteringAggregate) {
      HapticFeedback.lightImpact();
    }
    
    _previousIndex = index;
  }
}

/// A simple page widget for testing the pager
class TimeContextPage extends StatelessWidget {
  final int index;
  final String contextName;
  final DateTime date;
  final String period;

  const TimeContextPage({
    super.key,
    required this.index,
    required this.contextName,
    required this.date,
    required this.period,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            contextName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Date: ${date.day}/${date.month}/${date.year}',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Period: $period',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Index: $index',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.white54,
            ),
          ),
        ],
      ),
    );
  }
}
