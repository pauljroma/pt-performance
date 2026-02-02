-- ACP-836: Streak Tracking Feature
-- Creates tables and functions for tracking workout and arm care streaks

-- ============================================================================
-- STREAK RECORDS TABLE
-- Stores current and longest streak for each patient/streak type combination
-- ============================================================================

CREATE TABLE IF NOT EXISTS streak_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    streak_type TEXT NOT NULL CHECK (streak_type IN ('workout', 'arm_care', 'combined')),
    current_streak INTEGER NOT NULL DEFAULT 0,
    longest_streak INTEGER NOT NULL DEFAULT 0,
    last_activity_date DATE,
    streak_start_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_patient_streak_type UNIQUE (patient_id, streak_type)
);

-- Index for efficient patient lookups
CREATE INDEX IF NOT EXISTS idx_streak_records_patient_id ON streak_records(patient_id);
CREATE INDEX IF NOT EXISTS idx_streak_records_last_activity ON streak_records(last_activity_date);

-- ============================================================================
-- STREAK HISTORY TABLE
-- Tracks daily activity for calendar view and streak calculation
-- ============================================================================

CREATE TABLE IF NOT EXISTS streak_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    activity_date DATE NOT NULL,
    workout_completed BOOLEAN DEFAULT false,
    arm_care_completed BOOLEAN DEFAULT false,
    session_id UUID REFERENCES scheduled_sessions(id) ON DELETE SET NULL,
    manual_session_id UUID REFERENCES manual_sessions(id) ON DELETE SET NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT uq_patient_activity_date UNIQUE (patient_id, activity_date)
);

-- Indexes for efficient queries
CREATE INDEX IF NOT EXISTS idx_streak_history_patient_id ON streak_history(patient_id);
CREATE INDEX IF NOT EXISTS idx_streak_history_activity_date ON streak_history(activity_date DESC);
CREATE INDEX IF NOT EXISTS idx_streak_history_patient_date ON streak_history(patient_id, activity_date DESC);

-- ============================================================================
-- FUNCTION: Calculate current streak for a patient
-- ============================================================================

CREATE OR REPLACE FUNCTION calculate_current_streak(
    p_patient_id UUID,
    p_streak_type TEXT DEFAULT 'combined'
)
RETURNS INTEGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_streak INTEGER := 0;
    v_current_date DATE := CURRENT_DATE;
    v_last_activity DATE;
    r_record RECORD;
BEGIN
    -- Determine which activity to check based on streak type
    FOR r_record IN
        SELECT activity_date,
               CASE
                   WHEN p_streak_type = 'workout' THEN workout_completed
                   WHEN p_streak_type = 'arm_care' THEN arm_care_completed
                   ELSE (workout_completed OR arm_care_completed)
               END AS has_activity
        FROM streak_history
        WHERE patient_id = p_patient_id
        ORDER BY activity_date DESC
    LOOP
        -- If this is the first iteration, check if activity was today or yesterday
        IF v_last_activity IS NULL THEN
            IF r_record.activity_date = v_current_date OR r_record.activity_date = v_current_date - 1 THEN
                IF r_record.has_activity THEN
                    v_streak := 1;
                    v_last_activity := r_record.activity_date;
                ELSE
                    EXIT; -- No activity on today/yesterday, streak is 0
                END IF;
            ELSE
                EXIT; -- Gap in activity, streak is 0
            END IF;
        ELSE
            -- Check for consecutive days
            IF r_record.activity_date = v_last_activity - 1 AND r_record.has_activity THEN
                v_streak := v_streak + 1;
                v_last_activity := r_record.activity_date;
            ELSIF r_record.activity_date = v_last_activity THEN
                -- Same day, skip
                CONTINUE;
            ELSE
                EXIT; -- Gap found, stop counting
            END IF;
        END IF;
    END LOOP;

    RETURN v_streak;
END;
$$;

-- ============================================================================
-- FUNCTION: Update streak on activity
-- Called when a workout or arm care session is completed
-- ============================================================================

CREATE OR REPLACE FUNCTION update_streak_on_activity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_current_streak INTEGER;
    v_longest_streak INTEGER;
    v_streak_types TEXT[] := ARRAY['workout', 'arm_care', 'combined'];
    v_streak_type TEXT;
