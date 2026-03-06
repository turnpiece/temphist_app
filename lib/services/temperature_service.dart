import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import '../models/temperature_data.dart';
import '../models/period_temperature_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/app_config.dart';
import '../utils/debug_utils.dart';
import '../constants/app_constants.dart';

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

class TemperatureService {
  static final Map<String, PeriodTemperatureData> _periodCache = {};
  final String apiBaseUrl;

  /// Clears all cached period data. Call on refresh so stale data is not served.
  static void clearCache() {
    _periodCache.clear();
  }

  TemperatureService({
    String? apiBaseUrl,
  }) : apiBaseUrl = apiBaseUrl ?? AppConfig.apiBaseUrl;

  /// Retrieve Firebase ID token for authentication with retry logic
  Future<String> getAuthToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        DebugUtils.logLazy(() => '⚠️ No Firebase user found, attempting to sign in...');
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
      DebugUtils.logLazy(() => '❌ Firebase authentication failed: $e');
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
        DebugUtils.logLazy(() => '🔐 Service-level Firebase auth attempt $attempts/$maxRetries');
        
        await FirebaseAuth.instance.signInAnonymously().timeout(
          const Duration(seconds: kFirebaseAuthTimeoutSeconds),
          onTimeout: () {
            throw TimeoutException('Firebase authentication timed out', const Duration(seconds: kFirebaseAuthTimeoutSeconds));
          },
        );
        
