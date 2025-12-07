# TestFlight Deployment - Linear Issues Breakdown

## Epic: iOS TestFlight Automated Deployment
**Goal**: 100% automated CI/CD pipeline for iOS app deployment to TestFlight

## Issue 1: Root Cause Analysis - Why Automated Builds Fail
**Issue ID**: To be created
**Title**: [ROOT CAUSE] Automatic code signing incompatible with GitHub Actions CI/CD
**Priority**: P0 - Blocker
**Status**: In Progress

### Problem Statement
After 130+ failed build attempts over 14+ hours, the core issue is:
- GitHub Actions cannot use Xcode's "Automatic Code Signing"
- Automatic signing requires an Apple ID logged into Xcode
- CI/CD runners cannot login to Apple ID accounts
- Error: "No Accounts: Add a new account in Accounts settings"

### Root Causes Identified
1. ❌ **Wrong approach**: Using automatic code signing in Xcode project
2. ❌ **Missing infrastructure**: No certificate/provisioning profile management
3. ❌ **Configuration mismatch**: Bundle ID changed multiple times (Romatechv100 → com.ptperformance.app)
4. ✅ **GitHub Actions billing**: Fixed (was blocking for 13 hours)
5. ✅ **API credentials**: Configured correctly

### What Doesn't Work in CI/CD
- `-allowProvisioningUpdates` flag (requires manual Xcode login)
- `CODE_SIGN_STYLE = Automatic` (requires Apple ID account)
- Passing `DEVELOPMENT_TEAM` via xcargs (still needs profiles)

### What Does Work (Industry Standard)
- **Fastlane Match**: Certificate management in encrypted git repo
- **Manual Code Signing**: Xcode uses match-provided profiles
- **App Store Connect API**: No password needed for uploads

---

## Issue 2: Implement Fastlane Match for Certificate Management
**Issue ID**: To be created
**Title**: Set up fastlane match for automated iOS code signing
**Priority**: P0 - Blocker
**Status**: Ready to Start
**Depends on**: Issue 1 (Root Cause)

### Acceptance Criteria
- [ ] Match initialized: `bundle exec fastlane match appstore` run successfully
- [ ] Certificates created in Apple Developer Portal for com.ptperformance.app
- [ ] Provisioning profile created and stored in https://github.com/pauljroma/apple-certificates.git
- [ ] MATCH_PASSWORD saved to GitHub secrets
- [ ] Matchfile configured with correct Bundle ID

### Steps to Complete
1. Install correct bundler version: `gem install bundler:2.7.2`
2. Run match init: `bundle exec fastlane match appstore --readonly false`
3. Enter encryption password when prompted (save to 1Password)
4. Verify certificates in Apple Developer Portal
5. Add MATCH_PASSWORD to GitHub secrets

### Files Modified
- `ios-app/PTPerformance/fastlane/Matchfile` (✅ already updated)
- `ios-app/PTPerformance/fastlane/Fastfile` (✅ already updated)
- GitHub Secrets: MATCH_PASSWORD (⏳ pending)

---

## Issue 3: Configure Xcode Project for Manual Signing
**Issue ID**: To be created
**Title**: Update Xcode project to use manual code signing with match profiles
**Priority**: P0 - Blocker
**Status**: Partially Complete
**Depends on**: Issue 2 (Match Setup)

### Current Status
- ✅ CODE_SIGN_STYLE = Manual (changed from Automatic)
- ✅ PRODUCT_BUNDLE_IDENTIFIER = com.ptperformance.app
- ⏳ DEVELOPMENT_TEAM = 5NNLBL74XR (needs to be set in project)
- ⏳ PROVISIONING_PROFILE_SPECIFIER = "match AppStore com.ptperformance.app"

### Acceptance Criteria
- [ ] Xcode project file has DEVELOPMENT_TEAM set
- [ ] Project references match provisioning profile
- [ ] Build succeeds locally with match certificates
- [ ] No "requires a development team" errors

### Commands to Execute
```bash
# Set development team in Xcode project
cd ios-app/PTPerformance
/usr/libexec/PlistBuddy -c "Set :objects:A6BE1DD65218F79355CC8317:buildSettings:DEVELOPMENT_TEAM 5NNLBL74XR" PTPerformance.xcodeproj/project.pbxproj
```

---

## Issue 4: Test Local Build with Match
**Issue ID**: To be created
**Title**: Verify local iOS build works with fastlane match
**Priority**: P0 - Blocker
**Status**: Ready to Start
**Depends on**: Issue 2, Issue 3

### Acceptance Criteria
- [ ] Local build completes: `bundle exec fastlane beta` succeeds
- [ ] Match downloads certificates from git repo
- [ ] Xcode signs IPA with match profile
- [ ] Upload to TestFlight succeeds
- [ ] Build appears in App Store Connect

