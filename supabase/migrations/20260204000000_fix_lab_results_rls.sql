-- Fix RLS policies for lab_results table
-- The policies were incorrectly checking patient_id = auth.uid()
-- But patient_id is the patient's ID, not the auth user's ID
-- We need to verify ownership through the patients table

-- Drop existing policies
DROP POLICY IF EXISTS "Patients view own lab results" ON lab_results;
DROP POLICY IF EXISTS "Patients insert own lab results" ON lab_results;
DROP POLICY IF EXISTS "Patients update own lab results" ON lab_results;
DROP POLICY IF EXISTS "Patients delete own lab results" ON lab_results;

-- Create corrected policies that check ownership through patients table
CREATE POLICY "Patients view own lab results" ON lab_results
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = lab_results.patient_id
            AND patients.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients insert own lab results" ON lab_results
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = lab_results.patient_id
            AND patients.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients update own lab results" ON lab_results
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = lab_results.patient_id
            AND patients.user_id = auth.uid()
        )
    ) WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = lab_results.patient_id
            AND patients.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients delete own lab results" ON lab_results
    FOR DELETE USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = lab_results.patient_id
            AND patients.user_id = auth.uid()
        )
    );

-- Also fix biomarker_values table if it has the same issue
DROP POLICY IF EXISTS "Patients view own biomarker values" ON biomarker_values;
DROP POLICY IF EXISTS "Patients insert own biomarker values" ON biomarker_values;

CREATE POLICY "Patients view own biomarker values" ON biomarker_values
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM lab_results lr
            JOIN patients p ON p.id = lr.patient_id
            WHERE lr.id = biomarker_values.lab_result_id
            AND p.user_id = auth.uid()
        )
    );

CREATE POLICY "Patients insert own biomarker values" ON biomarker_values
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM lab_results lr
            JOIN patients p ON p.id = lr.patient_id
            WHERE lr.id = biomarker_values.lab_result_id
            AND p.user_id = auth.uid()
        )
    );

-- Verify RLS is enabled
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE biomarker_values ENABLE ROW LEVEL SECURITY;
