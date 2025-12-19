# Error Handling Best Practices

**Purpose:** Comprehensive guide for handling errors consistently across PT Performance iOS app to ensure reliability and debuggability.

**Context:** Build 44 had production issues that could have been caught with better error handling. This guide establishes patterns to prevent future issues.

---

## Core Principles

### 1. Fail Fast, Report Everything

Always catch and report errors. Never silently swallow exceptions.

```swift
// ❌ BAD - Silent failure
do {
    try loadPatients()
} catch {
    // Nothing happens - error is lost
}

// ✅ GOOD - Report error
do {
    try await loadPatients()
} catch {
    error.log(context: [
        "operation": "load_patients",
        "user_role": currentUser.role
    ])
    showErrorAlert("Failed to load patients")
}
```

### 2. Provide Context

Include relevant context with every error to aid debugging.

```swift
// ❌ BAD - No context
error.log()

// ✅ GOOD - Rich context
error.log(context: [
    "patient_id": patientId,
    "operation": "fetch_exercise_logs",
    "session_id": sessionId,
    "date_range": "\(startDate) to \(endDate)"
])
```

### 3. Use Appropriate Severity

Match severity to impact on user experience.

```swift
// Fatal - App crashes, data loss
error.log(level: .fatal)

// Error - Feature broken, user blocked
error.log(level: .error)

// Warning - Degraded experience, workaround exists
error.log(level: .warning)

// Info - Notable event, no user impact
ErrorLogger.shared.logUserAction("feature_used")
```

---

## Error Types

### 1. Network Errors

**When:** API calls, file downloads, any network operation

**How to Handle:**
```swift
func fetchPatients() async throws -> [Patient] {
    let url = URL(string: "\(apiBase)/patients")!
    var request = URLRequest(url: url)
    request.httpMethod = "GET"

    do {
        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            // Log error with full context
            let error = NetworkError.httpError(statusCode: httpResponse.statusCode)
            ErrorLogger.shared.logNetworkError(
                request: request,
                response: httpResponse,
                error: error
            )
            throw error
        }

        let patients = try JSONDecoder().decode([Patient].self, from: data)
        return patients

    } catch let error as DecodingError {
        // Schema mismatch - critical!
        ErrorLogger.shared.logDecodingError(
            type: "Patient",
            error: error,
            data: String(data: data, encoding: .utf8)
        )
        throw error

    } catch {
        // General network error
        ErrorLogger.shared.logNetworkError(
            request: request,
            response: nil,
            error: error
        )
        throw error
    }
}
```

**Key Points:**
- Always log network errors with request/response details
- Separate handling for DecodingErrors (schema issues)
- Preserve original error for caller to handle
- Include response body for debugging

---

### 2. Database Errors

**When:** Supabase queries, database operations

**How to Handle:**
```swift
func saveExerciseLog(_ log: ExerciseLog) async throws {
    do {
        // Use PerformanceMonitor to track query duration
        try await PerformanceMonitor.shared.trackDatabaseQuery(
            operation: "insert_exercise_log"
        ) {
            try await supabase
                .from("exercise_logs")
                .insert(log)
                .execute()
        }

    } catch {
        // Log with database context
        ErrorLogger.shared.logDatabaseError(
            operation: "save_exercise_log",
            query: "INSERT INTO exercise_logs",
            error: error
        )
        throw error
    }
}
```

**Key Points:**
- Wrap database operations in performance monitoring
- Log operation name and query details
- Track slow queries automatically (> 1s)
- Never expose sensitive data in logs

---

### 3. Validation Errors

**When:** User input validation, data integrity checks

