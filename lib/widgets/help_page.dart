import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// A full-screen scrollable help page explaining how the app works.
///
/// Entry point: tapping "Help" in [SettingsSheet] dismisses the sheet and
/// navigates here using a slide-up transition.
class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  /// Push the help page onto the navigator with a slide-up animation.
  static Future<void> show(BuildContext context) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => const HelpPage(),
      transitionBuilder: (_, animation, __, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBackgroundColour, kBackgroundColourDark],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screenWidth = MediaQuery.of(context).size.width;
              final isTablet = screenWidth >= kTabletBreakpointWidth;
              final contentWidth = isTablet
                  ? kTabletMaxContentWidth.clamp(0.0, constraints.maxWidth)
                  : constraints.maxWidth;
              return Center(
                child: SizedBox(
                  width: contentWidth,
                  child: Column(
                    children: [
                      _Header(),
                      Divider(
                        color: kGreyLabelColour.withValues(alpha: 0.3),
                        height: 1,
                      ),
                      const Expanded(child: _Body()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
      child: Row(
        children: [
          const Text(
            'Help',
            style: TextStyle(
              color: kTextPrimaryColour,
              fontSize: kFontSizeBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.close,
              color: kGreyLabelColour,
              size: kIconSize + 2,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: kContentHorizontalMargin + kScreenPadding,
        vertical: kSectionTopPadding,
      ),
      children: const [
        _Section(
          title: 'What is TempHist?',
          body:
              'TempHist shows you temperature history for your location — same day, week, month and year — going back decades. See how today compares to years past.',
        ),
        _Section(
          title: 'Reading the chart',
          body:
              'Each bar represents the temperature recorded on the same date in a different year.',
          bullets: [
            _Bullet(color: kBarCurrentYearColour, label: 'Green bar — this year'),
            _Bullet(color: kBarOtherYearColour, label: 'Red bars — previous years'),
          ],
          footer: 'Tap any bar to see the exact temperature for that year.',
        ),
        _Section(
          title: 'Average and trend',
          body: 'The chart also shows two reference lines:',
          bullets: [
            _Bullet(color: kAverageColour, label: 'Average (blue line) — the historical mean temperature for this date.'),
            _Bullet(color: kTrendColour, label: 'Trend (yellow line) — shows whether temperatures are rising or falling over the decades.'),
          ],
          footer: 'Trend accuracy increases with longer time periods. The trend is most reliable on the Year view, where each data point averages a full year of readings. On the Day view it reflects a single date each year, so day-to-day weather variation can make it less meaningful.',
        ),
        _Section(
          title: 'Time periods',
          body: 'Swipe left and right to view different time periods:',
          items: [
            'Day — a single date across each year',
            'Week — the past week\'s average in each year',
            'Month — the past month\'s average in each year',
            'Year — the past year\'s average in each year',
          ],
        ),
        _Section(
          title: 'Location',
          body:
              'TempHist uses your GPS location to show data from the nearest weather station. The current location is shown at the top of the screen.',
          items: [
            'Recent locations — places where you have opened the app. When you first install it this will just be your current location, but the list grows as you open the app in new places.',
            'Popular locations — a curated list of cities you can browse and select manually.',
          ],
          footer:
              'To change location: tap the location name or go to Settings → Location, then choose from your recent or popular cities.',
        ),
        _Section(
          title: 'Settings',
          body: 'Tap the gear icon in the top-right corner to:',
          items: [
            'Switch between °C and °F',
            'Change location',
            'View this help page',
            'View the privacy policy',
          ],
        ),
        SizedBox(height: kSectionBottomPadding),
      ],
    );
  }
}

/// A single help section with a heading and body content.
class _Section extends StatelessWidget {
  final String title;
  final String body;
  final List<_Bullet>? bullets;
  final List<String>? items;
  final String? footer;

  const _Section({
    required this.title,
    required this.body,
    this.bullets,
    this.items,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: kSectionBottomPadding * 1.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: kTextPrimaryColour,
              fontSize: kFontSizeBody,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              color: kGreyLabelColour,
              fontSize: kFontSizeBody,
              height: 1.45,
            ),
          ),
          if (bullets != null) ...[
            const SizedBox(height: 10),
            ...bullets!.map((b) => _BulletRow(bullet: b)),
          ],
          if (items != null) ...[
            const SizedBox(height: 10),
            ...items!.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '• ',
                      style: TextStyle(
                        color: kGreyLabelColour,
                        fontSize: kFontSizeBody,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        item,
                        style: const TextStyle(
                          color: kGreyLabelColour,
                          fontSize: kFontSizeBody,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: 10),
            Text(
              footer!,
              style: const TextStyle(
                color: kGreyLabelColour,
                fontSize: kFontSizeBody,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A colour-dot + label row used inside [_Section].
class _Bullet {
  final Color color;
  final String label;

  const _Bullet({required this.color, required this.label});
}

class _BulletRow extends StatelessWidget {
  final _Bullet bullet;

  const _BulletRow({required this.bullet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 5, right: 8),
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: bullet.color,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              bullet.label,
              style: const TextStyle(
                color: kGreyLabelColour,
                fontSize: kFontSizeBody,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
