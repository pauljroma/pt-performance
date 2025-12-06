# EPIC – Throwing Workload Dashboards

## Purpose

Provide therapists with clear, actionable views of:
- throwing workload
- velocity trends
- command trends
- risk flags

Derived from bullpen, on-ramp, and plyo XLS logic.

---

## 1. Dashboard Elements

### 1.1 Overview

- Total pitches per week
- Total throwing days
- Average FB velocity
- Hit-spot % (command)
- Plyo volume index

### 1.2 Time-Series Charts

- Velocity over time per pitch type.
- Workload (pitches) over time.
- Command (hit-spot%) over time.

---

## 2. Views

### View 1 – Weekly Throwing Summary

For a selected date range:
- total pitches
- average intensity
- # of bullpen days
- # of plyo days

### View 2 – Pitch Type Detail

Per pitch type:
- avg velocity
- velocity delta vs baseline
- sample sizes

### View 3 – Risk Strip

- Icons for:
  - velocity drop
  - high workload
  - high pain

---

## 3. Backend Requirements

- Views:
  - `vw_throwing_workload`
  - `vw_pitch_type_velocity`
- Backend endpoints:
  - `/throwing-summary/{patientId}`
  - `/throwing-detail/{patientId}?pitchType=...`

---

## 4. UI Requirements

- iPad-first charts.
- Ability to:
  - filter date range
  - filter pitch types
- Use consistent colors:
  - velocity: accent
  - workload: neutral
  - risk flags: red/amber

---

## 5. Definition of Done

- Dashboards render correctly for Brebbia data.
- Numbers and trends align with original XLS patterns.
- PTs can quickly identify workload and risk.
