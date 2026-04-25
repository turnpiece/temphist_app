import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../onboarding_page.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.of(context).size.height < 700 ? 80.0 : 120.0;
    return OnboardingPage(
      title: 'How does today compare\nto the same day in years past?',
      body: 'Was this week unusually warm? How about the past month or the past year? '
          'TempHist shows you decades of temperature history for any location.',
      visual: SvgPicture.asset(
        'assets/logo.svg',
        width: logoSize,
        height: logoSize,
      ),
      centerVisual: false,
    );
  }
}
