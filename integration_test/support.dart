// Shared helpers for the integration tests.

import 'dart:io' show HttpOverrides;
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:temphist_app/main.dart' as app;
import 'package:temphist_app/widgets/temperature_bar_chart.dart';

const networkTimeout = Duration(seconds: 90);
const uiTimeout = Duration(seconds: 15);

/// Pumps frames until [finder] matches something, or fails after [timeout].
/// `pumpAndSettle` can't be used here: the splash/loading spinners animate
/// forever.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = uiTimeout,
  String? reason,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for '
      '${reason ?? finder}');
}

Future<void> pumpUntilGone(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = uiTimeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isEmpty) return;
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for '
      '$finder to disappear');
}

/// Pumps for a fixed time so animations (page transitions, sheets) finish.
Future<void> pumpFor(WidgetTester tester, Duration d) async {
  final deadline = DateTime.now().add(d);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

Future<void> tapAndPump(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await pumpFor(tester, const Duration(milliseconds: 600));
}

// --- Finders -----------------------------------------------------------

Finder get skipButton => find.text('Skip');
Finder get nextButton => find.text('Next');
Finder get getStartedButton => find.text('Get Started');
Finder tab(String label) => find.text(label).hitTestable();

Finder get loadingLocation => find.text('Loading location...');

/// Plain [Text] widgets only (excludes text inside a [TextField]).
Finder textWidget(bool Function(String) test) => find.byWidgetPredicate(
      (w) => w is Text && w.data != null && test(w.data!),
      description: 'Text matching predicate',
    );

/// The "Average ..." stat row, optionally requiring a temperature [unit] such
/// as '°C' or '°F'. Not `hitTestable()`: the stats sit below the chart, so they
/// are built but may be scrolled off-screen.
Finder statsBlock({String? unit}) => find.byWidgetPredicate(
      (w) {
        if (w is! RichText) return false;
        final text = w.text.toPlainText();
        return text.startsWith('Average') &&
            (unit == null || text.contains(unit));
      },
      description: 'Average stat${unit == null ? '' : ' in $unit'}',
    );

/// Waits for the stats row to be built, scrolling the page up and down to
/// reach it: it sits below the chart and the list only builds what is near the
/// viewport.
Future<void> waitForStats(
  WidgetTester tester, {
  String? unit,
  Duration timeout = networkTimeout,
  String? reason,
  bool scrollBack = true,
}) async {
  final stats = statsBlock(unit: unit);
  final deadline = DateTime.now().add(timeout);
  var attempt = 0;
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    if (stats.evaluate().isNotEmpty) {
      if (scrollBack) await scrollToTop(tester);
      return;
    }
    if (verticalScrollable.evaluate().isNotEmpty) {
      // Six nudges down the page, then six back up, repeating.
      final down = (attempt ~/ 6).isEven;
      await tester.drag(verticalScrollable.first, Offset(0, down ? -250 : 250));
      attempt++;
    }
  }
  fail('Timed out after ${timeout.inSeconds}s waiting for '
      '${reason ?? stats}');
}

Finder get verticalScrollable => find
    .byWidgetPredicate((w) => w is Scrollable && w.axis == Axis.vertical)
    .hitTestable();

/// The period tabs scroll with the page, so go back to the top where the rest
/// of a test expects to find them.
Future<void> scrollToTop(WidgetTester tester) async {
  for (var i = 0; i < 4 && verticalScrollable.evaluate().isNotEmpty; i++) {
    await tester.drag(verticalScrollable.first, const Offset(0, 500));
    await tester.pump(const Duration(milliseconds: 100));
  }
  await pumpFor(tester, const Duration(milliseconds: 400));
}

/// Whether the stats on the current page are shown in °F (reads them, then
/// returns to the top).
Future<bool> showingFahrenheit(WidgetTester tester) async {
  await waitForStats(tester, scrollBack: false);
  final text = tester.widget<RichText>(statsBlock().first).text.toPlainText();
  await scrollToTop(tester);
  return text.contains('°F');
}

