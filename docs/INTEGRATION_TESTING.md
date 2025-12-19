# Integration Testing Guide

**Purpose:** Comprehensive guide for running and maintaining integration tests for PT Performance iOS app.

**Context:** Build 45 introduced integration tests to catch issues before production deployment. These tests validate critical user flows, schema compatibility, and performance baselines.

---

## Quick Start

### Run All Integration Tests

```bash
# From Xcode
# 1. Open PTPerformance.xcodeproj
# 2. Press Cmd+U to run all tests
# Or: Product → Test

# From command line
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Run Specific Test Suite

```bash
# Run only integration tests
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -only-testing:PTPerformanceTests/CriticalPathTests

# Run only performance benchmarks
xcodebuild test \
  -only-testing:PTPerformanceTests/PerformanceBenchmarkTests
```

---

## Test Suites Overview

### 1. SupabaseIntegrationTests

**Purpose:** Validate Supabase connectivity and basic operations

**What It Tests:**
- Supabase client initialization
- Database URL configuration
- Demo user authentication (patient & therapist)
- Basic table accessibility
- Simple queries

**Critical Tests:**
- ✅ `testDemoPatientLogin` - Patient can authenticate
- ✅ `testDemoTherapistLogin` - Therapist can authenticate
- ✅ `testPatientsTableAccessible` - RLS allows patient table access
- ✅ `testSessionsTableAccessible` - Sessions table accessible

**When to Run:** Before every deployment

---

### 2. CriticalPathTests

**Purpose:** Validate complete user workflows end-to-end

**What It Tests:**
- Complete patient flow: login → load program → view session → log exercise
- Complete therapist flow: login → view patients → view programs
- Table relationships and data integrity
- Schema validation (no decoding errors)

**Critical Tests:**
- ✅ `testPatientCompleteFlow` - Full patient experience works
- ✅ `testTherapistCompleteFlow` - Full therapist experience works
- ✅ `testNoSchemaMismatches` - All models decode correctly
- ✅ `testTableRelationships` - Foreign keys work correctly

**When to Run:**
- Before every deployment
- After schema changes
- After model updates

**⚠️ DEPLOYMENT BLOCKERS:**
If any of these tests fail, **DO NOT DEPLOY**. These tests validate critical user flows.

---

### 3. PerformanceBenchmarkTests

**Purpose:** Establish performance baselines and catch regressions

**What It Tests:**
- Authentication performance (< 3s)
- Simple query performance (< 1s)
- Complex query performance (< 2s)
- Batch operation performance
- Memory usage under load
- Concurrent query optimization

**Performance Thresholds:**
- Login: < 3.0s
- Simple queries: < 1.0s
- Complex queries (joins): < 2.0s
- View load: < 2.0s

**Critical Tests:**
- ✅ `testPatientLoginPerformance` - Login meets SLA
- ✅ `testComplexQueryPerformance` - Joins are optimized
- ✅ `testOverallPerformanceBaseline` - No regression vs baseline

**When to Run:**
- Weekly performance check
- Before major releases
- After database optimizations

---

## Test Infrastructure

### IntegrationTestBase

All integration tests inherit from `IntegrationTestBase`, which provides:

**Authentication Helpers:**
```swift
// Login as demo patient
let session = try await loginAsPatient()

// Login as demo therapist
let session = try await loginAsTherapist()

// Sign out
try await signOut()
```

**Query Helpers:**
```swift
// Execute query with performance tracking
let result = try await executeQuery("operation_name", table: "patients") {
    try await supabase.client.from("patients").select().execute().value
}

// Fetch by ID
let patient: Patient = try await fetchById(table: "patients", id: "123")
```

**Assertion Helpers:**
```swift
// Assert table is accessible
try await assertTableAccessible("patients")

// Assert query meets performance threshold
try await assertQueryPerformance("fetch_patients", threshold: 1.0) {
    try await loadPatients()
}

// Assert no schema mismatch
assertNoSchemaMismatch()
```

**Test Data Cleanup:**
```swift
// Track created data for automatic cleanup
trackCreatedPatient(patientId)
trackCreatedProgram(programId)
trackCreatedSession(sessionId)

