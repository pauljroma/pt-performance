-- Check therapist and patient linkage

-- 1. Check therapist record
SELECT
  'Therapist' as record_type,
  id,
  email,
  user_id,
  CASE
    WHEN user_id IS NULL THEN '❌ NOT LINKED TO AUTH'
    ELSE '✅ Linked to auth'
  END as auth_status
FROM therapists
WHERE email = 'demo-pt@ptperformance.app';

-- 2. Check patient record and therapist linkage
SELECT
  'Patient' as record_type,
  id,
  email,
  user_id,
  therapist_id,
  CASE
    WHEN user_id IS NULL THEN '❌ NOT LINKED TO AUTH'
    ELSE '✅ Linked to auth'
  END as patient_auth_status,
  CASE
    WHEN therapist_id IS NULL THEN '❌ NO THERAPIST'
    ELSE '✅ Has therapist'
  END as therapist_link_status
FROM patients
WHERE email = 'demo-athlete@ptperformance.app';

-- 3. Verify auth users exist
SELECT
  'Auth Users' as record_type,
  id,
  email
FROM auth.users
WHERE email IN ('demo-pt@ptperformance.app', 'demo-athlete@ptperformance.app')
ORDER BY email;

-- 4. Check if therapist can see patients (RLS policy test)
-- This simulates what the therapist user would see
SELECT
  'RLS Test' as test_type,
  COUNT(*) as patient_count
FROM patients p
WHERE p.therapist_id = (SELECT id FROM therapists WHERE email = 'demo-pt@ptperformance.app');
