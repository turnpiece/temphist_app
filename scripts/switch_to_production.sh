#!/bin/bash

# Script to switch the app to production mode
echo "Switching to production mode..."

# Update the build config
sed -i '' 's/isDebugBuild = true/isDebugBuild = false/' lib/config/build_config.dart

echo "✅ Switched to production mode"
echo "📱 Debug features are now disabled"
echo "🔒 Debug UI will not be shown"
echo "📊 Debug logging is disabled"
echo ""
echo "To switch back to debug mode, run: ./scripts/switch_to_debug.sh"
echo "To build for production, run: flutter build web --release"