### Test Command
```bash
cd ios-app/PTPerformance
export APP_STORE_CONNECT_API_KEY_ID="NKWNDTD3DJ"
export APP_STORE_CONNECT_API_ISSUER_ID="69a6de9d-2840-47e3-e053-5b8c7c11a4d1"
export APP_STORE_CONNECT_API_KEY_CONTENT="<base64-encoded-key>"
export MATCH_PASSWORD="<password-from-issue-2>"
bundle exec fastlane beta
```

---

## Issue 5: Enable Automated GitHub Actions Build
**Issue ID**: To be created
**Title**: Configure GitHub Actions to build and deploy iOS app automatically
**Priority**: P0 - Blocker
**Status**: Ready to Start
**Depends on**: Issue 4 (Local Build Test)

### Current GitHub Actions Configuration
File: `.github/workflows/ios-testflight.yml`

**Environment Variables Configured**:
- ✅ APP_STORE_CONNECT_API_KEY_ID
- ✅ APP_STORE_CONNECT_API_ISSUER_ID
- ✅ APP_STORE_CONNECT_API_KEY_CONTENT
- ✅ FASTLANE_TEAM_ID
- ✅ MATCH_GIT_BASIC_AUTHORIZATION
- ⏳ MATCH_PASSWORD (needs to be added)

### Acceptance Criteria
- [ ] MATCH_PASSWORD added to GitHub secrets
- [ ] Push to main triggers build
- [ ] Build downloads match certificates
- [ ] Archive succeeds with manual signing
- [ ] Upload to TestFlight succeeds
- [ ] No manual intervention required

### Success Criteria
Build logs show:
```
[fastlane] 🔓 Successfully decrypted certificates
[fastlane] 📦 Installing provisioning profile
[fastlane] ▸ ** ARCHIVE SUCCEEDED **
[fastlane] 📤 Uploading to TestFlight...
[fastlane] ✅ Successfully uploaded package
```

---

## Issue 6: Document the Working Pipeline
**Issue ID**: To be created
**Title**: Create runbook for iOS TestFlight deployment pipeline
**Priority**: P1 - High
**Status**: Ready to Start
**Depends on**: Issue 5 (Automated Build)

### Deliverables
- [ ] RUNBOOK.md with step-by-step deployment process
- [ ] Troubleshooting guide for common issues
- [ ] How to rotate certificates when they expire
- [ ] How to add new devices for testing
- [ ] Emergency rollback procedure

---

## Issue 7: Clean Up Linear Bootstrap Folder
**Issue ID**: To be created
**Title**: Archive deprecated Linear helper scripts and organize workspace
**Priority**: P2 - Medium
**Status**: Todo

### Problem
Multiple duplicate .env files and deprecated Python scripts scattered throughout:
- `/Users/expo/Code/expo/clients/linear-bootstrap/.env`
- `/Users/expo/Code/expo/clients/linear-bootstrap/agent-service/.env`
- 15+ deprecated `*_linear_*.py` scripts from old agents

### Tasks
- [ ] Create `.archive/linear-helpers-deprecated/` folder
- [ ] Move all deprecated `*_linear_*.py` scripts to archive
- [ ] Keep only: `linear_client.py`, `linear_bootstrap.py`, `create_testflight_issues.py`
- [ ] Consolidate .env files (keep root .env only)
- [ ] Update .gitignore to prevent future .env duplication
- [ ] Document which scripts are active vs deprecated

### Files to Archive
```
agent1_linear_updates.py
agent2_linear_update.py
agent2_update_linear.py
agent3_linear_helper.py
agent3_phase2_linear_update.py
agent3_update_linear.py
check_linear_status.py
complete_mvp_in_linear.py
phase3_linear_update.py
update_deployment_linear.py
update_linear_cli_instructions.py
update_linear_deployment_status.py
(and others)
```

---

## Timeline & Dependencies

```
Issue 1 (Root Cause) → ✅ DONE
    ↓
Issue 2 (Match Setup) → ⏳ IN PROGRESS (blocked by bundler version)
    ↓
Issue 3 (Xcode Config) → Ready
    ↓
Issue 4 (Local Test) → Ready
    ↓
Issue 5 (CI/CD) → Ready
    ↓
Issue 6 (Documentation) → Ready
```

## Estimated Time to Complete
- Issue 2: 15 minutes (match initialization)
- Issue 3: 5 minutes (set DEVELOPMENT_TEAM)
- Issue 4: 10 minutes (local build test)
- Issue 5: 5 minutes (add MATCH_PASSWORD to GitHub)
- Issue 6: 30 minutes (write documentation)

**Total**: ~1 hour to fully automated pipeline

## Critical Blockers Right Now
1. **Bundler version mismatch**: Need to install bundler 2.7.2
2. **Match not initialized**: Need to run `fastlane match appstore`
3. **MATCH_PASSWORD missing**: Need to add to GitHub secrets

## Success Metrics
- ✅ 100% automated builds (no manual steps)
- ✅ Build time < 10 minutes
- ✅ Every push to main deploys to TestFlight
- ✅ Zero failed builds due to signing issues
