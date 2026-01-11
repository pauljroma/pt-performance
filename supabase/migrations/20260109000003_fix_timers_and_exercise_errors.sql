-- Fix timer RLS and exercise save errors
-- BUILD 143: Apply both fixes to resolve production errors

-- ============================================================================
-- FIX 1: workout_timers RLS policies
-- ============================================================================
-- Error: "new row violates row-level security policy for table workout_timers"

DROP POLICY IF EXISTS "Patients can view their own timer sessions" ON workout_timers;
DROP POLICY IF EXISTS "Therapists can view all timer sessions" ON workout_timers;
DROP POLICY IF EXISTS "Patients can create their own timer sessions" ON workout_timers;
DROP POLICY IF EXISTS "Patients can update their own timer sessions" ON workout_timers;

-- Enable RLS
ALTER TABLE workout_timers ENABLE ROW LEVEL SECURITY;

-- Patient can view their own timer sessions
CREATE POLICY "Patients can view their own timer sessions"
    ON workout_timers FOR SELECT
    TO authenticated
    USING (patient_id = auth.uid());

-- Therapists can view all timer sessions
CREATE POLICY "Therapists can view all timer sessions"
    ON workout_timers FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

-- Patients can create their own timer sessions
CREATE POLICY "Patients can create their own timer sessions"
    ON workout_timers FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own timer sessions
CREATE POLICY "Patients can update their own timer sessions"
    ON workout_timers FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid());

-- ============================================================================
-- FIX 2: calculate_rm_estimate function for integer arrays
-- ============================================================================
-- Error: "function calculate_rm_estimate(numeric, integer[]) does not exist"

-- Drop existing functions
DROP FUNCTION IF EXISTS calculate_rm_estimate(numeric, integer) CASCADE;
DROP FUNCTION IF EXISTS calculate_rm_estimate(numeric, integer[]) CASCADE;

-- Create overloaded function for single integer (backwards compatibility)
CREATE OR REPLACE FUNCTION calculate_rm_estimate(
  weight numeric,
  reps integer
)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
BEGIN
  -- Epley formula: 1RM = weight × (1 + reps/30)
  IF reps IS NULL OR reps <= 0 OR weight IS NULL OR weight <= 0 THEN
    RETURN NULL;
  END IF;

  RETURN ROUND((weight * (1 + reps::numeric / 30))::numeric, 2);
END;
$$;

-- Create new function for integer array
-- Uses the LOWEST rep count (heaviest relative intensity) for best 1RM estimate
CREATE OR REPLACE FUNCTION calculate_rm_estimate(
  weight numeric,
  reps integer[]
)
RETURNS numeric
LANGUAGE plpgsql
IMMUTABLE
SET search_path = public
AS $$
DECLARE
  min_reps integer;
BEGIN
  -- Validate inputs
  IF weight IS NULL OR weight <= 0 OR reps IS NULL OR array_length(reps, 1) IS NULL THEN
    RETURN NULL;
  END IF;

  -- Get minimum reps (closest to failure = best 1RM estimate)
  SELECT MIN(r) INTO min_reps FROM unnest(reps) AS r WHERE r > 0;

  IF min_reps IS NULL OR min_reps <= 0 THEN
    RETURN NULL;
  END IF;

  -- Epley formula: 1RM = weight × (1 + reps/30)
  RETURN ROUND((weight * (1 + min_reps::numeric / 30))::numeric, 2);
END;
$$;

-- Add comments
COMMENT ON FUNCTION calculate_rm_estimate(numeric, integer) IS
  'Calculate 1RM estimate using Epley formula for single rep count';

COMMENT ON FUNCTION calculate_rm_estimate(numeric, integer[]) IS
  'Calculate 1RM estimate using Epley formula for rep array (uses minimum reps)';

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION calculate_rm_estimate(numeric, integer) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_rm_estimate(numeric, integer) TO service_role;
GRANT EXECUTE ON FUNCTION calculate_rm_estimate(numeric, integer[]) TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_rm_estimate(numeric, integer[]) TO service_role;

-- Recreate trigger function to use array version
DROP FUNCTION IF EXISTS update_rm_estimate() CASCADE;

CREATE OR REPLACE FUNCTION update_rm_estimate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  -- Update RM estimate when weight/reps change
  -- Now handles actual_reps as integer array
  IF NEW.actual_load IS NOT NULL AND NEW.actual_load > 0
     AND NEW.actual_reps IS NOT NULL AND array_length(NEW.actual_reps, 1) > 0 THEN
    NEW.rm_estimate := calculate_rm_estimate(NEW.actual_load, NEW.actual_reps);
  END IF;

  RETURN NEW;
END;
$$;

COMMENT ON FUNCTION update_rm_estimate() IS
  'Trigger function to update RM estimate. Handles actual_reps as integer array.';

-- Recreate trigger
DROP TRIGGER IF EXISTS update_rm_estimate_trigger ON exercise_logs;
CREATE TRIGGER update_rm_estimate_trigger
  BEFORE INSERT OR UPDATE ON exercise_logs
  FOR EACH ROW
  EXECUTE FUNCTION update_rm_estimate();

-- Backfill RM estimates for existing records
UPDATE exercise_logs
SET rm_estimate = calculate_rm_estimate(actual_load, actual_reps)
WHERE actual_load IS NOT NULL
  AND actual_load > 0
  AND actual_reps IS NOT NULL
  AND array_length(actual_reps, 1) > 0
  AND rm_estimate IS NULL;

-- ============================================================================
-- Completion Log
-- ============================================================================
DO $$
BEGIN
  RAISE NOTICE 'BUILD 143: Timer and Exercise fixes applied';
  RAISE NOTICE '  ✅ workout_timers RLS policies created';
  RAISE NOTICE '  ✅ Patients can create/view/update their own timer sessions';
  RAISE NOTICE '  ✅ Therapists can view all timer sessions';
  RAISE NOTICE '  ✅ calculate_rm_estimate(numeric, integer) created';
  RAISE NOTICE '  ✅ calculate_rm_estimate(numeric, integer[]) created';
  RAISE NOTICE '  ✅ update_rm_estimate() trigger recreated';
  RAISE NOTICE '  ✅ Existing exercise_logs backfilled';
END $$;
