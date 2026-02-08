--
-- Phase 3 Database Migration - X2Index Performance Indexes
-- Created: 2026-02-08
--
-- This migration adds optimized indexes for Phase 3 features:
-- - Safety incidents and escalations
-- - Timeline conflicts
-- - Weekly reports
-- - Historical trends
--

-- ============================================================================
-- SAFETY INCIDENTS TABLE AND INDEXES
-- ============================================================================

-- Create safety_incidents table if not exists
CREATE TABLE IF NOT EXISTS public.safety_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    incident_type TEXT NOT NULL CHECK (incident_type IN ('pain_threshold', 'vital_anomaly', 'contradictory_data', 'ai_uncertainty', 'missed_escalation')),
    severity TEXT NOT NULL CHECK (severity IN ('low', 'medium', 'high', 'critical')),
    description TEXT NOT NULL,
    trigger_data JSONB,
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'resolved', 'dismissed')),
    escalated_to UUID REFERENCES auth.users(id),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    resolution_notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fetching open incidents by therapist's patients
CREATE INDEX IF NOT EXISTS idx_safety_incidents_athlete_status
ON public.safety_incidents(athlete_id, status);

-- Index for fetching high severity open incidents (for dashboard badges)
CREATE INDEX IF NOT EXISTS idx_safety_incidents_severity_status
ON public.safety_incidents(severity, status)
WHERE status IN ('open', 'investigating');

-- Index for escalation queries
CREATE INDEX IF NOT EXISTS idx_safety_incidents_escalated_to
ON public.safety_incidents(escalated_to)
WHERE escalated_to IS NOT NULL;

-- Index for time-based queries (incident age)
CREATE INDEX IF NOT EXISTS idx_safety_incidents_created_at
ON public.safety_incidents(created_at DESC);

-- Composite index for command center queries
CREATE INDEX IF NOT EXISTS idx_safety_incidents_command_center
ON public.safety_incidents(status, severity, created_at DESC)
WHERE status IN ('open', 'investigating');

-- ============================================================================
-- TIMELINE CONFLICTS TABLE AND INDEXES
-- ============================================================================

-- Create timeline_conflicts table if not exists
CREATE TABLE IF NOT EXISTS public.timeline_conflicts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES public.patients(id) ON DELETE CASCADE,
    conflict_type TEXT NOT NULL CHECK (conflict_type IN ('value_discrepancy', 'duplicate_entry', 'time_overlap', 'source_disagreement')),
    event_ids UUID[] NOT NULL,
    description TEXT NOT NULL,
    resolution_status TEXT NOT NULL DEFAULT 'pending' CHECK (resolution_status IN ('pending', 'resolved', 'dismissed')),
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    resolution_method TEXT,
    resolution_value TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fetching pending conflicts by patient
CREATE INDEX IF NOT EXISTS idx_timeline_conflicts_patient_status
ON public.timeline_conflicts(patient_id, resolution_status);

-- Index for pending conflicts (dashboard view)
CREATE INDEX IF NOT EXISTS idx_timeline_conflicts_pending
ON public.timeline_conflicts(resolution_status, created_at DESC)
WHERE resolution_status = 'pending';

-- ============================================================================
-- WEEKLY REPORTS TABLE AND INDEXES
-- ============================================================================

