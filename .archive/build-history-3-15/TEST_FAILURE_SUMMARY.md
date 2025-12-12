# iOS Test Suite Failure - Quick Summary

## The Problem

**Build 8 is broken in production** with error: `"data could not be read because it doesn't exist"`

**Tests report "ALL PASSED"** but they never actually executed - this is a **FALSE POSITIVE**.

---

## Why Tests Didn't Run

### 3 Critical Failures:

1. **Xcode Scheme Misconfigured**
   - File: `PTPerformance.xcscheme`
   - Issue: `<Testables>` section is empty
   - Result: xcodebuild says "Scheme PTPerformance is not currently configured for the test action"

2. **Test Targets Missing Info.plist**
   - Targets: PTPerformanceTests, PTPerformanceUITests
   - Issue: `GENERATE_INFOPLIST_FILE` not set to YES
   - Result: "Cannot code sign because the target does not have an Info.plist file"

3. **QC Script Has False Positive Bug**
   - File: `run_qc_tests.sh`
   - Issue: Pipes xcodebuild to xcpretty, which always returns 0
   - Result: Tests report PASSED even when they fail

---

## What Would Have Caught Build 8 Bug

These tests exist but never executed:

### SupabaseIntegrationTests.swift
```swift
func testPatientSessionsQueryWithRelationships() {
    // Tests THE EXACT QUERY that's failing in production
    // Would have shown "No sessions found for patient"
}
```

### PatientFlowUITests.swift
```swift
func testPatientSessionDataLoads() {
    // Tests complete patient flow: login → load session data
    // Would have detected "data could not be read" error
}
```

### ConfigTests.swift
```swift
func testBackendURLNotLocalhost() {
    // Prevents localhost configuration on TestFlight builds
}
```

---

## Likely Root Cause of Build 8 Bug

Patient session query returns **empty results** because:

Most likely: **Database seed data missing**
- Patient has no active program
- Active program has no phases
- Phases have no sessions
- Need to run: `003_seed_demo_data.sql`, `004_seed_exercise_library.sql`, `005_seed_session_exercises.sql`

Other possibilities:
- Backend Edge Function not deployed: `/functions/v1/today-session/{patientId}`
- RLS policies blocking patient's access to sessions table
- Foreign key relationships broken

---

## Fix Checklist (In Order)

### Priority 0: Fix Test Infrastructure (BLOCKING)

- [ ] Edit `PTPerformance.xcscheme` - add test targets to `<Testables>` section
- [ ] Set `GENERATE_INFOPLIST_FILE = YES` for PTPerformanceTests target
- [ ] Set `GENERATE_INFOPLIST_FILE = YES` for PTPerformanceUITests target
- [ ] Fix `run_qc_tests.sh` exit code detection (remove xcpretty or use pipefail)
- [ ] Verify: `xcodebuild test -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro'`

### Priority 1: Fix Build 8 Production Bug

- [ ] Check Supabase database for demo patient data:
  ```sql
  SELECT p.*, prog.*, ph.*, s.*
  FROM patients p
  LEFT JOIN programs prog ON prog.patient_id = p.id
  LEFT JOIN phases ph ON ph.program_id = prog.id
  LEFT JOIN sessions s ON s.phase_id = ph.id
  WHERE p.email = 'demo-athlete@ptperformance.app';
  ```
- [ ] If empty: Run seed scripts in `/infra/` directory
- [ ] Verify backend Edge Function deployed: `curl https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session/test`
- [ ] Check RLS policies on sessions table

### Priority 2: Validate Fix

- [ ] Run full test suite: `./run_qc_tests.sh`
- [ ] Verify ALL tests actually execute and pass
- [ ] Fix any failing tests
- [ ] Build 9 only if tests genuinely pass

---

## Test Suite Overview

**Created**: Commit 142431e
**Files**: 5 test files, ~70+ test cases
**Coverage**:
- 3 unit test files (ViewModels, Config)
- 1 integration test file (Supabase database queries)
- 1 UI test file (Patient/therapist flows)

**Status**: Well-designed but never executed due to project misconfiguration

---

## Quick Diagnosis Commands

```bash
# 1. Check if tests can build
cd /Users/expo/Code/expo/clients/linear-bootstrap/ios-app/PTPerformance
xcodebuild build-for-testing -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 2. Try to run tests
xcodebuild test -scheme PTPerformance -destination 'platform=iOS Simulator,name=iPhone 17 Pro'

# 3. Check test scheme configuration
cat PTPerformance.xcodeproj/xcshareddata/xcschemes/PTPerformance.xcscheme | grep -A 10 "TestAction"

# 4. List available test schemes
xcodebuild -list -project PTPerformance.xcodeproj
```

---

## Key Files

| File | Location | Issue |
|------|----------|-------|
| Scheme config | `PTPerformance.xcodeproj/xcshareddata/xcschemes/PTPerformance.xcscheme` | Empty `<Testables>` |
| Project config | `PTPerformance.xcodeproj/project.pbxproj` | Missing GENERATE_INFOPLIST_FILE |
| QC runner | `run_qc_tests.sh` | False positive exit codes |
| Full analysis | `TEST_FAILURE_ANALYSIS.md` | Complete diagnostic report |

---

**Bottom Line**: Fix test infrastructure first, then tests will reveal the exact database issue causing Build 8 to fail.

**Report**: See `TEST_FAILURE_ANALYSIS.md` for complete details and step-by-step fixes.
