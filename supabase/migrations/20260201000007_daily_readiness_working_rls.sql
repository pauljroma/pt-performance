-- BUILD 366: Working RLS for daily_readiness
-- Uses subquery to check patient ownership

-- Enable RLS
ALTER TABLE daily_readiness ENABLE ROW LEVEL SECURITY;

-- Single policy for all operations
-- Check that patient_id belongs to a patient owned by current user
CREATE POLICY "users_manage_own_patient_readiness"
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

GRANT ALL ON daily_readiness TO authenticated;

COMMENT ON TABLE daily_readiness IS 'BUILD 366 - Working RLS with patient ownership check';
