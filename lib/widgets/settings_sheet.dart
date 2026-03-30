import 'package:flutter/material.dart';

import '../constants/app_constants.dart';

/// A bottom-aligned settings modal with the same slide-up animation as
/// [LocationSelectorSheet].
///
/// Current rows:
///   • Temperature units — °C / °F segmented toggle
///   • Location — opens the location selector
///   • Help — placeholder (no action yet)
class SettingsSheet extends StatefulWidget {
  final bool isFahrenheit;
  final ValueChanged<bool> onUnitChanged;
  final VoidCallback onOpenLocationSelector;

  const SettingsSheet({
    super.key,
    required this.isFahrenheit,
    required this.onUnitChanged,
    required this.onOpenLocationSelector,
  });

  /// Show the settings sheet using the same dialog + slide-up animation
  /// pattern as [LocationSelectorSheet].
  static Future<void> show(
    BuildContext context, {
    required bool isFahrenheit,
    required ValueChanged<bool> onUnitChanged,
    required VoidCallback onOpenLocationSelector,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, __, ___) => SettingsSheet(
        isFahrenheit: isFahrenheit,
        onUnitChanged: onUnitChanged,
        onOpenLocationSelector: onOpenLocationSelector,
      ),
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
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late bool _isFahrenheit;

  @override
  void initState() {
    super.initState();
    _isFahrenheit = widget.isFahrenheit;
  }

  void _toggleUnit(bool fahrenheit) {
    setState(() => _isFahrenheit = fahrenheit);
    widget.onUnitChanged(fahrenheit);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [kBackgroundColour, kBackgroundColourDark],
            ),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 12),
                  child: Row(
                    children: [
                      const Text(
                        'Settings',
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
                ),
                Divider(
                  color: kGreyLabelColour.withValues(alpha: 0.3),
                  height: 1,
                ),

                // Temperature units row
                _SettingsRow(
                  icon: Icons.thermostat_outlined,
                  label: 'Temperature units',
                  trailing: _UnitToggle(
                    isFahrenheit: _isFahrenheit,
                    onChanged: _toggleUnit,
                  ),
                ),

                // Location row
                _SettingsRow(
                  icon: Icons.location_on_outlined,
                  label: 'Location',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: kGreyLabelColour,
                    size: kIconSize + 4,
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    widget.onOpenLocationSelector();
                  },
                ),

                // Help row
                _SettingsRow(
                  icon: Icons.help_outline,
                  label: 'Help',
                  trailing: Icon(
                    Icons.chevron_right,
                    color: kGreyLabelColour,
                    size: kIconSize + 4,
                  ),
                  onTap: () {
                    // Placeholder — no action yet.
                  },
                ),

                // Bottom spacing
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A single row in the settings sheet.
class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget trailing;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: kGreyLabelColour, size: kIconSize + 3),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: kTextPrimaryColour,
                  fontSize: kFontSizeBody,
                ),
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

/// A pair of tappable °C / °F labels — the active one is highlighted in green.
class _UnitToggle extends StatelessWidget {
  final bool isFahrenheit;
  final ValueChanged<bool> onChanged;

  const _UnitToggle({
    required this.isFahrenheit,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('°C', isActive: !isFahrenheit, onTap: () => onChanged(false)),
          _segment('°F', isActive: isFahrenheit, onTap: () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(String label, {required bool isActive, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: isActive ? kBarCurrentYearColour.withValues(alpha: 0.25) : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isActive ? kBarCurrentYearColour : kGreyLabelColour,
            fontSize: kFontSizeBody,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
