#!/bin/bash

# GitHub Secrets Configuration Script for iOS TestFlight Deployment
# This script sets up all required secrets for the automated CI/CD pipeline

set -e

REPO="pauljroma/pt-performance"

echo "=== GitHub Secrets Configuration for iOS TestFlight ==="
echo ""
echo "This script will configure the following secrets:"
echo "  - APP_STORE_CONNECT_API_KEY_ID"
echo "  - APP_STORE_CONNECT_API_ISSUER_ID"
echo "  - APP_STORE_CONNECT_API_KEY_CONTENT"
echo "  - FASTLANE_TEAM_ID"
echo ""

# Check if gh CLI is installed
if ! command -v gh &> /dev/null; then
    echo "❌ ERROR: GitHub CLI (gh) is not installed."
    echo "Install it with: brew install gh"
    exit 1
fi

# Check if user is authenticated
if ! gh auth status &> /dev/null; then
    echo "❌ ERROR: Not authenticated with GitHub CLI."
    echo "Run: gh auth login"
    exit 1
fi

echo "Setting secrets for repository: $REPO"
echo ""

# Set API Key ID
echo "Setting APP_STORE_CONNECT_API_KEY_ID..."
echo "415c860b88184388b6e889bfd87bb440" | gh secret set APP_STORE_CONNECT_API_KEY_ID --repo "$REPO"

# Set API Issuer ID
echo "Setting APP_STORE_CONNECT_API_ISSUER_ID..."
echo "eebecd15-2a07-4dc3-a74c-aed17ca3887a" | gh secret set APP_STORE_CONNECT_API_ISSUER_ID --repo "$REPO"

# Set API Key Content (base64 encoded .p8 file)
echo "Setting APP_STORE_CONNECT_API_KEY_CONTENT..."
cat <<'EOF' | gh secret set APP_STORE_CONNECT_API_KEY_CONTENT --repo "$REPO"
LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0tCk1JR1RBZ0VBTUJNR0J5cUdTTTQ5QWdFR0NDcUdTTTQ5QXdFSEJIa3dkd0lCQVFRZ1FYZ1ZIbzhDdk5Ed0hoekMKOVNVNVRxZUpCQlVRM3FwU3NYWFFiN09FQ3ZHZ0NnWUlLb1pJemowREFRZWhSQU5DQUFTWlhoc3FuVGZUU1o3cApZTEtFMGI3Z0FkUVRUTEdaV0ZCKzNTbTNQOHpLM3ozTnFQTExwV0Z2a0prNVNUYmZJR0YzWXpSZDdRUllOCmNrY2tHT2RMd20zCi0tLS0tRU5EIFBSSVZBVEUgS0VZLS0tLS0K
EOF

# Set Team ID
echo "Setting FASTLANE_TEAM_ID..."
echo "5NNLBL74XR" | gh secret set FASTLANE_TEAM_ID --repo "$REPO"

echo ""
echo "✅ All secrets configured successfully!"
echo ""
echo "Verify secrets with:"
echo "  gh secret list --repo $REPO"
echo ""
echo "Next steps:"
echo "  1. Commit and push the updated Fastfile and workflow"
echo "  2. Trigger the workflow with: gh workflow run ios-testflight.yml --repo $REPO"
echo "  3. Monitor the run with: gh run list --workflow=ios-testflight.yml --repo $REPO"
echo ""
