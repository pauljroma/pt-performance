# Deploy to TestFlight

One-command deployment: iOS build to TestFlight + Supabase migrations.

## Trigger

```
/deploy [build-number]
```

**Examples:**
- `/deploy` - Auto-increment build number
- `/deploy 89` - Deploy as build 89

## Prerequisites

Before running:
1. Ensure Xcode command line tools installed
2. Valid Apple Developer account authenticated
3. Supabase CLI authenticated (for migrations)

## Execution Steps

### Phase 1: Verification

1. **Check pending migrations:**
```bash
ls -la supabase/migrations/*.sql 2>/dev/null | tail -5
```

2. **Get current build number:**
```bash
grep 'buildNumber = ' ios-app/PTPerformance/Config.swift
```

3. **Check git status:**
```bash
git status --short
```

### Phase 2: Supabase Migrations

If migrations exist that haven't been applied:

1. List pending migrations in `supabase/migrations/`
2. Apply each via Supabase Dashboard SQL Editor:
   - URL: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
   - Paste migration content
   - Execute

**Note:** CLI migrations don't work reliably - use Dashboard.

### Phase 3: Build Number Update

1. **Update Config.swift:**
```swift
static let buildNumber = "[NEW_NUMBER]"
```

2. **Update Xcode project:**
```bash
cd ios-app/PTPerformance
# Update CURRENT_PROJECT_VERSION in project.pbxproj
```

### Phase 4: iOS Build

```bash
cd ios-app/PTPerformance

# Run tests first
xcodebuild test \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  -quiet

# Archive for release
xcodebuild archive \
  -project PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -archivePath build/PTPerformance.xcarchive \
  -destination 'generic/platform=iOS'

# Export IPA
xcodebuild -exportArchive \
  -archivePath build/PTPerformance.xcarchive \
  -exportPath build \
  -exportOptionsPlist ExportOptions.plist
```

### Phase 5: Upload to TestFlight

```bash
# Using altool (requires App Store Connect API key)
xcrun altool --upload-app \
  -f build/PTPerformance.ipa \
  -t ios \
  --apiKey [API_KEY_ID] \
  --apiIssuer [ISSUER_ID]

# OR using Transporter CLI
xcrun iTMSTransporter -m upload \
  -f build/PTPerformance.ipa \
  -u [APPLE_ID] \
  -p [APP_SPECIFIC_PASSWORD]
```

### Phase 6: Git Tag

```bash
git add .
git commit -m "Build [NUMBER]: [DESCRIPTION]"
git tag -a "build-[NUMBER]" -m "TestFlight build [NUMBER]"
git push origin main --tags
```

### Phase 7: Notify (Optional)

Post deployment summary to Slack:
```bash
curl -X POST "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "text": "Build [NUMBER] uploaded to TestFlight",
    "blocks": [
      {
        "type": "section",
        "text": {
          "type": "mrkdwn",
          "text": "*PT Performance Build [NUMBER]*\n:white_check_mark: Uploaded to TestFlight\n:clock1: Processing (5-15 min)"
        }
      }
    ]
  }'
```

## Output

After successful deployment:
```
Deployment Complete

Build: 89
TestFlight: Uploaded (processing)
Migrations: 2 applied
Git Tag: build-89

Next Steps:
1. Wait 5-15 min for TestFlight processing
2. Install via TestFlight app on device
3. Run smoke test
```

## Rollback

If deployment fails:

1. **iOS Build Failure:**
   - Check Xcode signing certificates
   - Verify provisioning profiles
   - Clean build folder and retry

2. **Migration Failure:**
   - DO NOT proceed with iOS build
   - Fix migration SQL
   - Rerun migration

3. **Upload Failure:**
   - Check App Store Connect credentials
   - Verify build number not already used
   - Use Transporter.app as fallback

## Reference

See also:
- `.claude/BUILD_RUNBOOK.md` - Detailed build process
- `.claude/MIGRATION_RUNBOOK.md` - Migration procedures
- `ios-app/PTPerformance/fastlane/` - Fastlane configuration
