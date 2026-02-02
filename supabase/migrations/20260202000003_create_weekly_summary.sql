-- Weekly Summary Function (ACP-843)
-- Generates weekly progress summary data for patient notifications
-- Created: 2026-02-02

-- =============================================================================
-- WEEKLY SUMMARY FUNCTION
-- =============================================================================
-- Returns aggregated weekly workout data including:
-- - Workout completion metrics
-- - Volume tracking with week-over-week comparison
-- - Streak maintenance status
-- - Top performing exercise
-- - Primary area needing improvement

CREATE OR REPLACE FUNCTION get_weekly_summary(
    p_patient_id UUID,
    p_week_start DATE DEFAULT (CURRENT_DATE - INTERVAL '7 days')::DATE
)
RETURNS TABLE (
    workouts_completed INTEGER,
    workouts_scheduled INTEGER,
    adherence_percentage NUMERIC,
    total_volume NUMERIC,
    volume_change_pct NUMERIC,
    streak_maintained BOOLEAN,
    current_streak INTEGER,
    top_exercise TEXT,
    improvement_area TEXT,
    week_start_date DATE,
    week_end_date DATE
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_end DATE := p_week_start + INTERVAL '6 days';
    v_prev_week_start DATE := p_week_start - INTERVAL '7 days';
    v_current_volume NUMERIC := 0;
    v_prev_volume NUMERIC := 0;
    v_completed_count INTEGER := 0;
    v_scheduled_count INTEGER := 0;
    v_adherence NUMERIC := 0;
    v_streak INTEGER := 0;
    v_streak_maintained BOOLEAN := FALSE;
    v_top_ex TEXT := NULL;
    v_improvement TEXT := NULL;
BEGIN
    -- Calculate completed sessions in the week
    SELECT COUNT(*)
    INTO v_completed_count
    FROM scheduled_sessions ss
    WHERE ss.patient_id = p_patient_id
      AND ss.scheduled_date BETWEEN p_week_start AND v_week_end
      AND ss.status = 'completed';

    -- Also count completed manual sessions
    SELECT v_completed_count + COUNT(*)
    INTO v_completed_count
    FROM manual_sessions ms
    WHERE ms.patient_id = p_patient_id
      AND ms.completed = TRUE
      AND ms.completed_at::DATE BETWEEN p_week_start AND v_week_end;

    -- Calculate scheduled sessions (target)
    SELECT COUNT(*)
    INTO v_scheduled_count
    FROM scheduled_sessions ss
    WHERE ss.patient_id = p_patient_id
      AND ss.scheduled_date BETWEEN p_week_start AND v_week_end
      AND ss.status IN ('scheduled', 'completed', 'rescheduled');

    -- If no scheduled sessions, use a reasonable default based on typical week
    IF v_scheduled_count = 0 THEN
        v_scheduled_count := GREATEST(v_completed_count, 3);
    END IF;

    -- Calculate adherence percentage
    IF v_scheduled_count > 0 THEN
        v_adherence := ROUND((v_completed_count::NUMERIC / v_scheduled_count::NUMERIC) * 100, 1);
    ELSE
        v_adherence := 0;
    END IF;

    -- Calculate total volume for current week (sets * reps * weight)
    SELECT COALESCE(SUM(
        COALESCE(el.actual_sets, 1) *
        COALESCE((SELECT SUM(r) FROM unnest(el.actual_reps) AS r), 0) *
        COALESCE(el.actual_load, 0)
    ), 0)
    INTO v_current_volume
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at::DATE BETWEEN p_week_start AND v_week_end;

    -- Also add manual session exercise volume
    SELECT v_current_volume + COALESCE(SUM(
        COALESCE(mse.target_sets, 1) *
        COALESCE(NULLIF(regexp_replace(COALESCE(mse.target_reps, '0'), '[^0-9]', '', 'g'), '')::INTEGER, 0) *
        COALESCE(mse.target_load, 0)
    ), 0)
    INTO v_current_volume
    FROM manual_session_exercises mse
    JOIN manual_sessions ms ON ms.id = mse.manual_session_id
    WHERE ms.patient_id = p_patient_id
      AND ms.completed = TRUE
      AND ms.completed_at::DATE BETWEEN p_week_start AND v_week_end;

    -- Calculate previous week's volume for comparison
    SELECT COALESCE(SUM(
        COALESCE(el.actual_sets, 1) *
        COALESCE((SELECT SUM(r) FROM unnest(el.actual_reps) AS r), 0) *
        COALESCE(el.actual_load, 0)
    ), 0)
    INTO v_prev_volume
    FROM exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND el.logged_at::DATE BETWEEN v_prev_week_start AND p_week_start - INTERVAL '1 day';

    -- Calculate current workout streak (consecutive days with workouts)
    WITH workout_dates AS (
        SELECT DISTINCT DATE(logged_at) as workout_date
        FROM exercise_logs
        WHERE patient_id = p_patient_id
        UNION
        SELECT DISTINCT DATE(completed_at) as workout_date
        FROM manual_sessions
        WHERE patient_id = p_patient_id AND completed = TRUE
        ORDER BY workout_date DESC
    ),
    streak_calc AS (
        SELECT workout_date,
               workout_date - (ROW_NUMBER() OVER (ORDER BY workout_date DESC))::INTEGER AS streak_group
        FROM workout_dates
        WHERE workout_date <= CURRENT_DATE
    )
    SELECT COUNT(*) INTO v_streak
    FROM streak_calc
    WHERE streak_group = (SELECT MAX(streak_group) FROM streak_calc WHERE workout_date >= CURRENT_DATE - INTERVAL '1 day');

    -- Check if streak was maintained (at least one workout in the past 2 days)
    SELECT EXISTS (
        SELECT 1 FROM exercise_logs
        WHERE patient_id = p_patient_id
          AND logged_at >= CURRENT_DATE - INTERVAL '2 days'
        UNION
        SELECT 1 FROM manual_sessions
        WHERE patient_id = p_patient_id
          AND completed = TRUE
          AND completed_at >= CURRENT_DATE - INTERVAL '2 days'
    ) INTO v_streak_maintained;

    -- Find top exercise (most volume in the week)
    SELECT et.exercise_name INTO v_top_ex
    FROM exercise_logs el
    JOIN session_exercises se ON se.id = el.session_exercise_id
    JOIN exercise_templates et ON et.id = se.exercise_template_id
    WHERE el.patient_id = p_patient_id
      AND el.logged_at::DATE BETWEEN p_week_start AND v_week_end
    GROUP BY et.exercise_name
    ORDER BY SUM(COALESCE(el.actual_sets, 1) * COALESCE(el.actual_load, 0)) DESC
    LIMIT 1;

    -- If no top exercise from prescribed workouts, check manual sessions
    IF v_top_ex IS NULL THEN
        SELECT mse.exercise_name INTO v_top_ex
        FROM manual_session_exercises mse
        JOIN manual_sessions ms ON ms.id = mse.manual_session_id
        WHERE ms.patient_id = p_patient_id
          AND ms.completed = TRUE
          AND ms.completed_at::DATE BETWEEN p_week_start AND v_week_end
        GROUP BY mse.exercise_name
        ORDER BY SUM(COALESCE(mse.target_sets, 1) * COALESCE(mse.target_load, 0)) DESC
        LIMIT 1;
    END IF;

    -- Determine improvement area based on various factors
    IF v_adherence < 80 THEN
        v_improvement := 'Workout Consistency';
    ELSIF v_current_volume < v_prev_volume AND v_prev_volume > 0 THEN
        v_improvement := 'Training Volume';
    ELSIF v_streak < 3 THEN
        v_improvement := 'Daily Activity Streak';
    ELSE
        -- Check for exercises with low RPE progression or stagnant weights
        SELECT et.exercise_name INTO v_improvement
        FROM exercise_logs el
        JOIN session_exercises se ON se.id = el.session_exercise_id
        JOIN exercise_templates et ON et.id = se.exercise_template_id
        WHERE el.patient_id = p_patient_id
          AND el.logged_at::DATE BETWEEN p_week_start AND v_week_end
          AND el.rpe >= 8  -- High RPE indicates struggling
        GROUP BY et.exercise_name
        ORDER BY AVG(el.rpe) DESC
        LIMIT 1;

        IF v_improvement IS NOT NULL THEN
            v_improvement := v_improvement || ' (high effort)';
        ELSE
            v_improvement := 'Keep up the great work!';
        END IF;
    END IF;

    RETURN QUERY SELECT
        v_completed_count,
        v_scheduled_count,
        v_adherence,
        v_current_volume,
        CASE WHEN v_prev_volume > 0
             THEN ROUND(((v_current_volume - v_prev_volume) / v_prev_volume) * 100, 1)
             ELSE 0
        END,
        v_streak_maintained,
        v_streak,
        v_top_ex,
        v_improvement,
        p_week_start,
        v_week_end;
END;
$$;

-- =============================================================================
-- WEEKLY SUMMARY PREFERENCES TABLE
-- =============================================================================
-- Stores user preferences for weekly summary notifications

CREATE TABLE IF NOT EXISTS weekly_summary_preferences (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    notification_enabled BOOLEAN DEFAULT TRUE,
    notification_day TEXT DEFAULT 'sunday' CHECK (notification_day IN ('sunday', 'monday')),
    notification_hour INTEGER DEFAULT 19 CHECK (notification_hour >= 0 AND notification_hour <= 23),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(patient_id)
);

-- Enable RLS
ALTER TABLE weekly_summary_preferences ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Patients can view own preferences"
    ON weekly_summary_preferences FOR SELECT
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

CREATE POLICY "Patients can insert own preferences"
    ON weekly_summary_preferences FOR INSERT
    WITH CHECK (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

CREATE POLICY "Patients can update own preferences"
    ON weekly_summary_preferences FOR UPDATE
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- =============================================================================
-- WEEKLY SUMMARY HISTORY TABLE
-- =============================================================================
-- Stores generated weekly summaries for historical reference

CREATE TABLE IF NOT EXISTS weekly_summary_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    workouts_completed INTEGER NOT NULL DEFAULT 0,
    workouts_scheduled INTEGER NOT NULL DEFAULT 0,
    adherence_percentage NUMERIC(5,2) DEFAULT 0,
    total_volume NUMERIC DEFAULT 0,
    volume_change_pct NUMERIC(6,2) DEFAULT 0,
    streak_maintained BOOLEAN DEFAULT FALSE,
    current_streak INTEGER DEFAULT 0,
    top_exercise TEXT,
    improvement_area TEXT,
    notification_sent BOOLEAN DEFAULT FALSE,
    notification_sent_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(patient_id, week_start_date)
);

-- Enable RLS
ALTER TABLE weekly_summary_history ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Patients can view own history"
    ON weekly_summary_history FOR SELECT
    USING (patient_id IN (
        SELECT id FROM patients WHERE user_id = auth.uid()
    ));

-- Index for efficient lookups
CREATE INDEX IF NOT EXISTS idx_weekly_summary_history_patient_week
    ON weekly_summary_history(patient_id, week_start_date DESC);

-- =============================================================================
-- HELPER FUNCTION: Save Weekly Summary
-- =============================================================================
-- Saves a generated weekly summary to history

CREATE OR REPLACE FUNCTION save_weekly_summary(p_patient_id UUID, p_week_start DATE DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_start DATE := COALESCE(p_week_start, (CURRENT_DATE - INTERVAL '7 days')::DATE);
    v_summary RECORD;
    v_history_id UUID;
BEGIN
    -- Get the weekly summary
    SELECT * INTO v_summary FROM get_weekly_summary(p_patient_id, v_week_start);

    -- Insert or update in history
    INSERT INTO weekly_summary_history (
        patient_id,
        week_start_date,
        week_end_date,
        workouts_completed,
        workouts_scheduled,
        adherence_percentage,
        total_volume,
        volume_change_pct,
        streak_maintained,
        current_streak,
        top_exercise,
        improvement_area
    ) VALUES (
        p_patient_id,
        v_summary.week_start_date,
        v_summary.week_end_date,
        v_summary.workouts_completed,
        v_summary.workouts_scheduled,
        v_summary.adherence_percentage,
        v_summary.total_volume,
        v_summary.volume_change_pct,
        v_summary.streak_maintained,
        v_summary.current_streak,
        v_summary.top_exercise,
        v_summary.improvement_area
    )
    ON CONFLICT (patient_id, week_start_date)
    DO UPDATE SET
        workouts_completed = EXCLUDED.workouts_completed,
        workouts_scheduled = EXCLUDED.workouts_scheduled,
        adherence_percentage = EXCLUDED.adherence_percentage,
        total_volume = EXCLUDED.total_volume,
        volume_change_pct = EXCLUDED.volume_change_pct,
        streak_maintained = EXCLUDED.streak_maintained,
        current_streak = EXCLUDED.current_streak,
        top_exercise = EXCLUDED.top_exercise,
        improvement_area = EXCLUDED.improvement_area
    RETURNING id INTO v_history_id;

    RETURN v_history_id;
END;
$$;

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_weekly_summary(UUID, DATE) TO authenticated;
GRANT EXECUTE ON FUNCTION save_weekly_summary(UUID, DATE) TO authenticated;

-- Add comment
COMMENT ON FUNCTION get_weekly_summary IS 'Returns weekly progress summary for patient notifications (ACP-843)';
COMMENT ON TABLE weekly_summary_preferences IS 'User preferences for weekly summary notifications (ACP-843)';
COMMENT ON TABLE weekly_summary_history IS 'Historical weekly summaries for patient progress tracking (ACP-843)';
