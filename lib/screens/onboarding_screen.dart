import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart'; // Import for color constants

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _completeOnboarding() {
    // Call the callback immediately
    widget.onComplete();
    
    // Handle SharedPreferences asynchronously
    _saveOnboardingSeen();
  }

  Future<void> _saveOnboardingSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              kBackgroundColour, // Top color
              kBackgroundColourDark, // Bottom color
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
          children: [
            // Page indicator
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index 
                          ? kAccentColour
                          : kGreyLabelColour.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }),
              ),
            ),
            
            // PageView with slides
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                children: [
                  _buildWelcomeSlide(context),
                  _buildSlide(
                    context,
                    'Swipe to explore previous days.',
                    Icons.swipe,
                    'Navigate through different dates to see how temperatures have changed over time.',
                  ),
                  _buildSlide(
                    context,
                    'Privacy: We only use your location while you use the app.',
                    Icons.location_on,
                    'Your location data is only used to fetch temperature information and is not stored or shared.',
                  ),
                ],
              ),
            ),
            
            // Navigation buttons
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Previous button (only show if not on first page)
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: _previousPage,
                      style: TextButton.styleFrom(
                        foregroundColor: kTextPrimaryColour,
                      ),
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox(width: 80), // Spacer for alignment
                  
                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColour,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Get Started' : 'Next',
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

  Widget _buildWelcomeSlide(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Logo and title on the same line
          Row(
            children: [
              // App logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: kAccentColour.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: SvgPicture.asset(
                    'assets/logo.svg',
                    colorFilter: const ColorFilter.mode(
                      kAccentColour,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              // App title
              Expanded(
                child: Text(
                  kAppTitle,
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: kAccentColour,
                    fontSize: 32,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 40),
          
          // Welcome message
          Text(
            'See how today compares to past decades.',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: kTextPrimaryColour,
            ),
            textAlign: TextAlign.left,
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            'Discover temperature patterns and trends over the years with our interactive charts.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: kTextPrimaryColour.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
          
          const SizedBox(height: 40),
          
          // Bar chart image
          Center(
            child: SizedBox(
              width: 240,
              height: 180,
              child: SvgPicture.asset(
                'assets/images/simplified-bar-chart.svg',
                fit: BoxFit.contain,
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(
    BuildContext context,
    String title,
    IconData icon,
    String description,
  ) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: kAccentColour.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 60,
              color: kAccentColour,
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: kTextPrimaryColour,
            ),
            textAlign: TextAlign.left,
          ),
          
          const SizedBox(height: 20),
          
          // Description
          Text(
            description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: kTextPrimaryColour.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.left,
          ),
        ],
      ),
    );
  }
}
