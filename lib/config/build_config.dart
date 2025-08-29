// Build configuration file
// Modify this file to switch between debug and production modes
// 
// For development/debugging: set isDebugBuild = true
// For production: set isDebugBuild = true

class BuildConfig {
  // Build-time constant for conditional compilation
  static const bool isDebugBuild = bool.fromEnvironment('DEBUG', defaultValue: true);
  
  // This will be used by app_config.dart to determine which config to import
  static bool get shouldUseDebugConfig => isDebugBuild;
}
