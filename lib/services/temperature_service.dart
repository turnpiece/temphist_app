import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/temperature_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TemperatureService {
  final String apiBaseUrl;

  TemperatureService({
    this.apiBaseUrl = 'https://api.temphist.com',
  });

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
      print('API Response for $city/$date: $responseBody'); // Debug log
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return TemperatureData.fromJson(json);
    } else {
      print('API Error Response: ${response.statusCode} - ${response.body}'); // Debug log
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
      print('Complete API Response for $city/$monthDay: $responseBody'); // Debug log
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return TemperatureData.fromJson(json);
    } else {
      print('Complete API Error Response: ${response.statusCode} - ${response.body}'); // Debug log
      throw Exception('Failed to fetch complete temperature data: ${response.statusCode}');
    }
  }

  Future<Map<String, dynamic>> fetchAverageData(String city, String date) async {
    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/average/$city/$date');

    print('DEBUG: Fetching /average/ for city=$city, date=$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      print('Average API Response for $city/$date: $responseBody'); // Debug log
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      print('Average API Error Response: ${response.statusCode} - ${response.body}'); // Debug log
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
      print('Trend API Response for $city/$date: $responseBody'); // Debug log
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      print('Trend API Error Response: ${response.statusCode} - ${response.body}'); // Debug log
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
      print('Summary API Response for $city/$date: $responseBody'); // Debug log
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      print('Summary API Error Response: \\${response.statusCode} - \\${response.body}'); // Debug log
      throw Exception('Failed to fetch summary data: \\${response.statusCode}');
    }
  }
}
