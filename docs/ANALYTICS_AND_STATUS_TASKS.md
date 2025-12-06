# LINEAR ISSUE PACK — Analytics & Status Tasks (From XLS)

**Purpose:** Use "John Brebbia – example profile.xlsx" as canonical test data to validate all analytics and status views.

**Project:** MVP 1 — PT App & Agent Pilot
**Team:** Agent-Control-Plane

---

## A1 — Build Patient Status Card (Personal + Program + Analytics)

**Zones:** zone-7, zone-12
**Priority:** High

**Objective:**
Implement a Therapist Dashboard "Patient Status Card" using Brebbia XLS data as canonical test input.

**Scope (Allowed Changes):**
- Supabase queries for: patients, programs, phases, vw_patient_adherence, vw_pain_trend
- SwiftUI: TherapistTabView, TherapistDashboardView

**Definition of Done:**
- Status card displays: Name, Age, Team/Level, Active program, Phase, Adherence %, Pain status.
- For seeded Brebbia data, adherence % matches spreadsheet.
- Pain indicator reflects last 7 days from vw_pain_trend.
- No active program → message "No active program."

---

## B1 — Body Composition Trend Line (Weight + Body Fat %)

**Zones:** zone-7, zone-10b, zone-12
**Priority:** Medium

**Objective:**
Implement analytics + UI to show weight and BF% trends derived from Body Comp. XLS data.

**Scope:**
- Table: body_comp_measurements
- Chart UI in PatientHistoryView

**Definition of Done:**
- XLS Body Comp rows imported into DB.
- Trend lines match XLS values (± rounding).
- Tapping datapoint shows correct weight & BF%.
- Chart renders correctly on iPhone + iPad.

---

## C1 — Validate 1RM Calculations (S&C Sheet)

**Zones:** zone-7, zone-10b
**Priority:** High

**Objective:**
Implement and test Epley, Brzycki, Lombardi formulas to match S&C sheet exactly.

**Scope:**
- Backend utils file strength_utils
- Unit test suite

**Definition of Done:**
- For each S&C example:
  - Epley ≈ XLS
  - Brzycki ≈ XLS
  - Lombardi ≈ XLS
- Unit tests pass with <2% error tolerance.

---

## C2 — Strength / Hypertrophy / Endurance Load Targets

**Zones:** zone-7, zone-3c, zone-10b
**Priority:** High

**Objective:**
Implement target load recommendations based on 1RM: strength (90%), hypertrophy (77.5%), endurance (65%).

**Scope:**
- Backend /strength-targets endpoint
- SQL or in-code functions

**Definition of Done:**
- Outputs match XLS logic exactly.
- Tested against 3–5 lifts from Brebbia sample.
- Program Builder uses these values when prescribing loads.

---

## D1 — Bullpen Command Analytics (Hit Spot %)

**Zones:** zone-7, zone-10b, zone-12
**Priority:** Medium

**Objective:**
Extract hit/miss spot counts from Bullpen XLS and compute hit_spot_pct for analytics.

**Scope:**
- Table: bullpen_logs
- SwiftUI bullpen summary UI

**Definition of Done:**
- hit_spot_pct computed accurately (matches sheet).
- Therapist view shows hit_spot_pct per session.
- Seeded Brebbia bullpen logs display expected values.

---

## D2 — Bullpen Velocity Trends by Pitch Type

**Zones:** zone-7, zone-10b, zone-12
**Priority:** Medium

**Objective:**
Compute and display velocity trend lines per pitch type based on Bullpen XLS.

**Scope:**
- bullpen_logs importer
- Backend: velocity aggregation
- UI: Trend chart

**Definition of Done:**
- Avg velo per pitch type matches XLS.
- Trend line visual matches XLS patterns.
- Therapist dashboard can filter by pitch type.

---

## E1 — 8-Week On-Ramp Velocity Progression

**Zones:** zone-7, zone-10b, zone-12
**Priority:** Medium

**Objective:**
Implement velocity progression analytics for the 8-week On-Ramp program.

**Scope:**
- Import from XLS "8 Week On Ramp"
- Schema extension (ball_weight_oz) if needed
- UI chart under Patient History

**Definition of Done:**
- Multi-week velocity trend matches XLS.
- Can filter by ball weight.
- No missing values; DIV/0 handled gracefully.

---

## F1 — Plyo Drill Analytics (Velocity & Volume)

**Zones:** zone-7, zone-10b, zone-12
**Priority:** Medium

**Objective:**
Model and visualize plyo drill performance (velocity + volume) using Plyo XLS data.

**Scope:**
- Table: plyo_logs (or extend bullpen_logs)
- Backend: drill aggregation
- UI: Plyo section in HistoryView

**Definition of Done:**
- Plyo logs imported with correct ball weights/drill names.
- Avg velocity per drill matches spreadsheet.
- Session drill count aligns with XLS.
- UI shows per-drill breakdown.

---

## G1 — Composite Readiness Score (Pain + Adherence + Velocity)

**Zones:** zone-7, zone-3c, zone-12, zone-10b
**Priority:** High

**Objective:**
Implement a composite readiness metric modeled from XLS data interactions.

**Inputs Combined:**
- Pain trend
- Adherence %
- Velocity trend
- Plyo volume (optional)

**Scope:**
- Backend: computeReadinessScore(patientId)
- UI: readiness indicator on Therapist Dashboard

**Definition of Done:**
- Readiness score = 0–100.
- Score responds correctly to XLS-based test scenarios:
  - High pain → score drops
  - Low adherence → drops
  - Good velocity → increases
- Therapist dashboard displays score + drivers ("Pain ↑3", "Adherence 80%").

---

## Z1 — Create Automated XLS Test Data Importer (BONUS META-TASK)

**Zones:** zone-7, zone-3c, zone-10b
**Priority:** Medium

**Objective:**
Create a test utility that imports XLS rows into Supabase tables for analytics testing.

**Scope:**
- Python/Node script under scripts/
- XLS parsing (weights, drills, bullpen entries)

**Definition of Done:**
- Running script populates DB with all Brebbia sample data.
- Analytics tasks (A–G) validate cleanly.
- Importer can be used for future athletes.
