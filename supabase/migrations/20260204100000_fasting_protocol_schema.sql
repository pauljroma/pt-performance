-- ============================================================================
-- CREATE FASTING PROTOCOL TRACKING SYSTEM
-- ============================================================================
-- Comprehensive fasting tracking with protocols, logs, goals, and streaks
-- Supports various fasting methods: 16:8, 18:6, 20:4, OMAD, 5:2, etc.
--
-- Date: 2026-02-04
-- Linear: ACP-427
-- ============================================================================

BEGIN;

-- ============================================================================
-- TABLE 1: FASTING PROTOCOLS (Template protocols)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL,

    -- Fasting window configuration
    fasting_hours INTEGER NOT NULL CHECK (fasting_hours >= 0 AND fasting_hours <= 168),
    eating_window_hours INTEGER NOT NULL CHECK (eating_window_hours >= 0 AND eating_window_hours <= 24),

    -- Weekly pattern for complex protocols (e.g., 5:2 where 2 days are low cal)
    -- Example: {"fast_days": [1, 4], "normal_days": [0, 2, 3, 5, 6]}
    -- or {"daily": true} for daily intermittent fasting
    weekly_pattern JSONB DEFAULT '{"daily": true}'::jsonb,

    -- Caloric restrictions for certain protocols
    min_calories_fast_day INTEGER CHECK (min_calories_fast_day IS NULL OR min_calories_fast_day >= 0),

    -- Difficulty and guidance
    difficulty_level TEXT NOT NULL CHECK (difficulty_level IN ('beginner', 'intermediate', 'advanced', 'expert')),

    -- Benefits array: e.g., ["weight loss", "insulin sensitivity", "autophagy"]
    benefits JSONB DEFAULT '[]'::jsonb,

    -- Precautions array: e.g., ["not for diabetics", "consult doctor if pregnant"]
    precautions JSONB DEFAULT '[]'::jsonb,

    -- Protocol metadata
    is_active BOOLEAN NOT NULL DEFAULT true,
    sort_order INTEGER DEFAULT 0,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add all potentially missing columns if table already exists from previous migration
DO $$
BEGIN
    -- Add weekly_pattern if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'weekly_pattern') THEN
        ALTER TABLE fasting_protocols ADD COLUMN weekly_pattern JSONB DEFAULT '{"daily": true}'::jsonb;
    END IF;
    -- Add min_calories_fast_day if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'min_calories_fast_day') THEN
        ALTER TABLE fasting_protocols ADD COLUMN min_calories_fast_day INTEGER CHECK (min_calories_fast_day IS NULL OR min_calories_fast_day >= 0);
    END IF;
    -- Add difficulty_level if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'difficulty_level') THEN
        ALTER TABLE fasting_protocols ADD COLUMN difficulty_level TEXT DEFAULT 'intermediate';
    END IF;
    -- Add benefits if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'benefits') THEN
        ALTER TABLE fasting_protocols ADD COLUMN benefits JSONB DEFAULT '[]'::jsonb;
    END IF;
    -- Add precautions if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'precautions') THEN
        ALTER TABLE fasting_protocols ADD COLUMN precautions JSONB DEFAULT '[]'::jsonb;
    END IF;
    -- Add is_active if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'is_active') THEN
        ALTER TABLE fasting_protocols ADD COLUMN is_active BOOLEAN NOT NULL DEFAULT true;
    END IF;
    -- Add sort_order if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'fasting_protocols' AND column_name = 'sort_order') THEN
        ALTER TABLE fasting_protocols ADD COLUMN sort_order INTEGER DEFAULT 0;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_fasting_protocols_active ON fasting_protocols(is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_fasting_protocols_difficulty ON fasting_protocols(difficulty_level);
CREATE INDEX IF NOT EXISTS idx_fasting_protocols_sort ON fasting_protocols(sort_order, name);

COMMENT ON TABLE fasting_protocols IS 'Template fasting protocols that users can follow (16:8, 5:2, OMAD, etc.)';
-- Comments only apply to columns that exist - wrapped in DO block for safety
DO $$
BEGIN
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.fasting_hours IS ''Target fasting duration in hours per fasting period''';
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.eating_window_hours IS ''Daily eating window in hours (24 - fasting_hours for daily protocols)''';
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.weekly_pattern IS ''JSON pattern for weekly scheduling - daily protocols or specific fast days''';
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.min_calories_fast_day IS ''Minimum calories allowed on fasting days (for modified fasts like 5:2)''';
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.difficulty_level IS ''Protocol difficulty: beginner, intermediate, advanced, expert''';
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.benefits IS ''JSON array of expected benefits from this protocol''';
    EXECUTE 'COMMENT ON COLUMN fasting_protocols.precautions IS ''JSON array of precautions and contraindications''';
EXCEPTION WHEN undefined_column THEN
    -- Ignore if columns don't exist
    NULL;
END $$;

-- ============================================================================
-- TABLE 2: FASTING LOGS (User fasting sessions)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    protocol_id UUID REFERENCES fasting_protocols(id) ON DELETE SET NULL,

    -- Fasting type (allows custom fasting even without a protocol)
    fasting_type TEXT NOT NULL CHECK (fasting_type IN (
        'intermittent', 'extended', 'water_only', 'modified', 'custom'
    )),

    -- Target and timing
    target_hours NUMERIC(5,2) NOT NULL CHECK (target_hours > 0 AND target_hours <= 168),
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    planned_end_at TIMESTAMPTZ NOT NULL,
    actual_hours NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN ended_at IS NOT NULL
            THEN EXTRACT(EPOCH FROM (ended_at - started_at)) / 3600
            ELSE NULL
        END
    ) STORED,

    -- Wellness tracking (1-10 scale)
    mood_start INTEGER CHECK (mood_start IS NULL OR (mood_start >= 1 AND mood_start <= 10)),
    mood_end INTEGER CHECK (mood_end IS NULL OR (mood_end >= 1 AND mood_end <= 10)),
    energy_level INTEGER CHECK (energy_level IS NULL OR (energy_level >= 1 AND energy_level <= 10)),
    hunger_level INTEGER CHECK (hunger_level IS NULL OR (hunger_level >= 1 AND hunger_level <= 10)),

    -- Status tracking
    was_broken_early BOOLEAN DEFAULT FALSE,
    break_reason TEXT,

    -- Notes
    notes TEXT,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_end_time CHECK (ended_at IS NULL OR ended_at >= started_at),
    CONSTRAINT valid_planned_end CHECK (planned_end_at >= started_at),
    CONSTRAINT break_reason_required CHECK (
        (was_broken_early = TRUE AND break_reason IS NOT NULL) OR
        (was_broken_early = FALSE)
    )
);

