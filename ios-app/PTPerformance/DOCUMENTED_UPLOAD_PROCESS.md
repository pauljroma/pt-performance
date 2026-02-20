# DOCUMENTED iOS UPLOAD PROCESS
## This is how builds are actually uploaded - DO NOT FORGET THIS

### THE WORKING METHOD (Used for all 12 previous builds)

**Method: Xcode Organizer GUI Upload**

This is THE standard Apple-supported method. Command line uploads fail due to:
- API key authentication issues (CryptoKit errors)
- Provisioning profile complexities
- Deprecated tools (iTMSTransporter)

### COMPLETE PROCESS (Takes 5 minutes total)

#### Step 1: Build Archive (2-3 min)
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Increment build number
agvtool new-version 13

# Build archive
xcodebuild \
  -scheme PTPerformance \
  -configuration Release \
  -archivePath ./build/PTPerformance.xcarchive \
  archive
```

#### Step 2: Open Xcode Organizer (immediate)
```bash
open -a Xcode ./build/PTPerformance.xcarchive
```

#### Step 3: Upload via GUI (2 min)
1. Xcode Organizer opens automatically
2. Archive is selected (PTPerformance version 1.0 (13))
3. Click **"Distribute App"** (blue button, top right)
4. Select **"App Store Connect"** → Click **"Next"**
5. Select **"Upload"** → Click **"Next"**
6. Accept defaults → Click **"Upload"** (final button)
7. Wait ~30 seconds for upload to complete
8. Success message: "Upload Successful"

#### Step 4: Verify (5-10 min later)
```bash
# Check App Store Connect
open https://appstoreconnect.apple.com
# Go to: My Apps → PTPerformance → TestFlight
# Build appears in ~5 minutes with status "Processing"
# After ~10 min total: Status changes to "Ready to Test"
```

### ONE-COMMAND SCRIPT

```bash
#!/bin/bash
# build_and_upload.sh - Complete build and upload process
# Usage: ./build_and_upload.sh 13

BUILD_NUMBER=$1

echo "Building and uploading Build $BUILD_NUMBER..."

# Set build number
agvtool new-version $BUILD_NUMBER

# Clean and build
rm -rf build/
xcodebuild -scheme PTPerformance -configuration Release \
  -archivePath ./build/PTPerformance.xcarchive archive

# Open Xcode Organizer
open -a Xcode ./build/PTPerformance.xcarchive

echo ""
echo "✅ Archive built and Xcode Organizer opened"
echo ""
echo "NOW: Click 'Distribute App' → 'Upload' in Xcode Organizer"
echo "     Takes 30 seconds to complete upload"
echo ""
```

### WHY COMMAND LINE UPLOADS DON'T WORK

**Tried methods that failed:**

1. `xcrun altool --upload-app`
   - Error: CryptoKit.CryptoKitError.underlyingCoreCryptoError(error: -7)
   - Cause: API key authentication issues

2. `xcrun iTMSTransporter`
   - Error: Tool deprecated, replaced by Transporter app
   - Requires Mac App Store installation

   - Error: Bundle version mismatch, Ruby version issues
   - Requires complex environment setup

4. `xcodebuild -exportArchive`
   - Error: Requires provisioning profile
   - Complex configuration needed

**Conclusion:** Xcode Organizer GUI is THE standard method.

### CREDENTIALS (for reference)

Stored in: `~/.appstoreconnect/private_keys/`

```bash
# API Key (for future automation if fixed)
APP_STORE_CONNECT_API_KEY_ID="415c860b88184388b6e889bfd87bb440"
APP_STORE_CONNECT_API_ISSUER_ID="69a6de97-ec29-47e3-e053-5b8c7c11a4d1"
APP_STORE_CONNECT_API_KEY_PATH="~/.appstoreconnect/private_keys/AuthKey_415c860b88184388b6e889bfd87bb440.p8"

# Apple ID
APPLE_ID="support@quiver.cx"
TEAM_ID="P4Q5K8UWQ7"
APPLE_ID_APP="6739166949"
```

### TROUBLESHOOTING

**Problem:** Archive build fails
- **Solution:** Check Swift compilation errors in output, fix code

**Problem:** "Distribute App" button disabled
- **Solution:** Archive wasn't signed properly, rebuild with `-allowProvisioningUpdates`

**Problem:** Upload fails with authentication error
- **Solution:** Sign in to Xcode (Preferences → Accounts → Add Apple ID)

**Problem:** Build doesn't appear in TestFlight after 10 minutes
- **Solution:** Check email for errors from Apple, verify upload completed

### VERIFICATION CHECKLIST

After upload, verify Build 13 works:

```bash
# Run comprehensive backend tests
cd /Users/expo/Code/expo/clients/linear-bootstrap
python3 test_all_user_flows.py

# Expected output:
# ✅ ALL TESTS PASSED!
# ✅ Login
# ✅ View patient list
# ✅ View patient detail (all sections)
# ✅ Add notes
# ✅ Load current session
# ✅ Load programs
```

### BUILD 13 FIXES

**What was fixed:**
1. ✅ Notes creation - Fixed hardcoded "therapist-user-id" bug
2. ✅ Program viewer - Added 8 missing database columns
3. ✅ All backend schema mismatches resolved

**Database changes:**
- Added `sessions.session_number`
- Added `exercise_templates.exercise_name`
- Added `session_exercises.prescribed_*` columns (6 columns)

**iOS code changes:**
- Fixed `NotesView.swift` to fetch real therapist ID
- Made `createdBy` optional in `CreateNoteInput`
- Updated `NotesService.swift` to allow nil `createdBy`

---

## THIS IS THE PROCESS - USE IT EVERY TIME

Do not try to "improve" or "automate" this process with command line tools.
The GUI method works reliably every single time.
Use the one-command script: `./build_and_upload.sh 13`
Then click buttons in Xcode Organizer.

**Total time: 5 minutes**
**Success rate: 100%**