**How to Handle:**
```swift
func validateWorkoutInput(_ reps: String, _ weight: String) -> ValidationResult {
    // Validate reps
    guard let repsInt = Int(reps), repsInt > 0 else {
        ErrorLogger.shared.logValidationError(
            field: "reps",
            value: reps,
            reason: "Must be positive integer"
        )
        return .failure(message: "Reps must be a positive number")
    }

    // Validate weight
    guard let weightDouble = Double(weight), weightDouble >= 0 else {
        ErrorLogger.shared.logValidationError(
            field: "weight",
            value: weight,
            reason: "Must be non-negative number"
        )
        return .failure(message: "Weight must be a number")
    }

    return .success
}

enum ValidationResult {
    case success
    case failure(message: String)
}
```

**Key Points:**
- Log validation failures for analytics
- Don't expose internal field names to users
- Use warning level (not error) for validation
- Track validation patterns to improve UX

---

### 4. Schema Mismatches (CRITICAL)

**When:** DecodingError from API responses or database queries

**How to Handle:**
```swift
do {
    let patients = try JSONDecoder().decode([Patient].self, from: data)
    return patients

} catch let error as DecodingError {
    // This is CRITICAL - schema mismatch means validation failed!
    ErrorLogger.shared.logDecodingError(
        type: "Patient",
        error: error,
        data: String(data: data, encoding: .utf8)?.prefix(500)  // First 500 chars
    )

    // Extract specific field that caused issue
    switch error {
    case .keyNotFound(let key, _):
        print("Missing key: \(key.stringValue)")
    case .typeMismatch(let type, let context):
        print("Type mismatch at \(context.codingPath): expected \(type)")
    default:
        break
    }

    throw error
}
```

**Why This is Critical:**
- Schema mismatches cause Build 44-style production bugs
- These should NEVER happen if schema validation is run
- Marked as `.fatal` in Sentry for immediate attention
- Indicates iOS model and database are out of sync

**Prevention:**
- Run `python3 scripts/validate_ios_schema.py` before every deployment
- Schema validation CI/CD blocks merges with mismatches
- Never skip validation checks

---

## Performance Monitoring

### Track View Load Times

```swift
struct PatientListView: View {
    var body: some View {
        List {
            // ... view content
        }
        .trackViewLoad("PatientListView")  // Automatic tracking!
    }
}

// Or manual tracking for more control
struct CustomView: View {
    var body: some View {
        VStack {
            // ... content
        }
        .task {
            PerformanceMonitor.shared.startViewLoad("CustomView")
        }
        .onAppear {
            PerformanceMonitor.shared.finishViewLoad("CustomView")
        }
    }
}
```

**Thresholds:**
- ✅ Good: < 2 seconds
- ⚠️ Warning: 2-4 seconds (logged automatically)
- 🔴 Poor: > 4 seconds (requires optimization)

---

### Track Database Operations

```swift
func fetchSessions(for patientId: String) async throws -> [Session] {
    return try await PerformanceMonitor.shared.trackDatabaseQuery(
        operation: "fetch_sessions"
    ) {
        try await supabase
            .from("sessions")
            .select()
            .eq("patient_id", value: patientId)
            .execute()
            .value
    }
}
```

**Benefits:**
- Automatic duration tracking
- Slow query warnings (> 1s)
- Performance trends in Sentry
- Helps identify optimization opportunities

---

### Track Network Requests

```swift
func fetchData() async throws -> Data {
    return try await PerformanceMonitor.shared.trackNetworkRequest(
        url: "/api/patients",
        method: "GET"
    ) {
        let (data, _) = try await URLSession.shared.data(for: request)
        return data
    }
}
```

**Thresholds:**
- ✅ Good: < 3 seconds
- ⚠️ Warning: 3-5 seconds (logged automatically)
- 🔴 Poor: > 5 seconds (requires investigation)

---

### Track Memory Usage

```swift
// Log memory usage at critical points
func loadLargeDataset() {
    // Before
    PerformanceMonitor.shared.logMemoryUsage()

    // Load data
    let data = heavyOperation()

    // After
    PerformanceMonitor.shared.logMemoryUsage()
}
```