-- Create indexes safely (ignore if columns don't exist)
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_fasting_logs_patient ON fasting_logs(patient_id);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_fasting_logs_patient_date ON fasting_logs(patient_id, started_at DESC);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_fasting_logs_protocol ON fasting_logs(protocol_id) WHERE protocol_id IS NOT NULL;
EXCEPTION WHEN undefined_column THEN NULL;
END $$;
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_fasting_logs_active ON fasting_logs(patient_id, ended_at) WHERE ended_at IS NULL;
EXCEPTION WHEN undefined_column THEN NULL;
END $$;
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_fasting_logs_started ON fasting_logs(started_at DESC);
EXCEPTION WHEN undefined_column THEN NULL;
END $$;
DO $$
BEGIN
    CREATE INDEX IF NOT EXISTS idx_fasting_logs_completed ON fasting_logs(patient_id, ended_at DESC) WHERE ended_at IS NOT NULL;
EXCEPTION WHEN undefined_column THEN NULL;
END $$;

COMMENT ON TABLE fasting_logs IS 'Individual fasting session records for patients';
-- Comments wrapped in DO block for safety (columns may not exist in older tables)
DO $$
BEGIN
    COMMENT ON TABLE fasting_logs IS 'Individual fasting session logs tracking user fasting activity';
EXCEPTION WHEN undefined_column OR undefined_table THEN NULL;
END $$;

-- ============================================================================
-- TABLE 3: FASTING GOALS (User fasting targets)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    protocol_id UUID REFERENCES fasting_protocols(id) ON DELETE SET NULL,

    -- Goal targets
    target_fasts_per_week INTEGER NOT NULL CHECK (target_fasts_per_week >= 1 AND target_fasts_per_week <= 7),
    target_hours_per_fast NUMERIC(5,2) NOT NULL CHECK (target_hours_per_fast > 0 AND target_hours_per_fast <= 168),

    -- Goal period
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,

    -- Status
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_goal_period CHECK (end_date IS NULL OR end_date >= start_date)
);

-- Partial unique index for one active goal per patient (can't be inline constraint)
CREATE UNIQUE INDEX IF NOT EXISTS idx_fasting_goals_unique_active ON fasting_goals(patient_id) WHERE is_active = TRUE;

DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_fasting_goals_patient ON fasting_goals(patient_id); EXCEPTION WHEN duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_fasting_goals_active ON fasting_goals(patient_id, is_active) WHERE is_active = TRUE; EXCEPTION WHEN duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_fasting_goals_protocol ON fasting_goals(protocol_id) WHERE protocol_id IS NOT NULL; EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_fasting_goals_dates ON fasting_goals(start_date, end_date); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

COMMENT ON TABLE fasting_goals IS 'User-defined fasting goals and targets';

-- ============================================================================
-- TABLE 4: FASTING STREAKS (Track consistency)
-- ============================================================================

CREATE TABLE IF NOT EXISTS fasting_streaks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL UNIQUE REFERENCES patients(id) ON DELETE CASCADE,

    -- Streak tracking
    current_streak INTEGER NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),

    -- Streak dates
    last_fast_date DATE,
    streak_start_date DATE,

    -- Totals
    total_fasts_completed INTEGER NOT NULL DEFAULT 0 CHECK (total_fasts_completed >= 0),
    total_hours_fasted NUMERIC(10,2) NOT NULL DEFAULT 0 CHECK (total_hours_fasted >= 0),

    -- Timestamps
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    -- Constraints
    CONSTRAINT valid_longest_streak CHECK (longest_streak >= current_streak),
    CONSTRAINT valid_streak_dates CHECK (
        (current_streak = 0 AND streak_start_date IS NULL) OR
        (current_streak > 0 AND streak_start_date IS NOT NULL)
    )
);

