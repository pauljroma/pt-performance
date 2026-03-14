# Modus 1.0 Release Readiness

**Last updated:** 2026-03-14
**Target:** Public App Store 1.0

---

## Scope: Patient MVP

The 1.0 release is a patient-first, workout-first app. It does NOT ship therapist workflows, broad AI chat, nutrition/fasting/supplements, baseball packs, or clinical dashboards.

### Shipped Features

| Feature | Status | Notes |
|---------|--------|-------|
| Apple Sign-In + session restore | Ready | Via `AppleSignInService` |
| Onboarding (3-page flow + quick setup) | Ready | Skip option available |
| Today screen / daily action loop | Ready | `TodayHubView` |
| Workout retrieval + quick start | Ready | `ProgramsHubView` |
| Workout execution + completion | Ready | Exercise logging pipeline |
| Readiness check-in | Ready | `daily_readiness` table |
| Streaks + weekly summary | Ready | Feature-flagged ON |
| HealthKit (optional) | Ready | Not required for onboarding |
| Settings / privacy / account | Ready | Therapist linking hidden behind flag |
| Crash reporting (Sentry) | Ready | `SENTRY_DSN` env var slot in xcscheme; operator must populate |
| AI Exercise Substitution | Ready | Low-risk, reduces workout friction |
| AI Safety Checks | Ready | Safety-critical, keeps users safe |
| AI Progressive Overload | Ready | Core workout value |

### Deferred from 1.0 (feature-flagged OFF)

Every deferred feature is gated in both the flag service defaults AND the navigation entry points (ProfileHubView, HealthHubView, PatientTabView). No deferred feature is reachable in the 1.0 UI.

| Feature | Flag | Default | Navigation Gated |
|---------|------|---------|-----------------|
| AI Chat | `ai_chat_enabled` | `false` | ProfileHubView |
| AI Nutrition | `ai_nutrition_enabled` | `false` | ProfileHubView |
| AI SOAP Suggestions | `ai_soap_suggestions_enabled` | `false` | Therapist-only |
| AI Health Coach | `ai_health_coach_enabled` | `false` | HealthHubView badge |
| Supplements | `supplements_enabled` | `false` | HealthHubView + quick actions |
| Baseball Pack | `baseball_pack_enabled` | `false` | ProfileHubView |
| Elite Tier | `elite_tier_enabled` | `false` | Subscription gating |
| Therapist Mode | `therapist_mode_enabled` | `false` | RootView |
| Therapist Linking | `therapist_linking_enabled` | `false` | UnifiedSettingsView |
| Paywall | `paywall_enabled` | `false` | Subscription flow |
| WHOOP Integration | `whoop_integration_enabled` | `false` | Settings |
| Fasting Tracker | `fasting_tracker_enabled` | `false` | HealthHubView + snapshot + quick actions |
| Biomarker Dashboard | `biomarker_dashboard_enabled` | `false` | HealthHubView |
| Lab Upload | `lab_upload_enabled` | `false` | HealthHubView |
| Body Comp Tools | `body_comp_tools_enabled` | `false` | ProfileHubView |
| Leaderboards | `leaderboards_enabled` | `false` | AchievementsDashboardView |
| Pain Tracking | `pain_tracking_enabled` | `false` | MVP mode suppresses tab |
| ROM Exercises | `rom_exercises_enabled` | `false` | MVP mode suppresses tab |
| PR Tracking | `pr_tracking_enabled` | `false` | MVP mode suppresses tab |
| Performance Analytics | `performance_analytics_enabled` | `false` | MVP mode suppresses tab |
| Mode Selection | `mode_selection_enabled` | `false` | RootView |
| Mode Dashboards | `mode_dashboards_enabled` | `false` | PatientTabView |

---

## Security Blockers: Status

### A. Secrets Hygiene

| Item | Status | Action Taken |
|------|--------|-------------|
| Private key (`AuthKey_9S37GWGW49.p8`) removed from git tracking | Done | `git rm --cached` |
| `.gitignore` updated for `.p8`, `.p12`, `.pem`, `.cer`, `private_keys/` | Done | |
| Supabase anon key in Config.swift | Acceptable | Anon key is client-safe by design; RLS is the enforcement boundary |
| `SENTRY_DSN` env var slot added to xcscheme | Done | Operator must populate value |
| Key rotation needed | REQUIRED | Revoke `9S37GWGW49` in App Store Connect, generate new key, store in CI secrets only |