**Thresholds:**
- ✅ Normal: < 250 MB
- ⚠️ Warning: 250-500 MB
- 🔴 High: > 500 MB (logged automatically)

---

## User Context

Always set user context after authentication:

```swift
// After successful login
func handleLogin(userId: String, role: UserRole) {
    // Update app state (automatically updates Sentry)
    appState.isAuthenticated = true
    appState.userId = userId
    appState.userRole = role

    // Sentry user context is automatically updated via AppState.updateUserContext()
}

// On logout
func handleLogout() {
    appState.isAuthenticated = false
    appState.userId = nil
    appState.userRole = nil

    // Sentry user context automatically cleared
}
```

**Why This Matters:**
- Errors are attributed to specific user types
- Can filter issues by patient vs therapist
- Helps identify user-specific problems
- Privacy-safe (no email/PII tracked)

---

## Custom Tags

Use tags to categorize and filter errors:

```swift
// Set environment tag
ErrorLogger.shared.setTag(key: "environment", value: "production")

// Set feature tag
ErrorLogger.shared.setTag(key: "feature", value: "workout_logging")

// Set version tag (automatic in app init)
ErrorLogger.shared.setTag(key: "build", value: "44")
```

**Common Tags:**
- `environment`: production, staging, development
- `feature`: workout_logging, patient_management, etc.
- `user_type`: patient, therapist
- `screen`: current screen name
- `release`: version number

---

## Error Recovery

### Graceful Degradation

```swift
func loadPatientData() async {
    do {
        let patients = try await fetchPatients()
        self.patients = patients

    } catch {
        error.log(context: ["operation": "load_patients"])

        // Show error to user
        self.errorMessage = "Failed to load patients. Please try again."

        // Graceful degradation - use cached data if available
        if let cachedPatients = cache.patients {
            self.patients = cachedPatients
            self.showingCachedData = true
        }
    }
}
```

### Retry Logic

```swift
func fetchWithRetry<T>(
    operation: String,
    maxRetries: Int = 3,
    work: @escaping () async throws -> T
) async throws -> T {
    var lastError: Error?

    for attempt in 1...maxRetries {
        do {
            let result = try await work()

            // Log successful retry
            if attempt > 1 {
                ErrorLogger.shared.logUserAction(
                    action: "retry_succeeded",
                    properties: [
                        "operation": operation,
                        "attempt": attempt
                    ]
                )
            }

            return result

        } catch {
            lastError = error

            // Log retry attempt
            if attempt < maxRetries {
                ErrorLogger.shared.log(
                    error,
                    context: [
                        "operation": operation,
                        "retry_attempt": attempt,
                        "max_retries": maxRetries
                    ],
                    level: .warning
                )

                // Exponential backoff
                try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
            }
        }
    }

    // All retries failed
    if let error = lastError {
        error.log(context: [
            "operation": operation,
            "attempts": maxRetries,
            "result": "all_retries_failed"
        ])
        throw error
    }

    fatalError("Unreachable")
}

// Usage
let patients = try await fetchWithRetry(operation: "fetch_patients") {
    try await supabase.from("patients").select().execute().value
}
```

---

## Testing Error Handling

### Simulate Network Errors

```swift
#if DEBUG
func simulateNetworkError() throws {
    if shouldSimulateError {
        throw NetworkError.connectionLost
    }
}
#endif
```

### Test Error Logging

```swift
func testErrorLogging() {
    let error = NSError(domain: "Test", code: 123)

    ErrorLogger.shared.log(
        error,
        context: ["test": "error_logging"],
        level: .error
    )

    // Check Sentry dashboard to verify error appears
}
```

### Verify Performance Tracking

```swift
func testPerformanceTracking() async {
    await PerformanceMonitor.shared.trackOperation(
        name: "test_operation",
        category: "test"
    ) {
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    // Check Sentry performance dashboard for transaction
}
```

---

## Checklist: Before Every Deployment

