import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:temphist_app/widgets/location_selector_sheet.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget _sheet({
  String gpsLocation = '',
  String selectedLocation = '',
  void Function(String)? onLocationSelected,
}) {
  return MaterialApp(
    home: LocationSelectorSheet(
      gpsLocation: gpsLocation,
      selectedLocation: selectedLocation,
      onLocationSelected: onLocationSelected ?? (_) {},
    ),
  );
}

/// Pumps the widget and waits for the async data load to complete.
Future<void> _pump(WidgetTester tester, Widget widget) async {
  await tester.pumpWidget(widget);
  await tester.pump();
  await tester.pump(const Duration(seconds: 2));
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationSelectorSheet — current location section', () {
    testWidgets('shows "CURRENT" header when gpsLocation is set',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Sydney, Australia',
        ),
      );
      expect(find.text('CURRENT'), findsOneWidget);
    });

    testWidgets('hides "CURRENT" header when gpsLocation is empty',
        (tester) async {
      await _pump(
        tester,
        _sheet(gpsLocation: '', selectedLocation: 'Sydney, Australia'),
      );
      expect(find.text('CURRENT'), findsNothing);
    });

    testWidgets('displays the GPS city name in current location section',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Sydney, Australia',
        ),
      );
      // City name is split on comma, so only "Sydney" appears
      expect(find.text('Sydney'), findsOneWidget);
    });
  });

  group('LocationSelectorSheet — popular locations section', () {
    testWidgets('shows "POPULAR" section after data loads',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Sydney, Australia',
        ),
      );
      expect(find.text('POPULAR'), findsOneWidget);
    });
  });

  group('LocationSelectorSheet — recent locations section', () {
    testWidgets('shows "RECENT" section when history is present',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'locationHistory': '["London, United Kingdom","Paris, France"]',
      });
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'London, United Kingdom',
        ),
      );
      expect(find.text('RECENT'), findsOneWidget);
    });

    testWidgets('hides "RECENT" when history is empty',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Sydney, Australia',
        ),
      );
      expect(find.text('RECENT'), findsNothing);
    });

    testWidgets('GPS location is excluded from recent locations list',
        (tester) async {
      // History contains London (also the GPS location) and Paris.
      // London should not appear in the Recent section — only in Current.
      SharedPreferences.setMockInitialValues({
        'locationHistory': '["London, United Kingdom","Paris, France"]',
      });
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'London, United Kingdom',
          selectedLocation: 'London, United Kingdom',
        ),
      );
      // London appears exactly once (Current location), not again in Recent
      expect(find.text('London'), findsOneWidget);
      // Paris is not the GPS location, so it does appear in Recent
      expect(find.text('Paris'), findsOneWidget);
    });

    testWidgets(
        'GPS location excluded even when format differs from history entry',
        (tester) async {
      // GPS may return "London, Greater London, United Kingdom" while history
      // stored "London, United Kingdom". Exclusion uses city-name comparison.
      SharedPreferences.setMockInitialValues({
        'locationHistory':
            '["London, United Kingdom","Paris, France"]',
      });
      await _pump(
        tester,
        _sheet(
          // GPS resolved with admin area included
          gpsLocation: 'London, Greater London, United Kingdom',
          selectedLocation: 'London, Greater London, United Kingdom',
        ),
      );
      // Only one "London" visible — not duplicated in Recent
      expect(find.text('London'), findsOneWidget);
    });
  });

  group('LocationSelectorSheet — selected location check', () {
    testWidgets('selected location in recent shows check icon', (tester) async {
      SharedPreferences.setMockInitialValues({
        'locationHistory': '["Belfast, United Kingdom","Paris, France"]',
      });
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Belfast, United Kingdom',
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets(
        'current location row shows check when GPS equals selected',
        (tester) async {
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Sydney, Australia',
        ),
      );
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets(
        'no check on current row when selected differs from GPS',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'locationHistory': '["Belfast, United Kingdom"]',
      });
      await _pump(
        tester,
        _sheet(
          gpsLocation: 'Sydney, Australia',
          selectedLocation: 'Belfast, United Kingdom',
        ),
      );
      // Check is on Belfast (in Recent), not on Sydney (Current)
      final checkIcons = tester.widgetList<Icon>(find.byIcon(Icons.check));
      expect(checkIcons.length, 1);
    });
  });
}
