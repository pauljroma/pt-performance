# BUILD & DEPLOYMENT RUNBOOK

## When to Use This Runbook

**Trigger Keywords:** "create build", "upload to TestFlight", "new build number", "deploy iOS"

**Rule:** When build/deployment is mentioned → Read this FIRST, execute mechanically.

---

## Build Process Overview

**Standard Build Flow:**
1. Verify all migrations applied
2. Increment build number
3. Build IPA via Xcode/fastlane
4. Upload to TestFlight
5. Update Linear issue
6. Document in outcomes

**Time:** ~5-10 minutes total

---

## Step 1: Pre-Build Verification

### 1a. Check for pending migrations

```bash
# List migration files
ls -lt supabase/migrations/*.sql | grep -v ".applied"

# If any files found WITHOUT .applied suffix → Apply them first
# Use MIGRATION_RUNBOOK.md to apply
```

**Rule:** Never create a build with unapplied migrations (causes runtime errors)

### 1b. Verify current build number

```bash
# Check Xcode project
grep CURRENT_PROJECT_VERSION ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj | head -1

# Check Config.swift
grep 'buildNumber = ' ios-app/PTPerformance/Config.swift
```

**Current:** Build 32

### 1c. Verify clean git state (optional)

```bash
git status
# Should show only expected changes
# Commit any uncommitted work before building
```

---

## Step 2: Increment Build Number

### 2a. Decide on build number

**Pattern:**
- **Minor feature/fix:** Increment by 1 (32 → 33)
- **Major feature complete:** Increment to next milestone (32 → 35)

**User decides** - ask if unclear.

### 2b. Update build number in files

**Three locations to update:**

```bash
# 1. Config.swift
# Update line: static let buildNumber = "32"
# Change to: static let buildNumber = "33"

# 2. Xcode project (if using fastlane, this may be automatic)
# Fastlane typically handles this via increment_build_number

# 3. README.md
# Update: **Build:** 32
# Change to: **Build:** 33
```

---

## Step 3: Build IPA

### Method A: Using Fastlane (Preferred)

```bash
cd ios-app/PTPerformance
bundle exec fastlane beta
```

**What fastlane does:**
1. Increments build number automatically
2. Builds IPA for TestFlight
3. Archives build
4. Optionally uploads (if configured)

**Expected Output:**
```
✅ Build succeeded
✅ IPA created at: ios-app/PTPerformance/PTPerformance.ipa
```

### Method B: Using Xcode GUI

1. Open `ios-app/PTPerformance/PTPerformance.xcodeproj`
2. Select "Any iOS Device" as target
3. Product → Archive
4. Wait for archive to complete
5. Organizer window opens → Click "Distribute App"
6. Select "TestFlight & App Store"
7. Follow wizard

**Time:** ~3-5 minutes for build + archive

---

## Step 4: Upload to TestFlight

### If fastlane handled upload

Check output - if you see:
```
✅ Successfully uploaded to TestFlight
```

Skip to Step 5.

### If manual upload needed

```bash
# Using Xcode Organizer (already open from Method B above)
# OR using command line:

cd ios-app/PTPerformance
xcrun altool --upload-app -f PTPerformance.ipa -t ios -u YOUR_APPLE_ID -p YOUR_APP_SPECIFIC_PASSWORD
```

**Note:** May require Application-Specific Password from Apple ID settings.

### Alternative: Transporter App

1. Open Transporter app (installed with Xcode)
2. Drag IPA file into Transporter
3. Click "Deliver"
4. Wait for upload (1-5 minutes depending on network)

---

## Step 5: Verify TestFlight Upload

### 5a. Check App Store Connect

1. Go to: https://appstoreconnect.apple.com
2. My Apps → PT Performance
3. TestFlight tab
4. Check "iOS Builds" section

**Expected:** New build appears within 2-5 minutes

### 5b. Wait for processing

**Timeline:**
- Upload complete: Immediate
- Processing: 2-10 minutes
- Available for testing: 2-15 minutes (varies)

**Status progression:**
1. "Processing" (Apple is analyzing the build)
2. "Ready to Test" (can distribute to testers)

---

## Step 6: Update Documentation

### 6a. Update Linear issue

Post comment to current issue (e.g., ACP-107):

```
✅ Build 33 uploaded to TestFlight
Feature: [DESCRIPTION]
Changes: [BULLET LIST OF CHANGES]
Status: Processing (available in 5-10 min)
```

