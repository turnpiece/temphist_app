import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_constants.dart';

/// The "Weather data by Open-Meteo.com" credit.
///
/// Open-Meteo's licence (CC BY 4.0) requires a link next to wherever its data
/// is displayed, so this sits directly under the stats bubble on each period
/// page. The Help page carries the fuller attribution.
class DataAttribution extends StatelessWidget {
  const DataAttribution({super.key});

  Future<void> _open(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await launchUrl(
      Uri.parse(kOpenMeteoUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open the link.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      child: InkWell(
        onTap: () => _open(context),
        child: const Padding(
          // Vertical padding gives a comfortable tap target without changing
          // how the small credit text looks.
          padding: EdgeInsets.symmetric(vertical: 8),
          // Deliberately ignores the system text size: the credit is
          // secondary, and scaling it would let it outgrow the stats above it.
          child: Text(
            kOpenMeteoCreditText,
            textScaler: TextScaler.noScaling,
            style: TextStyle(
              color: kGreyLabelColour,
              fontSize: kFontSizeBody - 3,
              height: 1.4,
              decoration: TextDecoration.underline,
              decorationColor: kGreyLabelColour,
            ),
          ),
        ),
      ),
    );
  }
}
