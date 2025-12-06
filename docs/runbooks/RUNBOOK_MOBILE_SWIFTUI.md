# RUNBOOK – iOS/iPadOS Mobile App (SwiftUI)
Zones: zone-12
Goal: Create a functional patient + therapist app

---

## 1. Preparation

### Inputs
- Skeleton SwiftUI files
- `PT_APP_UX_AND_FLOWS.md`
- `EPIC_I_PATIENT_APP_UX_AND_FLOWS.md`
- Supabase SDK integration guide

### Tools
- Xcode
- Simulator
- Claude agent for code generation

---

## 2. Steps

### Step A — App Skeleton
1. Confirm `PTPerformanceApp.swift` loads RootView.
2. Implement:
   - AuthView
   - PatientTabView
   - TherapistTabView
3. Add navigation scaffolding.

**DoD:**
- App compiles
- App switches between patient/therapist modes

---

### Step B — Supabase Auth Integration
1. Add Supabase Swift client:
   ```swift
   import Supabase
   ```
2. Implement login flow.
3. Map authenticated user → patient or therapist.

**DoD:**
- Demo user signs in/out
- Session persists across launches

---

### Step C — Today Session Screen
1. Build List view for exercises.
2. Pull real data from Supabase endpoint `/today-session/{id}`.
3. Support navigation to exercise detail.

**DoD:**
- Real patient sees today session loaded from Supabase
- No hardcoded placeholders

---

### Step D — Exercise Logging
1. Add:
   - actual reps
   - actual load
   - RPE slider
   - per-exercise pain slider
2. Submit logs to Supabase.

**DoD:**
- Logs appear in exercise_logs
- Session summary renders correctly

---

### Step E — History View
1. Render pain trend chart.
2. Render adherence %.
3. Pull from:
   - vw_pain_trend
   - vw_patient_adherence

**DoD:**
- Charts display correctly for seeded data

---

## 3. Final Outputs
- End-to-end working mobile UX
- Real session logging
- Therapist dashboard stub
- Linear issue updated
