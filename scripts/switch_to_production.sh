#!/bin/bash

# Script to switch the app to production mode
echo "🔄 Switching to production mode..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the Flutter project root directory"
    exit 1
fi

# Configure debug config for production-like behavior in simulator
echo "📝 Configuring debug config for production-like behavior..."
cat > lib/config/debug_config.dart << 'EOF'
// Debug configuration - only included in debug builds
class DebugConfig {
  static const bool enableDebugLogging = false;
  static const bool enableEndpointFailureSimulation = false;
  static const bool enableDebugUI = false;
  
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
  static const String releaseDate = 'Production Build';
}
EOF

# Clean and rebuild
echo "🧹 Cleaning project..."
flutter clean

echo "📦 Getting dependencies..."
flutter pub get

echo "🍎 Installing CocoaPods dependencies..."
cd ios && pod install && cd ..

echo "✅ Production mode configuration ready!"
echo ""
echo "🐛 Debug features: DISABLED"
echo "🎛️  Debug UI: DISABLED"
echo "📝 Debug logging: DISABLED"
echo "🎯 Endpoint simulation: DISABLED"
echo ""
echo "🚀 Ready to run:"
echo "  • In Xcode: Build and run (Debug configuration with production behavior)"
echo "  • Command line: flutter run --debug (production-like behavior)"
echo "  • Physical device: flutter run --release (true production)"
echo ""
echo "📸 Perfect for App Store screenshots!"
echo "🔄 To return to debug mode: ./scripts/switch_to_debug.sh"
