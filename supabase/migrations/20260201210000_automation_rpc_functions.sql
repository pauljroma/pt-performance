-- ============================================================================
-- AUTOMATION RPC FUNCTIONS FOR MAKE.COM INTEGRATION
-- ============================================================================
-- Date: 2026-02-01
-- Purpose: Provide RPC functions for Make.com automation scenarios
--
-- Functions:
--   1. get_inactive_patients(days_inactive, max_results) - Find patients without recent sessions
--   2. get_weekly_stats(p_therapist_id) - Weekly dashboard stats for a therapist
--   3. get_top_exercises(p_therapist_id, p_limit) - Most-used exercises by therapist's patients
--   4. get_next_program_in_sequence(p_current_program_id) - Get next program in sequence
--   5. log_automation_event(p_event_type, p_patient_id, p_metadata) - Audit trail for automation
--
-- Security Considerations:
--   - Functions use SECURITY DEFINER to bypass RLS where appropriate for automation
--   - Parameter validation to prevent injection and invalid data
--   - Audit logging for compliance tracking
-- ============================================================================

BEGIN;

-- ============================================================================
-- 1. GET_INACTIVE_PATIENTS
-- ============================================================================
-- Returns patients with no completed session in X days
-- Used by: Make.com re-engagement workflow, inactive patient alerts

