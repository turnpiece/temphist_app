#!/bin/bash

# Script to switch the app to production mode
echo "Switching to production mode..."

echo "✅ Production mode configuration ready"
echo "📱 Debug features will be disabled in release builds"
echo "🔒 Debug UI will not be shown in release builds"
echo "📊 Debug logging is disabled in release builds"
echo ""
echo "To build for production:"
echo "  flutter build apk --release"
echo "  flutter build ios --release"
echo "  flutter build web --release"
echo ""
echo "To test in debug mode: flutter run --debug"
echo "To test in production mode: flutter run --release"
echo ""
echo "Note: The app automatically uses production config when built with --release flag"
