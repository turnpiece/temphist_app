import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/temperature_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../utils/debug_utils.dart';

/// Extension to capitalize the first letter of a string
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1);
  }
}

/// Custom exception for rate limit errors
class RateLimitException implements Exception {
  final String detail;
  final String message;
  
  RateLimitException(this.detail) : message = 'Rate limit exceeded: $detail';
  
  @override
  String toString() => message;
}

// Debug logging function that can be controlled globally
// @deprecated Use DebugUtils.logLazy() or DebugUtils.logSimple() directly for better performance
void debugLog(String message) {
  DebugUtils.logLazy(() => message);
}

class TemperatureService {
  final String apiBaseUrl;

  TemperatureService({
    String? apiBaseUrl,
  }) : apiBaseUrl = apiBaseUrl ?? AppConfig.apiBaseUrl;

  /// Retrieve Firebase ID token for authentication
  Future<String> getAuthToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not signed in');
    final token = await user.getIdToken();
    if (token == null) throw Exception('Failed to get Firebase ID token');
    return token;
  }

  Future<TemperatureData> fetchTemperature(String city, String date) async {
    return _fetchTemperatureData('weather', city, date);
  }

  Future<TemperatureData> fetchCompleteData(String city, String date) async {
    // Extract month-day from the date (e.g., "2025-06-18" -> "06-18")
    final monthDay = date.substring(5); // Get "06-18" from "2025-06-18"
    return _fetchTemperatureData('data', city, monthDay);
  }

  /// Common helper function for fetching data from API endpoints
  Future<Map<String, dynamic>> _fetchApiData(String endpoint, String city, String date) async {
    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/$endpoint/$city/$date');

    debugLog('Fetching /$endpoint/ for city=$city, date=$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      debugLog('${endpoint.capitalize()} API Response for $city/$date: $responseBody');
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      debugLog('${endpoint.capitalize()} API Error Response: ${response.statusCode} - ${response.body}');
      
      // Check if it's a rate limit error
      if (response.statusCode == 429) {
        try {
          final errorJson = jsonDecode(response.body);
          final detail = errorJson['detail']?.toString() ?? 'Rate limit exceeded';
          throw RateLimitException(detail);
        } catch (e) {
          throw RateLimitException('Rate limit exceeded');
        }
      }
      
      throw Exception('Failed to fetch $endpoint data: ${response.statusCode}');
    }
  }

  /// Common helper function for fetching TemperatureData from API endpoints
  Future<TemperatureData> _fetchTemperatureData(String endpoint, String city, String date) async {
    final json = await _fetchApiData(endpoint, city, date);
    return TemperatureData.fromJson(json);
  }

  Future<Map<String, dynamic>> fetchAverageData(String city, String date) async {
    return _fetchApiData('average', city, date);
  }

  Future<Map<String, dynamic>> fetchTrendData(String city, String date) async {
    return _fetchApiData('trend', city, date);
  }

  Future<Map<String, dynamic>> fetchSummaryData(String city, String date) async {
    return _fetchApiData('summary', city, date);
  }
}
