import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../visuals/tap_bar_illustration.dart';

class OnboardingTapPage extends StatelessWidget {
  const OnboardingTapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OrientationBuilder(
      builder: (context, orientation) => orientation == Orientation.landscape
          ? _buildLandscape()
          : _buildPortrait(),
    );
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
                    const TapBarIllustration(),
                    const SizedBox(height: 32),
                    ..._textContent(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLandscape() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            flex: 2,
            child: TapBarIllustration(),
          ),
          const SizedBox(width: 24),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _textContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _textContent() => [
        const Text(
          'Tap for details',
          style: TextStyle(
            color: kAccentColour,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Tap any bar to see the exact temperature recorded for that year.',
          style: TextStyle(
            color: kTextPrimaryColour,
            fontSize: kFontSizeBody,
            height: 1.5,
          ),
        ),
      ];
}
