# Submit a new build to TestFlight

Increments the build number, archives, and uploads to TestFlight.

## Arguments
- `$ARGUMENTS`: Optional build number override (default: increment by 1)

## Pre-Flight

1. Check current build number:
```bash
grep CURRENT_PROJECT_VERSION /Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj | head -1
```

2. Verify clean build:
```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build 2>&1 | tail -5
```

3. Check no pending migrations:
```bash
ls /Users/expo/pt-performance/supabase/migrations/_pending/ 2>/dev/null
```

## Step 1: Bump Build Number

Update ALL occurrences of `CURRENT_PROJECT_VERSION` in `project.pbxproj` (Debug + Release). Also update `Config.swift` buildNumber if present.

## Step 2: Archive and Upload

**Fastlane (preferred):**
```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && bundle exec fastlane beta
```

**Manual:** Open Xcode > Product > Archive > Distribute App > TestFlight & App Store.

## Step 3: Verify

Report the new build number and confirm upload success. Processing takes 5-15 minutes in App Store Connect.
