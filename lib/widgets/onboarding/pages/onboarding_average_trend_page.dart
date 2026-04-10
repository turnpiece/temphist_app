import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../visuals/average_trend_illustration.dart';

class OnboardingAverageTrendPage extends StatelessWidget {
  const OnboardingAverageTrendPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Always use the stacked portrait layout — gives the illustration full
    // content width and uses vertical space effectively even in landscape.
    return _buildPortrait();
  }

  Widget _buildPortrait() {
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
                    const SizedBox(height: 24),
                    const AverageTrendIllustration(),
                    const SizedBox(height: 24),
                    ..._legendWidgets(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleWidget() => const Text(
        'Average and trend',
        style: TextStyle(
          color: kAccentColour,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  List<Widget> _legendWidgets() => [
        const Text(
          'Average: the historical mean temperature for this date.',
          style: TextStyle(
            color: kAverageColour,
            fontSize: kFontSizeBody,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Trend: shows whether temperatures are rising or falling over the years.',
          style: TextStyle(
            color: kTrendLineColour,
            fontSize: kFontSizeBody,
            height: 1.5,
          ),
        ),
      ];
}
