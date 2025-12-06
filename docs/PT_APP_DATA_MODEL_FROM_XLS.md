# PT App – Data Model Derived from XLS (Brebbia Example)

This document maps the example XLS fields into normalized database entities for Supabase.

---

## 1. Patient Demographics (from "Personal" tab)
Fields extracted:
- First name
- Last name
- Age
- DOB
- Sport / Position
- College / Team
- Dominant hand
- Height / Weight
- Medical conditions
- Surgical history
- Medications
- Allergies
- Goals (short + long term)

Mapped to table: **patients**
- id (UUID)
- first_name
- last_name
- date_of_birth
- sport
- position
- dominant_hand
- height_in
- weight_lb
- medical_history (JSON)
- medications (JSON)
- goals (text)

---

## 2. Strength & Conditioning Logic (from "S&C" tab)
Spreadsheet includes:
- 1RM calculation using **Epley**, **Brzycki**, **Lombardi**
- Estimated maxes for:
  - Squat
  - Bench
  - Deadlift
  - Clean
- Weekly progressions

Tables needed:

### exercise_templates
- name
- category (strength, mobility, plyo, bullpen)
- load_type (weight, bodyweight, distance, time)

### session_exercises
- target_sets
- target_reps
- target_load
- rm_method (Epley, Brzycki, etc.)

### exercise_logs
- actual_sets
- actual_reps
- actual_load
- rm_estimate (computed)

Formulas preserved for agents:
- Epley: `1RM = weight * (1 + reps/30)`
- Brzycki: `1RM = weight * 36 / (37 - reps)`
- Lombardi: `1RM = weight * reps^0.10`

---

## 3. Body Composition (from "Body Comp.")
Fields:
- Weight tracking
- BF%
- Lean mass
- Date

Table: body_comp_measurements
- patient_id
- date
- weight_lb
- body_fat_pct
- lean_mass_lb (optional)

---

## 4. Pitching-Specific Data (from Bullpen tab)
From your XLS:
- Pitch types
- Velocity
- Command rating
- Volume (pitch count)
- Pain notes
- Feel notes

Table: bullpen_logs
- patient_id
- date
- pitch_type
- velocity
- command_rating
- pain_rating
- notes

Velocity and command trends will feed the therapist dashboard.

---

## 5. 8-Week On-Ramp Program (from tab)
Your XLS includes:
- Progression of workload
- Week-by-week intensity
- Plyo drills
- Mechanical focus

Tables impacted:
- programs
- phases
- sessions
- session_exercises (plyo, medicine ball, drills)

This is the **initial seed program** for demo and testing.

---

## 6. Pain & Functional Scales
You capture:
- Pain per exercise (0–10)
- Pain per session (0–10)
- Notes
- Red flag indicators (keywords)

Tables:
- pain_logs
- session_notes

Agents must enforce clinical safety:
- If pain > 5 for 2+ sessions → propose plan change
- If pain spikes > 3 in a single session → zone-4b alert

---

## 7. Derived Views for Analytics

### vw_patient_adherence
- scheduled_sessions
- completed_sessions
- percent_complete

### vw_pain_trend
- date
- pain_value
- rolling_avg_pain_3

### vw_bullpen_progress
- pitch_type
- avg_velocity
- command_trend

These improve PT decision-making and AI reasoning.
