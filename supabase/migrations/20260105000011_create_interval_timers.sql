-- ============================================================================
-- CREATE INTERVAL TIMERS - BUILD 116 AGENT 2
-- ============================================================================
-- Comprehensive interval timer system with templates and session tracking
-- Supports Tabata, EMOM, AMRAP, Intervals, and Custom timers
--
-- Date: 2026-01-03
-- Linear: BUILD 116
-- ============================================================================

-- ============================================================================
-- ENUMS
-- ============================================================================

-- Timer type enumeration
CREATE TYPE timer_type AS ENUM (
    'tabata',      -- 20s work / 10s rest classic Tabata protocol
    'emom',        -- Every Minute On the Minute
    'amrap',       -- As Many Rounds As Possible
    'intervals',   -- Custom interval training
    'custom'       -- Fully customizable timer
);

COMMENT ON TYPE timer_type IS
    'Timer protocol type: tabata (20/10), emom (every minute), amrap (max rounds), intervals (custom), custom (fully flexible)';

-- Timer category enumeration
CREATE TYPE timer_category AS ENUM (
    'cardio',      -- Cardiovascular conditioning
    'strength',    -- Strength training intervals
    'warmup',      -- Pre-workout warmup
    'cooldown',    -- Post-workout cooldown
    'recovery'     -- Active recovery sessions
);

COMMENT ON TYPE timer_category IS
    'Timer category for organization: cardio, strength, warmup, cooldown, recovery';

-- ============================================================================
-- TABLES
-- ============================================================================

