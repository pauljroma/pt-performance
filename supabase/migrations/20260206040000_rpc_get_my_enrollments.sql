-- Build 447: RPC to get current user's enrolled programs
-- Handles the auth.uid() to patients.id lookup internally

-- ============================================================================
-- Function: Get my enrolled programs with program details
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_enrolled_programs()
RETURNS TABLE (
    enrollment_id UUID,
    program_library_id UUID,
    program_title TEXT,
    program_category TEXT,
    program_description TEXT,
    program_duration_weeks INT,
    program_difficulty_level TEXT,
    program_cover_image_url TEXT,
    enrollment_status TEXT,
    progress_percentage INT,
    enrolled_at TIMESTAMPTZ,
    started_at TIMESTAMPTZ
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_patient_id UUID;
    v_auth_email TEXT;
BEGIN
    -- Get the current user's email from JWT
    v_auth_email := auth.jwt() ->> 'email';

    -- Find patient ID by auth user_id or email
    SELECT p.id INTO v_patient_id
    FROM patients p
    WHERE p.user_id = auth.uid()
       OR p.email = v_auth_email
    LIMIT 1;

    IF v_patient_id IS NULL THEN
        RAISE NOTICE 'No patient found for auth.uid()=% or email=%', auth.uid(), v_auth_email;
        RETURN;
    END IF;

    RAISE NOTICE 'Found patient_id=% for email=%', v_patient_id, v_auth_email;

    -- Return enrolled programs
    RETURN QUERY
    SELECT
        pe.id as enrollment_id,
        pl.id as program_library_id,
        pl.title as program_title,
        pl.category as program_category,
        pl.description as program_description,
        pl.duration_weeks as program_duration_weeks,
        pl.difficulty_level as program_difficulty_level,
        pl.cover_image_url as program_cover_image_url,
        pe.status as enrollment_status,
        pe.progress_percentage,
        pe.enrolled_at,
        pe.started_at
    FROM program_enrollments pe
    JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE pe.patient_id = v_patient_id
      AND pe.status = 'active'
    ORDER BY pe.enrolled_at DESC;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_my_enrolled_programs() TO authenticated;

-- ============================================================================
-- Function: Get my patient ID (for debugging)
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_patient_id()
RETURNS TABLE (
    patient_id UUID,
    patient_email TEXT,
    auth_uid UUID,
    auth_email TEXT,
    match_type TEXT
)
LANGUAGE plpgsql
SECURITY INVOKER
AS $$
DECLARE
    v_auth_email TEXT;
BEGIN
    v_auth_email := auth.jwt() ->> 'email';

    -- Try by user_id first
    RETURN QUERY
    SELECT
        p.id as patient_id,
        p.email as patient_email,
        auth.uid() as auth_uid,
        v_auth_email as auth_email,
        'user_id' as match_type
    FROM patients p
    WHERE p.user_id = auth.uid()
    LIMIT 1;

    IF FOUND THEN
        RETURN;
    END IF;

    -- Fall back to email
    RETURN QUERY
    SELECT
        p.id as patient_id,
        p.email as patient_email,
        auth.uid() as auth_uid,
        v_auth_email as auth_email,
        'email' as match_type
    FROM patients p
    WHERE p.email = v_auth_email
    LIMIT 1;
END;
$$;

GRANT EXECUTE ON FUNCTION get_my_patient_id() TO authenticated;

-- ============================================================================
-- Test the function
-- ============================================================================

DO $$
DECLARE
    v_count INT;
BEGIN
    -- Test with paul@romatech.com's patient_id directly
    SELECT COUNT(*) INTO v_count
    FROM program_enrollments pe
    JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE pe.patient_id = '743bbbd4-771a-418e-b161-a7a9e88c83e7'::UUID
      AND pe.status = 'active';

    RAISE NOTICE 'Direct query: % active enrollments for paul@romatech.com', v_count;
END $$;
