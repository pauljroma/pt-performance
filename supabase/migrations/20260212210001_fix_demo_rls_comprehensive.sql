-- Migration: Fix RLS policy gaps for demo patient
-- Demo Patient ID: 00000000-0000-0000-0000-000000000001
-- This migration ensures all relevant tables have proper RLS policies for anonymous demo access

-- ============================================================================
-- GRANTS: Ensure anon role has necessary permissions
-- ============================================================================

GRANT SELECT, INSERT, UPDATE ON ai_chat_sessions TO anon;
GRANT SELECT, INSERT, UPDATE ON ai_chat_messages TO anon;
GRANT SELECT, INSERT, UPDATE ON manual_sessions TO anon;
GRANT SELECT, INSERT, UPDATE ON scheduled_sessions TO anon;
GRANT SELECT, INSERT, UPDATE ON patient_goals TO anon;
GRANT SELECT, INSERT, UPDATE ON patient_supplement_stacks TO anon;
GRANT SELECT, INSERT, UPDATE ON biomarker_values TO anon;

-- ============================================================================
-- TABLE: ai_chat_sessions
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'ai_chat_sessions'
        AND policyname = 'demo_patient_ai_chat_sessions_select'
    ) THEN
        CREATE POLICY "demo_patient_ai_chat_sessions_select" ON ai_chat_sessions
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'ai_chat_sessions'
        AND policyname = 'demo_patient_ai_chat_sessions_insert'
    ) THEN
        CREATE POLICY "demo_patient_ai_chat_sessions_insert" ON ai_chat_sessions
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'ai_chat_sessions'
        AND policyname = 'demo_patient_ai_chat_sessions_update'
    ) THEN
        CREATE POLICY "demo_patient_ai_chat_sessions_update" ON ai_chat_sessions
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- ============================================================================
-- TABLE: ai_chat_messages
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'ai_chat_messages'
        AND policyname = 'demo_patient_ai_chat_messages_select'
    ) THEN
        CREATE POLICY "demo_patient_ai_chat_messages_select" ON ai_chat_messages
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'ai_chat_messages'
        AND policyname = 'demo_patient_ai_chat_messages_insert'
    ) THEN
        CREATE POLICY "demo_patient_ai_chat_messages_insert" ON ai_chat_messages
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'ai_chat_messages'
        AND policyname = 'demo_patient_ai_chat_messages_update'
    ) THEN
        CREATE POLICY "demo_patient_ai_chat_messages_update" ON ai_chat_messages
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- ============================================================================
-- TABLE: manual_sessions (verify existing)
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'manual_sessions'
        AND policyname = 'demo_patient_manual_sessions_select'
    ) THEN
        CREATE POLICY "demo_patient_manual_sessions_select" ON manual_sessions
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'manual_sessions'
        AND policyname = 'demo_patient_manual_sessions_insert'
    ) THEN
        CREATE POLICY "demo_patient_manual_sessions_insert" ON manual_sessions
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'manual_sessions'
        AND policyname = 'demo_patient_manual_sessions_update'
    ) THEN
        CREATE POLICY "demo_patient_manual_sessions_update" ON manual_sessions
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- ============================================================================
-- TABLE: scheduled_sessions
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'scheduled_sessions'
        AND policyname = 'demo_patient_scheduled_sessions_select'
    ) THEN
        CREATE POLICY "demo_patient_scheduled_sessions_select" ON scheduled_sessions
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'scheduled_sessions'
        AND policyname = 'demo_patient_scheduled_sessions_insert'
    ) THEN
        CREATE POLICY "demo_patient_scheduled_sessions_insert" ON scheduled_sessions
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'scheduled_sessions'
        AND policyname = 'demo_patient_scheduled_sessions_update'
    ) THEN
        CREATE POLICY "demo_patient_scheduled_sessions_update" ON scheduled_sessions
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- ============================================================================
-- TABLE: patient_goals
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patient_goals'
        AND policyname = 'demo_patient_patient_goals_select'
    ) THEN
        CREATE POLICY "demo_patient_patient_goals_select" ON patient_goals
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patient_goals'
        AND policyname = 'demo_patient_patient_goals_insert'
    ) THEN
        CREATE POLICY "demo_patient_patient_goals_insert" ON patient_goals
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patient_goals'
        AND policyname = 'demo_patient_patient_goals_update'
    ) THEN
        CREATE POLICY "demo_patient_patient_goals_update" ON patient_goals
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- ============================================================================
-- TABLE: patient_supplement_stacks (verify existing)
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patient_supplement_stacks'
        AND policyname = 'demo_patient_patient_supplement_stacks_select'
    ) THEN
        CREATE POLICY "demo_patient_patient_supplement_stacks_select" ON patient_supplement_stacks
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patient_supplement_stacks'
        AND policyname = 'demo_patient_patient_supplement_stacks_insert'
    ) THEN
        CREATE POLICY "demo_patient_patient_supplement_stacks_insert" ON patient_supplement_stacks
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'patient_supplement_stacks'
        AND policyname = 'demo_patient_patient_supplement_stacks_update'
    ) THEN
        CREATE POLICY "demo_patient_patient_supplement_stacks_update" ON patient_supplement_stacks
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- ============================================================================
-- TABLE: biomarker_values (verify existing)
-- ============================================================================

-- SELECT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'biomarker_values'
        AND policyname = 'demo_patient_biomarker_values_select'
    ) THEN
        CREATE POLICY "demo_patient_biomarker_values_select" ON biomarker_values
            FOR SELECT TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- INSERT policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'biomarker_values'
        AND policyname = 'demo_patient_biomarker_values_insert'
    ) THEN
        CREATE POLICY "demo_patient_biomarker_values_insert" ON biomarker_values
            FOR INSERT TO anon
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;

-- UPDATE policy
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'biomarker_values'
        AND policyname = 'demo_patient_biomarker_values_update'
    ) THEN
        CREATE POLICY "demo_patient_biomarker_values_update" ON biomarker_values
            FOR UPDATE TO anon
            USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
            WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);
    END IF;
END $$;
