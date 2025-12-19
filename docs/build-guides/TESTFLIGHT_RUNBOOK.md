# TestFlight Deployment Runbook

## Overview

This runbook documents the complete process for deploying the PTPerformance iOS app to TestFlight using a fully automated CI/CD pipeline with fastlane match.

## Architecture

- **Code Signing**: Manual signing with fastlane match
- **Certificate Storage**: Private git repository (encrypted)
- **CI/CD**: GitHub Actions on macos-14 runners
- **Upload Method**: App Store Connect API

## Prerequisites

### 1. Apple Developer Account
- Team ID: `5NNLBL74XR`
- Bundle ID: `com.ptperformance.app`
- App Store Connect access

### 2. App Store Connect API Key
- Key ID: `NKWNDTD3DJ`
- Issuer ID: `69a6de9d-2840-47e3-e053-5b8c7c11a4d1`
- API Key (.p8 file) stored in GitHub Secrets as base64

### 3. Certificates Repository
- Repo: https://github.com/pauljroma/apple-certificates.git
- Purpose: Stores encrypted certificates and provisioning profiles
- Access: Match downloads these during build

## Initial Setup (One-Time)

### Step 1: Initialize Fastlane Match

Run this **once** from a Mac with Xcode:

```bash
cd ios-app/PTPerformance
bundle install
bundle exec fastlane match appstore --readonly false
```

This will:
1. Prompt for encryption password (save in 1Password)
2. Create distribution certificate in Apple Developer Portal
3. Create App Store provisioning profile for com.ptperformance.app
4. Encrypt and push to certificates repo

### Step 2: Configure GitHub Secrets

Add these secrets to the repository:

```bash
# 1. App Store Connect API Key (already configured)
gh secret set APP_STORE_CONNECT_API_KEY_ID --repo pauljroma/linear-bootstrap
# Enter: NKWNDTD3DJ

gh secret set APP_STORE_CONNECT_API_ISSUER_ID --repo pauljroma/linear-bootstrap
# Enter: 69a6de9d-2840-47e3-e053-5b8c7c11a4d1

gh secret set APP_STORE_CONNECT_API_KEY_CONTENT --repo pauljroma/linear-bootstrap
# Enter: <base64 encoded .p8 file>

gh secret set FASTLANE_TEAM_ID --repo pauljroma/linear-bootstrap
# Enter: 5NNLBL74XR

# 2. Fastlane Match Secrets (need to be added)
gh secret set MATCH_PASSWORD --repo pauljroma/linear-bootstrap
# Enter: <password from Step 1>

# 3. Git access for certificates repo
# Create GitHub personal access token with 'repo' scope
# Then encode as: echo -n "username:ghp_xxxxx" | base64
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --repo pauljroma/linear-bootstrap
# Enter: <base64 encoded credentials>
```

### Step 3: Verify Xcode Project Settings

These are already configured in PTPerformance.xcodeproj:

- ✅ `CODE_SIGN_STYLE = Manual`
- ✅ `CODE_SIGN_IDENTITY = Apple Distribution`
- ✅ `DEVELOPMENT_TEAM = 5NNLBL74XR`
- ✅ `PROVISIONING_PROFILE_SPECIFIER = match AppStore com.ptperformance.app`
- ✅ `PRODUCT_BUNDLE_IDENTIFIER = com.ptperformance.app`

## Automated Deployment

### Trigger Deployment

**Option 1: Push to main/master**
```bash
git push origin main
```
Automatically triggers when changes are in `ios-app/**` directory.

**Option 2: Manual Trigger**
```bash
gh workflow run "Deploy to TestFlight" --repo pauljroma/linear-bootstrap
```

### Build Process

1. **Checkout**: Code checked out from repo
2. **Xcode Selection**: Xcode 15.2 selected
3. **Ruby Setup**: Ruby 3.3 + bundler installed
4. **Dependencies**: Fastlane gems installed
5. **Match**: Downloads certificates from private repo
6. **Build**: Xcode builds and signs with match profile
7. **Upload**: IPA uploaded to App Store Connect
8. **TestFlight**: Build appears in TestFlight (processing takes 10-15 min)

### Expected Logs

Successful build shows:
```
[fastlane] 🔓 Successfully decrypted certificates
[fastlane] 📦 Installing provisioning profile
[fastlane] 🔨 Building PTPerformance...
[fastlane] ▸ Code Signing Identity: Apple Distribution
[fastlane] ▸ Provisioning Profile: match AppStore com.ptperformance.app
[fastlane] ** ARCHIVE SUCCEEDED **
[fastlane] 📤 Uploading to TestFlight...
[fastlane] ✅ Build uploaded successfully
```

