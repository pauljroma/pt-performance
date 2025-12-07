# TestFlight Deployment - Next Steps

**Status**: Configuration Complete ✅ | Awaiting Manual Steps ⏳

## What We Just Completed

✅ All 6 TestFlight issues (ACP-107 to ACP-112) completed
✅ Xcode project switched to Manual code signing
✅ GitHub Actions workflow updated with MATCH environment variables
✅ Comprehensive runbook created (`ios-app/TESTFLIGHT_RUNBOOK.md`)
✅ Workspace cleaned up (46 deprecated scripts archived)
✅ Changes committed and pushed (commit `5a243bf`)

## Why There's No Build in TestFlight Yet

There are **3 required manual steps** that must be completed before a build can succeed:

### Issue 1: Missing GitHub Secrets (Critical)

The workflow needs these secrets that aren't set yet:
- ❌ `MATCH_PASSWORD` - Not set (needed by fastlane match)
- ❌ `MATCH_GIT_BASIC_AUTHORIZATION` - Not set (needed to access certificates repo)

### Issue 2: Certificates Not Created Yet

Fastlane match needs to be run **once locally** to:
- Create distribution certificate in Apple Developer Portal
- Create App Store provisioning profile
- Encrypt and push to https://github.com/pauljroma/apple-certificates.git

### Issue 3: Previous Build Error

The last build (before our changes) failed with:
```
[07:59:16]: string contains null byte
💥 app_store_connect_api_key
```

This suggests the `APP_STORE_CONNECT_API_KEY_CONTENT` secret might have encoding issues (extra newlines/null bytes in the base64).

## Required Actions (In Order)

### Step 1: Run Fastlane Match Locally (One-Time Setup)

**Prerequisites**:
- Mac with Xcode installed
- Access to Apple Developer account (Team ID: 5NNLBL74XR)
- Write access to https://github.com/pauljroma/apple-certificates.git

**Commands**:
```bash
cd ios-app/PTPerformance
bundle install
bundle exec fastlane match appstore --readonly false
```

**What This Does**:
1. Prompts for encryption password (save this!)
2. Creates distribution certificate in Apple Developer Portal
3. Creates App Store provisioning profile for `com.ptperformance.app`
4. Encrypts and pushes to certificates repo

**Expected Output**:
```
[fastlane] Successfully created certificate
[fastlane] Successfully created provisioning profile
[fastlane] All required keys, certificates and provisioning profiles are installed
```

### Step 2: Add GitHub Secrets

After Step 1 completes, add these secrets:

```bash
# MATCH_PASSWORD (from Step 1 prompt)
gh secret set MATCH_PASSWORD --repo pauljroma/pt-performance
# Enter the password you created in Step 1

# MATCH_GIT_BASIC_AUTHORIZATION
# First create GitHub Personal Access Token with 'repo' scope
# Then encode: echo -n "username:ghp_xxxxx" | base64
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --repo pauljroma/pt-performance
# Paste the base64 encoded credentials
```

### Step 3: Fix APP_STORE_CONNECT_API_KEY_CONTENT Secret (If Needed)

If the build still fails with "string contains null byte":

```bash
# Re-encode the .p8 file cleanly
base64 -i /path/to/AuthKey_NKWNDTD3DJ.p8 | tr -d '\n' | pbcopy

# Update the secret
gh secret set APP_STORE_CONNECT_API_KEY_CONTENT --repo pauljroma/pt-performance
# Paste from clipboard
```

The `tr -d '\n'` removes all newlines which can cause the null byte error.

### Step 4: Trigger a Build

**Option 1: Push to main**
```bash
# Make any small change
touch ios-app/.trigger-build
git add ios-app/.trigger-build
git commit -m "chore: trigger TestFlight build"
git push origin main
```

**Option 2: Manual workflow dispatch**
```bash
gh workflow run "Deploy to TestFlight"
```

**Option 3: Via GitHub UI**
1. Go to https://github.com/pauljroma/pt-performance/actions
2. Select "Deploy to TestFlight" workflow
3. Click "Run workflow" → Select "main" branch → Run

