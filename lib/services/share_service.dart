import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/app_config.dart';
import '../constants/app_constants.dart';
import '../utils/debug_utils.dart';
import 'temperature_service.dart';

class ShareService {
  final TemperatureService _temperatureService;

  ShareService() : _temperatureService = TemperatureService();

  /// Maps the app's short period keys to the API's canonical period names.
  static String _apiPeriod(String period) => switch (period) {
        'week' => 'weekly',
        'month' => 'monthly',
        'year' => 'yearly',
        _ => period, // 'daily' passes through unchanged
      };

  /// Creates a share record on the server and returns the short share URL.
  Future<String> createShare({
    required String location,
    required String period,
    required String identifier,
    required int refYear,
    required String unit,
  }) async {
    final token = await _temperatureService.getAuthToken();
    final url = Uri.parse('${AppConfig.apiBaseUrl}/v1/shares');

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
        'period': _apiPeriod(period),
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

  /// Captures the widget identified by [repaintKey] as a PNG file in the
  /// temporary directory. Returns null if capture fails.
  Future<File?> captureWidget(GlobalKey repaintKey) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: 2.0);

      // Composite onto a solid background so the PNG is opaque on any surface.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        Paint()..color = kBackgroundColour,
      );
      canvas.drawImage(image, Offset.zero, Paint());
      final composited = await recorder
          .endRecording()
          .toImage(image.width, image.height);

      final byteData =
          await composited.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return null;

      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/temphist_share.png');
      await file.writeAsBytes(byteData.buffer.asUint8List());
      return file;
    } catch (e) {
      DebugUtils.logLazy(() => 'ShareService: image capture failed: $e');
      return null;
    }
  }

  /// Opens the system share sheet with the chart image (if available) and URL.
  ///
  /// [shareButtonKey] is used to compute the popover anchor rect required on
  /// iPad. Pass the key attached to the share button widget.
  Future<void> share({
    required String shareUrl,
    required String text,
    File? imageFile,
    GlobalKey? shareButtonKey,
  }) async {
    final rect = _buttonRect(shareButtonKey);
    if (imageFile != null) {
      await Share.shareXFiles(
        [XFile(imageFile.path)],
        text: '$text\n$shareUrl',
        sharePositionOrigin: rect,
      );
    } else {
      await Share.share(
        '$text\n$shareUrl',
        sharePositionOrigin: rect,
      );
    }
  }

  /// Returns the screen rect of [key]'s widget, or a small fallback rect at
  /// the top-right of the screen if the key has no render object.
  Rect _buttonRect(GlobalKey? key) {
    if (key?.currentContext != null) {
      final box = key!.currentContext!.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final pos = box.localToGlobal(Offset.zero);
        return pos & box.size;
      }
    }
    // Fallback: top-right corner (safe for iPhone too).
    return const Rect.fromLTWH(0, 0, 1, 1);
  }
}
