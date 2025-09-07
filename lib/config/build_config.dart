// Build configuration file
// This file uses Flutter's built-in debug mode detection
// 
// For development/debugging: flutter run --debug (kDebugMode=true)
// For production: flutter build --release (kDebugMode=false)

import 'package:flutter/foundation.dart';

class BuildConfig {
  // Use Flutter's built-in debug mode detection
  // This is more reliable than environment variables
  static bool get isDebugBuild => kDebugMode;
  
  // This will be used by app_config.dart to determine which config to import
  static bool get shouldUseDebugConfig => isDebugBuild;
  
  // Additional build information
  static bool get isReleaseBuild => !isDebugBuild;
  static bool get isDebugMode => isDebugBuild;
}
