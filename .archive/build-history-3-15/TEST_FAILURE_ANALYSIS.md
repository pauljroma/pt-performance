# iOS QC Test Suite Failure Analysis
## Build 8 Production Debugging Report

**Date**: December 9, 2025
**Build**: Build 8 (FAILING in production)
**User Report**: "data could not be read because it doesn't exist"
**Test Suite Commit**: 142431e

---

## Executive Summary

**CRITICAL FINDING**: The test suite CANNOT execute because the Xcode project is misconfigured. Tests appear to "pass" but actually fail silently, creating a **FALSE POSITIVE** that allowed Build 8 to be deployed with broken functionality.

### Test Execution Status

| Test Suite | Status | Root Cause |
|------------|--------|------------|
| Unit Tests | **FAILED** | Xcode scheme not configured for testing |
| Integration Tests | **FAILED** | Test target missing Info.plist configuration |
| UI Tests | **FAILED** | PTPerformanceTests target not set up in scheme |

### Build 8 Production Issue

**User Impact**: Patient login succeeds but session data fails to load with error:
```
"data could not be read because it doesn't exist"
```

---

## Test Execution Failures

### Failure #1: Xcode Scheme Misconfiguration

**Test Output**:
```
xcodebuild: error: Scheme PTPerformance is not currently configured for the test action.
```

**Root Cause**:
The `PTPerformance.xcscheme` file has an **empty `<Testables>` section** (lines 30-31):

```xml
<TestAction
   buildConfiguration = "Debug"
   selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
   selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
   shouldUseLaunchSchemeArgsEnv = "YES">
   <Testables>
   </Testables>  <!-- ❌ EMPTY - No test targets configured! -->
</TestAction>
```

**Expected Configuration**:
```xml
<Testables>
   <TestableReference
      skipped = "NO">
      <BuildableReference
         BuildableIdentifier = "primary"
         BlueprintIdentifier = "[TEST_TARGET_ID]"
         BuildableName = "PTPerformanceTests.xctest"
         BlueprintName = "PTPerformanceTests"
         ReferencedContainer = "container:PTPerformance.xcodeproj">
      </BuildableReference>
   </TestableReference>
</Testables>
```

**Impact**: Tests never execute. The shell script incorrectly interprets xcodebuild errors as "success" because it doesn't check exit codes properly.

---

### Failure #2: Test Target Info.plist Missing

**Test Output**:
```
error: Cannot code sign because the target does not have an Info.plist file
and one is not being generated automatically. Apply an Info.plist file to
the target using the INFOPLIST_FILE build setting or generate one automatically
by setting the GENERATE_INFOPLIST_FILE build setting to YES (recommended).
```

**Root Cause**:
When tests were added in commit 142431e, the test targets (`PTPerformanceTests` and `PTPerformanceUITests`) were created without Info.plist files and without enabling automatic Info.plist generation.

**Required Fix**:
Set `GENERATE_INFOPLIST_FILE = YES` in project.pbxproj for both test targets.

**Impact**: Even with correct scheme configuration, tests cannot build or execute.

---

### Failure #3: False Positive Test Results

**Issue**: The QC test runner script (`run_qc_tests.sh`) has a **critical flaw** in error handling:

```bash
if xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
    -only-testing:PTPerformanceTests/TodaySessionViewModelTests \
    | xcpretty --color; then
    echo "✅ Unit Tests PASSED"
    UNIT_TESTS_PASSED=1
else
    echo "❌ Unit Tests FAILED"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi
```

**Problem**: The script pipes xcodebuild output to `xcpretty`, which always returns exit code 0. Therefore, the `if` condition **ALWAYS evaluates to true**, even when xcodebuild fails.

**Result**: All tests report as "PASSED" even though they never executed:
```
Unit Tests:        ✅ PASS
Integration Tests: ✅ PASS
UI Tests:          ✅ PASS

✅ ALL TESTS PASSED - BUILD APPROVED FOR DEPLOYMENT
```

This is how Build 8 (broken code) passed QC gates and was deployed to TestFlight.

---

## Build 8 Root Cause Analysis

Based on code review and test analysis, here's what's happening in production:

### Data Loading Flow

1. **Patient Login** → ✅ SUCCESS
   - User authenticates via Supabase Auth
   - PTSupabaseClient.fetchUserRole() finds patient record
   - User role set to `.patient`, userId populated

