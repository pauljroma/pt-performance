-- Verification queries for BUILD 143 migration
-- Run this in Supabase SQL editor to verify fixes were applied

-- Check 1: workout_timers RLS policies
SELECT
    'RLS Policies on workout_timers' as check_name,
    COUNT(*) as count,
    CASE
        WHEN COUNT(*) = 4 THEN '✅ PASS'
        ELSE '❌ FAIL - Expected 4 policies'
    END as status
FROM pg_policies
WHERE tablename = 'workout_timers';

-- Check 2: List all workout_timers policies
SELECT
    policyname as policy_name,
    cmd as command_type
FROM pg_policies
WHERE tablename = 'workout_timers'
ORDER BY policyname;

-- Check 3: calculate_rm_estimate functions exist
SELECT
    'calculate_rm_estimate functions' as check_name,
    COUNT(*) as count,
    CASE
        WHEN COUNT(*) >= 2 THEN '✅ PASS'
        ELSE '❌ FAIL - Expected 2 functions'
    END as status
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'calculate_rm_estimate'
AND n.nspname = 'public';

-- Check 4: List function signatures
SELECT
    p.proname as function_name,
    pg_get_function_identity_arguments(p.oid) as arguments
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE p.proname = 'calculate_rm_estimate'
AND n.nspname = 'public'
ORDER BY arguments;

-- Check 5: update_rm_estimate trigger exists
SELECT
    'update_rm_estimate trigger' as check_name,
    COUNT(*) as count,
    CASE
        WHEN COUNT(*) = 1 THEN '✅ PASS'
        ELSE '❌ FAIL - Expected 1 trigger'
    END as status
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE t.tgname = 'update_rm_estimate_trigger'
AND c.relname = 'exercise_logs';

-- Check 6: Test the functions work
SELECT
    'Function test: calculate_rm_estimate(100, 10)' as test_name,
    calculate_rm_estimate(100::numeric, 10) as result,
    CASE
        WHEN calculate_rm_estimate(100::numeric, 10) = 133.33 THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status;

SELECT
    'Function test: calculate_rm_estimate(100, ARRAY[10,8,6])' as test_name,
    calculate_rm_estimate(100::numeric, ARRAY[10,8,6]) as result,
    CASE
        WHEN calculate_rm_estimate(100::numeric, ARRAY[10,8,6]) = 120.00 THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status;

-- Summary
SELECT
    '=== VERIFICATION SUMMARY ===' as summary,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename = 'workout_timers') as rls_policies,
    (SELECT COUNT(*) FROM pg_proc p JOIN pg_namespace n ON p.pronamespace = n.oid WHERE p.proname = 'calculate_rm_estimate' AND n.nspname = 'public') as functions,
    (SELECT COUNT(*) FROM pg_trigger t JOIN pg_class c ON t.tgrelid = c.oid WHERE t.tgname = 'update_rm_estimate_trigger' AND c.relname = 'exercise_logs') as triggers;
