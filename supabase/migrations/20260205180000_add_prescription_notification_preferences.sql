-- Fix notifications not saving: Create missing prescription_notification_preferences table
-- The SmartNotificationService references this table but it was never created
--
-- Build 439+ - Added missing table for prescription notification preferences

-- ============================================================================
-- Prescription Notification Preferences Table
-- Stores user preferences for prescription-related notifications
-- ============================================================================

CREATE TABLE IF NOT EXISTS prescription_notification_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    new_prescription_enabled BOOLEAN DEFAULT true,
    deadline_24h_enabled BOOLEAN DEFAULT true,
    deadline_6h_enabled BOOLEAN DEFAULT true,
    deadline_1h_enabled BOOLEAN DEFAULT true,
    overdue_enabled BOOLEAN DEFAULT true,
    therapist_follow_up_enabled BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_patient_prescription_notification_prefs UNIQUE (patient_id)
);

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_prescription_notification_prefs_patient
    ON prescription_notification_preferences(patient_id);

-- ============================================================================
-- RLS Policies
-- Using correct pattern: join through patients table where user_id = auth.uid()
-- ============================================================================

ALTER TABLE prescription_notification_preferences ENABLE ROW LEVEL SECURITY;

-- SELECT: Patients can view their own preferences
CREATE POLICY "prescription_notification_preferences_select"
    ON prescription_notification_preferences
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = prescription_notification_preferences.patient_id
            AND (p.user_id = auth.uid() OR p.email = (auth.jwt() ->> 'email'))
        )
    );

-- INSERT: Patients can insert their own preferences
CREATE POLICY "prescription_notification_preferences_insert"
    ON prescription_notification_preferences
    FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = prescription_notification_preferences.patient_id
            AND (p.user_id = auth.uid() OR p.email = (auth.jwt() ->> 'email'))
        )
    );

-- UPDATE: Patients can update their own preferences
CREATE POLICY "prescription_notification_preferences_update"
    ON prescription_notification_preferences
    FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = prescription_notification_preferences.patient_id
            AND (p.user_id = auth.uid() OR p.email = (auth.jwt() ->> 'email'))
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = prescription_notification_preferences.patient_id
            AND (p.user_id = auth.uid() OR p.email = (auth.jwt() ->> 'email'))
        )
    );

-- DELETE: Patients can delete their own preferences
CREATE POLICY "prescription_notification_preferences_delete"
    ON prescription_notification_preferences
    FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = prescription_notification_preferences.patient_id
            AND (p.user_id = auth.uid() OR p.email = (auth.jwt() ->> 'email'))
        )
    );

-- ============================================================================
-- Add prescription_id column to notification_history if missing
-- Required for tracking prescription-related notifications
-- ============================================================================

ALTER TABLE notification_history
    ADD COLUMN IF NOT EXISTS prescription_id UUID REFERENCES workout_prescriptions(id) ON DELETE SET NULL;

-- Update notification_type check constraint to include prescription types
ALTER TABLE notification_history
    DROP CONSTRAINT IF EXISTS notification_history_notification_type_check;

ALTER TABLE notification_history
    ADD CONSTRAINT notification_history_notification_type_check
    CHECK (notification_type IN (
        'workout_reminder',
        'streak_alert',
        'weekly_summary',
        'custom',
        'prescription_assigned',
        'prescription_deadline_24h',
        'prescription_deadline_6h',
        'prescription_deadline_1h',
        'prescription_overdue',
        'therapist_follow_up'
    ));

-- Index for prescription-related notification queries
CREATE INDEX IF NOT EXISTS idx_notification_history_prescription
    ON notification_history(prescription_id) WHERE prescription_id IS NOT NULL;

-- ============================================================================
-- Grants
-- ============================================================================

GRANT ALL ON prescription_notification_preferences TO authenticated;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE prescription_notification_preferences IS
    'User preferences for prescription-related notifications (deadlines, overdue alerts, etc.)';

COMMENT ON COLUMN prescription_notification_preferences.new_prescription_enabled IS
    'Notify when a new prescription is assigned by therapist';
COMMENT ON COLUMN prescription_notification_preferences.deadline_24h_enabled IS
    'Notify 24 hours before prescription deadline';
COMMENT ON COLUMN prescription_notification_preferences.deadline_6h_enabled IS
    'Notify 6 hours before prescription deadline';
COMMENT ON COLUMN prescription_notification_preferences.deadline_1h_enabled IS
    'Notify 1 hour before prescription deadline (final reminder)';
COMMENT ON COLUMN prescription_notification_preferences.overdue_enabled IS
    'Notify when prescription becomes overdue';
COMMENT ON COLUMN prescription_notification_preferences.therapist_follow_up_enabled IS
    'For therapists: notify for patient follow-ups';