// Cleanup happens automatically in tearDown()
```

---

## Running Tests

### Prerequisites

1. **Demo Users Must Exist**
   - Patient: `nic.roma+patient@gmail.com`
   - Therapist: `nic.roma+therapist@gmail.com`
   - Both with password: `TestPassword123!`

2. **Database Must Be Accessible**
   - Supabase URL configured in `Config.swift`
   - Network connectivity available
   - RLS policies allow test access

3. **Test Data Seeded**
   - At least one active program exists
   - Programs have phases
   - Phases have sessions
   - Sessions have exercises

### Run Tests Locally

**From Xcode:**
1. Open `PTPerformance.xcodeproj`
2. Select iPhone simulator (any model)
3. Press `Cmd+U` or Product → Test
4. View results in Test Navigator (Cmd+6)

**From Terminal:**
```bash
# Run all tests
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
  | xcpretty

# Run only integration tests (faster)
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -only-testing:PTPerformanceTests \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

---

## Continuous Integration

### GitHub Actions Integration

Tests run automatically on:
- Every pull request to `main`
- Every push to `main`
- Manual workflow dispatch

**Workflow:** `.github/workflows/ios-tests.yml`

**What It Does:**
1. Checks out code
2. Sets up Xcode environment
3. Runs schema validation
4. Runs integration tests
5. Uploads test results as artifacts
6. Posts results as PR comment

**Required Secrets:**
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_ANON_KEY` - Public anon key
- `SUPABASE_DB_URL` - Database connection string (for schema validation)

---

## Test Data Management

### Demo Users

**Patient:**
- Email: `nic.roma+patient@gmail.com`
- Password: `TestPassword123!`
- Role: Patient
- Should have: Active program with sessions

**Therapist:**
- Email: `nic.roma+therapist@gmail.com`
- Password: `TestPassword123!`
- Role: Therapist
- Should have: Assigned patients

### Test Data Requirements

**Minimum Data:**
```sql
-- At least 1 patient with active program
INSERT INTO patients (id, first_name, last_name, therapist_id)
VALUES ('...', 'Nic', 'Roma', '...');

-- At least 1 active program
INSERT INTO programs (id, patient_id, name, status)
VALUES ('...', '...', 'Winter Lift', 'active');

-- At least 1 phase
INSERT INTO phases (id, program_id, name, sequence)
VALUES ('...', '...', 'Phase 1', 1);

-- At least 1 session
INSERT INTO sessions (id, phase_id, name, sequence)
VALUES ('...', '...', 'Session 1', 1);

-- At least 1 exercise
INSERT INTO exercises (id, session_id, name, order_index)
VALUES ('...', '...', 'Squat', 1);
```

**Seed Script:** `supabase/seed.sql`

---

## Troubleshooting

### Test Failures

#### "Authentication failed"

**Cause:** Demo users don't exist or credentials are wrong

**Fix:**
```sql
-- Create demo patient user
-- (Run in Supabase SQL Editor)
-- Note: Users created via auth.users, then profiles in patients table
```

Verify credentials in `Config.swift`:
```swift
enum Demo {
    static let patientEmail = "nic.roma+patient@gmail.com"
    static let patientPassword = "TestPassword123!"
    static let therapistEmail = "nic.roma+therapist@gmail.com"
    static let therapistPassword = "TestPassword123!"
}
```

---

#### "No active programs found"

**Cause:** Test data not seeded

**Fix:**
```bash
# Seed database
supabase db reset  # Caution: drops all data!
# Or manually insert test data
```

---

#### "Cannot access table 'patients'"

**Cause:** RLS policies too restrictive

**Fix:**
1. Check RLS policies allow authenticated users
2. Verify user is authenticated before query
3. Check user role has permission

---

#### "Schema mismatch detected"

**Cause:** Swift model doesn't match database schema

**Fix:**
```bash
# Run schema validation
python3 scripts/validate_ios_schema.py --verbose

