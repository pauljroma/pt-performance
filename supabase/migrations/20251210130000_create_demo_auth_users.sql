-- Create demo auth users and link them properly

-- ============================================================================
-- 1. CREATE AUTH USERS (if they don't exist)
-- ============================================================================

-- Create demo patient auth user
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role,
  aud
)
VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'demo-athlete@ptperformance.app',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"name":"Demo Athlete"}'::jsonb,
  false,
  'authenticated',
  'authenticated'
)
ON CONFLICT (email) DO NOTHING;

-- Create demo therapist auth user
INSERT INTO auth.users (
  id,
  instance_id,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_super_admin,
  role,
  aud
)
VALUES (
  gen_random_uuid(),
  '00000000-0000-0000-0000-000000000000',
  'demo-pt@ptperformance.app',
  crypt('password123', gen_salt('bf')),
  now(),
  now(),
  now(),
  '{"provider":"email","providers":["email"]}'::jsonb,
  '{"name":"Demo Therapist"}'::jsonb,
  false,
  'authenticated',
  'authenticated'
)
ON CONFLICT (email) DO NOTHING;

-- ============================================================================
-- 2. LINK THERAPIST TO AUTH USER
-- ============================================================================

UPDATE therapists t
SET user_id = au.id
FROM auth.users au
WHERE t.email = au.email
  AND t.email = 'demo-pt@ptperformance.app';

-- ============================================================================
-- 3. LINK PATIENT TO AUTH USER
-- ============================================================================

UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.email = 'demo-athlete@ptperformance.app';

-- ============================================================================
-- 4. VERIFICATION
-- ============================================================================

DO $$
DECLARE
  patient_auth_exists BOOLEAN;
  therapist_auth_exists BOOLEAN;
  patient_linked BOOLEAN;
  therapist_linked BOOLEAN;
  patient_has_therapist BOOLEAN;
BEGIN
  -- Check auth users exist
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'demo-athlete@ptperformance.app') INTO patient_auth_exists;
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'demo-pt@ptperformance.app') INTO therapist_auth_exists;

  -- Check linkages
  SELECT user_id IS NOT NULL INTO patient_linked FROM patients WHERE email = 'demo-athlete@ptperformance.app';
  SELECT user_id IS NOT NULL INTO therapist_linked FROM therapists WHERE email = 'demo-pt@ptperformance.app';
  SELECT therapist_id IS NOT NULL INTO patient_has_therapist FROM patients WHERE email = 'demo-athlete@ptperformance.app';

  RAISE NOTICE '=== AUTH SETUP STATUS ===';
  RAISE NOTICE 'Patient auth user exists: %', patient_auth_exists;
  RAISE NOTICE 'Therapist auth user exists: %', therapist_auth_exists;
  RAISE NOTICE 'Patient linked to auth: %', patient_linked;
  RAISE NOTICE 'Therapist linked to auth: %', therapist_linked;
  RAISE NOTICE 'Patient has therapist: %', patient_has_therapist;

  IF patient_auth_exists AND therapist_auth_exists AND patient_linked AND therapist_linked AND patient_has_therapist THEN
    RAISE NOTICE '✅ ALL CHECKS PASSED - Ready for login!';
    RAISE NOTICE 'Login credentials:';
    RAISE NOTICE '  Patient: demo-athlete@ptperformance.app / password123';
    RAISE NOTICE '  Therapist: demo-pt@ptperformance.app / password123';
  ELSE
    RAISE WARNING '❌ SETUP INCOMPLETE - Check failed items above';
  END IF;
END $$;
