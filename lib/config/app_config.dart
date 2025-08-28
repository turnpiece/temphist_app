// Conditional import file that selects the appropriate configuration
// This uses conditional compilation to include debug or production config

// Use conditional compilation to import the appropriate config
// In debug mode, import debug config; in production, import production config
import 'debug_config.dart' if (dart.library.io) 'production_config.dart' as config;

// Create a unified interface that can be used throughout the app
class AppConfig {
  // Debug logging
  static bool get isDebugMode => config.DebugConfig.enableDebugLogging;
  static bool get enableEndpointFailureSimulation => config.DebugConfig.enableEndpointFailureSimulation;
  static bool get enableDebugUI => config.DebugConfig.enableDebugUI;
  
  // API configuration
  static String get apiBaseUrl => config.DebugConfig.apiBaseUrl;
  
  // Simulation defaults
  static bool get defaultSimulateAverageFailure => config.DebugConfig.defaultSimulateAverageFailure;
  static bool get defaultSimulateTrendFailure => config.DebugConfig.defaultSimulateTrendFailure;
  static bool get defaultSimulateSummaryFailure => config.DebugConfig.defaultSimulateSummaryFailure;
  
  // Utility methods
  static bool get isProductionMode => !isDebugMode;
  static bool get shouldShowDebugFeatures => isDebugMode && enableDebugUI;
}
