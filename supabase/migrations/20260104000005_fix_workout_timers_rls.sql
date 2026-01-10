-- Fix workout_timers RLS policies
-- BUILD 137: Ensure RLS is enabled and policies are correct

-- Drop existing policies (if any) to avoid conflicts
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

-- Log completion
DO $$
BEGIN
  RAISE NOTICE 'BUILD 137: workout_timers RLS policies fixed';
  RAISE NOTICE '  ✅ RLS enabled on workout_timers';
  RAISE NOTICE '  ✅ Patients can view their own timer sessions';
  RAISE NOTICE '  ✅ Therapists can view all timer sessions';
  RAISE NOTICE '  ✅ Patients can create their own timer sessions';
  RAISE NOTICE '  ✅ Patients can update their own timer sessions';
END $$;
