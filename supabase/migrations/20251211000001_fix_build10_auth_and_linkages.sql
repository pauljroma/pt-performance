-- ============================================================================
-- FIX BUILD 10: Auth User Linkages
-- ============================================================================
-- This migration fixes the empty data issue by:
-- 1. Fixing user_id linkages for patients and therapists
-- 2. Ensuring patient is linked to therapist
-- 3. Verifying all linkages are correct
--
-- Date: 2025-12-11
-- Issue: Build 10 empty data after successful login
-- Root Cause: patients.user_id and therapists.user_id not linked to auth.users
--
-- Note: Passwords were updated separately via fix_demo_user_passwords.py
-- ============================================================================

-- STEP 1: Link patient record to auth user (using actual auth user ID)
-- ============================================================================

UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND au.email = 'demo-athlete@ptperformance.app';

-- STEP 2: Link therapist record to auth user (using actual auth user ID)
-- ============================================================================

UPDATE therapists t
SET user_id = au.id
FROM auth.users au
WHERE t.email = 'demo-pt@ptperformance.app'
  AND au.email = 'demo-pt@ptperformance.app';

-- STEP 3: Ensure patient is linked to therapist
-- ============================================================================

UPDATE patients p
SET therapist_id = t.id
FROM therapists t
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND t.email = 'demo-pt@ptperformance.app'
  AND p.therapist_id IS NULL;  -- Only update if not already set

-- STEP 5: Verification and Report
-- ============================================================================

DO $$
DECLARE
  patient_auth_id UUID;
  patient_user_id UUID;
  therapist_auth_id UUID;
  therapist_user_id UUID;
  patient_therapist_id UUID;
  therapist_id UUID;
  patient_linked BOOLEAN;
  therapist_linked BOOLEAN;
  relationship_linked BOOLEAN;
BEGIN
  -- Get auth user IDs
  SELECT id INTO patient_auth_id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app';
  SELECT id INTO therapist_auth_id FROM auth.users WHERE email = 'demo-pt@ptperformance.app';

  -- Get record user_ids
  SELECT user_id INTO patient_user_id FROM patients WHERE email = 'demo-athlete@ptperformance.app';
  SELECT user_id INTO therapist_user_id FROM therapists WHERE email = 'demo-pt@ptperformance.app';

  -- Get relationship
  SELECT p.therapist_id, t.id INTO patient_therapist_id, therapist_id
  FROM patients p
  CROSS JOIN therapists t
  WHERE p.email = 'demo-athlete@ptperformance.app'
    AND t.email = 'demo-pt@ptperformance.app';

  -- Check linkages
  patient_linked := (patient_user_id = patient_auth_id);
  therapist_linked := (therapist_user_id = therapist_auth_id);
  relationship_linked := (patient_therapist_id = therapist_id);

  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'BUILD 10 FIX - VERIFICATION REPORT';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'AUTH USERS:';
  RAISE NOTICE '  Patient auth.users.id:   %', patient_auth_id;
  RAISE NOTICE '  Therapist auth.users.id: %', therapist_auth_id;
  RAISE NOTICE '';
  RAISE NOTICE 'RECORD LINKAGES:';
  RAISE NOTICE '  patients.user_id:        %', patient_user_id;
  RAISE NOTICE '  therapists.user_id:      %', therapist_user_id;
  RAISE NOTICE '  patients.therapist_id:   %', patient_therapist_id;
  RAISE NOTICE '';
  RAISE NOTICE 'VALIDATION:';
  RAISE NOTICE '  Patient linked to auth:       % %',
    CASE WHEN patient_linked THEN '✅' ELSE '❌' END,
    CASE WHEN patient_linked THEN 'PASS' ELSE 'FAIL' END;
  RAISE NOTICE '  Therapist linked to auth:     % %',
    CASE WHEN therapist_linked THEN '✅' ELSE '❌' END,
    CASE WHEN therapist_linked THEN 'PASS' ELSE 'FAIL' END;
  RAISE NOTICE '  Patient linked to therapist:  % %',
    CASE WHEN relationship_linked THEN '✅' ELSE '❌' END,
    CASE WHEN relationship_linked THEN 'PASS' ELSE 'FAIL' END;
  RAISE NOTICE '';

  IF patient_linked AND therapist_linked AND relationship_linked THEN
    RAISE NOTICE '========================================================================';
    RAISE NOTICE '✅ ALL CHECKS PASSED - Build 11 ready for deployment!';
    RAISE NOTICE '========================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'iOS App Credentials (Config.swift):';
    RAISE NOTICE '  Patient:   demo-athlete@ptperformance.app / demo-patient-2025';
    RAISE NOTICE '  Therapist: demo-pt@ptperformance.app / demo-therapist-2025';
    RAISE NOTICE '';
  ELSE
    RAISE WARNING '========================================================================';
    RAISE WARNING '❌ VALIDATION FAILED - DO NOT DEPLOY';
    RAISE WARNING '========================================================================';
  END IF;
END $$;
