-- ============================================================================
-- Migration: M7 - PT Weekly Report System
-- Created: 2026-02-08
-- Description: Tables for weekly therapist reports with automated generation
-- ============================================================================

-- ============================================================================
-- WEEKLY REPORTS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.weekly_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    therapist_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    generated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Session Metrics
    session_completion_rate DECIMAL(5,4) DEFAULT 0,
    total_sessions_scheduled INTEGER DEFAULT 0,
    total_sessions_completed INTEGER DEFAULT 0,

    -- Pain Metrics
    average_pain_level DECIMAL(4,2),
    pain_trend TEXT DEFAULT 'stable' CHECK (pain_trend IN ('improving', 'stable', 'declining')),

    -- Recovery Metrics
    average_recovery_score DECIMAL(5,2),
    recovery_trend TEXT DEFAULT 'stable' CHECK (recovery_trend IN ('improving', 'stable', 'declining')),

    -- Adherence
    adherence_score DECIMAL(5,4) DEFAULT 0,

    -- Goals Progress (stored as JSONB array)
    goals_progress JSONB DEFAULT '[]'::jsonb,

    -- AI Recommendations
    ai_recommendations_adopted INTEGER DEFAULT 0,
    ai_recommendations_total INTEGER DEFAULT 0,

    -- Highlights
    achievements JSONB DEFAULT '[]'::jsonb,
    concerns JSONB DEFAULT '[]'::jsonb,
    recommendations JSONB DEFAULT '[]'::jsonb,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT unique_patient_week UNIQUE (patient_id, week_start_date),
    CONSTRAINT valid_date_range CHECK (week_end_date >= week_start_date),
    CONSTRAINT valid_completion_rate CHECK (session_completion_rate >= 0 AND session_completion_rate <= 1),
    CONSTRAINT valid_adherence_score CHECK (adherence_score >= 0 AND adherence_score <= 1),
    CONSTRAINT valid_pain_level CHECK (average_pain_level IS NULL OR (average_pain_level >= 0 AND average_pain_level <= 10))
);

-- ============================================================================
-- REPORT SCHEDULES TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.report_schedules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    day_of_week INTEGER NOT NULL DEFAULT 2 CHECK (day_of_week >= 1 AND day_of_week <= 7), -- 1=Sunday, 7=Saturday
    hour INTEGER NOT NULL DEFAULT 8 CHECK (hour >= 0 AND hour <= 23),
    is_enabled BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- One schedule per therapist
    CONSTRAINT unique_therapist_schedule UNIQUE (therapist_id)
);

-- ============================================================================
-- INDEXES
-- ============================================================================

