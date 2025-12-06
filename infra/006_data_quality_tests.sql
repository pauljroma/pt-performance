-- 006_data_quality_tests.sql
-- Data Quality Tests and Validation
-- Agent 3 - Phase 1: Data Layer (ACP-86)
--
-- Comprehensive data quality checks including:
-- - Missing/invalid fields
-- - Foreign key validation
-- - Data consistency checks
-- - RM formula validation
-- - Business logic validation
--
-- Run after all seed scripts

-- ============================================================================
-- TEST FRAMEWORK
-- ============================================================================

-- Create test results table
CREATE TABLE IF NOT EXISTS data_quality_test_results (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  test_name text NOT NULL,
  test_category text NOT NULL,
  severity text CHECK (severity IN ('error', 'warning', 'info')) DEFAULT 'error',
  passed boolean NOT NULL,
  issue_count int DEFAULT 0,
  details text,
  run_at timestamptz DEFAULT now()
);

-- Clear previous test results
TRUNCATE data_quality_test_results;

-- ============================================================================
-- CATEGORY 1: MISSING/INVALID FIELDS
-- ============================================================================

-- Test 1.1: Therapists with missing required fields
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Therapists - Missing Required Fields',
  'Missing Fields',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ': ' ||
    CASE
      WHEN first_name IS NULL THEN 'missing first_name '
      WHEN last_name IS NULL THEN 'missing last_name '
      WHEN email IS NULL THEN 'missing email '
      ELSE ''
    END, '; ') as details
FROM therapists
WHERE first_name IS NULL OR last_name IS NULL OR email IS NULL;

-- Test 1.2: Patients with missing required fields
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Patients - Missing Required Fields',
  'Missing Fields',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ': ' || first_name || ' ' || last_name, '; ') as details
FROM patients
WHERE first_name IS NULL OR last_name IS NULL OR therapist_id IS NULL;

-- Test 1.3: Programs with missing dates
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Programs - Missing Dates',
  'Missing Fields',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ': ' || name, '; ') as details
FROM programs
WHERE start_date IS NULL OR end_date IS NULL;

-- Test 1.4: Exercises with missing metadata
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercises - Missing Metadata',
  'Missing Fields',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(name || ' (missing: ' ||
    CASE
      WHEN category IS NULL THEN 'category '
      ELSE ''
    END ||
    CASE
      WHEN body_region IS NULL THEN 'body_region '
      ELSE ''
    END || ')', '; ') as details
FROM exercise_templates
WHERE category IS NULL OR body_region IS NULL;

-- ============================================================================
-- CATEGORY 2: FOREIGN KEY VALIDATION
-- ============================================================================

-- Test 2.1: Patients with invalid therapist_id
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Patients - Invalid Therapist Reference',
  'Foreign Keys',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(p.id::text || ': ' || p.first_name || ' ' || p.last_name, '; ') as details
FROM patients p
LEFT JOIN therapists t ON t.id = p.therapist_id
WHERE p.therapist_id IS NOT NULL AND t.id IS NULL;

-- Test 2.2: Programs with invalid patient_id
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Programs - Invalid Patient Reference',
  'Foreign Keys',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(pr.id::text || ': ' || pr.name, '; ') as details
FROM programs pr
LEFT JOIN patients p ON p.id = pr.patient_id
WHERE p.id IS NULL;

-- Test 2.3: Session exercises with invalid exercise template
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Session Exercises - Invalid Exercise Template',
  'Foreign Keys',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(se.id::text, '; ') as details
FROM session_exercises se
LEFT JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE et.id IS NULL;

-- Test 2.4: Exercise logs with invalid references
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercise Logs - Invalid References',
  'Foreign Keys',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(el.id::text || ' (missing: ' ||
    CASE WHEN p.id IS NULL THEN 'patient ' ELSE '' END ||
    CASE WHEN s.id IS NULL THEN 'session ' ELSE '' END ||
    CASE WHEN se.id IS NULL THEN 'session_exercise' ELSE '' END || ')', '; ') as details