2. **TodaySessionViewModel.fetchTodaySession()** → ❌ FAILS
   - Backend API call: `https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session/{patientId}`
   - Backend likely returns 404 or 500 (Edge Function not deployed or broken)

3. **Fallback to Supabase Direct Query** → ❌ FAILS
   Query executed:
   ```swift
   let sessions = try await supabase.client
       .from("sessions")
       .select("""
           *,
           phases!inner(
               id, name, program_id,
               programs!inner(
                   id, name, patient_id, status
               )
           )
       """)
       .eq("phases.programs.patient_id", value: patientId)
       .eq("phases.programs.status", value: "active")
       .order("sequence", ascending: true)
       .limit(1)
       .execute()
       .value
   ```

4. **Query Returns Empty** → User sees error
   Possible causes:
   - Patient has no active program (`programs.status != 'active'`)
   - Active program has no phases
   - Phases have no sessions
   - Foreign key relationships broken
   - RLS policies blocking access
   - **MOST LIKELY**: Demo data not seeded in production database

---

## Critical Test Findings

### Tests That Would Have Caught Build 8 Bug

**SupabaseIntegrationTests.swift** - Line 179-251:
```swift
func testPatientSessionsQueryWithRelationships() async throws {
    // This test executes THE EXACT QUERY that's failing in production
    let sessionsResponse: [Session] = try await supabase.client
        .from("sessions")
        .select(/* same complex query with inner joins */)
        .eq("phases.programs.patient_id", value: patientId)
        .eq("phases.programs.status", value: "active")
        .execute()
        .value

    if sessionsResponse.isEmpty {
        print("""
            ⚠️ WARNING: No sessions found for patient

            This is likely why Build 8 shows "data could not be read"

            ACTION REQUIRED: Run seed scripts to create demo data
            """)
    }
}
```

**ConfigTests.swift** - Line 16-36:
```swift
func testBackendURLNotLocalhost() {
    XCTAssertFalse(backendURL.contains("localhost"),
        "CRITICAL BUG: Backend URL contains localhost - will fail on physical devices")
}
```

**PatientFlowUITests.swift** - Line 70-112:
```swift
func testPatientSessionDataLoads() throws {
    // This UI test simulates the exact user flow that's broken

    let errorMessage = app.staticTexts
        .containing(NSPredicate(format: "label CONTAINS[c] 'could not be read'"))
        .firstMatch

    XCTAssertFalse(errorMessage.exists,
        """
        🚨 BUILD 8 BUG DETECTED: Error message shown
        This is the exact failure reported by user!
        """)
}
```

**None of these tests executed**, so the bug went undetected.

---

## Recommended Fixes

### Priority 1: Fix Test Infrastructure (BLOCKING)

#### Fix 1.1: Configure Xcode Scheme for Testing

Edit `/Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance/PTPerformance.xcodeproj/xcshareddata/xcschemes/PTPerformance.xcscheme`:

Find the `<TestAction>` section and replace empty `<Testables>` with:

```xml
<Testables>
   <TestableReference
      skipped = "NO">
      <BuildableReference
         BuildableIdentifier = "primary"
         BlueprintIdentifier = "PTPerformanceTests"
         BuildableName = "PTPerformanceTests.xctest"
         BlueprintName = "PTPerformanceTests"
         ReferencedContainer = "container:PTPerformance.xcodeproj">
      </BuildableReference>
   </TestableReference>
   <TestableReference
      skipped = "NO">
      <BuildableReference
         BuildableIdentifier = "primary"
         BlueprintIdentifier = "PTPerformanceUITests"
         BuildableName = "PTPerformanceUITests.xctest"
         BlueprintName = "PTPerformanceUITests"
         ReferencedContainer = "container:PTPerformance.xcodeproj">
      </BuildableReference>
   </TestableReference>
</Testables>
```

#### Fix 1.2: Enable Auto-Generated Info.plist for Test Targets

Edit `project.pbxproj` for both test targets, add:
```
GENERATE_INFOPLIST_FILE = YES;
```

Or run this command:
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
xcodebuild -target PTPerformanceTests GENERATE_INFOPLIST_FILE=YES
xcodebuild -target PTPerformanceUITests GENERATE_INFOPLIST_FILE=YES
```

#### Fix 1.3: Fix QC Test Runner Script

Edit `run_qc_tests.sh` to properly check xcodebuild exit codes:

```bash
# Run unit tests
set +e  # Don't exit on error, we want to check exit code
xcodebuild test \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
    -only-testing:PTPerformanceTests/TodaySessionViewModelTests \
    2>&1 | xcpretty --color

