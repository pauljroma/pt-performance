# EPIC B – Strength & Conditioning Model (from S&C Sheet)

## B.1 Purpose

Translate the S&C sheet into:

- A coherent **strength model** (1RM estimates + targets).
- Data structures that support long-term progression.
- UI that exposes **context, not spreadsheets** to PT and athlete.

Source: `S&C` tab in XLS.

---

## B.2 1RM Estimation Logic

From XLS:

- Exercises: Trap Bar Deadlift, SSB Squat, Front Squat, Bench, etc.
- For each: input weight + reps.
- Calculated columns for:
  - Epley
  - Brzycki
  - Lombardi
  - Strength (90% of 1RM)
  - Hypertrophy (77.5%)
  - Endurance (65%)

**Formulas:**

- Epley: `1RM = W * (1 + R / 30)`
- Brzycki: `1RM = W * 36 / (37 - R)`
- Lombardi: `1RM = W * R^0.10`

> Agents must preserve these formulas exactly where used.

---

## B.3 Data Model

### B.3.1 Exercise Templates

From S&C:

- Exercises have categories and loading patterns.

**`exercise_templates` additions:**

- `primary_muscle_group`
- `is_primary_lift` boolean
- `default_rm_method` (`'epley' | 'brzycki' | 'lombardi' | 'none'`)

### B.3.2 Logging Actual Sets

`exercise_logs` already captures:

- `actual_reps`
- `actual_load`
- `rpe`

Agents should add:

- `rm_estimate` (numeric) – computed for each set based on `default_rm_method`.
- `is_pr` boolean if rm_estimate surpasses prior max.

---

## B.4 Derived Strength Targets

From XLS columns:

- "Strength (90%)"
- "Hypertrophy (77.5%)"
- "Endurance (65%)"

Agents must support:

- A simple API / function that:
  - Reads an exercise template.
  - Reads recent logs.
  - Computes suggested loads for:
    - strength
    - hypertrophy
    - endurance
- This API will be used to populate exercise prescription (target_load) automatically.

**Definition of Done (backend):**

- Function: `getStrengthTargets(patientId, exerciseTemplateId)` returns:
  - `strength_load`
  - `hypertrophy_load`
  - `endurance_load`
  - with notes on which 1RM method used.

---

## B.5 UI/UX

### B.5.1 Therapist View

- For a given exercise:
  - Show estimated 1RM and last 3 sessions.
  - Show recommended strength/hypertrophy/endurance loads.
  - Allow PT to override.

### B.5.2 Patient View

- Patient never sees raw formulas.
- Sees:
  - "Use 255 lbs x 3 sets of 5" (with scale if needed).
  - If loads change, show stable progression.

---

## B.6 Agent Tasks (examples for Linear)

- "Implement 1RM computation utils from XLS formulas."
  Zones: `zone-7`, `zone-10b`
- "Add rm_estimate to exercise_logs and backfill logic."
  Zones: `zone-7`, `zone-8`
- "Build getStrengthTargets() backend endpoint."
  Zones: `zone-3c`, `zone-7`
- "Display strength targets in therapist program editor."
  Zone: `zone-12`

---
