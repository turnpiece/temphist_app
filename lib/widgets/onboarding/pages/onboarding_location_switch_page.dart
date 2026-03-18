import 'package:flutter/material.dart';

import '../onboarding_page.dart';
import '../visuals/location_switch_illustration.dart';

class OnboardingLocationSwitchPage extends StatelessWidget {
  const OnboardingLocationSwitchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPage(
      title: 'Switch location',
      body: 'Tap the location name at the top of the screen to switch to a '
          'different city.\n\n'
          'Choose from your recently visited locations or browse popular '
          'destinations worldwide.',
      visual: LocationSwitchIllustration(),
    );
  }
}