**Operator checklist for key rotation:**
1. Go to App Store Connect > Users and Access > Integrations > App Store Connect API
2. Revoke key ID `9S37GWGW49`
3. Generate a new key
4. Store the new `.p8` file in CI secrets (GitHub Actions secret `APP_STORE_CONNECT_API_KEY`)
5. Update the key ID in any build scripts (`testflight-submit` skill references this)
6. Do NOT commit the new key to git

### B. CI/Testing Truthfulness

| Item | Status |
|------|--------|
| QC script (`scripts/run_qc_checks.sh`) rewritten to fail on real failures | Done |
| QC script now includes SwiftLint check and secrets-tracking check | Done |
| False-PASS QC log (`qc_test_output.log`) deleted | Done |
| `ios-ci.yml` re-enabled with blocking lint/test/build jobs | Done |
| `schema-validation.yml` re-enabled (gracefully skips without DB creds) | Done |
| `agent-service` config allows `NODE_ENV=test` without `process.exit` | Done |
| `continue-on-error: true` removed from all CI test jobs | Done |
| `test_ai_functions.sh` now exits 2 (partial) when integration tests skipped | Done |

### C. RLS / Access Control

| Item | Status |
|------|--------|
| 18 `USING(true)` tables tightened with patient-scoped policies | Done (migration `20260314120000`) |
| HIPAA-sensitive tables (arm_care, body_comp, prescriptions) properly scoped | Done |
| Session chain tables (sessions, session_exercises) scoped via program ownership | Done |
| Migration needs to be pushed to production | REQUIRED |

### D. Scope Discipline

| Item | Status |
|------|--------|
| MVP mode (`mvp_mode: true`) enforced | Done |
| Patient tab bar: Today, Workouts, Recovery, Settings | Done |
| Therapist mode shows "Coming Soon" placeholder | Done |
| Therapist linking hidden from Settings when flag is off | Done |
| Non-1.0 AI features disabled by default | Done |
| AI Chat gated in ProfileHubView by flag | Done |
| Nutrition dashboard gated in ProfileHubView by flag | Done |
| Supplements gated in HealthHubView by flag | Done |
| AI Health Coach badge gated in HealthHubView by flag | Done |
| Fasting tap handlers gated in HealthHubView by flag | Done |
| All deferred features verified unreachable in 1.0 UI | Done |

---

## Pre-Submission Checklist

- [ ] Apple App Store Connect API key rotated (current key was in git history)
- [ ] RLS migration `20260314120000` pushed to production Supabase
- [ ] `SENTRY_DSN` value populated in xcscheme (or CI archive env)
- [ ] App Store metadata reviewed (screenshots, description, privacy policy URL)
- [ ] Privacy Nutrition Label matches actual data collection
- [ ] TestFlight build tested on physical device
- [ ] Sign-in flow verified end-to-end
- [ ] Session restore verified (kill app, reopen)
- [ ] Onboarding flow verified
- [ ] Today screen loads with workout data
- [ ] User can start and complete a workout
- [ ] Readiness check-in works or degrades gracefully
- [ ] Streaks display correctly after workout completion
- [ ] Settings surfaces load without crashes
- [ ] No deferred features visible in any tab
- [ ] No force-unwrap crashes in release build

---

## Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|------------|
| Exposed API key in git history | High | Rotate key immediately; history contains the private key even after removal from HEAD |
| RLS migration not yet applied to prod | High | Push migration before any public build |
| `SENTRY_DSN` empty until operator populates | Medium | Crash reporting silently inactive; app functions normally but crashes go unreported |
| No automated UI tests in CI | Medium | Manual smoke testing covers launch paths; UI test infrastructure exists but needs macOS CI runner |
| App Store screenshots incomplete | Medium | Only 1 screenshot exists; need 3+ per device class for submission |
| Demo mode uses anon key | Low | `is_own_patient()` SECURITY DEFINER handles demo user; USING(true) policies removed |
| Subscription/paywall not verified | Low | Paywall is flagged OFF for 1.0; free app at launch |

---

## Verification Evidence

| Check | Result |
|-------|--------|
| iOS debug build | BUILD SUCCEEDED (2026-03-14) |
| Feature flag gating audit | All 22 deferred features verified gated |
| QC script truthfulness | Rewritten with proper exit codes |
| CI workflows | `ios-ci.yml` + `schema-validation.yml` active |
| Git tracked secrets | Zero `.p8`/`.p12`/`.pem`/`.cer` files tracked |
