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

## Step 2: Unlock Keychain

This is required for code signing to work. Read the password from `~/.ptp_build_keychain_pass` (user stores it once with `echo 'PASSWORD' > ~/.ptp_build_keychain_pass && chmod 600 ~/.ptp_build_keychain_pass`).

```bash
KEYCHAIN_PASS=$(cat ~/.ptp_build_keychain_pass 2>/dev/null)
if [ -z "$KEYCHAIN_PASS" ]; then
  echo "❌ Keychain password not found. Run: echo 'YOUR_MAC_PASSWORD' > ~/.ptp_build_keychain_pass && chmod 600 ~/.ptp_build_keychain_pass"
  exit 1
fi
security unlock-keychain -p "$KEYCHAIN_PASS" ~/Library/Keychains/login.keychain-db && \
security set-key-partition-list -S apple-tool:,apple:,codesign: -s -k "$KEYCHAIN_PASS" -t private ~/Library/Keychains/login.keychain-db && \
echo "✅ Keychain unlocked and partition list set"
```

## Step 3: Archive

```bash
cd /Users/expo/pt-performance/ios-app/PTPerformance && \
xcodebuild archive \
  -scheme PTPerformance \
  -archivePath ./build/PTPerformance.xcarchive \
  -allowProvisioningUpdates \
  2>&1 | tail -10
```

## Step 4: Export and Upload to TestFlight

Create `build/ExportOptions.plist`:
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
	<key>manageAppVersionAndBuildNumber</key>
	<false/>
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
  -authenticationKeyPath ~/.appstoreconnect/private_keys/AuthKey_9S37GWGW49.p8 \
  -authenticationKeyID 9S37GWGW49 \
  -authenticationKeyIssuerID eebecd15-2a07-4dc3-a74c-aed17ca3887a \
  2>&1 | tail -20
```

## Step 5: Commit and Push

Commit with message format: `Build NNN: <summary of changes since last build>`

## Step 6: Verify

Confirm output contains `EXPORT SUCCEEDED` and `Upload succeeded`. Report the build number. Processing takes 5-15 minutes in App Store Connect.
