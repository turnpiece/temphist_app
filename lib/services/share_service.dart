import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:share_plus/share_plus.dart';

import '../constants/app_constants.dart';
import '../utils/debug_utils.dart';
import 'temperature_service.dart';

class ShareService {
  final TemperatureService _temperatureService;

  ShareService({TemperatureService? temperatureService})
      : _temperatureService = temperatureService ?? TemperatureService();

  /// Creates a share record on the server and returns the short share URL.
  Future<String> createShare({
    required String location,
    required String period,
    required String identifier,
    required int refYear,
    required String unit,
  }) async {
    final token = await _temperatureService.getAuthToken();
    final url =
        Uri.parse('${_temperatureService.apiBaseUrl}/v1/shares');

    DebugUtils.logLazy(() => 'ShareService: creating share for $period/$identifier ($location)');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'location': location,
        'period': kApiRecordsPeriodSegment(period),
        'identifier': identifier,
        'ref_year': refYear,
        'unit': unit,
      }),
    ).timeout(const Duration(seconds: kApiTimeoutSeconds));

    DebugUtils.logLazy(() => 'ShareService: response ${response.statusCode} — ${response.body}');

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to create share: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    return data['url'] as String;
  }

  /// Opens the system share sheet with the share URL.
  ///
  /// Passes the URL as a native NSURL activity item on iOS so iMessage and
  /// other apps receive a tappable rich link card (image + title + domain)
  /// built from the share page's Open Graph tags — matching the single
  /// clickable card produced when sharing from the website.
  ///
  /// [shareButtonKey] is used to compute the popover anchor rect required on
  /// iPad. Pass the key attached to the share button widget.
  Future<void> share({
    required String shareUrl,
    GlobalKey? shareButtonKey,
  }) async {
    final rect = _buttonRect(shareButtonKey);
    await SharePlus.instance.share(
      ShareParams(
        uri: Uri.parse(shareUrl),
        sharePositionOrigin: rect,
      ),
    );
  }

  /// Returns the screen rect of [key]'s widget, or a fallback rect at the
  /// centre of the screen if the key has no render object.
  Rect _buttonRect(GlobalKey? key) {
    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        return pos & box.size;
      }
    }
    // Fallback: centre of the screen. A (0,0) rect can silently prevent the
    // share sheet from presenting on physical iOS devices.
    final view = ui.PlatformDispatcher.instance.views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return Rect.fromLTWH(size.width / 2, size.height / 2, 1, 1);
  }
}
