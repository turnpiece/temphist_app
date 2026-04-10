import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Reusable layout for a single onboarding page.
/// Portrait: visual centred above title and body.
/// Landscape: visual on the left, title and body on the right.
class OnboardingPage extends StatelessWidget {
  final String title;
  final String body;
  final Widget visual;
  final bool centerVisual;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.body,
    required this.visual,
    this.centerVisual = true,
  });

  @override
  Widget build(BuildContext context) {
    return _buildPortrait();
  }

  Widget _buildPortrait() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
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
                    if (centerVisual) Center(child: visual) else visual,
                    const SizedBox(height: 40),
                    _titleWidget(),
                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      _bodyWidget(),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleWidget() => Text(
        title,
        style: const TextStyle(
          color: kAccentColour,
          fontSize: 24,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  Widget _bodyWidget() => Text(
        body,
        style: const TextStyle(
          color: kTextPrimaryColour,
          fontSize: kFontSizeBody,
          height: 1.5,
        ),
      );
}
