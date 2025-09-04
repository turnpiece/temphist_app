# Debug Configuration System

This directory contains the configuration system for managing debug vs production code in your Flutter app.

## Files

### `build_config.dart`

- **Purpose**: Main switch to control debug vs production mode
- **Usage**: Set `isDebugBuild = false` when building for production
- **Location**: `lib/config/build_config.dart`

### `debug_config.dart`

- **Purpose**: Contains all debug-specific settings and constants
- **Usage**: Only included when `isDebugBuild = true`
- **Location**: `lib/config/debug_config.dart`

### `production_config.dart`

- **Purpose**: Contains all production-specific settings and constants
- **Usage**: Only included when `isDebugBuild = false`
- **Location**: `lib/config/production_config.dart`

### `app_config.dart`

- **Purpose**: Unified interface that provides access to the appropriate config
- **Usage**: Import this file throughout your app to access configuration
- **Location**: `lib/config/app_config.dart`

## How to Use

### 1. Access Configuration in Your Code

```dart
import 'package:your_app/config/app_config.dart';

// Check if debug mode is enabled
if (AppConfig.isDebugMode) {
  // Debug-only code here
}

// Check if debug UI should be shown
if (AppConfig.shouldShowDebugFeatures) {
  // Show debug UI elements
}

// Access API configuration
final apiUrl = AppConfig.apiBaseUrl;
```

### 2. Switch Between Debug and Production

**For Development/Debugging:**

```dart
// In lib/config/build_config.dart
static const bool isDebugBuild = true;
```

**For Production:**

```dart
// In lib/config/build_config.dart
static const bool isDebugBuild = false;
```

### 3. Add New Configuration Options

1. Add the option to both `debug_config.dart` and `production_config.dart`
2. Add a getter to `app_config.dart`
3. Use the getter in your code

### 4. Debug Utilities

Use the `DebugUtils` class for consistent debug logging:

```dart
import 'package:your_app/utils/debug_utils.dart';

DebugUtils.log('This is a debug message');
DebugUtils.logWithContext('API', 'Making request to endpoint');
DebugUtils.logWithTimestamp('User action performed');
```

## Benefits

1. **Zero Production Overhead**: Debug code is completely removed in production builds
2. **Clean Separation**: Debug and production code are clearly separated
3. **Easy Switching**: Single file to change between modes
4. **Consistent Interface**: Same API regardless of build mode
5. **Better Security**: Debug features can't be accidentally enabled in production

## Migration from Old System

The old constants `DEBUGGING` and `SIMULATE_ENDPOINT_FAILURES` have been removed. Use `AppConfig` methods directly instead.

## Best Practices

1. Always use `AppConfig` methods instead of hardcoded constants
2. Use `DebugUtils` for all debug logging
3. Keep debug-specific code in conditional blocks
4. Test both debug and production configurations
5. Document any new configuration options
