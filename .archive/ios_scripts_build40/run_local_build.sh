#!/bin/bash
# Run Local iOS Build with .env support
# Usage: ./run_local_build.sh

set -e

cd "$(dirname "$0")"

# Setup rbenv
export PATH="$HOME/.rbenv/shims:$PATH"
eval "$(rbenv init - bash 2>/dev/null)" || true

echo "=================================================="
echo "🚀 Starting Local iOS Build"
echo "=================================================="
echo ""

# Check if .env exists
if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found!"
    echo ""
    echo "Please run setup first:"
    echo "  ./setup_local_build.sh"
    echo ""
    echo "Or see: QUICK_LOCAL_BUILD_SETUP.md"
    exit 1
fi

echo "✓ Found .env file"
echo ""

# Load environment variables from .env
echo "📦 Loading environment variables..."
set -a
source .env
set +a

# Verify required variables
required_vars=(
    "APP_STORE_CONNECT_API_KEY_ID"
    "APP_STORE_CONNECT_API_ISSUER_ID"
    "APP_STORE_CONNECT_API_KEY_CONTENT"
    "FASTLANE_TEAM_ID"
    "MATCH_PASSWORD"
    "MATCH_GIT_BASIC_AUTHORIZATION"
)

missing_vars=0
for var in "${required_vars[@]}"; do
    if [ -z "${!var}" ]; then
        echo "❌ Missing: $var"
        missing_vars=1
    else
        echo "✓ $var is set"
    fi
done

if [ $missing_vars -eq 1 ]; then
    echo ""
    echo "❌ ERROR: Some required variables are missing!"
    echo "Please check your .env file."
    exit 1
fi

echo ""
echo "=================================================="
echo "🏗️  Building iOS App..."
echo "=================================================="
echo ""
echo "This will take 2-3 minutes on M3 Ultra"
echo "You'll see real-time progress below:"
echo ""

# Run fastlane
bundle exec fastlane beta

echo ""
echo "=================================================="
echo "✅ Build Complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Check App Store Connect in 5-10 minutes"
echo "  2. Build will appear in TestFlight"
echo "  3. Install TestFlight app on iPad to test"
echo ""
