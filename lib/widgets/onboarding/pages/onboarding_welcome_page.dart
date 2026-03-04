import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../onboarding_page.dart';

class OnboardingWelcomePage extends StatelessWidget {
  const OnboardingWelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      title: 'How does today compare\nto years past?',
      body: 'TempHist shows you temperature history for your location — '
          'same day, week, month and year — going back decades.',
      visual: SvgPicture.asset(
        'assets/logo.svg',
        width: 120,
        height: 120,
      ),
    );
  }
}