        DebugUtils.logLazy(() => '✅ Service-level Firebase authentication successful');
        return;
        
      } catch (e) {
        DebugUtils.logLazy(() => '❌ Service-level Firebase auth attempt $attempts failed: $e');
        
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
    final monthDay = date.length >= 10 ? date.substring(5) : date;
    final json = await _fetchV1Records('daily', city, monthDay);
    return TemperatureData.fromJson(json);
  }

  /// Common helper function for fetching data from API endpoints
  Future<Map<String, dynamic>> _fetchApiData(String endpoint, String city, String date) async {
    final normalizedEndpoint = endpoint.replaceAll('/', '').toLowerCase();

    // Legacy endpoints for summary/average/trend were removed; route to v1.
    if (normalizedEndpoint == 'summary' ||
        normalizedEndpoint == 'average' ||
        normalizedEndpoint == 'trend') {
      final json =
          await _fetchV1Subresource('daily', city, date, normalizedEndpoint);
      final data = json['data'];
      if (normalizedEndpoint == 'summary') {
        return {
          'summary': data,
          'metadata': json['metadata'],
          'period': json['period'],
          'location': json['location'],
          'identifier': json['identifier'],
        };
      }
      if (normalizedEndpoint == 'average') {
        final mean = (data is Map<String, dynamic>) ? data['mean'] : null;
        return {
          'average': mean,
          'data': data,
          'metadata': json['metadata'],
          'period': json['period'],
          'location': json['location'],
          'identifier': json['identifier'],
        };
      }
      final slope = (data is Map<String, dynamic>) ? data['slope'] : null;
      final unit = (data is Map<String, dynamic>) ? data['unit'] : null;
      return {
        'slope': slope,
        'unit': unit,
        'data': data,
        'metadata': json['metadata'],
        'period': json['period'],
        'location': json['location'],
        'identifier': json['identifier'],
      };
    }

    final token = await getAuthToken();
    final url = Uri.parse('$apiBaseUrl/$normalizedEndpoint/$city/$date');

    DebugUtils.logLazy(() => 'Fetching /$normalizedEndpoint/ for city=$city, date=$date');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseBody = response.body;
      DebugUtils.logLazy(
        () => '${normalizedEndpoint.capitalize()} API Response for $city/$date: $responseBody',
      );
      
      if (responseBody.isEmpty) {
        throw Exception('Empty response from API');
      }
      
      final json = jsonDecode(responseBody);
      if (json == null) {
        throw Exception('API returned null response');
      }
      
      return json;
    } else {
      DebugUtils.logLazy(
        () => '${normalizedEndpoint.capitalize()} API Error Response: ${response.statusCode} - ${response.body}',
      );
      
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
      
      throw Exception(
        'Failed to fetch $normalizedEndpoint data: ${response.statusCode}',
      );
    }
  }

  /// Fetch v1 records data (full response) for a specific period and identifier.
  Future<Map<String, dynamic>> _fetchV1Records(
    String period,
    String location,
    String identifier,
  ) async {
    final token = await getAuthToken();
    final apiPeriod = _apiPeriodPath(period);
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse(
      '$apiBaseUrl/v1/records/$apiPeriod/$encodedLocation/$identifier',
    );

    DebugUtils.logLazy(() => 'Fetching v1 records: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded fetching v1 records');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch v1 records: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Fetch a v1 subresource (average/trend/summary) for daily records.
  Future<Map<String, dynamic>> _fetchV1Subresource(
    String period,
    String location,
    String identifier,
    String subresource,
  ) async {
    final token = await getAuthToken();
    final apiPeriod = _apiPeriodPath(period);
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse(
      '$apiBaseUrl/v1/records/$apiPeriod/$encodedLocation/$identifier/$subresource',
    );

    DebugUtils.logLazy(() => 'Fetching v1 subresource ($subresource): $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded fetching $subresource');
    }

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch $subresource: ${response.statusCode}');
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Common helper function for fetching TemperatureData from API endpoints
  Future<TemperatureData> _fetchTemperatureData(String endpoint, String city, String date) async {
    final json = await _fetchApiData(endpoint, city, date);
    return TemperatureData.fromJson(json);
  }

  Future<Map<String, dynamic>> fetchAverageData(String city, String date) async {
    final json = await _fetchV1Subresource('daily', city, date, 'average');
    final data = json['data'];
    final mean = (data is Map<String, dynamic>) ? data['mean'] : null;
    return {
      'average': mean,
      'data': data,
      'metadata': json['metadata'],
      'period': json['period'],
      'location': json['location'],
      'identifier': json['identifier'],
    };
  }

  Future<Map<String, dynamic>> fetchTrendData(String city, String date) async {
    final json = await _fetchV1Subresource('daily', city, date, 'trend');
    final data = json['data'];
    final slope = (data is Map<String, dynamic>) ? data['slope'] : null;
    final unit = (data is Map<String, dynamic>) ? data['unit'] : null;
    return {
      'slope': slope,
      'unit': unit,
      'data': data,
      'metadata': json['metadata'],
      'period': json['period'],
      'location': json['location'],
      'identifier': json['identifier'],
    };
  }

  Future<Map<String, dynamic>> fetchSummaryData(String city, String date) async {
    final json = await _fetchV1Subresource('daily', city, date, 'summary');
    return {
      'summary': json['data'],
      'metadata': json['metadata'],
      'period': json['period'],
      'location': json['location'],
      'identifier': json['identifier'],
    };
  }

  // ---------------------------------------------------------------------------
  // v1 Records API — used for period views (daily, weekly, monthly, yearly)
  // ---------------------------------------------------------------------------

  /// Maps internal period keys to API path segments.
  static String _apiPeriodPath(String period) {
    switch (period) {
      case 'week':
        return 'weekly';
      case 'month':
        return 'monthly';
      case 'year':
        return 'yearly';
      case 'daily':
      default:
        return 'daily';
    }
  }

  /// Fetch period temperature data using the async job endpoint with a
  /// synchronous fallback, mirroring the web app's approach.
  ///
  /// [period] is one of 'daily', 'week', 'month', 'year'.
  /// [location] is the city/location string (e.g. "London, UK").
  /// [identifier] is the MM-DD date string (e.g. "02-06").
  /// [onProgress] optional callback invoked while the job is processing.
  Future<PeriodTemperatureData> fetchPeriodData(
    String period,
    String location,
    String identifier, {
    void Function(AsyncJobStatus)? onProgress,
  }) async {
    final cacheKey = '${_apiPeriodPath(period)}|$location|$identifier';
    final cached = _periodCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    try {
      DebugUtils.logLazy(() => 'Attempting async fetch for $period data...');
      final jobId = await _createAsyncJob(period, location, identifier);
      final result = await _pollJobStatus(jobId, onProgress: onProgress);
      DebugUtils.logLazy(() => 'Async fetch successful for $period data');
      _periodCache[cacheKey] = result.data;
      return result.data;
    } catch (e) {
      final msg = e.toString();
      // Fall back to synchronous endpoint on timeout or job failure
      if (msg.contains('timed out') ||
          msg.contains('polling failed') ||
          msg.contains('Job failed')) {
        DebugUtils.logLazy(() => 'Async job failed ($msg), falling back to sync API...');
        try {
          final fallback =
              await _fetchPeriodDataSync(period, location, identifier);
          DebugUtils.logLazy(() => 'Synchronous fallback successful for $period data');
          _periodCache[cacheKey] = fallback;
          return fallback;
        } catch (fallbackError) {
          throw Exception(
            'Period data fetch failed: $msg. '
            'Sync fallback also failed: $fallbackError',
          );
        }
      }
      rethrow;
    }
  }

  /// POST to create an async job, returns the job ID.
  Future<String> _createAsyncJob(
    String period,
    String location,
    String identifier,
  ) async {
    final token = await getAuthToken();
    final apiPeriod = _apiPeriodPath(period);
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse(
      '$apiBaseUrl/v1/records/$apiPeriod/$encodedLocation/$identifier/async',
    );

    DebugUtils.logLazy(() => 'Creating async job: $url');

    final response = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: kApiTimeoutSeconds));

    if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded creating async job');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to create async job: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    final jobId = json['job_id'];
    if (jobId == null || (jobId as String).isEmpty) {
      throw Exception('Invalid job response: missing job_id');
    }
    return jobId;
  }

  /// Poll the job status endpoint until the job completes or fails.
  Future<JobResult> _pollJobStatus(
    String jobId, {
    void Function(AsyncJobStatus)? onProgress,
    int maxPolls = 100,
    Duration pollInterval = const Duration(seconds: 3),
  }) async {
    int pollCount = 0;

    while (pollCount < maxPolls) {
      try {
        final token = await getAuthToken();
        final url = Uri.parse('$apiBaseUrl/v1/jobs/$jobId');
        final response = await http.get(
          url,
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: kFirebaseAuthTimeoutSeconds));

        if (response.statusCode == 429) {
          throw RateLimitException('Rate limit exceeded polling job');
        }

        if (response.statusCode != 200) {
          throw Exception('Job status check failed: ${response.statusCode}');
        }

        final status = AsyncJobStatus.fromJson(jsonDecode(response.body));

        if (status.isReady) {
          return status.result!;
        } else if (status.isError) {
          throw Exception('Job failed: ${status.error ?? "Unknown error"}');
        }

        // Still processing — notify caller and wait
        if (onProgress != null) {
          onProgress(status);
        }
        await Future.delayed(pollInterval);
        pollCount++;
      } catch (e) {
        if (e is RateLimitException) rethrow;
        if (pollCount > 10) {
          throw Exception(
            'Job polling failed after $pollCount attempts: $e',
          );
        }
        await Future.delayed(pollInterval);
        pollCount++;
      }
    }

    throw Exception(
      'Job polling timed out after $maxPolls attempts',
    );
  }

  /// Synchronous fallback: GET the period data directly.
  Future<PeriodTemperatureData> _fetchPeriodDataSync(
    String period,
    String location,
    String identifier,
  ) async {
    final token = await getAuthToken();
    final apiPeriod = _apiPeriodPath(period);
    final encodedLocation = Uri.encodeComponent(location);
    final url = Uri.parse(
      '$apiBaseUrl/v1/records/$apiPeriod/$encodedLocation/$identifier',
    );

    DebugUtils.logLazy(() => 'Sync fallback: $url');

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 60));

    if (response.statusCode == 429) {
      throw RateLimitException('Rate limit exceeded on sync fallback');
    }

    if (response.statusCode != 200) {
      throw Exception('Sync API failed: ${response.statusCode}');
    }

    final json = jsonDecode(response.body);
    return PeriodTemperatureData.fromJson(json);
  }
}
