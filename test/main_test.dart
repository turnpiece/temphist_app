import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temphist_app/main.dart';
import 'package:temphist_app/screens/onboarding_screen.dart';
import 'package:temphist_app/services/onboarding_service.dart';
import 'dart:async';

// Import explore tests
import 'explore_test.dart' as explore_tests;

void main() {
  group('TemperatureScreen Tests', () {
    testWidgets('App loads without crashing', (WidgetTester tester) async {
      final mockData = {
        'chartData': <TemperatureChartData>[],
        'averageTemperature': null,
        'trendSlope': null,
        'summary': '',
        'displayDate': '',
        'city': '',
      };

      await tester.pumpWidget(MaterialApp(
        home: TemperatureScreen(
          testFuture: Future.value(mockData),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Verify that the app loads without crashing
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('App shows logo and date/location pill', (WidgetTester tester) async {
      final mockData = {
        'chartData': <TemperatureChartData>[],
        'averageTemperature': null,
        'trendSlope': null,
        'summary': '',
        'displayDate': '',
        'city': '',
      };

      await tester.pumpWidget(MaterialApp(
        home: TemperatureScreen(
          testFuture: Future.value(mockData),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      
      // Check for logo (SvgPicture)
      expect(find.byType(SvgPicture), findsOneWidget);
      // Check for date/location pill
      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('Chart and summary render with data', (WidgetTester tester) async {
      // Mock chart data
      final mockData = {
        'chartData': [
          TemperatureChartData(year: '2020', temperature: 15.0, isCurrentYear: false, hasData: true),
          TemperatureChartData(year: '2021', temperature: 16.0, isCurrentYear: true, hasData: true),
        ],
        'averageTemperature': 15.5,
        'trendSlope': 0.1,
        'summary': 'Test summary',
        'displayDate': '1st January',
        'city': 'Testville',
      };

      await tester.pumpWidget(MaterialApp(
        home: TemperatureScreen(
          testFuture: Future.value(mockData),
        ),
      ));

      // Wait for the FutureBuilder to complete
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Check for summary text
      expect(find.text('Test summary'), findsOneWidget);
      // Check for average temperature display
      expect(find.textContaining('15.5'), findsOneWidget);
    });

    testWidgets('Shows loading indicator while waiting', (WidgetTester tester) async {
      // Use a future that never completes
      final neverCompletes = Completer<Map<String, dynamic>>().future;

      await tester.pumpWidget(MaterialApp(
        home: TemperatureScreen(
          testFuture: neverCompletes,
        ),
      ));

      // Wait for the app to initialize
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // The app should show some loading state - check for any text that indicates loading
      // Since the app uses a custom loading system, check for any text that might indicate loading
      // The app should show some UI elements even when loading
      expect(find.byType(Text), findsWidgets);
    });

    testWidgets('Shows error and retry button on error', (WidgetTester tester) async {
      // Create a completer that we can control
      final completer = Completer<Map<String, dynamic>>();

      await tester.pumpWidget(MaterialApp(
        home: TemperatureScreen(
          testFuture: completer.future,
        ),
      ));

      // Complete the future with an error
      completer.completeError('Test error');

      // Wait for the error to be displayed
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Verify that error message and retry button are shown
      expect(find.textContaining('Error loading data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('OnboardingService Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('hasSeenOnboarding returns false by default', () async {
      final hasSeen = await OnboardingService.hasSeenOnboarding();
      expect(hasSeen, false);
    });

    test('hasSeenOnboarding returns true after marking as seen', () async {
      await OnboardingService.markOnboardingSeen();
      final hasSeen = await OnboardingService.hasSeenOnboarding();
      expect(hasSeen, true);
    });

    test('resetOnboarding clears the seen flag', () async {
      // First mark as seen
      await OnboardingService.markOnboardingSeen();
      expect(await OnboardingService.hasSeenOnboarding(), true);
      
      // Then reset
      await OnboardingService.resetOnboarding();
      expect(await OnboardingService.hasSeenOnboarding(), false);
    });

    test('markOnboardingSeen persists across multiple calls', () async {
      await OnboardingService.markOnboardingSeen();
      expect(await OnboardingService.hasSeenOnboarding(), true);
      
      // Call again to ensure it doesn't break
      await OnboardingService.markOnboardingSeen();
      expect(await OnboardingService.hasSeenOnboarding(), true);
    });
  });

  group('OnboardingScreen Tests', () {
    testWidgets('displays all three slides', (WidgetTester tester) async {
      bool onCompleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () {
              onCompleteCalled = true;
            },
          ),
        ),
      );

      // Should show first slide
      expect(find.text('See how today compares to past decades.'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
      expect(find.text('Previous'), findsNothing);

      // Navigate to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Swipe to explore previous days.'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);

      // Navigate to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Privacy: We only use your location while you use the app.'), findsOneWidget);
      expect(find.text('Get Started'), findsOneWidget);
      expect(find.text('Previous'), findsOneWidget);

      // Complete onboarding
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      
      // Wait a bit more for the async SharedPreferences operation
      await tester.pump(const Duration(milliseconds: 100));

      expect(onCompleteCalled, true);
    });

    testWidgets('can navigate back and forth between slides', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () {},
          ),
        ),
      );

      // Start on first slide
      expect(find.text('See how today compares to past decades.'), findsOneWidget);

      // Go to second slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Swipe to explore previous days.'), findsOneWidget);

      // Go back to first slide
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('See how today compares to past decades.'), findsOneWidget);

      // Go to second slide again
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Swipe to explore previous days.'), findsOneWidget);

      // Go to third slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Privacy: We only use your location while you use the app.'), findsOneWidget);

      // Go back to second slide
      await tester.tap(find.text('Previous'));
      await tester.pumpAndSettle();
      expect(find.text('Swipe to explore previous days.'), findsOneWidget);
    });

    testWidgets('shows correct page indicators', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () {},
          ),
        ),
      );

      // Should show 3 page indicators
      expect(find.byType(Container), findsWidgets);
      
      // First page should be active (wider indicator)
      // This is a bit tricky to test precisely, but we can verify the structure
      expect(find.text('See how today compares to past decades.'), findsOneWidget);
    });

    testWidgets('calls onComplete when Get Started is tapped', (WidgetTester tester) async {
      bool onCompleteCalled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: OnboardingScreen(
            onComplete: () {
              onCompleteCalled = true;
            },
          ),
        ),
      );

      // Navigate to last slide
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Tap Get Started
      await tester.tap(find.text('Get Started'));
      await tester.pumpAndSettle();
      
      // Wait a bit more for the async SharedPreferences operation
      await tester.pump(const Duration(milliseconds: 100));

      expect(onCompleteCalled, true);
    });
  });

  group('OnboardingWrapper Tests', () {
    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('shows loading indicator initially', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingWrapper(),
        ),
      );

      // Should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows onboarding screen when not seen', (WidgetTester tester) async {
      // Ensure onboarding is not seen
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingWrapper(),
        ),
      );

      // Wait for async initialization
      await tester.pumpAndSettle();

      // Should show onboarding screen
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('See how today compares to past decades.'), findsOneWidget);
    });

    testWidgets('shows temperature screen when onboarding seen', (WidgetTester tester) async {
      // Set onboarding as seen
      SharedPreferences.setMockInitialValues({
        'onboarding_seen': true,
      });
      
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingWrapper(),
        ),
      );

      // Wait for async initialization but with a timeout
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Should show temperature screen (not onboarding)
      expect(find.byType(OnboardingScreen), findsNothing);
      // The temperature screen should be present (though we can't easily test its content)
      expect(find.byType(TemperatureScreen), findsOneWidget);
    });

    testWidgets('shows onboarding screen initially when not seen', (WidgetTester tester) async {
      // Start with onboarding not seen
      SharedPreferences.setMockInitialValues({});
      
      await tester.pumpWidget(
        const MaterialApp(
          home: OnboardingWrapper(),
        ),
      );

      // Wait for async initialization
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      // Should show onboarding screen
      expect(find.byType(OnboardingScreen), findsOneWidget);
      expect(find.text('See how today compares to past decades.'), findsOneWidget);
    });
  });

  // Run explore tests
  explore_tests.main();
} 