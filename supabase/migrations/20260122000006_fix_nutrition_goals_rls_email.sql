-- Migration: Fix nutrition_goals RLS using email matching (like meal_plan_items)
-- Description: Match patient via email from JWT token
-- Issue: patient_id doesn't match auth.uid() directly

-- Drop existing policies
DROP POLICY IF EXISTS "patients_select_own_goals" ON nutrition_goals;
DROP POLICY IF EXISTS "patients_insert_own_goals" ON nutrition_goals;
DROP POLICY IF EXISTS "patients_update_own_goals" ON nutrition_goals;
DROP POLICY IF EXISTS "patients_delete_own_goals" ON nutrition_goals;

-- Enable RLS
ALTER TABLE nutrition_goals ENABLE ROW LEVEL SECURITY;

-- SELECT policy - join with patients table and check email
CREATE POLICY "nutrition_goals_select" ON nutrition_goals
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = nutrition_goals.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT policy
CREATE POLICY "nutrition_goals_insert" ON nutrition_goals
    FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "nutrition_goals_update" ON nutrition_goals
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = nutrition_goals.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "nutrition_goals_delete" ON nutrition_goals
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = nutrition_goals.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON nutrition_goals TO authenticated;

-- Reload schema
NOTIFY pgrst, 'reload schema';