Finder get visibleChart => find.byType(TemperatureBarChart).hitTestable();

/// Makes every request to the TempHist API fail fast with a connection error,
/// without touching the emulator's network (other hosts, and Firebase's native
/// SDKs, are unaffected). Install with `HttpOverrides.global = ...`.
class BlockTempHistApi extends HttpOverrides {
  @override
  String findProxyFromEnvironment(Uri url, Map<String, String>? environment) {
    return url.host.endsWith('temphist.com')
        ? 'PROXY 127.0.0.1:9' // nothing listens on the discard port
        : 'DIRECT';
  }
}

// --- Flows -------------------------------------------------------------

/// Cold-starts the app and waits for the first interactive screen
/// (onboarding in debug builds, otherwise the main screen).
Future<void> launchApp(WidgetTester tester) async {
  final originalOnError = FlutterError.onError;
  final originalPlatformOnError = PlatformDispatcher.instance.onError;

  // main() is `async void`: it returns before Firebase etc. have initialised,
  // so the wait below is what actually synchronises on startup.
  app.main();
  try {
    // Debug builds replay onboarding on every launch, so 'Skip' can only be
    // the new widget tree. Waiting for it (rather than the tabs) stops a test
    // from racing the previous test's tree, which lingers until runApp.
    await pumpUntilFound(
      tester,
      kDebugMode ? skipButton : tab('Today'),
      timeout: const Duration(seconds: 60),
      reason: 'the freshly launched app (if the OS location permission dialog '
          'is showing, grant it: see integration_test/run_android.sh)',
    );
  } finally {
    // main() routes errors to Crashlytics. Put the test framework's handlers
    // back so a failure is reported as itself rather than as a confusing
    // "test overrode FlutterError.onError" assertion.
    FlutterError.onError = originalOnError;
    PlatformDispatcher.instance.onError = originalPlatformOnError;
  }
}

/// Dismisses onboarding if it is showing and waits for the main screen with
/// its period tabs.
Future<void> reachMainScreen(WidgetTester tester) async {
  if (skipButton.evaluate().isNotEmpty) {
    await tapAndPump(tester, skipButton);
  }
  await pumpUntilFound(tester, tab('Today'),
      reason: 'period tabs on the main screen');
}

/// Reaches the main screen and waits until the first page has real data
/// (location resolved, chart and stats rendered). If the OS location
/// permission was denied the app asks for a city first; pick one.
Future<void> reachLoadedMainScreen(WidgetTester tester) async {
  await launchApp(tester);
  await reachMainScreen(tester);

  final deadline = DateTime.now().add(networkTimeout);
  while (DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 250));
    final requiredSelector = find.text('Choose your location');
    if (requiredSelector.evaluate().isNotEmpty) {
      final london =
          textWidget((t) => t == 'London' || t.startsWith('London,'));
      await pumpUntilFound(tester, london, reason: 'a city in the selector');
      await tapAndPump(tester, london.first);
    }
    if (loadingLocation.evaluate().isEmpty &&
        visibleChart.evaluate().isNotEmpty) {
      await waitForStats(tester, timeout: const Duration(seconds: 30));
      return;
    }
  }
  fail('Main screen never finished loading data within '
      '${networkTimeout.inSeconds}s (check network / API / App Check). '
      'loadingLocation=${loadingLocation.evaluate().length}, '
      'charts=${find.byType(TemperatureBarChart).evaluate().length}, '
      'visibleCharts=${visibleChart.evaluate().length}, '
      'stats=${statsBlock().evaluate().length}');
}

Future<void> openSettings(WidgetTester tester) async {
  await tapAndPump(tester, find.byIcon(Icons.settings));
  await pumpUntilFound(tester, find.text('Temperature units'),
      reason: 'settings sheet');
}
