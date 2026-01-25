-- Migration: Fix nutrition_logs RLS using email matching (like nutrition_goals)
-- Description: Match patient via email from JWT token
-- Issue: 42501 - "new row violates row-level security policy for table nutrition_logs"

-- Drop existing policies
DROP POLICY IF EXISTS "Patients can view their own nutrition logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Patients can insert their own nutrition logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Patients can update their own nutrition logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Patients can delete their own nutrition logs" ON nutrition_logs;
DROP POLICY IF EXISTS "Therapists can view patient nutrition logs" ON nutrition_logs;

-- Enable RLS
ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;

-- SELECT policy - join with patients table and check email
CREATE POLICY "nutrition_logs_select" ON nutrition_logs
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = nutrition_logs.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT policy
CREATE POLICY "nutrition_logs_insert" ON nutrition_logs
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "nutrition_logs_update" ON nutrition_logs
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = nutrition_logs.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "nutrition_logs_delete" ON nutrition_logs
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = nutrition_logs.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_logs TO authenticated;

-- Reload schema
NOTIFY pgrst, 'reload schema';
