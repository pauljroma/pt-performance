-- Verify RLS policies exist for therapist access

-- Check RLS policies on patients table
SELECT
  schemaname,
  tablename,
  policyname,
  CASE
    WHEN policyname LIKE '%therapist%' THEN '✅ Therapist policy'
    WHEN policyname LIKE '%patient%' THEN '✅ Patient policy'
    ELSE '⚠️ Other policy'
  END as policy_type
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN ('patients', 'programs', 'phases', 'sessions')
ORDER BY tablename, policyname;

-- Test: Can therapist see their patients? (simulation)
-- This tests the data without RLS (to verify data exists)
SELECT
  'Data Check (No RLS)' as test,
  COUNT(*) as patient_count,
  array_agg(p.email) as patient_emails
FROM patients p
JOIN therapists t ON p.therapist_id = t.id
WHERE t.email = 'demo-pt@ptperformance.app';

-- Show therapist and patient IDs for debugging
SELECT
  'Therapist Info' as type,
  t.id as therapist_id,
  t.email,
  t.user_id as therapist_user_id,
  (SELECT COUNT(*) FROM patients WHERE therapist_id = t.id) as patient_count
FROM therapists t
WHERE t.email = 'demo-pt@ptperformance.app';

SELECT
  'Patient Info' as type,
  p.id as patient_id,
  p.email,
  p.user_id as patient_user_id,
  p.therapist_id,
  t.email as therapist_email
FROM patients p
LEFT JOIN therapists t ON p.therapist_id = t.id
WHERE p.email = 'demo-athlete@ptperformance.app';
