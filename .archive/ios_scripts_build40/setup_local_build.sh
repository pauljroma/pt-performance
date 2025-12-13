#!/bin/bash
# Local Build Setup Script
# This script helps you set up local iOS builds for TestFlight

set -e

echo "=================================================="
echo "🔧 Local iOS Build Setup"
echo "=================================================="
echo ""

# Check if .env already exists
if [ -f .env ]; then
    echo "⚠️  .env file already exists!"
    echo ""
    read -p "Do you want to overwrite it? (y/n): " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Setup cancelled."
        exit 1
    fi
fi

echo "You need 6 secrets from GitHub. You can get them from:"
echo "  Option 1: Ask the person who set up GitHub Actions"
echo "  Option 2: Regenerate them (if you're the admin)"
echo ""
echo "I'll guide you through each one..."
echo ""

# Function to read secret
read_secret() {
    local var_name=$1
    local description=$2
    local example=$3

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 $var_name"
    echo "   $description"
    if [ ! -z "$example" ]; then
        echo "   Example: $example"
    fi
    echo ""
    read -p "Enter value: " value
    echo "$var_name=$value" >> .env
    echo "✓ Saved"
    echo ""
}

# Create empty .env file
> .env

# Collect all secrets
read_secret "APP_STORE_CONNECT_API_KEY_ID" \
    "API Key ID from App Store Connect" \
    "9S37GWGW49"

read_secret "APP_STORE_CONNECT_API_ISSUER_ID" \
    "Issuer ID from App Store Connect" \
    "69a6de9d-2840-47e3-e053-5b8c7c11a4d1"

read_secret "APP_STORE_CONNECT_API_KEY_CONTENT" \
    "Base64-encoded .p8 key content" \
    "(long base64 string)"

read_secret "FASTLANE_TEAM_ID" \
    "Apple Developer Team ID" \
    "5NNLBL74XR"

read_secret "MATCH_PASSWORD" \
    "Password for match certificates repo" \
    "(your password)"

read_secret "MATCH_GIT_BASIC_AUTHORIZATION" \
    "Git basic auth for match repo" \
    "(base64 encoded username:token)"

echo "=================================================="
echo "✅ Setup Complete!"
echo "=================================================="
echo ""
echo "Your secrets are saved in .env"
echo ""
echo "Next steps:"
echo "  1. Run: bundle exec fastlane beta"
echo "  2. Wait 2-3 minutes for build"
echo "  3. Build will upload to TestFlight automatically"
echo ""
