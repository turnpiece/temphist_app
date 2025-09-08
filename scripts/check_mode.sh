#!/bin/bash

# Script to check current app mode
echo "🔍 Checking current app mode..."

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Error: Please run this script from the Flutter project root directory"
    exit 1
fi

# Check debug config
if [ -f "lib/config/debug_config.dart" ]; then
    echo "📝 Debug configuration:"
    
    if grep -q "enableDebugLogging = true" lib/config/debug_config.dart; then
        echo "  🐛 Debug logging: ENABLED"
    else
        echo "  🐛 Debug logging: DISABLED"
    fi
    
    if grep -q "enableDebugUI = true" lib/config/debug_config.dart; then
        echo "  🎛️  Debug UI: ENABLED"
    else
        echo "  🎛️  Debug UI: DISABLED"
    fi
    
    if grep -q "enableEndpointFailureSimulation = true" lib/config/debug_config.dart; then
        echo "  🎯 Endpoint simulation: ENABLED"
    else
        echo "  🎯 Endpoint simulation: DISABLED"
    fi
    
    if grep -q "Development Build" lib/config/debug_config.dart; then
        echo "  📱 Mode: DEBUG"
    else
        echo "  📱 Mode: PRODUCTION-LIKE"
    fi
else
    echo "❌ Debug configuration file not found"
fi

echo ""
echo "🔄 To switch modes:"
echo "  • Debug mode: ./scripts/switch_to_debug.sh"
echo "  • Production mode: ./scripts/switch_to_production.sh"
