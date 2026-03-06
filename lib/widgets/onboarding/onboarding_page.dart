import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';

/// Reusable layout for a single onboarding page.
/// Shows [visual] at top (centred), then [title] and [body] below.
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
                  Text(
                    title,
                    style: const TextStyle(
                      color: kAccentColour,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (body.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      body,
                      style: const TextStyle(
                        color: kTextPrimaryColour,
                        fontSize: kFontSizeBody,
                        height: 1.5,
                      ),
                    ),
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
}