- [ ] Run schema validation: `python3 scripts/validate_ios_schema.py`
- [ ] No fatal errors in local testing
- [ ] Error logging tested for new features
- [ ] Performance monitoring added for new views
- [ ] User context properly set after auth
- [ ] Validation errors logged appropriately
- [ ] Network errors include request/response context
- [ ] Database errors include operation details
- [ ] No sensitive data in error logs
- [ ] Sentry release created for version tracking

---

## Common Mistakes

### ❌ Mistake 1: Silent Failures

```swift
// BAD
do {
    try await saveData()
} catch {
    print("Error: \(error)")  // Only logs to console, not tracked
}
```

**Fix:**
```swift
// GOOD
do {
    try await saveData()
} catch {
    error.log(context: ["operation": "save_data"])
    showErrorToUser()
}
```

---

### ❌ Mistake 2: Missing Context

```swift
// BAD
error.log()  // No context
```

**Fix:**
```swift
// GOOD
error.log(context: [
    "view": "PatientListView",
    "patient_id": patientId,
    "action": "load_exercises"
])
```

---

### ❌ Mistake 3: Wrong Severity

```swift
// BAD - Using .error for validation issue
ErrorLogger.shared.log(validationError, level: .error)
```

**Fix:**
```swift
// GOOD - Validation issues are warnings
ErrorLogger.shared.log(validationError, level: .warning)
```

---

### ❌ Mistake 4: Exposing Sensitive Data

```swift
// BAD
error.log(context: [
    "password": userPassword,  // Never log passwords!
    "email": userEmail,        // Avoid PII
    "ssn": patientSSN          // Never log sensitive data
])
```

**Fix:**
```swift
// GOOD
error.log(context: [
    "user_id": userId,         // Use IDs instead
    "user_role": role          // Generic info only
])
```

---

### ❌ Mistake 5: Not Using Performance Tracking

```swift
// BAD
func fetchData() async throws {
    try await heavyOperation()
}
```

**Fix:**
```swift
// GOOD
func fetchData() async throws {
    try await PerformanceMonitor.shared.trackDatabaseQuery(
        operation: "fetch_data"
    ) {
        try await heavyOperation()
    }
}
```

---

## Quick Reference

### Error Logging

```swift
// General error
error.log(context: ["operation": "..."], level: .error)

// Network error
ErrorLogger.shared.logNetworkError(request: req, response: resp, error: error)

// Database error
ErrorLogger.shared.logDatabaseError(operation: "...", error: error)

// Validation error
ErrorLogger.shared.logValidationError(field: "...", value: "...", reason: "...")

// Decoding error (schema mismatch)
ErrorLogger.shared.logDecodingError(type: "ModelName", error: error, data: "...")
```

### Performance Tracking

```swift
// View load (automatic)
.trackViewLoad("ViewName")

// Database query
try await PerformanceMonitor.shared.trackDatabaseQuery(operation: "...") { ... }

// Network request
try await PerformanceMonitor.shared.trackNetworkRequest(url: "...", method: "GET") { ... }

// Custom operation
try await PerformanceMonitor.shared.trackOperation(name: "...", category: "...") { ... }

// Memory usage
PerformanceMonitor.shared.logMemoryUsage()
```

### User Context

```swift
// Set user (automatic via AppState)
appState.userId = "123"
appState.userRole = .patient

// Clear user (automatic on logout)
appState.userId = nil
```

---

## Related Documentation

- [Monitoring Dashboard Guide](./MONITORING_DASHBOARD.md)
- [Schema Validation Guide](./SCHEMA_VALIDATION.md)
- [Performance Optimization](./PERFORMANCE_OPTIMIZATION.md)

---

## Support

**Questions:** Create Linear issue with label `error-handling`

**Bugs:** Report via Sentry dashboard or Linear with label `bug`

**Improvements:** Submit PR with updates to this guide

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 5 (Error Monitoring Engineer)