FROM exercise_logs el
LEFT JOIN patients p ON p.id = el.patient_id
LEFT JOIN sessions s ON s.id = el.session_id
LEFT JOIN session_exercises se ON se.id = el.session_exercise_id
WHERE p.id IS NULL OR s.id IS NULL OR se.id IS NULL;

-- ============================================================================
-- CATEGORY 3: DATA CONSISTENCY
-- ============================================================================

-- Test 3.1: Program date consistency
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Programs - Date Logic Consistency',
  'Data Consistency',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ': ' || name || ' (end: ' || end_date || ' before start: ' || start_date || ')', '; ') as details
FROM programs
WHERE end_date < start_date;

-- Test 3.2: Phase date consistency within program
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Phases - Date Alignment with Program',
  'Data Consistency',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(ph.id::text || ': ' || ph.name, '; ') as details
FROM phases ph
JOIN programs pr ON pr.id = ph.program_id
WHERE ph.start_date < pr.start_date OR ph.end_date > pr.end_date;

-- Test 3.3: Overlapping phases within same program
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Phases - No Overlapping Dates',
  'Data Consistency',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(ph1.id::text || ' overlaps with ' || ph2.id::text, '; ') as details
FROM phases ph1
JOIN phases ph2 ON ph1.program_id = ph2.program_id AND ph1.id != ph2.id
WHERE ph1.start_date <= ph2.end_date AND ph1.end_date >= ph2.start_date;

-- Test 3.4: Pain scores within valid range (0-10)
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Pain Logs - Valid Pain Score Range',
  'Data Consistency',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ' (rest: ' || pain_rest || ', during: ' || pain_during || ', after: ' || pain_after || ')', '; ') as details
FROM pain_logs
WHERE pain_rest < 0 OR pain_rest > 10
   OR pain_during < 0 OR pain_during > 10
   OR pain_after < 0 OR pain_after > 10;

-- Test 3.5: RPE scores within valid range (0-10)
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercise Logs - Valid RPE Range',
  'Data Consistency',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ' (RPE: ' || rpe || ')', '; ') as details
FROM exercise_logs
WHERE rpe < 0 OR rpe > 10;

-- Test 3.6: Session intensity ratings within valid range
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Sessions - Valid Intensity Range',
  'Data Consistency',
  'error',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ': ' || name || ' (intensity: ' || intensity_rating || ')', '; ') as details
FROM sessions
WHERE intensity_rating IS NOT NULL AND (intensity_rating < 0 OR intensity_rating > 10);

-- ============================================================================
-- CATEGORY 4: RM FORMULA VALIDATION
-- ============================================================================

-- Test 4.1: Epley Formula Accuracy
-- Formula: 1RM = weight * (1 + reps/30)
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercise Logs - Epley RM Formula Accuracy',
  'RM Formulas',
  'info',
  CASE
    WHEN count(*) = 0 THEN true
    WHEN count(CASE WHEN abs(el.rm_estimate - (el.actual_load * (1 + el.actual_reps / 30.0))) > 1 THEN 1 END) = 0 THEN true
    ELSE false
  END as passed,
  count(CASE WHEN abs(el.rm_estimate - (el.actual_load * (1 + el.actual_reps / 30.0))) > 1 THEN 1 END) as issue_count,
  string_agg(
    CASE
      WHEN abs(el.rm_estimate - (el.actual_load * (1 + el.actual_reps / 30.0))) > 1
      THEN el.id::text || ' (stored: ' || el.rm_estimate || ', calculated: ' || round(el.actual_load * (1 + el.actual_reps / 30.0), 1) || ')'
      ELSE NULL
    END, '; ') as details
FROM exercise_logs el
JOIN session_exercises se ON se.id = el.session_exercise_id
JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE et.default_rm_method = 'epley'
  AND el.rm_estimate IS NOT NULL
  AND el.actual_load > 0
  AND el.actual_reps > 0;