-- Create weekly_reports table if not exists
CREATE TABLE IF NOT EXISTS public.weekly_reports (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapist_id UUID NOT NULL REFERENCES auth.users(id),
    title TEXT NOT NULL,
    date_range_start DATE NOT NULL,
    date_range_end DATE NOT NULL,
    patient_ids UUID[] NOT NULL,
    patient_count INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'generating' CHECK (status IN ('generating', 'ready', 'failed')),
    highlights TEXT,
    pdf_url TEXT,
    html_content TEXT,
    metrics JSONB,
    generated_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fetching reports by therapist
CREATE INDEX IF NOT EXISTS idx_weekly_reports_therapist
ON public.weekly_reports(therapist_id, created_at DESC);

-- Index for ready reports
CREATE INDEX IF NOT EXISTS idx_weekly_reports_ready
ON public.weekly_reports(therapist_id, status, created_at DESC)
WHERE status = 'ready';

-- ============================================================================
-- HISTORICAL TRENDS MATERIALIZED VIEW
-- ============================================================================

-- Readiness trends by patient (daily aggregates)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_readiness_trends AS
SELECT
    patient_id,
    DATE(check_in_date) as trend_date,
    AVG(overall_score) as avg_readiness,
    MIN(overall_score) as min_readiness,
    MAX(overall_score) as max_readiness,
    COUNT(*) as data_points
FROM public.daily_readiness
GROUP BY patient_id, DATE(check_in_date);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_readiness_trends_pk
ON public.mv_readiness_trends(patient_id, trend_date);

-- Pain trends by patient (daily aggregates)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_pain_trends AS
SELECT
    el.patient_id,
    DATE(el.created_at) as trend_date,
    AVG(el.pain_score) as avg_pain,
    MAX(el.pain_score) as max_pain,
    COUNT(*) as data_points
FROM public.exercise_logs el
WHERE el.pain_score IS NOT NULL
GROUP BY el.patient_id, DATE(el.created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_pain_trends_pk
ON public.mv_pain_trends(patient_id, trend_date);

-- Adherence trends by patient (daily aggregates)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_adherence_trends AS
SELECT
    s.patient_id,
    DATE(s.completed_at) as trend_date,
    COUNT(CASE WHEN s.status = 'completed' THEN 1 END)::DECIMAL /
        NULLIF(COUNT(*), 0) * 100 as adherence_rate,
    COUNT(*) as total_sessions,
    COUNT(CASE WHEN s.status = 'completed' THEN 1 END) as completed_sessions
FROM public.sessions s
WHERE s.completed_at IS NOT NULL
GROUP BY s.patient_id, DATE(s.completed_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_adherence_trends_pk
ON public.mv_adherence_trends(patient_id, trend_date);

-- Volume trends by patient (daily aggregates)
CREATE MATERIALIZED VIEW IF NOT EXISTS public.mv_volume_trends AS
SELECT
    el.patient_id,
    DATE(el.created_at) as trend_date,
    SUM(el.weight * el.reps) as total_volume,
    SUM(el.reps) as total_reps,
    COUNT(DISTINCT el.exercise_id) as exercises_performed
FROM public.exercise_logs el
WHERE el.weight IS NOT NULL AND el.reps IS NOT NULL
GROUP BY el.patient_id, DATE(el.created_at);

CREATE UNIQUE INDEX IF NOT EXISTS idx_mv_volume_trends_pk
ON public.mv_volume_trends(patient_id, trend_date);

-- ============================================================================
-- REFRESH FUNCTION FOR MATERIALIZED VIEWS
-- ============================================================================

CREATE OR REPLACE FUNCTION public.refresh_trend_views()
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_readiness_trends;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_pain_trends;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_adherence_trends;
    REFRESH MATERIALIZED VIEW CONCURRENTLY public.mv_volume_trends;
END;
$$;

-- ============================================================================
-- RLS POLICIES FOR NEW TABLES
-- ============================================================================

-- Enable RLS
ALTER TABLE public.safety_incidents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.timeline_conflicts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.weekly_reports ENABLE ROW LEVEL SECURITY;

-- Safety incidents policies
CREATE POLICY "Therapists can view their patients' incidents"
ON public.safety_incidents FOR SELECT
USING (
    athlete_id IN (
        SELECT id FROM public.patients
        WHERE therapist_id = auth.uid()
    )
);

CREATE POLICY "Therapists can insert incidents for their patients"
ON public.safety_incidents FOR INSERT
WITH CHECK (
    athlete_id IN (
        SELECT id FROM public.patients
        WHERE therapist_id = auth.uid()
    )
);

CREATE POLICY "Therapists can update their patients' incidents"
ON public.safety_incidents FOR UPDATE
USING (
    athlete_id IN (
        SELECT id FROM public.patients
        WHERE therapist_id = auth.uid()
    )
);

-- Timeline conflicts policies
CREATE POLICY "Therapists can view their patients' conflicts"
ON public.timeline_conflicts FOR SELECT
USING (
    patient_id IN (
        SELECT id FROM public.patients
        WHERE therapist_id = auth.uid()
    )
);

CREATE POLICY "Therapists can manage their patients' conflicts"
ON public.timeline_conflicts FOR ALL
USING (
    patient_id IN (
        SELECT id FROM public.patients
        WHERE therapist_id = auth.uid()
    )
);

-- Weekly reports policies
CREATE POLICY "Therapists can view their own reports"
ON public.weekly_reports FOR SELECT
USING (therapist_id = auth.uid());

CREATE POLICY "Therapists can create their own reports"
ON public.weekly_reports FOR INSERT
WITH CHECK (therapist_id = auth.uid());

CREATE POLICY "Therapists can update their own reports"
ON public.weekly_reports FOR UPDATE
USING (therapist_id = auth.uid());

-- ============================================================================
-- ADDITIONAL PERFORMANCE INDEXES
-- ============================================================================

-- Index for patient timeline queries
CREATE INDEX IF NOT EXISTS idx_timeline_events_patient_date
ON public.timeline_events(patient_id, timestamp DESC)
WHERE patient_id IS NOT NULL;

-- Index for session completion tracking
CREATE INDEX IF NOT EXISTS idx_sessions_patient_status
ON public.sessions(patient_id, status, completed_at DESC);

-- Index for exercise log queries (trend calculations)
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_date
ON public.exercise_logs(patient_id, created_at DESC);

-- Index for daily readiness queries
CREATE INDEX IF NOT EXISTS idx_daily_readiness_patient_date
ON public.daily_readiness(patient_id, check_in_date DESC);

-- ============================================================================
-- UPDATED_AT TRIGGER
-- ============================================================================

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to safety_incidents
DROP TRIGGER IF EXISTS set_safety_incidents_updated_at ON public.safety_incidents;
CREATE TRIGGER set_safety_incidents_updated_at
    BEFORE UPDATE ON public.safety_incidents
    FOR EACH ROW
    EXECUTE FUNCTION public.set_updated_at();

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON public.safety_incidents TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.timeline_conflicts TO authenticated;
GRANT SELECT, INSERT, UPDATE ON public.weekly_reports TO authenticated;
GRANT SELECT ON public.mv_readiness_trends TO authenticated;
GRANT SELECT ON public.mv_pain_trends TO authenticated;
GRANT SELECT ON public.mv_adherence_trends TO authenticated;
GRANT SELECT ON public.mv_volume_trends TO authenticated;
GRANT EXECUTE ON FUNCTION public.refresh_trend_views() TO authenticated;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE public.safety_incidents IS 'Phase 3: Tracks safety escalations and incidents for X2Index Command Center';
COMMENT ON TABLE public.timeline_conflicts IS 'Phase 3: Tracks data conflicts in the canonical timeline';
COMMENT ON TABLE public.weekly_reports IS 'Phase 3: Stores generated weekly progress reports';
COMMENT ON MATERIALIZED VIEW public.mv_readiness_trends IS 'Phase 3: Pre-computed readiness trends for historical analysis';
COMMENT ON MATERIALIZED VIEW public.mv_pain_trends IS 'Phase 3: Pre-computed pain trends for historical analysis';
COMMENT ON MATERIALIZED VIEW public.mv_adherence_trends IS 'Phase 3: Pre-computed adherence trends for historical analysis';
COMMENT ON MATERIALIZED VIEW public.mv_volume_trends IS 'Phase 3: Pre-computed volume trends for historical analysis';