## Troubleshooting

### Build Fails: "No matching provisioning profiles found"

**Cause**: Match certificates not in repo or MATCH_PASSWORD incorrect

**Fix**:
```bash
# Re-run match init locally
cd ios-app/PTPerformance
bundle exec fastlane match appstore --readonly false --force

# Update GitHub secret with correct password
gh secret set MATCH_PASSWORD --repo pauljroma/linear-bootstrap
```

### Build Fails: "Could not clone certificates repo"

**Cause**: MATCH_GIT_BASIC_AUTHORIZATION missing or incorrect

**Fix**:
```bash
# Create new GitHub token with 'repo' scope
# Encode: echo -n "username:ghp_xxxxx" | base64
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --repo pauljroma/linear-bootstrap
```

### Build Fails: "Team ID mismatch"

**Cause**: DEVELOPMENT_TEAM doesn't match FASTLANE_TEAM_ID

**Fix**: Verify both are set to `5NNLBL74XR`

### Upload Fails: "Invalid credentials"

**Cause**: App Store Connect API key incorrect or expired

**Fix**:
1. Download new .p8 key from App Store Connect
2. Base64 encode: `base64 -i AuthKey_XXX.p8 | pbcopy`
3. Update secret: `gh secret set APP_STORE_CONNECT_API_KEY_CONTENT`

### Build Succeeds but TestFlight Processing Fails

**Cause**: Missing compliance info or export options

**Fix**: Check App Store Connect for specific error message

## Certificate Rotation

Certificates expire after 1 year. To renew:

```bash
cd ios-app/PTPerformance

# Revoke old certificates
bundle exec fastlane match nuke distribution

# Create new certificates
bundle exec fastlane match appstore --readonly false
```

This will automatically update the certificates repo. No CI/CD changes needed.

## Emergency Rollback

If a build needs to be removed from TestFlight:

1. Go to App Store Connect
2. Select PTPerformance app
3. Navigate to TestFlight
4. Select the build
5. Click "Expire Build"

Previous build will become active again automatically.

## Testing the Pipeline

### Local Test
```bash
cd ios-app/PTPerformance
bundle exec fastlane beta
```

Should build and upload just like CI.

### CI Test
```bash
# Trigger workflow
gh workflow run "Deploy to TestFlight"

# Watch logs
gh run watch

# Check status
gh run list --workflow="Deploy to TestFlight"
```

## Monitoring

### Build Status
- GitHub Actions: https://github.com/pauljroma/linear-bootstrap/actions
- Filter: "Deploy to TestFlight" workflow

### TestFlight Status
- App Store Connect: https://appstoreconnect.apple.com/apps
- Navigate to: PTPerformance → TestFlight

### Build Artifacts
- Failed builds upload logs to GitHub Actions artifacts
- Successful builds upload IPA (retained 30 days)

## Security Notes

### Secrets Storage
- All secrets stored in GitHub Secrets (encrypted at rest)
- Secrets never appear in logs
- Match password required for certificate decryption

### Access Control
- Only team members with repo write access can trigger builds
- App Store Connect API key scoped to TestFlight upload only
- Certificates repo private and encrypted

### Audit Trail
- All deployments logged in GitHub Actions
- TestFlight shows upload history
- Match repo has git history of certificate changes

## Maintenance Schedule

- **Monthly**: Verify GitHub secrets still valid
- **Quarterly**: Review TestFlight feedback
- **Annually**: Rotate certificates before expiration
- **As Needed**: Update Xcode version in workflow

## Support Contacts

- Apple Developer Support: https://developer.apple.com/support/
- Fastlane Docs: https://docs.fastlane.tools/
- GitHub Actions Support: https://github.com/support

## Appendix: File Locations

- Workflow: `.github/workflows/ios-testflight.yml`
- Fastfile: `ios-app/PTPerformance/fastlane/Fastfile`
- Matchfile: `ios-app/PTPerformance/fastlane/Matchfile`
- Xcode Project: `ios-app/PTPerformance/PTPerformance.xcodeproj`
- Certificates Repo: https://github.com/pauljroma/apple-certificates.git

## Appendix: Common Commands

```bash
# Check fastlane version
bundle exec fastlane --version

# List available lanes
bundle exec fastlane lanes

# Validate Matchfile
bundle exec fastlane match appstore --readonly true

# Check certificates status
security find-identity -v -p codesigning

# Clean Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData

# View GitHub secrets (names only)
gh secret list
```
