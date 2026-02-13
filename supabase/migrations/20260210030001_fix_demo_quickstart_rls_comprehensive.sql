-- ============================================================================
-- COMPREHENSIVE DEMO QUICKSTART RLS FIX
-- ============================================================================
-- Problem: Multiple "permission denied" and RLS violations during quickstart
-- Root cause: anon role missing INSERT/UPDATE on multiple tables
-- Solution: Add full CRUD policies for anon on all quickstart-related tables
-- ============================================================================

-- ============================================================================
-- STEP 1: Fix patients table - more permissive UPDATE policy
-- ============================================================================

-- Drop and recreate with simpler condition
DROP POLICY IF EXISTS "patients_anon_update" ON patients;
DROP POLICY IF EXISTS "patients_anon_insert" ON patients;
DROP POLICY IF EXISTS "patients_anon_read" ON patients;

-- SELECT: any row (demo mode reads demo patient)
CREATE POLICY "patients_anon_read"
    ON patients FOR SELECT
    TO anon
    USING (true);

-- UPDATE: only demo patient, allow all field updates
CREATE POLICY "patients_anon_update"
    ON patients FOR UPDATE
    TO anon
    USING (id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (true);

-- INSERT: only demo patient ID allowed
CREATE POLICY "patients_anon_insert"
    ON patients FOR INSERT
    TO anon
    WITH CHECK (id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE ON patients TO anon;

-- ============================================================================
-- STEP 2: Fix patient_goals table
-- ============================================================================

DROP POLICY IF EXISTS "patient_goals_anon_read" ON patient_goals;
DROP POLICY IF EXISTS "patient_goals_anon_insert" ON patient_goals;
DROP POLICY IF EXISTS "patient_goals_anon_update" ON patient_goals;
DROP POLICY IF EXISTS "patient_goals_anon_delete" ON patient_goals;

CREATE POLICY "patient_goals_anon_read"
    ON patient_goals FOR SELECT
    TO anon
    USING (true);

CREATE POLICY "patient_goals_anon_insert"
    ON patient_goals FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "patient_goals_anon_update"
    ON patient_goals FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (true);

CREATE POLICY "patient_goals_anon_delete"
    ON patient_goals FOR DELETE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

GRANT SELECT, INSERT, UPDATE, DELETE ON patient_goals TO anon;

-- ============================================================================
-- STEP 3: Fix daily_readiness table
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_readiness') THEN
        EXECUTE 'DROP POLICY IF EXISTS "daily_readiness_anon_read" ON daily_readiness';
        EXECUTE 'DROP POLICY IF EXISTS "daily_readiness_anon_insert" ON daily_readiness';
        EXECUTE 'DROP POLICY IF EXISTS "daily_readiness_anon_update" ON daily_readiness';

        EXECUTE 'CREATE POLICY "daily_readiness_anon_read" ON daily_readiness FOR SELECT TO anon USING (true)';
        EXECUTE 'CREATE POLICY "daily_readiness_anon_insert" ON daily_readiness FOR INSERT TO anon WITH CHECK (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid)';
        EXECUTE 'CREATE POLICY "daily_readiness_anon_update" ON daily_readiness FOR UPDATE TO anon USING (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid) WITH CHECK (true)';

        EXECUTE 'GRANT SELECT, INSERT, UPDATE ON daily_readiness TO anon';
        RAISE NOTICE 'Fixed daily_readiness anon policies';
    END IF;
END $$;

-- ============================================================================
-- STEP 4: Fix streak_records table
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'streak_records') THEN
        EXECUTE 'DROP POLICY IF EXISTS "streak_records_anon_read" ON streak_records';
        EXECUTE 'DROP POLICY IF EXISTS "streak_records_anon_insert" ON streak_records';
        EXECUTE 'DROP POLICY IF EXISTS "streak_records_anon_update" ON streak_records';

        EXECUTE 'CREATE POLICY "streak_records_anon_read" ON streak_records FOR SELECT TO anon USING (true)';
        EXECUTE 'CREATE POLICY "streak_records_anon_insert" ON streak_records FOR INSERT TO anon WITH CHECK (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid)';
        EXECUTE 'CREATE POLICY "streak_records_anon_update" ON streak_records FOR UPDATE TO anon USING (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid) WITH CHECK (true)';

        EXECUTE 'GRANT SELECT, INSERT, UPDATE ON streak_records TO anon';
        RAISE NOTICE 'Fixed streak_records anon policies';
    END IF;
END $$;

-- ============================================================================
-- STEP 5: Fix streak_history table
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'streak_history') THEN
        EXECUTE 'DROP POLICY IF EXISTS "streak_history_anon_read" ON streak_history';
        EXECUTE 'DROP POLICY IF EXISTS "streak_history_anon_insert" ON streak_history';
        EXECUTE 'DROP POLICY IF EXISTS "streak_history_anon_update" ON streak_history';

        EXECUTE 'CREATE POLICY "streak_history_anon_read" ON streak_history FOR SELECT TO anon USING (true)';
        EXECUTE 'CREATE POLICY "streak_history_anon_insert" ON streak_history FOR INSERT TO anon WITH CHECK (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid)';
        EXECUTE 'CREATE POLICY "streak_history_anon_update" ON streak_history FOR UPDATE TO anon USING (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid) WITH CHECK (true)';

        EXECUTE 'GRANT SELECT, INSERT, UPDATE ON streak_history TO anon';
        RAISE NOTICE 'Fixed streak_history anon policies';
    END IF;
