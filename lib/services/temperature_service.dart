import 'dart:convert';
import 'dart:async';
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

  /// Retrieve Firebase ID token for authentication with retry logic
  Future<String> getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugLog('⚠️ No Firebase user found, attempting to sign in...');
        // Try to sign in if no user is found
        await _signInWithRetry();
        final newUser = FirebaseAuth.instance.currentUser;
        if (newUser == null) {
          throw Exception('Unable to authenticate with Firebase');
        }
        final token = await newUser.getIdToken();
        if (token == null) throw Exception('Failed to get Firebase ID token');
        return token;
      }
      
      final token = await user.getIdToken();
      if (token == null) throw Exception('Failed to get Firebase ID token');
      return token;
    } catch (e) {
      debugLog('❌ Firebase authentication failed: $e');
      // If Firebase auth fails completely, we could implement a fallback
      // For now, we'll rethrow the error to be handled by the calling code
      throw Exception('Firebase authentication failed: $e');
    }
  }

  /// Sign in with retry logic for service-level authentication
  Future<void> _signInWithRetry({int maxRetries = 2}) async {
    int attempts = 0;
    
    while (attempts < maxRetries) {
      try {
        attempts++;
        debugLog('🔐 Service-level Firebase auth attempt $attempts/$maxRetries');
        
        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: 15),
          onTimeout: () {
            throw TimeoutException('Firebase authentication timed out', const Duration(seconds: 15));
          },
        );
        
        debugLog('✅ Service-level Firebase authentication successful');
        return;
        
      } catch (e) {
        debugLog('❌ Service-level Firebase auth attempt $attempts failed: $e');
        
        if (attempts >= maxRetries) {
          throw Exception('All Firebase auth attempts failed: $e');
        }
        
        // Wait before retrying
        await Future.delayed(Duration(seconds: attempts));
      }
    }
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
      
      // Parse API error response to extract meaningful error message
      String errorMessage = 'Failed to fetch $endpoint data: ${response.statusCode}';
      try {
        final errorJson = jsonDecode(response.body);
        if (errorJson is Map<String, dynamic>) {
          final apiError = errorJson['error']?.toString();
          final apiStatus = errorJson['status']?.toString();
          
          if (apiError != null && apiError.isNotEmpty) {
            errorMessage = apiError;
            // Add status code context if available
            if (apiStatus != null && apiStatus.isNotEmpty) {
              errorMessage += ' (Status: $apiStatus)';
            }
          }
        }
      } catch (e) {
        // If we can't parse the error response, use the original message
        debugLog('Could not parse API error response: $e');
      }
      
      throw Exception(errorMessage);
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
