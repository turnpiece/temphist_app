import 'package:flutter/material.dart';

import '../onboarding_page.dart';
import '../../../constants/app_constants.dart';

class OnboardingLocationPage extends StatelessWidget {
  const OnboardingLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return OnboardingPage(
      title: 'Location',
      body: 'View the temperature history of wherever you are now, all the '
          'places you\'ve been where you\'ve used the app, and also a '
          'selection of cities around the world.\n\n'
          'Tap the location name at the top of the screen at any time to '
          'switch location.',
      visual: Icon(
        Icons.location_on_outlined,
        color: kAccentColour,
        size: 80,
      ),
    );
  }
}
