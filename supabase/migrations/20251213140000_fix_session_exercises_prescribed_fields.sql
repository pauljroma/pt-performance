-- 20251213140000_fix_session_exercises_prescribed_fields.sql
-- Fix session_exercises to populate prescribed_* fields for iOS app compatibility
-- The iOS app expects prescribed_sets (Int, non-optional) but migration used target_sets

-- ============================================================================
-- UPDATE EXISTING WINTER LIFT EXERCISES
-- ============================================================================

-- Copy target_* values to prescribed_* fields for compatibility
UPDATE session_exercises
SET
  prescribed_sets = target_sets,
  prescribed_reps = target_reps::text,  -- Convert int to text
  prescribed_load = target_load,
  rest_period_seconds = COALESCE(rest_period_seconds, 90),  -- Default 90 seconds
  order_index = sequence  -- Use sequence as order_index
WHERE session_id IN (
  SELECT id FROM sessions WHERE phase_id IN (
    SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300'
  )
);

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
DECLARE
  exercises_fixed int;
  exercises_with_null_prescribed int;
BEGIN
  -- Count exercises that were fixed
  SELECT COUNT(*) INTO exercises_fixed
  FROM session_exercises
  WHERE session_id IN (
    SELECT id FROM sessions WHERE phase_id IN (
      SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300'
    )
  )
  AND prescribed_sets IS NOT NULL;

  -- Count exercises that still have null prescribed_sets
  SELECT COUNT(*) INTO exercises_with_null_prescribed
  FROM session_exercises
  WHERE session_id IN (
    SELECT id FROM sessions WHERE phase_id IN (
      SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300'
    )
  )
  AND prescribed_sets IS NULL;

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'SESSION EXERCISES PRESCRIBED FIELDS FIX';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Exercises with prescribed_sets: %', exercises_fixed;
  RAISE NOTICE 'Exercises with NULL prescribed_sets: %', exercises_with_null_prescribed;
  RAISE NOTICE '============================================';
END $$;
