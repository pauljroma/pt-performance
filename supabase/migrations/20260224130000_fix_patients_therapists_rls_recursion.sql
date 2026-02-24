-- Build 602: Fix infinite recursion between patients and therapists RLS policies
--
-- ROOT CAUSE:
--   patients_auth_select ON patients: ... therapist_id IN (SELECT id FROM therapists WHERE ...)
--   therapists_authenticated_select ON therapists: ... id IN (SELECT therapist_id FROM patients WHERE ...)
--   These cross-reference each other, causing PostgreSQL to detect infinite recursion.
--
-- FIX:
--   Replace inline SELECTs with SECURITY DEFINER functions that bypass RLS,
--   breaking the circular evaluation chain.

BEGIN;

-- ============================================================================
-- 1. Create SECURITY DEFINER helper to check if user is a therapist and get ID
--    This replaces: SELECT id FROM therapists WHERE user_id = auth.uid()
--    Used in patients policies to check therapist access
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_therapist_id_for_user()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    tid UUID;
BEGIN
    SELECT id INTO tid FROM public.therapists WHERE user_id = auth.uid() LIMIT 1;
    RETURN tid;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_therapist_id_for_user() TO authenticated;

-- ============================================================================
-- 2. Create SECURITY DEFINER helper to get patient's therapist_id
--    This replaces: SELECT therapist_id FROM patients WHERE user_id = auth.uid()
--    Used in therapists policies to let patients see their therapist
-- ============================================================================

CREATE OR REPLACE FUNCTION public.get_patient_therapist_ids()
RETURNS SETOF UUID
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN QUERY SELECT therapist_id FROM public.patients
        WHERE user_id = auth.uid() AND therapist_id IS NOT NULL;
END;
$$;

GRANT EXECUTE ON FUNCTION public.get_patient_therapist_ids() TO authenticated;

-- ============================================================================
-- 3. Fix patients policies — replace inline therapists SELECT
-- ============================================================================

DROP POLICY IF EXISTS "patients_auth_select" ON patients;
DROP POLICY IF EXISTS "patients_auth_update" ON patients;

CREATE POLICY "patients_auth_select"
    ON patients FOR SELECT
    TO authenticated
    USING (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = auth_email()
        OR therapist_id = get_therapist_id_for_user()
    );

CREATE POLICY "patients_auth_update"
    ON patients FOR UPDATE
    TO authenticated
    USING (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = auth_email()
        OR therapist_id = get_therapist_id_for_user()
    )
    WITH CHECK (
        id = '00000000-0000-0000-0000-000000000001'::uuid
        OR user_id = auth.uid()
        OR email = auth_email()
        OR therapist_id = get_therapist_id_for_user()
    );

-- ============================================================================
-- 4. Fix therapists policies — replace inline patients SELECT
-- ============================================================================

DROP POLICY IF EXISTS "therapists_authenticated_select" ON therapists;

-- Patients can see their own therapist's record
CREATE POLICY "therapists_authenticated_select" ON public.therapists
    FOR SELECT
    TO authenticated
    USING (
        id IN (SELECT get_patient_therapist_ids())
    );

-- ============================================================================
-- 5. Force PostgREST schema cache reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

COMMIT;