CREATE OR REPLACE FUNCTION get_inactive_patients(
    p_days_inactive INT DEFAULT 7,
    p_max_results INT DEFAULT 50
)
RETURNS TABLE (
    id UUID,
    full_name TEXT,
    email TEXT,
    days_inactive INT,
    last_session_date DATE,
    therapist_id UUID
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Parameter validation
    IF p_days_inactive < 1 THEN
        RAISE EXCEPTION 'p_days_inactive must be at least 1';
    END IF;

    IF p_max_results < 1 OR p_max_results > 1000 THEN
        RAISE EXCEPTION 'p_max_results must be between 1 and 1000';
    END IF;

    RETURN QUERY
    SELECT
        p.id,
        COALESCE(p.first_name || ' ' || p.last_name, p.first_name, 'Unknown') AS full_name,
        p.email,
        COALESCE(
            EXTRACT(DAY FROM (CURRENT_DATE - MAX(s.completed_at)::date))::INT,
            9999  -- No sessions ever completed
        ) AS days_inactive,
        MAX(s.completed_at)::date AS last_session_date,
        p.therapist_id
    FROM patients p
    LEFT JOIN programs pr ON pr.patient_id = p.id
    LEFT JOIN phases ph ON ph.program_id = pr.id
    LEFT JOIN sessions s ON s.phase_id = ph.id AND s.completed = true
    GROUP BY p.id, p.first_name, p.last_name, p.email, p.therapist_id
    HAVING
        MAX(s.completed_at) IS NULL
        OR MAX(s.completed_at) < CURRENT_DATE - p_days_inactive
    ORDER BY
        CASE WHEN MAX(s.completed_at) IS NULL THEN 1 ELSE 0 END DESC,
        MAX(s.completed_at) ASC NULLS FIRST
    LIMIT p_max_results;
END;
$$;

COMMENT ON FUNCTION get_inactive_patients IS
    'Returns patients with no completed session in X days. Used for Make.com re-engagement automation.';

-- ============================================================================
-- 2. GET_WEEKLY_STATS
-- ============================================================================
-- Returns weekly dashboard stats for a therapist
-- Used by: Make.com weekly report automation, therapist dashboards

CREATE OR REPLACE FUNCTION get_weekly_stats(
    p_therapist_id UUID
)
RETURNS TABLE (
    active_patients_count INT,
    sessions_completed INT,
    sessions_scheduled INT,
    average_adherence NUMERIC,
    average_readiness NUMERIC,
    patients_with_pain_flags INT,
    readiness_low_count INT,
    readiness_med_count INT,
    readiness_high_count INT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_week_start DATE;
    v_week_end DATE;
BEGIN
    -- Parameter validation
    IF p_therapist_id IS NULL THEN
        RAISE EXCEPTION 'p_therapist_id cannot be null';
    END IF;

    -- Calculate week boundaries (last 7 days)
    v_week_end := CURRENT_DATE;
    v_week_start := v_week_end - INTERVAL '6 days';

    RETURN QUERY
    WITH therapist_patients AS (
        -- Get all patients for this therapist
        SELECT p.id AS patient_id
        FROM patients p
        WHERE p.therapist_id = p_therapist_id
    ),
    active_patients AS (
        -- Patients with active programs
        SELECT DISTINCT pr.patient_id
        FROM programs pr
        JOIN therapist_patients tp ON tp.patient_id = pr.patient_id
        WHERE pr.status = 'active'
    ),
    completed_sessions AS (
        -- Sessions completed in the last 7 days
        SELECT s.id, pr.patient_id
        FROM sessions s
        JOIN phases ph ON ph.id = s.phase_id
        JOIN programs pr ON pr.id = ph.program_id
        JOIN therapist_patients tp ON tp.patient_id = pr.patient_id
        WHERE s.completed = true
          AND s.completed_at >= v_week_start
          AND s.completed_at <= v_week_end + INTERVAL '1 day'
    ),
    scheduled_sessions AS (
        -- Sessions scheduled in the last 7 days
        SELECT ss.id, ss.patient_id
        FROM scheduled_sessions ss
        JOIN therapist_patients tp ON tp.patient_id = ss.patient_id
        WHERE ss.scheduled_date >= v_week_start
          AND ss.scheduled_date <= v_week_end
    ),
    adherence_stats AS (
        -- Calculate average adherence
        SELECT
            AVG(va.adherence_pct) AS avg_adherence
        FROM vw_patient_adherence va
        JOIN therapist_patients tp ON tp.patient_id = va.patient_id
    ),
    readiness_stats AS (
        -- Readiness stats for the week
        SELECT
            AVG(dr.readiness_score) AS avg_readiness,
            COUNT(*) FILTER (WHERE dr.readiness_score < 40) AS low_count,
            COUNT(*) FILTER (WHERE dr.readiness_score >= 40 AND dr.readiness_score < 70) AS med_count,
            COUNT(*) FILTER (WHERE dr.readiness_score >= 70) AS high_count
        FROM daily_readiness dr
        JOIN therapist_patients tp ON tp.patient_id = dr.patient_id
        WHERE dr.date >= v_week_start
          AND dr.date <= v_week_end
    ),
    pain_flag_stats AS (
        -- Patients with active (unresolved) pain flags
        SELECT COUNT(DISTINCT pf.patient_id) AS patients_with_flags
        FROM pain_flags pf
        JOIN therapist_patients tp ON tp.patient_id = pf.patient_id
        WHERE pf.resolved_at IS NULL
          AND pf.triggered_at >= v_week_start
    )
    SELECT
        (SELECT COUNT(*)::INT FROM active_patients) AS active_patients_count,
        (SELECT COUNT(*)::INT FROM completed_sessions) AS sessions_completed,
        (SELECT COUNT(*)::INT FROM scheduled_sessions) AS sessions_scheduled,
        COALESCE((SELECT ROUND(avg_adherence, 1) FROM adherence_stats), 0.0) AS average_adherence,
        COALESCE((SELECT ROUND(avg_readiness, 1) FROM readiness_stats), 0.0) AS average_readiness,
        COALESCE((SELECT patients_with_flags::INT FROM pain_flag_stats), 0) AS patients_with_pain_flags,
        COALESCE((SELECT low_count::INT FROM readiness_stats), 0) AS readiness_low_count,
        COALESCE((SELECT med_count::INT FROM readiness_stats), 0) AS readiness_med_count,
        COALESCE((SELECT high_count::INT FROM readiness_stats), 0) AS readiness_high_count;
END;
$$;

COMMENT ON FUNCTION get_weekly_stats IS
    'Returns weekly dashboard statistics for a therapist including patient counts, session metrics, adherence, and readiness distribution.';

-- ============================================================================
-- 3. GET_TOP_EXERCISES
-- ============================================================================
-- Returns most-used exercises by therapist's patients
-- Used by: Make.com reporting automation, therapist insights

CREATE OR REPLACE FUNCTION get_top_exercises(
    p_therapist_id UUID,
    p_limit INT DEFAULT 10
)
RETURNS TABLE (
    exercise_id UUID,
    name TEXT,
    total_sets BIGINT,
    unique_patients BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Parameter validation
    IF p_therapist_id IS NULL THEN
        RAISE EXCEPTION 'p_therapist_id cannot be null';
    END IF;

    IF p_limit < 1 OR p_limit > 100 THEN
        RAISE EXCEPTION 'p_limit must be between 1 and 100';
    END IF;

    RETURN QUERY
    SELECT
        et.id AS exercise_id,
        et.name,
        COALESCE(SUM(el.sets_completed), 0) AS total_sets,
        COUNT(DISTINCT el.patient_id) AS unique_patients
    FROM exercise_templates et
    JOIN session_exercises se ON se.exercise_template_id = et.id
    JOIN exercise_logs el ON el.session_exercise_id = se.id
    JOIN patients p ON p.id = el.patient_id
    WHERE p.therapist_id = p_therapist_id
      AND el.logged_at >= CURRENT_DATE - INTERVAL '30 days'  -- Last 30 days
    GROUP BY et.id, et.name
    ORDER BY total_sets DESC, unique_patients DESC
    LIMIT p_limit;
END;
$$;

COMMENT ON FUNCTION get_top_exercises IS
    'Returns the most-used exercises by a therapist''s patients in the last 30 days, ranked by total sets completed.';

-- ============================================================================
-- 4. GET_NEXT_PROGRAM_IN_SEQUENCE
-- ============================================================================
-- Returns the next program in a sequence after completing current
-- Used by: Make.com program progression automation

CREATE OR REPLACE FUNCTION get_next_program_in_sequence(
    p_current_program_id UUID
)
RETURNS TABLE (
    next_program_id UUID,
    next_program_name TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_patient_id UUID;
    v_current_sequence INT;
    v_program_category TEXT;
BEGIN
    -- Parameter validation
    IF p_current_program_id IS NULL THEN
        RAISE EXCEPTION 'p_current_program_id cannot be null';
    END IF;

    -- Get current program details
    SELECT
        pr.patient_id,
        COALESCE(pr.metadata->>'sequence_order', '0')::INT,
        COALESCE(pr.metadata->>'category', pr.name)
    INTO v_patient_id, v_current_sequence, v_program_category
    FROM programs pr
    WHERE pr.id = p_current_program_id;

    IF v_patient_id IS NULL THEN
        -- Program not found, return NULL
        RETURN QUERY SELECT NULL::UUID, NULL::TEXT WHERE FALSE;
        RETURN;
    END IF;

    -- Strategy 1: Look for next program in sequence by metadata
    -- Programs can have metadata.sequence_order to indicate ordering
    RETURN QUERY
    SELECT
        pr.id AS next_program_id,
        pr.name AS next_program_name
    FROM programs pr
    WHERE pr.patient_id = v_patient_id
      AND pr.status = 'active'
      AND pr.id != p_current_program_id
      AND (
          -- Option A: sequence_order in metadata
          (pr.metadata->>'sequence_order')::INT = v_current_sequence + 1
          OR
          -- Option B: same category, created after current program
          (
              COALESCE(pr.metadata->>'category', pr.name) = v_program_category
              AND pr.created_at > (
                  SELECT created_at FROM programs WHERE id = p_current_program_id
              )
          )
      )
    ORDER BY
        COALESCE((pr.metadata->>'sequence_order')::INT, 9999),
        pr.created_at
    LIMIT 1;

    -- If no result from above, also check program_library for suggested next programs
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            pl.program_id AS next_program_id,
            pl.title AS next_program_name
        FROM program_library pl
        WHERE pl.category = v_program_category
          AND pl.program_id != p_current_program_id
          AND NOT EXISTS (
              -- Exclude programs patient is already enrolled in
              SELECT 1 FROM program_enrollments pe
              WHERE pe.program_library_id = pl.id
                AND pe.patient_id = v_patient_id
                AND pe.status IN ('active', 'completed')
          )
        ORDER BY pl.is_featured DESC, pl.created_at
        LIMIT 1;
    END IF;
END;
$$;

COMMENT ON FUNCTION get_next_program_in_sequence IS
    'Returns the next program in a sequence after completing the current one. Uses metadata.sequence_order or category matching.';

-- ============================================================================
-- 5. LOG_AUTOMATION_EVENT
-- ============================================================================
-- Logs automation actions for audit trail
-- Used by: Make.com to log all automation actions for HIPAA compliance

CREATE OR REPLACE FUNCTION log_automation_event(
    p_event_type TEXT,
    p_patient_id UUID DEFAULT NULL,
    p_metadata JSONB DEFAULT '{}'::JSONB
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_log_id UUID;
BEGIN
    -- Parameter validation
    IF p_event_type IS NULL OR LENGTH(TRIM(p_event_type)) = 0 THEN
        RAISE EXCEPTION 'p_event_type cannot be null or empty';
    END IF;

    -- Validate event type against allowed automation events
    IF p_event_type NOT IN (
        'inactive_patient_alert',
        'weekly_report_sent',
        'program_progression',
        'reminder_sent',
        'exercise_recommendation',
        'pain_flag_alert',
        'readiness_alert',
        'adherence_alert',
        'engagement_campaign',
        'webhook_triggered',
        'data_sync',
        'custom_automation'
    ) THEN
        RAISE EXCEPTION 'Invalid event_type: %. Allowed types: inactive_patient_alert, weekly_report_sent, program_progression, reminder_sent, exercise_recommendation, pain_flag_alert, readiness_alert, adherence_alert, engagement_campaign, webhook_triggered, data_sync, custom_automation', p_event_type;
    END IF;

    -- Insert into audit_logs table
    INSERT INTO audit_logs (
        user_id,
        user_email,
        user_role,
        action_type,
        resource_type,
        resource_id,
        operation,
        description,
        affected_patient_id,
        old_values,
        new_values,
        is_sensitive,
        compliance_category,
        status
    ) VALUES (
        COALESCE(auth.uid(), '00000000-0000-0000-0000-000000000000'::UUID),  -- System user if no auth context
        'automation@system.internal',
        'automation',
        'ADMIN',
        'automation_event',
        gen_random_uuid(),  -- Resource ID for this event
        p_event_type,
        COALESCE(p_metadata->>'description', 'Automation event: ' || p_event_type),
        p_patient_id,
        NULL,
        p_metadata,
        CASE WHEN p_patient_id IS NOT NULL THEN TRUE ELSE FALSE END,  -- Sensitive if patient-related
        'AUTOMATION',
        'success'
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;

COMMENT ON FUNCTION log_automation_event IS
    'Logs automation actions for audit trail and HIPAA compliance. Used by Make.com and other automation platforms.';

-- ============================================================================
-- INDEXES FOR PERFORMANCE (Recommended)
-- ============================================================================

-- Index for get_inactive_patients: Find patients by last session date
-- CREATE INDEX IF NOT EXISTS idx_sessions_completed_at_desc
--     ON sessions(completed_at DESC) WHERE completed = true;

-- Index for get_weekly_stats: Pain flags by trigger date
-- CREATE INDEX IF NOT EXISTS idx_pain_flags_triggered_at
--     ON pain_flags(triggered_at DESC) WHERE resolved_at IS NULL;

-- Index for get_top_exercises: Exercise logs in last 30 days
-- CREATE INDEX IF NOT EXISTS idx_exercise_logs_logged_at_30d
--     ON exercise_logs(logged_at DESC) WHERE logged_at >= CURRENT_DATE - INTERVAL '30 days';

-- Index for log_automation_event: Automation events in audit_logs
-- CREATE INDEX IF NOT EXISTS idx_audit_logs_automation
--     ON audit_logs(operation, timestamp DESC) WHERE user_role = 'automation';

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

-- Grant execute to authenticated users (Make.com uses service role or authenticated context)
GRANT EXECUTE ON FUNCTION get_inactive_patients TO authenticated;
GRANT EXECUTE ON FUNCTION get_weekly_stats TO authenticated;
GRANT EXECUTE ON FUNCTION get_top_exercises TO authenticated;
GRANT EXECUTE ON FUNCTION get_next_program_in_sequence TO authenticated;
GRANT EXECUTE ON FUNCTION log_automation_event TO authenticated;

-- Also grant to service_role for backend automation
GRANT EXECUTE ON FUNCTION get_inactive_patients TO service_role;
GRANT EXECUTE ON FUNCTION get_weekly_stats TO service_role;
GRANT EXECUTE ON FUNCTION get_top_exercises TO service_role;
GRANT EXECUTE ON FUNCTION get_next_program_in_sequence TO service_role;
GRANT EXECUTE ON FUNCTION log_automation_event TO service_role;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_func_count INT;
BEGIN
    SELECT COUNT(*) INTO v_func_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public'
      AND p.proname IN (
          'get_inactive_patients',
          'get_weekly_stats',
          'get_top_exercises',
          'get_next_program_in_sequence',
          'log_automation_event'
      );

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'AUTOMATION RPC FUNCTIONS CREATED - BUILD 2026-02-01';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions created: %/5', v_func_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Available RPC Functions:';
    RAISE NOTICE '  1. get_inactive_patients(days_inactive INT, max_results INT)';
    RAISE NOTICE '     -> Returns patients with no session in X days';
    RAISE NOTICE '';
    RAISE NOTICE '  2. get_weekly_stats(p_therapist_id UUID)';
    RAISE NOTICE '     -> Returns weekly dashboard stats for a therapist';
    RAISE NOTICE '';
    RAISE NOTICE '  3. get_top_exercises(p_therapist_id UUID, p_limit INT)';
    RAISE NOTICE '     -> Returns most-used exercises by therapist patients';
    RAISE NOTICE '';
    RAISE NOTICE '  4. get_next_program_in_sequence(p_current_program_id UUID)';
    RAISE NOTICE '     -> Returns next program in progression sequence';
    RAISE NOTICE '';
    RAISE NOTICE '  5. log_automation_event(p_event_type TEXT, p_patient_id UUID, p_metadata JSONB)';
    RAISE NOTICE '     -> Logs automation actions for audit trail';
    RAISE NOTICE '';
    RAISE NOTICE 'Security:';
    RAISE NOTICE '  - All functions use SECURITY DEFINER';
    RAISE NOTICE '  - Parameter validation prevents injection';
    RAISE NOTICE '  - Audit logging for compliance tracking';
    RAISE NOTICE '';
    RAISE NOTICE 'Usage from Make.com:';
    RAISE NOTICE '  POST /rest/v1/rpc/get_inactive_patients';
    RAISE NOTICE '  { "days_inactive": 7, "max_results": 50 }';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;

COMMIT;
