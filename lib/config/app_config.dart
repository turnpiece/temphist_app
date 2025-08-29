// Conditional import file that selects the appropriate configuration
// This uses conditional compilation to include debug or production config

// Use conditional compilation to import the appropriate config
// This approach uses build-time constants for better control
import 'debug_config.dart' as debug_config;
import 'production_config.dart' as production_config;

// Create a unified interface that can be used throughout the app
class AppConfig {
  // Build-time constants for conditional compilation
  static const bool _isDebugBuild = bool.fromEnvironment('DEBUG', defaultValue: true);
  
  // Debug logging
  static bool get isDebugMode => _isDebugBuild ? debug_config.DebugConfig.enableDebugLogging : production_config.ProductionConfig.enableDebugLogging;
  static bool get enableEndpointFailureSimulation => _isDebugBuild ? debug_config.DebugConfig.enableEndpointFailureSimulation : production_config.ProductionConfig.enableEndpointFailureSimulation;
  static bool get enableDebugUI => _isDebugBuild ? debug_config.DebugConfig.enableDebugUI : production_config.ProductionConfig.enableDebugUI;
  
  // API configuration
  static String get apiBaseUrl => _isDebugBuild ? debug_config.DebugConfig.apiBaseUrl : production_config.ProductionConfig.apiBaseUrl;
  
  // Simulation defaults
  static bool get defaultSimulateAverageFailure => _isDebugBuild ? debug_config.DebugConfig.defaultSimulateAverageFailure : production_config.ProductionConfig.defaultSimulateAverageFailure;
  static bool get defaultSimulateTrendFailure => _isDebugBuild ? debug_config.DebugConfig.defaultSimulateTrendFailure : production_config.ProductionConfig.defaultSimulateTrendFailure;
  static bool get defaultSimulateSummaryFailure => _isDebugBuild ? debug_config.DebugConfig.defaultSimulateSummaryFailure : production_config.ProductionConfig.defaultSimulateSummaryFailure;
  
  // Utility methods
  static bool get isProductionMode => !isDebugMode;
  static bool get shouldShowDebugFeatures => isDebugMode && enableDebugUI;
  
  // Version information
  static String get appVersion => _isDebugBuild ? debug_config.DebugConfig.appVersion : production_config.ProductionConfig.appVersion;
  static String get buildNumber => _isDebugBuild ? debug_config.DebugConfig.buildNumber : production_config.ProductionConfig.buildNumber;
  static String get releaseDate => _isDebugBuild ? debug_config.DebugConfig.releaseDate : production_config.ProductionConfig.releaseDate;
  static String get fullVersion => 'v${appVersion}+${buildNumber}';
}
