import 'package:flutter/material.dart';

import '../onboarding_page.dart';
import '../../../constants/app_constants.dart';

class OnboardingLocationPage extends StatelessWidget {
  const OnboardingLocationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final iconSize = constraints.maxHeight < 500 ? 60.0 : 80.0;
        return OnboardingPage(
          title: 'Location',
          body: 'View the temperature history of wherever you are now, all the '
              'places you\'ve been, or any city in the world — just search by '
              'name.\n\n'
              'Tap the location name at the top of the screen at any time to '
              'switch location.',
          visual: Icon(
            Icons.location_on_outlined,
            color: kAccentColour,
            size: iconSize,
          ),
        );
      },
    );
  }
}
