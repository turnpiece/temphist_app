import 'package:flutter/material.dart';

import '../onboarding_page.dart';
import '../../../constants/app_constants.dart';

class OnboardingLocationPage extends StatelessWidget {
  const OnboardingLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      title: 'Your local weather history',
      body: 'TempHist uses your location to show data for the nearest '
          'weather station.\n\n'
          'You can always see which location is being used at the top of the screen.',
      visual: Icon(
        Icons.location_on_outlined,
        color: kAccentColour,
        size: 80,
      ),
    );
  }
}
