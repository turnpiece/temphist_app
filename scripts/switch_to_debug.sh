#!/bin/bash

# Script to switch the app to debug mode
echo "Switching to debug mode..."

# Update the build config
sed -i '' 's/isDebugBuild = false/isDebugBuild = true/' lib/config/build_config.dart

echo "✅ Switched to debug mode"
echo "🐛 Debug features are now enabled"
echo "🎛️  Debug UI will be shown"
echo "📝 Debug logging is enabled"
echo ""
echo "To switch to production mode, run: ./scripts/switch_to_production.sh"
echo "To build for development, run: flutter build web --debug"
