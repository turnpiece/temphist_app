import 'package:flutter/material.dart';

import '../onboarding_page.dart';
import '../../../constants/app_constants.dart';

class OnboardingLocationPage extends StatelessWidget {
  const OnboardingLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      title: 'Location',
      body: 'TempHist uses your location to show data for the nearest '
          'weather station.\n\n'
          'Tap the location name at the top of the screen at any time to '
          'switch to a different city — including popular destinations '
          'worldwide.',
      visual: Icon(
        Icons.location_on_outlined,
        color: kAccentColour,
        size: 80,
      ),
    );
  }
}
