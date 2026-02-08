-- Migration: Create Load Progression History Table
-- Sprint: Auto-Regulation System
-- Created: 2026-02-08
-- Description: Tracks exercise load progression decisions based on RPE feedback

-- ============================================================================
-- TABLE: load_progression_history
-- ============================================================================
-- Stores progression decisions for exercises based on RPE feedback and auto-regulation

CREATE TABLE IF NOT EXISTS load_progression_history (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    exercise_template_id UUID REFERENCES exercise_templates(id) ON DELETE SET NULL,
    session_id UUID REFERENCES manual_sessions(id) ON DELETE SET NULL,

    -- Load tracking
    current_load NUMERIC(8,2) NOT NULL,
    load_unit TEXT NOT NULL DEFAULT 'lbs',
    next_load NUMERIC(8,2),

    -- RPE feedback
    target_rpe_low NUMERIC(3,1),
    target_rpe_high NUMERIC(3,1),
    actual_rpe NUMERIC(3,1) NOT NULL,

    -- Progression decision
    progression_action TEXT NOT NULL CHECK (progression_action IN ('increase', 'hold', 'decrease', 'deload')),
    reason TEXT,

    -- Performance metadata
    sets_completed INTEGER,
    reps_completed INTEGER,
    form_quality INTEGER CHECK (form_quality >= 1 AND form_quality <= 5),

    -- Timestamps
    logged_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table comment
COMMENT ON TABLE load_progression_history IS 'Tracks load progression decisions based on RPE auto-regulation';

-- Column comments
COMMENT ON COLUMN load_progression_history.current_load IS 'Load used for this set in specified unit';
COMMENT ON COLUMN load_progression_history.next_load IS 'Recommended load for next session';
COMMENT ON COLUMN load_progression_history.actual_rpe IS 'RPE reported by patient (1-10 scale)';
COMMENT ON COLUMN load_progression_history.progression_action IS 'Progression decision: increase, hold, decrease, or deload';
COMMENT ON COLUMN load_progression_history.form_quality IS 'Form quality rating 1-5 (5 is perfect)';

-- ============================================================================
-- TABLE: deload_triggers
-- ============================================================================
-- Tracks individual events that can trigger a deload period

CREATE TABLE IF NOT EXISTS deload_triggers (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign key
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,

    -- Trigger details
    trigger_type TEXT NOT NULL CHECK (trigger_type IN (
        'missed_reps_primary',
        'rpe_overshoot',
        'joint_pain',
        'readiness_low'
    )),
    occurred_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    severity INTEGER NOT NULL DEFAULT 1 CHECK (severity >= 1 AND severity <= 3),
    details JSONB,

    -- Resolution status
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    resolved_at TIMESTAMPTZ,
    resolved_by TEXT, -- 'deload' or 'manual'

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table comment
COMMENT ON TABLE deload_triggers IS 'Tracks events that can trigger a deload period';

-- Column comments
COMMENT ON COLUMN deload_triggers.trigger_type IS 'Type of trigger: missed_reps_primary, rpe_overshoot, joint_pain, readiness_low';
COMMENT ON COLUMN deload_triggers.severity IS 'Severity 1-3 (1=minor, 3=severe)';
COMMENT ON COLUMN deload_triggers.resolved IS 'Whether this trigger has been addressed';

-- ============================================================================
-- TABLE: deload_history
-- ============================================================================
-- Tracks scheduled and completed deload periods

CREATE TABLE IF NOT EXISTS deload_history (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    program_id UUID REFERENCES training_programs(id) ON DELETE SET NULL,
    phase_id UUID REFERENCES training_phases(id) ON DELETE SET NULL,

    -- Trigger information
    trigger_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    triggers_met TEXT[] NOT NULL DEFAULT '{}',
    trigger_window_start TIMESTAMPTZ,
    trigger_window_end TIMESTAMPTZ,

    -- Deload prescription
    load_reduction_pct NUMERIC(5,2) NOT NULL DEFAULT 12.0,
    volume_reduction_pct NUMERIC(5,2) NOT NULL DEFAULT 35.0,
    duration_days INTEGER NOT NULL DEFAULT 7,

    -- Status
    status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'active', 'completed', 'cancelled')),
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,

    -- Outcome
    recovery_notes TEXT,
    effectiveness_rating INTEGER CHECK (effectiveness_rating >= 1 AND effectiveness_rating <= 5),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Table comment
COMMENT ON TABLE deload_history IS 'Tracks scheduled and completed deload periods';

-- ============================================================================
-- INDEXES
-- ============================================================================

-- load_progression_history indexes
CREATE INDEX IF NOT EXISTS idx_load_progression_history_patient_id
    ON load_progression_history(patient_id);

CREATE INDEX IF NOT EXISTS idx_load_progression_history_exercise
    ON load_progression_history(patient_id, exercise_template_id);

CREATE INDEX IF NOT EXISTS idx_load_progression_history_logged_at
    ON load_progression_history(logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_load_progression_history_patient_exercise_date
    ON load_progression_history(patient_id, exercise_template_id, logged_at DESC);

-- deload_triggers indexes
CREATE INDEX IF NOT EXISTS idx_deload_triggers_patient_id
    ON deload_triggers(patient_id);

CREATE INDEX IF NOT EXISTS idx_deload_triggers_unresolved
    ON deload_triggers(patient_id, occurred_at)
    WHERE resolved = FALSE;

CREATE INDEX IF NOT EXISTS idx_deload_triggers_type
    ON deload_triggers(trigger_type);

-- deload_history indexes
CREATE INDEX IF NOT EXISTS idx_deload_history_patient_id
    ON deload_history(patient_id);

CREATE INDEX IF NOT EXISTS idx_deload_history_status
    ON deload_history(patient_id, status)
    WHERE status IN ('scheduled', 'active');

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE load_progression_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE deload_triggers ENABLE ROW LEVEL SECURITY;
ALTER TABLE deload_history ENABLE ROW LEVEL SECURITY;

-- load_progression_history policies
CREATE POLICY load_progression_history_select_own ON load_progression_history
    FOR SELECT TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY load_progression_history_insert_own ON load_progression_history
    FOR INSERT TO authenticated
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY load_progression_history_service ON load_progression_history
    FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

-- deload_triggers policies
CREATE POLICY deload_triggers_select_own ON deload_triggers
    FOR SELECT TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY deload_triggers_insert_own ON deload_triggers
    FOR INSERT TO authenticated
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY deload_triggers_update_own ON deload_triggers
    FOR UPDATE TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY deload_triggers_service ON deload_triggers
    FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

-- deload_history policies
CREATE POLICY deload_history_select_own ON deload_history
    FOR SELECT TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY deload_history_insert_own ON deload_history
    FOR INSERT TO authenticated
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY deload_history_update_own ON deload_history
    FOR UPDATE TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY deload_history_service ON deload_history
    FOR ALL TO service_role
    USING (TRUE) WITH CHECK (TRUE);

-- ============================================================================
-- TRIGGERS
-- ============================================================================

CREATE TRIGGER update_deload_history_updated_at
    BEFORE UPDATE ON deload_history
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_table_count INTEGER;
    v_index_count INTEGER;
    v_policy_count INTEGER;
BEGIN
    -- Verify tables exist
    SELECT COUNT(*) INTO v_table_count
    FROM information_schema.tables
    WHERE table_schema = 'public'
      AND table_name IN ('load_progression_history', 'deload_triggers', 'deload_history');

    IF v_table_count != 3 THEN
        RAISE EXCEPTION 'Expected 3 tables, found %', v_table_count;
    END IF;

    -- Verify indexes
    SELECT COUNT(*) INTO v_index_count
    FROM pg_indexes
    WHERE schemaname = 'public'
      AND (indexname LIKE 'idx_load_progression%'
           OR indexname LIKE 'idx_deload_triggers%'
           OR indexname LIKE 'idx_deload_history%');

    IF v_index_count < 8 THEN
        RAISE EXCEPTION 'Expected at least 8 indexes, found %', v_index_count;
    END IF;

    -- Verify RLS policies
    SELECT COUNT(*) INTO v_policy_count
    FROM pg_policies
    WHERE schemaname = 'public'
      AND tablename IN ('load_progression_history', 'deload_triggers', 'deload_history');

    IF v_policy_count < 10 THEN
        RAISE EXCEPTION 'Expected at least 10 RLS policies, found %', v_policy_count;
    END IF;

    RAISE NOTICE '✓ Migration 20260208170000_create_load_progression_history.sql completed successfully';
    RAISE NOTICE '  - Tables: %', v_table_count;
    RAISE NOTICE '  - Indexes: %', v_index_count;
    RAISE NOTICE '  - RLS Policies: %', v_policy_count;
END $$;
