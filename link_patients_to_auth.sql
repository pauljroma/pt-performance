-- ============================================================================
-- Link Patients to Auth Users
-- Run this AFTER applying migration 009_fix_rls_policies.sql
-- Date: 2025-12-09
-- ============================================================================

-- This script links existing patient records to their corresponding auth.users
-- based on matching email addresses

-- STEP 1: Review current status
-- Shows which patients are linked vs unlinked

SELECT
  'Current Patient-Auth Linkage Status' as info,
  COUNT(*) as total_patients,
  COUNT(user_id) as linked_patients,
  COUNT(*) - COUNT(user_id) as unlinked_patients
FROM patients;

-- Show details
SELECT
  p.id as patient_id,
  p.first_name,
  p.last_name,
  p.email as patient_email,
  p.user_id,
  au.email as auth_email,
  CASE
    WHEN p.user_id IS NOT NULL THEN '✅ LINKED'
    WHEN p.email IS NOT NULL AND au.email IS NOT NULL THEN '⚠️  CAN LINK (email match)'
    WHEN p.email IS NULL THEN '❌ NO EMAIL ON PATIENT'
    ELSE '❌ NO MATCHING AUTH USER'
  END as status
FROM patients p
LEFT JOIN auth.users au ON p.email = au.email
ORDER BY p.created_at DESC;

-- ============================================================================
-- STEP 2: Link patients to auth users by email (DRY RUN)
-- ============================================================================

-- This shows what WOULD be updated (doesn't actually update)
SELECT
  'Patients that can be linked by email' as info;

SELECT
  p.id as patient_id,
  p.first_name || ' ' || p.last_name as patient_name,
  p.email,
  au.id as auth_user_id,
  'UPDATE patients SET user_id = ''' || au.id || ''' WHERE id = ''' || p.id || ''';' as update_statement
FROM patients p
INNER JOIN auth.users au ON p.email = au.email
WHERE p.user_id IS NULL
  AND p.email IS NOT NULL;

-- ============================================================================
-- STEP 3: Actually link patients to auth users
-- UNCOMMENT THE LINES BELOW TO EXECUTE THE UPDATE
-- ============================================================================

/*
-- Link all patients with matching emails to auth users
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL
  AND p.email IS NOT NULL;

-- Show results
SELECT
  'Linkage Complete' as info,
  COUNT(*) as total_patients,
  COUNT(user_id) as linked_patients,
  COUNT(*) - COUNT(user_id) as unlinked_patients
FROM patients;
*/

-- ============================================================================
-- STEP 4: Manual linking (for specific patients)
-- ============================================================================

-- Example: Link a specific patient by email
/*
UPDATE patients
SET user_id = (SELECT id FROM auth.users WHERE email = 'patient@example.com')
WHERE email = 'patient@example.com'
  AND user_id IS NULL;
*/

-- Example: Link Adam Mitchell (demo patient)
/*
UPDATE patients
SET user_id = (SELECT id FROM auth.users WHERE email = 'adam@demo.com')
WHERE email = 'adam@demo.com'
  AND user_id IS NULL;
*/

-- ============================================================================
-- STEP 5: Verification after linking
-- ============================================================================

-- Run this after linking to verify
/*
SELECT
  p.id,
  p.first_name || ' ' || p.last_name as patient_name,
  p.email,
  p.user_id,
  au.email as auth_email,
  au.created_at as auth_created_at,
  au.last_sign_in_at as last_sign_in,
  CASE
    WHEN p.user_id IS NOT NULL THEN '✅ LINKED'
    ELSE '❌ NOT LINKED'
  END as status
FROM patients p
LEFT JOIN auth.users au ON p.user_id = au.id
ORDER BY p.created_at DESC;
*/

-- ============================================================================
-- TROUBLESHOOTING
-- ============================================================================

-- Check for patients with no email (cannot auto-link)
SELECT
  'Patients with no email address' as info;

SELECT
  id,
  first_name,
  last_name,
  email,
  user_id,
  therapist_id
FROM patients
WHERE email IS NULL
ORDER BY created_at DESC;

-- Check for patients with email but no matching auth user
SELECT
  'Patients with email but no matching auth user' as info;

SELECT
  p.id,
  p.first_name,
  p.last_name,
  p.email
FROM patients p
LEFT JOIN auth.users au ON p.email = au.email
WHERE p.email IS NOT NULL
  AND au.id IS NULL
ORDER BY p.created_at DESC;

-- Check for auth users with no matching patient
SELECT
  'Auth users with no matching patient' as info;

SELECT
  au.id,
  au.email,
  au.created_at
FROM auth.users au
LEFT JOIN patients p ON au.email = p.email
WHERE p.id IS NULL
ORDER BY au.created_at DESC;

-- ============================================================================
-- NOTES
-- ============================================================================

/*
IMPORTANT:
1. Run STEP 1 first to see current status
2. Run STEP 2 to see what would be updated (dry run)
3. Uncomment STEP 3 to actually perform the update
4. Run STEP 5 to verify the linkage was successful

MANUAL LINKING:
If you need to link specific patients, use STEP 4 examples.

SECURITY:
The user_id links patient records to Supabase auth users.
Without this link, patients cannot access their data due to RLS policies.

AFTER LINKING:
Test patient login and data access to ensure RLS policies work correctly.
*/
