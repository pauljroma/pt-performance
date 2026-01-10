-- ============================================================================
-- COMPLETE DEMO RESET: Clean + Load Fresh Data
-- ============================================================================
-- Execute this in Supabase Dashboard → SQL Editor
-- This will:
--   1. Clean all old session data
--   2. Load fresh data from John Brebbia Excel spreadsheet
-- ============================================================================

-- ============================================================================
-- STEP 1: CLEANUP OLD DATA
-- ============================================================================

DO $$
DECLARE
  v_patient_id uuid := '00000000-0000-0000-0000-000000000001'::uuid;
  v_therapist_id uuid := '00000000-0000-0000-0000-000000000100'::uuid;
  v_patient_email text := 'demo-athlete@ptperformance.app';
  v_therapist_email text := 'demo-pt@ptperformance.app';

  -- Counters
  exercise_logs_deleted int;
  pain_logs_deleted int;
  bullpen_logs_deleted int;
  plyo_logs_deleted int;
  body_comp_deleted int;
  session_status_deleted int;
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE 'STEP 1: CLEANUP OLD DATA';
  RAISE NOTICE '========================================';

  -- Delete exercise logs
  DELETE FROM exercise_logs WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS exercise_logs_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % exercise logs', exercise_logs_deleted;

  -- Delete pain logs
  DELETE FROM pain_logs WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS pain_logs_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % pain logs', pain_logs_deleted;

  -- Delete bullpen logs
  DELETE FROM bullpen_logs WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS bullpen_logs_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % bullpen logs', bullpen_logs_deleted;

  -- Delete plyo logs
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'plyo_logs') THEN
    DELETE FROM plyo_logs WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS plyo_logs_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % plyo logs', plyo_logs_deleted;
  END IF;

  -- Delete body comp
  DELETE FROM body_comp_measurements WHERE patient_id = v_patient_id;
  GET DIAGNOSTICS body_comp_deleted = ROW_COUNT;
  RAISE NOTICE '✓ Deleted % body comp measurements', body_comp_deleted;

  -- Delete session status
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'session_status') THEN
    DELETE FROM session_status WHERE patient_id = v_patient_id;
    GET DIAGNOSTICS session_status_deleted = ROW_COUNT;
    RAISE NOTICE '✓ Deleted % session status records', session_status_deleted;
  END IF;

  -- Delete AI conversations
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'ai_conversations') THEN
    DELETE FROM ai_conversations WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted AI conversations';
  END IF;

  -- Delete scheduled sessions
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'scheduled_sessions') THEN
    DELETE FROM scheduled_sessions WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted scheduled sessions';
  END IF;

  -- Delete workload flags
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workload_flags') THEN
    DELETE FROM workload_flags WHERE patient_id = v_patient_id;
    RAISE NOTICE '✓ Deleted workload flags';
  END IF;

  RAISE NOTICE '✅ Cleanup complete!';
  RAISE NOTICE '';
END $$;

-- ============================================================================
-- STEP 2: LOAD FRESH DEMO DATA
-- ============================================================================
-- ============================================================================
-- JOHN BREBBIA DEMO DATA LOADER
-- Generated from Excel file: John Brebbia - example profile.xlsx
-- ============================================================================
-- This script loads realistic demo data for John Brebbia's account
-- Run AFTER cleanup_john_brebbia_demo.sql for a fresh demo state
-- ============================================================================


