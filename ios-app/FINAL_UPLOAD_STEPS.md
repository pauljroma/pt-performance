# Build 71 - Final Upload Steps

## ✅ Build Complete - Ready for Upload

**Build Number**: 71
**IPA Location**: `/Users/expo/Code/expo/ios-app/PTPerformance/build/export/PTPerformance.ipa`
**Status**: Archive and export successful

---

## Choose Your Upload Method

### Method 1: Download Transporter (Easiest - 5 minutes)

1. **Download Transporter**
   ```bash
   open "https://apps.apple.com/us/app/transporter/id1450874784"
   ```
   Or search "Transporter" in Mac App Store

2. **Install and Open**
   - Install from App Store
   - Open Transporter app

3. **Sign In**
   - Use Apple ID: paul@roma.ai
   - Enter password when prompted

4. **Upload IPA**
   - Click the "+" button or "Add App"
   - Navigate to: `/Users/expo/Code/expo/ios-app/PTPerformance/build/export/PTPerformance.ipa`
   - Select the file
   - Click "Deliver"
   - Wait 2-5 minutes for upload to complete

5. **Verify**
   - Go to https://appstoreconnect.apple.com
   - Navigate to: My Apps → PTPerformance → TestFlight
   - Wait 15-30 minutes for processing
   - Build 71 should appear

---

### Method 2: Command Line (Requires App-Specific Password)

1. **Generate App-Specific Password**
   ```bash
   open "https://appleid.apple.com"
   ```
   - Sign in with paul@roma.ai
   - Go to "Security" section
   - Click "Generate Password" under "App-Specific Passwords"
   - Label it: "Xcode Upload"
   - Copy the password (xxxx-xxxx-xxxx-xxxx)

2. **Save Password to Keychain**
   ```bash
   security add-generic-password -a "paul@roma.ai" -s "altool" -w
   # Paste the app-specific password when prompted
   ```

3. **Upload to TestFlight**
   ```bash
   cd /Users/expo/Code/expo/ios-app/PTPerformance

   xcrun altool --upload-app \
     --type ios \
     --file build/export/PTPerformance.ipa \
     --username paul@roma.ai \
     --password @keychain:altool
   ```

4. **Wait for Confirmation**
   - Command will show progress
   - Should complete in 2-5 minutes
   - Look for "No errors uploading" message

5. **Verify in App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - My Apps → PTPerformance → TestFlight
   - Wait 15-30 minutes for processing

---

### Method 3: Use Xcode Directly

1. **Open Archive in Xcode**
   ```bash
   open -a Xcode /Users/expo/Code/expo/ios-app/PTPerformance/build/PTPerformance.xcarchive
   ```

2. **Distribute App**
   - Xcode Organizer will open
   - Click "Distribute App"
   - Select "App Store Connect"
   - Click "Upload"
   - Follow the prompts
   - Sign in with paul@roma.ai when asked

3. **Wait for Processing**
   - Same as other methods (15-30 minutes)

---

## After Upload Completes

### Immediate (0-30 minutes)
- [ ] Verify build appears in App Store Connect
- [ ] Check for processing errors
- [ ] Note the build status

### Short Term (1-2 hours)
- [ ] Once processing completes, add to external testing
- [ ] Update release notes:
  ```
  Build 71 - Scheduled Sessions Calendar

  New Features:
  • Monthly calendar view with session indicators
  • Drag-to-reschedule sessions with haptic feedback
  • Session reminder notifications (1 hour before)
  • Quick session completion interface

  Testing Focus:
  • Calendar navigation and session display
  • Drag-and-drop rescheduling
  • Notification delivery and snooze
  • Quick logging workflow
  ```

### Medium Term (1-2 days)
- [ ] Enable for external testers
- [ ] Monitor TestFlight feedback
- [ ] Check crash reports in Xcode Organizer

### Update Linear Issues
Once uploaded, mark these as complete:
- ACP-197: Calendar Monthly View UI
- ACP-198: Calendar Data Integration
- ACP-199: Drag-to-Reschedule Interaction
- ACP-200: Session Reminder Notifications
- ACP-201: Session Status Color Coding
- ACP-202: Calendar Navigation Controls
- ACP-203: Session Quick Completion UI
- ACP-207: Calendar Integration Tests
- ACP-208: Notification Tests

---

## Quick Reference

**IPA File**:
```
/Users/expo/Code/expo/ios-app/PTPerformance/build/export/PTPerformance.ipa
```

**Apple ID**: paul@roma.ai

**App Store Connect**:
https://appstoreconnect.apple.com

**App ID**: com.ptperformance.app

**Build Number**: 71

---

## Troubleshooting

### "Authentication failed"
→ Need app-specific password (see Method 2 above)

### "Invalid IPA"
→ Re-export: `cd PTPerformance && xcodebuild -exportArchive -archivePath build/PTPerformance.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist`

### "Upload timeout"
→ Try again, TestFlight servers may be slow

### "Processing stuck"
→ Normal, can take up to 30 minutes

---

## Build 71 Summary

✅ **All Complete:**
- 7 agents executed successfully
- ~3,194 lines production code
- ~1,555 lines test code (26+ tests)
- Build compiled (0 errors, 0 warnings)
- Archive created
- IPA exported

⏳ **Pending:**
- TestFlight upload (manual - choose method above)

---

**Ready to Upload**: `/Users/expo/Code/expo/ios-app/PTPerformance/build/export/PTPerformance.ipa`

Choose Method 1, 2, or 3 above to complete the deployment.