CREATE INDEX idx_fasting_streaks_patient ON fasting_streaks(patient_id);
CREATE INDEX idx_fasting_streaks_current ON fasting_streaks(current_streak DESC);
CREATE INDEX idx_fasting_streaks_longest ON fasting_streaks(longest_streak DESC);
CREATE INDEX idx_fasting_streaks_last_fast ON fasting_streaks(last_fast_date DESC);

COMMENT ON TABLE fasting_streaks IS 'Track fasting consistency and achievements for each patient';
COMMENT ON COLUMN fasting_streaks.patient_id IS 'Patient this streak record belongs to';
COMMENT ON COLUMN fasting_streaks.current_streak IS 'Current consecutive successful fasts';
COMMENT ON COLUMN fasting_streaks.longest_streak IS 'Longest ever consecutive successful fasts';
COMMENT ON COLUMN fasting_streaks.last_fast_date IS 'Date of most recent completed fast';
COMMENT ON COLUMN fasting_streaks.streak_start_date IS 'Date when current streak began';
COMMENT ON COLUMN fasting_streaks.total_fasts_completed IS 'Total number of fasts completed all-time';
COMMENT ON COLUMN fasting_streaks.total_hours_fasted IS 'Total hours spent fasting all-time';

-- ============================================================================
-- TRIGGERS: Auto-update timestamps
-- ============================================================================

CREATE OR REPLACE FUNCTION update_fasting_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_fasting_protocols_timestamp ON fasting_protocols;
CREATE TRIGGER update_fasting_protocols_timestamp
    BEFORE UPDATE ON fasting_protocols
    FOR EACH ROW
    EXECUTE FUNCTION update_fasting_timestamp();

DROP TRIGGER IF EXISTS update_fasting_logs_timestamp ON fasting_logs;
CREATE TRIGGER update_fasting_logs_timestamp
    BEFORE UPDATE ON fasting_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_fasting_timestamp();

DROP TRIGGER IF EXISTS update_fasting_goals_timestamp ON fasting_goals;
CREATE TRIGGER update_fasting_goals_timestamp
    BEFORE UPDATE ON fasting_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_fasting_timestamp();

DROP TRIGGER IF EXISTS update_fasting_streaks_timestamp ON fasting_streaks;
CREATE TRIGGER update_fasting_streaks_timestamp
    BEFORE UPDATE ON fasting_streaks
    FOR EACH ROW
    EXECUTE FUNCTION update_fasting_timestamp();

-- ============================================================================
-- FUNCTION: Update streak on fast completion
-- ============================================================================

CREATE OR REPLACE FUNCTION update_fasting_streak()
RETURNS TRIGGER AS $$
DECLARE
    v_streak_record fasting_streaks%ROWTYPE;
    v_fast_date DATE;
    v_days_since_last INTEGER;
BEGIN
    -- Only process when a fast is completed (ended_at changes from NULL to NOT NULL)
    IF OLD.ended_at IS NULL AND NEW.ended_at IS NOT NULL AND NEW.was_broken_early = FALSE THEN
        v_fast_date := DATE(NEW.ended_at);

        -- Get or create streak record
        SELECT * INTO v_streak_record
        FROM fasting_streaks
        WHERE patient_id = NEW.patient_id;

        IF NOT FOUND THEN
            -- Create new streak record
            INSERT INTO fasting_streaks (
                patient_id,
                current_streak,
                longest_streak,
                last_fast_date,
                streak_start_date,
                total_fasts_completed,
                total_hours_fasted
            ) VALUES (
                NEW.patient_id,
                1,
                1,
                v_fast_date,
                v_fast_date,
                1,
                COALESCE(NEW.actual_hours, 0)
            );
        ELSE
            -- Calculate days since last fast
            IF v_streak_record.last_fast_date IS NOT NULL THEN
                v_days_since_last := v_fast_date - v_streak_record.last_fast_date;
            ELSE
                v_days_since_last := 999; -- Force streak reset if no previous fast
            END IF;

            -- Update streak record
            UPDATE fasting_streaks
            SET
                current_streak = CASE
                    WHEN v_days_since_last <= 2 THEN current_streak + 1  -- Allow 1 day gap
                    ELSE 1  -- Reset streak
                END,
                longest_streak = CASE
                    WHEN v_days_since_last <= 2 AND current_streak + 1 > longest_streak
                    THEN current_streak + 1
                    WHEN v_days_since_last > 2 AND 1 > longest_streak THEN 1
                    ELSE longest_streak
                END,
                last_fast_date = v_fast_date,
                streak_start_date = CASE
                    WHEN v_days_since_last <= 2 THEN streak_start_date  -- Keep current streak start
                    ELSE v_fast_date  -- New streak starts today
                END,
                total_fasts_completed = total_fasts_completed + 1,
                total_hours_fasted = total_hours_fasted + COALESCE(NEW.actual_hours, 0),
                updated_at = NOW()
            WHERE patient_id = NEW.patient_id;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS update_streak_on_fast_completion ON fasting_logs;
