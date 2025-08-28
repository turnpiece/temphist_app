import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/temperature_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../utils/debug_utils.dart';

// Debug logging function that can be controlled globally
void debugLog(String message) {
  DebugUtils.log(message);
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
    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/weather/$city/$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      debugLog('API Response for $city/$date: $responseBody');
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return TemperatureData.fromJson(json);
    } else {
      debugLog('API Error Response: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch temperature data: ${response.statusCode}');
    }
  }

  Future<TemperatureData> fetchCompleteData(String city, String date) async {
    final token = await getAuthToken();
    // Extract month-day from the date (e.g., "2025-06-18" -> "06-18")
    final monthDay = date.substring(5); // Get "06-18" from "2025-06-18"
    final url = Uri.parse('$apiBaseUrl/data/$city/$monthDay');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      debugLog('Complete API Response for $city/$monthDay: $responseBody');
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return TemperatureData.fromJson(json);
    } else {
      debugLog('Complete API Error Response: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch complete temperature data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchAverageData(String city, String date) async {
    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/average/$city/$date');

    debugLog('Fetching /average/ for city=$city, date=$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      debugLog('Average API Response for $city/$date: $responseBody');
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      debugLog('Average API Error Response: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch average data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchTrendData(String city, String date) async {
    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/trend/$city/$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      debugLog('Trend API Response for $city/$date: $responseBody');
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      debugLog('Trend API Error Response: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch trend data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchSummaryData(String city, String date) async {
    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/summary/$city/$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      debugLog('Summary API Response for $city/$date: $responseBody');
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      debugLog('Summary API Error Response: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to fetch summary data: ${response.statusCode}');
    }
  }
}
