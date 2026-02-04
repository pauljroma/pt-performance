-- Allow demo patient to use lab_results without authentication
-- Demo patient ID: 00000000-0000-0000-0000-000000000001

-- Add policy for demo patient SELECT
CREATE POLICY "Demo patient view lab results" ON lab_results
    FOR SELECT USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Add policy for demo patient INSERT
CREATE POLICY "Demo patient insert lab results" ON lab_results
    FOR INSERT WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Add policy for demo patient UPDATE
CREATE POLICY "Demo patient update lab results" ON lab_results
    FOR UPDATE USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    ) WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Add policy for demo patient DELETE
CREATE POLICY "Demo patient delete lab results" ON lab_results
    FOR DELETE USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Same for biomarker_values - allow demo patient's lab results
CREATE POLICY "Demo patient view biomarker values" ON biomarker_values
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        )
    );

CREATE POLICY "Demo patient insert biomarker values" ON biomarker_values
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        )
    );
