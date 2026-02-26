import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_constants.dart';

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
        child: Center(
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo
                Transform.translate(
                  offset: const Offset(-30.0, 0.0),
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    width: 150,
                    height: 150,
                  ),
                ),
                const SizedBox(height: 24),
                // App title
                Text(
                  kAppTitle,
                  style: TextStyle(
                    color: kAccentColour,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // Loading indicator
                const CircularProgressIndicator(
                  color: kAccentColour,
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                // Loading text
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
        ),
      ),
    );
  }
}