-- Weekly reports indexes
CREATE INDEX IF NOT EXISTS idx_weekly_reports_patient_id ON public.weekly_reports(patient_id);
CREATE INDEX IF NOT EXISTS idx_weekly_reports_therapist_id ON public.weekly_reports(therapist_id);
CREATE INDEX IF NOT EXISTS idx_weekly_reports_week_start ON public.weekly_reports(week_start_date DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_reports_generated_at ON public.weekly_reports(generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_weekly_reports_patient_week ON public.weekly_reports(patient_id, week_start_date DESC);

-- Report schedules indexes
CREATE INDEX IF NOT EXISTS idx_report_schedules_therapist ON public.report_schedules(therapist_id);
CREATE INDEX IF NOT EXISTS idx_report_schedules_enabled ON public.report_schedules(is_enabled) WHERE is_enabled = true;

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update timestamp trigger for weekly_reports
CREATE OR REPLACE FUNCTION update_weekly_reports_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_weekly_reports_updated_at
    BEFORE UPDATE ON public.weekly_reports
    FOR EACH ROW
    EXECUTE FUNCTION update_weekly_reports_updated_at();

-- Update timestamp trigger for report_schedules
CREATE OR REPLACE FUNCTION update_report_schedules_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_report_schedules_updated_at
    BEFORE UPDATE ON public.report_schedules
    FOR EACH ROW
    EXECUTE FUNCTION update_report_schedules_updated_at();

-- ============================================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================================

-- Enable RLS on weekly_reports
ALTER TABLE public.weekly_reports ENABLE ROW LEVEL SECURITY;

-- Therapists can view reports for their patients
CREATE POLICY "Therapists can view their patients reports"
    ON public.weekly_reports FOR SELECT
    USING (
        therapist_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.patients p
            WHERE p.id = weekly_reports.patient_id
            AND p.therapist_id = auth.uid()
        )
    );

-- Therapists can insert reports for their patients
CREATE POLICY "Therapists can insert reports for their patients"
    ON public.weekly_reports FOR INSERT
    WITH CHECK (
        therapist_id = auth.uid()
        OR EXISTS (
            SELECT 1 FROM public.patients p
            WHERE p.id = patient_id
            AND p.therapist_id = auth.uid()
        )
    );

-- Therapists can update their own reports
CREATE POLICY "Therapists can update their reports"
    ON public.weekly_reports FOR UPDATE
    USING (therapist_id = auth.uid())
    WITH CHECK (therapist_id = auth.uid());

-- Therapists can delete their own reports
CREATE POLICY "Therapists can delete their reports"
    ON public.weekly_reports FOR DELETE
    USING (therapist_id = auth.uid());

-- Service role can do anything
CREATE POLICY "Service role full access to weekly_reports"
    ON public.weekly_reports FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- Enable RLS on report_schedules
ALTER TABLE public.report_schedules ENABLE ROW LEVEL SECURITY;

-- Therapists can manage their own schedules
CREATE POLICY "Therapists can view their schedules"
    ON public.report_schedules FOR SELECT
    USING (therapist_id = auth.uid());

CREATE POLICY "Therapists can insert their schedules"
    ON public.report_schedules FOR INSERT
    WITH CHECK (therapist_id = auth.uid());

CREATE POLICY "Therapists can update their schedules"
    ON public.report_schedules FOR UPDATE
    USING (therapist_id = auth.uid())
    WITH CHECK (therapist_id = auth.uid());

CREATE POLICY "Therapists can delete their schedules"
    ON public.report_schedules FOR DELETE
    USING (therapist_id = auth.uid());

-- Service role can do anything
CREATE POLICY "Service role full access to report_schedules"
    ON public.report_schedules FOR ALL
    USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get week boundaries for a date
CREATE OR REPLACE FUNCTION get_week_boundaries(p_date DATE)
RETURNS TABLE (week_start DATE, week_end DATE) AS $$
BEGIN
    -- Assuming week starts on Sunday
    week_start := p_date - (EXTRACT(DOW FROM p_date))::integer;
    week_end := week_start + 6;
    RETURN NEXT;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- Function to calculate metrics for a patient week
CREATE OR REPLACE FUNCTION calculate_weekly_metrics(
    p_patient_id UUID,
    p_week_start DATE,
    p_week_end DATE
) RETURNS JSONB AS $$
DECLARE
    v_result JSONB;
    v_sessions_scheduled INTEGER;
    v_sessions_completed INTEGER;
    v_avg_pain DECIMAL;
    v_pain_trend TEXT;
    v_avg_recovery DECIMAL;
    v_adherence DECIMAL;
BEGIN
    -- Count scheduled sessions
    SELECT COUNT(*) INTO v_sessions_scheduled
    FROM public.scheduled_sessions ss
    WHERE ss.patient_id = p_patient_id
      AND ss.scheduled_date BETWEEN p_week_start AND p_week_end;

    -- Count completed sessions
    SELECT COUNT(*) INTO v_sessions_completed
    FROM public.sessions s
    JOIN public.phases ph ON ph.id = s.phase_id
    JOIN public.programs p ON p.id = ph.program_id
    WHERE p.patient_id = p_patient_id
      AND s.completed = true
      AND s.session_date BETWEEN p_week_start AND p_week_end;

    -- Calculate average pain from exercise logs
    SELECT AVG(el.pain_score::decimal) INTO v_avg_pain
    FROM public.exercise_logs el
    WHERE el.patient_id = p_patient_id
      AND DATE(el.logged_at) BETWEEN p_week_start AND p_week_end
      AND el.pain_score IS NOT NULL;

    -- Calculate average recovery from daily readiness
    SELECT AVG(dr.recovery_score::decimal) INTO v_avg_recovery
    FROM public.daily_readiness dr
    WHERE dr.patient_id = p_patient_id
      AND dr.date BETWEEN p_week_start AND p_week_end;

    -- Calculate adherence (sessions completed / scheduled or completed / 5 if no schedule)
    IF v_sessions_scheduled > 0 THEN
        v_adherence := v_sessions_completed::decimal / v_sessions_scheduled::decimal;
    ELSIF v_sessions_completed > 0 THEN
        v_adherence := LEAST(v_sessions_completed::decimal / 5.0, 1.0);
    ELSE
        v_adherence := 0;
    END IF;

    -- Determine pain trend (compare to previous week)
    WITH current_week AS (
        SELECT AVG(el.pain_score::decimal) as avg_pain
        FROM public.exercise_logs el
        WHERE el.patient_id = p_patient_id
          AND DATE(el.logged_at) BETWEEN p_week_start AND p_week_end
    ),
    previous_week AS (
        SELECT AVG(el.pain_score::decimal) as avg_pain
        FROM public.exercise_logs el
        WHERE el.patient_id = p_patient_id
          AND DATE(el.logged_at) BETWEEN (p_week_start - 7) AND (p_week_start - 1)
    )
    SELECT
        CASE
            WHEN cw.avg_pain IS NULL OR pw.avg_pain IS NULL THEN 'stable'
            WHEN cw.avg_pain < pw.avg_pain - 0.5 THEN 'improving'
            WHEN cw.avg_pain > pw.avg_pain + 0.5 THEN 'declining'
            ELSE 'stable'
        END INTO v_pain_trend
    FROM current_week cw, previous_week pw;

    v_result := jsonb_build_object(
        'sessions_scheduled', COALESCE(v_sessions_scheduled, 0),
        'sessions_completed', COALESCE(v_sessions_completed, 0),
        'session_completion_rate', CASE WHEN v_sessions_scheduled > 0
            THEN v_sessions_completed::decimal / v_sessions_scheduled::decimal
            ELSE 0 END,
        'average_pain_level', v_avg_pain,
        'pain_trend', COALESCE(v_pain_trend, 'stable'),
        'average_recovery_score', v_avg_recovery,
        'recovery_trend', 'stable',
        'adherence_score', COALESCE(v_adherence, 0)
    );

    RETURN v_result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON public.weekly_reports TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.report_schedules TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.weekly_reports IS 'Weekly progress reports for therapist review of patient performance';
COMMENT ON TABLE public.report_schedules IS 'Automated weekly report generation schedules for therapists';

COMMENT ON COLUMN public.weekly_reports.session_completion_rate IS 'Ratio of completed to scheduled sessions (0-1)';
COMMENT ON COLUMN public.weekly_reports.adherence_score IS 'Overall adherence/compliance score (0-1)';
COMMENT ON COLUMN public.weekly_reports.goals_progress IS 'JSON array of goal progress objects with id, goal_name, target_value, current_value, percent_complete, trend';
COMMENT ON COLUMN public.weekly_reports.achievements IS 'JSON array of achievement strings for the week';
COMMENT ON COLUMN public.weekly_reports.concerns IS 'JSON array of concern strings identified during the week';
COMMENT ON COLUMN public.weekly_reports.recommendations IS 'JSON array of recommendation strings for the patient';

COMMENT ON COLUMN public.report_schedules.day_of_week IS '1=Sunday through 7=Saturday';
COMMENT ON COLUMN public.report_schedules.hour IS 'Hour of day (0-23) for report generation';
