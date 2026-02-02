-- BUILD 385: Proper RLS for daily_readiness (HIPAA compliant)
-- Must protect PHI while allowing legitimate access

BEGIN;

-- Re-enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Drop ALL existing policies first
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Policy 1: Patients can access their own readiness data
-- Uses both user_id and email fallback for legacy records
CREATE POLICY "daily_readiness_patient_own"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- Policy 2: Demo patient access (for testing only)
-- Allows any authenticated user to access the demo patient
CREATE POLICY "daily_readiness_demo_patient"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Policy 3: Therapists can view their patients' readiness
CREATE POLICY "daily_readiness_therapist_view"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid()
               OR t.email = (auth.jwt() ->> 'email')
        )
    );

-- Ensure grants
GRANT ALL ON daily_readiness TO authenticated;

COMMIT;
