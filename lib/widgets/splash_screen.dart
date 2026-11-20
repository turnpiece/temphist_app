import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_constants.dart';
import 'gradient_spinner.dart';

/// Size of the logo mark on the splash screen, in logical pixels.
///
/// The native iOS launch image (ios/Runner/Assets.xcassets/LaunchImage) draws
/// the same bars at this size, centred on screen, so the hand-off from the
/// native launch screen to this widget doesn't move the logo. Change both
/// together.
const Size kSplashLogoSize = Size(99, 84);

/// Splash screen displayed during app initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kBackgroundColour,
              kBackgroundColourDark,
            ],
          ),
        ),
        // The logo sits at the exact centre of the screen, where the native
        // launch image drew it; the title and spinner hang below it.
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              SvgPicture.asset(
                'assets/logo_mark.svg',
                width: kSplashLogoSize.width,
                height: kSplashLogoSize.height,
              ),
              Positioned(
                top: kSplashLogoSize.height + 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      kAppTitle,
                      style: TextStyle(
                        color: kHeadingColour,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const GradientSpinner.data(size: 56),
                    const SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: kTextPrimaryColour,
                        fontSize: kFontSizeBody,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
