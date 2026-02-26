# TempHist Mobile Refactoring Guide

## Overview

This guide outlines the refactoring plan for the TempHist Flutter mobile app to improve maintainability, testability, and code organization.

---

## ✅ Phase 1: Extract Constants and Utilities (COMPLETED)

### Created Files:
1. **`lib/constants/app_constants.dart`** - All color, layout, font, and time constants
2. **`lib/utils/date_utils.dart`** - Date formatting and manipulation helpers
3. **`lib/utils/location_utils.dart`** - Location string cleanup and validation
4. **`lib/widgets/splash_screen.dart`** - Splash screen extracted to separate widget

### Impact:
- Eliminates duplication of constants across files
- Makes utilities reusable across the codebase
- Reduces main.dart from 4,421 lines

---

## 📋 Phase 2: State Management (RECOMMENDED)

### Current State: Plain `setState()` with 50+ state variables

The app currently uses Flutter's built-in `setState()` with a massive state class containing 50+ variables:
- Location state (3 variables)
- Loading state (10+ variables)
- Data state (5+ variables)
- Error state (10+ variables)
- Network state (3 variables)
- Cache state (multiple variables)
- Timer state (5+ variables)

### Problems:
1. **Hard to test** - State logic mixed with UI code
2. **Hard to debug** - No clear data flow
3. **Rebuild inefficiency** - setState rebuilds entire widget tree
4. **No state history** - Can't track state changes
5. **Tight coupling** - Business logic tied to UI

### **RECOMMENDED SOLUTION: Riverpod**

#### Why Riverpod?
- ✅ **Compile-time safe** - Catches errors at compile time
- ✅ **Easy to test** - Providers are independent of widgets
- ✅ **No context needed** - Can read state anywhere
- ✅ **Built-in caching** - Reduces redundant rebuilds
- ✅ **Dev tools** - Excellent debugging support
- ✅ **Modern** - Actively maintained, best practices

#### Implementation Plan:

**Step 1: Add Riverpod dependency**
```yaml
# pubspec.yaml
dependencies:
  flutter_riverpod: ^2.5.1

dev_dependencies:
  riverpod_generator: ^2.4.0
  build_runner: ^2.4.8
```

**Step 2: Create state models**
```dart
// lib/state/temperature_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';

@freezed
class TemperatureState with _$TemperatureState {
  const factory TemperatureState({
    @Default('') String determinedLocation,
    @Default('') String displayLocation,
    @Default(false) bool isLocationDetermined,
    @Default(false) bool isDataLoading,
    @Default(false) bool isOnline,
    Map<String, dynamic>? currentData,
    @Default([]) List<int> failedYears,
    // ... other state
  }) = _TemperatureState;
}
```

**Step 3: Create providers**
```dart
// lib/providers/temperature_provider.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'temperature_provider.g.dart';

@riverpod
class TemperatureNotifier extends _$TemperatureNotifier {
  @override
  TemperatureState build() {
    return const TemperatureState();
  }

  Future<void> loadData(String location, String date) async {
    state = state.copyWith(isDataLoading: true);

    try {
      final service = ref.read(temperatureServiceProvider);
      final data = await service.fetchPeriodData('daily', location, date);

      state = state.copyWith(
        currentData: data,
        isDataLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isDataLoading: false,
        error: e.toString(),
      );
    }
  }
}

@riverpod
TemperatureService temperatureService(TemperatureServiceRef ref) {
  return TemperatureService();
}
```

**Step 4: Use in widgets**
```dart
// lib/screens/temperature_screen.dart
class TemperatureScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(temperatureNotifierProvider);

    return Scaffold(
      body: state.isDataLoading
          ? const CircularProgressIndicator()
          : TemperatureChart(data: state.currentData),
    );
  }
}
```

#### Migration Strategy:
1. **Week 1**: Set up Riverpod, create basic providers for read-only state
2. **Week 2**: Migrate location and loading state
3. **Week 3**: Migrate data fetching and caching
4. **Week 4**: Migrate error handling and network state
5. **Week 5**: Remove old setState code, clean up

#### Alternative: Provider (Simpler, but older)
```dart
// lib/providers/temperature_provider.dart
class TemperatureProvider extends ChangeNotifier {
  String _location = '';
  bool _isLoading = false;

  String get location => _location;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    // ... load data

    _isLoading = false;
    notifyListeners();
  }
}
```

---

## 📦 Phase 3: Cache Simplification

### Current State: 7 different caching methods

