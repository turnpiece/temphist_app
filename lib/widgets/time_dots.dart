import 'package:flutter/material.dart';
import '../state/app_state.dart';

/// A horizontal strip of dots indicating the current time context position
/// Used at the bottom of the Weather-style navigation
class TimeDots extends StatelessWidget {
  final int totalCount;
  final int activeIndex;
  final AppState appState;
  final VoidCallback? onDotTap;

  const TimeDots({
    super.key,
    required this.totalCount,
    required this.activeIndex,
    required this.appState,
    this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalCount, (index) {
          // Reverse the index so Today (index 0) appears on the right
          final reversedIndex = totalCount - 1 - index;
          final isActive = reversedIndex == activeIndex;
          final contextName = _getContextName(reversedIndex);
          
          return _buildDot(
            context: context,
            index: reversedIndex,
            isActive: isActive,
            contextName: contextName,
          );
        }),
      ),
    );
  }

  /// Build an individual dot
  Widget _buildDot({
    required BuildContext context,
    required int index,
    required bool isActive,
    required String contextName,
  }) {
    return Semantics(
      label: '$contextName, ${index + 1} of $totalCount',
      button: onDotTap != null,
      onTap: onDotTap != null ? () => _handleDotTap(index) : null,
      child: GestureDetector(
        onTap: onDotTap != null ? () => _handleDotTap(index) : null,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: isActive ? 12 : 8,
            height: isActive ? 12 : 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive 
                ? Colors.white 
                : Colors.white.withValues(alpha: 0.4),
              border: isActive 
                ? Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1)
                : null,
            ),
          ),
        ),
      ),
    );
  }

  /// Handle dot tap (for future tap-to-jump functionality)
  void _handleDotTap(int index) {
    if (onDotTap != null && index != activeIndex) {
      onDotTap!();
      // Future: Could implement direct navigation to specific context
      // appState.setTimeContextIndex(index);
    }
  }

  /// Get the context name for accessibility
  String _getContextName(int index) {
    switch (index) {
      case 0: return 'Today';
      case 1: return 'Yesterday';
      case 2: return 'Two days ago';
      case 3: return 'Three days ago';
      case 4: return 'Four days ago';
      case 5: return 'Five days ago';
      case 6: return 'Six days ago';
      case 7: return 'Past week';
      case 8: return 'Past month';
      default: return 'Unknown';
    }
  }
}
