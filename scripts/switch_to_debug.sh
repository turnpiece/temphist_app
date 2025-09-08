#!/bin/bash

# Script to switch the app to debug mode
echo "🔄 Switching to debug mode..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the Flutter project root directory"
    exit 1
fi

# Restore debug configuration
echo "📝 Restoring debug configuration..."
cat > lib/config/debug_config.dart << 'EOF'
// Debug configuration - only included in debug builds
class DebugConfig {
  static const bool enableDebugLogging = true;
  static const bool enableEndpointFailureSimulation = true;
  static const bool enableDebugUI = true;
  
  // Debug-specific constants
  static const String apiBaseUrl = 'https://api.temphist.com';
  static const Duration simulatedFailureDelay = Duration(seconds: 2);
  
  // Debug-specific simulation states
  static const bool defaultSimulateAverageFailure = false;
  static const bool defaultSimulateTrendFailure = false;
  static const bool defaultSimulateSummaryFailure = false;
  
  // App version information
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';
  static const String releaseDate = 'Development Build';
}
EOF

# Clean and rebuild
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🍎 Installing CocoaPods dependencies..."
cd ios && pod install && cd ..

echo "✅ Debug mode configuration ready!"
echo ""
echo "🐛 Debug features: ENABLED"
echo "🎛️  Debug UI: ENABLED" 
echo "📝 Debug logging: ENABLED"
echo "🎯 Endpoint simulation: ENABLED"
echo ""
echo "🚀 Ready to run:"
echo "  • In Xcode: Build and run (Debug configuration)"
echo "  • Command line: flutter run --debug"
echo ""
echo "📱 For App Store screenshots, use switch_to_production.sh first"