### Step 5: Monitor the Build

```bash
# Watch the workflow run
gh run watch

# Or check status
gh run list --workflow="Deploy to TestFlight" --limit 5
```

**Success looks like**:
```
✅ completed success feat(testflight): Complete TestFlight deployment... Deploy to TestFlight main push ...
```

**Check logs if it fails**:
```bash
# Get the run ID from the list above
gh run view <run-id> --log
```

## Expected Timeline

| Step | Duration | Who |
|------|----------|-----|
| 1. Run fastlane match | 5-10 min | Developer with Apple Developer access |
| 2. Add GitHub secrets | 2-3 min | Repo admin |
| 3. Fix API key secret | 1-2 min | Repo admin (if needed) |
| 4. Trigger build | 1 min | Anyone with write access |
| 5. Build completes | 5-7 min | Automated |
| 6. TestFlight processing | 10-15 min | Apple servers |
| **Total** | **~30 min** | |

## Verification

### Successful Build Indicators

**In GitHub Actions**:
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

**In App Store Connect**:
1. Go to https://appstoreconnect.apple.com/apps
2. Select PTPerformance
3. Navigate to TestFlight tab
4. Should see new build (Processing... → Ready to Test)

**In TestFlight App**:
- Build appears after ~10-15 min processing
- Can install on test devices
- Can add internal/external testers

## Troubleshooting Quick Reference

| Error | Fix |
|-------|-----|
| "No matching provisioning profiles" | Run `fastlane match appstore --readonly false` locally |
| "Could not clone certificates repo" | Check MATCH_GIT_BASIC_AUTHORIZATION secret |
| "Unauthorized access" | Verify MATCH_PASSWORD secret is correct |
| "string contains null byte" | Re-encode API key: `base64 -i key.p8 \| tr -d '\n'` |
| "Team ID mismatch" | Verify DEVELOPMENT_TEAM = FASTLANE_TEAM_ID = 5NNLBL74XR |

## Documentation Reference

- Full runbook: `ios-app/TESTFLIGHT_RUNBOOK.md`
- Fastlane docs: https://docs.fastlane.tools/actions/match/
- Workflow file: `.github/workflows/ios-testflight.yml`
- Matchfile: `ios-app/PTPerformance/fastlane/Matchfile`

## Current Status Summary

| Component | Status | Notes |
|-----------|--------|-------|
| Xcode Project | ✅ Ready | Manual signing configured |
| Fastfile | ✅ Ready | Uses fastlane match |
| Matchfile | ✅ Ready | Configured for appstore |
| GitHub Workflow | ✅ Ready | MATCH env vars added |
| Documentation | ✅ Complete | Runbook created |
| Certificates | ❌ Not Created | Need to run match locally |
| GitHub Secrets (MATCH) | ❌ Not Set | Need MATCH_PASSWORD + AUTH |
| GitHub Secret (API Key) | ⚠️ May Need Fix | Possible encoding issue |

## Next Session Checklist

When you have access to the required credentials:

- [ ] Run `bundle exec fastlane match appstore --readonly false`
- [ ] Save the encryption password securely (1Password)
- [ ] Add MATCH_PASSWORD to GitHub secrets
- [ ] Create GitHub token and add MATCH_GIT_BASIC_AUTHORIZATION
- [ ] (If needed) Fix APP_STORE_CONNECT_API_KEY_CONTENT encoding
- [ ] Trigger a workflow run
- [ ] Watch the build succeed
- [ ] Verify build appears in TestFlight
- [ ] Install and test the build

## Success Criteria

🎯 **Goal**: First successful automated TestFlight deployment

**We'll know we're done when**:
- ✅ GitHub Actions workflow completes successfully
- ✅ Build appears in App Store Connect TestFlight
- ✅ Build status changes from "Processing" to "Ready to Test"
- ✅ Can install build on a test device via TestFlight app

---

**Last Updated**: December 7, 2025
**Configuration Commit**: 5a243bf
**Status**: Ready for manual certificate setup