### 6b. Update README.md

```bash
# Update build number in header
# Change: **Build:** 32 (TestFlight)
# To: **Build:** 33 (TestFlight)
```

### 6c. Document in .outcomes/ (if major milestone)

For significant builds (new feature complete):

```bash
# Create build summary
cat > .outcomes/BUILD33_COMPLETE.md <<EOF
# Build 33 - Session Completion

**Feature:** Patient can complete session and see summary
**Status:** ✅ Complete, uploaded to TestFlight
**TestFlight:** Processing (ETA 10 min)

## Changes
- Added "Complete Session" button
- Created SessionSummaryView
- Implemented metrics calculation (volume, RPE, pain)

## Testing
1. Login as demo-athlete@ptperformance.app
2. Complete all exercises in today's session
3. Tap "Complete Session"
4. Verify summary shows correct metrics
EOF
```

---

## Step 7: Test on TestFlight

### 7a. Install build on device

**On iPad/iPhone:**
1. Open TestFlight app
2. Refresh (pull down)
3. Wait for Build 33 to appear
4. Tap "Install"

**ETA:** 2-15 minutes after upload

### 7b. Run smoke test

**Quick validation:**
1. Launch app
2. Login (demo credentials from Config.swift)
3. Navigate to feature that changed
4. Verify feature works as expected
5. Check for crashes/errors

### 7c. Report results

**If success:**
```
✅ Build 33 smoke test passed
Feature working as expected on TestFlight
```

**If failure:**
```
❌ Build 33 smoke test failed
Error: [DESCRIPTION]
Fix required before next build
```

---

## Common Issues

### "No signing identity found"

**Fix:**
1. Xcode → Preferences → Accounts
2. Select Apple ID
3. Download Manual Profiles
4. Try build again

### "Provisioning profile expired"

**Fix:**
1. Go to: https://developer.apple.com/account/resources/profiles
2. Renew provisioning profile
3. Download and double-click to install
4. Rebuild

### "Build already exists with this version"

**Fix:**
```bash
# Increment build number manually
# In project.pbxproj, find CURRENT_PROJECT_VERSION
# Increment by 1
```

### "Upload failed: Invalid IPA"

**Fix:**
1. Clean build folder: Product → Clean Build Folder
2. Delete Derived Data: ~/Library/Developer/Xcode/DerivedData/
3. Rebuild IPA

---

## Build Checklist Template

Use this for each build:

```markdown
## Build [NUMBER] Checklist

- [ ] All migrations applied
- [ ] Build number incremented
- [ ] IPA built successfully
- [ ] Uploaded to TestFlight
- [ ] Processing complete (10 min wait)
- [ ] Installed on test device
- [ ] Smoke test passed
- [ ] Linear issue updated
- [ ] README.md updated
- [ ] Outcomes documented (if milestone)
```

---

## Build Numbering Convention

**Pattern:** Sequential integers starting from 1

| Build | Phase | Feature |
|-------|-------|---------|
| 1-31 | Foundation | Initial development, archived |
| 32-34 | Exercise Logging | Patient exercise tracking |
| 35-37 | Dashboard Analytics | Therapist metrics & charts |
| 38-40 | PT Assistant AI | AI-powered plan suggestions |
| 41-43 | Program Builder | Program creation UI |
| 44-45 | Video Examples | Exercise video library |

**Current:** Build 32

**Next:** Build 33 (Session Completion feature)

---

## Fastlane Lanes Reference

**Available lanes:**

```bash
# Build and upload to TestFlight
bundle exec fastlane beta

# Build only (no upload)
bundle exec fastlane build

# Run tests
bundle exec fastlane test

# Increment build number
bundle exec fastlane increment_build
```

**Location:** `ios-app/PTPerformance/fastlane/Fastfile`

---

## Post-Build Actions

### If build is successful

1. ✅ Update Linear issue with TestFlight link
2. ✅ Notify stakeholders (if applicable)
3. ✅ Start planning next build

### If build fails

1. ❌ Document error in Linear
2. ❌ Fix issue
3. ❌ Retry build (same build number)

**Don't increment build number for failed builds**

---

**Summary: This runbook makes iOS builds mechanical and repeatable. Follow steps 1-7 in order.**

**Total Time:** 5-15 minutes (build + upload + verification)
