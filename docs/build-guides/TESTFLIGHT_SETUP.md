# TestFlight Deployment Guide

## Prerequisites

### 1. Apple Developer Account
- Sign up at https://developer.apple.com ($99/year)
- Complete enrollment

### 2. App-Specific Password
Since you're using terminal-only:

1. Go to https://appleid.apple.com
2. Sign in with your Apple ID
3. **Security** section → **App-Specific Passwords**
4. Click **Generate Password**
5. Label: "TestFlight Upload"
6. Copy the password (save it somewhere safe!)

### 3. Create App in App Store Connect

1. Go to https://appstoreconnect.apple.com
2. **Apps** → **+** → **New App**
3. Fill in:
   - Platform: iOS
   - Name: PT Performance
   - Primary Language: English
   - Bundle ID: com.ptperformance.app (or your custom one)
   - SKU: ptperformance-001
4. Click **Create**

## Build & Deploy

### Option 1: Quick Local Build (Test First)
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app
./build_local.sh
```

This builds for simulator - good for testing compilation.

### Option 2: Full TestFlight Deployment
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app
./deploy_testflight.sh
```

This will:
1. ✅ Add all Swift files to Xcode project
2. ✅ Build release archive
3. ✅ Export IPA
4. ⏸️  Show upload instructions (manual step)

### Upload to TestFlight

After build completes, upload the IPA:

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

xcrun altool --upload-app \
  --type ios \
  --file build/PTPerformance.ipa \
  --username your-apple-id@email.com \
  --password xxxx-xxxx-xxxx-xxxx
```

Replace:
- `your-apple-id@email.com` - Your Apple ID email
- `xxxx-xxxx-xxxx-xxxx` - Your app-specific password

## Install on iPad

1. Install **TestFlight** app from App Store on iPad
2. Sign in with same Apple ID
3. Build will appear after ~5 minutes processing
4. Tap **Install**

## Troubleshooting

**Build fails with "No signing identity"?**
```bash
# Check available identities
security find-identity -v -p codesigning

# If none, you need to create certificates in Apple Developer Portal
```

**Upload fails?**
- Verify app-specific password is correct
- Check App Store Connect app is created
- Ensure Bundle ID matches

**Want to test locally first?**
```bash
# Install on connected iPad (if you have access to it)
brew install ios-deploy

cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
ios-deploy --bundle build/PTPerformance.app
```

## Access via Tailscale

Since you're on Tailscale, you can:

1. Build on remote Mac: `./deploy_testflight.sh`
2. Download IPA via HTTP:
   ```bash
   # On Mac:
   cd build/
   python3 -m http.server 8080
   
   # On iPad browser (using Tailscale IP):
   http://100.x.x.x:8080/PTPerformance.ipa
   ```
3. Use a tool like **Diawi** to distribute:
   - Upload IPA to https://diawi.com
   - Get shareable link
   - Open on iPad → Install

## Next Steps

1. ✅ Run `./build_local.sh` first to test compilation
2. ✅ Fix any build errors
3. ✅ Run `./deploy_testflight.sh` to create IPA
4. ✅ Upload to TestFlight
5. ✅ Install on iPad via TestFlight app

Questions? Just ask!
