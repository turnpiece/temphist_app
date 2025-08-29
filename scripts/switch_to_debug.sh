#!/bin/bash

# Script to switch the app to debug mode
echo "Switching to debug mode..."

# Update the build config to use environment variable for debug
sed -i '' 's/defaultValue: false/defaultValue: true/' lib/config/build_config.dart

echo "✅ Switched to debug mode"
echo "🐛 Debug features are now enabled"
echo "🎛️  Debug UI will be shown"
echo "📝 Debug logging is enabled"
echo ""
echo "To switch to production mode, run: ./scripts/switch_to_production.sh"
echo "To build for development, run: flutter build web --debug"
