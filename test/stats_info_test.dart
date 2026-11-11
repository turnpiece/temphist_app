import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:temphist_app/widgets/stats_info.dart';

Widget _harness({double textScale = 1.0}) {
  return MaterialApp(
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: const Scaffold(body: SingleChildScrollView(child: _Box())),
  );
}

/// Mirrors how the stats box toggles the note.
class _Box extends StatefulWidget {
  const _Box();

  @override
  State<_Box> createState() => _BoxState();
}

class _BoxState extends State<_Box> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Align(
          alignment: Alignment.topRight,
          child: StatsInfoButton(
            expanded: _expanded,
            onPressed: () => setState(() => _expanded = !_expanded),
          ),
        ),
        if (_expanded) const StatsInfoNote(),
      ],
    );
  }
}

void main() {
  testWidgets('button has a semantics label and starts collapsed',
      (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(_harness());

    expect(
        find.bySemanticsLabel('What do these numbers mean?'), findsOneWidget);
    expect(find.textContaining('Average: the mean'), findsNothing);
    handle.dispose();
  });

  testWidgets('tapping toggles the plain-English note', (tester) async {
    await tester.pumpWidget(_harness());

    await tester.tap(find.bySemanticsLabel('What do these numbers mean?'));
    await tester.pump();

    expect(find.textContaining('mean of the 51 yearly values'), findsOneWidget);
    expect(find.textContaining('one standard error'), findsOneWidget);
    expect(find.textContaining('about twice its ±'), findsOneWidget);
    expect(find.textContaining('Standard deviation: how much'), findsOneWidget);
    expect(find.text('More about the numbers'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('What do these numbers mean?'));
    await tester.pump();
    expect(find.textContaining('mean of the 51 yearly values'), findsNothing);
  });

  testWidgets('does not overflow on a narrow phone at large text',
      (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 568 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness(textScale: 2.0));
    await tester.tap(find.bySemanticsLabel('What do these numbers mean?'));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets('"More about the numbers" opens the Help page at the section',
      (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 844 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_harness());
    await tester.tap(find.bySemanticsLabel('What do these numbers mean?'));
    await tester.pump();
    await tester.tap(find.text('More about the numbers'));
    await tester.pumpAndSettle();

    expect(find.text('Help'), findsOneWidget);
    expect(find.text('How certain is the trend?'), findsOneWidget);
  });
}
