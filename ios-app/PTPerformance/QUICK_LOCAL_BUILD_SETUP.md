# Quick Local Build Setup

## Option 1: Interactive Setup (Easiest)

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
./setup_local_build.sh
```

This script will ask for each secret value one by one.

## Option 2: Manual .env File

Create `.env` file with these values:

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
cp .env.example .env
# Then edit .env with your actual values
```

## Where to Get Secret Values

### If You're the GitHub Admin

1. Go to: https://github.com/pauljroma/pt-performance/settings/secrets/actions
2. You can't VIEW the secrets, but you can UPDATE them
3. If you have the original values, paste them

### If Someone Else Set Up GitHub

Ask them for these 6 values:

1. **APP_STORE_CONNECT_API_KEY_ID** - From App Store Connect API
2. **APP_STORE_CONNECT_API_ISSUER_ID** - From App Store Connect API
3. **APP_STORE_CONNECT_API_KEY_CONTENT** - Base64-encoded .p8 file
5. **MATCH_PASSWORD** - Password for the certificates repo
6. **MATCH_GIT_BASIC_AUTHORIZATION** - Git credentials for match repo

### If You Need to Regenerate

If you're the Apple Developer account owner, you can regenerate:

#### 1. App Store Connect API Key

1. Go to: https://appstoreconnect.apple.com/access/api
2. Click **Keys** → **+** (Generate New Key)
3. Name: "TestFlight Deployment"
4. Access: **App Manager**
5. Click **Generate**
6. Download the `.p8` file (YOU CAN ONLY DOWNLOAD ONCE!)
7. Save the Key ID and Issuer ID

Convert .p8 to base64:
```bash
base64 -i AuthKey_XXXXXX.p8 | tr -d '\n'
```

#### 2. Team ID

Your Apple Developer Team ID is needed for signing. Find it at https://developer.apple.com/account under Membership Details.

## After Setup

Run the build:
```bash
cd ios-app/PTPerformance
xcodebuild -scheme PTPerformance -configuration Release \
  -archivePath ./build/PTPerformance.xcarchive archive
```

Expected time: **2-3 minutes** on M3 Ultra!

## Verify Environment Variables

Before running, verify your .env is loaded:
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance

# Load .env
set -a
source .env
set +a

# Check if variables are set
echo "Key ID: ${APP_STORE_CONNECT_API_KEY_ID:0:10}..."
echo "Issuer ID: ${APP_STORE_CONNECT_API_ISSUER_ID:0:10}..."
echo "Team ID: Set in Xcode project"
```

## Troubleshooting

**"No such file .env"?**
- Make sure you created the .env file in the PTPerformance directory
- Run: `pwd` to verify you're in the right directory

**"Missing API key"?**
- Verify .env file has all 6 variables
- Make sure there are no spaces around the `=` sign
- Format: `VAR_NAME=value` (not `VAR_NAME = value`)

**"Unauthorized" error?**
- Check that APP_STORE_CONNECT_API_KEY_CONTENT is correct
- Verify it's base64 encoded (should be a long string)
- Make sure you copied the entire value


