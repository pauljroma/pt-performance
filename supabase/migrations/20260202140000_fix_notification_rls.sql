-- BUILD 385: Fix notification tables RLS policies
-- Ensures patients can access their notification settings even if user_id lookup fails
-- Uses email fallback similar to other RLS fixes

BEGIN;

-- Drop existing restrictive policies
DROP POLICY IF EXISTS "Patients can view own training patterns" ON training_time_patterns;
DROP POLICY IF EXISTS "System can manage training patterns" ON training_time_patterns;
DROP POLICY IF EXISTS "Patients can manage own notification settings" ON notification_settings;
DROP POLICY IF EXISTS "Patients can view own notification history" ON notification_history;
DROP POLICY IF EXISTS "System can manage notification history" ON notification_history;

-- ============================================================================
-- Training Time Patterns Policies
-- ============================================================================

-- SELECT: Patients can view their own patterns
CREATE POLICY "training_time_patterns_select"
    ON training_time_patterns
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT: Patients can insert their own patterns
CREATE POLICY "training_time_patterns_insert"
    ON training_time_patterns
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE: Patients can update their own patterns
CREATE POLICY "training_time_patterns_update"
    ON training_time_patterns
    FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE: Patients can delete their own patterns
CREATE POLICY "training_time_patterns_delete"
    ON training_time_patterns
    FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- Notification Settings Policies
-- ============================================================================

-- SELECT: Patients can view their own settings
CREATE POLICY "notification_settings_select"
    ON notification_settings
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT: Patients can insert their own settings
CREATE POLICY "notification_settings_insert"
    ON notification_settings
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE: Patients can update their own settings
CREATE POLICY "notification_settings_update"
    ON notification_settings
    FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE: Patients can delete their own settings
CREATE POLICY "notification_settings_delete"
    ON notification_settings
    FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- Notification History Policies
-- ============================================================================

-- SELECT: Patients can view their own history
CREATE POLICY "notification_history_select"
    ON notification_history
    FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT: Patients can insert their own history
CREATE POLICY "notification_history_insert"
    ON notification_history
    FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- Grant permissions
-- ============================================================================

GRANT ALL ON training_time_patterns TO authenticated;
GRANT ALL ON notification_settings TO authenticated;
GRANT ALL ON notification_history TO authenticated;

COMMIT;