BEGIN
    -- Loop through all streak types and update them
    FOREACH v_streak_type IN ARRAY v_streak_types
    LOOP
        -- Calculate current streak
        v_current_streak := calculate_current_streak(NEW.patient_id, v_streak_type);

        -- Upsert streak record
        INSERT INTO streak_records (
            patient_id,
            streak_type,
            current_streak,
            longest_streak,
            last_activity_date,
            streak_start_date,
            updated_at
        )
        VALUES (
            NEW.patient_id,
            v_streak_type,
            v_current_streak,
            v_current_streak,
            NEW.activity_date,
            CASE
                WHEN v_current_streak > 0 THEN NEW.activity_date - (v_current_streak - 1)
                ELSE NULL
            END,
            NOW()
        )
        ON CONFLICT (patient_id, streak_type)
        DO UPDATE SET
            current_streak = EXCLUDED.current_streak,
            longest_streak = GREATEST(streak_records.longest_streak, EXCLUDED.current_streak),
            last_activity_date = EXCLUDED.last_activity_date,
            streak_start_date = CASE
                WHEN EXCLUDED.current_streak > 0 THEN EXCLUDED.last_activity_date - (EXCLUDED.current_streak - 1)
                ELSE streak_records.streak_start_date
            END,
            updated_at = NOW();
    END LOOP;

    RETURN NEW;
END;
$$;

-- Trigger to update streaks when streak_history changes
DROP TRIGGER IF EXISTS trg_update_streak_on_activity ON streak_history;
CREATE TRIGGER trg_update_streak_on_activity
    AFTER INSERT OR UPDATE ON streak_history
    FOR EACH ROW
    EXECUTE FUNCTION update_streak_on_activity();

-- ============================================================================
-- FUNCTION: Record activity (for use from iOS app)
-- ============================================================================

