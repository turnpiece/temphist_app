import 'package:flutter/material.dart';

import '../../constants/app_constants.dart';
import '../../services/temperature_unit_service.dart';
import 'pages/onboarding_average_trend_page.dart';
import 'pages/onboarding_day_page.dart';
import 'pages/onboarding_location_page.dart';
import 'pages/onboarding_swipe_page.dart';
import 'pages/onboarding_tap_page.dart';
import 'pages/onboarding_temperature_unit_page.dart';
import 'pages/onboarding_welcome_page.dart';

/// Full-screen onboarding flow shown on first launch.
/// Calls [onComplete] when the user taps "Get Started" or "Skip".
class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final TemperatureUnitService unitService;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.unitService,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  late final List<Widget> _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _pages = [
      const OnboardingWelcomePage(),
      const OnboardingDayPage(),
      const OnboardingTapPage(),
      const OnboardingAverageTrendPage(),
      const OnboardingSwipePage(),
      const OnboardingLocationPage(),
      OnboardingTemperatureUnitPage(unitService: widget.unitService),
    ];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
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
          child: LayoutBuilder(builder: (context, constraints) {
            final screenWidth = MediaQuery.of(context).size.width;
            final isTablet = screenWidth >= kTabletBreakpointWidth;
            final contentWidth = isTablet
                ? kTabletMaxContentWidth.clamp(0.0, constraints.maxWidth)
                : constraints.maxWidth;
            final isLandscape = MediaQuery.of(context).orientation ==
                Orientation.landscape;
            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    // Skip button — right-aligned within the content width.
                    // Always occupies its row height to keep layout stable.
                    Align(
                      alignment: Alignment.centerRight,
                      child: Opacity(
                        opacity: _currentPage < _pages.length - 1 ? 1.0 : 0.0,
                        child: TextButton(
                          onPressed: _currentPage < _pages.length - 1
                              ? widget.onComplete
                              : null,
                          child: const Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: kFontSizeBody,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // In landscape, add breathing room between skip and content.
                    if (isLandscape) const SizedBox(height: 4),
                    Expanded(
                      child: PageView(
                        controller: _controller,
                        onPageChanged: (i) {
                          if (mounted) setState(() => _currentPage = i);
                        },
                        children: _pages,
                      ),
                    ),
                    SizedBox(height: isLandscape ? 6 : 24),
                    // Dot indicators
                    _buildDots(),
                    SizedBox(height: isLandscape ? 6 : 24),
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
                            _currentPage < _pages.length - 1
                                ? 'Next'
                                : 'Get Started',
                            style: const TextStyle(
                              fontSize: kFontSizeBody,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: isLandscape ? 12 : 40),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
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
