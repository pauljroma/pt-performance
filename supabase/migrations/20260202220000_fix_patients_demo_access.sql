-- BUILD 386: Fix cascading RLS failure for daily_readiness
--
-- ROOT CAUSE: daily_readiness RLS policies subquery the patients table.
-- When the subquery runs, it applies the current user's RLS context.
-- If the user can't read the demo patient row from patients table,
-- the subquery returns zero rows, and the daily_readiness policy fails.
--
-- FIX: Add a policy to patients table allowing any authenticated user
-- to read the demo patient row. This breaks the cascading failure.

BEGIN;

-- Add policy to allow any authenticated user to read demo patient
-- This is ESSENTIAL for daily_readiness RLS to work with demo patient
CREATE POLICY "patients_demo_patient_access"
    ON patients FOR SELECT
    TO authenticated
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Also ensure the daily_readiness table has proper demo patient access
-- Drop all existing policies first to avoid conflicts
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Create comprehensive policy that handles all cases
-- Using OR conditions to avoid nested subquery failures
CREATE POLICY "daily_readiness_all_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        -- Case 1: Demo patient (any authenticated user)
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        -- Case 2: Own patient via user_id linkage
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR
        -- Case 3: Own patient via email fallback (legacy)
        patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    )
    WITH CHECK (
        -- Can only write to demo patient or own patient
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR
        patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR
        patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Ensure grants
GRANT SELECT, INSERT, UPDATE, DELETE ON daily_readiness TO authenticated;

COMMIT;
