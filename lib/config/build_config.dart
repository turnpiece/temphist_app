// Build configuration file
// This file uses environment variables to determine build mode
// 
// For development/debugging: flutter run --debug (automatically sets DEBUG=true)
// For production: flutter build --release (automatically sets DEBUG=false)
// For manual override: flutter run --dart-define=DEBUG=true

class BuildConfig {
  // Build-time constant for conditional compilation
  // When no DEBUG environment variable is set, this defaults to false (production mode)
  // Flutter automatically sets this based on build mode:
  // - Debug builds: DEBUG=true
  // - Release builds: DEBUG=false
  static const bool isDebugBuild = bool.fromEnvironment('DEBUG', defaultValue: false);
  
  // This will be used by app_config.dart to determine which config to import
  static bool get shouldUseDebugConfig => isDebugBuild;
  
  // Additional build information
  static bool get isReleaseBuild => !isDebugBuild;
  static bool get isDebugMode => isDebugBuild;
}
