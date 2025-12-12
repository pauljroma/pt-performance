-- Fix all auth user linkages for Build 9

-- 1. Link patient to auth.users
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.email = 'demo-athlete@ptperformance.app';

-- 2. Link therapist to auth.users
UPDATE therapists t
SET user_id = au.id
FROM auth.users au
WHERE t.email = au.email
  AND t.email = 'demo-pt@ptperformance.app';

-- 3. Link patient to therapist
UPDATE patients p
SET therapist_id = t.id
FROM therapists t
WHERE p.email = 'demo-athlete@ptperformance.app'
  AND t.email = 'demo-pt@ptperformance.app';

-- 4. Verify and report
DO $$
DECLARE
  patient_user_id UUID;
  patient_auth_id UUID;
  therapist_user_id UUID;
  therapist_auth_id UUID;
  patient_therapist_id UUID;
  therapist_id UUID;
BEGIN
  SELECT user_id INTO patient_user_id FROM patients WHERE email = 'demo-athlete@ptperformance.app';
  SELECT id INTO patient_auth_id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app';
  SELECT user_id INTO therapist_user_id FROM therapists WHERE email = 'demo-pt@ptperformance.app';
  SELECT id INTO therapist_auth_id FROM auth.users WHERE email = 'demo-pt@ptperformance.app';
  SELECT p.therapist_id, t.id INTO patient_therapist_id, therapist_id
  FROM patients p, therapists t
  WHERE p.email = 'demo-athlete@ptperformance.app'
    AND t.email = 'demo-pt@ptperformance.app';

  RAISE NOTICE '===========================================';
  RAISE NOTICE 'BUILD 9 LINKAGE STATUS:';
  RAISE NOTICE '===========================================';
  RAISE NOTICE 'Patient user_id: % (auth: %)', patient_user_id, patient_auth_id;
  RAISE NOTICE 'Patient linked: %', CASE WHEN patient_user_id = patient_auth_id THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  RAISE NOTICE 'Therapist user_id: % (auth: %)', therapist_user_id, therapist_auth_id;
  RAISE NOTICE 'Therapist linked: %', CASE WHEN therapist_user_id = therapist_auth_id THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '';
  RAISE NOTICE 'Patient therapist_id: % (should be: %)', patient_therapist_id, therapist_id;
  RAISE NOTICE 'Patient has therapist: %', CASE WHEN patient_therapist_id = therapist_id THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '===========================================';
END $$;
