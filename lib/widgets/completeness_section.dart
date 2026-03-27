import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// Formats a sorted list of year integers into a compact ranges string.
/// e.g. [1982] → "1982", [1981, 1982, 1983] → "1981–1983",
/// [1981, 1982, 1990] → "1981–1982, 1990".
String formatMissingYearsList(List<int> years) {
  if (years.isEmpty) return '';
  final sorted = [...years]..sort();
  final ranges = <List<int>>[];
  var current = [sorted.first];
  for (int i = 1; i < sorted.length; i++) {
    if (sorted[i] == current.last + 1) {
      current.add(sorted[i]);
    } else {
      ranges.add(current);
      current = [sorted[i]];
    }
  }
  ranges.add(current);
  return ranges
      .map((r) => r.length == 1 ? '${r.first}' : '${r.first}–${r.last}')
      .join(', ');
}

/// Detects years in the expected rolling 50-year window that are entirely
/// absent from the API response and not already accounted for in [metaMissing].
List<int> detectAbsentYears(Set<int> loadedYears, List<int> metaMissing) {
  final currentYear = DateTime.now().year;
  final apiStartYear = currentYear - 50;
  return List.generate(currentYear - apiStartYear, (i) => apiStartYear + i)
      .where((y) => !loadedYears.contains(y) && !metaMissing.contains(y))
      .toList();
}

/// Shared completeness note used on both the daily and period screens.
///
/// Layout matches [_buildChartDataFailureMessage] on the daily screen:
/// an error row with icon, message, and an inline Retry button, followed
/// by the missing-years note and completeness percentage beneath.
///
/// When [onRetry] is null (e.g. the daily screen's _chartDataFailed path,
/// where a separate widget handles the error row) only the note and
/// completeness lines are shown.
class CompletenessSection extends StatelessWidget {
  final List<int> allMissing;
  final double completeness;

  /// Called when the user taps Retry. If null, no error row or button is shown.
  final VoidCallback? onRetry;

  /// When true, shows a "Retrying…" state instead of the Retry button.
  final bool isRetrying;

  /// If > 0, shows a "Retry attempts: N" line.
  final int retryCount;

  /// Optional override for the note text. When set this replaces the
  /// auto-generated "Data for X could not be loaded." line.
  final String? noteText;

  const CompletenessSection({
    super.key,
    required this.allMissing,
    required this.completeness,
    this.onRetry,
    this.isRetrying = false,
    this.retryCount = 0,
    this.noteText,
  });

  @override
  Widget build(BuildContext context) {
    if (allMissing.isEmpty && completeness >= 100 && noteText == null) {
      return const SizedBox.shrink();
    }

    final note = noteText ??
        (allMissing.isNotEmpty
            ? 'Note: Data for ${formatMissingYearsList(allMissing)} could not be loaded.'
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Error row — shown when a retry is possible or one is in progress.
        // Matches the inline layout of _buildChartDataFailureMessage.
        if (onRetry != null || isRetrying)
          Row(
            children: [
              Icon(
                isRetrying ? Icons.hourglass_empty : Icons.error_outline,
                color: isRetrying ? kGreyLabelColour : kAccentColour,
                size: kIconSize,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isRetrying
                      ? 'Retrying…'
                      : 'Failed to load some chart data.',
                  style: TextStyle(
                    color: isRetrying ? kGreyLabelColour : kAccentColour,
                    fontSize: kFontSizeBody - 1,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Keep the button in the layout at all times to prevent height
              // shift when switching between idle and retrying states.
              Opacity(
                opacity: isRetrying ? 0.0 : 1.0,
                child: IgnorePointer(
                  ignoring: isRetrying,
                  child: GestureDetector(
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: kAccentColour.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: kAccentColour,
                          fontSize: kFontSizeBody - 2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (note != null) ...[
          const SizedBox(height: 4),
          Text(
            note,
            style: const TextStyle(
              color: kGreyLabelColour,
              fontSize: kFontSizeBody - 2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        if (completeness < 80) ...[
          const SizedBox(height: 4),
          Text(
            'Data completeness: ${completeness.toStringAsFixed(0)}%',
            style: const TextStyle(
              color: kGreyLabelColour,
              fontSize: kFontSizeBody - 2,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
        if (retryCount > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Retry attempts: $retryCount',
            style: const TextStyle(
              color: kGreyLabelColour,
              fontSize: kFontSizeBody - 3,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ],
    );
  }
}