-- Test 4.2: Brzycki Formula Accuracy
-- Formula: 1RM = weight / (1.0278 - 0.0278 * reps)
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercise Logs - Brzycki RM Formula Accuracy',
  'RM Formulas',
  'info',
  CASE
    WHEN count(*) = 0 THEN true
    WHEN count(CASE WHEN abs(el.rm_estimate - (el.actual_load / (1.0278 - 0.0278 * el.actual_reps))) > 1 THEN 1 END) = 0 THEN true
    ELSE false
  END as passed,
  count(CASE WHEN abs(el.rm_estimate - (el.actual_load / (1.0278 - 0.0278 * el.actual_reps))) > 1 THEN 1 END) as issue_count,
  string_agg(
    CASE
      WHEN abs(el.rm_estimate - (el.actual_load / (1.0278 - 0.0278 * el.actual_reps))) > 1
      THEN el.id::text || ' (stored: ' || el.rm_estimate || ', calculated: ' || round(el.actual_load / (1.0278 - 0.0278 * el.actual_reps), 1) || ')'
      ELSE NULL
    END, '; ') as details
FROM exercise_logs el
JOIN session_exercises se ON se.id = el.session_exercise_id
JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE et.default_rm_method = 'brzycki'
  AND el.rm_estimate IS NOT NULL
  AND el.actual_load > 0
  AND el.actual_reps > 0
  AND el.actual_reps < 10;  -- Brzycki not valid for reps >= 10

-- ============================================================================
-- CATEGORY 5: BUSINESS LOGIC VALIDATION
-- ============================================================================

-- Test 5.1: Active programs should have at least one phase
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Programs - Active Programs Have Phases',
  'Business Logic',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(pr.id::text || ': ' || pr.name, '; ') as details
FROM programs pr
LEFT JOIN phases ph ON ph.program_id = pr.id
WHERE pr.status = 'active'
GROUP BY pr.id, pr.name
HAVING count(ph.id) = 0;

-- Test 5.2: Phases should have at least one session
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Phases - All Phases Have Sessions',
  'Business Logic',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(ph.id::text || ': ' || ph.name, '; ') as details
FROM phases ph
LEFT JOIN sessions s ON s.phase_id = ph.id
GROUP BY ph.id, ph.name
HAVING count(s.id) = 0;

-- Test 5.3: Throwing sessions should be marked as throwing_day
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Sessions - Throwing Exercises Marked as Throwing Day',
  'Business Logic',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(s.id::text || ': ' || s.name, '; ') as details
FROM sessions s
JOIN session_exercises se ON se.session_id = s.id
JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE et.category = 'bullpen'
  AND s.is_throwing_day = false
GROUP BY s.id, s.name;

-- Test 5.4: Patients should have valid age (18-80 years)
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Patients - Valid Age Range',
  'Business Logic',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(id::text || ': ' || first_name || ' ' || last_name || ' (age: ' ||
    EXTRACT(YEAR FROM age(date_of_birth)) || ')', '; ') as details
FROM patients
WHERE date_of_birth IS NOT NULL
  AND (EXTRACT(YEAR FROM age(date_of_birth)) < 18 OR EXTRACT(YEAR FROM age(date_of_birth)) > 80);

-- Test 5.5: Exercise library should have exercises in all major categories
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercise Library - Coverage of Major Categories',
  'Business Logic',
  'info',
  CASE
    WHEN count(DISTINCT category) >= 5 THEN true
    ELSE false
  END as passed,
  5 - count(DISTINCT category) as issue_count,
  'Categories present: ' || string_agg(DISTINCT category, ', ') ||
  ' | Expected: strength, mobility, plyo, bullpen, cardio' as details
FROM exercise_templates
WHERE category IN ('strength', 'mobility', 'plyo', 'bullpen', 'cardio');

-- Test 5.6: Session exercises should have valid set/rep schemes
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Session Exercises - Valid Set/Rep Schemes',
  'Business Logic',
  'warning',
  count(*) = 0 as passed,
  count(*) as issue_count,
  string_agg(se.id::text || ' (sets: ' || se.target_sets || ', reps: ' || se.target_reps || ')', '; ') as details
FROM session_exercises se
WHERE se.target_sets <= 0 OR se.target_sets > 10
   OR se.target_reps <= 0 OR se.target_reps > 100;

