# Modus 1.0 Test Strategy and Smoke-Test Matrix

**Scope:** Launch-critical patient MVP paths
**Environment:** iOS 18+, iPhone (primary), iPad (secondary)

---

## Test Tiers

### Tier 1: Automated (CI — every push to main)

| Test | Tool | Location | Status |
|------|------|----------|--------|
| SwiftLint | `ios-ci.yml` lint job | `.github/workflows/ios-ci.yml` | Active |
| Unit tests | `ios-ci.yml` test job | `PTPerformanceTests/` | Active |
| Debug build | `ios-ci.yml` build job | Xcode simulator build | Active |

### Tier 2: Local QC (pre-archive)

| Test | Script | Status |
|------|--------|--------|
| Unit tests | `scripts/run_qc_checks.sh` Check 1 | Fixed (fails truthfully) |
| Build compilation | `scripts/run_qc_checks.sh` Check 2 | Fixed |
| Code signing cert | `scripts/run_qc_checks.sh` Check 3 | Working |
| Build number | `scripts/run_qc_checks.sh` Check 4 | Working |
| SwiftLint | `scripts/run_qc_checks.sh` Check 5 | Added |
| No tracked secrets | `scripts/run_qc_checks.sh` Check 6 | Added |

### Tier 3: Manual Smoke Tests (pre-TestFlight)

See smoke-test matrix below.

### Tier 4: UI Tests (pre-release)

| Test Suite | Location | Status |
|-----------|----------|--------|
| Auth flow | `PTPerformanceUITests/` | Exists, needs CI runner |
| Onboarding flow | `PTPerformanceUITests/` | Exists, needs CI runner |

---

## Smoke-Test Matrix: Launch-Critical Paths

Run this matrix manually before every TestFlight submission and before App Store submission.

### Authentication

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 1 | Apple Sign-In (new user) | Tap "Sign in with Apple" > authorize | Lands on onboarding | |
| 2 | Apple Sign-In (existing user) | Tap "Sign in with Apple" > authorize | Lands on Today screen | |
| 3 | Session restore | Kill app > reopen | Lands on Today screen (no sign-in required) | |
| 4 | Sign out | Settings > Sign Out > confirm | Returns to sign-in screen | |
| 5 | Account deletion | Settings > Delete Account > confirm | Returns to sign-in screen, data purged | |

### Onboarding

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 6 | Full onboarding | Swipe through 3 pages > "Set Up My Profile" | Quick setup screen appears | |
| 7 | Skip onboarding | Tap "Quick Start" on page 1 | Lands on Today screen | |
| 8 | Quick setup completion | Fill profile > save | Lands on Today screen with profile data | |

### Today Screen

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 9 | Today loads | Navigate to Today tab | Shows daily readiness + workout card | |
| 10 | Empty state | New user with no data | Shows helpful empty state, not crash | |
| 11 | Readiness check-in | Tap readiness card > fill > save | Score displayed, card updates | |

### Workouts

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 12 | Workout list loads | Navigate to Workouts tab | Shows available workouts | |
| 13 | Quick start | Tap workout > "Start" | Exercise view appears | |
| 14 | Complete exercise | Log sets/reps > mark complete | Next exercise or completion screen | |
| 15 | Complete workout | Complete all exercises | Completion celebration, streak updates | |
| 16 | Mid-workout exit | Close app during workout | Resume or data preserved on reopen | |

### Recovery

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 17 | Recovery tab loads | Navigate to Recovery tab | Shows recovery info | |
| 18 | HealthKit prompt | First visit with HealthKit not connected | Optional prompt, not required | |
| 19 | HealthKit denied | Deny HealthKit access | App continues without HealthKit data | |

### Settings

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 20 | Settings loads | Navigate to Settings tab | All sections visible | |
| 21 | Therapist linking hidden | Check Account section | No "Therapist Linking" row visible | |
| 22 | Privacy settings | Tap Privacy & Data | Privacy controls displayed | |
| 23 | Export data | Tap Export My Data | Export process starts | |

### Streaks

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 24 | Streak displayed | After workout completion | Streak count visible on Today screen | |
| 25 | Weekly summary | After 7 days of data | Weekly summary card appears | |

### Edge Cases

| # | Test Case | Steps | Expected | Pass? |
|---|-----------|-------|----------|-------|
| 26 | Offline mode | Airplane mode > open app | Cached data shown, no crash | |
| 27 | Background/foreground | Background app 5min > foreground | Session valid, data refreshes | |
| 28 | Low storage | Fill device storage > use app | Graceful degradation, no crash | |
| 29 | Dark mode | Toggle system dark mode | All screens readable | |
| 30 | Dynamic type | Set accessibility large text | Text scales, no truncation on key screens | |

---

## RLS Verification Queries

Run these against production Supabase after migration `20260314120000` is applied:

```sql
-- Verify no USING(true) policies remain on HIPAA-sensitive tables
SELECT schemaname, tablename, policyname, qual
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'arm_care_assessments', 'body_comp_measurements', 'workout_prescriptions',
    'daily_readiness', 'exercise_logs', 'sessions', 'session_exercises'
  )
  AND qual = 'true';
-- Expected: 0 rows

-- Verify RLS is enabled on all patient data tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'streak_records', 'streak_history', 'daily_readiness',
    'arm_care_assessments', 'body_comp_measurements', 'workout_prescriptions',
    'manual_sessions', 'patient_goals', 'exercise_logs',
    'sessions', 'session_exercises', 'workout_modifications'
  );
-- Expected: all rows show rowsecurity = true
```

---

## Test Data

Use the 10 mock patient personas defined in CLAUDE.md for testing. Demo mode login: `demo-pt@ptperformance.app` (therapist Sarah Thompson).

Patient personas cover all three modes (rehab, performance, strength) and various injury types, providing coverage across the data model.
