import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';

/// Illustration for the temperature unit onboarding page.
/// Shows °C and °F side by side, with the active unit highlighted.
class UnitToggleIllustration extends StatelessWidget {
  final bool isFahrenheit;
  final double height;

  const UnitToggleIllustration({
    super.key,
    required this.isFahrenheit,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: 1.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _unitDisplay('22', '°C', isSelected: !isFahrenheit),
            const SizedBox(width: 16),
            Container(
              height: 60,
              width: 1,
              color: kGreyLabelColour.withValues(alpha: 0.3),
            ),
            const SizedBox(width: 16),
            _unitDisplay('72', '°F', isSelected: isFahrenheit),
          ],
        ),
      ),
    );
  }

  Widget _unitDisplay(String number, String unit, {required bool isSelected}) {
    final numberFontSize = height < 130 ? 36.0 : 56.0;
    final unitFontSize = height < 130 ? 18.0 : 28.0;
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isSelected ? 1.0 : 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            number,
            style: TextStyle(
              color: isSelected ? kBarCurrentYearColour : kTextPrimaryColour,
              fontSize: numberFontSize,
              fontWeight: FontWeight.w300,
              letterSpacing: -2,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              color: isSelected ? kBarCurrentYearColour : kTextPrimaryColour,
              fontSize: unitFontSize,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w300,
            ),
          ),
        ],
      ),
    );
  }
}
