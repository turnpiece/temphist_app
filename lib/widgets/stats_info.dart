import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../constants/app_constants.dart';
import 'help_page.dart';

/// Semantics label for the stats box info button.
const String kStatsInfoButtonLabel = 'What do these numbers mean?';

/// Plain-English notes shown when the stats box info button is expanded.
/// Kept in step with the web app's stats info note.
const String kStatsInfoAverage =
    'Average: the mean of the 51 yearly values in the chart, including this year\'s.';
const String kStatsInfoTrend =
    'Trend: how fast temperatures are changing per decade. The ± is how uncertain that figure is (one standard error). If the trend is smaller than about twice its ±, it can\'t be told apart from no trend.';
const String kStatsInfoDeviation =
    'Standard deviation: how much the yearly figures typically vary from the average.';
const String kStatsInfoMoreLink = 'More about the numbers';

/// A small "i" button for the stats box. Keeps the stats lines short while
/// still answering "what does the ± mean?" for people who want to know.
class StatsInfoButton extends StatelessWidget {
  final bool expanded;
  final VoidCallback onPressed;

  const StatsInfoButton({
    super.key,
    required this.expanded,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    // 48dp tap target around a 26dp visible circle.
    return Semantics(
      label: kStatsInfoButtonLabel,
      button: true,
      expanded: expanded,
      excludeSemantics: true,
      onTap: onPressed,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: SizedBox(
          width: 48,
          height: 48,
          child: Center(
            child: Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: expanded
                    ? kTextPrimaryColour.withValues(alpha: 0.18)
                    : Colors.transparent,
                border: Border.all(
                  color: kTextPrimaryColour.withValues(alpha: 0.6),
                ),
              ),
              child: const Text(
                'i',
                style: TextStyle(
                  color: kTextPrimaryColour,
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'serif',
                  height: 1,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The expandable note under the stats rows.
class StatsInfoNote extends StatefulWidget {
  const StatsInfoNote({super.key});

  @override
  State<StatsInfoNote> createState() => _StatsInfoNoteState();
}

class _StatsInfoNoteState extends State<StatsInfoNote> {
  late final TapGestureRecognizer _linkRecognizer;

  @override
  void initState() {
    super.initState();
    _linkRecognizer = TapGestureRecognizer()
      ..onTap =
          () => HelpPage.show(context, section: HelpSection.trendCertainty);
  }

  @override
  void dispose() {
    _linkRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: kTextPrimaryColour.withValues(alpha: 0.9),
      fontSize: kStatsFontSize - 1,
      height: 1.45,
    );
    Widget para(String text) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(text, style: style),
        );

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: kTextPrimaryColour.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          para(kStatsInfoAverage),
          para(kStatsInfoTrend),
          para(kStatsInfoDeviation),
          Semantics(
            link: true,
            child: Text.rich(
              TextSpan(
                text: kStatsInfoMoreLink,
                recognizer: _linkRecognizer,
                style: style.copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