# Fix any reported mismatches
# See SCHEMA_VALIDATION.md for details
```

---

#### "Query timeout"

**Cause:** Network issue or slow database

**Fix:**
1. Check network connectivity
2. Check Supabase dashboard for issues
3. Increase timeout threshold temporarily
4. Optimize query if consistently slow

---

#### "Test passes locally but fails in CI"

**Cause:** Environment differences

**Common Issues:**
- CI uses different database (staging vs production)
- Test data exists locally but not in CI
- Network restrictions in CI environment
- Secrets not configured correctly

**Fix:**
1. Verify CI secrets are set correctly
2. Check CI logs for specific error
3. Run tests against same database as CI
4. Ensure test data seeded in CI database

---

## Performance Testing

### Running Benchmarks

```bash
# Run performance benchmarks
xcodebuild test \
  -only-testing:PTPerformanceTests/PerformanceBenchmarkTests
```

### Interpreting Results

**Output Format:**
```
⏱️ Benchmarking: Patient Login Performance
  Iteration 1: 2.145s
  Iteration 2: 1.987s
  Iteration 3: 2.034s
  Iteration 4: 2.112s
  Iteration 5: 2.056s

📊 Results:
  Average: 2.067s
  Min: 1.987s
  Max: 2.145s
  Threshold: 3.000s

✅ Login performance within threshold
```

**What to Look For:**
- ✅ Average < Threshold: Performance is good
- ⚠️ Average close to threshold: Monitor for regression
- ❌ Average > Threshold: Performance degraded - investigate!

### Performance Regression

If benchmarks fail:
1. Check Sentry for slow operations in production
2. Review recent code changes (git blame)
3. Check database query explain plans
4. Look for N+1 query patterns
5. Consider adding indexes

---

## Best Practices

### 1. Keep Tests Fast

- Use `limit(1)` when possible
- Don't test exhaustively (sample data is enough)
- Mock slow external services
- Run expensive tests less frequently

### 2. Keep Tests Isolated

- Each test should be independent
- Use `setUp()` and `tearDown()` properly
- Clean up test data
- Don't assume test execution order

### 3. Keep Tests Readable

- Use descriptive test names
- Add comments explaining why, not what
- Use helper methods from `IntegrationTestBase`
- Print progress for long-running tests

### 4. Keep Tests Maintainable

- Update tests when features change
- Remove tests for deprecated features
- Refactor common patterns into base class
- Document complex test setup

---

## Writing New Tests

### Template

```swift
import XCTest
@testable import PTPerformance

@MainActor
final class MyNewTests: IntegrationTestBase {

    func testMyFeature() async throws {
        print("\n🧪 Testing: My Feature")
        print("="*80)

        // Step 1: Setup
        _ = try await loginAsPatient()

        // Step 2: Execute operation
        try await assertQueryPerformance("my_operation", threshold: 1.0) {
            // Your test code here
        }

        // Step 3: Assertions
        XCTAssertTrue(condition, "Failure message")

        // Step 4: Cleanup
        try await signOut()

        print("✅ Test passed")
    }
}
```

### Checklist

- [ ] Test name describes what it tests
- [ ] Uses `IntegrationTestBase` helpers
- [ ] Prints progress with emoji markers
- [ ] Has clear failure messages
- [ ] Cleans up test data
- [ ] Signs out after test
- [ ] Has performance threshold if applicable
- [ ] Logs errors to Sentry for debugging

---

## Related Documentation

- [Schema Validation Guide](./SCHEMA_VALIDATION.md)
- [Error Handling Best Practices](./ERROR_HANDLING.md)
- [Monitoring Dashboard Guide](./MONITORING_DASHBOARD.md)
- [Migration Testing Guide](./MIGRATION_TESTING.md)

---

## Support

**Failed Tests:** Create Linear issue with label `test-failure`

**New Test Requests:** Create Linear issue with label `test-coverage`

**CI Issues:** Check GitHub Actions logs or create issue with label `ci-cd`

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 2 (Integration Testing Engineer)
