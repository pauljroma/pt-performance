-- =============================================================================
-- RLS Policy Verification SQL
-- =============================================================================
-- Purpose: Query pg_policies to verify RLS is enabled and policies exist
-- Usage: psql $DATABASE_URL -f scripts/verify_rls_policies.sql
--
-- Output format:
--   table_name|rls_enabled|policy_count|select_count|insert_count|update_count|delete_count|grants_ok
--
-- Date: 2026-02-07
-- =============================================================================

-- List of critical tables to verify
WITH critical_tables AS (
    SELECT unnest(ARRAY[
        'sessions',
        'session_exercises',
        'exercise_logs',
        'manual_sessions',
        'manual_session_exercises',
        'workout_prescriptions',
        'workout_modifications',
        'patient_favorite_templates',
        'patient_workout_templates',
        'system_workout_templates',
        'streak_records',
        'streak_history',
        'daily_readiness',
        'arm_care_assessments',
        'body_comp_measurements',
        'notification_settings',
        'prescription_notification_preferences',
        'patients',
        'therapists',
        'users'
    ]) AS table_name
),

-- Get RLS status for each table
table_rls_status AS (
    SELECT
        t.tablename AS table_name,
        t.rowsecurity AS rls_enabled
    FROM pg_tables t
    WHERE t.schemaname = 'public'
),

-- Count policies by command type for each table
policy_counts AS (
    SELECT
        p.tablename AS table_name,
        COUNT(*) AS total_policies,
        COUNT(*) FILTER (WHERE p.cmd = 'SELECT' OR p.cmd = 'ALL') AS select_policies,
        COUNT(*) FILTER (WHERE p.cmd = 'INSERT' OR p.cmd = 'ALL') AS insert_policies,
        COUNT(*) FILTER (WHERE p.cmd = 'UPDATE' OR p.cmd = 'ALL') AS update_policies,
        COUNT(*) FILTER (WHERE p.cmd = 'DELETE' OR p.cmd = 'ALL') AS delete_policies
    FROM pg_policies p
    WHERE p.schemaname = 'public'
    GROUP BY p.tablename
),

-- Check grants to authenticated and anon roles
table_grants AS (
    SELECT
        t.relname AS table_name,
        bool_or(g.grantee = 'authenticated' AND g.privilege_type = 'SELECT') AS auth_select,
        bool_or(g.grantee = 'authenticated' AND g.privilege_type = 'INSERT') AS auth_insert,
        bool_or(g.grantee = 'authenticated' AND g.privilege_type = 'UPDATE') AS auth_update,
        bool_or(g.grantee = 'authenticated' AND g.privilege_type = 'DELETE') AS auth_delete,
        bool_or(g.grantee = 'anon' AND g.privilege_type = 'SELECT') AS anon_select
    FROM pg_class t
    LEFT JOIN information_schema.role_table_grants g
        ON g.table_name = t.relname
        AND g.table_schema = 'public'
    WHERE t.relnamespace = 'public'::regnamespace
        AND t.relkind = 'r'
    GROUP BY t.relname
)

-- Final output
SELECT
    ct.table_name,
    COALESCE(rls.rls_enabled, false) AS rls_enabled,
    COALESCE(pc.total_policies, 0) AS policy_count,
    COALESCE(pc.select_policies, 0) AS select_count,
    COALESCE(pc.insert_policies, 0) AS insert_count,
    COALESCE(pc.update_policies, 0) AS update_count,
    COALESCE(pc.delete_policies, 0) AS delete_count,
    CASE
        WHEN COALESCE(g.auth_select, false) THEN 'OK'
        ELSE 'MISSING_GRANTS'
    END AS grants_ok
FROM critical_tables ct
LEFT JOIN table_rls_status rls ON rls.table_name = ct.table_name
LEFT JOIN policy_counts pc ON pc.table_name = ct.table_name
LEFT JOIN table_grants g ON g.table_name = ct.table_name
ORDER BY ct.table_name;

-- =============================================================================
-- Additional Detailed Policy Report (for verbose mode)
-- =============================================================================

-- This section outputs detailed policy information for debugging

-- SELECT '--- POLICY DETAILS ---' AS section;

-- Show all policies for critical tables
-- SELECT
--     p.tablename AS table_name,
--     p.policyname AS policy_name,
--     p.cmd AS command,
--     p.permissive AS is_permissive,
--     p.roles AS roles,
--     CASE
--         WHEN p.qual IS NULL THEN 'NO USING CLAUSE'
--         WHEN p.qual = 'true' THEN 'USING (true) - PERMISSIVE!'
--         ELSE 'Has USING clause'
--     END AS using_status,
--     CASE
--         WHEN p.with_check IS NULL THEN 'NO WITH CHECK'
--         WHEN p.with_check = 'true' THEN 'WITH CHECK (true) - PERMISSIVE!'
--         ELSE 'Has WITH CHECK'
--     END AS check_status
-- FROM pg_policies p
-- WHERE p.schemaname = 'public'
--     AND p.tablename IN (
--         'sessions', 'session_exercises', 'exercise_logs',
--         'manual_sessions', 'manual_session_exercises',
--         'workout_prescriptions', 'workout_modifications',
--         'patient_favorite_templates', 'patient_workout_templates', 'system_workout_templates',
--         'streak_records', 'streak_history', 'daily_readiness',
--         'arm_care_assessments', 'body_comp_measurements',
--         'notification_settings', 'prescription_notification_preferences',
--         'patients', 'therapists', 'users'
--     )
-- ORDER BY p.tablename, p.policyname;

-- =============================================================================
-- Check for Dangerous Policies
-- =============================================================================

-- SELECT '--- DANGEROUS POLICIES CHECK ---' AS section;

-- Find policies that may be too permissive
-- SELECT
--     p.tablename AS table_name,
--     p.policyname AS policy_name,
--     p.cmd AS command,
--     'DANGEROUS: USING (true) allows access to ALL rows!' AS warning
-- FROM pg_policies p
-- WHERE p.schemaname = 'public'
--     AND (p.qual = 'true' OR p.qual = '(true)')
--     AND p.tablename IN (
--         'sessions', 'session_exercises', 'exercise_logs',
--         'patients', 'daily_readiness', 'exercise_logs'
--     );

-- =============================================================================
-- Check for Tables with RLS Enabled but No Policies
-- =============================================================================

-- SELECT '--- RLS WITHOUT POLICIES (BLOCKED ACCESS) ---' AS section;

-- Tables with RLS enabled but no policies block ALL access
-- SELECT
--     t.tablename AS table_name,
--     'RLS enabled but NO POLICIES - all access blocked!' AS warning
-- FROM pg_tables t
-- LEFT JOIN pg_policies p ON p.tablename = t.tablename AND p.schemaname = t.schemaname
-- WHERE t.schemaname = 'public'
--     AND t.rowsecurity = true
--     AND p.policyname IS NULL;
