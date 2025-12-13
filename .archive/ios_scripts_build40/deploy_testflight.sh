#!/bin/bash
set -e

# TestFlight Deployment Automation Script
# Usage: ./deploy_testflight.sh <build_number>
# Example: ./deploy_testflight.sh 35

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}==>${NC} $1"
}

print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

print_error() {
    echo -e "${RED}❌${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠️${NC}  $1"
}

# Check if build number is provided
if [ -z "$1" ]; then
    print_error "Build number required!"
    echo "Usage: ./deploy_testflight.sh <build_number>"
    echo "Example: ./deploy_testflight.sh 35"
    exit 1
fi

BUILD_NUMBER=$1
PREVIOUS_BUILD=$((BUILD_NUMBER - 1))

print_step "Starting TestFlight deployment for Build $BUILD_NUMBER"
echo ""

# ============================================================================
# STEP 1: Apply Database Migrations
# ============================================================================

print_step "STEP 1: Applying database migrations..."
cd /Users/expo/Code/expo/clients/linear-bootstrap

# Load environment variables
if [ ! -f .env ]; then
    print_error ".env file not found!"
    exit 1
fi

source .env

# Set Supabase access token
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"
export SUPABASE_DB_PASSWORD="${SUPABASE_PASSWORD}"

# Check for unapplied migrations
UNAPPLIED_MIGRATIONS=$(ls supabase/migrations/*.sql 2>/dev/null | grep -v ".applied" || true)

if [ -n "$UNAPPLIED_MIGRATIONS" ]; then
    print_warning "Found unapplied migrations:"
    echo "$UNAPPLIED_MIGRATIONS"
    echo ""

    # Apply migrations
    print_step "Applying migrations to remote database..."
    if supabase db push -p "${SUPABASE_PASSWORD}" --include-all; then
        print_success "Migrations applied successfully"

        # Mark as applied
        for migration in $UNAPPLIED_MIGRATIONS; do
            mv "$migration" "${migration}.applied"
            print_success "Marked $(basename $migration) as applied"
        done
    else
        print_error "Migration failed! Check errors above."
        exit 1
    fi
else
    print_success "No unapplied migrations found"
fi

echo ""

# ============================================================================
# STEP 2: Increment Build Number
# ============================================================================

print_step "STEP 2: Incrementing build number to $BUILD_NUMBER..."
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Update Config.swift
sed -i '' "s/static let buildNumber = \"$PREVIOUS_BUILD\"/static let buildNumber = \"$BUILD_NUMBER\"/" Config.swift
print_success "Updated Config.swift"

# Update Xcode project
sed -i '' "s/CURRENT_PROJECT_VERSION = $PREVIOUS_BUILD;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" PTPerformance.xcodeproj/project.pbxproj
print_success "Updated PTPerformance.xcodeproj"

echo ""

# ============================================================================
# STEP 3: Clean Build Directories
# ============================================================================

print_step "STEP 3: Cleaning build directories..."
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/PTPerformance-*
print_success "Build directories cleaned"

echo ""

# ============================================================================
# STEP 4: Build Archive
# ============================================================================

print_step "STEP 4: Building iOS archive..."
print_warning "This may take 2-3 minutes..."

if xcodebuild archive \
    -project PTPerformance.xcodeproj \
    -scheme PTPerformance \
    -archivePath build/PTPerformance.xcarchive \
    -configuration Release \
    -allowProvisioningUpdates 2>&1 | tail -5; then
    print_success "Archive build succeeded"
else
    print_error "Archive build failed!"
    exit 1
fi

echo ""

# ============================================================================
# STEP 5: Export IPA
# ============================================================================

print_step "STEP 5: Exporting IPA..."

if xcodebuild -exportArchive \
    -archivePath build/PTPerformance.xcarchive \
    -exportPath build/ \
    -exportOptionsPlist ExportOptions.plist \
    -allowProvisioningUpdates 2>&1 | tail -3; then
    print_success "IPA export succeeded"
else
    print_error "IPA export failed!"
    exit 1
fi

# Verify IPA exists
if [ -f "build/PTPerformance.ipa" ]; then
    IPA_SIZE=$(ls -lh build/PTPerformance.ipa | awk '{print $5}')
    print_success "IPA created: $IPA_SIZE"
else
    print_error "IPA file not found!"
    exit 1
fi

echo ""

# ============================================================================
# STEP 6: Upload to TestFlight
# ============================================================================

print_step "STEP 6: Uploading to TestFlight..."
print_warning "This may take 30-60 seconds..."

source .env

if xcrun altool --upload-app \
    --type ios \
    --file "build/PTPerformance.ipa" \
    --apiKey ${APP_STORE_CONNECT_API_KEY_ID} \
    --apiIssuer ${APP_STORE_CONNECT_API_ISSUER_ID} 2>&1 | grep -E "UPLOAD|UUID|Transferred"; then
    echo ""
    print_success "Upload succeeded!"
else
    print_error "Upload failed!"
    exit 1
fi

echo ""

# ============================================================================
# STEP 7: Summary
# ============================================================================

print_success "Build $BUILD_NUMBER deployment complete!"
echo ""
echo "Next steps:"
echo "1. Wait 5-15 minutes for Apple to process the build"
echo "2. Check App Store Connect: https://appstoreconnect.apple.com/apps"
echo "3. Install on iPad via TestFlight when ready"
echo "4. Test the new features"
echo ""
print_warning "Don't forget to commit your changes:"
echo "git add -A"
echo "git commit -m \"build: Deploy Build $BUILD_NUMBER to TestFlight\""
echo ""
