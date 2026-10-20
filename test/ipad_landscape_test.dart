import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:temphist_app/services/temperature_unit_service.dart';
import 'package:temphist_app/widgets/help_page.dart';
import 'package:temphist_app/widgets/location_selector_sheet.dart';
import 'package:temphist_app/widgets/onboarding/onboarding_screen.dart';
import 'package:temphist_app/widgets/settings_sheet.dart';

/// iPad logical sizes in landscape (width × height), smallest height first.
const _landscapeSizes = <String, Size>{
  'iPad mini 744×1133': Size(1133, 744),
  'iPad 11" 834×1194': Size(1194, 834),
  'iPad Pro 12.9" 1024×1366': Size(1366, 1024),
};

/// iPad logical sizes in portrait, for the onboarding portrait check.
const _portraitSizes = <String, Size>{
  'iPad mini 744×1133': Size(744, 1133),
  'iPad Pro 12.9" 1024×1366': Size(1024, 1366),
};

/// Approximate height of the iPad on-screen keyboard in landscape.
const _landscapeKeyboardHeight = 400.0;

void _useView(WidgetTester tester, Size size, {double keyboard = 0}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
  addTearDown(tester.view.reset);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final entry in _landscapeSizes.entries) {
    group('iPad landscape — ${entry.key}', () {
      testWidgets('settings sheet renders without overflow', (tester) async {
        _useView(tester, entry.value);
        await tester.pumpWidget(MaterialApp(
          home: SettingsSheet(
            isFahrenheit: false,
            onUnitChanged: (_) {},
            onOpenLocationSelector: () {},
          ),
        ));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      testWidgets('help page renders and scrolls without overflow',
          (tester) async {
        _useView(tester, entry.value);
        await tester.pumpWidget(const MaterialApp(home: HelpPage()));
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -3000));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      });

      for (final keyboard in [0.0, _landscapeKeyboardHeight]) {
        testWidgets(
            'location selector renders without overflow '
            '(keyboard ${keyboard.toInt()})', (tester) async {
          _useView(tester, entry.value, keyboard: keyboard);
          await tester.pumpWidget(MaterialApp(
            home: LocationSelectorSheet(
              gpsLocation: 'London, United Kingdom',
              selectedLocation: 'London, United Kingdom',
              onLocationSelected: (_, __) {},
              connectivityOnline: true,
            ),
          ));
          await tester.pump();
          await tester.pump(const Duration(seconds: 2));
          expect(tester.takeException(), isNull);
        });
      }

      testWidgets('onboarding pages render without overflow', (tester) async {
        _useView(tester, entry.value);
        await tester.pumpWidget(MaterialApp(
          home: OnboardingScreen(
            onComplete: () {},
            unitService: TemperatureUnitService(),
          ),
        ));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull);
        for (var i = 0; i < 6; i++) {
          await tester.tap(find.text('Next'));
          await tester.pump(const Duration(seconds: 1));
          expect(tester.takeException(), isNull, reason: 'page ${i + 2}');
        }
      });
    });
  }

  for (final entry in _portraitSizes.entries) {
    testWidgets(
        'onboarding pages render without overflow in portrait — '
        '${entry.key}', (tester) async {
      _useView(tester, entry.value);
      await tester.pumpWidget(MaterialApp(
        home: OnboardingScreen(
          onComplete: () {},
          unitService: TemperatureUnitService(),
        ),
      ));
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
      for (var i = 0; i < 6; i++) {
        await tester.tap(find.text('Next'));
        await tester.pump(const Duration(seconds: 1));
        expect(tester.takeException(), isNull, reason: 'page ${i + 2}');
      }
    });
  }
}
