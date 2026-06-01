import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import '../constants/app_constants.dart';
import '../models/selection_method.dart';
import '../utils/debug_utils.dart';
import 'temperature_service.dart';

class AnalyticsService {
  /// Submit an analytics event to `POST /analytics`.
  ///
  /// All parameters except [requestedLocation] and [selectionMethod] are
  /// optional. Failures are always swallowed — analytics must never degrade
  /// the core weather experience.
  static Future<void> submit({
    required String requestedLocation,
    required SelectionMethod selectionMethod,
    String? canonicalLocation,
    int? responseTimeMs,
    bool? cacheHit,
    String? apiBaseUrl,
  }) async {
    try {
      final platform = io.Platform.isIOS
          ? 'ios'
          : io.Platform.isAndroid
              ? 'android'
              : 'mobile';

      final payload = <String, dynamic>{
        'requested_location': requestedLocation,
        'selection_method': selectionMethod.apiValue,
        'platform': platform,
      };
      if (canonicalLocation != null) {
        payload['canonical_location'] = canonicalLocation;
      }
      if (responseTimeMs != null) payload['response_time_ms'] = responseTimeMs;
      if (cacheHit != null) payload['cache_hit'] = cacheHit;

      final service = TemperatureService(apiBaseUrl: apiBaseUrl);
      final token = await service.getAuthToken();

      final response = await http
          .post(
            Uri.parse('${apiBaseUrl ?? kApiBaseUrl}/analytics'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: kApiTimeoutSeconds));

      DebugUtils.logLazy(
          () => 'AnalyticsService: submitted → HTTP ${response.statusCode}');
    } catch (e) {
      DebugUtils.logLazy(
          () => 'AnalyticsService: POST failed (swallowed): $e');
    }
  }
}
