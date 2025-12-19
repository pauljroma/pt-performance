# APNs (Apple Push Notification service) Setup Guide

## Overview

This guide covers the complete setup process for Apple Push Notifications (APNs) for the PT Performance app. APNs enables the app to deliver push notifications for workload flags, session reminders, and safety alerts.

## Prerequisites

- Apple Developer Account with admin access
- Access to Apple Developer Portal
- Xcode 15.0 or later
- PT Performance app bundle ID: `com.ptperformance.app`

## Setup Steps

### 1. Create APNs Authentication Key (Recommended Method)

Apple now recommends using token-based authentication (APNs Auth Key) instead of certificates, as it's simpler and never expires.

#### Steps:

1. **Navigate to Apple Developer Portal**
   - Go to [https://developer.apple.com/account](https://developer.apple.com/account)
   - Sign in with your Apple Developer account

2. **Create APNs Key**
   - Go to Certificates, Identifiers & Profiles
   - Select "Keys" from the sidebar
   - Click the "+" button to create a new key
   - Enter a name: "PT Performance APNs Key"
   - Check "Apple Push Notifications service (APNs)"
   - Click "Continue" then "Register"

3. **Download and Save the Key**
   - Download the `.p8` file immediately (you can only download it once!)
   - Save it securely - you'll need this for your backend
   - Note the **Key ID** (10-character string)
   - Note your **Team ID** (found in top right of developer portal)

4. **Store Credentials Securely**
   ```
   Key ID: XXXXXXXXXX (10 characters)
   Team ID: YYYYYYYYYY (10 characters)
   Auth Key File: AuthKey_XXXXXXXXXX.p8
   Bundle ID: com.ptperformance.app
   ```

### 2. Enable Push Notifications in Xcode

1. **Open Xcode Project**
   - Open `PTPerformance.xcodeproj`

2. **Add Push Notification Capability**
   - Select the PTPerformance target
   - Go to "Signing & Capabilities"
   - Click "+ Capability"
   - Add "Push Notifications"

3. **Add Background Modes**
   - In the same "Signing & Capabilities" tab
   - Click "+ Capability"
   - Add "Background Modes"
   - Check "Remote notifications"

4. **Verify Entitlements**
   - Xcode should auto-generate `PTPerformance.entitlements`
   - Verify it contains:
     ```xml
     <key>aps-environment</key>
     <string>development</string>
     ```

### 3. Configure Supabase for Push Notifications

1. **Install Supabase Edge Function**
   ```bash
   cd supabase/functions
   supabase functions deploy send-push-notification
   ```

2. **Add APNs Credentials to Supabase Secrets**
   ```bash
   # Set APNs Key ID
   supabase secrets set APNS_KEY_ID=XXXXXXXXXX

   # Set Team ID
   supabase secrets set APNS_TEAM_ID=YYYYYYYYYY

   # Set the .p8 key content (base64 encoded)
   cat AuthKey_XXXXXXXXXX.p8 | base64 | supabase secrets set APNS_AUTH_KEY=

   # Set bundle ID
   supabase secrets set APNS_BUNDLE_ID=com.ptperformance.app
   ```

3. **Create Push Notification Tokens Table**
   - Migration already created: `20251219000005_create_push_tokens.sql`
   - Run: `supabase db push`

### 4. Implement iOS Push Notification Handling

The following files handle push notifications in the iOS app:

#### PushNotificationService.swift
- Registers device for remote notifications
- Handles device token updates
- Manages push notification permissions
- Syncs device tokens with Supabase

#### NotificationService.swift (Enhanced)
- Handles both local and remote notifications
- Manages notification categories and actions
- Schedules session reminders
- Handles workload flag alerts

### 5. Testing Push Notifications

#### Test with Development Environment

1. **Run App on Physical Device**
   - Push notifications don't work on simulator
   - Use a real iPhone/iPad with iOS 13+

2. **Get Device Token**
   - App logs device token on successful registration
   - Check Xcode console for: `"APNs device token: ..."`

3. **Send Test Notification via Supabase**
   ```sql
   -- Send test notification to a user
   SELECT send_push_notification(
     user_id := 'uuid-here',
     title := 'Test Notification',
     body := 'This is a test from Supabase',
     data := '{"type": "test"}'::jsonb
   );
   ```

4. **Test Workload Flag Notifications**
   ```sql
   -- Trigger a high-priority workload flag
   INSERT INTO workload_flags (
     patient_id,
     high_acwr,
     acwr,
     acute_workload,
     chronic_workload
   ) VALUES (
     'patient-uuid',
     true,
     1.6,
     120.0,
     75.0
   );
   ```

#### Test Notification Categories

The app supports these notification types:

1. **Session Reminders**
   - Category: `SESSION_REMINDER`
   - Actions: "Start Workout", "Snooze 15 min"

2. **Workload Flags**
   - Category: `WORKLOAD_FLAG`
   - Actions: "View Details", "Dismiss"
   - Priority: High for critical flags, Normal for warnings

3. **Safety Alerts**
   - Category: `SAFETY_ALERT`
   - Actions: "Review", "Dismiss"
   - Priority: Critical (time-sensitive)

### 6. Production Deployment

#### Update for Production

1. **Update Entitlements for Production**
   - In Xcode, change `aps-environment` from `development` to `production`
   - This happens automatically when archiving for App Store/TestFlight

2. **Update Supabase Environment**
   ```bash
   # Set production environment flag
   supabase secrets set APNS_ENVIRONMENT=production
   ```

3. **Verify Production Settings**
   - Ensure production Supabase project has correct APNs credentials
   - Test with TestFlight build before App Store release

#### App Store Review

For App Store review, provide this information:

**Push Notification Usage Description:**
> "PT Performance uses push notifications to send important safety alerts about training workload, remind users of scheduled workout sessions, and notify therapists of patient progress updates. Notifications help prevent overtraining injuries and ensure optimal rehabilitation outcomes."

### 7. Monitoring and Debugging

#### Check Push Notification Status

1. **Device Token Registration**
   ```sql
   -- Check if device token is registered
   SELECT * FROM push_notification_tokens
   WHERE user_id = 'uuid-here'
   ORDER BY updated_at DESC
   LIMIT 1;
   ```

2. **Notification Delivery Logs**
   ```sql
   -- Check notification delivery status
   SELECT * FROM notification_logs
   WHERE user_id = 'uuid-here'
   ORDER BY created_at DESC
   LIMIT 10;
   ```

3. **APNs Feedback Service**
   - Supabase Edge Function logs APNs responses
   - Check function logs: `supabase functions logs send-push-notification`

#### Common Issues

**Issue: "No device token received"**
- Solution: Ensure app has notification permissions
- Check: Device is not on simulator
- Verify: Provisioning profile has Push Notification capability

**Issue: "Invalid device token"**
- Solution: Device token changes between development and production
- Fix: Delete old tokens, re-register device

**Issue: "Notifications not received"**
- Check: User has granted notification permissions
- Verify: APNs credentials are correct in Supabase
- Test: Send test notification via APNs console

**Issue: "BadDeviceToken error from APNs"**
- Cause: Using development certificate with production device token (or vice versa)
- Fix: Ensure APNS_ENVIRONMENT matches your build configuration

### 8. Best Practices

1. **Handle Permission Requests Gracefully**
   - Request permissions at appropriate times (not on app launch)
   - Explain why notifications are beneficial
   - Provide in-app notification center as alternative

2. **Optimize Notification Content**
   - Keep titles under 25 characters
   - Keep bodies under 2 lines (100 characters)
   - Use rich content (images, actions) appropriately

3. **Respect User Preferences**
   - Allow users to customize notification types
   - Support notification quiet hours
   - Provide granular controls (workload flags only, session reminders only, etc.)

4. **Monitor Delivery Rates**
   - Track notification send success rates
   - Monitor user engagement with notifications
   - Adjust strategy based on analytics

5. **Security Considerations**
   - Never include PHI (Protected Health Information) in notification content
   - Use generic messages: "New safety alert" instead of specific values
   - Require app unlock to view sensitive details

### 9. Notification Payload Examples

#### Session Reminder Notification
```json
{
  "aps": {
    "alert": {
      "title": "Workout Reminder",
      "body": "Your session is starting in 30 minutes"
    },
    "category": "SESSION_REMINDER",
    "sound": "default",
    "badge": 1
  },
  "scheduled_session_id": "uuid",
  "session_id": "uuid",
  "patient_id": "uuid"
}
```

#### High-Priority Workload Flag
```json
{
  "aps": {
    "alert": {
      "title": "Safety Alert",
      "body": "High workload detected - Review recommended"
    },
    "category": "WORKLOAD_FLAG",
    "sound": "default",
    "badge": 1,
    "interruption-level": "time-sensitive"
  },
  "flag_id": "uuid",
  "flag_type": "high_acwr",
  "severity": "critical",
  "patient_id": "uuid"
}
```

#### Safety Alert Notification
```json
{
  "aps": {
    "alert": {
      "title": "Review Required",
      "body": "Patient reported pain level > 7/10"
    },
    "category": "SAFETY_ALERT",
    "sound": "default",
    "badge": 1,
    "interruption-level": "critical"
  },
  "alert_type": "pain_threshold",
  "patient_id": "uuid",
  "therapist_id": "uuid"
}
```

## Resources

- [Apple Push Notification Service Documentation](https://developer.apple.com/documentation/usernotifications)
- [Supabase Edge Functions Guide](https://supabase.com/docs/guides/functions)
- [APNs Provider API](https://developer.apple.com/documentation/usernotifications/setting_up_a_remote_notification_server)

## Support

For issues with APNs setup:
1. Check Apple Developer Forums
2. Review Supabase function logs
3. Test with Apple's Push Notification Console
4. Contact Apple Developer Support for certificate issues

## Version History

- **1.0** (2025-12-19): Initial APNs setup guide for Build 69
- Compatible with iOS 13.0+, Supabase Edge Functions v1
