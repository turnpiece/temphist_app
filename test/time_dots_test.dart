import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/widgets/time_dots.dart';
import 'package:temphist_app/state/app_state.dart';

void main() {
  group('TimeDots Widget Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    testWidgets('displays correct number of dots', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 0,
              appState: appState,
            ),
          ),
        ),
      );

      // Should have 9 dots (Today through PastMonth)
      expect(find.byType(TimeDots), findsOneWidget);
      
      // Count the individual dot containers
      final dotContainers = find.byType(AnimatedContainer);
      expect(dotContainers, findsNWidgets(9));
    });

    testWidgets('active dot is visually distinct', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 2, // Third dot should be active (but appears in reversed position)
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find all AnimatedContainer widgets (the dots)
      final dotContainers = find.byType(AnimatedContainer);
      expect(dotContainers, findsNWidgets(9));

      // The active dot should be larger (12x12) and have a border
      // With reversed order, index 2 appears at position 6 (9-1-2)
      final activeDot = dotContainers.at(6);
      final activeDotWidget = tester.widget<AnimatedContainer>(activeDot);
      
      // Check that the active dot has the correct constraints
      expect(activeDotWidget.constraints?.minWidth, equals(12));
      expect(activeDotWidget.constraints?.minHeight, equals(12));
    });

    testWidgets('inactive dots are smaller and dimmer', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 1, // Second dot active (appears at position 7 in reversed order)
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final dotContainers = find.byType(AnimatedContainer);
      
      // Check first dot (inactive) - with reversed order, index 0 appears at position 8
      final inactiveDot = dotContainers.at(8);
      final inactiveDotWidget = tester.widget<AnimatedContainer>(inactiveDot);
      expect(inactiveDotWidget.constraints?.minWidth, equals(8));
      expect(inactiveDotWidget.constraints?.minHeight, equals(8));
    });

    testWidgets('accessibility labels are present', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 0,
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check that Semantics widgets are present (there will be more than 9 due to MaterialApp/Scaffold)
      final semanticsWidgets = find.byType(Semantics);
      expect(semanticsWidgets, findsAtLeastNWidgets(9));

      // Check specific accessibility labels
      expect(find.bySemanticsLabel('Today, 1 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Yesterday, 2 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Past week, 8 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Past month, 9 of 9'), findsOneWidget);
    });

    testWidgets('active dot follows pager index changes', (WidgetTester tester) async {
      int currentIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: Column(
                  children: [
                    TimeDots(
                      totalCount: 9,
                      activeIndex: currentIndex,
                      appState: appState,
                    ),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          currentIndex = (currentIndex + 1) % 9;
                        });
                      },
                      child: const Text('Next'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Initially, first dot should be active (appears at position 8 in reversed order)
      final initialDots = find.byType(AnimatedContainer);
      var activeDot = initialDots.at(8);
      var activeDotWidget = tester.widget<AnimatedContainer>(activeDot);
      expect(activeDotWidget.constraints?.minWidth, equals(12));

      // Tap next button to change active index
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      // Now second dot should be active (appears at position 7 in reversed order)
      final updatedDots = find.byType(AnimatedContainer);
      activeDot = updatedDots.at(7);
      activeDotWidget = tester.widget<AnimatedContainer>(activeDot);
      expect(activeDotWidget.constraints?.minWidth, equals(12));

      // First dot should now be inactive (appears at position 8 in reversed order)
      final inactiveDot = updatedDots.at(8);
      final inactiveDotWidget = tester.widget<AnimatedContainer>(inactiveDot);
      expect(inactiveDotWidget.constraints?.minWidth, equals(8));
    });

    testWidgets('handles tap-to-jump when onDotTap is provided', (WidgetTester tester) async {
      bool tapHandled = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 0,
              appState: appState,
              onDotTap: () {
                tapHandled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a dot (not the active one)
      final dotContainers = find.byType(AnimatedContainer);
      await tester.tap(dotContainers.at(2));
      await tester.pumpAndSettle();

      expect(tapHandled, isTrue);
    });

    testWidgets('does not handle tap when onDotTap is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 0,
              appState: appState,
              // onDotTap is null
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap on a dot - should not cause any errors
      final dotContainers = find.byType(AnimatedContainer);
      await tester.tap(dotContainers.at(2));
      await tester.pumpAndSettle();

      // Should still be working fine
      expect(find.byType(TimeDots), findsOneWidget);
    });

    testWidgets('context names are correct for all indices', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeDots(
              totalCount: 9,
              activeIndex: 0,
              appState: appState,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check all context names
      expect(find.bySemanticsLabel('Today, 1 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Yesterday, 2 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Two days ago, 3 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Three days ago, 4 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Four days ago, 5 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Five days ago, 6 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Six days ago, 7 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Past week, 8 of 9'), findsOneWidget);
      expect(find.bySemanticsLabel('Past month, 9 of 9'), findsOneWidget);
    });
  });
}
