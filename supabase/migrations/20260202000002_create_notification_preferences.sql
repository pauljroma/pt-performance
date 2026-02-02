-- 20260202000002_create_notification_preferences.sql
-- Smart Notification Timing Feature (ACP-841)
-- Tracks user training patterns and notification preferences for adaptive reminders

-- ============================================================================
-- Training Time Patterns
-- Stores historical workout timing data per day of week
-- ============================================================================

CREATE TABLE IF NOT EXISTS training_time_patterns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sunday, 6=Saturday
    preferred_hour INTEGER CHECK (preferred_hour BETWEEN 0 AND 23),
    workout_count INTEGER DEFAULT 0,
    avg_start_time TIME,
    confidence_score NUMERIC DEFAULT 0 CHECK (confidence_score BETWEEN 0 AND 1), -- Higher = more reliable pattern
    last_updated TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_patient_day UNIQUE (patient_id, day_of_week)
);

-- Index for efficient lookups by patient
CREATE INDEX IF NOT EXISTS idx_training_patterns_patient ON training_time_patterns(patient_id);

-- ============================================================================
-- Notification Settings
-- User preferences for workout reminders
-- ============================================================================

CREATE TABLE IF NOT EXISTS notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    smart_timing_enabled BOOLEAN DEFAULT true,
    fallback_reminder_time TIME DEFAULT '09:00',
    reminder_minutes_before INTEGER DEFAULT 30 CHECK (reminder_minutes_before BETWEEN 5 AND 120),
    streak_alerts_enabled BOOLEAN DEFAULT true,
    weekly_summary_enabled BOOLEAN DEFAULT true,
    quiet_hours_start TIME DEFAULT '22:00',
    quiet_hours_end TIME DEFAULT '07:00',
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_patient_notification_settings UNIQUE (patient_id)
);

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_notification_settings_patient ON notification_settings(patient_id);

-- ============================================================================
-- Notification History
-- Track sent notifications for analytics and deduplication
-- ============================================================================

CREATE TABLE IF NOT EXISTS notification_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    notification_type TEXT NOT NULL CHECK (notification_type IN ('workout_reminder', 'streak_alert', 'weekly_summary', 'custom')),
    title TEXT NOT NULL,
    body TEXT,
    scheduled_for TIMESTAMPTZ NOT NULL,
    sent_at TIMESTAMPTZ,
    opened_at TIMESTAMPTZ,
    action_taken BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for querying notification history
CREATE INDEX IF NOT EXISTS idx_notification_history_patient ON notification_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_notification_history_scheduled ON notification_history(scheduled_for);

-- ============================================================================
-- Function: analyze_training_patterns
-- Analyzes workout completion times and updates patterns table
-- ============================================================================

CREATE OR REPLACE FUNCTION analyze_training_patterns(p_patient_id UUID)
RETURNS VOID AS $$
DECLARE
    day_rec RECORD;
    avg_time TIME;
    pattern_count INTEGER;
    confidence NUMERIC;
    pref_hour INTEGER;
BEGIN
    -- Analyze workout patterns for each day of the week
    FOR day_rec IN
        SELECT
            EXTRACT(DOW FROM performed_at) AS dow,
            COUNT(*) AS workout_count,
            AVG(EXTRACT(HOUR FROM performed_at) * 60 + EXTRACT(MINUTE FROM performed_at)) AS avg_minutes
        FROM exercise_logs
        WHERE patient_id = p_patient_id
          AND performed_at > NOW() - INTERVAL '90 days' -- Look at last 90 days
        GROUP BY EXTRACT(DOW FROM performed_at)
        HAVING COUNT(*) >= 2 -- Need at least 2 data points
    LOOP
        -- Calculate average time as TIME type
        avg_time := make_time(
            FLOOR(day_rec.avg_minutes / 60)::INTEGER,
            (day_rec.avg_minutes::INTEGER % 60),
            0
        );

        -- Calculate preferred hour
        pref_hour := FLOOR(day_rec.avg_minutes / 60)::INTEGER;

        -- Calculate confidence (more workouts = higher confidence, max at 10 workouts)
        confidence := LEAST(day_rec.workout_count / 10.0, 1.0);

        -- Upsert the pattern
        INSERT INTO training_time_patterns (
            patient_id,
            day_of_week,
            preferred_hour,
            workout_count,
            avg_start_time,
            confidence_score,
            last_updated
        )
        VALUES (
            p_patient_id,
            day_rec.dow::INTEGER,
            pref_hour,
            day_rec.workout_count,
            avg_time,
            confidence,
            NOW()
        )
        ON CONFLICT (patient_id, day_of_week)
        DO UPDATE SET
            preferred_hour = EXCLUDED.preferred_hour,
            workout_count = EXCLUDED.workout_count,
            avg_start_time = EXCLUDED.avg_start_time,
            confidence_score = EXCLUDED.confidence_score,
            last_updated = NOW();
    END LOOP;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Function: get_optimal_reminder_time
