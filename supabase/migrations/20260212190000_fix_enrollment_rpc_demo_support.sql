-- ============================================================================
-- FIX get_my_enrolled_programs() FOR DEMO MODE
-- ============================================================================
-- Problem: RPC uses auth.uid() which is NULL in demo mode (anon key)
-- Solution: Add parameter to pass patient_id directly, fallback for demo
-- Demo Patient ID: 00000000-0000-0000-0000-000000000001
-- ============================================================================

-- ============================================================================
-- STEP 1: Create new function with optional patient_id parameter
-- ============================================================================

CREATE OR REPLACE FUNCTION get_my_enrolled_programs(p_patient_id UUID DEFAULT NULL)
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
SECURITY DEFINER  -- Changed to DEFINER to bypass RLS
AS $$
DECLARE
    v_patient_id UUID;
    v_auth_email TEXT;
BEGIN
    -- If patient_id provided directly (demo mode), use it
    IF p_patient_id IS NOT NULL THEN
        v_patient_id := p_patient_id;
    ELSE
        -- Get the current user's email from JWT
        v_auth_email := auth.jwt() ->> 'email';

        -- Find patient ID by auth user_id or email
        SELECT p.id INTO v_patient_id
        FROM patients p
        WHERE p.user_id = auth.uid()
           OR p.email = v_auth_email
        LIMIT 1;
    END IF;

    -- Return empty if no patient found
    IF v_patient_id IS NULL THEN
        RETURN;
    END IF;

    -- Return enrolled programs for this patient
    RETURN QUERY
    SELECT
        pe.id as enrollment_id,
        pe.program_library_id,
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

-- ============================================================================
-- STEP 2: Grant execute to both anon and authenticated
-- ============================================================================

GRANT EXECUTE ON FUNCTION get_my_enrolled_programs(UUID) TO anon;
GRANT EXECUTE ON FUNCTION get_my_enrolled_programs(UUID) TO authenticated;

-- ============================================================================
-- STEP 3: Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_count INT;
BEGIN
    -- Test with demo patient
    SELECT COUNT(*) INTO v_count
    FROM get_my_enrolled_programs('00000000-0000-0000-0000-000000000001'::uuid);

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'get_my_enrolled_programs() Updated for Demo';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Demo patient enrolled programs: %', v_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Function now:';
    RAISE NOTICE '  - Accepts optional patient_id parameter';
    RAISE NOTICE '  - Works with anon role (demo mode)';
    RAISE NOTICE '  - Falls back to auth.uid() if no param';
    RAISE NOTICE '============================================';
END $$;
