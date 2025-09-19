import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/explore_state.dart';

/// Service for caching explore screen data with TTL support
class ExploreCacheService {
  static const Duration _dailyCacheExpiration = Duration(days: 7);
  static const Duration _weeklyCacheExpiration = Duration(days: 3);
  static const Duration _monthlyCacheExpiration = Duration(days: 1);

  /// Generate cache key for daily data
  String _getDailyCacheKey(LocationInfo location, DateTime date) {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return 'daily:${location.cacheKey}:$dateStr';
  }

  /// Generate cache key for weekly data
  String _getWeeklyCacheKey(LocationInfo location, DateTime anchorDate) {
    final dateStr = '${anchorDate.year}-${anchorDate.month.toString().padLeft(2, '0')}-${anchorDate.day.toString().padLeft(2, '0')}';
    return 'weekly:${location.cacheKey}:$dateStr';
  }

  /// Generate cache key for monthly data
  String _getMonthlyCacheKey(LocationInfo location, DateTime anchorDate) {
    final dateStr = '${anchorDate.year}-${anchorDate.month.toString().padLeft(2, '0')}-${anchorDate.day.toString().padLeft(2, '0')}';
    return 'monthly:${location.cacheKey}:$dateStr';
  }

  /// Get cache key based on period
  String _getCacheKey(LocationInfo location, DateTime date, ExplorePeriod period) {
    switch (period) {
      case ExplorePeriod.day:
        return _getDailyCacheKey(location, date);
      case ExplorePeriod.week:
        return _getWeeklyCacheKey(location, date);
      case ExplorePeriod.month:
        return _getMonthlyCacheKey(location, date);
    }
  }

  /// Get cache expiration based on period
  Duration _getCacheExpiration(ExplorePeriod period) {
    switch (period) {
      case ExplorePeriod.day:
        return _dailyCacheExpiration;
      case ExplorePeriod.week:
        return _weeklyCacheExpiration;
      case ExplorePeriod.month:
        return _monthlyCacheExpiration;
    }
  }

  /// Cache explore data
  Future<void> cacheExploreData(
    LocationInfo location,
    DateTime date,
    ExplorePeriod period,
    Map<String, dynamic> data,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(location, date, period);
      
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'location': {
          'displayName': location.displayName,
          'latitude': location.latitude,
          'longitude': location.longitude,
          'countryCode': location.countryCode,
        },
        'date': date.toIso8601String(),
        'period': period.name,
      };

      await prefs.setString(cacheKey, jsonEncode(cacheData));
    } catch (e) {
      // Error caching explore data
    }
  }

  /// Load cached explore data
  Future<Map<String, dynamic>?> loadCachedExploreData(
    LocationInfo location,
    DateTime date,
    ExplorePeriod period,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cacheKey = _getCacheKey(location, date, period);
      final cachedData = prefs.getString(cacheKey);
      
      if (cachedData == null) {
        return null;
      }

      final data = jsonDecode(cachedData) as Map<String, dynamic>;
      final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
      final age = DateTime.now().difference(timestamp);
      final expiration = _getCacheExpiration(period);

      if (age > expiration) {
        await prefs.remove(cacheKey);
        return null;
      }

      return data['data'] as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Clear expired cache entries
  Future<void> clearExpiredCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final now = DateTime.now();

      for (final key in keys) {
        if (key.startsWith('daily:') || key.startsWith('weekly:') || key.startsWith('monthly:')) {
          try {
            final cachedData = prefs.getString(key);
            if (cachedData != null) {
              final data = jsonDecode(cachedData) as Map<String, dynamic>;
              final timestamp = DateTime.fromMillisecondsSinceEpoch(data['timestamp'] as int);
              final age = now.difference(timestamp);
              
              Duration expiration;
              if (key.startsWith('daily:')) {
                expiration = _dailyCacheExpiration;
              } else if (key.startsWith('weekly:')) {
                expiration = _weeklyCacheExpiration;
              } else if (key.startsWith('monthly:')) {
                expiration = _monthlyCacheExpiration;
              } else {
                continue;
              }

              if (age > expiration) {
                await prefs.remove(key);
              }
            }
          } catch (e) {
            // If we can't parse the data, remove it
            await prefs.remove(key);
          }
        }
      }

      // Cleaned expired cache entries
    } catch (e) {
      // Error clearing expired explore cache
    }
  }

  /// Clear all explore cache
  Future<void> clearAllCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith('daily:') || key.startsWith('weekly:') || key.startsWith('monthly:')) {
          await prefs.remove(key);
        }
      }

      // Cleared explore cache entries
    } catch (e) {
      // Error clearing explore cache
    }
  }

  /// Get cache statistics
  Future<Map<String, int>> getCacheStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      
      int dailyCount = 0;
      int weeklyCount = 0;
      int monthlyCount = 0;

      for (final key in keys) {
        if (key.startsWith('daily:')) {
          dailyCount++;
        } else if (key.startsWith('weekly:')) {
          weeklyCount++;
        } else if (key.startsWith('monthly:')) {
          monthlyCount++;
        }
      }

      return {
        'daily': dailyCount,
        'weekly': weeklyCount,
        'monthly': monthlyCount,
      };
    } catch (e) {
      return {'daily': 0, 'weekly': 0, 'monthly': 0};
    }
  }
}
