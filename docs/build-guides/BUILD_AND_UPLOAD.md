# iOS Build and TestFlight Upload Guide

**COMPLETE WORKFLOW - Follow these steps every time**

## Prerequisites Check

```bash
# 1. Verify you're in the iOS app directory
pwd
# Should show: .../clients/linear-bootstrap/ios-app/PTPerformance

# 2. Check Xcode is installed
xcodebuild -version

# 3. Check build number
agvtool what-version
```

---

## Step 1: Increment Build Number

```bash
# Increment to next build number
agvtool next-version -all

# OR set specific build number (e.g., 14)
agvtool new-version 14

# Verify
agvtool what-version
```

---

## Step 2: Build Archive Locally

```bash
# Clean build folder first
rm -rf build/

# Build archive (takes 2-3 minutes)
xcodebuild \
  -scheme PTPerformance \
  -configuration Release \
  -archivePath ./build/PTPerformance.xcarchive \
  archive

# Check for success
ls -lh ./build/PTPerformance.xcarchive
```

**If build fails:**
- Check error message in output
- Common issues:
  - Swift compilation errors → fix code
  - Code signing → check provisioning profile
  - Missing dependencies → run `pod install` if using CocoaPods

---

## Step 3: Upload to TestFlight

### Method A: Using Xcode Organizer (RECOMMENDED - Always Works)

1. Open Xcode
2. Go to **Window → Organizer** (Cmd+Option+Shift+O)
3. Select **Archives** tab
4. Find **PTPerformance version 1.0 (XX)** - should be at top
5. Click **Distribute App**
6. Select **App Store Connect** → **Upload** → **Next**
7. Accept defaults → **Upload**
8. Wait 2-5 minutes for processing

### Method B: Command Line Upload (Requires Setup)

**First Time Setup:**

```bash
# Create .env file with credentials
cd ~/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
cat > .env.fastlane <<'EOF'
APP_STORE_CONNECT_API_KEY_ID="your-key-id"
APP_STORE_CONNECT_API_ISSUER_ID="your-issuer-id"
APP_STORE_CONNECT_API_KEY_CONTENT="base64-encoded-key"
FASTLANE_APPLE_ID="your@email.com"
EOF

chmod 600 .env.fastlane
```

**Get App Store Connect API Key:**
1. Go to https://appstoreconnect.apple.com/access/api
2. Create key with "App Manager" role
3. Download .p8 file
4. Base64 encode: `cat AuthKey_XXXXX.p8 | base64`

**Upload command:**

```bash
# Source credentials
source .env.fastlane

# Upload using fastlane
fastlane pilot upload \
  --ipa ./build/PTPerformance.ipa \
  --skip_waiting_for_build_processing

# OR upload archive directly
fastlane pilot upload \
  --build_number $(agvtool what-version | tail -1) \
  --skip_waiting_for_build_processing
```

### Method C: Upload Script (Run After Build)

```bash
# Run the upload script
./upload_to_testflight.sh

# Script will:
# 1. Export .ipa from archive
# 2. Validate .ipa
# 3. Upload to TestFlight
# 4. Show TestFlight URL
```

---

## Step 4: Verify Upload

1. Go to https://appstoreconnect.apple.com
2. Select **PTPerformance** app
3. Go to **TestFlight** tab
4. Check **iOS Builds** - new build should appear in ~5 minutes
5. Status will show:
   - "Processing" (5-10 min)
   - "Ready to Test" (good!)
   - "Missing Compliance" (needs export compliance answer)

---

## Complete One-Command Build & Upload

```bash
# Clean, build, and prepare for upload (use Xcode Organizer for upload)
./build_for_testflight.sh 14

# This script:
# 1. Sets build number to 14
# 2. Cleans build folder
# 3. Builds archive
# 4. Opens Xcode Organizer
# 5. You click "Distribute App" → "Upload"
```

---

## Troubleshooting

### Build Fails with Swift Errors
```bash
# Check what changed
git diff

# If you edited code, fix the errors shown
# Common: Optional binding issues, type mismatches
```

### Build Fails with "Provisioning Profile"
```bash
# Open in Xcode and let it manage signing
open PTPerformance.xcodeproj

# Go to Signing & Capabilities
# Check "Automatically manage signing"
```

### Upload Fails with "Authentication Failed"
```bash
# Method A: Use Xcode Organizer (always works with your Apple ID)

# Method B: Re-create App Store Connect API key
# Go to appstoreconnect.apple.com/access/api
```

### "No builds available" in TestFlight
- Wait 10 minutes - processing takes time
- Check email for errors from Apple
- Verify app was uploaded: `xcrun altool --list-apps`

---

## Why This Process?

**1. Local Build** (xcodebuild archive)
- Creates .xcarchive file
- Includes all assets, symbols, bitcode
- Can be uploaded multiple ways

**2. Export (optional)**
- Converts .xcarchive → .ipa
- .ipa is the final app bundle
- Required for some upload methods

**3. Upload**
- Sends to App Store Connect
- Processes for TestFlight
- Takes 5-10 minutes to appear

---

## Quick Reference Card

```bash
# STANDARD BUILD & UPLOAD PROCESS
cd ios-app/PTPerformance

# 1. Increment build
agvtool new-version 14

# 2. Build archive
xcodebuild -scheme PTPerformance -configuration Release \
  -archivePath ./build/PTPerformance.xcarchive archive

# 3. Open Xcode Organizer and upload
open -a Xcode PTPerformance.xcodeproj
# Window → Organizer → Archives → Distribute App
```

---

## File Locations

```
build/PTPerformance.xcarchive     - Archive (created by xcodebuild)
build/PTPerformance.ipa            - IPA (exported from archive)
fastlane/logs/                     - Build logs
ExportOptions.plist                - Export configuration
.env.fastlane                      - Upload credentials (DO NOT COMMIT)
```

---

## Credentials Storage

**NEVER commit these files:**
- `.env.fastlane` - Has API keys
- `AuthKey_*.p8` - App Store Connect API key file
- `*.mobileprovision` - Provisioning profiles

**Add to .gitignore:**
```bash
echo ".env.fastlane" >> .gitignore
echo "AuthKey_*.p8" >> .gitignore
echo "*.mobileprovision" >> .gitignore
```

---

## Testing the Build

After upload, test on physical device:

1. Install TestFlight app on iPad
2. Open TestFlight
3. Find "PTPerformance"
4. Tap "Install"
5. Test all features:
   - Login
   - View patient list
   - View patient detail (all 4 sections)
   - Add a note
   - View program

---

## Emergency: Need to Upload RIGHT NOW

```bash
# Fast path - uses Xcode UI
./emergency_upload.sh

# This opens Xcode Organizer with the latest archive selected
# Just click: Distribute App → App Store Connect → Upload → Upload
```

---

## Common Mistakes to Avoid

1. ❌ Forgetting to increment build number
   - Result: Upload fails with "build already exists"
   - Fix: `agvtool next-version -all`

2. ❌ Not cleaning build folder
   - Result: Old build cached, changes not included
   - Fix: `rm -rf build/`

3. ❌ Using wrong upload method
   - Result: Authentication errors
   - Fix: Use Xcode Organizer (always works)

4. ❌ Not waiting for processing
   - Result: "No builds in TestFlight"
   - Fix: Wait 10 minutes, refresh

5. ❌ Building wrong scheme
   - Result: Different app uploaded
   - Fix: Always use `-scheme PTPerformance`

---

## Archive This Guide

Save this file in the project root so it's always available.

Next time you need to upload:
1. Read this file
2. Follow the steps
3. Don't improvise!
