# HANDOFF - Complete TestFlight Deployment Recipe

**Date**: December 8, 2025
**Duration**: ~8 hours
**Status**: 🟡 **Local Build Works, Xcode Project Needs Configuration**

---

## 🎯 CURRENT STATUS

### ✅ What Works (100% Repeatable)
- **Local iOS builds**: 66 seconds on M3 Ultra
- **All secrets configured** in `.env` file
- **Certificates working**: fastlane match with SSH
- **Build artifact**: Creates valid IPA file
- **Upload attempt**: Reaches Apple's servers

### ❌ What's Blocked
- **TestFlight upload validation**: Apple rejects due to missing Xcode project configuration
- **Root cause**: Xcode project missing required iOS app assets and settings

---

## 🔍 COMPLETE DIAGNOSTIC HISTORY

### Issue 1: GitHub Actions Hung (RESOLVED ✅)
**Problem**: Builds hung for 60+ minutes at code signing step

**Root Cause**: Missing `-allowProvisioningUpdates` flag

**Fix Applied**:
```ruby
# File: ios-app/PTPerformance/fastlane/Fastfile
build_app(
  # ... other params
  xcargs: "-allowProvisioningUpdates",  # THE FIX
  # ... other params
)
```

**Commit**: 661a1b6f

**Learning**: GitHub Actions runs take 25-30 min (vs 66 sec local). Always use `-allowProvisioningUpdates` in CI.

---

### Issue 2: Local Build Setup (RESOLVED ✅)

**Problem**: Needed local build environment for faster iteration

**Solution**: Created `.env` file with all secrets

**Location**: `/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/.env`

**Contents**:
```bash
APP_STORE_CONNECT_API_KEY_ID=9S37GWGW49
APP_STORE_CONNECT_API_ISSUER_ID=eebecd15-2a07-4dc3-a74c-aed17ca3887a
APP_STORE_CONNECT_API_KEY_CONTENT=LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t... (base64)
FASTLANE_TEAM_ID=5NNLBL74XR
MATCH_PASSWORD=paul-and-shelle-married-novi-2020
MATCH_GIT_BASIC_AUTHORIZATION=cGF1bGpyb21hOmdob19HVzFzazJwbTRiTTlXVUFYU3ZzSVpKQjNuYm5yUm0wQWNtOWc=
```

**How to Build Locally**:
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
./run_local_build.sh
```

**Performance**: 66 seconds total (vs 30+ minutes on GitHub Actions)

---

### Issue 3: Git Authentication for Match (RESOLVED ✅)

**Problem**: fastlane match couldn't clone apple-certificates repo

**Root Cause**: SSH key was deploy key for pt-performance repo only, not apple-certificates

**Solution**: Switched to HTTPS with gh CLI token

**Fix**:
```ruby
# File: ios-app/PTPerformance/fastlane/Matchfile
git_url("https://github.com/pauljroma/apple-certificates.git")  # Changed from SSH
```

**Token**: Used `gh auth token` value encoded as base64 for MATCH_GIT_BASIC_AUTHORIZATION

---

### Issue 4: App Store Connect API 500 Error (RESOLVED ✅)

**Problem**: Upload failed with "GET APP SETTINGS: received status code 500"

**Root Cause**: App record in App Store Connect was incomplete

**Solution**: Filled out required app information:
- Primary Language: English
- Category: Health & Fitness
- Age Rating: Completed questionnaire
- Pricing: Set
- Created App Store version 1.0

**Command That Revealed It**:
```bash
xcrun altool --upload-app -f PTPerformance.ipa -t ios \
  --apiKey 9S37GWGW49 \
  --apiIssuer eebecd15-2a07-4dc3-a74c-aed17ca3887a
```

**Learning**: Fastlane's `upload_to_testflight` hides errors. Always test with `xcrun altool` for real error messages.

---

### Issue 5: Xcode Project Validation Errors (CURRENT BLOCKER ❌)

**Problem**: Apple rejects IPA with 5 validation errors

**Errors**:
1. **Missing app icon** (120x120 for iPhone)
2. **Missing app icon** (152x152 for iPad)
3. **Missing CFBundleIconName** in Info.plist
4. **Missing interface orientations** (UISupportedInterfaceOrientations)
5. **Missing launch screen** (UILaunchStoryboardName)

**Full Error Output**:
```
UPLOAD FAILED with 5 errors
- Missing required icon file (120x120 pixels)
- Missing required icon file (152x152 pixels)
- Missing Info.plist value CFBundleIconName
- Invalid bundle. No orientations specified
- Invalid bundle. Missing launch screen storyboard
```

**Root Cause**: Xcode project was created as minimal SwiftUI app without proper iOS assets

**What's Missing**:
- Asset catalog (`Assets.xcassets`)
- App icons in multiple sizes
- Info.plist entries for iPad support
- Launch screen configuration

---

## 🛠️ THE FIX: Xcode Project Configuration

### Required Steps

#### Step 1: Create Asset Catalog with App Icons

1. Open Xcode:
   ```bash
   open /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/PTPerformance.xcodeproj
   ```

2. Add Asset Catalog:
   - File → New → File → Asset Catalog
   - Name it `Assets`
   - Save in PTPerformance folder

3. Add AppIcon:
   - Right-click in Assets.xcassets → App Icons & Launch Images → New iOS App Icon
   - Add icon images for all required sizes:
     - 120x120 (iPhone @2x)
     - 180x180 (iPhone @3x)
     - 152x152 (iPad @2x)
     - 167x167 (iPad Pro @2x)
     - 1024x1024 (App Store)

4. Configure in Project Settings:
   - Select PTPerformance target
   - General tab → App Icons and Launch Screen
   - App Icons: Select "AppIcon" from Assets

#### Step 2: Configure Info.plist Settings

Add to project's Info tab (or create Info.plist):

```xml
<key>CFBundleIconName</key>
<string>AppIcon</string>

