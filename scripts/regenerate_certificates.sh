#!/bin/bash

# Script to regenerate iOS certificates using fastlane match
# This will nuke existing certificates and create new ones

set -e  # Exit on any error

echo "🔐 Regenerating iOS certificates..."

# Navigate to iOS directory
cd ios

# Check if we have the required environment variables
if [ -z "$APP_STORE_KEY_ID" ] || [ -z "$APP_STORE_ISSUER_ID" ] || [ -z "$APP_STORE_PRIVATE_KEY" ]; then
    echo "❌ Error: Missing required environment variables:"
    echo "   APP_STORE_KEY_ID: ${APP_STORE_KEY_ID:+SET}"
    echo "   APP_STORE_ISSUER_ID: ${APP_STORE_ISSUER_ID:+SET}"
    echo "   APP_STORE_PRIVATE_KEY: ${APP_STORE_PRIVATE_KEY:+SET}"
    echo ""
    echo "Please set these environment variables or export them from your secrets."
    exit 1
fi

echo "✅ Environment variables are set"

# Set up API key for App Store Connect
export API_KEY="{\"key_id\":\"$APP_STORE_KEY_ID\",\"issuer_id\":\"$APP_STORE_ISSUER_ID\",\"key_content\":\"$APP_STORE_PRIVATE_KEY\",\"is_key_content_base64\":true}"

echo "🗑️  Step 1: Nuking existing certificates..."
echo "This will remove certificates from Apple Developer Portal and the match repository"

# Nuke development certificates
echo "Nuking development certificates..."
bundle exec fastlane match nuke development --api_key "$API_KEY" --readonly false

# Nuke distribution certificates  
echo "Nuking distribution certificates..."
bundle exec fastlane match nuke distribution --api_key "$API_KEY" --readonly false

echo "✅ Step 1 complete: Existing certificates removed"

echo ""
echo "🆕 Step 2: Generating new certificates..."

# Generate new development certificates
echo "Generating development certificates..."
bundle exec fastlane match development --api_key "$API_KEY" --readonly false

# Generate new distribution certificates
echo "Generating distribution certificates..."
bundle exec fastlane match appstore --api_key "$API_KEY" --readonly false

echo "✅ Step 2 complete: New certificates generated"

echo ""
echo "🎉 Certificate regeneration complete!"
echo ""
echo "Next steps:"
echo "1. Commit and push the updated certificates to your match repository"
echo "2. Try building again"
echo ""
echo "To commit the changes:"
echo "  cd ../.."
echo "  git add ."
echo "  git commit -m 'Regenerate iOS certificates'"
echo "  git push"
