# Submit a new build to TestFlight

Archives, signs, and uploads the app to TestFlight using xcodebuild.

## Arguments
- `$ARGUMENTS`: Optional build number override (default: increment by 1)

## Pre-Flight

1. Check current build number:
```bash
grep CURRENT_PROJECT_VERSION /Users/expo/pt-performance/ios-app/PTPerformance/PTPerformance.xcodeproj/project.pbxproj | head -1
```

2. Check recent git log to avoid reusing a build number:
```bash
git log --oneline -5
```

3. Verify clean build:
```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build 2>&1 | tail -5
```

## Step 1: Bump Build Number

Increment `CURRENT_PROJECT_VERSION` in `project.pbxproj` (both Debug + Release occurrences). Use `$ARGUMENTS` if provided, otherwise increment by 1 from the highest of (current pbxproj value, recent git log build numbers).

## Step 2: Archive

```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild archive \
  -scheme PTPerformance \
  -archivePath ./build/PTPerformance.xcarchive \
  -allowProvisioningUpdates \
  2>&1 | tail -10
```

## Step 3: Export and Upload to TestFlight

Create `build/ExportOptions.plist` if it doesn't exist:
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>app-store-connect</string>
	<key>destination</key>
	<string>upload</string>
	<key>signingStyle</key>
	<string>automatic</string>
	<key>teamID</key>
	<string>5NNLBL74XR</string>
	<key>uploadSymbols</key>
	<true/>
</dict>
</plist>
```

Then export and upload:
```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild -exportArchive \
  -archivePath ./build/PTPerformance.xcarchive \
  -exportOptionsPlist ./build/ExportOptions.plist \
  -exportPath ./build/export \
  -allowProvisioningUpdates \
  2>&1 | tail -20
```

## Step 4: Commit and Push

Commit with message format: `Build NNN: <summary of changes since last build>`

## Step 5: Verify

Confirm output contains `EXPORT SUCCEEDED` and `Upload succeeded`. Report the build number. Processing takes 5-15 minutes in App Store Connect.
