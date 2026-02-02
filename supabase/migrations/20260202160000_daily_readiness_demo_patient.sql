-- BUILD 385: Allow demo patient access for daily_readiness
-- The test patient 00000000-0000-0000-0000-000000000001 needs special handling
-- since it may not have user_id or email matching the logged-in user

-- Add policy for demo patient access (any authenticated user can use demo patient)
CREATE POLICY "daily_readiness_demo_patient"
    ON daily_readiness FOR ALL
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    )
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
    );

-- Also add to other key tables that might need demo patient access

-- notification_settings
DROP POLICY IF EXISTS "notification_settings_demo_patient" ON notification_settings;
CREATE POLICY "notification_settings_demo_patient"
    ON notification_settings FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- training_time_patterns
DROP POLICY IF EXISTS "training_time_patterns_demo_patient" ON training_time_patterns;
CREATE POLICY "training_time_patterns_demo_patient"
    ON training_time_patterns FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- notification_history
DROP POLICY IF EXISTS "notification_history_demo_patient" ON notification_history;
CREATE POLICY "notification_history_demo_patient"
    ON notification_history FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- patient_favorite_exercises
DROP POLICY IF EXISTS "patient_favorite_exercises_demo_patient" ON patient_favorite_exercises;
CREATE POLICY "patient_favorite_exercises_demo_patient"
    ON patient_favorite_exercises FOR ALL
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
