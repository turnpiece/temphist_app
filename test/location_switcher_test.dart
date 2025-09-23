import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:temphist_app/screens/location_switcher_screen.dart';
import 'package:temphist_app/state/app_state.dart';
import 'package:temphist_app/models/explore_state.dart';

void main() {
  group('LocationSwitcherScreen Widget Tests', () {
    late AppState appState;

    setUp(() {
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
      appState = AppState();
    });

    testWidgets('multi-location selection updates state and resets pager', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      // Set up multiple locations
      final location1 = LocationInfo(
        displayName: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final location2 = LocationInfo(
        displayName: 'New York, NY, USA',
        latitude: 40.7128,
        longitude: -74.0060,
      );
      final location3 = LocationInfo(
        displayName: 'Tokyo, Japan',
        latitude: 35.6762,
        longitude: 139.6503,
      );

      // Add locations to app state
      await appState.addVisitedLocation(location1);
      await appState.addVisitedLocation(location2);
      await appState.addVisitedLocation(location3);

      // Set current location to first one
      appState.setCurrentLocation(location1);

      // Set pager to a non-Today context
      appState.setTimeContextIndex(3); // D-3
      expect(appState.timeContextIndex, equals(3));

      bool locationSelectedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {
                locationSelectedCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify all locations are displayed
      expect(find.text('London, UK'), findsOneWidget);
      expect(find.text('New York, NY, USA'), findsOneWidget);
      expect(find.text('Tokyo, Japan'), findsOneWidget);

      // Verify current location is highlighted
      expect(find.text('Current'), findsOneWidget);

      // Tap on a different location (Tokyo)
      final tokyoTile = find.text('Tokyo, Japan');
      expect(tokyoTile, findsOneWidget);
      await tester.tap(tokyoTile);
      await tester.pumpAndSettle();

      // Verify the callback was called
      expect(locationSelectedCalled, isTrue);

      // Verify the current location was updated
      expect(appState.currentLocation?.displayName, equals('Tokyo, Japan'));

      // Verify the pager was reset to Today (index 0)
      expect(appState.timeContextIndex, equals(0));
      expect(appState.currentTimeContextName, equals('Today'));
    });

    testWidgets('single-location empty-state message renders', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      // Set up single location
      final location = LocationInfo(
        displayName: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
      );

      // Add single location to app state
      await appState.addVisitedLocation(location);
      appState.setCurrentLocation(location);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify the single location is displayed
      expect(find.text('London, UK'), findsOneWidget);
      expect(find.text('Current'), findsOneWidget);

      // Verify the helpful message is displayed
      expect(find.text("When you visit other locations they'll appear here."), findsOneWidget);

      // Verify the message has the correct styling (info icon)
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // Verify the message is in a styled container
      final messageContainer = find.byType(Container).first;
      expect(messageContainer, findsOneWidget);
    });

    testWidgets('empty state renders when no locations', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      // Don't add any locations to app state
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify empty state is displayed
      expect(find.text('No Locations Yet'), findsOneWidget);
      expect(find.text('Visit different locations to build your list'), findsOneWidget);
      expect(find.byIcon(Icons.location_off), findsOneWidget);
    });

    testWidgets('settings button navigates to settings', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      // Set up single location
      final location = LocationInfo(
        displayName: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
      );

      await appState.addVisitedLocation(location);
      appState.setCurrentLocation(location);

      bool settingsTappedCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {},
              onSettingsTapped: () {
                settingsTappedCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap settings button
      final settingsButton = find.byIcon(Icons.settings);
      expect(settingsButton, findsOneWidget);
      await tester.tap(settingsButton);
      await tester.pumpAndSettle();

      // Verify callback was called
      expect(settingsTappedCalled, isTrue);
    });

    testWidgets('location tiles show correct information', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      // Set up location with coordinates
      final location = LocationInfo(
        displayName: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
      );

      await appState.addVisitedLocation(location);
      appState.setCurrentLocation(location);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify location name is displayed
      expect(find.text('London, UK'), findsOneWidget);

      // Verify coordinates are displayed
      expect(find.text('51.5074, -0.1278'), findsOneWidget);

      // Verify current location badge
      expect(find.text('Current'), findsOneWidget);

      // Verify location icon
      expect(find.byIcon(Icons.my_location), findsOneWidget);
    });

    testWidgets('non-current locations show different styling', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      // Set up multiple locations
      final location1 = LocationInfo(
        displayName: 'London, UK',
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final location2 = LocationInfo(
        displayName: 'New York, NY, USA',
        latitude: 40.7128,
        longitude: -74.0060,
      );

      await appState.addVisitedLocation(location1);
      await appState.addVisitedLocation(location2);
      appState.setCurrentLocation(location1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify current location has "Current" badge
      expect(find.text('Current'), findsOneWidget);

      // Verify non-current location has chevron icon
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      // Verify non-current location has different icon
      expect(find.byIcon(Icons.location_on), findsOneWidget);
    });

    testWidgets('app bar shows correct title and close button', (WidgetTester tester) async {
      // Initialize AppState
      await appState.initialize();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LocationSwitcherScreen(
              appState: appState,
              onLocationSelected: () {},
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify app bar title
      expect(find.text('Select Location'), findsOneWidget);

      // Verify close button
      expect(find.byIcon(Icons.close), findsOneWidget);

      // Verify settings button
      expect(find.byIcon(Icons.settings), findsOneWidget);
    });
  });
}
