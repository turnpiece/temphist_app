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
  ///
  /// If [footerText] is provided a footer strip is composited below the chart
  /// so the description is baked into the image (avoiding Messages treating
  /// the image and share text as separate messages).
  Future<File?> captureWidget(GlobalKey repaintKey, {String? footerText}) async {
    try {
      final boundary = repaintKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) return null;

      const double pixelRatio = 2.0;
      final image = await boundary.toImage(pixelRatio: pixelRatio);

      // Footer dimensions (logical → physical pixels).
      const double footerLogicalHeight = 52.0;
      const double footerPaddingLogical = 16.0;
      final footerPx = footerText != null
          ? (footerLogicalHeight * pixelRatio).round()
          : 0;
      final totalHeight = image.height + footerPx;

      // Composite onto a solid background so the PNG is opaque on any surface.
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        Rect.fromLTWH(0, 0, image.width.toDouble(), totalHeight.toDouble()),
        Paint()..color = kBackgroundColour,
      );
      canvas.drawImage(image, Offset.zero, Paint());

      if (footerText != null) {
        // Darker footer strip below the chart.
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            image.height.toDouble(),
            image.width.toDouble(),
            footerPx.toDouble(),
          ),
          Paint()..color = kBackgroundColourDark,
        );

        // Footer text (single line, ellipsised if too long).
        final fontSize = 13.0 * pixelRatio;
        final paddingPx = footerPaddingLogical * pixelRatio;
        final paraBuilder = ui.ParagraphBuilder(
          ui.ParagraphStyle(
            fontSize: fontSize,
            fontFamily: 'sans-serif',
            maxLines: 1,
            ellipsis: '…',
          ),
        )
          ..pushStyle(ui.TextStyle(
            color: const Color(0xFFECECEC),
            fontSize: fontSize,
            fontWeight: ui.FontWeight.w500,
          ))
          ..addText(footerText);
        final para = paraBuilder.build()
          ..layout(ui.ParagraphConstraints(
            width: image.width - paddingPx * 2,
          ));
        // Vertically centre the text in the footer strip.
        final textY = image.height + (footerPx - para.height) / 2;
        canvas.drawParagraph(para, Offset(paddingPx, textY));
      }

      final composited = await recorder
          .endRecording()
          .toImage(image.width, totalHeight);

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

  /// Opens the system share sheet with the share URL.
  ///
  /// Passes the URL as a native NSURL activity item on iOS so that iMessage
  /// and other apps receive a tappable link rather than a plain string. Once
  /// the share page has Open Graph meta tags, platforms will also show a rich
  /// link-preview card (image + title + description) automatically.
  ///
  /// [shareButtonKey] is used to compute the popover anchor rect required on
  /// iPad. Pass the key attached to the share button widget.
  Future<void> share({
    required String shareUrl,
    GlobalKey? shareButtonKey,
  }) async {
    final rect = _buttonRect(shareButtonKey);
    await Share.shareUri(
      Uri.parse(shareUrl),
      sharePositionOrigin: rect,
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
