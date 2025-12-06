# RUNBOOK – Clinical Validation Tests

## Purpose
Ensure clinical rules from PT domain operate correctly across:
- Pain
- ROM (future)
- Workload
- Throwing behavior
- Adherence

---

## 1. Pain Validation Tests

### Test P1 – Pain Spike Under Load
**Given:**
- Day 1 pain_during = 3
- Day 2 pain_during = 6

**Expected:**
- Flag raised = true
- zone-4b Plan Change Request created
- PT assistant recommendation: "reduce session intensity"

---

### Test P2 – Persistently Medium Pain
**Given:** 3 sessions with pain_during between 3–5

**Expected:**
- PT assistant warns but does not block progression
- No automatic session rollback

---

### Test P3 – Acute Pain Drop on Lower Load
**Given:**
- Lower intensity day
- Pain goes from 6 → 2

**Expected:**
- Adaptation = positive
- No flag
- Encourage continued monitoring

---

### Test P4 – Chronic High Pain (>5 for 4+ sessions)
**Given:** pain_during > 5 for 4 consecutive sessions

**Expected:**
- High severity flag
- zone-4b Plan Change Request with urgent priority
- PT assistant blocks any load increases

---

## 2. Throwing Tests

### Test T1 – Velocity Decline
**Given:**
- Avg velocity for FB drops 4+ mph in 2 days

**Expected:**
- High severity flag
- zone-4b Plan Change Request with rationale
- Recommend cutting volume next session

---

### Test T2 – Poor Command
**Given:** hit_spot_pct drops below 50% over 3 bullpen sessions.

**Expected:**
- Flag severity = medium
- PT assistant suggests mechanical check or reduced-intensity session.

---

### Test T3 – Gradual Velocity Increase (Positive)
**Given:** Velocity increases 1-2 mph over 2 weeks with stable pain

**Expected:**
- No flag
- Positive adaptation noted
- PT assistant acknowledges progress

---

### Test T4 – High Workload + Pain Spike
**Given:**
- Pitch count > 60
- pain_during > 6

**Expected:**
- Critical flag
- zone-4b Plan Change Request
- Next throwing session blocked until PT review

---

## 3. Adherence Tests

### Test A1 – Low Adherence (<60% week)
**Expected:**
- readiness score decreases
- PT assistant notifies therapist
- No auto-plan-change unless correlated with pain

---

### Test A2 – Perfect Adherence (100% for 2+ weeks)
**Expected:**
- Positive signal in therapist dashboard
- Readiness score boost
- PT assistant may suggest progression if pain stable

---

### Test A3 – Missed Sessions After Injury Flag
**Given:**
- injury_flag = true
- 2+ missed sessions

**Expected:**
- Flag for "potential injury avoidance"
- PT assistant recommends check-in

---

## 4. Strength Progression Tests

### Test S1 – Safe Linear Progression
**Given:**
- pain < 3
- all reps completed
- no fatigue flags

**Expected:**
- Auto-suggest load increase 2-5%
- No plan change request needed

---

### Test S2 – Failed Reps with High Pain
**Given:**
- actual_reps < target_reps
- pain_during > 5

**Expected:**
- Flag for "overreach"
- zone-4b Plan Change Request
- Recommend deload or alternative exercise

---

### Test S3 – PR Achievement
**Given:**
- rm_estimate > previous max
- is_pr = true

**Expected:**
- Positive acknowledgment
- No flag
- Progression continues

---

## 5. Program Execution Tests

### Test PE1 – Skipped Session Logic (1 day)
**Given:** 1 day missed

**Expected:**
- Keep current phase
- No session rollback

---

### Test PE2 – Multiple Skipped Sessions (3+ days)
**Given:** 3+ days missed

**Expected:**
- Repeat prior session
- PT assistant flags for review

---

### Test PE3 – Extended Break (7+ days)
**Given:** 7+ days missed

**Expected:**
- zone-4b Plan Change Request
- Recommend moving back one full week in program
- PT approval required to resume

---

## DoD
- All tests operational in backend logic.
- Flags accurately generated.
- Plan Change Requests created only when correct.
- No false positives in test suite.
- Clinical rules validated against PT domain expertise.
