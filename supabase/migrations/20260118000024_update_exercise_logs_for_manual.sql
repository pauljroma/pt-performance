-- Update exercise_logs table to support manual workout logging
-- Adds manual_session_exercise_id column with XOR constraint

-- Add the new column for manual session exercises
ALTER TABLE exercise_logs
    ADD COLUMN IF NOT EXISTS manual_session_exercise_id UUID REFERENCES manual_session_exercises(id) ON DELETE CASCADE;

-- Make session_exercise_id nullable (was required before)
ALTER TABLE exercise_logs
    ALTER COLUMN session_exercise_id DROP NOT NULL;

-- Add XOR constraint: must have exactly one reference (either prescribed OR manual)
-- First drop if exists (for idempotency)
ALTER TABLE exercise_logs DROP CONSTRAINT IF EXISTS exercise_logs_session_xor_manual;

ALTER TABLE exercise_logs ADD CONSTRAINT exercise_logs_session_xor_manual
    CHECK (
        (session_exercise_id IS NOT NULL AND manual_session_exercise_id IS NULL) OR
        (session_exercise_id IS NULL AND manual_session_exercise_id IS NOT NULL)
    );

-- Create index for manual session exercise lookups
CREATE INDEX IF NOT EXISTS idx_exercise_logs_manual_session_exercise
    ON exercise_logs(manual_session_exercise_id)
    WHERE manual_session_exercise_id IS NOT NULL;

-- Update RLS policy to allow patients to log manual workouts
DROP POLICY IF EXISTS "Patients can insert their own exercise logs" ON exercise_logs;

CREATE POLICY "Patients can insert their own exercise logs" ON exercise_logs
    FOR INSERT
    WITH CHECK (
        patient_id = auth.uid()
    );

-- Grant access
GRANT SELECT, INSERT, UPDATE ON exercise_logs TO authenticated;
