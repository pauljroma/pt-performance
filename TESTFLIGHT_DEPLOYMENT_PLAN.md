# TestFlight 100% Automated Deployment Plan

## Current Status
- ✅ GitHub Actions billing: FIXED
- ✅ App Store Connect API key: Configured (NKWNDTD3DJ)
- ✅ Bundle ID: com.ptperformance.app
- ✅ Fastfile updated: Using App Store Connect API
- ⏳ **CURRENT BLOCKER**: Automatic code signing fails in CI/CD without Apple ID login

## The Problem
GitHub Actions cannot use automatic code signing because:
1. No Apple ID can be logged into the CI/CD runner
2. `-allowProvisioningUpdates` only works with manual Xcode login
3. Every build fails with "No Accounts: Add a new account in Accounts settings"

## The Solution: Fastlane Match

Fastlane match is the industry-standard solution used by thousands of teams for automated iOS CI/CD.

### How Match Works
1. **Certificates stored in git repo**: Encrypted certificates/profiles in private repo
2. **Match downloads on build**: CI downloads and installs certificates automatically
3. **Manual code signing**: Xcode uses match-provided profiles (no Apple ID needed)

### Steps to Implement

#### Step 1: Initialize Match (Run ONCE locally)
```bash
cd ios-app/PTPerformance
bundle exec fastlane match appstore --readonly false
```

This will:
- Create certificates in Apple Developer Portal
- Generate App Store provisioning profile for com.ptperformance.app
- Encrypt and push to https://github.com/pauljroma/apple-certificates.git
- Prompt for encryption password (save in 1Password)

#### Step 2: Update GitHub Secrets
Add match encryption password:
```bash
gh secret set MATCH_PASSWORD --repo pauljroma/pt-performance
# Enter the password from Step 1
```

#### Step 3: Verify Xcode Project Settings
- CODE_SIGN_STYLE: Manual (✅ DONE)
- PRODUCT_BUNDLE_IDENTIFIER: com.ptperformance.app (✅ DONE)
- DEVELOPMENT_TEAM: 5NNLBL74XR (needs to be set)

#### Step 4: Update Fastfile (✅ DONE)
Already configured to use match in commit d551f6f

#### Step 5: Test Build
Push to main → GitHub Actions runs → Match downloads certs → Build succeeds → Upload to TestFlight

## Current Fastfile Configuration

```ruby
# Get certificates with match
match(
  type: "appstore",
  api_key: api_key,
  readonly: false,
  app_identifier: "com.ptperformance.app"
)

# Build with match signing
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

## Next Steps

1. ✅ Matchfile configured (d551f6f)
2. ✅ Fastfile uses match (d551f6f)
3. ✅ Xcode set to manual signing (d551f6f)
4. ⏳ **RUN MATCH INIT**: `bundle exec fastlane match appstore`
5. ⏳ Add MATCH_PASSWORD to GitHub secrets
6. ⏳ Test automated build

## Expected Outcome

After match is initialized:
- CI builds will download certificates from private repo
- Xcode signs with match-provided profiles
- IPA uploaded to TestFlight automatically
- **100% automated** - no manual steps needed

## Verification

Build succeeds when logs show:
```
[fastlane] Successfully installed provisioning profile
[fastlane] Building...
[fastlane] ** ARCHIVE SUCCEEDED **
[fastlane] Uploading to TestFlight...
[fastlane] ✅ Upload successful
```
