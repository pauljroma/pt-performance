-- Fix Clinical View Security
-- Add SECURITY_INVOKER to all clinical analytics views
-- This ensures RLS policies are properly enforced
-- Created: 2026-02-07

-- ============================================================================
-- Helper function: is_therapist(user_id)
-- The function already exists, skip recreation to avoid breaking RLS policies
-- ============================================================================

-- Function is_therapist(UUID) already exists from earlier migrations
-- Just ensure grants are in place
GRANT EXECUTE ON FUNCTION public.is_therapist(UUID) TO authenticated;

-- ============================================================================
-- Helper function: is_therapist()
-- Returns true if the current user is a therapist (no args version)
-- ============================================================================

CREATE OR REPLACE FUNCTION public.is_therapist()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.therapists
        WHERE user_id = auth.uid()
    );
END;
$$;

COMMENT ON FUNCTION public.is_therapist() IS 'Returns true if the current authenticated user is a therapist';

GRANT EXECUTE ON FUNCTION public.is_therapist() TO authenticated;

-- ============================================================================
-- Fix: vw_assessment_progress
-- ============================================================================

ALTER VIEW public.vw_assessment_progress SET (security_invoker = on);

-- ============================================================================
-- Fix: vw_outcome_measures_trend
-- ============================================================================

ALTER VIEW public.vw_outcome_measures_trend SET (security_invoker = on);

-- ============================================================================
-- Fix: vw_clinical_pain_trend
-- ============================================================================

ALTER VIEW public.vw_clinical_pain_trend SET (security_invoker = on);

-- ============================================================================
-- Fix: vw_therapist_documentation_dashboard
-- ============================================================================

ALTER VIEW public.vw_therapist_documentation_dashboard SET (security_invoker = on);

-- ============================================================================
-- Fix: vw_visit_summary_details
-- ============================================================================

ALTER VIEW public.vw_visit_summary_details SET (security_invoker = on);

-- ============================================================================
-- Fix: vw_patient_exceptions (from coaching system)
-- ============================================================================

-- Only alter if the view exists (from coaching migration)
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.views WHERE table_name = 'vw_patient_exceptions' AND table_schema = 'public') THEN
        ALTER VIEW public.vw_patient_exceptions SET (security_invoker = on);
        RAISE NOTICE 'vw_patient_exceptions: SECURITY_INVOKER enabled';
    ELSE
        RAISE NOTICE 'vw_patient_exceptions: view not found (coaching migration may not be applied yet)';
    END IF;
END $$;

-- ============================================================================
-- Verification query (run manually to verify)
-- ============================================================================
-- SELECT viewname, pg_get_viewdef(c.oid)
-- FROM pg_views v
-- JOIN pg_class c ON c.relname = v.viewname
-- WHERE v.schemaname = 'public'
--   AND v.viewname LIKE 'vw_%';