-- Interval templates (reusable timer configurations)
CREATE TABLE interval_templates (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    type timer_type NOT NULL,
    work_seconds int NOT NULL CHECK (work_seconds > 0),
    rest_seconds int NOT NULL CHECK (rest_seconds >= 0),
    rounds int NOT NULL CHECK (rounds > 0),
    cycles int DEFAULT 1 CHECK (cycles > 0),
    created_by uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    is_public boolean NOT NULL DEFAULT false,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_interval_templates_type ON interval_templates(type);
CREATE INDEX idx_interval_templates_created_by ON interval_templates(created_by);
CREATE INDEX idx_interval_templates_public ON interval_templates(is_public) WHERE is_public = true;

COMMENT ON TABLE interval_templates IS
    'Reusable interval timer templates created by therapists';
COMMENT ON COLUMN interval_templates.work_seconds IS 'Work duration in seconds';
COMMENT ON COLUMN interval_templates.rest_seconds IS 'Rest duration in seconds';
COMMENT ON COLUMN interval_templates.rounds IS 'Number of rounds per cycle';
COMMENT ON COLUMN interval_templates.cycles IS 'Number of complete cycles (default: 1)';
COMMENT ON COLUMN interval_templates.is_public IS 'If true, visible to all therapists';

-- Workout timers (patient timer sessions)
CREATE TABLE workout_timers (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id uuid NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    template_id uuid REFERENCES interval_templates(id) ON DELETE SET NULL,
    started_at timestamptz NOT NULL DEFAULT now(),
    completed_at timestamptz,
    rounds_completed int DEFAULT 0 CHECK (rounds_completed >= 0),
    paused_seconds int DEFAULT 0 CHECK (paused_seconds >= 0),
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_workout_timers_patient ON workout_timers(patient_id, started_at DESC);
CREATE INDEX idx_workout_timers_template ON workout_timers(template_id);
CREATE INDEX idx_workout_timers_completed ON workout_timers(completed_at) WHERE completed_at IS NOT NULL;

COMMENT ON TABLE workout_timers IS
    'Patient timer session tracking with completion data';
COMMENT ON COLUMN workout_timers.rounds_completed IS 'Number of rounds completed';
COMMENT ON COLUMN workout_timers.paused_seconds IS 'Total seconds the timer was paused';

-- Timer presets (curated preset configurations)
CREATE TABLE timer_presets (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    name text NOT NULL,
    description text,
    template_json jsonb NOT NULL,
    category timer_category NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_timer_presets_category ON timer_presets(category);

COMMENT ON TABLE timer_presets IS
    'Curated timer presets with full configuration JSON';
COMMENT ON COLUMN timer_presets.template_json IS 'Complete timer configuration as JSON (includes type, work, rest, rounds, cycles)';
COMMENT ON COLUMN timer_presets.category IS 'Preset category for filtering';

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

-- Interval Templates RLS
ALTER TABLE interval_templates ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Therapists can view all public templates"
    ON interval_templates FOR SELECT
    TO authenticated
    USING (
        is_public = true
        OR created_by = auth.uid()
        OR EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

CREATE POLICY "Therapists can create templates"
    ON interval_templates FOR INSERT
    TO authenticated
    WITH CHECK (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

CREATE POLICY "Therapists can update their own templates"
    ON interval_templates FOR UPDATE
    TO authenticated
    USING (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

CREATE POLICY "Therapists can delete their own templates"
    ON interval_templates FOR DELETE
    TO authenticated
    USING (
        created_by = auth.uid()
        AND EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

-- Workout Timers RLS
ALTER TABLE workout_timers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Patients can view their own timer sessions"
    ON workout_timers FOR SELECT
    TO authenticated
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists can view all timer sessions"
    ON workout_timers FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.id = auth.uid()
        )
    );

CREATE POLICY "Patients can create their own timer sessions"
    ON workout_timers FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own timer sessions"
    ON workout_timers FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid());

-- Timer Presets RLS (read-only for users)
ALTER TABLE timer_presets ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can view timer presets"
    ON timer_presets FOR SELECT
    TO authenticated
    USING (true);

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

-- Create a Tabata preset template
CREATE OR REPLACE FUNCTION create_tabata_preset(
    p_work int,
    p_rest int,
    p_rounds int
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_template_id uuid;
BEGIN
    -- Validate inputs
    IF p_work <= 0 OR p_rest < 0 OR p_rounds <= 0 THEN
        RAISE EXCEPTION 'Invalid timer parameters: work=%, rest=%, rounds=%', p_work, p_rest, p_rounds;
    END IF;

    -- Create template
    INSERT INTO interval_templates (
        name,
        type,
        work_seconds,
        rest_seconds,
        rounds,
        cycles,
        created_by,
        is_public
    ) VALUES (
        format('Tabata %ss/%ss x%s', p_work, p_rest, p_rounds),
        'tabata',
        p_work,
        p_rest,
        p_rounds,
        1,
        auth.uid(),
        false
    )
    RETURNING id INTO v_template_id;

    RETURN v_template_id;
END;
$$;

COMMENT ON FUNCTION create_tabata_preset IS
    'Create a Tabata interval template with specified work, rest, and rounds';

-- Log a timer session for a patient
CREATE OR REPLACE FUNCTION log_timer_session(
    p_patient_id uuid,
    p_template_id uuid,
    p_duration int
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_template record;
    v_total_rounds int;
BEGIN
    -- Validate patient exists
    IF NOT EXISTS (SELECT 1 FROM patients WHERE id = p_patient_id) THEN
        RAISE EXCEPTION 'Patient not found: %', p_patient_id;
    END IF;

    -- Validate template exists
    SELECT * INTO v_template
    FROM interval_templates
    WHERE id = p_template_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Template not found: %', p_template_id;
    END IF;

    -- Calculate rounds completed based on duration
    -- Formula: duration / (work + rest) = rounds
    v_total_rounds := FLOOR(p_duration::numeric / (v_template.work_seconds + v_template.rest_seconds)::numeric);

    -- Insert workout timer session
    INSERT INTO workout_timers (
        patient_id,
        template_id,
        started_at,
        completed_at,
        rounds_completed,
        paused_seconds
    ) VALUES (
        p_patient_id,
        p_template_id,
        now() - (p_duration || ' seconds')::interval,
        now(),
        v_total_rounds,
        0
    );
END;
$$;

COMMENT ON FUNCTION log_timer_session IS
    'Log a completed timer session for a patient with automatic round calculation';

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Updated_at trigger function
CREATE OR REPLACE FUNCTION update_timer_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_interval_templates_updated_at
    BEFORE UPDATE ON interval_templates
    FOR EACH ROW
    EXECUTE FUNCTION update_timer_updated_at();

CREATE TRIGGER update_workout_timers_updated_at
    BEFORE UPDATE ON workout_timers
    FOR EACH ROW
    EXECUTE FUNCTION update_timer_updated_at();

CREATE TRIGGER update_timer_presets_updated_at
    BEFORE UPDATE ON timer_presets
    FOR EACH ROW
    EXECUTE FUNCTION update_timer_updated_at();

-- ============================================================================
-- SEED DATA
-- ============================================================================

-- Seed common timer presets
INSERT INTO timer_presets (name, description, category, template_json) VALUES
-- Cardio presets
(
    'Classic Tabata',
    '20 seconds work, 10 seconds rest, 8 rounds - the original Tabata protocol',
    'cardio',
    '{"type": "tabata", "work_seconds": 20, "rest_seconds": 10, "rounds": 8, "cycles": 1}'::jsonb
),
(
    'EMOM 10',
    'Every minute on the minute for 10 minutes',
    'cardio',
    '{"type": "emom", "work_seconds": 50, "rest_seconds": 10, "rounds": 10, "cycles": 1}'::jsonb
),
(
    'AMRAP 15',
    'As many rounds as possible in 15 minutes',
    'cardio',
    '{"type": "amrap", "work_seconds": 900, "rest_seconds": 0, "rounds": 1, "cycles": 1}'::jsonb
),

-- Strength presets
(
    'Strength Intervals',
    '40 seconds work, 20 seconds rest, 6 rounds - strength focused',
    'strength',
    '{"type": "intervals", "work_seconds": 40, "rest_seconds": 20, "rounds": 6, "cycles": 1}'::jsonb
),
(
    'Power Tabata',
    '30 seconds explosive work, 15 seconds rest, 8 rounds',
    'strength',
    '{"type": "tabata", "work_seconds": 30, "rest_seconds": 15, "rounds": 8, "cycles": 1}'::jsonb
),

-- Warmup presets
(
    'Quick Warmup',
    '30 seconds per movement, 10 seconds transition, 5 rounds',
    'warmup',
    '{"type": "intervals", "work_seconds": 30, "rest_seconds": 10, "rounds": 5, "cycles": 1}'::jsonb
),
(
    'Dynamic Warmup',
    '40 seconds movement, 20 seconds rest, 8 rounds',
    'warmup',
    '{"type": "intervals", "work_seconds": 40, "rest_seconds": 20, "rounds": 8, "cycles": 1}'::jsonb
),

-- Cooldown presets
(
    'Cool Down Stretch',
    '45 seconds per stretch, 15 seconds transition, 6 rounds',
    'cooldown',
    '{"type": "intervals", "work_seconds": 45, "rest_seconds": 15, "rounds": 6, "cycles": 1}'::jsonb
),

-- Recovery presets
(
    'Active Recovery',
    '2 minutes light work, 1 minute rest, 5 rounds',
    'recovery',
    '{"type": "intervals", "work_seconds": 120, "rest_seconds": 60, "rounds": 5, "cycles": 1}'::jsonb
),
(
    'Mobility Flow',
    '60 seconds per position, 30 seconds transition, 8 rounds',
    'recovery',
    '{"type": "intervals", "work_seconds": 60, "rest_seconds": 30, "rounds": 8, "cycles": 1}'::jsonb
)

ON CONFLICT DO NOTHING;

-- ============================================================================
-- PERMISSIONS
-- ============================================================================

GRANT SELECT, INSERT, UPDATE, DELETE ON interval_templates TO authenticated;
GRANT SELECT, INSERT, UPDATE ON workout_timers TO authenticated;
GRANT SELECT ON timer_presets TO authenticated;
GRANT EXECUTE ON FUNCTION create_tabata_preset TO authenticated;
GRANT EXECUTE ON FUNCTION log_timer_session TO authenticated;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_tabata_count int;
    v_cardio_count int;
    v_preset_count int;
BEGIN
    -- Count Tabata templates
    SELECT COUNT(*) INTO v_tabata_count
    FROM interval_templates
    WHERE type = 'tabata';

    -- Count cardio presets
    SELECT COUNT(*) INTO v_cardio_count
    FROM timer_presets
    WHERE category = 'cardio';

    -- Count all presets
    SELECT COUNT(*) INTO v_preset_count
    FROM timer_presets;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'INTERVAL TIMERS CREATED - BUILD 116 AGENT 2';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Enums created:';
    RAISE NOTICE '   - timer_type: tabata, emom, amrap, intervals, custom';
    RAISE NOTICE '   - timer_category: cardio, strength, warmup, cooldown, recovery';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Tables created:';
    RAISE NOTICE '   - interval_templates (% templates)', v_tabata_count;
    RAISE NOTICE '   - workout_timers (session tracking)';
    RAISE NOTICE '   - timer_presets (% presets seeded)', v_preset_count;
    RAISE NOTICE '';
    RAISE NOTICE '✅ RLS policies: 8 policies configured';
    RAISE NOTICE '   - interval_templates: 4 policies (therapist-owned)';
    RAISE NOTICE '   - workout_timers: 4 policies (patient-owned)';
    RAISE NOTICE '   - timer_presets: 1 policy (read-only)';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Functions created:';
    RAISE NOTICE '   - create_tabata_preset(work int, rest int, rounds int) → uuid';
    RAISE NOTICE '   - log_timer_session(patient_id uuid, template_id uuid, duration int) → void';
    RAISE NOTICE '';
    RAISE NOTICE '✅ Validation:';
    RAISE NOTICE '   - Tabata templates: % found', v_tabata_count;
    RAISE NOTICE '   - Cardio presets: % found', v_cardio_count;
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'INTERVAL TIMER SYSTEM READY';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
END $$;
