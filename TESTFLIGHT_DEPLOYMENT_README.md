# TestFlight Deployment Process - Builds 1-33+

## Overview

This documents the **complete CLI-based process** for building and deploying iOS builds to TestFlight.
**User never opens Xcode** - everything is done via command line by Claude.

## Prerequisites

- Xcode Command Line Tools installed
- Apple Developer account credentials
- App Store Connect API key configured
- Ruby with xcodeproj gem installed

## Process Summary

1. Make code changes (Swift files)
2. Apply database migrations (via Supabase CLI - `supabase db push`)
3. Increment build number
4. **Add new files to Xcode project** (using xcodeproj gem)
5. Fix code compilation errors
6. Build archive via xcodebuild
7. Export IPA
8. Upload to TestFlight
9. Test on physical device (iPad via TestFlight)

---

## COMPLETE STEP-BY-STEP PROCESS (Build 33 - December 2024)

### Step 1: Apply Database Migration

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
supabase db push --password "${SUPABASE_PASSWORD}" --include-all
```

**If migration conflicts occur:**
```bash
supabase migration repair --status applied <timestamp> --password "${SUPABASE_PASSWORD}"
```

**Mark migration as applied:**
```bash
mv supabase/migrations/<timestamp>_<name>.sql supabase/migrations/<timestamp>_<name>.sql.applied
```

---

### Step 2: Increment Build Number

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Update Config.swift
# Change: static let buildNumber = "32"
# To: static let buildNumber = "33"

# Update Xcode project
sed -i '' 's/CURRENT_PROJECT_VERSION = 32;/CURRENT_PROJECT_VERSION = 33;/g' PTPerformance.xcodeproj/project.pbxproj
```

---

### Step 3: Add New Swift Files to Xcode Project (CRITICAL!)

**⚠️ This is the step that gets forgotten every time!**

When you create new Swift files, they must be added to the Xcode project or they won't compile.

**Use the xcodeproj Ruby gem (the ONLY reliable method):**

```ruby
#!/usr/bin/env ruby
require 'xcodeproj'

project = Xcodeproj::Project.open('PTPerformance.xcodeproj')
target = project.targets.first

# Find or create the appropriate group
views_group = project.main_group.find_subpath('Views', true)
patient_group = views_group.find_subpath('Patient', true) || views_group.new_group('Patient')

# Add the file reference
file_path = 'Views/Patient/SessionSummaryView.swift'  # Adjust path as needed
file_ref = patient_group.new_reference(file_path)

# Add to target's sources build phase
target.source_build_phase.add_file_reference(file_ref)

# Save
project.save
puts "✅ Added #{file_path} to Xcode project"
```

**Save as `add_file_to_project.rb` and run:**
```bash
ruby add_file_to_project.rb
```

**Why xcodeproj gem?**
- ❌ Python scripts that edit project.pbxproj directly often corrupt the file
- ❌ Manual editing of XML is error-prone
- ✅ xcodeproj gem is what fastlane uses - it's the standard tool
- ✅ Properly handles all the UUID generation and group structure

---

### Step 4: Fix Compilation Errors

Common errors when adding new Swift files:

**Error: "cannot find 'SomeView' in scope"**
- The file wasn't added to the Xcode project (see Step 3)
- Clear derived data: `rm -rf ~/Library/Developer/Xcode/DerivedData/PTPerformance-*`

**Error: "Type 'Any' cannot conform to 'Encodable'"**
- Use a proper Codable struct instead of `[String: Any]` dictionaries
- Example:
```swift
struct UpdateData: Codable {
    let field1: String
    let field2: Int
}
```

---

### Step 5: Build Archive

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Clean (optional but recommended)
rm -rf build/
rm -rf ~/Library/Developer/Xcode/DerivedData/PTPerformance-*

# Build archive
xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -archivePath build/PTPerformance.xcarchive \
  -configuration Release \
  -allowProvisioningUpdates
```

**Expected output:**
```
** ARCHIVE SUCCEEDED **
```

**If it fails:**
- Check error messages for missing files → Go back to Step 3
- Check for Swift compilation errors → Fix code
- Check for signing issues → Verify team ID is correct

---

### Step 6: Export IPA

**Update ExportOptions.plist** (if needed):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>5NNLBL74XR</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>uploadBitcode</key>
    <false/>
    <key>uploadSymbols</key>
    <true/>
    <key>compileBitcode</key>
    <false/>
</dict>
</plist>
```

**Export:**
```bash
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist \
  -allowProvisioningUpdates
```

**Expected output:**
```
** EXPORT SUCCEEDED **
```

**Verify IPA created:**
```bash
ls -lh build/*.ipa
# Should show: build/PTPerformance.ipa (~2.8MB)
```

---

### Step 7: Install App Store Connect API Key

**One-time setup:**
```bash
mkdir -p ~/.appstoreconnect/private_keys/

# Get credentials from .env file
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
source .env

# Decode and install API key
echo "$APP_STORE_CONNECT_API_KEY_CONTENT" | base64 -d > ~/.appstoreconnect/private_keys/AuthKey_${APP_STORE_CONNECT_API_KEY_ID}.p8

chmod 600 ~/.appstoreconnect/private_keys/AuthKey_*.p8
```

**Verify:**
```bash
ls -la ~/.appstoreconnect/private_keys/
# Should show: AuthKey_9S37GWGW49.p8
```

---

### Step 8: Upload to TestFlight

```bash
source .env  # Load API credentials

xcrun altool --upload-app \
  --type ios \
  --file "build/PTPerformance.ipa" \
  --apiKey ${APP_STORE_CONNECT_API_KEY_ID} \
  --apiIssuer ${APP_STORE_CONNECT_API_ISSUER_ID}
```

