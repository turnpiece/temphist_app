import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import 'pages/onboarding_average_trend_page.dart';
import 'pages/onboarding_day_page.dart';
import 'pages/onboarding_location_page.dart';
import 'pages/onboarding_swipe_page.dart';
import 'pages/onboarding_welcome_page.dart';

/// Full-screen onboarding flow shown on first launch.
/// Calls [onComplete] when the user taps "Get Started" or "Skip".
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  int _currentPage = 0;

  static const int _pageCount = 5;
  static const List<Widget> _pages = [
    OnboardingWelcomePage(),
    OnboardingDayPage(),
    OnboardingAverageTrendPage(),
    OnboardingSwipePage(),
    OnboardingLocationPage(),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pageCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackgroundColour, kBackgroundColourDark],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip row
              SizedBox(
                height: 48,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _currentPage < _pageCount - 1
                      ? TextButton(
                          onPressed: widget.onComplete,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: kGreyLabelColour,
                              fontSize: kFontSizeBody,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
              // Pages
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  children: _pages,
                ),
              ),
              const SizedBox(height: 24),
              // Dot indicators
              _buildDots(),
              const SizedBox(height: 24),
              // Next / Get Started button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _next,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColour,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage < _pageCount - 1 ? 'Next' : 'Get Started',
                      style: const TextStyle(
                        fontSize: kFontSizeBody,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pageCount, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? 10 : 8,
          height: active ? 10 : 8,
          decoration: BoxDecoration(
            color: active ? kBarCurrentYearColour : kGreyLabelColour,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
