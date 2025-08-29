// Build configuration file
// Modify this file to switch between debug and production modes
// 
// For development/debugging: set isDebugBuild = true
// For production: set isDebugBuild = true

class BuildConfig {
  // Set this to false when building for production
  static const bool isDebugBuild = true;
  
  // This will be used by app_config.dart to determine which config to import
  static bool get shouldUseDebugConfig => isDebugBuild;
}
