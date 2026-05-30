import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../onboarding_page.dart';
import '../visuals/average_trend_illustration.dart';

class OnboardingAverageTrendPage extends StatelessWidget {
  const OnboardingAverageTrendPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildPortrait();
  }

  Widget _buildPortrait() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 500;
          final isMedium = constraints.maxHeight < 700;
          final titleSize = isSmall ? 20.0 : (isMedium ? 22.0 : 24.0);
          final illustrationHeight = isSmall ? 160.0 : (isMedium ? 200.0 : 240.0);
          final gap = isSmall ? 16.0 : (isMedium ? 20.0 : 24.0);
          final bodySize = isSmall ? 15.0 : kFontSizeBody;
          return OnboardingScrollBody(
            constraints: constraints,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _titleWidget(fontSize: titleSize),
                SizedBox(height: gap),
                AverageTrendIllustration(height: illustrationHeight),
                SizedBox(height: gap),
                ..._legendWidgets(bodySize: bodySize),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _titleWidget({double fontSize = 24.0}) => Text(
        'Average and trend',
        style: TextStyle(
          color: kHeadingColour,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  List<Widget> _legendWidgets({double bodySize = kFontSizeBody}) => [
        Text(
          'Average: the historical mean temperature for this period.',
          style: TextStyle(
            color: kAverageColour,
            fontSize: bodySize,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Trend: shows whether temperatures are rising or falling, '
          'with the rate of change per decade shown below each chart.',
          style: TextStyle(
            color: kTrendLineColour,
            fontSize: bodySize,
            height: 1.5,
          ),
        ),
      ];
}
