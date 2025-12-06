# DATA INTEGRITY TEST SUITE

## Purpose
Ensure database integrity for:
- foreign keys
- missing data
- invalid values
- orphan logs
- KPI mismatches

---

## Scenarios

### DI1 – Orphaned Exercise Logs
**Test:**
Insert a log referencing a non-existent session.

**Expected:**
- Blocked by FK constraint
- Error logged
- Integrity test marks "pass"

**SQL:**
```sql
INSERT INTO exercise_logs (patient_id, session_id, session_exercise_id, actual_reps)
VALUES ('valid-patient-id', 'non-existent-session-id', 'non-existent-exercise-id', 10);
-- Should fail with FK violation
```

---

### DI2 – Invalid Pain Values
**Test:**
Attempt to insert invalid pain scores.

**Invalid Values:**
- pain_during = 12 (> 10)
- pain_after = -1 (< 0)

**Expected:**
- CHECK constraint violation
- Agent must validate before insert
- Error message: "Pain score must be between 0 and 10"

**SQL:**
```sql
INSERT INTO pain_logs (patient_id, pain_during) VALUES ('patient-id', 12);
-- Should fail with CHECK constraint
```

---

### DI3 – Invalid RPE Values
**Test:**
Attempt to insert RPE outside 0-10 range.

**Expected:**
- CHECK constraint blocks insertion
- Clear error message

---

### DI4 – Missing Session for On-Ramp Progression
**Test:**
Given:
- On-Ramp week expects 3 sessions
- Only 1 session logged

**Expected:**
- Adherence drop shown correctly
- vw_patient_adherence reflects 33% for that week
- Therapist dashboard shows red indicator

---

### DI5 – Missing Bullpen Velocity Data
**Test:**
If velocity field is NULL:

**Expected:**
- velocity calculations skip gracefully
- no crash or NaN output
- Dashboard shows "N/A" or blank

**Query:**
```sql
SELECT avg(velocity) FROM bullpen_logs WHERE velocity IS NOT NULL;
-- Should handle NULLs correctly
```

---

### DI6 – Mismatched Template / Prescription
**Test:**
session_exercise references missing exercise_template.

**Expected:**
- Flagged in `vw_data_quality_issues`
- Query returns problematic rows

**SQL:**
```sql
SELECT se.id, se.session_id, se.exercise_template_id
FROM session_exercises se
LEFT JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE et.id IS NULL;
-- Should return any orphaned prescriptions
```

---

### DI7 – Future Dates in Logs
**Test:**
Insert exercise_log with performed_at > NOW().

**Expected:**
- Warning flag in data quality view
- Therapist notified of data anomaly

---

### DI8 – Duplicate Session Exercises
**Test:**
Insert same exercise twice in same session at same sequence.

**Expected:**
- Either blocked by unique constraint
- Or flagged in data quality view

---

### DI9 – Negative Load Values
**Test:**
Attempt actual_load = -50.

**Expected:**
- CHECK constraint blocks
- Or data quality view flags for review

---

### DI10 – Patient Without Therapist
**Test:**
Patient record with therapist_id = NULL.

**Expected:**
- Allowed (for self-directed patients)
- But flagged if therapist dashboard tries to query
- RLS policies handle gracefully

---

## Data Quality View

Create comprehensive data quality view:

```sql
CREATE OR REPLACE VIEW vw_data_quality_issues AS
SELECT
  'orphaned_exercise_logs' as issue_type,
  COUNT(*) as issue_count
FROM exercise_logs el
LEFT JOIN sessions s ON s.id = el.session_id
WHERE s.id IS NULL

UNION ALL

SELECT
  'orphaned_session_exercises',
  COUNT(*)
FROM session_exercises se
LEFT JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE et.id IS NULL

UNION ALL

SELECT
  'future_dated_logs',
  COUNT(*)
FROM exercise_logs
WHERE performed_at > NOW()

UNION ALL

SELECT
  'invalid_pain_in_logs',
  COUNT(*)
FROM exercise_logs
WHERE pain_score NOT BETWEEN 0 AND 10

UNION ALL

SELECT
  'missing_program_phases',
  COUNT(*)
FROM programs pr
LEFT JOIN phases ph ON ph.program_id = pr.id
WHERE pr.status = 'active' AND ph.id IS NULL;
```

---

## DoD
- All integrity scenarios pass.
- vw_data_quality_issues returns 0 for all issue types in clean test environment.
- Foreign key constraints properly enforced.
- CHECK constraints validated.
- Data quality monitoring integrated into admin dashboard.
