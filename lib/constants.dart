/// Build-time constants for the application
/// These can be controlled via --dart-define flags or environment variables

/// Enable verbose logging in production builds
/// Usage: flutter build ios --dart-define=VERBOSE_LOGS=true
/// Or set environment variable: VERBOSE_LOGS=true
const bool verboseLogs = bool.fromEnvironment('VERBOSE_LOGS', defaultValue: false);

/// Additional build-time constants can be added here as needed
/// Examples:
/// const bool enableAnalytics = bool.fromEnvironment('ENABLE_ANALYTICS', defaultValue: true);
/// const String apiEndpoint = String.fromEnvironment('API_ENDPOINT', defaultValue: 'https://api.example.com');
