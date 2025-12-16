# Build 47: Manual Xcode Configuration Steps

**Date:** 2025-12-15
**Required Before:** TestFlight Upload
**Estimated Time:** 15-20 minutes

---

## Overview

Build 47 introduces ErrorLogger and PerformanceMonitor infrastructure classes, but these files (along with ChartData.swift from Build 46) need to be manually added to the Xcode project target. This cannot be done via command line without risking project file corruption.

---

## Step 1: Add New Swift Files to Xcode Project

### Files to Add (3 files):

1. **ErrorLogger.swift**
   - Location: `Services/ErrorLogger.swift`
   - Purpose: Centralized error logging with future Sentry integration
   - Target: PTPerformance (main app)

2. **PerformanceMonitor.swift**
   - Location: `Services/PerformanceMonitor.swift`
   - Purpose: App performance tracking (launch time, view loads, database queries, network requests)
   - Target: PTPerformance (main app)

3. **ChartData.swift** (from Build 46)
   - Location: `Models/ChartData.swift`
   - Purpose: Chart data models for analytics (VolumeChartData, StrengthChartData, ConsistencyChartData, TimePeriod)
   - Target: PTPerformance (main app)

### How to Add Files:

1. Open `/Users/expo/Code/expo/ios-app/PTPerformance/PTPerformance.xcodeproj` in Xcode
2. In the Project Navigator (left sidebar), locate each file
3. **If the file appears grayed out or with a red text color:**
   - Right-click the file → Get Info
   - In the Target Membership section, check "PTPerformance"
   - Click outside the inspector to save
4. **If the file doesn't appear in Xcode at all:**
   - Right-click the appropriate folder (Services/ or Models/)
   - Select "Add Files to 'PTPerformance'..."
   - Navigate to the file location
   - **IMPORTANT:** Check "Copy items if needed" is UNCHECKED
   - **IMPORTANT:** Check "Add to targets: PTPerformance"
   - Click "Add"

5. Verify the file is now included:
   - Select the file in Project Navigator
   - Open File Inspector (⌘⌥1)
   - Verify "Target Membership" shows PTPerformance is checked

---

## Step 2: Uncomment Code After Adding Files

### After adding ErrorLogger.swift and PerformanceMonitor.swift:

**File:** `PTPerformanceApp.swift`

1. **Lines 50-65** - App initialization:
```swift
// BEFORE:
// TODO: Uncomment once ErrorLogger.swift and PerformanceMonitor.swift are added to Xcode project
/*
// Track app launch performance
PerformanceMonitor.shared.trackAppLaunch()
...
*/

// AFTER:
// Track app launch performance
PerformanceMonitor.shared.trackAppLaunch()

// Log app startup
ErrorLogger.shared.logUserAction(
    action: "app_launched",
    properties: [
        "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
        "build": Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "unknown",
        "device": UIDevice.current.model,
        "os_version": UIDevice.current.systemVersion
    ]
)
```

2. **Lines 73-74** - App launch finish:
```swift
// BEFORE:
// TODO: Uncomment once PerformanceMonitor.swift is added to Xcode project
// PerformanceMonitor.shared.finishAppLaunch()

// AFTER:
PerformanceMonitor.shared.finishAppLaunch()
```

3. **Lines 99-120** - User context tracking:
```swift
// BEFORE:
// TODO: Uncomment once ErrorLogger.swift is added to Xcode project
/*
if isAuthenticated, let userId = userId {
    ErrorLogger.shared.setUser(...)
    ...
}
*/

// AFTER:
if isAuthenticated, let userId = userId {
    // Set user context for error tracking
    ErrorLogger.shared.setUser(
        userId: userId,
        email: nil, // Don't track email for privacy
        userType: userRole?.rawValue ?? "unknown"
    )

    // Log authentication event
    ErrorLogger.shared.logUserAction(
        action: "user_authenticated",
        properties: [
            "user_role": userRole?.rawValue ?? "unknown"
        ]
    )
} else {
    // Clear user context on logout
    ErrorLogger.shared.clearUser()
}
```

**File:** `Services/AnalyticsService.swift`

**Line 72-73:**
```swift
// BEFORE:
// TODO: Uncomment once ErrorLogger.swift is added to Xcode project target
// private let errorLogger = ErrorLogger.shared

// AFTER:
private let errorLogger = ErrorLogger.shared
```

### After adding ChartData.swift:

**File:** `Services/AnalyticsService.swift`

**Lines 153-381** - Uncomment all Build 46 analytics methods:
```swift
// BEFORE:
// TODO: Add ChartData.swift to Xcode project target to enable these methods
/*
/// Calculate volume data for a time period
func calculateVolumeData(...)
...
*/

// AFTER:
/// Calculate volume data for a time period
func calculateVolumeData(
    for patientId: String,
    period: TimePeriod
) async throws -> VolumeChartData {
    // ... implementation
}

/// Calculate strength progression for a specific exercise
func calculateStrengthData(...) async throws -> StrengthChartData {
    // ... implementation
}

/// Calculate workout consistency over time
func calculateConsistencyData(...) async throws -> ConsistencyChartData {
    // ... implementation
}

private func calculateCurrentStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
    // ... implementation
}

private func calculateLongestStreak(from dataPoints: [ConsistencyDataPoint]) -> Int {
    // ... implementation
}
```

---

## Step 3: Fix SessionSummaryView.swift Target Membership

### Problem:
`SessionSummaryView.swift` is incorrectly added to both PTPerformance AND PTPerformanceUITests targets, causing compilation errors when running tests.