The app currently implements custom caching with SharedPreferences:
1. `_cacheTemperatureData()` - Cache individual year data (24h expiry)
2. `_loadCachedTemperatureData()` - Load cached year data
3. `_cacheApiResponse()` - Cache API responses (varying expiry)
4. `_loadCachedApiResponse()` - Load cached API responses
5. `_cacheLoc ation()` - Cache location (30min expiry)
6. `_cleanupExpiredCache()` - Manual cache cleanup
7. Emergency cache cleanup when storage full

### Problems:
1. **Complex expiration logic** - Different expiry times (30min, 1h, 6h, 24h)
2. **Manual JSON encoding** - Error-prone serialization
3. **No size limits** - Can fill device storage
4. **Emergency cleanup** - Deletes 50% of cache when full
5. **SharedPreferences limitations** - Not designed for large data
6. **No LRU eviction** - Keeps all data until expiry

### **RECOMMENDED SOLUTION: Hive**

#### Why Hive?
- ✅ **Fast** - 10x faster than SharedPreferences
- ✅ **Type-safe** - Automatic serialization with adapters
- ✅ **Size limits** - Built-in size management
- ✅ **Lazy loading** - Only loads what you need
- ✅ **No native dependencies** - Pure Dart
- ✅ **Encrypted boxes** - Security built-in

#### Implementation Plan:

**Step 1: Add Hive dependency**
```yaml
# pubspec.yaml
dependencies:
  hive: ^2.2.3
  hive_flutter: ^1.1.0

dev_dependencies:
  hive_generator: ^2.0.1
  build_runner: ^2.4.8
```

**Step 2: Define cache models**
```dart
// lib/models/cache/temperature_cache_entry.dart
import 'package:hive/hive.dart';

part 'temperature_cache_entry.g.dart';

@HiveType(typeId: 0)
class TemperatureCacheEntry {
  @HiveField(0)
  final double temperature;

  @HiveField(1)
  final int year;

  @HiveField(2)
  final DateTime cachedAt;

  @HiveField(3)
  final String city;

  TemperatureCacheEntry({
    required this.temperature,
    required this.year,
    required this.cachedAt,
    required this.city,
  });

  bool get isExpired => DateTime.now().difference(cachedAt).inHours > 24;
}
```

**Step 3: Create cache service**
```dart
// lib/services/cache_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class CacheService {
  static const String temperatureBoxName = 'temperature_cache';
  static const String locationBoxName = 'location_cache';

  late Box<TemperatureCacheEntry> _temperatureBox;
  late Box<String> _locationBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TemperatureCacheEntryAdapter());

    _temperatureBox = await Hive.openBox<TemperatureCacheEntry>(
      temperatureBoxName,
      compactionStrategy: (entries, deletedEntries) {
        return deletedEntries > 50; // Auto-compact when 50 deleted
      },
    );

    _locationBox = await Hive.openBox<String>(locationBoxName);

    // Clean expired entries on init
    await cleanExpired();
  }

  Future<void> cacheTemperature(int year, String city, double temp) async {
    final key = '${city}_$year';
    final entry = TemperatureCacheEntry(
      temperature: temp,
      year: year,
      cachedAt: DateTime.now(),
      city: city,
    );

    await _temperatureBox.put(key, entry);
  }

  TemperatureCacheEntry? getCachedTemperature(int year, String city) {
    final key = '${city}_$year';
    final entry = _temperatureBox.get(key);

    if (entry != null && !entry.isExpired) {
      return entry;
    }

    return null;
  }

  Future<void> cleanExpired() async {
    final keysToDelete = <String>[];

    for (var key in _temperatureBox.keys) {
      final entry = _temperatureBox.get(key);
      if (entry?.isExpired ?? true) {
        keysToDelete.add(key as String);
      }
    }

    await _temperatureBox.deleteAll(keysToDelete);
  }

  Future<void> clearAll() async {
    await _temperatureBox.clear();
    await _locationBox.clear();
  }
}
```

**Step 4: Use in app**
```dart
// lib/main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize cache
  final cacheService = CacheService();
  await cacheService.init();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(TempHist());
}
```

#### Migration Strategy:
1. **Day 1**: Add Hive, create cache models
2. **Day 2**: Implement CacheService, test in isolation
3. **Day 3**: Migrate temperature data caching
4. **Day 4**: Migrate location caching
5. **Day 5**: Remove old SharedPreferences caching, test thoroughly

