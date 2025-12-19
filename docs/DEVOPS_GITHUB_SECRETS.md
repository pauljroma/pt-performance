# GitHub Secrets Configuration for iOS CI/CD

This document provides comprehensive documentation for all GitHub secrets required to run the iOS CI/CD pipeline and automated TestFlight deployments.

## Overview

The PTPerformance iOS app uses GitHub Actions for continuous integration and deployment. The workflows require several secrets to be configured in the GitHub repository settings for code signing, provisioning, and App Store Connect API access.

## Required Secrets

### Code Signing Secrets

#### `IOS_CERTIFICATE_BASE64`
**Type:** Base64-encoded P12 certificate
**Purpose:** Distribution certificate for code signing iOS builds
**How to Generate:**
```bash
# Export certificate from Keychain as .p12
# Then convert to base64
base64 -i certificate.p12 | pbcopy
```
**Used In:**
- `.github/workflows/ios-ci-cd.yml` (build-device job)
- `.github/workflows/ios-testflight-deploy.yml`

**Security Note:** This certificate must be an App Store Distribution certificate, not a Development certificate.

---

#### `IOS_CERTIFICATE_PASSWORD`
**Type:** String (password)
**Purpose:** Password for the P12 certificate
**How to Generate:** Use the password you set when exporting the certificate from Keychain
**Used In:**
- `.github/workflows/ios-ci-cd.yml` (build-device job)
- `.github/workflows/ios-testflight-deploy.yml`

**Security Note:** Use a strong password and store it securely. Never commit this to version control.

---

#### `IOS_PROVISIONING_PROFILE_BASE64`
**Type:** Base64-encoded mobileprovision file
**Purpose:** Provisioning profile for app signing
**How to Generate:**
```bash
# Download provisioning profile from Apple Developer Portal
# Convert to base64
base64 -i profile.mobileprovision | pbcopy
```
**Used In:**
- `.github/workflows/ios-ci-cd.yml` (build-device job)
- `.github/workflows/ios-testflight-deploy.yml`

**Requirements:**
- Profile type: App Store Distribution
- App ID: `com.ptperformance.app`
- Certificate: Must match the distribution certificate
- Devices: Not required for App Store profiles

---

### App Store Connect API Secrets

