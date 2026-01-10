-- 20251213120000_create_nic_roma_demo_user.sql
-- Create demo auth user and patient record for Nic Roma
-- Zone-7 (Data Access), Zone-8 (Data Ingestion)
--
-- Creates:
-- 1. Auth user for nic-demo@ptperformance.app
-- 2. Patient record for Nic Roma (linked to existing therapist)
--
-- Run after: 20251210000010_seed_demo_data.sql

-- ============================================================================
-- 1. CREATE NIC ROMA PATIENT RECORD
-- ============================================================================
-- Note: patient_id must match the ID used in 20251213000003_seed_winter_lift_program.sql

INSERT INTO patients (
  id,
  therapist_id,
  first_name,
  last_name,
  email,
  date_of_birth,
  sport,
  position,
  dominant_hand,
  height_in,
  weight_lb,
  medical_history,
  medications,
  goals,
  created_at
)
VALUES (
  '27d60616-8cb9-4434-b2b9-e84476788e08'::uuid,  -- Matches Winter Lift program
  '00000000-0000-0000-0000-000000000100'::uuid,  -- Sarah Thompson (demo therapist)
  'Nic',
  'Roma',
  'nic-demo@ptperformance.app',
  '1992-08-15'::date,
  'General Fitness',
  'Strength Training',
  'Right',
  70,
  185,
  '{
    "injuries": [],
    "surgeries": [],
    "chronic_conditions": []
  }'::jsonb,
  '{
    "current": [],
    "allergies": []
  }'::jsonb,
  'Build strength and muscle mass through progressive resistance training. Improve work capacity and movement quality.',
  '2025-01-13 08:00:00'::timestamptz
)
ON CONFLICT (id) DO UPDATE
SET
  email = EXCLUDED.email,
  first_name = EXCLUDED.first_name,
  last_name = EXCLUDED.last_name;

-- ============================================================================
-- 2. CREATE AUTH USER FOR NIC ROMA
-- ============================================================================
-- Create auth user automatically via Supabase admin functions
-- Password: demo-patient-2025 (same as John Brebbia for consistency)

DO $$
DECLARE
  nic_auth_id uuid;
  nic_patient_id uuid := '27d60616-8cb9-4434-b2b9-e84476788e08'::uuid;
  new_user_id uuid;
BEGIN
  -- Check if auth user already exists
  SELECT id INTO nic_auth_id
  FROM auth.users
  WHERE email = 'nic-demo@ptperformance.app';

  IF nic_auth_id IS NULL THEN
    -- Create auth user using Supabase internal function
    -- Insert into auth.users with encrypted password
    INSERT INTO auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    )
    VALUES (
      '00000000-0000-0000-0000-000000000000',
      gen_random_uuid(),
      'authenticated',
      'authenticated',
      'nic-demo@ptperformance.app',
      crypt('demo-patient-2025', gen_salt('bf')),  -- bcrypt hash
      now(),
      now(),
      now(),
      '',
      '',
      '',
      ''
    )
    RETURNING id INTO new_user_id;

    -- Insert into auth.identities table
    INSERT INTO auth.identities (
      id,
      provider_id,
      user_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    )
    VALUES (
      gen_random_uuid(),
      new_user_id::text,
      new_user_id,
      jsonb_build_object('sub', new_user_id::text, 'email', 'nic-demo@ptperformance.app'),
      'email',
      now(),
      now(),
      now()
    );

    -- Link to patient record
    UPDATE patients
    SET user_id = new_user_id
    WHERE id = nic_patient_id;

    RAISE NOTICE '✅ Created auth user and linked to Nic Roma patient record: %', new_user_id;
  ELSE
    -- Link existing auth user to patient record
    UPDATE patients
    SET user_id = nic_auth_id
    WHERE id = nic_patient_id AND user_id IS NULL;

    RAISE NOTICE '✅ Linked Nic Roma patient record to existing auth user %', nic_auth_id;
  END IF;
END $$;

-- ============================================================================
-- 3. VALIDATION
-- ============================================================================

DO $$
DECLARE
  nic_patient_exists boolean;
  nic_has_program boolean;
  nic_auth_exists boolean;
BEGIN
  -- Check patient record exists
  SELECT EXISTS(
    SELECT 1 FROM patients WHERE id = '27d60616-8cb9-4434-b2b9-e84476788e08'
  ) INTO nic_patient_exists;

  -- Check Winter Lift program exists
  SELECT EXISTS(
    SELECT 1 FROM programs WHERE patient_id = '27d60616-8cb9-4434-b2b9-e84476788e08'
  ) INTO nic_has_program;

  -- Check auth user exists
  SELECT EXISTS(
    SELECT 1 FROM auth.users WHERE email = 'nic-demo@ptperformance.app'
  ) INTO nic_auth_exists;

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'NIC ROMA DEMO USER VALIDATION';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Patient record: %', CASE WHEN nic_patient_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE 'Winter Lift program: %', CASE WHEN nic_has_program THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE 'Auth user: %', CASE WHEN nic_auth_exists THEN '✅ EXISTS' ELSE '⚠️  CREATE MANUALLY' END;
  RAISE NOTICE '============================================';
END $$;
