# EPIC – Return-to-Throw Progression Engine

## Purpose

Turn the 8-week on-ramp + bullpen + plyo logic into a reusable "Return-to-Throw Engine" that:

- Structures phases and sessions.
- Applies safe progression rules.
- Interfaces with pain/velocity flags.
- Supports plan-change proposals.

---

## 1. Components

### 1.1 Template Library

Define return-to-throw templates with:
- weeks
- throwing days
- target volume
- intensities
- ball weights

Templates driven by:
- surgery/injury type
- specificity (starter vs reliever)

---

### 1.2 Progression Rules

Rules for:

**Volume:**
- escalate by at most X% per week (e.g., 10–20%)
- downshift after high-workload weeks

**Intensity:**
- ramp intensity only if:
  - pain < threshold
  - velocity stable or improving

**Rest / Deload Weeks:**
- scheduled deload after certain weeks or if flags spike.

---

### 1.3 Data Inputs

From existing schema:
- bullpen_logs
- plyo_logs
- programs/phases/sessions
- pain_logs
- velocity history

---

## 2. Engine Behavior

### 2.1 Generate Plan

Inputs:
- patient profile
- baseline velocity
- injury type
- target return date range

Outputs:
- multi-week phased plan
- day-by-day throwing schedule
- volume + intensity per day

---

### 2.2 Monitor & Adjust

Each week:
- evaluate pain and velocity.
- adjust:
  - volume
  - intensity
  - timing (e.g., hold progression for 1 week).

For major adjustments:
- create Plan Change Request in Linear with:
  - context summary
  - recommended changes.

---

## 3. Definition of Done

- Engine can:
  - generate a safe, baseline return-to-throw plan.
  - adjust plan based on pain/velocity data.
- PT can override any step.
- Plan changes always go through Linear zone-4b.