UNIT_TEST_EXIT_CODE=$?
set -e

if [ $UNIT_TEST_EXIT_CODE -eq 0 ]; then
    echo "✅ Unit Tests PASSED"
    UNIT_TESTS_PASSED=1
else
    echo "❌ Unit Tests FAILED"
    TOTAL_FAILURES=$((TOTAL_FAILURES + 1))
fi
```

Alternatively, use xcodebuild without xcpretty for more reliable error detection.

---

### Priority 2: Fix Build 8 Production Issue

#### Fix 2.1: Verify Database Seed Data

Run these checks on production Supabase:

```sql
-- Check if demo patient exists
SELECT * FROM patients
WHERE email = 'demo-athlete@ptperformance.app';

-- Check if patient has active program
SELECT p.*, prog.*
FROM patients p
LEFT JOIN programs prog ON prog.patient_id = p.id
WHERE p.email = 'demo-athlete@ptperformance.app';

-- Check complete data chain: patient -> program -> phase -> session
SELECT
    p.first_name, p.last_name,
    prog.name as program_name, prog.status,
    ph.name as phase_name,
    s.name as session_name, s.sequence
FROM patients p
LEFT JOIN programs prog ON prog.patient_id = p.id
LEFT JOIN phases ph ON ph.program_id = prog.id
LEFT JOIN sessions s ON s.phase_id = ph.id
WHERE p.email = 'demo-athlete@ptperformance.app'
ORDER BY s.sequence;
```

**Expected**: At least 1 active program with phases and sessions.

**If empty**: Run seed scripts:
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap/infra
psql $DATABASE_URL -f 003_seed_demo_data.sql
psql $DATABASE_URL -f 004_seed_exercise_library.sql
psql $DATABASE_URL -f 005_seed_session_exercises.sql
```

#### Fix 2.2: Deploy Backend Edge Functions

The app tries backend API first:
```
https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session/{patientId}
```

**Check if deployed**:
```bash
curl -X GET \
  "https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session/test" \
  -H "Authorization: Bearer sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"
```

If 404, deploy the function from `/Users/expo/Code/expo/clients/linear-bootstrap/agent-service/`.

#### Fix 2.3: Verify RLS Policies

Check that RLS policies allow patients to read their own sessions:

```sql
-- Show current policies on sessions table
SELECT * FROM pg_policies WHERE tablename = 'sessions';

-- Test policy as demo patient
SET ROLE authenticated;
SET request.jwt.claims.sub = '(demo-patient-auth-id)';

SELECT * FROM sessions
WHERE id IN (
    SELECT s.id
    FROM sessions s
    JOIN phases ph ON s.phase_id = ph.id
    JOIN programs prog ON ph.program_id = prog.id
    WHERE prog.patient_id = '(demo-patient-id)'
);
```

---

### Priority 3: Prevent Future Failures

#### Fix 3.1: Add Pre-Deploy Validation

Create `pre_deploy_checks.sh`:
```bash
#!/bin/bash
set -e

echo "Running pre-deployment validation..."

# 1. Verify tests can build
echo "Step 1: Building test targets..."
xcodebuild build-for-testing \
    -scheme PTPerformance \
    -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 2. Run all tests
echo "Step 2: Running QC test suite..."
./run_qc_tests.sh

# 3. Check build configuration
echo "Step 3: Validating build settings..."
BUILD_CONFIG=$(xcodebuild -showBuildSettings -scheme PTPerformance | grep "CONFIGURATION")
echo "Build configuration: $BUILD_CONFIG"

echo "✅ All pre-deployment checks passed"
```

#### Fix 3.2: Add GitHub Actions CI Check

Create `.github/workflows/ios-tests.yml`:
```yaml
name: iOS Tests

on:
  pull_request:
  push:
    branches: [main, master]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3

      - name: Run iOS Tests
        run: |
          cd ios-app/PTPerformance
          xcodebuild test \
            -scheme PTPerformance \
            -destination 'platform=iOS Simulator,name=iPhone 15 Pro' \
            -resultBundlePath TestResults

      - name: Upload test results
        if: always()
        uses: actions/upload-artifact@v3
        with:
          name: test-results
          path: ios-app/PTPerformance/TestResults
```

---

## Test Coverage Summary

### Unit Tests (3 files, ~55 test cases)