-- ============================================================================
-- CATEGORY 6: DATA COMPLETENESS
-- ============================================================================

-- Test 6.1: Exercise library size
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
SELECT
  'Exercise Library - Minimum Size (50 exercises)',
  'Data Completeness',
  'error',
  count(*) >= 50 as passed,
  CASE WHEN count(*) < 50 THEN 50 - count(*) ELSE 0 END as issue_count,
  'Total exercises: ' || count(*) || ' (target: 50+)' as details
FROM exercise_templates;

-- Test 6.2: Demo data completeness
INSERT INTO data_quality_test_results (test_name, test_category, severity, passed, issue_count, details)
WITH demo_counts AS (
  SELECT
    (SELECT count(*) FROM therapists WHERE email = 'demo-pt@ptperformance.app') as therapist_count,
    (SELECT count(*) FROM patients WHERE email = 'demo-athlete@ptperformance.app') as patient_count,
    (SELECT count(*) FROM programs WHERE patient_id IN (SELECT id FROM patients WHERE email = 'demo-athlete@ptperformance.app')) as program_count,
    (SELECT count(*) FROM phases WHERE program_id IN (SELECT id FROM programs WHERE patient_id IN (SELECT id FROM patients WHERE email = 'demo-athlete@ptperformance.app'))) as phase_count,
    (SELECT count(*) FROM sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id IN (SELECT id FROM programs WHERE patient_id IN (SELECT id FROM patients WHERE email = 'demo-athlete@ptperformance.app')))) as session_count
)
SELECT
  'Demo Data - Completeness Check',
  'Data Completeness',
  'error',
  therapist_count = 1 AND patient_count = 1 AND program_count >= 1 AND phase_count = 4 AND session_count = 24 as passed,
  CASE
    WHEN therapist_count = 1 AND patient_count = 1 AND program_count >= 1 AND phase_count = 4 AND session_count = 24 THEN 0
    ELSE 1
  END as issue_count,
  'Therapists: ' || therapist_count || ' (expected: 1), ' ||
  'Patients: ' || patient_count || ' (expected: 1), ' ||
  'Programs: ' || program_count || ' (expected: 1+), ' ||
  'Phases: ' || phase_count || ' (expected: 4), ' ||
  'Sessions: ' || session_count || ' (expected: 24)' as details
FROM demo_counts;

-- ============================================================================
-- SUMMARY REPORT
-- ============================================================================

-- Overall summary
SELECT
  test_category,
  count(*) as total_tests,
  count(*) FILTER (WHERE passed) as tests_passed,
  count(*) FILTER (WHERE NOT passed) as tests_failed,
  count(*) FILTER (WHERE severity = 'error' AND NOT passed) as errors,
  count(*) FILTER (WHERE severity = 'warning' AND NOT passed) as warnings
FROM data_quality_test_results
GROUP BY test_category
ORDER BY
  count(*) FILTER (WHERE severity = 'error' AND NOT passed) DESC,
  count(*) FILTER (WHERE severity = 'warning' AND NOT passed) DESC;

-- Failed tests detail
SELECT
  test_name,
  test_category,
  severity,
  issue_count,
  details
FROM data_quality_test_results
WHERE NOT passed
ORDER BY
  CASE severity WHEN 'error' THEN 1 WHEN 'warning' THEN 2 ELSE 3 END,
  test_category,
  test_name;

-- Success summary
SELECT
  CASE
    WHEN count(*) FILTER (WHERE severity = 'error' AND NOT passed) = 0 THEN 'PASS'
    ELSE 'FAIL'
  END as overall_status,
  count(*) as total_tests,
  count(*) FILTER (WHERE passed) as passed,
  count(*) FILTER (WHERE NOT passed) as failed,
  round(100.0 * count(*) FILTER (WHERE passed) / count(*), 1) as pass_rate_pct,
  count(*) FILTER (WHERE severity = 'error' AND NOT passed) as critical_errors,
  count(*) FILTER (WHERE severity = 'warning' AND NOT passed) as warnings,
  count(*) FILTER (WHERE severity = 'info' AND NOT passed) as info_items
FROM data_quality_test_results;
