// What happens when the user refuses the location permission: the app must
// fall back to asking for a city and carry on working.
//
// Needs the permission to be refused up front (the OS dialog is native and
// can't be tapped from here):
//
//   integration_test/run_android.sh --deny-location [device-id]

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'support.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // One test, not two: choosing a city (and even the London fallback) is
  // cached, after which the app stops asking.
  testWidgets('refusing location asks for a city; back cannot skip it',
      (tester) async {
    await launchApp(tester);
    // The selector covers the tabs, so don't wait for them (reachMainScreen).
    await tapAndPump(tester, skipButton);

    // Required selector: titled "Choose your location", no close button.
    await pumpUntilFound(tester, find.text('Choose your location'),
        timeout: networkTimeout, reason: 'the required location selector');
    expect(find.text('Choose location'), findsNothing,
        reason: 'the dismissable selector should not be shown');
    expect(find.byIcon(Icons.close), findsNothing,
        reason: 'a required selector has no close button');

    // The Android back button must not be a way out of a required choice.
    await tester.binding.handlePopRoute();
    await pumpFor(tester, const Duration(seconds: 1));
    expect(find.text('Choose your location'), findsOneWidget,
        reason: 'back should not dismiss the required selector');

    final search = find.byType(TextField);
    await tester.enterText(search, 'Paris');
    await pumpFor(tester, const Duration(milliseconds: 500));
    await tester.testTextInput.receiveAction(TextInputAction.go);
    final result = textWidget((t) => t.startsWith('Paris'));
    await pumpUntilFound(tester, result,
        timeout: networkTimeout, reason: 'a Paris search result');
    await tapAndPump(tester, result.first);

    await pumpUntilGone(tester, find.text('Choose your location'));
    await pumpUntilFound(tester, textWidget((t) => t.startsWith('Paris')),
        reason: 'Paris in the location header');
    await waitForStats(tester, reason: 'Paris data to load');
    expect(visibleChart, findsWidgets);
  });
}
