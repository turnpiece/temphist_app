// Production configuration - only included in production builds
class ProductionConfig {
  static const bool enableDebugLogging = false;
  static const bool enableEndpointFailureSimulation = false;
  static const bool enableDebugUI = false;
  
  // Production-specific constants
  static const String apiBaseUrl = 'https://api.temphist.com';
  
  // Production simulation states (all false)
  static const bool defaultSimulateAverageFailure = false;
  static const bool defaultSimulateTrendFailure = false;
  static const bool defaultSimulateSummaryFailure = false;
}
