-- BUILD 384: Simple RLS fix for daily_readiness
-- Allow authenticated users full access to daily_readiness for their patients

BEGIN;

-- Enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Drop all existing policies
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN SELECT policyname FROM pg_policies WHERE tablename = 'daily_readiness'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS %I ON daily_readiness', pol.policyname);
    END LOOP;
END $$;

-- Simple policy: authenticated users can manage readiness for patients they own
CREATE POLICY "daily_readiness_patient_access"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    )
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Therapist access: can view readiness for their patients
CREATE POLICY "daily_readiness_therapist_view"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid()
        )
    );

-- Grant permissions
GRANT ALL ON daily_readiness TO authenticated;

COMMIT;
