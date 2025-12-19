# Sentry Setup Guide for PTPerformance

## Overview
Sentry provides real-time error tracking and performance monitoring for the PTPerformance iOS app.

## Prerequisites
1. Sentry account (https://sentry.io)
2. Xcode 15.2 or later
3. Swift Package Manager

## Installation

### 1. Add Sentry SDK via Swift Package Manager

1. Open `PTPerformance.xcodeproj` in Xcode
2. Go to File > Add Packages
3. Enter URL: `https://github.com/getsentry/sentry-cocoa`
4. Select version: 8.15.0 or later
5. Add to target: PTPerformance

### 2. Configure Sentry DSN

Add your Sentry DSN to the app:

**Option A: Environment Variable (Recommended)**
```bash
export SENTRY_DSN="https://your-dsn@sentry.io/project-id"
```

**Option B: Configuration File**
Create `ios-app/PTPerformance/Config.xcconfig`:
```
SENTRY_DSN = https://your-dsn@sentry.io/project-id
```

**Option C: GitHub Secrets (for CI/CD)**
Add to GitHub repository secrets:
- `SENTRY_DSN`
- `SENTRY_AUTH_TOKEN`

### 3. Initialize Sentry in App

In `PTPerformanceApp.swift`:

```swift
import SwiftUI
import Sentry

@main
struct PTPerformanceApp: App {
    init() {
        // Initialize Sentry
        SentryConfig.shared.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
```

### 4. Set User Context After Authentication

In your authentication handler:

```swift
// After successful login
SentryConfig.shared.setUser(
    userId: user.id.uuidString,
    email: user.email,
    username: "\(user.firstName) \(user.lastName)"
)

// On logout
SentryConfig.shared.clearUser()
```

## Usage

### Automatic Error Tracking

Sentry automatically captures:
- Uncaught exceptions
- App crashes
- Network errors
- Performance issues

### Manual Error Tracking

```swift
// Capture custom error
do {
    try somethingThatMightFail()
} catch {
    SentryConfig.shared.captureError(error, context: [
        "operation": "createProgram",
        "programId": programId.uuidString
    ])
}

// Capture message
SentryConfig.shared.captureMessage(
    "Important event occurred",
    level: .warning
)
```

### Breadcrumbs for User Flow Tracking

```swift
// Track user actions
SentryConfig.shared.addBreadcrumb(
    message: "User viewed program details",
    category: "navigation"
)

SentryConfig.shared.addBreadcrumb(
    message: "User started session logging",
    category: "user.action"
)
```

### Performance Monitoring

```swift
// Track performance of operations
let transaction = SentryConfig.shared.startTransaction(
    name: "Load Patient Programs",
    operation: "db.query"
)

// Perform operation
await loadPrograms()

// Finish transaction
transaction?.finish()
```

### Custom Context

```swift
// Add custom context
SentryConfig.shared.setContext(key: "patient", value: [
    "id": patientId.uuidString,
    "therapist_id": therapistId.uuidString,
    "program_count": programCount
])

// Add tags for filtering
SentryConfig.shared.setTag(key: "user_role", value: "therapist")
SentryConfig.shared.setTag(key: "app_section", value: "program_builder")
```

## Integration with Existing Error Logger

Update `ErrorLogger.swift` to send errors to Sentry:

```swift
extension ErrorLogger {
    func logError(_ error: Error, context: String) {
        // Existing logging
        print("Error in \(context): \(error)")

        // Send to Sentry
        SentryConfig.shared.captureError(error, context: [
            "context": context,
            "timestamp": Date().ISO8601Format()
        ])
    }
}
```

## CI/CD Integration

### Add to GitHub Actions

Update `.github/workflows/ios-testflight-deploy.yml`:

```yaml
- name: Upload Debug Symbols to Sentry
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: your-org
    SENTRY_PROJECT: ptperformance-ios
  run: |
    cd ios-app/PTPerformance

    # Install Sentry CLI
    brew install getsentry/tools/sentry-cli

    # Upload dSYMs
    sentry-cli upload-dif \
      --org $SENTRY_ORG \
      --project $SENTRY_PROJECT \
      PTPerformance.xcarchive/dSYMs
```

## Environment Configuration

### Production
- Environment: `production`
- Sample Rate: 100% (all errors)
- Traces Sample Rate: 20% (performance)

### Staging
- Environment: `staging`
- Sample Rate: 100%
- Traces Sample Rate: 50%

### Development
- Sentry disabled (DEBUG builds)
- Use console logging instead

## Monitoring Best Practices

### 1. Error Alerts
Configure Sentry alerts for:
- New errors
- Error frequency spikes
- Performance degradation
- Crash rate increases

### 2. Error Grouping
Use custom fingerprinting for better error grouping:
```swift
options.beforeSend = { event in
    // Customize error grouping
    event.fingerprint = ["{{ default }}", customIdentifier]
    return event
}
```

### 3. Privacy Considerations
- Never send PHI/PII in error messages
- Filter sensitive data in beforeSend callback
- Use user IDs instead of names/emails

### 4. Performance Budgets
Set performance budgets in Sentry:
- Program load: <500ms
- Database queries: <200ms
- API calls: <1000ms

## Dashboard Setup

### Key Metrics to Monitor
1. **Crash Rate**: < 0.1%
2. **Error Rate**: < 1%
3. **Response Time**: P95 < 500ms
4. **User Satisfaction**: Apdex score > 0.9

### Custom Dashboards
Create dashboards for:
- Therapist workflows
- Patient workflows
- Program builder errors
- Session logging errors
- Authentication issues

## Troubleshooting

### Sentry Not Capturing Errors
1. Check DSN is correct
2. Verify Sentry is initialized before errors occur
3. Check network connectivity
4. Verify sample rate settings

### Too Many Errors
1. Implement rate limiting
2. Filter known issues
3. Use beforeSend to filter noise

### Missing Debug Symbols
1. Ensure dSYM upload in CI/CD
2. Check Sentry CLI authentication
3. Verify project permissions

## Support

- Sentry Documentation: https://docs.sentry.io/platforms/apple/
- Sentry iOS SDK: https://github.com/getsentry/sentry-cocoa
- PTPerformance DevOps Team: devops@example.com
