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

            // On tablets the PageView is given a fixed height that fills most
            // of the screen.  Content starts just below the skip button; the
            // dots + next-button group is pinned to the bottom of the remaining
            // space via an Expanded + Align(bottomCenter).
            //
            // Using 72 % of available height in landscape and 70 % in portrait
            // ensures even the tallest page (Average & Trend, ~440 px) fits
            // without scrolling on all current iPad sizes.
            final double tabletPageViewHeight = isLandscape
                ? ((constraints.maxHeight - 48) * 0.72).clamp(200.0, 560.0)
                : ((constraints.maxHeight - 48) * 0.70).clamp(300.0, 660.0);

            final skipButton = Align(
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
            );

            final pageView = PageView(
              controller: _controller,
              onPageChanged: (i) {
                if (mounted) setState(() => _currentPage = i);
              },
              children: _pages,
            );

            return Center(
              child: SizedBox(
                width: contentWidth,
                child: Column(
                  children: [
                    // Skip always at the top, within the constrained width.
                    skipButton,
                    if (isTablet) ...[
                      // Tablet: large fixed-height PageView sits near the top;
                      // dots + button are pinned to the bottom of the remaining
                      // space so the button always appears low on the screen.
                      SizedBox(height: tabletPageViewHeight, child: pageView),
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildDots(isTablet: true),
                              SizedBox(height: isLandscape ? 12 : 28),
                              _buildNextButton(),
                              SizedBox(height: isLandscape ? 32 : 48),
                            ],
                          ),
                        ),
                      ),
                    ]
                    else ...[
                      // Phone: PageView fills remaining space; dots and button
                      // sit at the bottom.
                      // On small screens (iPhone SE: ~647px available) the
                      // bottom controls are tightened so the PageView gets
                      // more room and content is less likely to be clipped.
                      if (isLandscape) const SizedBox(height: 4),
                      Expanded(child: pageView),
                      SizedBox(height: isLandscape ? 16 : (constraints.maxHeight < 700 ? 12 : 48)),
                      _buildDots(),
                      SizedBox(height: isLandscape ? 12 : (constraints.maxHeight < 700 ? 10 : 28)),
                      _buildNextButton(),
                      SizedBox(height: isLandscape ? 6 : (constraints.maxHeight < 700 ? 10 : 20)),
                    ],
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildNextButton() {
    return Padding(
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
            _currentPage < _pages.length - 1 ? 'Next' : 'Get Started',
            style: const TextStyle(
              fontSize: kFontSizeBody,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDots({bool isTablet = false}) {
    final double activeSize = isTablet ? 14 : 10;
    final double inactiveSize = isTablet ? 11 : 8;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pages.length, (i) {
        final active = i == _currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: active ? activeSize : inactiveSize,
          height: active ? activeSize : inactiveSize,
          decoration: BoxDecoration(
            color: active ? kBarCurrentYearColour : kGreyLabelColour,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}