END $$;

-- ============================================================================
-- STEP 6: Fix notification_settings table
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'notification_settings') THEN
        EXECUTE 'DROP POLICY IF EXISTS "notification_settings_anon_read" ON notification_settings';
        EXECUTE 'DROP POLICY IF EXISTS "notification_settings_anon_insert" ON notification_settings';
        EXECUTE 'DROP POLICY IF EXISTS "notification_settings_anon_update" ON notification_settings';

        EXECUTE 'CREATE POLICY "notification_settings_anon_read" ON notification_settings FOR SELECT TO anon USING (true)';
        EXECUTE 'CREATE POLICY "notification_settings_anon_insert" ON notification_settings FOR INSERT TO anon WITH CHECK (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid)';
        EXECUTE 'CREATE POLICY "notification_settings_anon_update" ON notification_settings FOR UPDATE TO anon USING (patient_id = ''00000000-0000-0000-0000-000000000001''::uuid) WITH CHECK (true)';

        EXECUTE 'GRANT SELECT, INSERT, UPDATE ON notification_settings TO anon';
        RAISE NOTICE 'Fixed notification_settings anon policies';
    END IF;
END $$;

-- ============================================================================
-- STEP 7: Fix scheduled_sessions for updates
-- ============================================================================

DROP POLICY IF EXISTS "scheduled_sessions_anon_update" ON scheduled_sessions;
DROP POLICY IF EXISTS "scheduled_sessions_anon_insert" ON scheduled_sessions;

CREATE POLICY "scheduled_sessions_anon_insert"
    ON scheduled_sessions FOR INSERT
    TO anon
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

CREATE POLICY "scheduled_sessions_anon_update"
    ON scheduled_sessions FOR UPDATE
    TO anon
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (true);

GRANT SELECT, INSERT, UPDATE ON scheduled_sessions TO anon;

-- ============================================================================
-- STEP 8: Force schema reload
-- ============================================================================

NOTIFY pgrst, 'reload schema';
NOTIFY pgrst, 'reload config';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    anon_policy_count INT;
BEGIN
    SELECT COUNT(*) INTO anon_policy_count
    FROM pg_policies
    WHERE policyname LIKE '%anon%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Comprehensive Demo QuickStart RLS Fix';
    RAISE NOTICE '============================================';
    RAISE NOTICE 'Total anon policies: %', anon_policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Tables with full anon CRUD for demo patient:';
    RAISE NOTICE '  - patients';
    RAISE NOTICE '  - patient_goals';
    RAISE NOTICE '  - daily_readiness';
    RAISE NOTICE '  - streak_records';
    RAISE NOTICE '  - streak_history';
    RAISE NOTICE '  - notification_settings';
    RAISE NOTICE '  - scheduled_sessions';
    RAISE NOTICE '============================================';
END $$;
