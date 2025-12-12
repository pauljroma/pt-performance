# Export Compliance - TestFlight Build Missing

## Issue
Build 2 uploaded successfully but not appearing in TestFlight.

## Most Common Cause: Export Compliance Not Answered

Apple requires you to answer export compliance questions for each build before it becomes available in TestFlight.

---

## ✅ Fix: Answer Export Compliance Questions

### Step 1: Go to App Store Connect
https://appstoreconnect.apple.com/apps/6756226704/testflight/ios

### Step 2: Look for Yellow Warning Banner
You should see a message like:
- "Missing Compliance" or
- "Provide Export Compliance Information"

### Step 3: Click on the Build
- Click on Build 2 (if it shows up in the list)
- Or look for "Missing Compliance" status

### Step 4: Answer Questions
You'll be asked:
1. **"Does your app use encryption?"**
   - Answer: **NO** (for this demo app)
   - The app only uses standard HTTPS which is exempt

2. If you answer YES (by mistake), you'll need to select exemption type:
   - Choose: "App uses standard encryption"
   - Or: "No, it qualifies for exemption"

### Step 5: Submit
Click "Start Internal Testing" after answering

---

## Alternative: Add to Info.plist (Prevents Future Prompts)

To avoid this question for every build, add to `Info.plist`:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This tells Apple the app doesn't use non-standard encryption.

---

## Other Possible Issues

### 1. Build Still Processing
- Check email (paul@romatech.com) for processing notifications
- Typical time: 5-15 minutes
- Maximum time: 2 hours

### 2. Build Validation Failed
Check email for messages like:
- "Invalid Binary"
- "Missing Required Info"
- "Binary Rejected"

### 3. Privacy Descriptions Missing
If using camera, location, etc., you need Info.plist descriptions:
- `NSCameraUsageDescription`
- `NSLocationWhenInUseUsageDescription`
- etc.

Our app doesn't use these, so this shouldn't be the issue.

---

## How to Check Status

### Via Web (Recommended)
1. Go to: https://appstoreconnect.apple.com/apps/6756226704/testflight/ios
2. Look at "iOS Builds" section
3. Check for:
   - Build 2 with "Missing Compliance" badge
   - Build 2 with "Processing" status
   - Build 2 with "Ready to Test" status

### Via Email
Check paul@romatech.com for:
- Subject: "Your build has been processed" (success)
- Subject: "Your build failed" (error)
- Subject: "Export Compliance Required" (needs action)

---

## Quick Test: Build 1 Working

Since Build 1 is visible, we know:
- ✅ App Store Connect configured correctly
- ✅ API keys working
- ✅ Upload process works

This suggests Build 2 either needs export compliance answered or is still processing.

---

## Action Plan

1. **Check App Store Connect web interface NOW**
   - https://appstoreconnect.apple.com/apps/6756226704/testflight/ios
   - Look for Build 2
   - Look for yellow warning badges

2. **Check email (paul@romatech.com)**
   - Search for "Build" or "TestFlight"
   - Look for messages from last hour

3. **If Export Compliance prompt appears:**
   - Answer "NO" to encryption question
   - Submit
   - Build should appear in 1-2 minutes

4. **If no Build 2 at all:**
   - We may need to add `ITSAppUsesNonExemptEncryption` to Info.plist
   - Rebuild and re-upload

---

## Next Upload: Prevent This Issue

Before next build, add to `Info.plist`:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This will:
- Skip export compliance questions
- Make builds available immediately after processing
- Avoid manual intervention

---

**Most Likely Solution**: Go to App Store Connect and answer the export compliance question for Build 2. It should appear within 1-2 minutes after answering.
