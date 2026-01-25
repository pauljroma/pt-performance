-- Migration: Fix nutrition_goals RLS policies (simple version)
-- Description: Allow authenticated users to manage their own nutrition goals
-- Issue: 42501 - "new row violates row-level security policy"

-- Drop any existing policies
DROP POLICY IF EXISTS "patients_select_own_goals" ON nutrition_goals;
DROP POLICY IF EXISTS "patients_insert_own_goals" ON nutrition_goals;
DROP POLICY IF EXISTS "patients_update_own_goals" ON nutrition_goals;
DROP POLICY IF EXISTS "patients_delete_own_goals" ON nutrition_goals;

-- Enable RLS
ALTER TABLE nutrition_goals ENABLE ROW LEVEL SECURITY;

-- Simple policies: patient_id must match auth.uid()
CREATE POLICY "patients_select_own_goals" ON nutrition_goals
    FOR SELECT USING (patient_id::text = auth.uid()::text);

CREATE POLICY "patients_insert_own_goals" ON nutrition_goals
    FOR INSERT WITH CHECK (patient_id::text = auth.uid()::text);

CREATE POLICY "patients_update_own_goals" ON nutrition_goals
    FOR UPDATE USING (patient_id::text = auth.uid()::text);

CREATE POLICY "patients_delete_own_goals" ON nutrition_goals
    FOR DELETE USING (patient_id::text = auth.uid()::text);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_goals TO authenticated;

-- Reload schema
NOTIFY pgrst, 'reload schema';
