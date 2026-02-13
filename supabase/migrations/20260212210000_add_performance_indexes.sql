-- ============================================================================
-- PERFORMANCE INDEXES MIGRATION
-- ============================================================================
-- Adds indexes identified from query pattern analysis
-- ============================================================================

-- AI Chat queries
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_session_created
ON ai_chat_messages(session_id, created_at DESC);

-- Manual sessions filtered queries
CREATE INDEX IF NOT EXISTS idx_manual_sessions_patient_completed
ON manual_sessions(patient_id, completed, completed_at DESC);

-- Lab results sorted queries
CREATE INDEX IF NOT EXISTS idx_lab_results_patient_date
ON lab_results(patient_id, test_date DESC);

-- Fasting logs queries
CREATE INDEX IF NOT EXISTS idx_fasting_logs_patient_ended
ON fasting_logs(patient_id, ended_at, started_at DESC);

-- Patient supplement stacks
CREATE INDEX IF NOT EXISTS idx_patient_supplement_stacks_patient_active
ON patient_supplement_stacks(patient_id, is_active);

-- Patient goals
CREATE INDEX IF NOT EXISTS idx_patient_goals_patient_status
ON patient_goals(patient_id, status);

-- Workload flags (only if table and column exist)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'workload_flags' AND column_name = 'calculated_at'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_workload_flags_patient_calculated
        ON workload_flags(patient_id, calculated_at DESC);
    END IF;
END $$;

-- Fatigue accumulation (only if table and column exist)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'fatigue_accumulation' AND column_name = 'calculated_at'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_fatigue_accumulation_patient_calculated
        ON fatigue_accumulation(patient_id, calculated_at DESC);
    END IF;
END $$;

-- Progression suggestions (only if table exists)
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'progression_suggestions'
    ) THEN
        CREATE INDEX IF NOT EXISTS idx_progression_suggestions_patient_status
        ON progression_suggestions(patient_id, status);
    END IF;
END $$;

-- Load progression history (composite for AI progressive overload)
CREATE INDEX IF NOT EXISTS idx_load_progression_patient_exercise_logged
ON load_progression_history(patient_id, exercise_template_id, logged_at DESC);

-- Verification
DO $$
BEGIN
    RAISE NOTICE 'Performance indexes created successfully';
END $$;