### Fix:

1. In Xcode Project Navigator, locate:
   - `Views/Patient/SessionSummaryView.swift`

2. Select the file

3. Open File Inspector (⌘⌥1)

4. In "Target Membership" section:
   - ✅ PTPerformance should be CHECKED
   - ❌ PTPerformanceUITests should be UNCHECKED

5. Verify: Build the project and ensure no errors

---

## Step 4: Add Sentry SDK (Optional but Recommended)

### Why Add Sentry:
- Production error monitoring
- Performance tracking
- Crash reporting
- User session replay

### How to Add:

1. In Xcode, select the project in Project Navigator
2. Select the PTPerformance target
3. Go to "Package Dependencies" tab
4. Click the "+" button
5. Enter: `https://github.com/getsentry/sentry-cocoa`
6. Click "Add Package"
7. Select "Sentry" library
8. Click "Add Package"

### After Adding Sentry:

**File:** `PTPerformanceApp.swift`

**Lines 10-48** - Uncomment Sentry initialization:
```swift
// BEFORE:
// TODO: Re-enable Sentry initialization once package is added
/*
import Sentry
...
SentrySDK.start { options in
    ...
}
*/

// AFTER:
import Sentry

...

SentrySDK.start { options in
    #if DEBUG
    options.dsn = "" // Leave empty for debug builds
    options.debug = true
    options.environment = "development"
    #else
    // Production DSN should be injected via build configuration
    options.dsn = ProcessInfo.processInfo.environment["SENTRY_DSN"] ?? ""
    options.environment = "production"
    #endif

    options.tracesSampleRate = 1.0
    options.enableAutoSessionTracking = true
    options.enableAutoBreadcrumbTracking = true
    options.attachStacktrace = true

    if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
       let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
        options.releaseName = "\(version) (\(build))"
    }

    options.beforeSend = { event in
        // Remove any sensitive data from event
        return event
    }
}
```

**Files:** `Services/ErrorLogger.swift` and `Services/PerformanceMonitor.swift`

Uncomment all Sentry-related code sections marked with:
```swift
// TODO: When Sentry is added, [action]
/*
SentrySDK...
*/
```

---

## Step 5: Verify Build

### After completing all steps above:

1. **Clean Build Folder:** Product menu → Clean Build Folder (⇧⌘K)
2. **Build:** Product menu → Build (⌘B)
3. **Verify:** Build succeeds with 0 errors, 0 warnings
4. **Run Tests:** Product menu → Test (⌘U)
5. **Verify:** All tests pass

---

## Step 6: TestFlight Preparation

### After successful build and tests:

1. **Update Version/Build Number** (if needed):
   - Already set to build 47 in Config.swift

2. **Archive the App:**
   - Product menu → Archive
   - Wait for archive to complete
   - Organizer window will appear

3. **Distribute to TestFlight:**
   - Click "Distribute App"
   - Select "App Store Connect"
   - Click "Upload"
   - Select signing certificate
   - Click "Upload"

4. **Submit for Review:**
   - Go to App Store Connect
   - Select PTPerformance app
   - Go to TestFlight tab
   - Select build 47
   - Add "What to Test" notes
   - Submit for Beta Review

---

## Checklist Summary

- [ ] Add ErrorLogger.swift to PTPerformance target
- [ ] Add PerformanceMonitor.swift to PTPerformance target
- [ ] Add ChartData.swift to PTPerformance target
- [ ] Uncomment ErrorLogger/PerformanceMonitor code in PTPerformanceApp.swift
- [ ] Uncomment errorLogger in AnalyticsService.swift
- [ ] Uncomment Build 46 analytics methods in AnalyticsService.swift
- [ ] Fix SessionSummaryView.swift target membership (remove from UITests)
- [ ] (Optional) Add Sentry SDK package dependency
- [ ] (Optional) Uncomment Sentry initialization code
- [ ] Clean build folder
- [ ] Build project (⌘B) - verify 0 errors
- [ ] Run tests (⌘U) - verify all pass
- [ ] Archive for TestFlight
- [ ] Upload to App Store Connect
- [ ] Submit for Beta Review

---

## Expected Results

**After completing all steps:**

✅ Build 47 app builds successfully
✅ ErrorLogger tracks user actions and errors
✅ PerformanceMonitor tracks app launch time and view loads
✅ Build 46 analytics (volume, strength, consistency charts) are enabled
✅ Integration tests run successfully
✅ App is ready for TestFlight distribution

**Key Features Enabled:**

1. **Error Tracking** - All errors logged with context, user ID, and stack traces
2. **Performance Monitoring** - App launch time, view load times, database query performance
3. **Analytics Charts** - Volume, strength progression, consistency tracking over time
4. **Better Debugging** - Comprehensive logging for troubleshooting production issues

---

## Troubleshooting

### "Cannot find 'ErrorLogger' in scope"
- Verify ErrorLogger.swift is added to PTPerformance target
- Clean build folder (⇧⌘K) and rebuild

### "Cannot find type 'VolumeChartData' in scope"
- Verify ChartData.swift is added to PTPerformance target
- Clean build folder and rebuild

### Tests fail with "Cannot find type 'Session'"
- Verify SessionSummaryView.swift is NOT in PTPerformanceUITests target
- It should only be in PTPerformance target

### Sentry not working
- Verify Sentry package is added via Swift Package Manager
- Verify DSN is set in environment or code
- Check Xcode console for Sentry initialization messages

---

**Document Created:** 2025-12-15
**For Build:** 47
**Next Steps:** Complete checklist → TestFlight upload