#### `APP_STORE_CONNECT_API_KEY`
**Type:** Base64-encoded P8 file
**Purpose:** App Store Connect API authentication key
**How to Generate:**
1. Log in to [App Store Connect](https://appstoreconnect.apple.com)
2. Go to Users and Access > Keys
3. Click the "+" button to create a new API key
4. Give it a name (e.g., "GitHub Actions CI/CD")
5. Select "Admin" or "Developer" access
6. Download the .p8 file (you can only download it once!)
7. Convert to base64:
```bash
base64 -i AuthKey_XXXXXXXXXX.p8 | pbcopy
```
**Used In:**
- `.github/workflows/ios-testflight-deploy.yml`

**Security Note:** Store the original .p8 file securely. You cannot download it again from Apple.

---

#### `APP_STORE_CONNECT_KEY_ID`
**Type:** String (10-character alphanumeric)
**Purpose:** Key ID for App Store Connect API
**How to Generate:** This is provided when you create the API key in App Store Connect
**Example:** `AB12CD34EF`
**Used In:**
- `.github/workflows/ios-testflight-deploy.yml`

---

#### `APP_STORE_CONNECT_ISSUER_ID`
**Type:** String (UUID format)
**Purpose:** Issuer ID for App Store Connect API
**How to Generate:** Found in App Store Connect > Users and Access > Keys (at the top of the page)
**Example:** `12345678-1234-1234-1234-123456789012`
**Used In:**
- `.github/workflows/ios-testflight-deploy.yml`

---

#### `APP_STORE_CONNECT_API_KEY_CONTENT` (Fastlane)
**Type:** Base64-encoded P8 file content
**Purpose:** Used by fastlane for App Store Connect API authentication
**How to Generate:** Same as `APP_STORE_CONNECT_API_KEY`
**Used In:**
- Fastlane scripts (when running locally or via `fastlane beta`)

**Note:** This is the same value as `APP_STORE_CONNECT_API_KEY` but used in different contexts.

---

#### `APP_STORE_CONNECT_API_KEY_ID` (Fastlane)
**Type:** String (10-character alphanumeric)
**Purpose:** Used by fastlane for App Store Connect API authentication
**How to Generate:** Same as `APP_STORE_CONNECT_KEY_ID`
**Used In:**
- Fastlane scripts

---

#### `APP_STORE_CONNECT_API_ISSUER_ID` (Fastlane)
**Type:** String (UUID format)
**Purpose:** Used by fastlane for App Store Connect API authentication
**How to Generate:** Same as `APP_STORE_CONNECT_ISSUER_ID`
**Used In:**
- Fastlane scripts

---

### Supabase Secrets (for Integration Tests)

#### `SUPABASE_URL`
**Type:** String (URL)
**Purpose:** Supabase project URL for integration testing
**How to Generate:** Found in Supabase project settings
**Example:** `https://abcdefghijklmnop.supabase.co`
**Used In:**
- `.github/workflows/ios-ci-cd.yml` (integration-tests job)

---

#### `SUPABASE_ANON_KEY`
**Type:** String (JWT token)
**Purpose:** Supabase anonymous key for integration testing
**How to Generate:** Found in Supabase project settings > API
**Used In:**
- `.github/workflows/ios-ci-cd.yml` (integration-tests job)

**Security Note:** Use the anonymous key, not the service role key. The anon key has RLS protection.

---

## How to Add Secrets to GitHub

1. Navigate to your repository on GitHub
2. Go to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Enter the secret name (exactly as shown above)
5. Paste the secret value
6. Click "Add secret"

## Secret Verification Checklist

Before running the CI/CD pipeline, verify:

- [ ] `IOS_CERTIFICATE_BASE64` - Valid App Store Distribution certificate
- [ ] `IOS_CERTIFICATE_PASSWORD` - Correct password for the certificate
- [ ] `IOS_PROVISIONING_PROFILE_BASE64` - Valid App Store provisioning profile
- [ ] `APP_STORE_CONNECT_API_KEY` - Valid P8 key from App Store Connect
- [ ] `APP_STORE_CONNECT_KEY_ID` - Correct 10-character key ID
- [ ] `APP_STORE_CONNECT_ISSUER_ID` - Correct UUID from App Store Connect
- [ ] `SUPABASE_URL` - Valid Supabase project URL
- [ ] `SUPABASE_ANON_KEY` - Valid Supabase anonymous key

## Troubleshooting

### Code Signing Errors

**Error:** "No valid code signing identity found"
- **Solution:** Verify `IOS_CERTIFICATE_BASE64` is a valid distribution certificate
- **Check:** Certificate password is correct in `IOS_CERTIFICATE_PASSWORD`

**Error:** "Provisioning profile doesn't match certificate"
- **Solution:** Download a new provisioning profile that includes the distribution certificate
- **Check:** Both certificate and profile are for App Store distribution

### TestFlight Upload Errors

**Error:** "Authentication failed"
- **Solution:** Verify all three App Store Connect API secrets are correct
- **Check:** API key has not been revoked in App Store Connect

**Error:** "Invalid API key"
- **Solution:** Ensure `APP_STORE_CONNECT_API_KEY` is base64-encoded
- **Check:** Key ID and Issuer ID match the key in App Store Connect

### Integration Test Errors

**Error:** "Failed to connect to Supabase"
- **Solution:** Verify `SUPABASE_URL` is correct and project is active
- **Check:** `SUPABASE_ANON_KEY` is the anonymous key, not service role key

## Security Best Practices

1. **Never commit secrets to version control**
   - Use `.gitignore` for local secret files
   - Use GitHub Secrets for CI/CD

2. **Rotate secrets regularly**
   - Update certificates before expiration
   - Regenerate API keys annually

3. **Use minimal permissions**
   - App Store Connect API keys should have "Developer" role if possible
   - Supabase keys should use RLS policies

4. **Monitor secret usage**
   - Review GitHub Actions logs for unauthorized access
   - Check App Store Connect for API key usage

5. **Backup critical secrets**
   - Store certificates and keys in a secure password manager
   - Document the location of backup files

## Updating Secrets

When secrets need to be updated (e.g., certificate renewal):

1. Generate new certificate/key following the "How to Generate" instructions
2. Convert to base64 if required
3. Update the secret in GitHub repository settings
4. Test the workflow with a manual trigger
5. Update this documentation if the process has changed

## Local Development

For local fastlane runs, create a `.env` file in `ios-app/PTPerformance/fastlane/`:

```bash
APP_STORE_CONNECT_API_KEY_CONTENT="<base64-encoded-p8-content>"
APP_STORE_CONNECT_API_KEY_ID="AB12CD34EF"
APP_STORE_CONNECT_API_ISSUER_ID="12345678-1234-1234-1234-123456789012"
```

**Important:** Never commit the `.env` file. It's already in `.gitignore`.

## Related Documentation

- [iOS CI/CD Pipeline](.github/workflows/ios-ci-cd.yml) - Main CI/CD workflow
- [TestFlight Deploy](.github/workflows/ios-testflight-deploy.yml) - Manual TestFlight deployment
- [Fastlane Configuration](ios-app/PTPerformance/fastlane/Fastfile) - Fastlane automation
- [DEVOPS_ROLLBACK_PROCEDURES.md](./DEVOPS_ROLLBACK_PROCEDURES.md) - How to rollback failed deployments
- [DEVOPS_STAGING_ENVIRONMENT.md](./DEVOPS_STAGING_ENVIRONMENT.md) - Staging environment setup

## Support

For questions or issues with GitHub Secrets:
1. Check the troubleshooting section above
2. Review GitHub Actions logs for specific error messages
3. Consult Apple Developer documentation for certificate/provisioning issues
4. Contact the DevOps team for assistance

---

**Last Updated:** 2025-12-19
**Document Owner:** DevOps Team
**Review Frequency:** Quarterly or when secrets are updated
