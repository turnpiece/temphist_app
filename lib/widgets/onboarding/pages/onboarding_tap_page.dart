import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../onboarding_page.dart';
import '../visuals/tap_bar_illustration.dart';

class OnboardingTapPage extends StatelessWidget {
  const OnboardingTapPage({super.key});

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
          final gap = isSmall ? 16.0 : (isMedium ? 24.0 : 32.0);
          final bodySize = isSmall ? 15.0 : kFontSizeBody;
          return OnboardingScrollBody(
            constraints: constraints,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TapBarIllustration(),
                SizedBox(height: gap),
                ..._textContent(titleSize: titleSize, bodySize: bodySize),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _textContent({required double titleSize, required double bodySize}) => [
        Text(
          'Tap for details',
          style: TextStyle(
            color: kHeadingColour,
            fontSize: titleSize,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Tap any bar to see the exact temperature recorded for that year.',
          style: TextStyle(
            color: kTextPrimaryColour,
            fontSize: bodySize,
            height: 1.5,
          ),
        ),
      ];
}
