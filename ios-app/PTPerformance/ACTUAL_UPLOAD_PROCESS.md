# ACTUAL iOS BUILD & UPLOAD PROCESS
## THE METHOD THAT ACTUALLY WORKS (Used for all 13 builds)

### ⚠️ CRITICAL: This is the ONLY method that works

**DO NOT use Xcode Organizer GUI**
**DO NOT use command-line altool/iTMSTransporter**
**DO NOT try to "improve" this process**

### THE WORKING COMMAND (One Line)

```bash
./run_local_build.sh
```

**That's it. This handles everything automatically.**

---

## What This Script Does

1. ✅ Loads credentials from `.env` file
2. ✅ Increments build number automatically
3. ✅ Downloads provisioning profile via `match`
4. ✅ Builds archive with proper signing
5. ✅ Exports signed .ipa file
6. ✅ Uploads to TestFlight via App Store Connect API
7. ✅ Completes in ~80 seconds total

---

## Complete Process (If Starting Fresh)

### Prerequisites (One-Time Setup)

```bash
# 1. Ensure .env file exists with credentials
ls -la .env

bundle install

# 3. That's it!
```

### Build and Upload (Every Time)

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
./run_local_build.sh
```

**Output you'll see:**
```
🚀 Starting Local iOS Build
✓ Found .env file
📦 Loading environment variables...
✓ APP_STORE_CONNECT_API_KEY_ID is set
✓ APP_STORE_CONNECT_API_ISSUER_ID is set
... (more checks)
🏗️  Building iOS App...
... (build logs)
Successfully uploaded package to App Store Connect
✅ Build Complete!
```

**Total time:** ~2-3 minutes (build) + ~25 seconds (upload) = **~3 minutes total**

---

## Credentials (Stored in .env)

The `.env` file contains:
```bash
APP_STORE_CONNECT_API_KEY_ID="your-key-id"
APP_STORE_CONNECT_API_ISSUER_ID="your-issuer-id"
APP_STORE_CONNECT_API_KEY_CONTENT="base64-encoded-key"
TEAM_ID="P4Q5K8UWQ7"
MATCH_PASSWORD="your-match-password"
MATCH_GIT_BASIC_AUTHORIZATION="your-github-token"
```

**Location:** `/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/.env`

**Security:** File is `.gitignore`'d and has 600 permissions

---

## What Happens Behind the Scenes

### Step 1: Increment Build Number
```ruby
increment_build_number(
  build_number: 13,  # Auto-increments
  xcodeproj: "PTPerformance.xcodeproj"
)
```

### Step 2: Get Provisioning Profile
```ruby
match(
  type: "appstore",
  api_key: api_key,
  readonly: false,
  app_identifier: "com.ptperformance.app"
)
```

### Step 3: Build Archive
```ruby
build_app(
  scheme: "PTPerformance",
  export_method: "app-store",
  export_options: {
    method: "app-store",
    provisioningProfiles: {
      "com.ptperformance.app" => "match AppStore com.ptperformance.app"
    }
  }
)
```

### Step 4: Upload to TestFlight
```ruby
upload_to_testflight(
  api_key: api_key,
  skip_waiting_for_build_processing: true,
  distribute_external: false
)
```

---

## Verification

### Check Upload Success

```bash
# Method 1: Check App Store Connect
open https://appstoreconnect.apple.com
# Go to: My Apps → PTPerformance → TestFlight
# Build should appear in ~5 minutes

# Method 2: Check xcodebuild export output
# Look for: EXPORT SUCCEEDED
```

### Test on iPad

1. Install TestFlight app on iPad
2. Open TestFlight
3. Find "PTPerformance"
4. Install Build 13
5. Test all features:
   - Login (therapist and patient)
   - Patient list
   - Patient detail (all 4 sections)
   - Add notes
   - View programs

---

## Troubleshooting

### Error: "Missing .env file"
```bash
# Solution: Create .env from template
cp .env.example .env
# Edit .env with actual credentials
```

### Error: "bundle command not found"
```bash
# Solution: Check Xcode command line tools
xcode-select --install
bundle install
```

### Error: "Provisioning profile doesn't include signing certificate"
```bash
# Solution: Re-run match
# Re-download profiles via Xcode: Preferences > Accounts > Download Manual Profiles
```

### Error: "Authentication failed"
```bash
# Solution: Regenerate API key
# 1. Go to appstoreconnect.apple.com/access/api
# 2. Revoke old key
# 3. Create new key
# 4. Download .p8 file
# 5. Update .env with new credentials
```

---

## Build History

| Build | Date | Status | Method |
|-------|------|--------|--------|
| 1-12 | Various | ✅ Success | `./run_local_build.sh` |
| 13 | 2025-12-11 | ✅ Success | `./run_local_build.sh` |

**Success rate:** 13/13 = 100%

---

## Why Other Methods Don't Work

### ❌ Xcode Organizer GUI
- Requires manual interaction
- Not automatable
- User has never used this method

### ❌ xcrun altool
- Authentication errors (CryptoKit.CryptoKitError)
- API key format issues
- Deprecated tooling

### ❌ xcrun iTMSTransporter
- Completely deprecated
- Requires Mac App Store Transporter app
- Not command-line friendly

### ✅ ./run_local_build.sh
- **Works every single time**
- Handles all complexity automatically
- Loads credentials correctly
- Proper error handling
- Fast (3 minutes total)

---

## Quick Reference Card

```bash
# STANDARD BUILD & UPLOAD PROCESS
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
./run_local_build.sh

# Wait 3 minutes
# Check App Store Connect in 5 minutes
# Test on iPad

# DONE!
```

---

## Files Reference

```
.env                              - Credentials (DO NOT COMMIT)
run_local_build.sh               - THE SCRIPT TO USE
PTPerformance.ipa                - Output IPA file
build/PTPerformance.xcarchive    - Output archive
PTPerformance.app.dSYM.zip       - Debug symbols
```

---

## Environment Variables Explained

| Variable | Purpose | Example |
|----------|---------|---------|
| `APP_STORE_CONNECT_API_KEY_ID` | API key identifier | `415c860b88184388b6e889bfd87bb440` |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Your team's issuer ID | `69a6de97-ec29-47e3-e053-5b8c7c11a4d1` |
| `APP_STORE_CONNECT_API_KEY_CONTENT` | Base64-encoded .p8 file | `LS0tLS...` |
| `TEAM_ID` | Apple Developer Team ID | `P4Q5K8UWQ7` |
| `MATCH_PASSWORD` | Encryption password for match | (secret) |
| `MATCH_GIT_BASIC_AUTHORIZATION` | GitHub token for match repo | `base64(username:token)` |

---

## THIS IS THE PROCESS - NEVER FORGET

**One command:** `./run_local_build.sh`

**Success rate:** 100%

**Time:** 3 minutes

**DO NOT** try to use Xcode Organizer or other methods.

**This script is THE WAY.**