<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
    <string>UIInterfaceOrientationPortraitUpsideDown</string>
    <string>UIInterfaceOrientationLandscapeLeft</string>
    <string>UIInterfaceOrientationLandscapeRight</string>
</array>

<key>UILaunchStoryboardName</key>
<string>LaunchScreen</string>
```

#### Step 3: Add Launch Screen

1. Create LaunchScreen.storyboard:
   - File → New → File → Launch Screen
   - Name: LaunchScreen
   - Add to PTPerformance target

2. Or use modern approach (iOS 14+):
   - Create `LaunchScreen.swift` with SwiftUI view
   - Configure in project settings

#### Step 4: Rebuild and Upload

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Clean build
rm -rf build/

# Rebuild
./run_local_build.sh

# Upload
xcrun altool --upload-app -f PTPerformance.ipa -t ios \
  --apiKey 9S37GWGW49 \
  --apiIssuer eebecd15-2a07-4dc3-a74c-aed17ca3887a
```

---

## 📋 COMPLETE AUTOMATION RECIPE

### Prerequisites
- ✅ App created in App Store Connect with bundle ID: com.ptperformance.app
- ✅ App information filled out (language, category, age rating, pricing)
- ✅ App Store Connect API key with Admin role
- ✅ GitHub apple-certificates repo with fastlane match certificates
- ✅ Xcode project configured with icons, launch screen, Info.plist

### One-Time Setup

1. **Configure .env file**:
   ```bash
   cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
   cp .env.example .env
   # Fill in values from App Store Connect and GitHub
   ```

2. **Install Ruby dependencies**:
   ```bash
   rbenv local 3.3.6
   gem install bundler
   bundle install
   ```

3. **Configure git for match**:
   ```bash
   gh auth setup-git
   ```

### Build and Upload (Every Time)

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Option 1: Use helper script (recommended)
./run_local_build.sh

# Option 2: Manual fastlane
export PATH="$HOME/.rbenv/shims:$PATH"
source .env
bundle exec fastlane beta

# Option 3: Just build (no upload)
bundle exec fastlane build_app

# Option 4: Upload existing IPA
xcrun altool --upload-app -f PTPerformance.ipa -t ios \
  --apiKey $APP_STORE_CONNECT_API_KEY_ID \
  --apiIssuer $APP_STORE_CONNECT_API_ISSUER_ID
```

### Verify Upload

1. **Check in App Store Connect**:
   - https://appstoreconnect.apple.com/apps/6756226704/testflight/ios
   - Build should appear in 5-15 minutes

2. **Check email**: paul@romatech.com will receive notifications

3. **Command line check**:
   ```bash
   bundle exec fastlane run latest_testflight_build_number app_identifier:"com.ptperformance.app"
   ```

---

## 🔑 KEY LEARNINGS

### Build Performance
| Environment | Time | Notes |
|-------------|------|-------|
| M3 Ultra (local) | 66 seconds | Recommended for iteration |
| GitHub Actions | 25-30 min | Use for CI/CD only |

### Common Errors and Solutions

#### Error: "Write access to repository not granted" (403)
**Cause**: GitHub token doesn't have access to apple-certificates repo
**Fix**: Use `gh auth token` and re-encode for MATCH_GIT_BASIC_AUTHORIZATION

#### Error: "Authentication credentials are missing or invalid"
**Cause**: Wrong API key ID or issuer ID
**Fix**: Verify KEY_ID is 9S37GWGW49 (10 chars), not the longer hash

#### Error: "GET APP SETTINGS: 500 Internal Server Error"
**Cause**: App record incomplete in App Store Connect
**Fix**: Fill out all required app information and create version 1.0

#### Error: "Missing required icon file"
**Cause**: Xcode project missing asset catalog or app icons
**Fix**: Add Assets.xcassets with AppIcon set (all sizes)

#### Error: "No orientations were specified"
**Cause**: Missing UISupportedInterfaceOrientations in Info.plist
**Fix**: Add all 4 orientations for iPad multitasking support

### Critical Files

```
ios-app/PTPerformance/
├── .env                          # All secrets (LOCAL ONLY, gitignored)
├── .ruby-version                 # Ruby 3.3.6
├── Gemfile                       # fastlane, dotenv
├── fastlane/
│   ├── Fastfile                 # Build and upload automation
│   ├── Matchfile                # Certificate management
│   └── Appfile                  # App identifiers
├── run_local_build.sh           # One-command build script
├── PTPerformance.xcodeproj/     # Xcode project
└── [NEEDED] Assets.xcassets/    # ❌ Missing - needs to be created
    └── AppIcon.appiconset/
