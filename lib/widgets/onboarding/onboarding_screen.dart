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

            // On tablets the PageView is given a fixed height so the dots and
            // button follow naturally beneath the content.  The whole group is
            // then centred vertically by the parent Column, keeping it away
            // from the bottom edge on large screens.
            //
            // The height is derived from what's available after the skip-button
            // row (~48 px) and the controls below the PageView (spacing + dots
            // + spacing + button + bottom breathing room ≈ 170–180 px).
            final double tabletPageViewHeight = isLandscape
                ? ((constraints.maxHeight - 48) * 0.52).clamp(200.0, 380.0)
                : ((constraints.maxHeight - 48) * 0.58).clamp(300.0, 540.0);

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
                    if (isTablet)
                      // Tablet: fixed-height PageView; the Column centres the
                      // whole group (content + dots + button) vertically.
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(height: tabletPageViewHeight, child: pageView),
                            SizedBox(height: isLandscape ? 6 : 20),
                            _buildDots(),
                            SizedBox(height: isLandscape ? 12 : 28),
                            _buildNextButton(),
                            SizedBox(height: isLandscape ? 16 : 48),
                          ],
                        ),
                      )
                    else ...[
                      // Phone: PageView fills remaining space; dots and button
                      // sit at the bottom.
                      if (isLandscape) const SizedBox(height: 4),
                      Expanded(child: pageView),
                      SizedBox(height: isLandscape ? 6 : 20),
                      _buildDots(),
                      SizedBox(height: isLandscape ? 12 : 28),
                      _buildNextButton(),
                      SizedBox(height: isLandscape ? 12 : 40),
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
