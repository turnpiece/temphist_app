import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/state/app_state.dart';
import 'package:temphist_app/widgets/time_swipe_pager.dart';
import 'package:temphist_app/models/explore_state.dart';

void main() {
  group('TimeSwipePager', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    testWidgets('displays correct number of pages', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSwipePager(
              appState: appState,
              pageBuilder: (context, index) => TimeContextPage(
                index: index,
                contextName: 'Context $index',
                date: DateTime.now(),
                period: 'day',
              ),
            ),
          ),
        ),
      );

      // PageView.builder only builds visible pages, so we check that it exists
      expect(find.byType(TimeSwipePager), findsOneWidget);
      expect(find.byType(PageView), findsOneWidget);
      
      // Check that the initial page is displayed
      expect(find.byType(TimeContextPage), findsOneWidget);
    });

    testWidgets('initializes with Today page (index 0)', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSwipePager(
              appState: appState,
              pageBuilder: (context, index) => TimeContextPage(
                index: index,
                contextName: 'Context $index',
                date: DateTime.now(),
                period: 'day',
              ),
            ),
          ),
        ),
      );

      // Should start at index 0 (Today)
      expect(appState.timeContextIndex, equals(0));
      expect(appState.currentTimeContextName, equals('Today'));
    });

    testWidgets('page changes update app state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSwipePager(
              appState: appState,
              pageBuilder: (context, index) => TimeContextPage(
                index: index,
                contextName: 'Context $index',
                date: DateTime.now(),
                period: 'day',
              ),
            ),
          ),
        ),
      );

      // Test that the pager syncs with app state changes
      appState.setTimeContextIndex(2);
      await tester.pumpAndSettle();

      expect(appState.timeContextIndex, equals(2));
      expect(appState.currentTimeContextName, equals('D-2'));
    });

    testWidgets('handles boundary constraints', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSwipePager(
              appState: appState,
              pageBuilder: (context, index) => TimeContextPage(
                index: index,
                contextName: 'Context $index',
                date: DateTime.now(),
                period: 'day',
              ),
            ),
          ),
        ),
      );

      // Test that boundary constraints work
      expect(appState.canSwipeLeft, isFalse); // Can't go left from Today
      expect(appState.canSwipeRight, isTrue); // Can go right from Today
      
      // Navigate to PastMonth (index 8)
      appState.setTimeContextIndex(8);
      await tester.pumpAndSettle();

      expect(appState.canSwipeLeft, isTrue); // Can go left from PastMonth
      expect(appState.canSwipeRight, isFalse); // Can't go right from PastMonth
    });

    testWidgets('syncs with app state changes', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TimeSwipePager(
              appState: appState,
              pageBuilder: (context, index) => TimeContextPage(
                index: index,
                contextName: 'Context $index',
                date: DateTime.now(),
                period: 'day',
              ),
            ),
          ),
        ),
      );

      // Change app state programmatically
      appState.setTimeContextIndex(3);
      await tester.pumpAndSettle();

      expect(appState.timeContextIndex, equals(3));
      expect(appState.currentTimeContextName, equals('D-3'));
    });
  });

  group('AppState Time Context', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('initializes with Today context', () {
      expect(appState.timeContextIndex, equals(0));
      expect(appState.currentTimeContextName, equals('Today'));
      expect(appState.canSwipeRight, isTrue);
      expect(appState.canSwipeLeft, isFalse);
    });

    test('setTimeContextIndex updates context correctly', () {
      appState.setTimeContextIndex(5);
      expect(appState.timeContextIndex, equals(5));
      expect(appState.currentTimeContextName, equals('D-5'));
      expect(appState.canSwipeRight, isTrue);
      expect(appState.canSwipeLeft, isTrue);
    });

    test('moveToNextContext advances to next context', () {
      appState.moveToNextContext();
      expect(appState.timeContextIndex, equals(1));
      expect(appState.currentTimeContextName, equals('D-1'));
    });

    test('moveToPreviousContext goes back to previous context', () {
      appState.setTimeContextIndex(3);
      appState.moveToPreviousContext();
      expect(appState.timeContextIndex, equals(2));
      expect(appState.currentTimeContextName, equals('D-2'));
    });

    test('prevents moving beyond boundaries', () {
      // Try to move right from PastMonth
      appState.setTimeContextIndex(8);
      appState.moveToNextContext();
      expect(appState.timeContextIndex, equals(8)); // Should stay at 8

      // Try to move left from Today
      appState.setTimeContextIndex(0);
      appState.moveToPreviousContext();
      expect(appState.timeContextIndex, equals(0)); // Should stay at 0
    });

    test('updates date and period based on context', () {
      final now = DateTime.now();
      
      // Today
      appState.setTimeContextIndex(0);
      expect(appState.currentPeriod, equals(ExplorePeriod.day));
      
      // D-1
      appState.setTimeContextIndex(1);
      expect(appState.currentPeriod, equals(ExplorePeriod.day));
      expect(appState.currentDate.day, equals(now.subtract(const Duration(days: 1)).day));
      
      // PastWeek
      appState.setTimeContextIndex(7);
      expect(appState.currentPeriod, equals(ExplorePeriod.week));
      
      // PastMonth
      appState.setTimeContextIndex(8);
      expect(appState.currentPeriod, equals(ExplorePeriod.month));
    });

    test('identifies aggregate contexts correctly', () {
      expect(appState.isAggregateContext, isFalse); // Today
      
      appState.setTimeContextIndex(6);
      expect(appState.isAggregateContext, isFalse); // D-6
      
      appState.setTimeContextIndex(7);
      expect(appState.isAggregateContext, isTrue); // PastWeek
      
      appState.setTimeContextIndex(8);
      expect(appState.isAggregateContext, isTrue); // PastMonth
    });

    test('resetToToday resets to index 0', () {
      appState.setTimeContextIndex(5);
      appState.resetToToday();
      expect(appState.timeContextIndex, equals(0));
      expect(appState.currentTimeContextName, equals('Today'));
      expect(appState.currentPeriod, equals(ExplorePeriod.day));
    });
  });
}