CREATE TRIGGER update_streak_on_fast_completion
    AFTER UPDATE ON fasting_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_fasting_streak();

COMMENT ON FUNCTION update_fasting_streak IS 'Automatically update fasting streak when a fast is completed';

-- ============================================================================
-- FUNCTION: Get fasting statistics
-- ============================================================================

CREATE OR REPLACE FUNCTION get_fasting_statistics(
    p_patient_id UUID,
    p_days INTEGER DEFAULT 30
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_result JSON;
BEGIN
    SELECT json_build_object(
        'patient_id', p_patient_id,
        'days_analyzed', p_days,
        'period', json_build_object(
            'start_date', CURRENT_DATE - p_days,
            'end_date', CURRENT_DATE
        ),
        'summary', (
            SELECT json_build_object(
                'total_fasts', COUNT(*),
                'completed_fasts', COUNT(*) FILTER (WHERE ended_at IS NOT NULL AND NOT was_broken_early),
                'broken_fasts', COUNT(*) FILTER (WHERE was_broken_early),
                'in_progress', COUNT(*) FILTER (WHERE ended_at IS NULL),
                'total_hours', ROUND(COALESCE(SUM(actual_hours), 0)::numeric, 1),
                'avg_hours', ROUND(COALESCE(AVG(actual_hours), 0)::numeric, 1),
                'completion_rate', ROUND(
                    (COUNT(*) FILTER (WHERE ended_at IS NOT NULL AND NOT was_broken_early)::numeric /
                    NULLIF(COUNT(*) FILTER (WHERE ended_at IS NOT NULL), 0)) * 100, 1
                )
            )
            FROM fasting_logs
            WHERE patient_id = p_patient_id
            AND started_at >= CURRENT_DATE - p_days
        ),
        'streak', (
            SELECT json_build_object(
                'current_streak', current_streak,
                'longest_streak', longest_streak,
                'total_fasts_all_time', total_fasts_completed,
                'total_hours_all_time', ROUND(total_hours_fasted::numeric, 1)
            )
            FROM fasting_streaks
            WHERE patient_id = p_patient_id
        ),
        'recent_fasts', (
            SELECT json_agg(
                json_build_object(
                    'id', id,
                    'protocol_id', protocol_id,
                    'fasting_type', fasting_type,
                    'target_hours', target_hours,
                    'actual_hours', actual_hours,
                    'started_at', started_at,
                    'ended_at', ended_at,
                    'was_broken_early', was_broken_early,
                    'mood_change', CASE
                        WHEN mood_start IS NOT NULL AND mood_end IS NOT NULL
                        THEN mood_end - mood_start
                        ELSE NULL
                    END
                ) ORDER BY started_at DESC
            )
            FROM (
                SELECT * FROM fasting_logs
                WHERE patient_id = p_patient_id
                AND started_at >= CURRENT_DATE - p_days
                ORDER BY started_at DESC
                LIMIT 10
            ) recent
        ),
        'by_protocol', (
            SELECT json_agg(
                json_build_object(
                    'protocol_id', protocol_id,
                    'protocol_name', fp.name,
                    'count', count,
                    'avg_hours', avg_hours,
                    'completion_rate', completion_rate
                )
            )
            FROM (
                SELECT
                    fl.protocol_id,
                    COUNT(*) as count,
                    ROUND(AVG(actual_hours)::numeric, 1) as avg_hours,
                    ROUND(
                        (COUNT(*) FILTER (WHERE NOT was_broken_early)::numeric /
                        NULLIF(COUNT(*), 0)) * 100, 1
                    ) as completion_rate
                FROM fasting_logs fl
                WHERE fl.patient_id = p_patient_id
                AND fl.started_at >= CURRENT_DATE - p_days
                AND fl.ended_at IS NOT NULL
                GROUP BY fl.protocol_id
            ) by_protocol
            LEFT JOIN fasting_protocols fp ON fp.id = by_protocol.protocol_id
        )
    ) INTO v_result;

    RETURN v_result;
END;
$$;

COMMENT ON FUNCTION get_fasting_statistics IS 'Get comprehensive fasting statistics for a patient over N days';

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================

ALTER TABLE fasting_protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE fasting_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fasting_goals ENABLE ROW LEVEL SECURITY;
ALTER TABLE fasting_streaks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- RLS POLICIES: fasting_protocols (readable by all authenticated, managed by service)
-- ============================================================================

DROP POLICY IF EXISTS "Anyone can read active fasting protocols" ON fasting_protocols;
CREATE POLICY "Anyone can read active fasting protocols"
    ON fasting_protocols FOR SELECT
    TO authenticated
    USING (is_active = true);

DROP POLICY IF EXISTS "Service role can manage fasting protocols" ON fasting_protocols;
CREATE POLICY "Service role can manage fasting protocols"
    ON fasting_protocols FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- RLS POLICIES: fasting_logs
-- ============================================================================

-- Patients can view their own fasting logs
DROP POLICY IF EXISTS "Patients view own fasting logs" ON fasting_logs;
CREATE POLICY "Patients view own fasting logs"
    ON fasting_logs FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can create their own fasting logs
DROP POLICY IF EXISTS "Patients create own fasting logs" ON fasting_logs;
CREATE POLICY "Patients create own fasting logs"
    ON fasting_logs FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own fasting logs
DROP POLICY IF EXISTS "Patients update own fasting logs" ON fasting_logs;
CREATE POLICY "Patients update own fasting logs"
    ON fasting_logs FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Patients can delete their own fasting logs
DROP POLICY IF EXISTS "Patients delete own fasting logs" ON fasting_logs;
CREATE POLICY "Patients delete own fasting logs"
    ON fasting_logs FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view fasting logs for their patients
DROP POLICY IF EXISTS "Therapists view patient fasting logs" ON fasting_logs;
CREATE POLICY "Therapists view patient fasting logs"
    ON fasting_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = fasting_logs.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Demo patient: Any authenticated user can CRUD
DROP POLICY IF EXISTS "fasting_logs_demo_patient_select" ON fasting_logs;
CREATE POLICY "fasting_logs_demo_patient_select"
    ON fasting_logs FOR SELECT
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_logs_demo_patient_insert" ON fasting_logs;
CREATE POLICY "fasting_logs_demo_patient_insert"
    ON fasting_logs FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_logs_demo_patient_update" ON fasting_logs;
CREATE POLICY "fasting_logs_demo_patient_update"
    ON fasting_logs FOR UPDATE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_logs_demo_patient_delete" ON fasting_logs;
CREATE POLICY "fasting_logs_demo_patient_delete"
    ON fasting_logs FOR DELETE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Service role full access
DROP POLICY IF EXISTS "Service role can manage all fasting logs" ON fasting_logs;
CREATE POLICY "Service role can manage all fasting logs"
    ON fasting_logs FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- RLS POLICIES: fasting_goals
-- ============================================================================

-- Patients can view their own fasting goals
DROP POLICY IF EXISTS "Patients view own fasting goals" ON fasting_goals;
CREATE POLICY "Patients view own fasting goals"
    ON fasting_goals FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can create their own fasting goals
DROP POLICY IF EXISTS "Patients create own fasting goals" ON fasting_goals;
CREATE POLICY "Patients create own fasting goals"
    ON fasting_goals FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own fasting goals
DROP POLICY IF EXISTS "Patients update own fasting goals" ON fasting_goals;
CREATE POLICY "Patients update own fasting goals"
    ON fasting_goals FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Patients can delete their own fasting goals
DROP POLICY IF EXISTS "Patients delete own fasting goals" ON fasting_goals;
CREATE POLICY "Patients delete own fasting goals"
    ON fasting_goals FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view and manage goals for their patients
DROP POLICY IF EXISTS "Therapists view patient fasting goals" ON fasting_goals;
CREATE POLICY "Therapists view patient fasting goals"
    ON fasting_goals FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = fasting_goals.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Therapists create patient fasting goals" ON fasting_goals;
CREATE POLICY "Therapists create patient fasting goals"
    ON fasting_goals FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = fasting_goals.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Therapists update patient fasting goals" ON fasting_goals;
CREATE POLICY "Therapists update patient fasting goals"
    ON fasting_goals FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = fasting_goals.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Demo patient: Any authenticated user can CRUD
DROP POLICY IF EXISTS "fasting_goals_demo_patient_select" ON fasting_goals;
CREATE POLICY "fasting_goals_demo_patient_select"
    ON fasting_goals FOR SELECT
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_goals_demo_patient_insert" ON fasting_goals;
CREATE POLICY "fasting_goals_demo_patient_insert"
    ON fasting_goals FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_goals_demo_patient_update" ON fasting_goals;
CREATE POLICY "fasting_goals_demo_patient_update"
    ON fasting_goals FOR UPDATE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_goals_demo_patient_delete" ON fasting_goals;
CREATE POLICY "fasting_goals_demo_patient_delete"
    ON fasting_goals FOR DELETE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Service role full access
DROP POLICY IF EXISTS "Service role can manage all fasting goals" ON fasting_goals;
CREATE POLICY "Service role can manage all fasting goals"
    ON fasting_goals FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- RLS POLICIES: fasting_streaks
-- ============================================================================

-- Patients can view their own fasting streaks
DROP POLICY IF EXISTS "Patients view own fasting streaks" ON fasting_streaks;
CREATE POLICY "Patients view own fasting streaks"
    ON fasting_streaks FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can create their own streak record (usually auto-created)
DROP POLICY IF EXISTS "Patients create own fasting streaks" ON fasting_streaks;
CREATE POLICY "Patients create own fasting streaks"
    ON fasting_streaks FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own streaks (rare, usually trigger-managed)
DROP POLICY IF EXISTS "Patients update own fasting streaks" ON fasting_streaks;
CREATE POLICY "Patients update own fasting streaks"
    ON fasting_streaks FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Therapists can view streaks for their patients
DROP POLICY IF EXISTS "Therapists view patient fasting streaks" ON fasting_streaks;
CREATE POLICY "Therapists view patient fasting streaks"
    ON fasting_streaks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = fasting_streaks.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Demo patient: Any authenticated user can CRUD
DROP POLICY IF EXISTS "fasting_streaks_demo_patient_select" ON fasting_streaks;
CREATE POLICY "fasting_streaks_demo_patient_select"
    ON fasting_streaks FOR SELECT
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_streaks_demo_patient_insert" ON fasting_streaks;
CREATE POLICY "fasting_streaks_demo_patient_insert"
    ON fasting_streaks FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

DROP POLICY IF EXISTS "fasting_streaks_demo_patient_update" ON fasting_streaks;
CREATE POLICY "fasting_streaks_demo_patient_update"
    ON fasting_streaks FOR UPDATE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Service role full access
DROP POLICY IF EXISTS "Service role can manage all fasting streaks" ON fasting_streaks;
CREATE POLICY "Service role can manage all fasting streaks"
    ON fasting_streaks FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- GRANT PERMISSIONS
-- ============================================================================

GRANT SELECT ON fasting_protocols TO authenticated;
GRANT ALL ON fasting_protocols TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON fasting_logs TO authenticated;
GRANT ALL ON fasting_logs TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON fasting_goals TO authenticated;
GRANT ALL ON fasting_goals TO service_role;

GRANT SELECT, INSERT, UPDATE, DELETE ON fasting_streaks TO authenticated;
GRANT ALL ON fasting_streaks TO service_role;

GRANT EXECUTE ON FUNCTION get_fasting_statistics TO authenticated;
GRANT EXECUTE ON FUNCTION update_fasting_streak TO authenticated;
GRANT EXECUTE ON FUNCTION update_fasting_timestamp TO authenticated;

-- ============================================================================
-- SEED DATA: Common Fasting Protocols
-- ============================================================================

INSERT INTO fasting_protocols (name, description, fasting_hours, eating_window_hours, weekly_pattern, min_calories_fast_day, difficulty_level, benefits, precautions, sort_order) VALUES

-- 16:8 Intermittent Fasting (Most Popular)
(
    '16:8 Intermittent Fasting',
    'The most popular intermittent fasting method. Fast for 16 hours and eat within an 8-hour window. Typically skip breakfast and eat from noon to 8 PM.',
    16,
    8,
    '{"daily": true}'::jsonb,
    NULL,
    'beginner',
    '["Weight loss", "Improved insulin sensitivity", "Increased energy", "Mental clarity", "Easy to maintain long-term"]'::jsonb,
    '["Not recommended for pregnant women", "Consult doctor if diabetic", "May not be suitable for those with eating disorders"]'::jsonb,
    1
),

-- 18:6 Intermittent Fasting
(
    '18:6 Intermittent Fasting',
    'A slightly more challenging version of 16:8. Fast for 18 hours with a 6-hour eating window. Often involves eating 2 meals between noon and 6 PM.',
    18,
    6,
    '{"daily": true}'::jsonb,
    NULL,
    'intermediate',
    '["Enhanced fat burning", "Improved metabolic flexibility", "Better blood sugar control", "Increased autophagy", "Weight management"]'::jsonb,
    '["Not for beginners", "May cause initial hunger", "Monitor energy levels during workouts"]'::jsonb,
    2
),

-- 20:4 Warrior Diet
(
    '20:4 Warrior Diet',
    'Fast for 20 hours with a 4-hour eating window, typically in the evening. Based on ancient warrior eating patterns. Often one large meal with snacks.',
    20,
    4,
    '{"daily": true}'::jsonb,
    NULL,
    'advanced',
    '["Significant fat loss", "Increased growth hormone", "Enhanced autophagy", "Improved focus during fasting", "Simplified meal planning"]'::jsonb,
    '["Difficult to get adequate nutrition", "Not suitable for athletes with high caloric needs", "May affect sleep if eating late"]'::jsonb,
    3
),

-- OMAD (One Meal A Day)
(
    'OMAD (One Meal A Day)',
    'Eat only one meal per day within a 1-hour window. The most extreme daily intermittent fasting approach. Requires careful meal planning for nutrition.',
    23,
    1,
    '{"daily": true}'::jsonb,
    NULL,
    'expert',
    '["Maximum autophagy", "Simplified lifestyle", "Significant caloric restriction", "Mental discipline", "Time saved on meal prep"]'::jsonb,
    '["Risk of nutrient deficiency", "Not suitable for most athletes", "May lead to overeating", "Requires careful meal planning", "Not recommended long-term"]'::jsonb,
    4
),

-- 5:2 Diet
(
    '5:2 Modified Fasting',
    'Eat normally for 5 days per week and restrict calories to 500-600 on 2 non-consecutive days. A flexible approach that fits various lifestyles.',
    24,
    24,
    '{"fast_days": [1, 4], "normal_days": [0, 2, 3, 5, 6], "description": "Monday and Thursday are fast days"}'::jsonb,
    500,
    'intermediate',
    '["Flexibility in schedule", "Easier to maintain socially", "Proven weight loss results", "Improved insulin sensitivity", "No daily restriction needed"]'::jsonb,
    '["May experience extreme hunger on fast days", "Requires calorie counting on fast days", "Not suitable for those with blood sugar issues"]'::jsonb,
    5
),

-- 36-Hour Fast (Monk Fast)
(
    '36-Hour Monk Fast',
    'Extended fast lasting 36 hours, typically from dinner one day to breakfast two days later. Usually done once per week for enhanced benefits.',
    36,
    0,
    '{"frequency": "weekly", "description": "One 36-hour fast per week, typically dinner Sunday to breakfast Tuesday"}'::jsonb,
    NULL,
    'advanced',
    '["Deep autophagy", "Significant fat adaptation", "Mental clarity and focus", "Gut rest and healing", "Hormonal benefits"]'::jsonb,
    '["Requires experience with shorter fasts first", "Stay hydrated with electrolytes", "Break fast gently with light foods", "Not for those with medical conditions"]'::jsonb,
    6
),

-- Circadian Rhythm Fasting
(
    'Circadian Rhythm Fasting',
    'Align eating with natural daylight hours. Eat during daylight (typically 8 AM - 6 PM) and fast during darkness. Optimizes metabolism with circadian biology.',
    14,
    10,
    '{"daily": true, "eating_start": "08:00", "eating_end": "18:00", "description": "Eat with the sun, fast with the moon"}'::jsonb,
    NULL,
    'beginner',
    '["Aligns with natural body rhythms", "Improved sleep quality", "Better digestion", "Sustainable long-term", "Supports hormonal balance"]'::jsonb,
    '["Requires early dinner", "Social eating challenges", "May need adjustment for shift workers"]'::jsonb,
    7
),

-- Eat-Stop-Eat (24-Hour Fast)
(
    'Eat-Stop-Eat (24-Hour Fast)',
    'Complete 24-hour fast once or twice per week. Fast from dinner to dinner or lunch to lunch. Normal eating on non-fasting days.',
    24,
    0,
    '{"frequency": "1-2x weekly", "description": "One or two 24-hour fasts per week"}'::jsonb,
    NULL,
    'intermediate',
    '["Significant calorie reduction", "Enhanced autophagy", "Flexible scheduling", "Growth hormone boost", "Mental reset"]'::jsonb,
    '["Initial hunger can be challenging", "Requires gradual buildup", "Stay hydrated", "Avoid binge eating after fast"]'::jsonb,
    8
),

-- Alternate Day Fasting
(
    'Alternate Day Fasting',
    'Alternate between normal eating days and fasting/very low calorie days. Modified version allows 500 calories on fast days.',
    24,
    24,
    '{"pattern": "alternate", "fast_days": [0, 2, 4, 6], "normal_days": [1, 3, 5], "description": "Fast every other day"}'::jsonb,
    500,
    'advanced',
    '["Rapid weight loss", "Improved cholesterol levels", "Enhanced insulin sensitivity", "Cardiovascular benefits", "Research-backed results"]'::jsonb,
    '["Socially challenging", "Requires strong commitment", "May affect exercise performance", "Not sustainable for everyone long-term"]'::jsonb,
    9
),

-- 14:10 Gentle Fasting
(
    '14:10 Gentle Fasting',
    'A gentler introduction to intermittent fasting. Fast for 14 hours with a 10-hour eating window. Perfect for beginners or those transitioning from standard eating.',
    14,
    10,
    '{"daily": true}'::jsonb,
    NULL,
    'beginner',
    '["Easy to start", "Minimal lifestyle disruption", "Gradual adaptation", "Improved digestion", "Foundation for longer fasts"]'::jsonb,
    '["Benefits may be milder", "Good stepping stone to 16:8"]'::jsonb,
    10
)

ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    fasting_hours = EXCLUDED.fasting_hours,
    eating_window_hours = EXCLUDED.eating_window_hours,
    weekly_pattern = EXCLUDED.weekly_pattern,
    min_calories_fast_day = EXCLUDED.min_calories_fast_day,
    difficulty_level = EXCLUDED.difficulty_level,
    benefits = EXCLUDED.benefits,
    precautions = EXCLUDED.precautions,
    sort_order = EXCLUDED.sort_order,
    updated_at = NOW();

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_protocols_count INTEGER;
    v_logs_count INTEGER;
    v_goals_count INTEGER;
    v_streaks_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO v_protocols_count FROM fasting_protocols WHERE is_active = true;
    SELECT COUNT(*) INTO v_logs_count FROM fasting_logs;
    SELECT COUNT(*) INTO v_goals_count FROM fasting_goals;
    SELECT COUNT(*) INTO v_streaks_count FROM fasting_streaks;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'FASTING PROTOCOL TRACKING SYSTEM CREATED - ACP-427';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '   - fasting_protocols (% protocols seeded)', v_protocols_count;
    RAISE NOTICE '   - fasting_logs (% existing entries)', v_logs_count;
    RAISE NOTICE '   - fasting_goals (% existing entries)', v_goals_count;
    RAISE NOTICE '   - fasting_streaks (% existing entries)', v_streaks_count;
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '   - get_fasting_statistics(patient_id, days) -> JSON';
    RAISE NOTICE '   - update_fasting_streak() [trigger function]';
    RAISE NOTICE '   - update_fasting_timestamp() [trigger function]';
    RAISE NOTICE '';
    RAISE NOTICE 'Indexes Created:';
    RAISE NOTICE '   - idx_fasting_protocols_active';
    RAISE NOTICE '   - idx_fasting_protocols_difficulty';
    RAISE NOTICE '   - idx_fasting_protocols_sort';
    RAISE NOTICE '   - idx_fasting_logs_patient';
    RAISE NOTICE '   - idx_fasting_logs_patient_date';
    RAISE NOTICE '   - idx_fasting_logs_protocol';
    RAISE NOTICE '   - idx_fasting_logs_active';
    RAISE NOTICE '   - idx_fasting_logs_started';
    RAISE NOTICE '   - idx_fasting_logs_completed';
    RAISE NOTICE '   - idx_fasting_goals_patient';
    RAISE NOTICE '   - idx_fasting_goals_active';
    RAISE NOTICE '   - idx_fasting_goals_protocol';
    RAISE NOTICE '   - idx_fasting_goals_dates';
    RAISE NOTICE '   - idx_fasting_streaks_patient';
    RAISE NOTICE '   - idx_fasting_streaks_current';
    RAISE NOTICE '   - idx_fasting_streaks_longest';
    RAISE NOTICE '   - idx_fasting_streaks_last_fast';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '   - fasting_protocols: Public read, service role manage';
    RAISE NOTICE '   - fasting_logs: Patient CRUD own, Therapist read, Demo patient CRUD';
    RAISE NOTICE '   - fasting_goals: Patient CRUD own, Therapist manage, Demo patient CRUD';
    RAISE NOTICE '   - fasting_streaks: Patient read/update own, Therapist read, Demo patient CRUD';
    RAISE NOTICE '';
    RAISE NOTICE 'Seeded Protocols:';
    RAISE NOTICE '   1. 16:8 Intermittent Fasting (beginner)';
    RAISE NOTICE '   2. 18:6 Intermittent Fasting (intermediate)';
    RAISE NOTICE '   3. 20:4 Warrior Diet (advanced)';
    RAISE NOTICE '   4. OMAD - One Meal A Day (expert)';
    RAISE NOTICE '   5. 5:2 Modified Fasting (intermediate)';
    RAISE NOTICE '   6. 36-Hour Monk Fast (advanced)';
    RAISE NOTICE '   7. Circadian Rhythm Fasting (beginner)';
    RAISE NOTICE '   8. Eat-Stop-Eat 24-Hour Fast (intermediate)';
    RAISE NOTICE '   9. Alternate Day Fasting (advanced)';
    RAISE NOTICE '   10. 14:10 Gentle Fasting (beginner)';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'FASTING PROTOCOL SYSTEM READY';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;
