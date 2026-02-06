-- RPC function to get sessions for a user via their program enrollments
-- Build 444 - Fix: Users can see workouts from enrolled programs
--
-- Problem: iOS query filters by programs.patient_id but enrolled programs have patient_id = NULL
-- Solution: Create RPC that fetches sessions via enrollment relationship

-- ============================================================================
-- Function: Get sessions for a user's enrolled programs
-- ============================================================================

CREATE OR REPLACE FUNCTION get_enrolled_program_sessions(p_patient_id UUID)
RETURNS TABLE (
    session_id UUID,
    session_name TEXT,
    session_sequence INT,
    phase_id UUID,
    phase_name TEXT,
    phase_sequence INT,
    program_id UUID,
    program_name TEXT,
    enrollment_id UUID,
    program_library_id UUID,
    program_library_title TEXT
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id as session_id,
        s.name as session_name,
        s.sequence as session_sequence,
        p.id as phase_id,
        p.name as phase_name,
        p.sequence as phase_sequence,
        prog.id as program_id,
        prog.name as program_name,
        pe.id as enrollment_id,
        pl.id as program_library_id,
        pl.title as program_library_title
    FROM sessions s
    JOIN phases p ON p.id = s.phase_id
    JOIN programs prog ON prog.id = p.program_id
    JOIN program_library pl ON pl.program_id = prog.id
    JOIN program_enrollments pe ON pe.program_library_id = pl.id
    WHERE pe.patient_id = p_patient_id
      AND pe.status = 'active'
    ORDER BY p.sequence, s.sequence
    LIMIT 10;  -- Return first 10 sessions for efficiency
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_enrolled_program_sessions(UUID) TO authenticated;

-- ============================================================================
-- Function: Get today's session for an enrolled user
-- ============================================================================

CREATE OR REPLACE FUNCTION get_today_enrolled_session(p_patient_id UUID)
RETURNS TABLE (
    session_id UUID,
    session_name TEXT,
    phase_name TEXT,
    program_name TEXT,
    program_library_title TEXT,
    enrollment_id UUID
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_today DATE := CURRENT_DATE;
BEGIN
    -- First check scheduled_sessions for today
    RETURN QUERY
    SELECT
        ss.session_id,
        COALESCE(s.name, ss.workout_name) as session_name,
        COALESCE(p.name, 'Enrolled Program') as phase_name,
        COALESCE(prog.name, 'Enrolled Program') as program_name,
        pl.title as program_library_title,
        ss.enrollment_id
    FROM scheduled_sessions ss
    LEFT JOIN sessions s ON s.id = ss.session_id
    LEFT JOIN phases p ON p.id = s.phase_id
    LEFT JOIN programs prog ON prog.id = p.program_id
    LEFT JOIN program_enrollments pe ON pe.id = ss.enrollment_id
    LEFT JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE ss.patient_id = p_patient_id
      AND ss.scheduled_date = v_today
      AND ss.status = 'scheduled'
    ORDER BY ss.created_at
    LIMIT 1;

    -- If no scheduled session, return first session from enrolled program
    IF NOT FOUND THEN
        RETURN QUERY
        SELECT
            s.id as session_id,
            s.name as session_name,
            p.name as phase_name,
            prog.name as program_name,
            pl.title as program_library_title,
            pe.id as enrollment_id
        FROM sessions s
        JOIN phases p ON p.id = s.phase_id
        JOIN programs prog ON prog.id = p.program_id
        JOIN program_library pl ON pl.program_id = prog.id
        JOIN program_enrollments pe ON pe.program_library_id = pl.id
        WHERE pe.patient_id = p_patient_id
          AND pe.status = 'active'
        ORDER BY p.sequence, s.sequence
        LIMIT 1;
    END IF;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_today_enrolled_session(UUID) TO authenticated;

-- ============================================================================
-- Test the functions
-- ============================================================================

DO $$
DECLARE
    v_count INT;
    v_patient_id UUID := '743bbbd4-771a-418e-b161-a7a9e88c83e7'::UUID;
BEGIN
    -- Test get_enrolled_program_sessions
    SELECT COUNT(*) INTO v_count
    FROM get_enrolled_program_sessions(v_patient_id);

    RAISE NOTICE 'get_enrolled_program_sessions returned % rows for paul@romatech.com', v_count;

    -- Test get_today_enrolled_session
    SELECT COUNT(*) INTO v_count
    FROM get_today_enrolled_session(v_patient_id);

    RAISE NOTICE 'get_today_enrolled_session returned % rows for paul@romatech.com', v_count;
END $$;
