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
                    SizedBox(height: isSmall ? 16 : 24),
                    AverageTrendIllustration(height: isSmall ? 160.0 : 240.0),
                    SizedBox(height: isSmall ? 16 : 24),
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

  Widget _titleWidget({double fontSize = 24.0}) => Text(
        'Average and trend',
        style: TextStyle(
          color: kAccentColour,
          fontSize: fontSize,
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
