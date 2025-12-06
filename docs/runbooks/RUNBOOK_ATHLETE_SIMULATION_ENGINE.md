# RUNBOOK – Athlete Simulation Engine (Workload, Pain, Velocity, Adherence)

## Purpose
Provide deterministic simulations of:
- Daily sessions
- Pain responses
- Velocity changes
- Adherence behavior
- Fatigue & recovery
- Plyo & bullpen interactions

Allows backend agents and analytics to be tested in controlled scenarios.

---

## 1. Simulation Inputs

### Athlete Profile Variables
- baseline_1rm (trap bar, bench, squat)
- baseline_velocity (fastball, slider)
- injury_flag (boolean)
- fatigue_state (0–10)
- recovery_rate (0–10)
- adherence_tendency (0–1)
- pain_sensitivity (0–1)

### Program Variables
- daily workload target (0–10)
- session difficulty (low/med/high)
- throwing days (mon/thurs etc.)
- plyo intensity schedule

---

## 2. Simulation Outputs

### Per Session
- pain_during (0–10)
- pain_after (0–10)
- velocity_delta (mph)
- adherence (bool)
- fatigue_next_day
- soreness (0–10)

### Logs Written
- exercise_logs
- pain_logs
- bullpen_logs (if throwing day)

---

## 3. Simulation Rules
These derive from your XLS and PT domain knowledge.

### Pain Rules
- If intensity ↑ and injury_flag=true → pain increases 1–3 points.
- If fatigue > 7 → pain_during += 1–2.
- If plyo intensity > 7 → pain_after += 1.

### Velocity Rules (pitchers)
- If fatigue > 7 → velocity -2 to -4 mph.
- If soreness high → -1 to -3 mph.
- If well-recovered + no injury → +1 mph potential.

### Adherence Rules
Probability(adherence = true) = adherence_tendency − fatigue*0.05.

---

## 4. Simulation Steps

### Step A: Initialize Athlete State
Load initial conditions from XLS-derived sample.

### Step B: Iterate Daily
For each date:
1. Determine session type (strength, plyo, bullpen, off day).
2. Compute fatigue, pain, soreness.
3. Apply velocity or strength adaptation.
4. Write logs to DB.

### Step C: Export Results
Output:
- 30–60 day simulated time series.
- CSV + direct insert into Supabase.

---

## 5. Definition of Done
- Simulation runs deterministically with seed.
- Generates realistic data consistent with Brebbia XLS patterns.
- Can "stress test" readiness score and flag engine.
- Can automate end-to-end tests: ingestion → analytics → PT assistant → plan change.
