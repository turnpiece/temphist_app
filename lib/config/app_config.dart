import 'build_config.dart';
import 'debug_config.dart' as debug_config;
import 'production_config.dart' as production_config;

class AppConfig {
  static bool get _isDebugBuild => BuildConfig.isDebugBuild;

  static T _pick<T>(T debugValue, T productionValue) =>
      _isDebugBuild ? debugValue : productionValue;

  static bool get isDebugMode =>
      _pick(debug_config.DebugConfig.enableDebugLogging,
            production_config.ProductionConfig.enableDebugLogging);
  static bool get enableEndpointFailureSimulation =>
      _pick(debug_config.DebugConfig.enableEndpointFailureSimulation,
            production_config.ProductionConfig.enableEndpointFailureSimulation);
  static bool get enableDebugUI =>
      _pick(debug_config.DebugConfig.enableDebugUI,
            production_config.ProductionConfig.enableDebugUI);
  static String get apiBaseUrl =>
      _pick(debug_config.DebugConfig.apiBaseUrl,
            production_config.ProductionConfig.apiBaseUrl);
  static bool get defaultSimulateAverageFailure =>
      _pick(debug_config.DebugConfig.defaultSimulateAverageFailure,
            production_config.ProductionConfig.defaultSimulateAverageFailure);
  static bool get defaultSimulateTrendFailure =>
      _pick(debug_config.DebugConfig.defaultSimulateTrendFailure,
            production_config.ProductionConfig.defaultSimulateTrendFailure);
  static bool get defaultSimulateSummaryFailure =>
      _pick(debug_config.DebugConfig.defaultSimulateSummaryFailure,
            production_config.ProductionConfig.defaultSimulateSummaryFailure);
  static bool get shouldShowDebugFeatures => isDebugMode && enableDebugUI;
  static String get appVersion =>
      _pick(debug_config.DebugConfig.appVersion,
            production_config.ProductionConfig.appVersion);
  static String get buildNumber =>
      _pick(debug_config.DebugConfig.buildNumber,
            production_config.ProductionConfig.buildNumber);
  static String get releaseDate =>
      _pick(debug_config.DebugConfig.releaseDate,
            production_config.ProductionConfig.releaseDate);
  static String get fullVersion => 'v$appVersion+$buildNumber';
}