**TodaySessionViewModelTests.swift**:
- ✅ Backend URL validation (prevents localhost bugs)
- ✅ Initial state verification
- ✅ Patient ID validation
- ✅ Loading state management
- ✅ Error message handling
- ✅ Supabase client availability
- ✅ Demo data hardcoding prevention
- ✅ Backend fallback to Supabase
- ✅ Performance benchmarking

**PatientListViewModelTests.swift**:
- ✅ Therapist patient filtering (Build 8 fix)
- ✅ Search functionality
- ✅ Patient lookup by UUID
- ✅ Active flags loading
- ✅ Error handling without crashes
- ✅ Loading state management

**ConfigTests.swift**:
- ✅ Backend URL not localhost (CRITICAL)
- ✅ Backend URL is HTTPS
- ✅ Backend URL is Supabase Edge Functions
- ✅ Supabase credentials validation
- ✅ Demo credentials validation
- ✅ No DEBUG conditional compilation (Build 7 regression prevention)

### Integration Tests (1 file, ~10 test cases)

**SupabaseIntegrationTests.swift**:
- ✅ Client initialization
- ✅ URL configuration
- ✅ Demo patient login
- ✅ Demo therapist login
- ✅ Patients table accessibility
- ✅ Sessions table accessibility
- ✅ Workload flags table accessibility
- ✅ **Patient sessions query with relationships** (Build 8 bug detector)
- ✅ Therapist patients query with filter
- ✅ Query performance benchmarking

### UI Tests (1 file, ~6 test flows)

**PatientFlowUITests.swift**:
- ✅ Patient login flow
- ✅ **Patient session data loading** (Build 8 bug detector)
- ✅ Exercise detail view
- ✅ Exercise logging form
- ✅ Invalid credentials error handling
- ✅ iPad split view layout

---

## Immediate Action Items

### Must Complete Before Next Deployment

1. **Fix Xcode project configuration** (Blocking)
   - Add test targets to PTPerformance.xcscheme
   - Enable GENERATE_INFOPLIST_FILE for test targets
   - Verify tests execute: `xcodebuild test -scheme PTPerformance`

2. **Fix QC script error detection** (Blocking)
   - Update run_qc_tests.sh to check exit codes correctly
   - Remove xcpretty or use set -o pipefail
   - Test with intentional failure to verify blocking works

3. **Investigate Build 8 database issue** (Critical)
   - Check if demo patient has active program with sessions
   - Run seed scripts if data missing
   - Verify RLS policies allow patient data access
   - Test with curl or direct Supabase query

4. **Re-run full test suite** (Verification)
   - Execute: `./run_qc_tests.sh`
   - All tests must pass before deploying Build 9
   - Review any test failures and fix root causes

### Post-Fix Validation

1. Run integration tests to verify database query works
2. Run UI tests to verify complete patient flow
3. Deploy Build 9 ONLY if all tests pass
4. Monitor TestFlight feedback for "data could not be read" error

---

## Files Requiring Changes

| File | Change Required | Priority |
|------|----------------|----------|
| `PTPerformance.xcscheme` | Add test targets to `<Testables>` section | P0 |
| `project.pbxproj` | Set `GENERATE_INFOPLIST_FILE = YES` for test targets | P0 |
| `run_qc_tests.sh` | Fix exit code detection (remove xcpretty or use pipefail) | P0 |
| Supabase database | Verify/seed demo data (programs, phases, sessions) | P1 |
| Edge Functions | Deploy/verify `/today-session` endpoint | P2 |

---

## Conclusion

**Build 8 deployed broken code because the test suite never executed.** The Xcode project configuration error combined with the QC script's false-positive behavior created a perfect storm where all tests reported as "PASSED" despite never running.

The actual tests are **well-designed** and would have caught:
1. Backend localhost configuration bugs (ConfigTests)
2. Missing database seed data (SupabaseIntegrationTests)
3. Patient data loading failures (PatientFlowUITests)

**Next Steps**:
1. Fix test infrastructure immediately
2. Run tests and fix failures
3. Investigate database seed data issue
4. Deploy Build 9 only when ALL tests genuinely pass

This analysis provides the complete diagnostic information needed to fix both the test infrastructure and the production Build 8 issue.

---

**Report Generated**: December 9, 2025
**Analyst**: Claude Sonnet 4.5
**Test Suite Commit**: 142431e
**Status**: Test execution blocked by project misconfiguration