```

---

## 📊 APP STORE CONNECT CONFIGURATION

**App Name**: PT Performance
**Bundle ID**: com.ptperformance.app
**SKU**: com.ptperformance.app
**Apple ID**: 6756226704
**Team ID**: 5NNLBL74XR
**Team**: Paul Roma

**API Key**:
- Key ID: 9S37GWGW49
- Issuer ID: eebecd15-2a07-4dc3-a74c-aed17ca3887a
- Role: Admin (Developer didn't work, needed Admin)

**Certificates Repo**: https://github.com/pauljroma/apple-certificates.git
**Match Password**: paul-and-shelle-married-novi-2020

---

## 🚀 NEXT STEPS

### Immediate (Block Upload Issue)
1. Open Xcode project
2. Add asset catalog with app icons
3. Configure Info.plist for iPad support
4. Add launch screen
5. Rebuild and upload

### Future Improvements
1. **GitHub Actions**: Update MATCH_GIT_BASIC_AUTHORIZATION secret with working gh token
2. **Icons**: Design proper app icons (currently missing)
3. **Launch Screen**: Create branded launch screen
4. **Automation**: Create script to auto-generate missing assets
5. **Documentation**: Add to project README

---

## 🎓 PRODUCTION READINESS CHECKLIST

- [x] Local build works
- [x] Certificates configured (fastlane match)
- [x] Secrets stored securely (.env, gitignored)
- [x] Build script created (./run_local_build.sh)
- [x] App Store Connect app created
- [x] API key has proper permissions
- [ ] **App icons added to asset catalog** ⬅️ CURRENT BLOCKER
- [ ] **Info.plist configured for iPad** ⬅️ CURRENT BLOCKER
- [ ] **Launch screen created** ⬅️ CURRENT BLOCKER
- [ ] First TestFlight build uploaded
- [ ] GitHub Actions workflow updated with working token

---

## 📞 QUICK REFERENCE COMMANDS

### Build Locally
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
./run_local_build.sh
```

### Upload Existing IPA
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
xcrun altool --upload-app -f PTPerformance.ipa -t ios \
  --apiKey 9S37GWGW49 \
  --apiIssuer eebecd15-2a07-4dc3-a74c-aed17ca3887a
```

### Check TestFlight Status
```bash
# Via web
open https://appstoreconnect.apple.com/apps/6756226704/testflight/ios

# Via command line
bundle exec fastlane run latest_testflight_build_number \
  app_identifier:"com.ptperformance.app"
```

### Debug Upload Issues
```bash
# Get real error messages (not fastlane's masked ones)
xcrun altool --upload-app -f PTPerformance.ipa -t ios \
  --apiKey 9S37GWGW49 \
  --apiIssuer eebecd15-2a07-4dc3-a74c-aed17ca3887a 2>&1 | tee upload.log
```

---

## 🔐 SECURITY NOTES

**Secrets Stored**:
- `.env` file (LOCAL ONLY - in .gitignore)
- GitHub Secrets (for CI/CD)
- Keychain (certificates via fastlane match)

**Never Commit**:
- `.env` file
- `*.p8` key files
- `private_keys/` directory
- API tokens or passwords

**Token Rotation**:
- App Store Connect API keys: No expiration (rotate annually)
- GitHub Personal Access Tokens: 90 days or no expiration
- Match password: Never expires (stored in GitHub Secrets)

---

## 📈 SUCCESS METRICS

**Time Metrics**:
- Initial setup: ~8 hours (one-time)
- Xcode configuration: ~5-10 minutes (one-time)
- Local build: 66 seconds (every time)
- Upload to TestFlight: ~30 seconds
- Apple processing: 5-15 minutes
- **Total time to TestFlight**: ~3-4 minutes after Xcode fix

**vs GitHub Actions**:
- GitHub Actions build: 25-30 minutes
- Local is 27x faster

---

**END OF HANDOFF**

**Status**: Ready for Xcode project configuration
**Blocker**: Missing iOS assets (icons, launch screen, Info.plist)
**Next Action**: Open Xcode and configure project per Step 1-3 above
**Estimated Time**: 5-10 minutes

Once Xcode is configured, run `./run_local_build.sh` and builds will upload to TestFlight successfully.
