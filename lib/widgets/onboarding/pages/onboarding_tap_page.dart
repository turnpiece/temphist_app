import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
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
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const TapBarIllustration(),
                    SizedBox(height: isSmall ? 16 : 32),
                    ..._textContent(isSmall: isSmall),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _textContent({required bool isSmall}) => [
        Text(
          'Tap for details',
          style: TextStyle(
            color: kHeadingColour,
            fontSize: isSmall ? 20.0 : 24.0,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: isSmall ? 8 : 12),
        Text(
          'Tap any bar to see the exact temperature recorded for that year.',
          style: TextStyle(
            color: kTextPrimaryColour,
            fontSize: isSmall ? 15.0 : kFontSizeBody,
            height: 1.5,
          ),
        ),
      ];
}
