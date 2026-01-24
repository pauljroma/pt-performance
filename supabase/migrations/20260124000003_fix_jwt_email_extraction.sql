-- Migration: Fix JWT email extraction for RLS
-- Created: 2026-01-24
-- Purpose: Handle multiple possible email locations in Supabase JWT

-- ============================================================================
-- 1. UPDATE get_patient_id_for_auth_user FUNCTION
-- ============================================================================

-- Drop and recreate with better email extraction
CREATE OR REPLACE FUNCTION public.get_patient_id_for_auth_user()
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
    v_patient_id UUID;
BEGIN
    -- Try multiple ways to get the email from JWT
    -- Method 1: Direct email claim (standard Supabase)
    v_email := auth.jwt() ->> 'email';
    
    -- Method 2: From user_metadata (alternative location)
    IF v_email IS NULL THEN
        v_email := auth.jwt() -> 'user_metadata' ->> 'email';
    END IF;
    
    -- Method 3: From app_metadata
    IF v_email IS NULL THEN
        v_email := auth.jwt() -> 'app_metadata' ->> 'email';
    END IF;
    
    -- Debug: If still null, return null (will fail RLS check)
    IF v_email IS NULL THEN
        RAISE WARNING 'No email found in JWT for RLS check';
        RETURN NULL;
    END IF;
    
    -- Look up the patient by email
    SELECT id INTO v_patient_id
    FROM patients
    WHERE email = v_email
    LIMIT 1;
    
    -- Debug: Log if patient not found
    IF v_patient_id IS NULL THEN
        RAISE WARNING 'No patient found for email: %', v_email;
    END IF;
    
    RETURN v_patient_id;
END;
$$;

-- Also update user_owns_manual_session to use same pattern
CREATE OR REPLACE FUNCTION public.user_owns_manual_session(check_session_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
DECLARE
    v_email TEXT;
BEGIN
    -- Try multiple ways to get the email from JWT
    v_email := COALESCE(
        auth.jwt() ->> 'email',
        auth.jwt() -> 'user_metadata' ->> 'email',
        auth.jwt() -> 'app_metadata' ->> 'email'
    );
    
    IF v_email IS NULL THEN
        RETURN FALSE;
    END IF;
    
    RETURN EXISTS (
        SELECT 1
        FROM manual_sessions ms
        JOIN patients p ON p.id = ms.patient_id
        WHERE ms.id = check_session_id
        AND p.email = v_email
    );
END;
$$;

-- ============================================================================
-- 2. VERIFICATION
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'SUCCESS: Updated JWT email extraction functions';
END $$;
