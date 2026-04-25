import 'package:flutter/material.dart';

import '../../../constants/app_constants.dart';
import '../../../services/temperature_unit_service.dart';
import '../visuals/unit_toggle_illustration.dart';

/// Onboarding page that explains temperature units and lets the user
/// pick °C or °F before they reach the main screen.
class OnboardingTemperatureUnitPage extends StatefulWidget {
  final TemperatureUnitService unitService;

  const OnboardingTemperatureUnitPage({super.key, required this.unitService});

  @override
  State<OnboardingTemperatureUnitPage> createState() =>
      _OnboardingTemperatureUnitPageState();
}

class _OnboardingTemperatureUnitPageState
    extends State<OnboardingTemperatureUnitPage> {
  late bool _isFahrenheit;

  @override
  void initState() {
    super.initState();
    _isFahrenheit = widget.unitService.isFahrenheit.value;
    widget.unitService.isFahrenheit.addListener(_onUnitChanged);
  }

  @override
  void dispose() {
    widget.unitService.isFahrenheit.removeListener(_onUnitChanged);
    super.dispose();
  }

  void _onUnitChanged() {
    if (mounted) setState(() => _isFahrenheit = widget.unitService.isFahrenheit.value);
  }

  void _setUnit(bool fahrenheit) => widget.unitService.setFahrenheit(fahrenheit);

  @override
  Widget build(BuildContext context) {
    return _buildPortrait();
  }

  Widget _buildPortrait() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 32),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isSmall = constraints.maxHeight < 500;
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: UnitToggleIllustration(
                        isFahrenheit: _isFahrenheit,
                        height: isSmall ? 110 : 160,
                      ),
                    ),
                    SizedBox(height: isSmall ? 16 : 40),
                    _titleWidget(fontSize: isSmall ? 20.0 : 24.0),
                    SizedBox(height: isSmall ? 10 : 16),
                    _bodyWidget(),
                    SizedBox(height: isSmall ? 16 : 28),
                    Center(child: _unitToggle()),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _titleWidget({double fontSize = 24.0}) => Text(
        'Units',
        style: TextStyle(
          color: kAccentColour,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      );

  Widget _bodyWidget() => const Text(
        "Choose whether you'd like temperatures shown in Celsius or "
        'Fahrenheit. You can change this at any time from the settings menu.',
        style: TextStyle(
          color: kTextPrimaryColour,
          fontSize: kFontSizeBody,
          height: 1.5,
        ),
      );

  Widget _unitToggle() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('°C', isActive: !_isFahrenheit, onTap: () => _setUnit(false)),
          _segment('°F', isActive: _isFahrenheit, onTap: () => _setUnit(true)),
        ],
      ),
    );
  }

  Widget _segment(
    String label, {
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: isActive
              ? kBarCurrentYearColour.withValues(alpha: 0.25)
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? kBarCurrentYearColour : kGreyLabelColour,
            fontSize: 22,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
