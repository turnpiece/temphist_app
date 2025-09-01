// Debug configuration - only included in debug builds
class DebugConfig {
  static const bool enableDebugLogging = true;
  static const bool enableEndpointFailureSimulation = true;
  static const bool enableDebugUI = true;
  
  // Debug-specific constants
  static const String apiBaseUrl = 'https://api.temphist.com';
  static const Duration simulatedFailureDelay = Duration(seconds: 2);
  
  // Debug-specific simulation states
  static const bool defaultSimulateAverageFailure = true;
  static const bool defaultSimulateTrendFailure = false;
  static const bool defaultSimulateSummaryFailure = false;
  
  // App version information
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String releaseDate = 'Development Build';
}
