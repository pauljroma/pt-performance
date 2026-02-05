-- ============================================================================
-- FIX RLS POLICY GAPS
-- ============================================================================
-- Purpose: Address RLS policy inconsistencies identified in audit
-- Date: 2026-02-03
-- ============================================================================

BEGIN;

-- ============================================================================
-- FIX 1: DAILY_READINESS - Ensure Consistent Therapist Access Pattern
-- ============================================================================

-- Drop potentially overly permissive therapist policies
DROP POLICY IF EXISTS "Therapists can view all readiness data" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can view assigned patients readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can insert for assigned patients" ON daily_readiness;
DROP POLICY IF EXISTS "Therapists can update assigned patients readiness" ON daily_readiness;

-- Recreate therapist SELECT policy with proper linkage check
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'daily_readiness'
        AND policyname = 'Therapists view linked patient readiness'
    ) THEN
        CREATE POLICY "Therapists view linked patient readiness"
            ON daily_readiness FOR SELECT
            TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM therapist_patients tp
                    WHERE tp.patient_id = daily_readiness.patient_id
                    AND tp.therapist_id = auth.uid()
                    AND tp.active = true
                )
            );
    END IF;
END $$;

-- ============================================================================
-- FIX 2: AI_COACH - Add Therapist Read Access (Optional)
-- ============================================================================

-- Add therapist read access to ai_coach_conversations if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'ai_coach_conversations' AND schemaname = 'public') THEN
        -- Drop if exists to recreate cleanly
        DROP POLICY IF EXISTS "Therapists view linked patient conversations" ON ai_coach_conversations;

        CREATE POLICY "Therapists view linked patient conversations"
            ON ai_coach_conversations FOR SELECT
            TO authenticated
            USING (
                EXISTS (
                    SELECT 1 FROM therapist_patients tp
                    WHERE tp.patient_id = ai_coach_conversations.patient_id
                    AND tp.therapist_id = auth.uid()
                    AND tp.active = true
                )
            );
    END IF;
END $$;

-- Add therapist read access to ai_coach_messages if table exists
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'ai_coach_messages' AND schemaname = 'public') THEN
        -- Drop if exists to recreate cleanly
        DROP POLICY IF EXISTS "Therapists view linked patient messages" ON ai_coach_messages;

        CREATE POLICY "Therapists view linked patient messages"
            ON ai_coach_messages FOR SELECT
            TO authenticated
            USING (
                conversation_id IN (
                    SELECT c.id FROM ai_coach_conversations c
                    JOIN therapist_patients tp ON tp.patient_id = c.patient_id
                    WHERE tp.therapist_id = auth.uid()
                    AND tp.active = true
                )
            );
    END IF;
END $$;

-- ============================================================================
-- FIX 3: SCHEDULED_SESSIONS - Fix Therapist Policy
-- ============================================================================

-- Drop policies that use auth.role() which may not work correctly
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'scheduled_sessions' AND schemaname = 'public') THEN
        DROP POLICY IF EXISTS "Therapists view all scheduled sessions" ON scheduled_sessions;
        DROP POLICY IF EXISTS "Therapists manage scheduled sessions" ON scheduled_sessions;

        -- Create proper therapist policy using therapist_patients linkage
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = 'scheduled_sessions'
            AND policyname = 'Therapists view linked patient sessions'
        ) THEN
            CREATE POLICY "Therapists view linked patient sessions"
                ON scheduled_sessions FOR SELECT
                TO authenticated
                USING (
                    EXISTS (
                        SELECT 1 FROM therapist_patients tp
                        WHERE tp.patient_id = scheduled_sessions.patient_id
                        AND tp.therapist_id = auth.uid()
                        AND tp.active = true
                    )
                );
        END IF;

        -- Allow therapists to manage linked patient sessions
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = 'scheduled_sessions'
            AND policyname = 'Therapists manage linked patient sessions'
        ) THEN
            CREATE POLICY "Therapists manage linked patient sessions"
                ON scheduled_sessions FOR ALL
                TO authenticated
                USING (
                    EXISTS (
                        SELECT 1 FROM therapist_patients tp
                        WHERE tp.patient_id = scheduled_sessions.patient_id
                        AND tp.therapist_id = auth.uid()
                        AND tp.active = true
                    )
                )
                WITH CHECK (
                    EXISTS (
                        SELECT 1 FROM therapist_patients tp
                        WHERE tp.patient_id = scheduled_sessions.patient_id
                        AND tp.therapist_id = auth.uid()
                        AND tp.active = true
                    )
                );
        END IF;
    END IF;
END $$;

-- ============================================================================
-- FIX 4: Ensure biomarker_values DELETE requires lab_results ownership
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'biomarker_values' AND schemaname = 'public') THEN
        -- Verify DELETE policy exists and is correct
        IF NOT EXISTS (
            SELECT 1 FROM pg_policies
            WHERE tablename = 'biomarker_values'
            AND cmd = 'DELETE'
            AND policyname = 'Patients delete own biomarker values'
        ) THEN
            CREATE POLICY "Patients delete own biomarker values"
                ON biomarker_values FOR DELETE
                TO authenticated
                USING (
                    EXISTS (
                        SELECT 1 FROM lab_results lr
                        WHERE lr.id = biomarker_values.lab_result_id
                        AND lr.patient_id = auth.uid()
                    )
                );
        END IF;
    END IF;
END $$;

-- ============================================================================
-- FIX 5: Ensure ai_coach_messages has no DELETE policy (messages should be immutable)
-- ============================================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'ai_coach_messages' AND schemaname = 'public') THEN
        -- Drop any DELETE policies on ai_coach_messages
        DROP POLICY IF EXISTS "Users can delete messages in own conversations" ON ai_coach_messages;
        DROP POLICY IF EXISTS "Patients delete own ai_coach_messages" ON ai_coach_messages;

        -- Messages should be immutable - no DELETE allowed except for service role
    END IF;
END $$;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE tablename IN (
        'lab_results', 'biomarker_values', 'recovery_sessions',
        'fasting_logs', 'supplement_logs', 'patient_supplement_stacks',
        'ai_coach_conversations', 'ai_coach_messages', 'daily_readiness',
        'scheduled_sessions'
    );

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'RLS POLICY GAP FIXES APPLIED';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Total RLS policies on sensitive tables: %', v_policy_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Changes made:';
    RAISE NOTICE '  1. Fixed daily_readiness therapist access to use linkage check';
    RAISE NOTICE '  2. Added therapist read access to AI coach conversations/messages';
    RAISE NOTICE '  3. Fixed scheduled_sessions therapist policies';
    RAISE NOTICE '  4. Ensured biomarker_values DELETE requires ownership';
    RAISE NOTICE '  5. Removed DELETE policy from ai_coach_messages (immutable)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Run tests to verify:';
    RAISE NOTICE '  psql $DATABASE_URL -f scripts/test_rls_policies.sql';
    RAISE NOTICE '  supabase test db';
    RAISE NOTICE '';
END $$;

COMMIT;
