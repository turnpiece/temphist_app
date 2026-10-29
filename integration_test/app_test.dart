// End-to-end smoke tests that drive the real app (real Firebase, real API) on
// a device or emulator. They check that the main user journeys behave the same
// on Android as they do on iOS.
//
// Run on the Android emulator (grants the location permission as soon as the
// app is installed, because `flutter test` reinstalls it and the OS permission
// dialog would otherwise block the splash screen):
//
//   integration_test/run_android.sh [device-id] [extra flutter test args]
//
// Notes:
//  * Debug builds reset the "seen onboarding" flag on every launch, so every
//    test starts on the onboarding flow.
//  * The tests are location-agnostic: they assert on structure, not on a
//    particular city or temperature.
//  * The last test changes the selected location; keep it last.

import 'dart:io' show HttpOverrides;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:temphist_app/services/temperature_service.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('First launch', () {
    testWidgets('onboarding can be stepped through to the main screen',
        (tester) async {
      await launchApp(tester);
      await pumpUntilFound(tester, nextButton, reason: 'onboarding "Next"');

      // Step through every page until the last one offers "Get Started".
      var pages = 1;
      while (getStartedButton.evaluate().isEmpty) {
        expect(pages, lessThan(15), reason: 'onboarding never reached the end');
        await tapAndPump(tester, nextButton);
        pages++;
      }
      expect(pages, greaterThan(1), reason: 'onboarding should have >1 page');

      await tapAndPump(tester, getStartedButton);
      await pumpUntilFound(tester, tab('Today'));
      for (final label in ['Today', 'Week', 'Month', 'Year']) {
        expect(tab(label), findsOneWidget, reason: '$label tab');
      }
    });

    testWidgets('onboarding can be skipped', (tester) async {
      await launchApp(tester);
      await pumpUntilFound(tester, skipButton);
      await tapAndPump(tester, skipButton);
      await pumpUntilFound(tester, tab('Today'));
      expect(skipButton, findsNothing);
    });
  });

  group('Main screen', () {
    testWidgets('loads location, chart and stats for today', (tester) async {
      await reachLoadedMainScreen(tester);

      expect(loadingLocation, findsNothing);
      expect(visibleChart, findsWidgets);
      // Stats sit below the chart: scroll down to build them.
      final scrollable = find
          .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
          .hitTestable();
      for (var i = 0; i < 3; i++) {
        await tester.drag(scrollable.first, const Offset(0, -300));
        await tester.pump(const Duration(milliseconds: 100));
      }
      await pumpFor(tester, const Duration(milliseconds: 400));
      expect(statsBlock(), findsWidgets, reason: 'average stat');
      final averageText =
          tester.widget<RichText>(statsBlock().first).text.toPlainText();
      expect(averageText, matches(RegExp(r'^Average\s+-?\d+\.\d+°[CF]$')),
          reason: 'average should be a formatted temperature');
      expect(
        find.byWidgetPredicate(
            (w) => w is RichText && w.text.toPlainText().startsWith('Trend')),
        findsWidgets,
        reason: 'trend stat',
      );
      expect(
        tester
            .widget<RichText>(find
                .byWidgetPredicate((w) =>
                    w is RichText && w.text.toPlainText().startsWith('Trend'))
                .first)
            .text
            .toPlainText(),
        contains('/decade'),
        reason: 'trend should be expressed per decade',
      );
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.ios_share), findsOneWidget);
    });

    testWidgets('period tabs switch between today, week, month and year',
        (tester) async {
      await reachLoadedMainScreen(tester);

      final expectations = {
        'Week': 'Week ending',
        'Month': 'Month ending',
        'Year': 'Year ending',
      };
      for (final entry in expectations.entries) {
        await tapAndPump(tester, tab(entry.key));
        await pumpUntilFound(tester, find.textContaining(entry.value),
            reason: '${entry.value} header');
        await waitForStats(tester, reason: '${entry.key} stats to load');
        expect(visibleChart, findsWidgets, reason: '${entry.key} chart');
      }

      // And back to the first tab.
      await tapAndPump(tester, tab('Today'));
      await waitForStats(tester);
      expect(find.textContaining('Week ending'), findsNothing);
    });

    testWidgets('swiping moves between periods', (tester) async {
      await reachLoadedMainScreen(tester);

      final pages = find.byType(PageView);
      await tester.fling(pages.first, const Offset(-400, 0), 1500);
      await pumpFor(tester, const Duration(seconds: 1));
      await pumpUntilFound(tester, find.textContaining('Week ending'),
          reason: 'swipe left to reach the week page');

      await tester.fling(pages.first, const Offset(400, 0), 1500);
      await pumpFor(tester, const Duration(seconds: 1));
      expect(find.textContaining('Week ending'), findsNothing,
          reason: 'swipe right returns to today');
    });
  });

  group('Android back', () {
    testWidgets('steps back through the periods before leaving the app',
        (tester) async {
      await reachLoadedMainScreen(tester);
      await tapAndPump(tester, tab('Month'));
      await pumpUntilFound(tester, find.textContaining('Month ending'));

      // Same path as the edge-swipe back gesture with gesture navigation.
      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.textContaining('Week ending'), findsOneWidget,
          reason: 'back from Month goes to Week');

      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 800));
      expect(find.textContaining('Week ending'), findsNothing);
      expect(find.textContaining('Month ending'), findsNothing,
          reason: 'back from Week goes to Today');
      // A further back would leave the app, so stop here.
    });
  });

  group('Settings', () {
    testWidgets('sheet lists its rows and closes with the close button',
        (tester) async {
      await reachLoadedMainScreen(tester);
      await openSettings(tester);

      for (final label in [
        'Settings',
        'Temperature units',
        'Location',
        'Help',
        'Privacy policy',
      ]) {
        expect(find.text(label), findsWidgets, reason: label);
      }

      await tapAndPump(tester, find.byIcon(Icons.close));
      await pumpUntilGone(tester, find.text('Temperature units'));
      expect(tab('Today'), findsOneWidget);
    });

    testWidgets('Android system back closes the sheet instead of the app',
        (tester) async {
      await reachLoadedMainScreen(tester);
      await openSettings(tester);

      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 800));

      await pumpUntilGone(tester, find.text('Temperature units'));
      expect(tab('Today'), findsOneWidget, reason: 'still on main screen');
    });

    testWidgets('temperature unit toggle switches between °C and °F',
        (tester) async {
      await reachLoadedMainScreen(tester);

      final startedInF = await showingFahrenheit(tester);
      var inF = startedInF;

      Future<void> setUnit(String unit) async {
        await openSettings(tester);
        await tapAndPump(tester, find.text(unit).last);
        inF = unit == '°F';
        await waitForStats(tester, unit: unit, reason: 'stats shown in $unit');
      }

      try {
        await setUnit(startedInF ? '°C' : '°F');
        await setUnit(startedInF ? '°F' : '°C');
      } finally {
        // Leave the saved preference as we found it, even if an assertion
        // above failed part way.
        if (inF != startedInF) {
          await openSettings(tester);
          await tapAndPump(tester, find.text(startedInF ? '°F' : '°C').last);
        }
      }
    });

    testWidgets('Help opens the help page and back returns to the app',
        (tester) async {
      await reachLoadedMainScreen(tester);
      await openSettings(tester);

      await tapAndPump(tester, find.text('Help'));
      await pumpUntilFound(tester, find.text('What is TempHist?'),
          reason: 'help page');
      expect(find.text('Reading the chart'), findsWidgets);

      await tester.binding.handlePopRoute();
      await pumpFor(tester, const Duration(milliseconds: 800));
      await pumpUntilGone(tester, find.text('What is TempHist?'));
      expect(tab('Today'), findsOneWidget);
    });
  });

  group('Chart', () {
    testWidgets('exposes screen-reader labels and shows a tooltip on tap',
        (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await reachLoadedMainScreen(tester);

        // TalkBack: one summary for the whole chart plus one node per year.
        await pumpUntilFound(
          tester,
          find.bySemanticsLabel(RegExp(r'^Bar chart of temperature')),
          reason: 'chart summary label',
        );
        final yearRows = find.bySemanticsLabel(RegExp(r'^\d{4}: '));
        expect(yearRows.evaluate().length, greaterThan(10),
            reason: 'one labelled row per year');

        // Sighted users: tapping a bar shows a tooltip with the year (the
        // axis is painted, so a bare 4-digit Text can only be the tooltip).
        final tooltipYear = textWidget((t) => RegExp(r'^\d{4}$').hasMatch(t));
        expect(tooltipYear, findsNothing);

        final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
        final onScreen = [
          for (var i = 0; i < yearRows.evaluate().length; i++)
            tester.getRect(yearRows.at(i)),
        ].where((r) => r.center.dy > 250 && r.center.dy < screen.height - 120);
        expect(onScreen, isNotEmpty, reason: 'a year row visible on screen');
        final row = onScreen.first;

        var shown = false;
        for (final fraction in [0.1, 0.25, 0.4, 0.55, 0.7, 0.85]) {
          await tester
              .tapAt(Offset(row.left + row.width * fraction, row.center.dy));
          await pumpFor(tester, const Duration(milliseconds: 500));
          if (tooltipYear.evaluate().isNotEmpty) {
            shown = true;
            break;
          }
        }
        expect(shown, isTrue, reason: 'tapping a bar should show its tooltip');
      } finally {
        semantics.dispose();
      }
    });
  });

  group('Resilience', () {
    testWidgets('API outage shows an error with Retry, and Retry recovers',
        (tester) async {
      // The previous test can leave API jobs in flight, and the app shares an
      // in-flight job with any new request for the same data, which would
      // dodge the block below. Unmount and let them drain first.
      await tester.pumpWidget(const SizedBox.shrink());
      await pumpFor(tester, const Duration(seconds: 12));
      TemperatureService.clearCache();
      HttpOverrides.global = BlockTempHistApi();
      try {
        await launchApp(tester);
        await reachMainScreen(tester);
        await pumpUntilFound(tester, find.text('Retry'),
            timeout: networkTimeout, reason: 'error state with Retry');
        expect(find.byIcon(Icons.error_outline), findsWidgets);
        expect(statsBlock(), findsNothing);

        // The "network" comes back; Retry should fetch fresh data.
        HttpOverrides.global = null;
        TemperatureService.clearCache();
        await tapAndPump(tester, find.text('Retry').first);
        await waitForStats(tester, reason: 'data to load after Retry');
        expect(find.text('Retry'), findsNothing);
      } finally {
        HttpOverrides.global = null;
      }
    });

    testWidgets('largest system font still lays out and works', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 2.0;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      // Layout overflows surface as test failures: launchApp hands the
      // framework's error handler back once the app has started.
      await reachLoadedMainScreen(tester);
      for (final label in ['Week', 'Month', 'Year', 'Today']) {
        await tapAndPump(tester, tab(label));
        await waitForStats(tester, reason: '$label stats at 2x font');
      }
      await openSettings(tester);
      await tapAndPump(tester, find.byIcon(Icons.close));
      await pumpUntilGone(tester, find.text('Temperature units'));
    });

    testWidgets('unit choice survives an app restart', (tester) async {
      await reachLoadedMainScreen(tester);
      final startedInF = await showingFahrenheit(tester);
      final changeTo = startedInF ? '°C' : '°F';

      try {
        await openSettings(tester);
        await tapAndPump(tester, find.text(changeTo).last);
        await waitForStats(tester, unit: changeTo);

        // Cold start again in the same process; the saved preference must win.
        // Unmount first: runApp() on top of a live TempHist would just update
        // it in place and keep its state.
        await tester.pumpWidget(const SizedBox.shrink());
        await launchApp(tester);
        await reachMainScreen(tester);
        await waitForStats(tester,
            unit: changeTo, reason: 'unit to be remembered after restart');
      } finally {
        if (await showingFahrenheit(tester) != startedInF) {
          await openSettings(tester);
          await tapAndPump(tester, find.text(startedInF ? '°F' : '°C').last);
        }
      }
    });
  });

  // Keep last: selects a different location and leaves it selected.
  group('Location', () {
    testWidgets('searching for a city and selecting it loads its data',
        (tester) async {
      await reachLoadedMainScreen(tester);

      final semantics = tester.ensureSemantics();
      try {
        await tapAndPump(
          tester,
          find.bySemanticsLabel(RegExp(r'^Change location')),
        );
        await pumpUntilFound(tester, find.text('Choose location'),
            reason: 'location selector');

        final search = find.byType(TextField);
        expect(search, findsOneWidget);
        await tester.enterText(search, 'Paris');
        await pumpFor(tester, const Duration(milliseconds: 500));
        await tester.testTextInput.receiveAction(TextInputAction.go);

        final result = textWidget((t) => t.startsWith('Paris'));
        await pumpUntilFound(tester, result,
            timeout: networkTimeout, reason: 'a Paris search result');
        await tapAndPump(tester, result.first);

        // Selector closes and the header switches to the chosen city.
        await pumpUntilGone(tester, find.text('Choose location'));
        await pumpUntilFound(
          tester,
          textWidget((t) => t.startsWith('Paris')),
          reason: 'Paris in the location header',
        );
        await waitForStats(tester, reason: 'Paris stats to load');
        expect(visibleChart, findsWidgets);
      } finally {
        semantics.dispose();
      }
    });
  });
}