CREATE OR REPLACE FUNCTION record_streak_activity(
    p_patient_id UUID,
    p_activity_date DATE,
    p_workout_completed BOOLEAN DEFAULT false,
    p_arm_care_completed BOOLEAN DEFAULT false,
    p_session_id UUID DEFAULT NULL,
    p_manual_session_id UUID DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS streak_history
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_result streak_history;
BEGIN
    INSERT INTO streak_history (
        patient_id,
        activity_date,
        workout_completed,
        arm_care_completed,
        session_id,
        manual_session_id,
        notes
    )
    VALUES (
        p_patient_id,
        p_activity_date,
        p_workout_completed,
        p_arm_care_completed,
        p_session_id,
        p_manual_session_id,
        p_notes
    )
    ON CONFLICT (patient_id, activity_date)
    DO UPDATE SET
        workout_completed = COALESCE(streak_history.workout_completed, false) OR EXCLUDED.workout_completed,
        arm_care_completed = COALESCE(streak_history.arm_care_completed, false) OR EXCLUDED.arm_care_completed,
        session_id = COALESCE(EXCLUDED.session_id, streak_history.session_id),
        manual_session_id = COALESCE(EXCLUDED.manual_session_id, streak_history.manual_session_id),
        notes = COALESCE(EXCLUDED.notes, streak_history.notes)
    RETURNING * INTO v_result;

    RETURN v_result;
END;
$$;

-- ============================================================================
-- FUNCTION: Get streak statistics for a patient
-- ============================================================================

CREATE OR REPLACE FUNCTION get_streak_statistics(
    p_patient_id UUID
)
RETURNS TABLE (
    streak_type TEXT,
    current_streak INTEGER,
    longest_streak INTEGER,
    last_activity_date DATE,
    streak_start_date DATE,
    total_activity_days INTEGER,
    this_week_days INTEGER,
    this_month_days INTEGER
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH activity_counts AS (
        SELECT
            COUNT(*) FILTER (WHERE workout_completed OR arm_care_completed) AS total_combined,
            COUNT(*) FILTER (WHERE workout_completed) AS total_workout,
            COUNT(*) FILTER (WHERE arm_care_completed) AS total_arm_care,
            COUNT(*) FILTER (WHERE (workout_completed OR arm_care_completed) AND activity_date >= CURRENT_DATE - INTERVAL '7 days') AS week_combined,
            COUNT(*) FILTER (WHERE workout_completed AND activity_date >= CURRENT_DATE - INTERVAL '7 days') AS week_workout,
            COUNT(*) FILTER (WHERE arm_care_completed AND activity_date >= CURRENT_DATE - INTERVAL '7 days') AS week_arm_care,
            COUNT(*) FILTER (WHERE (workout_completed OR arm_care_completed) AND activity_date >= DATE_TRUNC('month', CURRENT_DATE)) AS month_combined,
            COUNT(*) FILTER (WHERE workout_completed AND activity_date >= DATE_TRUNC('month', CURRENT_DATE)) AS month_workout,
            COUNT(*) FILTER (WHERE arm_care_completed AND activity_date >= DATE_TRUNC('month', CURRENT_DATE)) AS month_arm_care
        FROM streak_history
        WHERE patient_id = p_patient_id
    )
    SELECT
        sr.streak_type,
        sr.current_streak,
        sr.longest_streak,
        sr.last_activity_date,
        sr.streak_start_date,
        CASE sr.streak_type
            WHEN 'workout' THEN ac.total_workout::INTEGER
            WHEN 'arm_care' THEN ac.total_arm_care::INTEGER
            ELSE ac.total_combined::INTEGER
        END AS total_activity_days,
        CASE sr.streak_type
            WHEN 'workout' THEN ac.week_workout::INTEGER
            WHEN 'arm_care' THEN ac.week_arm_care::INTEGER
            ELSE ac.week_combined::INTEGER
        END AS this_week_days,
        CASE sr.streak_type
            WHEN 'workout' THEN ac.month_workout::INTEGER
            WHEN 'arm_care' THEN ac.month_arm_care::INTEGER
            ELSE ac.month_combined::INTEGER
        END AS this_month_days
    FROM streak_records sr
    CROSS JOIN activity_counts ac
    WHERE sr.patient_id = p_patient_id;
END;
$$;

-- ============================================================================
-- FUNCTION: Get streak history for calendar view
-- ============================================================================

CREATE OR REPLACE FUNCTION get_streak_history_for_calendar(
    p_patient_id UUID,
    p_start_date DATE DEFAULT CURRENT_DATE - INTERVAL '30 days',
    p_end_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    activity_date DATE,
    workout_completed BOOLEAN,
    arm_care_completed BOOLEAN,
    has_any_activity BOOLEAN,
    session_id UUID,
    manual_session_id UUID,
    notes TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        sh.activity_date,
        sh.workout_completed,
        sh.arm_care_completed,
        (sh.workout_completed OR sh.arm_care_completed) AS has_any_activity,
        sh.session_id,
        sh.manual_session_id,
        sh.notes
    FROM streak_history sh
    WHERE sh.patient_id = p_patient_id
      AND sh.activity_date BETWEEN p_start_date AND p_end_date
    ORDER BY sh.activity_date DESC;
END;
$$;

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Enable RLS
ALTER TABLE streak_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE streak_history ENABLE ROW LEVEL SECURITY;

-- Streak Records Policies
DROP POLICY IF EXISTS "streak_records_select_own" ON streak_records;
CREATE POLICY "streak_records_select_own" ON streak_records
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "streak_records_insert_own" ON streak_records;
CREATE POLICY "streak_records_insert_own" ON streak_records
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "streak_records_update_own" ON streak_records;
CREATE POLICY "streak_records_update_own" ON streak_records
    FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Streak History Policies
DROP POLICY IF EXISTS "streak_history_select_own" ON streak_history;
CREATE POLICY "streak_history_select_own" ON streak_history
    FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "streak_history_insert_own" ON streak_history;
CREATE POLICY "streak_history_insert_own" ON streak_history
    FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "streak_history_update_own" ON streak_history;
CREATE POLICY "streak_history_update_own" ON streak_history
    FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Therapist access policies
DROP POLICY IF EXISTS "streak_records_therapist_select" ON streak_records;
CREATE POLICY "streak_records_therapist_select" ON streak_records
    FOR SELECT
    USING (
        patient_id IN (
            SELECT tp.patient_id
            FROM therapist_patients tp
            JOIN therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "streak_history_therapist_select" ON streak_history;
CREATE POLICY "streak_history_therapist_select" ON streak_history
    FOR SELECT
    USING (
        patient_id IN (
            SELECT tp.patient_id
            FROM therapist_patients tp
            JOIN therapists t ON t.id = tp.therapist_id
            WHERE t.user_id = auth.uid()
        )
    );

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON streak_records TO authenticated;
GRANT SELECT, INSERT, UPDATE ON streak_history TO authenticated;
GRANT EXECUTE ON FUNCTION calculate_current_streak TO authenticated;
GRANT EXECUTE ON FUNCTION record_streak_activity TO authenticated;
GRANT EXECUTE ON FUNCTION get_streak_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION get_streak_history_for_calendar TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE streak_records IS 'Stores current and longest streak data for each patient and streak type';
COMMENT ON TABLE streak_history IS 'Daily activity log for streak tracking and calendar display';
COMMENT ON FUNCTION calculate_current_streak IS 'Calculates the current streak count for a patient';
COMMENT ON FUNCTION update_streak_on_activity IS 'Trigger function to update streak records when activity is logged';
COMMENT ON FUNCTION record_streak_activity IS 'RPC function to record daily activity from iOS app';
COMMENT ON FUNCTION get_streak_statistics IS 'Returns comprehensive streak statistics for a patient';
COMMENT ON FUNCTION get_streak_history_for_calendar IS 'Returns activity history for calendar display';
