-- Verification query to check auth linkages
DO $$
DECLARE
  patient_auth_id UUID;
  therapist_auth_id UUID;
  patient_record_user_id UUID;
  therapist_record_user_id UUID;
  patient_has_therapist BOOLEAN;
BEGIN
  -- Get auth user IDs
  SELECT id INTO patient_auth_id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app';
  SELECT id INTO therapist_auth_id FROM auth.users WHERE email = 'demo-pt@ptperformance.app';

  -- Get patient/therapist record user_ids
  SELECT user_id INTO patient_record_user_id FROM patients WHERE email = 'demo-athlete@ptperformance.app';
  SELECT user_id INTO therapist_record_user_id FROM therapists WHERE email = 'demo-pt@ptperformance.app';

  -- Check if patient has therapist
  SELECT therapist_id IS NOT NULL INTO patient_has_therapist FROM patients WHERE email = 'demo-athlete@ptperformance.app';

  RAISE NOTICE '========================================';
  RAISE NOTICE 'AUTH USERS:';
  RAISE NOTICE '  Patient auth.users ID: %', patient_auth_id;
  RAISE NOTICE '  Therapist auth.users ID: %', therapist_auth_id;
  RAISE NOTICE '';
  RAISE NOTICE 'LINKAGES:';
  RAISE NOTICE '  Patient record user_id: %', patient_record_user_id;
  RAISE NOTICE '  Therapist record user_id: %', therapist_record_user_id;
  RAISE NOTICE '';
  RAISE NOTICE 'STATUS:';
  RAISE NOTICE '  Patient linked to auth: %', CASE WHEN patient_record_user_id = patient_auth_id THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  Therapist linked to auth: %', CASE WHEN therapist_record_user_id = therapist_auth_id THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '  Patient has therapist: %', CASE WHEN patient_has_therapist THEN '✅ YES' ELSE '❌ NO' END;
  RAISE NOTICE '========================================';
END $$;
