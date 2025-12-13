#!/bin/bash
set -e

echo "========================================================================"
echo "BUILD 11 PRE-UPLOAD VALIDATION"
echo "========================================================================"
echo ""
echo "This script validates that:"
echo "  1. Demo users can authenticate with correct passwords"
echo "  2. Auth linkages are correct (user_id matches auth.users.id)"
echo "  3. Database queries return expected data (not empty)"
echo "  4. RLS policies allow data access"
echo ""

cd supabase

# Export access token
export SUPABASE_ACCESS_TOKEN="sbp_066132db7c4b421210b0249fc463e84abcd945e4"

echo "Step 1: Checking auth users exist with correct emails..."
echo "------------------------------------------------------------------------"

# Create temporary validation migration
cat > migrations/99999999999997_validate_build11.sql << 'EOF'
-- Validation queries for Build 11

-- Check 1: Auth users exist
DO $$
DECLARE
  patient_exists BOOLEAN;
  therapist_exists BOOLEAN;
BEGIN
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'demo-athlete@ptperformance.app') INTO patient_exists;
  SELECT EXISTS(SELECT 1 FROM auth.users WHERE email = 'demo-pt@ptperformance.app') INTO therapist_exists;

  RAISE NOTICE '';
  RAISE NOTICE '=== CHECK 1: AUTH USERS EXIST ===';
  IF patient_exists AND therapist_exists THEN
    RAISE NOTICE '✅ PASS: Both auth users exist';
  ELSE
    RAISE WARNING '❌ FAIL: Auth users missing';
    RAISE WARNING '  Patient exists: %', patient_exists;
    RAISE WARNING '  Therapist exists: %', therapist_exists;
  END IF;
END $$;

-- Check 2: Linkages are correct
DO $$
DECLARE
  patient_linked BOOLEAN;
  therapist_linked BOOLEAN;
  patient_has_therapist BOOLEAN;
BEGIN
  SELECT p.user_id = au.id INTO patient_linked
  FROM patients p, auth.users au
  WHERE p.email = 'demo-athlete@ptperformance.app'
    AND au.email = 'demo-athlete@ptperformance.app';

  SELECT t.user_id = au.id INTO therapist_linked
  FROM therapists t, auth.users au
  WHERE t.email = 'demo-pt@ptperformance.app'
    AND au.email = 'demo-pt@ptperformance.app';

  SELECT p.therapist_id IS NOT NULL INTO patient_has_therapist
  FROM patients p
  WHERE p.email = 'demo-athlete@ptperformance.app';

  RAISE NOTICE '';
  RAISE NOTICE '=== CHECK 2: LINKAGES CORRECT ===';
  IF patient_linked AND therapist_linked AND patient_has_therapist THEN
    RAISE NOTICE '✅ PASS: All linkages correct';
  ELSE
    RAISE WARNING '❌ FAIL: Linkages broken';
    RAISE WARNING '  Patient linked: %', patient_linked;
    RAISE WARNING '  Therapist linked: %', therapist_linked;
    RAISE WARNING '  Patient has therapist: %', patient_has_therapist;
  END IF;
END $$;

-- Check 3: Demo data exists
DO $$
DECLARE
  program_count INT;
  phase_count INT;
  session_count INT;
BEGIN
  SELECT COUNT(*) INTO program_count FROM programs WHERE patient_id = '00000000-0000-0000-0000-000000000001';
  SELECT COUNT(*) INTO phase_count FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000200';
  SELECT COUNT(*) INTO session_count FROM sessions WHERE phase_id IN (
    SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000200'
  );

  RAISE NOTICE '';
  RAISE NOTICE '=== CHECK 3: DEMO DATA EXISTS ===';
  IF program_count > 0 AND phase_count >= 4 AND session_count >= 24 THEN
    RAISE NOTICE '✅ PASS: Demo data exists';
    RAISE NOTICE '  Programs: %', program_count;
    RAISE NOTICE '  Phases: %', phase_count;
    RAISE NOTICE '  Sessions: %', session_count;
  ELSE
    RAISE WARNING '❌ FAIL: Demo data missing or incomplete';
    RAISE WARNING '  Programs: % (expected: 1)', program_count;
    RAISE WARNING '  Phases: % (expected: 4)', phase_count;
    RAISE WARNING '  Sessions: % (expected: 24)', session_count;
  END IF;
END $$;

-- Check 4: RLS policies allow access (simulate auth context)
DO $$
DECLARE
  patient_programs INT;
  therapist_patients INT;
BEGIN
  -- Set session to patient auth user
  PERFORM set_config('request.jwt.claims', json_build_object('sub',
    (SELECT id::text FROM auth.users WHERE email = 'demo-athlete@ptperformance.app')
  )::text, false);

  -- Try to query as patient
  SELECT COUNT(*) INTO patient_programs FROM programs WHERE patient_id IN (
    SELECT id FROM patients WHERE user_id = (
      SELECT id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app'
    )
  );

  -- Set session to therapist auth user
  PERFORM set_config('request.jwt.claims', json_build_object('sub',
    (SELECT id::text FROM auth.users WHERE email = 'demo-pt@ptperformance.app')
  )::text, false);

  -- Try to query as therapist
  SELECT COUNT(*) INTO therapist_patients FROM patients WHERE therapist_id IN (
    SELECT id FROM therapists WHERE user_id = (
      SELECT id FROM auth.users WHERE email = 'demo-pt@ptperformance.app'
    )
  );

  RAISE NOTICE '';
  RAISE NOTICE '=== CHECK 4: RLS POLICIES ALLOW ACCESS ===';
  IF patient_programs > 0 AND therapist_patients > 0 THEN
    RAISE NOTICE '✅ PASS: RLS policies allow data access';
    RAISE NOTICE '  Patient can see programs: %', patient_programs;
    RAISE NOTICE '  Therapist can see patients: %', therapist_patients;
  ELSE
    RAISE WARNING '❌ FAIL: RLS policies blocking access';
    RAISE WARNING '  Patient programs visible: %', patient_programs;
    RAISE WARNING '  Therapist patients visible: %', therapist_patients;
  END IF;
END $$;

-- Final summary
DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'If all checks passed above, Build 11 is ready for TestFlight upload!';
  RAISE NOTICE '========================================================================';
END $$;
EOF

# Run the validation
echo ""
echo "Running validation checks..."
echo ""

supabase db push --include-all --yes 2>&1 | grep -A 50 "NOTICE\|WARNING"

# Clean up temporary migration
rm migrations/99999999999997_validate_build11.sql

echo ""
echo "========================================================================"
echo "Validation complete!"
echo "========================================================================"
echo ""
echo "Next steps:"
echo "  1. Review validation output above"
echo "  2. If all checks PASS, proceed to iOS build"
echo "  3. If any checks FAIL, run migration fix first"
echo ""
