# TestFlight Deployment Guide

## Current Status

Your FastLane setup is **partially complete**. We've created multiple deployment lanes to handle different signing scenarios.

## The API Key Issue

Your App Store Connect API key (`415c860b88184388b6e889bfd87bb440`) **does not have sufficient permissions** to create or manage certificates. This is why Match and cert/sigh fail with authentication errors.

### To Fix the API Key:

1. Go to: https://appstoreconnect.apple.com/access/api
2. Find your API key with ID: `415c860b88184388b6e889bfd87bb440`
3. Check its "Access" level:
   - If it shows "Developer" or "Customer Support": **This is the problem**
   - It needs to be "Admin" or "App Manager" to create certificates

4. **To fix**: Revoke the current key and create a new one with "Admin" or "App Manager" access
5. Update GitHub secrets with the new key

## Available Fastlane Lanes

We've created 4 different lanes to handle various signing scenarios:

### 1. `beta` (Original - Uses Match)
```bash
bundle exec fastlane beta
```
- **Status**: ❌ Fails due to API key permissions
- **Requires**: API key with Admin/App Manager access
- **Use when**: API key is fixed and you want automated certificate management

### 2. `beta_manual` (Manual Certificates)
```bash
bundle exec fastlane beta_manual
```
- **Status**: ⚠️ Ready but requires manual certificate setup
- **Requires**: You to create and install certificates manually
- **Steps**:
  1. Create Apple Distribution certificate at: https://developer.apple.com/account/resources/certificates/add
  2. Create App Store provisioning profile at: https://developer.apple.com/account/resources/profiles/add
  3. Install both on this Mac
  4. Run this lane

### 3. `beta_auto` (Xcode Automatic Signing)
```bash
bundle exec fastlane beta_auto
```
- **Status**: ⚠️ Fails due to old Xcode project format
- **Requires**: Opening project in Xcode to upgrade project file
- **Use when**: You want Xcode to handle all signing automatically

### 4. `beta_simple` (Simplest - Currently Testing)
```bash
bundle exec fastlane beta_simple
```
- **Status**: ✅ Currently running!
- **Requires**: Nothing special - uses project's existing config
- **Flags**: `-allowProvisioningUpdates` lets Xcode auto-create profiles

## Recommended Workflow

**For local testing (right now):**
- Use `beta_simple` - it should work with minimal setup

**For CI/CD (GitHub Actions):**
Option A - Fix API key and use Match:
1. Create new API key with Admin/App Manager access
2. Update GitHub secrets
3. Use `beta` lane
4. Match will handle all certificates automatically

Option B - Manual certificates:
1. Create certificates manually
2. Export them and add to Match repository
3. Use `beta_manual` lane
4. Add MATCH_PASSWORD to GitHub secrets

## GitHub Secrets Status

All secrets are configured:
- ✅ APP_STORE_CONNECT_API_KEY_ID
- ✅ APP_STORE_CONNECT_API_ISSUER_ID
- ✅ APP_STORE_CONNECT_API_KEY_CONTENT
- ✅ APPLE_ID
- ✅ FASTLANE_TEAM_ID
- ✅ FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD
- ⚠️ MATCH_PASSWORD (not yet added - needed for Match to work in CI)

## Next Steps

1. **Immediate**: Wait for `beta_simple` build to complete and see if it succeeds
2. **If it succeeds**: You can deploy to TestFlight locally with `beta_simple`
3. **For CI/CD**: Choose between Option A (fix API key) or Option B (manual certs)
4. **Update GitHub Actions workflow** to use the chosen lane:
   ```yaml
   - name: Deploy to TestFlight
     run: |
       cd ios-app/PTPerformance
       bundle exec fastlane beta_simple  # or beta_auto, beta_manual, etc.
   ```

## Key Files

- **Fastfile**: `/ios-app/PTPerformance/fastlane/Fastfile` - All lane definitions
- **Matchfile**: `/ios-app/PTPerformance/fastlane/Matchfile` - Match configuration
- **GitHub Workflow**: `/.github/workflows/ios-testflight.yml` - CI/CD pipeline
- **Match Repository**: https://github.com/pauljroma/apple-certificates (private)
- **Match Passphrase**: `paul-and-shelle-married-novi-2020`

## Testing Locally

To test any lane locally:
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Set up environment
eval "$(rbenv init - zsh)"
export APP_STORE_CONNECT_API_KEY_ID="415c860b88184388b6e889bfd87bb440"
export APP_STORE_CONNECT_API_ISSUER_ID="eebecd15-2a07-4dc3-a74c-aed17ca3887a"
export APP_STORE_CONNECT_API_KEY_CONTENT="LS0tLS1CRUdJTiBQUklWQVRFIEtFWS0tLS0t..."  # Full base64 key
export FASTLANE_TEAM_ID="5NNLBL74XR"
export MATCH_PASSWORD="paul-and-shelle-married-novi-2020"  # Only needed for Match

# Run lane
bundle exec fastlane <lane_name>
```

## Common Issues

### "Authentication credentials are missing or invalid"
- **Cause**: API key lacks permissions to create/manage certificates
- **Fix**: Use `beta_simple` (no cert creation) or fix API key permissions

### "Seems to be a very old project file format"
- **Cause**: Xcode project needs upgrading
- **Fix**: Open `PTPerformance.xcodeproj` in Xcode 15.2 and let it upgrade

### "No signing identity found"
- **Cause**: No Apple Distribution certificate installed
- **Fix**: Create one manually at developer.apple.com or use `beta_simple` with `-allowProvisioningUpdates`

## Support

If you encounter issues, check:
1. Fastlane logs (shown during execution)
2. GitHub Actions logs (for CI/CD issues)
3. App Store Connect (for API key status)
4. This Mac's Keychain Access (for installed certificates)
