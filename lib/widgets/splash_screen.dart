import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_constants.dart';
import 'gradient_spinner.dart';

/// Size of the logo mark on the splash screen, in logical pixels.
///
/// The logo's left edge lines up with the left edge of the centred title, as
/// the logo itself is left-aligned. The native iOS launch image
/// (ios/Runner/Assets.xcassets/LaunchImage) is the title's width (162.67pt)
/// and draws the same bars at this size 2pt in from its left edge, centred on
/// screen, so the hand-off from the native launch screen to this widget
/// doesn't move the logo. Change both together.
const Size kSplashLogoSize = Size(99, 84);

/// Splash screen displayed during app initialization
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  static const TextStyle _titleStyle = TextStyle(
    color: kHeadingColour,
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: 1.2,
  );

  @override
  Widget build(BuildContext context) {
    // The title isn't scaled with the system text size, so its width (and so
    // the logo's position) always matches the native launch image.
    final titleWidth = (TextPainter(
      text: TextSpan(
        text: kAppTitle,
        style: DefaultTextStyle.of(context).style.merge(_titleStyle),
      ),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout())
        .width;

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
        // A title-wide box at the exact centre of the screen, where the native
        // launch image drew it, holds the logo against its left edge; the
        // title and spinner hang below it, centred.
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              SizedBox(
                width: titleWidth,
                height: kSplashLogoSize.height,
                child: Container(
                  alignment: Alignment.centerLeft,
                  // The "T" is drawn about 2pt inside the title's box (its
                  // side bearing); line the bars up with the visible T.
                  padding: const EdgeInsets.only(left: 2),
                  child: SvgPicture.asset(
                    'assets/logo_mark.svg',
                    width: kSplashLogoSize.width,
                    height: kSplashLogoSize.height,
                  ),
                ),
              ),
              Positioned(
                top: kSplashLogoSize.height + 32,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      kAppTitle,
                      style: _titleStyle,
                      textScaler: TextScaler.noScaling,
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
