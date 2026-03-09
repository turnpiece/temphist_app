import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Reusable layout for a single onboarding page.
/// Portrait: visual centred above title and body.
/// Landscape: visual on the left, title and body on the right.
class OnboardingPage extends StatelessWidget {
  final String title;
  final String body;
  final Widget visual;

  const OnboardingPage({
    super.key,
    required this.title,
    required this.body,
    required this.visual,
  });

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
                    Center(child: visual),
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

  Widget _buildLandscape() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Center(child: visual),
          ),
          const SizedBox(width: 32),
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _titleWidget(),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _bodyWidget(),
                  ],
                ],
              ),
            ),
          ),
        ],
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
