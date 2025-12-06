# RUNBOOK – Analytics Input/Output Tests

**Purpose:** Define strict IO test cases for key analytics functions, using XLS-derived values as ground truth.

---

## 1. 1RM and Strength Targets

### Input Example
- Exercise: Trap Bar Deadlift
- Weight: 405 lb
- Reps: 5

**Expected Output:**
- Epley 1RM: specific numeric value (from XLS)
- Brzycki 1RM: specific value
- Lombardi 1RM: specific value
- Strength target (90%): derived
- Hypertrophy target (77.5%): derived
- Endurance target (65%): derived

**Test:**
- `compute1RMAndTargets(405, 5)` returns all values within 1–2% of XLS.

---

## 2. Pain Trend

### Input
- 5 pain_logs entries with:
  - pain_during: [2, 3, 4, 5, 6] over consecutive days

**Expected Output:**
- trend direction: upward
- average pain: known numeric
- risk flag: raised when pain_during > 5

**Test:**
- `computePainTrend(patientId)` returns the correct numeric trend and flag.

---

## 3. Readiness Score

### Input
- Pain trend: stable, moderate
- Adherence: 80%
- Velocity: stable or slightly up
- Workload: moderate

**Expected Output:**
- readiness score in a "Green" band (e.g., 80–90)

**Change:**
- Drop adherence to 40%
- Raise pain to 6
- Velocity drops 4 mph

**Expected Output:**
- readiness score in "Red" band (<60)

---

## 4. Throwing Workload

**Given:**
- 3 bullpen sessions with:
  - pitches: [30, 40, 35]
  - average velocity: [92, 91, 88]

**Expected:**
- workload trend: stable to high
- velocity trend: negative, with alert by 3rd session.

**Test:**
- `computeThrowingWorkloadMetrics(patientId)` identifies velocity drop and sets correct flags.

---

## DoD
- Each function has 3–5 concrete IO test cases tied to XLS-derived examples.
- All analytics function outputs match test specifications.
