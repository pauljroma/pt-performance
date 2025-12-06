# EPIC C – Throwing, On-Ramp, and Plyo Model (from Skill Tracker Sheets)

## C.1 Purpose

Convert the bullpen, 8-week on-ramp, and plyo drill trackers into a structured **throwing workload + skill tracking model** suitable for:

- Return-to-throw protocols.
- In-season maintenance.
- Workload and velocity monitoring.

Sources:
- `Skill Tracker Bullpen`
- `Skill Tracker 8 Week On Ramp`
- `Skill Tracker Plyo Drills`

---

## C.2 Bullpen Model (Pinnacle Pen Tracker)

From XLS:

- "Pitch Type", "Missed Spot", "Hit Spot", "Total Pitches", "Hit Spot %"
- Velocity chart by pitch type:
  - 4-FB, 2-FB, Cutter, CB, SL, Split, CH, Fork
- Average velocity per pitch type.

**Tables:**

### bullpen_logs (already defined)
Enhance with:

- `pitch_type` (enum-like text)
- `missed_spot_count`
- `hit_spot_count`
- `hit_spot_pct`
- `avg_velocity` (per session, per pitch type)

**Logic:**

- `hit_spot_pct = hit_spot_count / (hit_spot_count + missed_spot_count)` (if denominator > 0).
- Derived trends: command and velocity over time.

---

## C.3 8-Week On-Ramp Program

From XLS:

- Columns like:
  - Date
  - Throw #
  - Velo by ball weight: 5 oz, 6 oz, 4 oz, 7 oz, 5 oz, 4 oz
  - AVG row

Interpretation:

- Weekly progression of throws with varying ball weights.
- Velocity targets and progression.

**Mapping to program model:**

- On-ramp as a **Program** with Phases = weeks, Sessions = individual throwing days.
- `session_exercises` include:
  - "On-Ramp Throws – Ball X oz"
  - target reps / distance / intensity notes.

**Derived metrics:**

- `onramp_session_logs` can be just `bullpen_logs` + ball weight or a separate table.
- We need to track:
  - velocity per ball weight
  - adherence to planned throws

---

## C.4 Plyo Drills

From `Skill Tracker Plyo Drills`:

- Date
- Multiple drill columns:
  - 7oz, 5oz, 3.5oz etc.
- Running averages and DIV/0 behavior for missing data.

**Tables:**

- Either reuse `bullpen_logs` with a `is_plyo` flag, or:
- Create `plyo_logs`:
  - patient_id
  - date
  - drill_name
  - ball_weight_oz
  - velocity
  - notes

Goal: unify later into a **ThrowingWorkload** view.

---

## C.5 Derived Views

### vw_throwing_workload

- patient_id
- date
- total_pitches (bullpen + on-ramp)
- average_velocity_fastball
- average_plyo_velocity
- hit_spot_pct (overall, and/or per pitch_type)
- flags:
  - `high_workload_flag` (boolean)
  - `velocity_drop_flag`

### vw_onramp_progress

- week
- target vs actual sessions
- velocity progression

---

## C.6 Plan Change Triggers (for zone-4b)

Based on throwing data:

- If velocity drops > X mph over Y sessions with stable workload → flag.
- If command (hit_spot_pct) drops consistently → flag.
- If pain in bullpen logs ≥ 5 more than 2 sessions in a row → auto-create Plan Change Request.

**Plan Change Request contents:**

- Summarize:
  - recent workloads
  - velocity trend
  - pain trend
- Suggest:
  - reduce volume
  - change intensity
  - adjust phase timing

---

## C.7 Agent Tasks (examples)

- "Normalize bullpen tracker into bullpen_logs and add command metrics."
  Zones: `zone-7`, `zone-8`
- "Model 8-week on-ramp as program → phases → sessions."
  Zones: `zone-7`, `zone-12`
- "Implement vw_throwing_workload and vw_onramp_progress."
  Zones: `zone-7`, `zone-10b`
- "Wire throwing workload flags into therapist dashboard."
  Zone: `zone-12`
- "Create Plan Change Request generator for throwing flags."
  Zones: `zone-3c`, `zone-4b`

---