-- ============================================================================
-- BODY COMPOSITION MEASUREMENTS
-- ============================================================================


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-06'::date,
  207.2,
  13.8,
  'Weight: 207.2 lbs, SMM: 103.4 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-09'::date,
  211.6,
  13.4,
  'Weight: 211.6 lbs, SMM: 105.4 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-13'::date,
  211.5,
  13.7,
  'Weight: 211.5 lbs, SMM: 105.4 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-15'::date,
  212.4,
  13.0,
  'Weight: 212.4 lbs, SMM: 106.9 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-17'::date,
  213.1,
  12.9,
  'Weight: 213.1 lbs, SMM: 107.4 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-20'::date,
  212.2,
  13.3,
  'Weight: 212.2 lbs, SMM: 106.5 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-22'::date,
  215.2,
  14.0,
  'Weight: 215.2 lbs, SMM: 107.1 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-24'::date,
  216.1,
  13.5,
  'Weight: 216.1 lbs, SMM: 108.2 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-27'::date,
  216.7,
  14.4,
  'Weight: 216.7 lbs, SMM: 106.9 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-29'::date,
  217.9,
  14.9,
  'Weight: 217.9 lbs, SMM: 106.9 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-10-31'::date,
  217.6,
  14.7,
  'Weight: 217.6 lbs, SMM: 107.1 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-11-03'::date,
  216.9,
  15.1,
  'Weight: 216.9 lbs, SMM: 106.0 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-11-05'::date,
  219.0,
  15.2,
  'Weight: 219.0 lbs, SMM: 107.4 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-11-12'::date,
  220.5,
  15.8,
  'Weight: 220.5 lbs, SMM: 107.1 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-11-14'::date,
  220.2,
  15.6,
  'Weight: 220.2 lbs, SMM: 107.6 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-11-17'::date,
  219.9,
  15.7,
  'Weight: 219.9 lbs, SMM: 106.9 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-11-21'::date,
  221.3,
  16.0,
  'Weight: 221.3 lbs, SMM: 107.6 lbs'
)
ON CONFLICT DO NOTHING;


INSERT INTO body_comp_measurements (patient_id, measured_at, weight_lb, body_fat_pct, notes)
VALUES (
  '00000000-0000-0000-0000-000000000001'::uuid,
  '2025-12-01'::date,
  221.4,
  16.8,
  'Weight: 221.4 lbs, SMM: 106.3 lbs'
)
ON CONFLICT DO NOTHING;


-- ============================================================================
-- STRENGTH & CONDITIONING DATA (1RM ESTIMATES)
-- ============================================================================
-- Note: These should be linked to actual exercise_templates
-- For now, storing as comments for reference

-- Trap Bar Deadlift: 290.0 lbs x 6 reps = ~348.0 lbs 1RM

-- SSB Squat: 205.0 lbs x 8 reps = ~259.7 lbs 1RM

-- Barbell RDL: 225.0 lbs x 5 reps = ~262.5 lbs 1RM

-- Barbell Hip Thrust: 405.0 lbs x 5 reps = ~472.5 lbs 1RM

-- SSB Reverse Lunge: 135.0 lbs x 8 reps = ~171.0 lbs 1RM

-- 1-Arm DB Row: 115.0 lbs x 5 reps = ~134.2 lbs 1RM

-- Landmine Press (Split Stance): 50.0 lbs x 5 reps = ~58.3 lbs 1RM

-- DB Bench Press: 190.0 lbs x 5 reps = ~221.7 lbs 1RM

-- 2025-11-05 00:00:00: 6.0 lbs x 2 reps = ~3.0 lbs 1RM

-- 2025-12-05 00:00:00: 7.0 lbs x 2 reps = ~3.0 lbs 1RM

-- 2026-01-05 00:00:00: 7.0 lbs x 3 reps = ~3.0 lbs 1RM

-- 2025-11-05 00:00:00: 6.0 lbs x 7 reps = ~8.0 lbs 1RM

-- 2025-12-05 00:00:00: 5.0 lbs x 6 reps = ~7.0 lbs 1RM

-- 2026-01-05 00:00:00: 4.0 lbs x 5 reps = ~6.0 lbs 1RM


-- ============================================================================
-- ON-RAMP THROWING PROGRESSION
-- ============================================================================
-- Velocities with different ball weights during on-ramp program


-- 2025-12-05: Throw #1 - 5oz: 85.0mph, 6oz: 83.0mph, 4oz: 96.0mph


-- ============================================================================
-- PLYOMETRIC DRILL DATA
-- ============================================================================


INSERT INTO plyo_logs (patient_id, logged_at, drill_name, ball_weight_oz, velocity, throw_count, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-11-17'::timestamptz, 'Drill 1', 7.0, 80.0, 1, 'Throw 1'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-11-17'::timestamptz, 'Drill 1', 5.0, 80.0, 1, 'Throw 1'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-11-17'::timestamptz, 'Drill 1', 3.5, 90.0, 1, 'Throw 1')
ON CONFLICT DO NOTHING;


-- ============================================================================
-- VERIFICATION
-- ============================================================================
SELECT
  'Body Comp Measurements' as data_type,
  count(*) as count
FROM body_comp_measurements
WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid

UNION ALL

SELECT
  'Plyo Logs',
  count(*)
FROM plyo_logs
WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid;
