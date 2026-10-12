import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';
import 'onboarding/visuals/average_trend_illustration.dart';
import 'onboarding/visuals/day_chart_illustration.dart';

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
    // This page is a full-screen dialog route, so a SnackBar shown through the
    // app's root ScaffoldMessenger would sit underneath it. A local messenger
    // and Scaffold keep the "could not open link" message on this page.
    return ScaffoldMessenger(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Material(
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
              'Each bar represents the mean temperature for the same date, week, month or year in a different year. Bar colours show how warm or cool that year was compared with the 50-year average.',
          visual: DayChartIllustration(height: 180),
          bullets: [
            _Bullet(
                color: kBarCoolColour,
                label: 'Blue bars — cooler than average years'),
            _Bullet(
                color: kBarWarmColour,
                label: 'Red bars — warmer than average years'),
          ],
          footer:
              'Tap any bar to see the temperature for that period in that year, and how far it was above or below the historical average.',
        ),
        _Section(
          title: 'Average and trend',
          body: 'The chart also shows two reference lines:',
          visual: AverageTrendIllustration(height: 220),
          bullets: [
            _Bullet(
                color: kAverageColour,
                label:
                    'Average (grey dotted line) — the historical mean temperature for this series.'),
            _Bullet(
                color: kTrendColour,
                label:
                    'Trend (yellow line) — shows whether temperatures are rising, falling or steady over the decades.'),
          ],
          footer:
              'The error margin on the trend gives an idea as to how reliable it is. Trend accuracy increases with longer time periods. The trend is most reliable on the Year view, where each data point averages a full year of readings. On the Day view it reflects a single date each year, so day-to-day weather variation can make it less meaningful.',
        ),
        _Section(
          title: 'Where the data comes from',
          body:
              'The temperatures are the ERA5 reanalysis, produced by ECMWF for the Copernicus Climate Change Service and delivered through Open-Meteo. The record starts in 1940.',
          items: [
            'A reanalysis re-runs a weather model over past decades so that it agrees with the observations available at the time.',
            'Each value is a modelled estimate of the daily mean air temperature for a grid cell about 25 km across, not a reading from a single weather station. It can differ from official station records, especially in cities, on coasts and in hills.',
            'The newest few days come from Open-Meteo\'s forecast model, so today\'s value can sit slightly above or below the history it is compared with.',
          ],
          richFooter: [
            _TextPart('Weather data by '),
            _TextPart('Open-Meteo.com', url: 'https://open-meteo.com'),
            _TextPart(', licensed under '),
            _TextPart('CC BY 4.0',
                url: 'https://creativecommons.org/licenses/by/4.0/'),
            _TextPart('. Generated using '),
            _TextPart('Copernicus Climate Change Service',
                url: 'https://climate.copernicus.eu'),
            _TextPart(
                ' information 2022. Data set: Hersbach, H. et al. (2023). '),
            _TextPart('ERA5 hourly data on single levels from 1940 to present',
                url: 'https://doi.org/10.24381/cds.adbb2d47'),
            _TextPart('. ECMWF.'),
          ],
        ),
        _Section(
          title: 'How the numbers are made',
          body:
              'For the date you are viewing, each of the last 51 years (this year and the 50 before it) gets a single value: the mean of the daily temperatures in a window ending on that date. The window is the day itself for Today, the 7 days ending on it for Week, 31 days for Month and 365 days for Year.',
          items: [
            'The average is the mean of those yearly values.',
            'The trend is a straight-line fit through the yearly values, in °C (or °F) per decade, with an error margin.',
          ],
          footer: 'A trend describes the past; it is not a forecast.',
        ),
        _Section(
          title: 'Time periods',
          body: 'Swipe left and right to view different time periods:',
          items: [
            'Today — today\'s date in each year',
            'Week — the past week\'s average in each year',
            'Month — the past month\'s average in each year',
            'Year — the past year\'s average in each year',
          ],
        ),
        _Section(
          title: 'Location',
          body:
              'Tap the location name at the top of the screen to switch location. The selector shows:',
          items: [
            'Current — your actual location, detected automatically.',
            'Visited — places where you have opened the app. The list grows as you travel.',
            'Popular — frequently selected cities across all users, updated monthly.',
          ],
          footer:
              'Use the search box to find any city by name. It also shows locations you\'ve previously searched for or selected.',
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
  final Widget? visual;
  final List<_Bullet>? bullets;
  final List<String>? items;
  final String? footer;

  /// A footer made of plain text and tappable links. Shown instead of
  /// [footer] when both are given, in a slightly smaller size since it is
  /// a credit line rather than explanatory text.
  final List<_TextPart>? richFooter;

  const _Section({
    required this.title,
    required this.body,
    this.visual,
    this.bullets,
    this.items,
    this.footer,
    this.richFooter,
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
          if (visual != null) ...[
            const SizedBox(height: 16),
            visual!,
          ],
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
          if (richFooter != null) ...[
            const SizedBox(height: 10),
            _LinkText(parts: richFooter!),
          ] else if (footer != null) ...[
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

/// One run of text inside a [_LinkText]; tappable when [url] is set.
class _TextPart {
  final String text;
  final String? url;

  const _TextPart(this.text, {this.url});
}

/// Body-style text with inline external links.
///
/// Stateful only so the [TapGestureRecognizer]s are created once and disposed.
class _LinkText extends StatefulWidget {
  final List<_TextPart> parts;

  const _LinkText({required this.parts});

  @override
  State<_LinkText> createState() => _LinkTextState();
}

class _LinkTextState extends State<_LinkText> {
  late final List<TapGestureRecognizer?> _recognizers;

  @override
  void initState() {
    super.initState();
    _recognizers = [
      for (final part in widget.parts)
        if (part.url != null)
          (TapGestureRecognizer()..onTap = () => _open(part.url!))
        else
          null,
    ];
  }

  @override
  void dispose() {
    for (final recognizer in _recognizers) {
      recognizer?.dispose();
    }
    super.dispose();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!mounted || ok) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the link.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: const TextStyle(
          color: kGreyLabelColour,
          fontSize: kFontSizeBody - 2,
          height: 1.45,
        ),
        children: [
          for (var i = 0; i < widget.parts.length; i++)
            TextSpan(
              text: widget.parts[i].text,
              recognizer: _recognizers[i],
              style: widget.parts[i].url == null
                  ? null
                  : const TextStyle(
                      color: kTextPrimaryColour,
                      decoration: TextDecoration.underline,
                      decorationColor: kTextPrimaryColour,
                    ),
            ),
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
            padding: const EdgeInsets.only(right: 8),
            child: SizedBox(
              height: kFontSizeBody * 1.55,
              child: Center(
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: bullet.color,
                    shape: BoxShape.circle,
                  ),
                ),
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