-- Returns the best time to send a workout reminder for a given day
-- ============================================================================

CREATE OR REPLACE FUNCTION get_optimal_reminder_time(
    p_patient_id UUID,
    p_day_of_week INTEGER
)
RETURNS JSONB AS $$
DECLARE
    pattern_rec RECORD;
    settings_rec RECORD;
    reminder_time TIME;
    result_time TIMESTAMPTZ;
    is_smart BOOLEAN;
BEGIN
    -- Get notification settings
    SELECT * INTO settings_rec
    FROM notification_settings
    WHERE patient_id = p_patient_id;

    -- If no settings exist, use defaults
    IF NOT FOUND THEN
        settings_rec.smart_timing_enabled := true;
        settings_rec.fallback_reminder_time := '09:00'::TIME;
        settings_rec.reminder_minutes_before := 30;
    END IF;

    -- If smart timing is disabled, use fallback
    IF NOT settings_rec.smart_timing_enabled THEN
        RETURN jsonb_build_object(
            'reminder_time', settings_rec.fallback_reminder_time,
            'is_smart', false,
            'confidence', 0
        );
    END IF;

    -- Get pattern for this day
    SELECT * INTO pattern_rec
    FROM training_time_patterns
    WHERE patient_id = p_patient_id
      AND day_of_week = p_day_of_week;

    -- If no pattern exists or low confidence, use fallback
    IF NOT FOUND OR pattern_rec.confidence_score < 0.3 THEN
        RETURN jsonb_build_object(
            'reminder_time', settings_rec.fallback_reminder_time,
            'is_smart', false,
            'confidence', COALESCE(pattern_rec.confidence_score, 0)
        );
    END IF;

    -- Calculate reminder time (subtract reminder_minutes_before from avg workout time)
    reminder_time := pattern_rec.avg_start_time - (settings_rec.reminder_minutes_before || ' minutes')::INTERVAL;

    -- Ensure reminder time is not during quiet hours
    IF reminder_time < settings_rec.quiet_hours_end THEN
        reminder_time := settings_rec.quiet_hours_end;
    END IF;

    IF reminder_time > settings_rec.quiet_hours_start THEN
        reminder_time := settings_rec.quiet_hours_start - INTERVAL '30 minutes';
    END IF;

    RETURN jsonb_build_object(
        'reminder_time', reminder_time,
        'is_smart', true,
        'confidence', pattern_rec.confidence_score,
        'based_on_workouts', pattern_rec.workout_count
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- Function: record_workout_completion_time
-- Called after workout to update patterns (for learning)
-- ============================================================================

CREATE OR REPLACE FUNCTION record_workout_completion_time(
    p_patient_id UUID,
    p_completion_time TIMESTAMPTZ DEFAULT NOW()
)
RETURNS VOID AS $$
BEGIN
    -- Trigger pattern analysis for incremental learning
    PERFORM analyze_training_patterns(p_patient_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- RLS Policies
-- ============================================================================

-- Enable RLS
ALTER TABLE training_time_patterns ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_history ENABLE ROW LEVEL SECURITY;

-- Training Time Patterns: patients can view their own patterns
CREATE POLICY "Patients can view own training patterns"
    ON training_time_patterns
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Training Time Patterns: system can insert/update (via functions)
CREATE POLICY "System can manage training patterns"
    ON training_time_patterns
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- Notification Settings: patients can manage their own settings
CREATE POLICY "Patients can manage own notification settings"
    ON notification_settings
    FOR ALL
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

-- Notification History: patients can view their own history
CREATE POLICY "Patients can view own notification history"
    ON notification_history
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Notification History: system can insert
CREATE POLICY "System can manage notification history"
    ON notification_history
    FOR ALL
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- Initialize default settings for existing patients
-- ============================================================================

INSERT INTO notification_settings (patient_id)
SELECT id FROM patients
WHERE id NOT IN (SELECT patient_id FROM notification_settings)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE training_time_patterns IS 'Stores learned workout timing patterns per day of week for smart notifications';
COMMENT ON TABLE notification_settings IS 'User preferences for workout reminders and notifications';
COMMENT ON TABLE notification_history IS 'History of sent notifications for analytics';
COMMENT ON FUNCTION analyze_training_patterns IS 'Analyzes workout completion times and updates patterns table for smart reminders';
COMMENT ON FUNCTION get_optimal_reminder_time IS 'Returns the best time to send a workout reminder based on learned patterns';
