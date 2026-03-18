import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Illustration for the "switch location" onboarding page.
///
/// Mimics the app's location header (name + chevron) with a tap indicator
/// and a small bottom-sheet mockup showing a few location options.
class LocationSwitchIllustration extends StatelessWidget {
  const LocationSwitchIllustration({super.key});

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Mock app header strip
        Container(
          decoration: BoxDecoration(
            color: kBackgroundColourDark.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: kAccentColour.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                color: kAccentColour,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                'London',
                style: TextStyle(
                  color: kAccentColour,
                  fontSize: kFontSizeBody,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                Icons.keyboard_arrow_down,
                color: kAccentColour.withValues(alpha: 0.7),
                size: 20,
              ),
            ],
          ),
        ),
        // Tap indicator
        const SizedBox(height: 10),
        Icon(
          Icons.touch_app_outlined,
          color: kGreyLabelColour.withValues(alpha: 0.55),
          size: 32,
        ),
        // Mini bottom-sheet mockup
        const SizedBox(height: 10),
        Container(
          width: 220,
          decoration: BoxDecoration(
            color: kBackgroundColourDark,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: kGreyLabelColour.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('CURRENT'),
              _locationRow('London', isSelected: true),
              _divider(),
              _sectionLabel('RECENT'),
              _locationRow('Paris'),
              _locationRow('New York'),
              _divider(),
              _sectionLabel('POPULAR'),
              _locationRow('Tokyo'),
              _locationRow('Sydney'),
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 2),
        child: Text(
          text,
          style: TextStyle(
            color: kGreyLabelColour.withValues(alpha: 0.6),
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.6,
          ),
        ),
      );

  Widget _locationRow(String city, {bool isSelected = false}) {
    final color = isSelected ? kBarCurrentYearColour : kAccentColour;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Icon(Icons.location_on_outlined, size: 13, color: color),
          const SizedBox(width: 6),
          Text(
            city,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          if (isSelected) ...[
            const Spacer(),
            Icon(Icons.check, size: 13, color: kBarCurrentYearColour),
          ],
        ],
      ),
    );
  }

  Widget _divider() => Divider(
        height: 1,
        thickness: 0.5,
        color: kGreyLabelColour.withValues(alpha: 0.15),
        indent: 12,
        endIndent: 12,
      );
}