**Expected output:**
```
==========================================
UPLOAD SUCCEEDED with no errors
Delivery UUID: <uuid>
==========================================
```

---

### Step 9: Wait for Processing & Test

**Processing time:** 5-15 minutes

**Check status:**
1. Go to https://appstoreconnect.apple.com
2. Navigate to PT Performance → TestFlight
3. Wait for build to appear with status "Ready to Test"

**Install on iPad:**
1. Open TestFlight app on iPad
2. Pull to refresh
3. Install new build (Build 33)
4. Test the feature

---

## Method 1: Using xcrun (Apple's Official Tool) - DEPRECATED

**Note:** The above process (Steps 1-9) is the current working method as of Build 33.
The methods below are kept for reference but may not work without modifications.

### Step 1: Build the Archive

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Clean build folder
rm -rf build/

# Build archive
xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -archivePath build/PTPerformance.xcarchive \
  -configuration Release \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=5NNLBL74XR
```

### Step 2: Export IPA

```bash
# Export for App Store distribution
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist
```

**ExportOptions.plist** (create if doesn't exist):
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>app-store</string>
    <key>teamID</key>
    <string>5NNLBL74XR</string>
    <key>uploadSymbols</key>
    <true/>
    <key>uploadBitcode</key>
    <false/>
</dict>
</plist>
```

### Step 3: Upload to TestFlight

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/PTPerformance.ipa \
  --apiKey NKWNDTD3DJ \
  --apiIssuer 69a6de9d-2840-47e3-e053-5b8c7c11a4d1
```

**Note:** API key file (.p8) must be in `~/.private_keys/` or `~/private_keys/` or `~/.appstoreconnect/private_keys/`

---

## Method 2: Custom Build Script

### Create build_and_upload.sh

```bash
#!/bin/bash
set -e

BUILD_NUMBER=$1
if [ -z "$BUILD_NUMBER" ]; then
  echo "Usage: ./build_and_upload.sh <build_number>"
  exit 1
fi

echo "🚀 Building Build $BUILD_NUMBER for TestFlight"

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Clean
echo "🧹 Cleaning..."
rm -rf build/

# Update build number
echo "📝 Updating build number to $BUILD_NUMBER..."
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" PTPerformance/Info.plist || true
sed -i '' "s/CURRENT_PROJECT_VERSION = [0-9]*;/CURRENT_PROJECT_VERSION = $BUILD_NUMBER;/g" PTPerformance.xcodeproj/project.pbxproj

# Build archive
echo "🔨 Building archive..."
xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -archivePath build/PTPerformance.xcarchive \
  -configuration Release \
  CODE_SIGN_STYLE=Automatic \
  DEVELOPMENT_TEAM=5NNLBL74XR

# Export IPA
echo "📦 Exporting IPA..."
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportPath build/ \
  -exportOptionsPlist ExportOptions.plist

# Upload
echo "📤 Uploading to TestFlight..."
xcrun altool --upload-app \
  --type ios \
  --file build/PTPerformance.ipa \
  --apiKey NKWNDTD3DJ \
  --apiIssuer 69a6de9d-2840-47e3-e053-5b8c7c11a4d1

echo "✅ Build $BUILD_NUMBER uploaded successfully!"
echo "⏳ Processing will take 5-15 minutes on Apple's servers"
```

### Usage

```bash
chmod +x build_and_upload.sh
./build_and_upload.sh 33
```

---

## API Key Setup (One-Time)

If API key isn't set up:

1. Download API key from App Store Connect:
   - Go to: https://appstoreconnect.apple.com/access/api
   - Keys tab → Generate new key (or use existing)
   - Download .p8 file

2. Place in correct directory:
   ```bash
   mkdir -p ~/.appstoreconnect/private_keys/
   mv ~/Downloads/AuthKey_NKWNDTD3DJ.p8 ~/.appstoreconnect/private_keys/
   ```

**Existing Credentials:**
- Key ID: `NKWNDTD3DJ`
- Issuer ID: `69a6de9d-2840-47e3-e053-5b8c7c11a4d1`
- Team ID: `5NNLBL74XR`

---

## Post-Upload

After upload completes:

1. **Wait 5-15 minutes** for Apple to process the build
2. **Check App Store Connect:**
   - https://appstoreconnect.apple.com/apps
   - Navigate to PT Performance → TestFlight
   - Verify build appears with correct number
3. **Install on iPad:**
   - Open TestFlight app on iPad
   - Pull to refresh
   - Install new build
4. **Test:**
   - Login as demo patient
   - Test the new feature
   - Verify no crashes/regressions

---

## Troubleshooting

### "No signing identity found"

```bash
# List available signing identities
security find-identity -v -p codesigning

# If none found, sign in to Xcode (one-time):
xcodebuild -checkFirstLaunchStatus
```

### "Could not find API key"

```bash
# Verify key file location
ls -la ~/.appstoreconnect/private_keys/

# Should see: AuthKey_NKWNDTD3DJ.p8
```

### "Archive failed"

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/

# Try again
```

---

## Build History

| Build | Date | Method Used | Status |
|-------|------|-------------|--------|
| 1-31  | 2025-11-XX | Mixed | ✅ Archived |
| 32    | 2025-12-12 | Unknown (xcrun or script) | ✅ Complete |
| 33    | 2025-12-12 | TBD | 🔄 In Progress |

---

## Next Steps for Build 33

**TODO:**
1. ☐ Determine which method was used for Build 32
2. ☐ Use same method for Build 33 for consistency
3. ☐ Document actual command used
4. ☐ Create script if none exists

---

**Last Updated:** 2025-12-12
**Maintained By:** Claude (via command line)