#### Alternative: Simple In-Memory Cache with LRU
```dart
// lib/services/simple_cache_service.dart
class SimpleCacheService {
  final Map<String, CacheEntry> _cache = {};
  final int maxEntries = 1000;
  final List<String> _accessOrder = [];

  void put(String key, dynamic value, Duration ttl) {
    if (_cache.length >= maxEntries) {
      _evictLRU();
    }

    _cache[key] = CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    _updateAccessOrder(key);
  }

  dynamic get(String key) {
    final entry = _cache[key];
    if (entry != null && !entry.isExpired) {
      _updateAccessOrder(key);
      return entry.value;
    }
    _cache.remove(key);
    return null;
  }

  void _evictLRU() {
    if (_accessOrder.isNotEmpty) {
      final oldest = _accessOrder.removeAt(0);
      _cache.remove(oldest);
    }
  }

  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
  }
}
```

---

## 🧹 Phase 4: Remove Unused Code

### Identified Unused Methods (from `flutter analyze`):

1. **`_cacheTemperatureData`** (line 907) - Replaced by v1 API
2. **`_loadCachedTemperatureData`** (line 924) - Replaced by v1 API
3. **`_loadAverageAndTrendData`** (line 1987) - Not called anymore
4. **`_buildLoadingDateSection`** (line 2533) - Old UI component
5. **`_buildDeterminedLocationSection`** (line 2549) - Old UI component
6. **`_buildDateSection`** (line 3393) - Old UI component
7. **Unused import**: `models/period_temperature_data.dart` in main.dart

### Removal Plan:

**Step 1: Remove unused cache methods**
```bash
# These methods are from the old progressive loading system
# Safe to remove as they're replaced by v1 API + PeriodPage

# Remove lines 907-922 (_cacheTemperatureData)
# Remove lines 924-958 (_loadCachedTemperatureData)
```

**Step 2: Remove unused data loading methods**
```bash
# Remove lines 1987-2100 (_loadAverageAndTrendData)
# This was for the old progressive loading approach
```

**Step 3: Remove unused UI builder methods**
```bash
# Remove lines 2533-2548 (_buildLoadingDateSection)
# Remove lines 2549-2592 (_buildDeterminedLocationSection)
# Remove lines 3393-3418 (_buildDateSection)
```

**Step 4: Remove unused imports**
```dart
// main.dart - remove if not used after refactor:
// import 'models/period_temperature_data.dart'; // Check usage first
```

**Step 5: Run analyzer and tests**
```bash
flutter analyze
flutter test
```

### Expected Impact:
- **~500 lines removed** from main.dart
- **Reduced confusion** - No dead code to navigate
- **Faster builds** - Less code to compile
- **Better maintainability** - Only active code remains

---

## 📊 Complete Refactoring Plan

### Recommended Order:
1. **Phase 4** (Remove Unused Code) - 1 day - Low risk
2. **Phase 3** (Cache Simplification) - 1 week - Medium risk
3. **Phase 2** (State Management) - 3-4 weeks - High risk, high reward

### File Structure After Full Refactor:

```
lib/
├── constants/
│   └── app_constants.dart ✅
├── models/
│   ├── temperature_data.dart
│   ├── period_temperature_data.dart
│   └── cache/
│       └── temperature_cache_entry.dart
├── providers/
│   ├── temperature_provider.dart
│   ├── location_provider.dart
│   └── network_provider.dart
├── screens/
│   └── temperature_screen.dart
├── services/
│   ├── cache_service.dart
│   ├── location_service.dart
│   ├── network_service.dart
│   └── temperature_service.dart
├── utils/
│   ├── date_utils.dart ✅
│   ├── location_utils.dart ✅
│   └── debug_utils.dart
├── widgets/
│   ├── splash_screen.dart ✅
│   ├── temperature_bar_chart.dart
│   └── period_page.dart
├── config/
│   ├── app_config.dart
│   └── build_config.dart
└── main.dart (< 100 lines)
```

### Success Metrics:
- ✅ main.dart reduced from 4,421 to < 500 lines
- ✅ All tests passing
- ✅ No unused code warnings
- ✅ State management with clear data flow
- ✅ Cache with automatic expiration and size limits
- ✅ Easy to add new features
- ✅ Easy to test in isolation

---

## 🎯 Quick Wins (Do These First)

1. **Use the new utility files** - Update imports in main.dart
2. **Remove 7 unused methods** - Safe, immediate impact
3. **Replace SharedPreferences with Hive** - Biggest performance win
4. **Extract TemperatureScreen** - Makes main.dart manageable

---

## 📚 Resources

- [Riverpod Documentation](https://riverpod.dev/)
- [Hive Documentation](https://docs.hivedb.dev/)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [Effective Dart](https://dart.dev/guides/language/effective-dart)

---

**Generated**: 2026-02-26
**Status**: Phase 1 Complete, Phases 2-4 Planned
