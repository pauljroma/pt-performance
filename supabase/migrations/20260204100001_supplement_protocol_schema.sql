-- ============================================================================
-- SUPPLEMENT PROTOCOL SCHEMA MIGRATION
-- ============================================================================
-- ACP-435: Comprehensive database schema for supplement tracking
--
-- Tables:
--   1. supplements - Master catalog of supplements
--   2. supplement_stacks - Predefined supplement combinations
--   3. supplement_stack_items - Supplements in each stack
--   4. patient_supplement_logs - Daily intake tracking
--   5. patient_supplement_routines - User's daily plan
--   6. supplement_compliance - Track adherence
--
-- Date: 2026-02-04
-- ============================================================================

BEGIN;

-- ============================================================================
-- CUSTOM TYPES (ENUMS)
-- ============================================================================

-- Evidence rating for supplements
DO $$ BEGIN
    CREATE TYPE supplement_evidence_rating AS ENUM (
        'strong',
        'moderate',
        'emerging',
        'limited'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Supplement category enum
DO $$ BEGIN
    CREATE TYPE supplement_category AS ENUM (
        'performance',
        'recovery',
        'sleep',
        'health',
        'cognitive',
        'hormonal',
        'joint',
        'digestive'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Supplement timing enum (extend existing if needed)
DO $$ BEGIN
    CREATE TYPE supplement_timing_type AS ENUM (
        'morning',
        'afternoon',
        'evening',
        'pre_workout',
        'post_workout',
        'with_meal',
        'before_bed',
        'empty_stomach',
        'any_time'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- WADA status enum
DO $$ BEGIN
    CREATE TYPE wada_status AS ENUM (
        'not_banned',
        'banned',
        'at_risk',
        'monitoring',
        'unknown'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Stack difficulty level
DO $$ BEGIN
    CREATE TYPE stack_difficulty AS ENUM (
        'beginner',
        'intermediate',
        'advanced'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- 1. SUPPLEMENTS TABLE - Master Catalog
-- ============================================================================

CREATE TABLE IF NOT EXISTS supplements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    brand TEXT,
    category supplement_category NOT NULL,
    subcategory TEXT,
    description TEXT,

    -- Benefits and effects
    benefits JSONB DEFAULT '[]'::jsonb,

    -- Dosing information
    typical_dose NUMERIC(10,2),
    dose_unit TEXT DEFAULT 'mg',
    timing_recommendation supplement_timing_type DEFAULT 'any_time',

    -- Evidence and research
    evidence_rating supplement_evidence_rating DEFAULT 'limited',
    research_notes TEXT,

    -- Safety information
    interactions JSONB DEFAULT '[]'::jsonb,
    contraindications JSONB DEFAULT '[]'::jsonb,
    side_effects JSONB DEFAULT '[]'::jsonb,

    -- Athletic status
    is_banned_substance BOOLEAN DEFAULT false,
    wada_status wada_status DEFAULT 'unknown',

    -- Purchase information
    purchase_url TEXT,
    price_estimate NUMERIC(10,2),

    -- Metadata
    image_url TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT supplements_name_brand_unique UNIQUE (name, brand)
);

-- Add missing columns to existing supplements table
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplements' AND column_name = 'is_active') THEN
        ALTER TABLE supplements ADD COLUMN is_active BOOLEAN DEFAULT true;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplements' AND column_name = 'wada_status') THEN
        ALTER TABLE supplements ADD COLUMN wada_status TEXT DEFAULT 'unknown';
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplements' AND column_name = 'benefits') THEN
        ALTER TABLE supplements ADD COLUMN benefits JSONB DEFAULT '[]'::jsonb;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplements' AND column_name = 'interactions') THEN
        ALTER TABLE supplements ADD COLUMN interactions JSONB DEFAULT '[]'::jsonb;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplements' AND column_name = 'evidence_rating') THEN
        ALTER TABLE supplements ADD COLUMN evidence_rating TEXT DEFAULT 'limited';
    END IF;
END $$;

COMMENT ON TABLE supplements IS 'Master catalog of supplements with dosing, evidence, and safety information';

-- Indexes for supplements (wrapped for safety)
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplements_category ON supplements(category); EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplements_name ON supplements(name); EXCEPTION WHEN undefined_column THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplements_evidence ON supplements(evidence_rating); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplements_active ON supplements(is_active) WHERE is_active = true; EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplements_wada ON supplements(wada_status); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

-- ============================================================================
-- 2. SUPPLEMENT_STACKS TABLE - Predefined Combinations
-- ============================================================================

CREATE TABLE IF NOT EXISTS supplement_stacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT,
    goal TEXT NOT NULL,
    difficulty_level stack_difficulty DEFAULT 'beginner',
    monthly_cost_estimate NUMERIC(10,2),

    -- Metadata
    image_url TEXT,
    source TEXT,
    source_url TEXT,
    is_featured BOOLEAN DEFAULT false,
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES patients(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE supplement_stacks IS 'Predefined supplement combinations for specific goals';
COMMENT ON COLUMN supplement_stacks.goal IS 'Primary goal of the stack (e.g., sleep, recovery, performance)';
COMMENT ON COLUMN supplement_stacks.source IS 'Source of the stack recommendation (e.g., Huberman Lab)';
COMMENT ON COLUMN supplement_stacks.monthly_cost_estimate IS 'Estimated monthly cost in USD';

-- Indexes for supplement_stacks
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_stacks_goal ON supplement_stacks(goal); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_stacks_difficulty ON supplement_stacks(difficulty_level); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_stacks_featured ON supplement_stacks(is_featured) WHERE is_featured = true; EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_stacks_active ON supplement_stacks(is_active) WHERE is_active = true; EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

-- ============================================================================
-- 3. SUPPLEMENT_STACK_ITEMS TABLE - Supplements in Each Stack
-- ============================================================================

CREATE TABLE IF NOT EXISTS supplement_stack_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    stack_id UUID NOT NULL REFERENCES supplement_stacks(id) ON DELETE CASCADE,
    supplement_id UUID NOT NULL REFERENCES supplements(id) ON DELETE CASCADE,

    -- Dosing for this stack
    dose NUMERIC(10,2) NOT NULL,
    dose_unit TEXT DEFAULT 'mg',
    timing supplement_timing_type DEFAULT 'any_time',

    -- Stack-specific info
    is_required BOOLEAN DEFAULT true,
    notes TEXT,
    display_order INTEGER DEFAULT 0,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT supplement_stack_items_unique UNIQUE (stack_id, supplement_id)
);

COMMENT ON TABLE supplement_stack_items IS 'Individual supplements that make up a stack';
COMMENT ON COLUMN supplement_stack_items.is_required IS 'Whether supplement is core (required) or optional';
COMMENT ON COLUMN supplement_stack_items.notes IS 'Stack-specific notes for this supplement';

-- Indexes for supplement_stack_items
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_stack_items_stack ON supplement_stack_items(stack_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_stack_items_supplement ON supplement_stack_items(supplement_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

-- ============================================================================
-- 4. PATIENT_SUPPLEMENT_LOGS TABLE - Daily Intake Tracking
-- ============================================================================

CREATE TABLE IF NOT EXISTS patient_supplement_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    supplement_id UUID NOT NULL REFERENCES supplements(id) ON DELETE CASCADE,

    -- Dosing information
    dose_amount NUMERIC(10,2) NOT NULL,
    dose_unit TEXT DEFAULT 'mg',

    -- Timing
    taken_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    timing supplement_timing_type,
    with_food BOOLEAN,

    -- Notes
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE patient_supplement_logs IS 'Patient daily supplement intake log';
COMMENT ON COLUMN patient_supplement_logs.taken_at IS 'Exact timestamp when supplement was taken';
COMMENT ON COLUMN patient_supplement_logs.with_food IS 'Whether supplement was taken with food';

-- Indexes for patient_supplement_logs
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_logs_patient ON patient_supplement_logs(patient_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_logs_supplement ON patient_supplement_logs(supplement_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_logs_taken_at ON patient_supplement_logs(taken_at DESC); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_logs_patient_date ON patient_supplement_logs(patient_id, taken_at DESC); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_logs_patient_supplement ON patient_supplement_logs(patient_id, supplement_id, taken_at DESC); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

-- ============================================================================
-- 5. PATIENT_SUPPLEMENT_ROUTINES TABLE - User's Daily Plan
-- ============================================================================

CREATE TABLE IF NOT EXISTS patient_supplement_routines (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    supplement_id UUID NOT NULL REFERENCES supplements(id) ON DELETE CASCADE,
    stack_id UUID REFERENCES supplement_stacks(id) ON DELETE SET NULL,

    -- Dosing plan
    dose NUMERIC(10,2) NOT NULL,
    dose_unit TEXT DEFAULT 'mg',
    timing supplement_timing_type NOT NULL,

    -- Schedule
    days_of_week INTEGER[] DEFAULT ARRAY[0,1,2,3,4,5,6],

    -- Reminders
    reminder_enabled BOOLEAN DEFAULT false,
    reminder_time TIME,

    -- Status
    is_active BOOLEAN DEFAULT true,
    start_date DATE DEFAULT CURRENT_DATE,
    end_date DATE,

    -- Notes
    notes TEXT,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT patient_supplement_routines_unique UNIQUE (patient_id, supplement_id, timing)
);

COMMENT ON TABLE patient_supplement_routines IS 'Patient supplement routine/schedule';
COMMENT ON COLUMN patient_supplement_routines.days_of_week IS 'Array of days (0=Sunday, 6=Saturday)';
COMMENT ON COLUMN patient_supplement_routines.stack_id IS 'Reference to stack if supplement is part of adopted stack';
COMMENT ON COLUMN patient_supplement_routines.reminder_time IS 'Time to send reminder notification';

-- Indexes for patient_supplement_routines
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_routines_patient ON patient_supplement_routines(patient_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_routines_active ON patient_supplement_routines(patient_id, is_active) WHERE is_active = true; EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_routines_stack ON patient_supplement_routines(stack_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_patient_supplement_routines_timing ON patient_supplement_routines(timing); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

-- ============================================================================
-- 6. SUPPLEMENT_COMPLIANCE TABLE - Track Adherence
-- ============================================================================

CREATE TABLE IF NOT EXISTS supplement_compliance (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    date DATE NOT NULL DEFAULT CURRENT_DATE,

    -- Compliance metrics
    planned_supplements INTEGER NOT NULL DEFAULT 0,
    taken_supplements INTEGER NOT NULL DEFAULT 0,
    compliance_rate NUMERIC(5,2) GENERATED ALWAYS AS (
        CASE
            WHEN planned_supplements > 0 THEN (taken_supplements::NUMERIC / planned_supplements) * 100
            ELSE 0
        END
    ) STORED,

    -- Details
    missed_supplements JSONB DEFAULT '[]'::jsonb,

    -- Metadata
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Constraints
    CONSTRAINT supplement_compliance_unique UNIQUE (patient_id, date)
);

COMMENT ON TABLE supplement_compliance IS 'Daily supplement compliance tracking';
COMMENT ON COLUMN supplement_compliance.compliance_rate IS 'Calculated compliance percentage (0-100)';
COMMENT ON COLUMN supplement_compliance.missed_supplements IS 'JSONB array of missed supplement IDs and timings';

-- Indexes for supplement_compliance
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_compliance_patient ON supplement_compliance(patient_id); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_compliance_date ON supplement_compliance(date DESC); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_compliance_patient_date ON supplement_compliance(patient_id, date DESC); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;
DO $$ BEGIN CREATE INDEX IF NOT EXISTS idx_supplement_compliance_rate ON supplement_compliance(compliance_rate); EXCEPTION WHEN undefined_column OR duplicate_table THEN NULL; END $$;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_stacks ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_stack_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_supplement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_supplement_routines ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_compliance ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- SUPPLEMENTS POLICIES (Public read, admin write)
-- ============================================================================

-- Anyone can view active supplements
DROP POLICY IF EXISTS "supplements_select_all" ON supplements;
CREATE POLICY "supplements_select_all"
    ON supplements FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Therapists can manage supplements
DROP POLICY IF EXISTS "supplements_insert_therapist" ON supplements;
CREATE POLICY "supplements_insert_therapist"
    ON supplements FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "supplements_update_therapist" ON supplements;
CREATE POLICY "supplements_update_therapist"
    ON supplements FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- SUPPLEMENT_STACKS POLICIES (Public read for active, admin write)
-- ============================================================================

-- Anyone can view active stacks
DROP POLICY IF EXISTS "supplement_stacks_select_all" ON supplement_stacks;
CREATE POLICY "supplement_stacks_select_all"
    ON supplement_stacks FOR SELECT
    TO authenticated
    USING (is_active = true);

-- Therapists can manage stacks
DROP POLICY IF EXISTS "supplement_stacks_insert_therapist" ON supplement_stacks;
CREATE POLICY "supplement_stacks_insert_therapist"
    ON supplement_stacks FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "supplement_stacks_update_therapist" ON supplement_stacks;
CREATE POLICY "supplement_stacks_update_therapist"
    ON supplement_stacks FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- SUPPLEMENT_STACK_ITEMS POLICIES (Public read, admin write)
-- ============================================================================

-- Anyone can view stack items
DROP POLICY IF EXISTS "supplement_stack_items_select_all" ON supplement_stack_items;
CREATE POLICY "supplement_stack_items_select_all"
    ON supplement_stack_items FOR SELECT
    TO authenticated
    USING (true);

-- Therapists can manage stack items
DROP POLICY IF EXISTS "supplement_stack_items_insert_therapist" ON supplement_stack_items;
CREATE POLICY "supplement_stack_items_insert_therapist"
    ON supplement_stack_items FOR INSERT
    TO authenticated
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "supplement_stack_items_update_therapist" ON supplement_stack_items;
CREATE POLICY "supplement_stack_items_update_therapist"
    ON supplement_stack_items FOR UPDATE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "supplement_stack_items_delete_therapist" ON supplement_stack_items;
CREATE POLICY "supplement_stack_items_delete_therapist"
    ON supplement_stack_items FOR DELETE
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- PATIENT_SUPPLEMENT_LOGS POLICIES
-- ============================================================================

-- Patients can view their own logs + demo patient access
DROP POLICY IF EXISTS "patient_supplement_logs_select" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_select"
    ON patient_supplement_logs FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can insert their own logs
DROP POLICY IF EXISTS "patient_supplement_logs_insert" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_insert"
    ON patient_supplement_logs FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can update their own logs
DROP POLICY IF EXISTS "patient_supplement_logs_update" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_update"
    ON patient_supplement_logs FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can delete their own logs
DROP POLICY IF EXISTS "patient_supplement_logs_delete" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_delete"
    ON patient_supplement_logs FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Therapists can view their patients' logs
DROP POLICY IF EXISTS "patient_supplement_logs_therapist_select" ON patient_supplement_logs;
CREATE POLICY "patient_supplement_logs_therapist_select"
    ON patient_supplement_logs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = patient_supplement_logs.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- PATIENT_SUPPLEMENT_ROUTINES POLICIES
-- ============================================================================

-- Patients can view their own routines + demo patient access
DROP POLICY IF EXISTS "patient_supplement_routines_select" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_select"
    ON patient_supplement_routines FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can insert their own routines
DROP POLICY IF EXISTS "patient_supplement_routines_insert" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_insert"
    ON patient_supplement_routines FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can update their own routines
DROP POLICY IF EXISTS "patient_supplement_routines_update" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_update"
    ON patient_supplement_routines FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can delete their own routines
DROP POLICY IF EXISTS "patient_supplement_routines_delete" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_delete"
    ON patient_supplement_routines FOR DELETE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Therapists can view their patients' routines
DROP POLICY IF EXISTS "patient_supplement_routines_therapist_select" ON patient_supplement_routines;
CREATE POLICY "patient_supplement_routines_therapist_select"
    ON patient_supplement_routines FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = patient_supplement_routines.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- SUPPLEMENT_COMPLIANCE POLICIES
-- ============================================================================

-- Patients can view their own compliance + demo patient access
DROP POLICY IF EXISTS "supplement_compliance_select" ON supplement_compliance;
CREATE POLICY "supplement_compliance_select"
    ON supplement_compliance FOR SELECT
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can insert their own compliance records
DROP POLICY IF EXISTS "supplement_compliance_insert" ON supplement_compliance;
CREATE POLICY "supplement_compliance_insert"
    ON supplement_compliance FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Patients can update their own compliance
DROP POLICY IF EXISTS "supplement_compliance_update" ON supplement_compliance;
CREATE POLICY "supplement_compliance_update"
    ON supplement_compliance FOR UPDATE
    TO authenticated
    USING (
        patient_id = '00000000-0000-0000-0000-000000000001'::uuid
        OR patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE email = (auth.jwt() ->> 'email'))
    );

-- Therapists can view their patients' compliance
DROP POLICY IF EXISTS "supplement_compliance_therapist_select" ON supplement_compliance;
CREATE POLICY "supplement_compliance_therapist_select"
    ON supplement_compliance FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = supplement_compliance.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- GRANTS
-- ============================================================================

GRANT SELECT ON supplements TO authenticated;
GRANT SELECT ON supplement_stacks TO authenticated;
GRANT SELECT ON supplement_stack_items TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_routines TO authenticated;
GRANT SELECT, INSERT, UPDATE ON supplement_compliance TO authenticated;

-- ============================================================================
-- TRIGGERS FOR updated_at
-- ============================================================================

CREATE OR REPLACE FUNCTION update_supplements_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS supplements_updated_at ON supplements;
CREATE TRIGGER supplements_updated_at
    BEFORE UPDATE ON supplements
    FOR EACH ROW
    EXECUTE FUNCTION update_supplements_updated_at();

DROP TRIGGER IF EXISTS supplement_stacks_updated_at ON supplement_stacks;
CREATE TRIGGER supplement_stacks_updated_at
    BEFORE UPDATE ON supplement_stacks
    FOR EACH ROW
    EXECUTE FUNCTION update_supplements_updated_at();

DROP TRIGGER IF EXISTS supplement_stack_items_updated_at ON supplement_stack_items;
CREATE TRIGGER supplement_stack_items_updated_at
    BEFORE UPDATE ON supplement_stack_items
    FOR EACH ROW
    EXECUTE FUNCTION update_supplements_updated_at();

DROP TRIGGER IF EXISTS patient_supplement_logs_updated_at ON patient_supplement_logs;
CREATE TRIGGER patient_supplement_logs_updated_at
    BEFORE UPDATE ON patient_supplement_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_supplements_updated_at();

DROP TRIGGER IF EXISTS patient_supplement_routines_updated_at ON patient_supplement_routines;
CREATE TRIGGER patient_supplement_routines_updated_at
    BEFORE UPDATE ON patient_supplement_routines
    FOR EACH ROW
    EXECUTE FUNCTION update_supplements_updated_at();

DROP TRIGGER IF EXISTS supplement_compliance_updated_at ON supplement_compliance;
CREATE TRIGGER supplement_compliance_updated_at
    BEFORE UPDATE ON supplement_compliance
    FOR EACH ROW
    EXECUTE FUNCTION update_supplements_updated_at();

-- ============================================================================
-- HELPER FUNCTIONS
-- ============================================================================

-- Function to get patient's supplement routine for a specific day
CREATE OR REPLACE FUNCTION get_patient_supplement_routine(
    p_patient_id UUID,
    p_day_of_week INTEGER DEFAULT NULL
)
RETURNS TABLE (
    routine_id UUID,
    supplement_id UUID,
    supplement_name TEXT,
    supplement_category supplement_category,
    dose NUMERIC,
    dose_unit TEXT,
    timing supplement_timing_type,
    reminder_time TIME,
    stack_name TEXT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        psr.id AS routine_id,
        s.id AS supplement_id,
        s.name AS supplement_name,
        s.category AS supplement_category,
        psr.dose,
        psr.dose_unit,
        psr.timing,
        psr.reminder_time,
        ss.name AS stack_name
    FROM patient_supplement_routines psr
    JOIN supplements s ON s.id = psr.supplement_id
    LEFT JOIN supplement_stacks ss ON ss.id = psr.stack_id
    WHERE psr.patient_id = p_patient_id
    AND psr.is_active = true
    AND (p_day_of_week IS NULL OR p_day_of_week = ANY(psr.days_of_week))
    ORDER BY
        CASE psr.timing
            WHEN 'morning' THEN 1
            WHEN 'with_meal' THEN 2
            WHEN 'pre_workout' THEN 3
            WHEN 'afternoon' THEN 4
            WHEN 'post_workout' THEN 5
            WHEN 'evening' THEN 6
            WHEN 'before_bed' THEN 7
            ELSE 8
        END,
        s.name;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to calculate daily compliance
CREATE OR REPLACE FUNCTION calculate_supplement_compliance(
    p_patient_id UUID,
    p_date DATE DEFAULT CURRENT_DATE
)
RETURNS TABLE (
    planned INTEGER,
    taken INTEGER,
    compliance_pct NUMERIC
) AS $$
DECLARE
    v_day_of_week INTEGER;
    v_planned INTEGER;
    v_taken INTEGER;
BEGIN
    v_day_of_week := EXTRACT(DOW FROM p_date)::INTEGER;

    -- Count planned supplements for this day
    SELECT COUNT(*)::INTEGER INTO v_planned
    FROM patient_supplement_routines psr
    WHERE psr.patient_id = p_patient_id
    AND psr.is_active = true
    AND v_day_of_week = ANY(psr.days_of_week);

    -- Count taken supplements for this day
    SELECT COUNT(DISTINCT supplement_id)::INTEGER INTO v_taken
    FROM patient_supplement_logs psl
    WHERE psl.patient_id = p_patient_id
    AND DATE(psl.taken_at) = p_date;

    -- Return results
    RETURN QUERY SELECT
        v_planned,
        v_taken,
        CASE
            WHEN v_planned > 0 THEN ROUND((v_taken::NUMERIC / v_planned) * 100, 1)
            ELSE 0::NUMERIC
        END;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get supplement stack details
CREATE OR REPLACE FUNCTION get_supplement_stack_details(
    p_stack_id UUID
)
RETURNS TABLE (
    stack_id UUID,
    stack_name TEXT,
    stack_description TEXT,
    stack_goal TEXT,
    difficulty stack_difficulty,
    monthly_cost NUMERIC,
    supplement_id UUID,
    supplement_name TEXT,
    supplement_category supplement_category,
    dose NUMERIC,
    dose_unit TEXT,
    timing supplement_timing_type,
    is_required BOOLEAN,
    item_notes TEXT,
    evidence_rating supplement_evidence_rating,
    benefits JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ss.id AS stack_id,
        ss.name AS stack_name,
        ss.description AS stack_description,
        ss.goal AS stack_goal,
        ss.difficulty_level AS difficulty,
        ss.monthly_cost_estimate AS monthly_cost,
        s.id AS supplement_id,
        s.name AS supplement_name,
        s.category AS supplement_category,
        ssi.dose,
        ssi.dose_unit,
        ssi.timing,
        ssi.is_required,
        ssi.notes AS item_notes,
        s.evidence_rating,
        s.benefits
    FROM supplement_stacks ss
    JOIN supplement_stack_items ssi ON ssi.stack_id = ss.id
    JOIN supplements s ON s.id = ssi.supplement_id
    WHERE ss.id = p_stack_id
    AND ss.is_active = true
    AND s.is_active = true
    ORDER BY ssi.display_order, s.name;
END;
$$ LANGUAGE plpgsql STABLE;

-- Function to adopt a supplement stack for a patient
CREATE OR REPLACE FUNCTION adopt_supplement_stack(
    p_patient_id UUID,
    p_stack_id UUID
)
RETURNS INTEGER AS $$
DECLARE
    v_inserted INTEGER := 0;
    v_item RECORD;
BEGIN
    -- Insert routines for each supplement in the stack
    FOR v_item IN
        SELECT ssi.supplement_id, ssi.dose, ssi.dose_unit, ssi.timing
        FROM supplement_stack_items ssi
        WHERE ssi.stack_id = p_stack_id
    LOOP
        INSERT INTO patient_supplement_routines (
            patient_id,
            supplement_id,
            stack_id,
            dose,
            dose_unit,
            timing,
            is_active
        ) VALUES (
            p_patient_id,
            v_item.supplement_id,
            p_stack_id,
            v_item.dose,
            v_item.dose_unit,
            v_item.timing,
            true
        )
        ON CONFLICT (patient_id, supplement_id, timing)
        DO UPDATE SET
            dose = EXCLUDED.dose,
            dose_unit = EXCLUDED.dose_unit,
            stack_id = EXCLUDED.stack_id,
            is_active = true,
            updated_at = NOW();

        v_inserted := v_inserted + 1;
    END LOOP;

    RETURN v_inserted;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- SEED DATA - SUPPLEMENTS (only if brand column exists)
-- ============================================================================

-- Skip seed data if existing table doesn't have required columns
DO $$
BEGIN
    -- Only seed if brand column exists (new schema)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'supplements' AND column_name = 'brand') THEN
        -- Performance Supplements
        INSERT INTO supplements (name, brand, category, subcategory, description, benefits, typical_dose, dose_unit, timing_recommendation, evidence_rating, wada_status, price_estimate) VALUES
('Creatine Monohydrate', 'Thorne', 'performance', 'strength', 'Most researched performance supplement. Increases muscle phosphocreatine stores for improved strength and power output.', '["increased strength", "improved power output", "enhanced muscle recovery", "cognitive benefits"]', 5, 'g', 'any_time', 'strong', 'not_banned', 25.00),
('Beta-Alanine', 'NOW Sports', 'performance', 'endurance', 'Buffers muscle acidity during high-intensity exercise. Reduces fatigue and extends time to exhaustion.', '["reduced muscle fatigue", "improved endurance", "enhanced high-intensity performance"]', 3.2, 'g', 'pre_workout', 'strong', 'not_banned', 20.00),
('Caffeine', 'Nutricost', 'performance', 'energy', 'Central nervous system stimulant that enhances alertness, focus, and exercise performance.', '["increased alertness", "improved focus", "enhanced endurance", "increased fat oxidation"]', 200, 'mg', 'pre_workout', 'strong', 'not_banned', 15.00),
('Citrulline Malate', 'Transparent Labs', 'performance', 'pump', 'Increases nitric oxide production for improved blood flow. Reduces muscle soreness and fatigue.', '["improved blood flow", "reduced muscle soreness", "enhanced endurance", "better pumps"]', 6, 'g', 'pre_workout', 'moderate', 'not_banned', 30.00),
('HMB', 'Optimum Nutrition', 'performance', 'muscle', 'Metabolite of leucine that helps prevent muscle breakdown during intense training or caloric deficit.', '["reduced muscle breakdown", "improved recovery", "lean mass preservation"]', 3, 'g', 'with_meal', 'moderate', 'not_banned', 35.00),
('Sodium Bicarbonate', 'Arm & Hammer', 'performance', 'buffer', 'Buffers blood pH during high-intensity exercise. Delays fatigue in short, intense efforts.', '["delayed fatigue", "improved high-intensity performance", "enhanced power output"]', 0.3, 'g/kg', 'pre_workout', 'strong', 'not_banned', 5.00),
('Beetroot Powder', 'BeetElite', 'performance', 'endurance', 'Rich in nitrates that improve oxygen efficiency and endurance performance.', '["improved oxygen efficiency", "enhanced endurance", "reduced oxygen cost of exercise"]', 6, 'g', 'pre_workout', 'moderate', 'not_banned', 40.00)
ON CONFLICT (name, brand) DO NOTHING;

-- Recovery Supplements
INSERT INTO supplements (name, brand, category, subcategory, description, benefits, typical_dose, dose_unit, timing_recommendation, evidence_rating, wada_status, price_estimate) VALUES
('Omega-3 Fish Oil', 'Nordic Naturals', 'recovery', 'anti-inflammatory', 'Essential fatty acids EPA and DHA with powerful anti-inflammatory effects. Supports heart, brain, and joint health.', '["reduced inflammation", "improved joint health", "cardiovascular support", "brain health"]', 3, 'g', 'with_meal', 'strong', 'not_banned', 35.00),
('Tart Cherry Extract', 'Swanson', 'recovery', 'anti-inflammatory', 'Natural anti-inflammatory and antioxidant. Reduces muscle soreness and improves sleep quality.', '["reduced muscle soreness", "improved sleep", "antioxidant protection", "faster recovery"]', 500, 'mg', 'before_bed', 'moderate', 'not_banned', 20.00),
('Curcumin', 'Thorne Meriva', 'recovery', 'anti-inflammatory', 'Bioavailable turmeric extract with potent anti-inflammatory properties. Supports joint health and recovery.', '["reduced inflammation", "joint support", "antioxidant effects", "improved recovery"]', 500, 'mg', 'with_meal', 'moderate', 'not_banned', 40.00),
('Collagen Peptides', 'Vital Proteins', 'recovery', 'connective tissue', 'Supports tendon, ligament, and skin health. May improve joint comfort and recovery from connective tissue injuries.', '["joint health", "tendon support", "skin elasticity", "gut health"]', 15, 'g', 'morning', 'emerging', 'not_banned', 30.00),
('Glutamine', 'NOW Sports', 'recovery', 'muscle', 'Most abundant amino acid in muscle tissue. Supports immune function and gut health during intense training.', '["immune support", "gut health", "muscle recovery", "reduced soreness"]', 5, 'g', 'post_workout', 'emerging', 'not_banned', 25.00),
('Bromelain', 'NOW Foods', 'recovery', 'enzyme', 'Proteolytic enzyme from pineapple. Reduces inflammation and supports tissue repair.', '["reduced inflammation", "faster healing", "improved digestion"]', 500, 'mg', 'empty_stomach', 'emerging', 'not_banned', 15.00)
ON CONFLICT (name, brand) DO NOTHING;

-- Sleep Supplements
INSERT INTO supplements (name, brand, category, subcategory, description, benefits, typical_dose, dose_unit, timing_recommendation, evidence_rating, wada_status, price_estimate) VALUES
('Magnesium Glycinate', 'Pure Encapsulations', 'sleep', 'mineral', 'Highly bioavailable form of magnesium. Promotes relaxation, muscle recovery, and sleep quality.', '["improved sleep quality", "muscle relaxation", "stress reduction", "recovery support"]', 400, 'mg', 'before_bed', 'moderate', 'not_banned', 30.00),
('L-Theanine', 'Thorne', 'sleep', 'amino acid', 'Amino acid from tea that promotes calm alertness. Reduces anxiety without sedation and improves sleep quality.', '["reduced anxiety", "improved focus", "better sleep quality", "relaxation without drowsiness"]', 200, 'mg', 'before_bed', 'moderate', 'not_banned', 20.00),
('Apigenin', 'Double Wood', 'sleep', 'flavonoid', 'Flavonoid from chamomile that promotes relaxation and sleep. Works synergistically with magnesium and L-theanine.', '["improved sleep onset", "relaxation", "reduced anxiety"]', 50, 'mg', 'before_bed', 'emerging', 'not_banned', 25.00),
('Glycine', 'BulkSupplements', 'sleep', 'amino acid', 'Amino acid that lowers core body temperature and promotes deep sleep. Also supports cognitive function.', '["improved sleep quality", "lower body temperature", "enhanced cognitive function"]', 3, 'g', 'before_bed', 'moderate', 'not_banned', 15.00),
('Melatonin', 'Life Extension', 'sleep', 'hormone', 'Hormone that regulates circadian rhythm. Best for jet lag and shift work, not long-term use.', '["improved sleep onset", "circadian rhythm support", "jet lag relief"]', 0.5, 'mg', 'before_bed', 'strong', 'not_banned', 10.00),
('GABA', 'NOW Foods', 'sleep', 'neurotransmitter', 'Inhibitory neurotransmitter that promotes relaxation. May have limited blood-brain barrier penetration.', '["relaxation", "stress reduction", "improved sleep"]', 500, 'mg', 'before_bed', 'limited', 'not_banned', 15.00),
('Valerian Root', 'Gaia Herbs', 'sleep', 'herbal', 'Traditional herbal sleep aid. May improve sleep quality and reduce time to fall asleep.', '["improved sleep", "reduced sleep latency", "relaxation"]', 450, 'mg', 'before_bed', 'emerging', 'not_banned', 20.00)
ON CONFLICT (name, brand) DO NOTHING;

-- Health/Foundation Supplements
INSERT INTO supplements (name, brand, category, subcategory, description, benefits, typical_dose, dose_unit, timing_recommendation, evidence_rating, wada_status, price_estimate) VALUES
('Vitamin D3', 'Thorne', 'health', 'vitamin', 'Essential for bone health, immune function, and hormonal balance. Most people are deficient.', '["bone health", "immune support", "hormonal balance", "mood support"]', 5000, 'IU', 'morning', 'strong', 'not_banned', 15.00),
('Vitamin K2 MK-7', 'Life Extension', 'health', 'vitamin', 'Directs calcium to bones and away from arteries. Essential companion to vitamin D3.', '["bone health", "cardiovascular support", "calcium metabolism"]', 100, 'mcg', 'morning', 'moderate', 'not_banned', 20.00),
('B Complex', 'Thorne Basic B', 'health', 'vitamin', 'Essential B vitamins for energy metabolism, nervous system function, and methylation.', '["energy production", "nervous system support", "methylation support"]', 1, 'capsule', 'morning', 'strong', 'not_banned', 25.00),
('Zinc Picolinate', 'Thorne', 'health', 'mineral', 'Essential mineral for immune function, testosterone production, and wound healing.', '["immune support", "testosterone support", "wound healing", "skin health"]', 30, 'mg', 'with_meal', 'moderate', 'not_banned', 15.00),
('Ashwagandha KSM-66', 'Nootropics Depot', 'health', 'adaptogen', 'Adaptogen that reduces cortisol, supports testosterone, and improves stress resilience.', '["stress reduction", "cortisol control", "testosterone support", "improved sleep"]', 600, 'mg', 'evening', 'moderate', 'not_banned', 25.00),
('Probiotics', 'Seed DS-01', 'health', 'gut', 'Multi-strain probiotic for gut health, immune function, and nutrient absorption.', '["gut health", "immune support", "improved digestion", "nutrient absorption"]', 2, 'capsules', 'morning', 'moderate', 'not_banned', 50.00),
('Vitamin C', 'Thorne', 'health', 'vitamin', 'Essential antioxidant for immune function, collagen synthesis, and iron absorption.', '["immune support", "antioxidant protection", "collagen synthesis"]', 1000, 'mg', 'with_meal', 'strong', 'not_banned', 15.00),
('Selenium', 'Life Extension', 'health', 'mineral', 'Essential trace mineral for thyroid function, antioxidant protection, and immune health.', '["thyroid support", "antioxidant protection", "immune function"]', 200, 'mcg', 'with_meal', 'moderate', 'not_banned', 10.00)
ON CONFLICT (name, brand) DO NOTHING;

-- Cognitive Supplements
INSERT INTO supplements (name, brand, category, subcategory, description, benefits, typical_dose, dose_unit, timing_recommendation, evidence_rating, wada_status, price_estimate) VALUES
('Alpha-GPC', 'Nootropics Depot', 'cognitive', 'choline', 'Highly bioavailable choline source. Enhances focus, memory, and mind-muscle connection.', '["improved focus", "enhanced memory", "better mind-muscle connection"]', 300, 'mg', 'morning', 'moderate', 'not_banned', 30.00),
('Lions Mane', 'Real Mushrooms', 'cognitive', 'mushroom', 'Medicinal mushroom that supports nerve growth factor (NGF). May improve cognitive function and mood.', '["cognitive enhancement", "nerve health", "mood support"]', 1000, 'mg', 'morning', 'emerging', 'not_banned', 35.00),
('Rhodiola Rosea', 'Nootropics Depot', 'cognitive', 'adaptogen', 'Adaptogen that reduces mental fatigue and improves focus during stress.', '["reduced mental fatigue", "improved focus", "stress resilience"]', 300, 'mg', 'morning', 'moderate', 'not_banned', 20.00),
('Phosphatidylserine', 'Jarrow Formulas', 'cognitive', 'phospholipid', 'Phospholipid that supports brain cell membrane health and cognitive function.', '["memory support", "cognitive function", "cortisol reduction"]', 100, 'mg', 'morning', 'moderate', 'not_banned', 30.00),
('Bacopa Monnieri', 'Nootropics Depot', 'cognitive', 'herbal', 'Ayurvedic herb that improves memory formation and reduces anxiety.', '["improved memory", "reduced anxiety", "cognitive enhancement"]', 300, 'mg', 'with_meal', 'moderate', 'not_banned', 20.00)
ON CONFLICT (name, brand) DO NOTHING;

-- Joint Supplements
INSERT INTO supplements (name, brand, category, subcategory, description, benefits, typical_dose, dose_unit, timing_recommendation, evidence_rating, wada_status, price_estimate) VALUES
('Glucosamine Sulfate', 'Thorne', 'joint', 'structural', 'Building block for cartilage. May slow joint degeneration and reduce pain.', '["joint support", "cartilage health", "reduced joint pain"]', 1500, 'mg', 'with_meal', 'moderate', 'not_banned', 25.00),
('Chondroitin', 'NOW Foods', 'joint', 'structural', 'Component of cartilage that provides cushioning. Often combined with glucosamine.', '["cartilage support", "joint cushioning", "reduced stiffness"]', 1200, 'mg', 'with_meal', 'moderate', 'not_banned', 25.00),
('MSM', 'Doctor Best', 'joint', 'sulfur', 'Organic sulfur compound that supports connective tissue and reduces inflammation.', '["reduced inflammation", "connective tissue support", "joint comfort"]', 3000, 'mg', 'with_meal', 'emerging', 'not_banned', 15.00),
('Boswellia', 'Life Extension', 'joint', 'herbal', 'Herbal extract with potent anti-inflammatory effects. Supports joint comfort and mobility.', '["reduced inflammation", "joint comfort", "improved mobility"]', 300, 'mg', 'with_meal', 'moderate', 'not_banned', 20.00),
('Hyaluronic Acid', 'NOW Foods', 'joint', 'structural', 'Lubricates joints and supports skin hydration. May improve joint comfort.', '["joint lubrication", "skin hydration", "joint comfort"]', 200, 'mg', 'with_meal', 'emerging', 'not_banned', 20.00),
('UC-II Collagen', 'Life Extension', 'joint', 'collagen', 'Undenatured type II collagen that supports joint immune response and comfort.', '["joint comfort", "immune modulation", "cartilage support"]', 40, 'mg', 'empty_stomach', 'moderate', 'not_banned', 35.00)
ON CONFLICT (name, brand) DO NOTHING;

-- ============================================================================
-- SEED DATA - SUPPLEMENT STACKS
-- ============================================================================

INSERT INTO supplement_stacks (name, description, goal, difficulty_level, monthly_cost_estimate, source, is_featured) VALUES
('Huberman Sleep Stack', 'Dr. Andrew Huberman''s recommended sleep optimization protocol. Promotes deep, restorative sleep without grogginess.', 'sleep', 'beginner', 75.00, 'Huberman Lab Podcast', true),
('Athletic Recovery Stack', 'Comprehensive recovery protocol for serious athletes. Reduces inflammation, supports tissue repair, and accelerates recovery.', 'recovery', 'intermediate', 120.00, 'PT Performance', true),
('Foundational Health Stack', 'Essential supplements for optimal health and performance. Covers common nutritional gaps.', 'health', 'beginner', 85.00, 'PT Performance', true),
('Pre-Workout Performance Stack', 'Science-backed pre-workout stack for maximum performance. Enhances strength, endurance, and focus.', 'performance', 'intermediate', 70.00, 'PT Performance', true),
('Cognitive Performance Stack', 'Nootropic stack for enhanced focus, memory, and mental clarity.', 'cognitive', 'intermediate', 95.00, 'PT Performance', false),
('Joint Health Stack', 'Comprehensive joint support for athletes with heavy training loads.', 'joint', 'beginner', 85.00, 'PT Performance', false),
('Stress & Cortisol Stack', 'Adaptogenic stack for managing stress and optimizing cortisol levels.', 'hormonal', 'beginner', 65.00, 'PT Performance', false),
('Testosterone Support Stack', 'Natural support for healthy testosterone levels through optimizing key nutrients.', 'hormonal', 'intermediate', 70.00, 'PT Performance', false)
ON CONFLICT (name) DO NOTHING;

-- ============================================================================
-- SEED DATA - SUPPLEMENT STACK ITEMS
-- ============================================================================

-- Huberman Sleep Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Magnesium Glycinate' THEN 400
        WHEN 'L-Theanine' THEN 200
        WHEN 'Apigenin' THEN 50
        WHEN 'Glycine' THEN 2000
    END,
    CASE s.name
        WHEN 'Glycine' THEN 'mg'
        ELSE 'mg'
    END,
    'before_bed'::supplement_timing_type,
    CASE s.name
        WHEN 'Magnesium Glycinate' THEN true
        WHEN 'L-Theanine' THEN true
        WHEN 'Apigenin' THEN true
        WHEN 'Glycine' THEN false
    END,
    CASE s.name
        WHEN 'Magnesium Glycinate' THEN 'Take 30-60 minutes before bed'
        WHEN 'L-Theanine' THEN 'Promotes relaxation without sedation'
        WHEN 'Apigenin' THEN 'Derived from chamomile'
        WHEN 'Glycine' THEN 'Optional - helps lower body temperature'
    END,
    CASE s.name
        WHEN 'Magnesium Glycinate' THEN 1
        WHEN 'L-Theanine' THEN 2
        WHEN 'Apigenin' THEN 3
        WHEN 'Glycine' THEN 4
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Huberman Sleep Stack'
AND s.name IN ('Magnesium Glycinate', 'L-Theanine', 'Apigenin', 'Glycine')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Athletic Recovery Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Omega-3 Fish Oil' THEN 3000
        WHEN 'Tart Cherry Extract' THEN 500
        WHEN 'Curcumin' THEN 500
        WHEN 'Collagen Peptides' THEN 15000
        WHEN 'Magnesium Glycinate' THEN 400
    END,
    'mg',
    CASE s.name
        WHEN 'Omega-3 Fish Oil' THEN 'with_meal'
        WHEN 'Tart Cherry Extract' THEN 'before_bed'
        WHEN 'Curcumin' THEN 'with_meal'
        WHEN 'Collagen Peptides' THEN 'morning'
        WHEN 'Magnesium Glycinate' THEN 'before_bed'
    END::supplement_timing_type,
    true,
    NULL,
    CASE s.name
        WHEN 'Omega-3 Fish Oil' THEN 1
        WHEN 'Tart Cherry Extract' THEN 2
        WHEN 'Curcumin' THEN 3
        WHEN 'Collagen Peptides' THEN 4
        WHEN 'Magnesium Glycinate' THEN 5
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Athletic Recovery Stack'
AND s.name IN ('Omega-3 Fish Oil', 'Tart Cherry Extract', 'Curcumin', 'Collagen Peptides', 'Magnesium Glycinate')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Foundational Health Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Vitamin D3' THEN 5000
        WHEN 'Vitamin K2 MK-7' THEN 100
        WHEN 'Omega-3 Fish Oil' THEN 3000
        WHEN 'Magnesium Glycinate' THEN 400
        WHEN 'Zinc Picolinate' THEN 30
    END,
    CASE s.name
        WHEN 'Vitamin D3' THEN 'IU'
        WHEN 'Vitamin K2 MK-7' THEN 'mcg'
        ELSE 'mg'
    END,
    CASE s.name
        WHEN 'Magnesium Glycinate' THEN 'before_bed'
        ELSE 'morning'
    END::supplement_timing_type,
    CASE s.name
        WHEN 'Vitamin D3' THEN true
        WHEN 'Omega-3 Fish Oil' THEN true
        WHEN 'Magnesium Glycinate' THEN true
        ELSE false
    END,
    CASE s.name
        WHEN 'Vitamin D3' THEN 'Take with fat for absorption'
        WHEN 'Vitamin K2 MK-7' THEN 'Take together with D3'
        WHEN 'Omega-3 Fish Oil' THEN 'Split dose if desired'
        ELSE NULL
    END,
    CASE s.name
        WHEN 'Vitamin D3' THEN 1
        WHEN 'Vitamin K2 MK-7' THEN 2
        WHEN 'Omega-3 Fish Oil' THEN 3
        WHEN 'Magnesium Glycinate' THEN 4
        WHEN 'Zinc Picolinate' THEN 5
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Foundational Health Stack'
AND s.name IN ('Vitamin D3', 'Vitamin K2 MK-7', 'Omega-3 Fish Oil', 'Magnesium Glycinate', 'Zinc Picolinate')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Pre-Workout Performance Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Caffeine' THEN 200
        WHEN 'Citrulline Malate' THEN 6000
        WHEN 'Beta-Alanine' THEN 3200
        WHEN 'Creatine Monohydrate' THEN 5000
    END,
    'mg',
    'pre_workout'::supplement_timing_type,
    CASE s.name
        WHEN 'Caffeine' THEN false
        WHEN 'Creatine Monohydrate' THEN true
        ELSE true
    END,
    CASE s.name
        WHEN 'Caffeine' THEN 'Adjust dose based on tolerance - optional'
        WHEN 'Citrulline Malate' THEN 'Take 30-45 minutes before training'
        WHEN 'Beta-Alanine' THEN 'May cause tingling (paresthesia) - harmless'
        WHEN 'Creatine Monohydrate' THEN 'Can take any time - timing not critical'
    END,
    CASE s.name
        WHEN 'Caffeine' THEN 1
        WHEN 'Citrulline Malate' THEN 2
        WHEN 'Beta-Alanine' THEN 3
        WHEN 'Creatine Monohydrate' THEN 4
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Pre-Workout Performance Stack'
AND s.name IN ('Caffeine', 'Citrulline Malate', 'Beta-Alanine', 'Creatine Monohydrate')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Cognitive Performance Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Alpha-GPC' THEN 300
        WHEN 'Lions Mane' THEN 1000
        WHEN 'Rhodiola Rosea' THEN 300
        WHEN 'Caffeine' THEN 100
        WHEN 'L-Theanine' THEN 200
    END,
    'mg',
    CASE s.name
        WHEN 'Lions Mane' THEN 'with_meal'
        ELSE 'morning'
    END::supplement_timing_type,
    CASE s.name
        WHEN 'Alpha-GPC' THEN true
        WHEN 'Lions Mane' THEN true
        ELSE false
    END,
    CASE s.name
        WHEN 'Alpha-GPC' THEN 'Best taken on empty stomach'
        WHEN 'Lions Mane' THEN 'Take consistently for 4+ weeks for full effect'
        WHEN 'Caffeine' THEN '2:1 ratio with L-Theanine for smooth focus'
        WHEN 'L-Theanine' THEN 'Synergistic with caffeine'
        ELSE NULL
    END,
    CASE s.name
        WHEN 'Alpha-GPC' THEN 1
        WHEN 'Lions Mane' THEN 2
        WHEN 'Rhodiola Rosea' THEN 3
        WHEN 'Caffeine' THEN 4
        WHEN 'L-Theanine' THEN 5
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Cognitive Performance Stack'
AND s.name IN ('Alpha-GPC', 'Lions Mane', 'Rhodiola Rosea', 'Caffeine', 'L-Theanine')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Joint Health Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Glucosamine Sulfate' THEN 1500
        WHEN 'Chondroitin' THEN 1200
        WHEN 'MSM' THEN 3000
        WHEN 'Omega-3 Fish Oil' THEN 3000
        WHEN 'Collagen Peptides' THEN 10000
    END,
    'mg',
    CASE s.name
        WHEN 'Collagen Peptides' THEN 'morning'
        ELSE 'with_meal'
    END::supplement_timing_type,
    CASE s.name
        WHEN 'Glucosamine Sulfate' THEN true
        WHEN 'Omega-3 Fish Oil' THEN true
        WHEN 'Collagen Peptides' THEN true
        ELSE false
    END,
    CASE s.name
        WHEN 'Glucosamine Sulfate' THEN 'Can split into 2-3 doses'
        WHEN 'Collagen Peptides' THEN 'Take with vitamin C for best absorption'
        ELSE NULL
    END,
    CASE s.name
        WHEN 'Glucosamine Sulfate' THEN 1
        WHEN 'Chondroitin' THEN 2
        WHEN 'MSM' THEN 3
        WHEN 'Omega-3 Fish Oil' THEN 4
        WHEN 'Collagen Peptides' THEN 5
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Joint Health Stack'
AND s.name IN ('Glucosamine Sulfate', 'Chondroitin', 'MSM', 'Omega-3 Fish Oil', 'Collagen Peptides')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Stress & Cortisol Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Ashwagandha KSM-66' THEN 600
        WHEN 'Rhodiola Rosea' THEN 300
        WHEN 'Magnesium Glycinate' THEN 400
        WHEN 'L-Theanine' THEN 200
    END,
    'mg',
    CASE s.name
        WHEN 'Ashwagandha KSM-66' THEN 'evening'
        WHEN 'Rhodiola Rosea' THEN 'morning'
        WHEN 'Magnesium Glycinate' THEN 'before_bed'
        WHEN 'L-Theanine' THEN 'afternoon'
    END::supplement_timing_type,
    CASE s.name
        WHEN 'Ashwagandha KSM-66' THEN true
        WHEN 'Magnesium Glycinate' THEN true
        ELSE false
    END,
    CASE s.name
        WHEN 'Ashwagandha KSM-66' THEN 'Cycle 8 weeks on, 2 weeks off'
        WHEN 'Rhodiola Rosea' THEN 'Best on empty stomach'
        ELSE NULL
    END,
    CASE s.name
        WHEN 'Ashwagandha KSM-66' THEN 1
        WHEN 'Rhodiola Rosea' THEN 2
        WHEN 'Magnesium Glycinate' THEN 3
        WHEN 'L-Theanine' THEN 4
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Stress & Cortisol Stack'
AND s.name IN ('Ashwagandha KSM-66', 'Rhodiola Rosea', 'Magnesium Glycinate', 'L-Theanine')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

-- Testosterone Support Stack
INSERT INTO supplement_stack_items (stack_id, supplement_id, dose, dose_unit, timing, is_required, notes, display_order)
SELECT
    ss.id,
    s.id,
    CASE s.name
        WHEN 'Vitamin D3' THEN 5000
        WHEN 'Zinc Picolinate' THEN 30
        WHEN 'Magnesium Glycinate' THEN 400
        WHEN 'Ashwagandha KSM-66' THEN 600
        WHEN 'Omega-3 Fish Oil' THEN 3000
    END,
    CASE s.name
        WHEN 'Vitamin D3' THEN 'IU'
        ELSE 'mg'
    END,
    CASE s.name
        WHEN 'Vitamin D3' THEN 'morning'
        WHEN 'Zinc Picolinate' THEN 'with_meal'
        WHEN 'Magnesium Glycinate' THEN 'before_bed'
        WHEN 'Ashwagandha KSM-66' THEN 'evening'
        WHEN 'Omega-3 Fish Oil' THEN 'with_meal'
    END::supplement_timing_type,
    true,
    CASE s.name
        WHEN 'Vitamin D3' THEN 'Optimize levels to 50-80 ng/mL'
        WHEN 'Zinc Picolinate' THEN 'Don''t exceed 40mg daily long-term'
        WHEN 'Ashwagandha KSM-66' THEN 'Shown to increase T by ~15% in studies'
        ELSE NULL
    END,
    CASE s.name
        WHEN 'Vitamin D3' THEN 1
        WHEN 'Zinc Picolinate' THEN 2
        WHEN 'Magnesium Glycinate' THEN 3
        WHEN 'Ashwagandha KSM-66' THEN 4
        WHEN 'Omega-3 Fish Oil' THEN 5
    END
FROM supplement_stacks ss
CROSS JOIN supplements s
WHERE ss.name = 'Testosterone Support Stack'
AND s.name IN ('Vitamin D3', 'Zinc Picolinate', 'Magnesium Glycinate', 'Ashwagandha KSM-66', 'Omega-3 Fish Oil')
ON CONFLICT (stack_id, supplement_id) DO NOTHING;

    END IF;  -- End of brand column check
END $$;

-- ============================================================================
-- VIEWS
-- ============================================================================

-- View for daily supplement schedule
CREATE OR REPLACE VIEW vw_patient_supplement_schedule AS
SELECT
    psr.patient_id,
    psr.id AS routine_id,
    s.id AS supplement_id,
    s.name AS supplement_name,
    s.category,
    psr.dose,
    psr.dose_unit,
    psr.timing,
    psr.reminder_time,
    psr.days_of_week,
    ss.name AS stack_name,
    s.evidence_rating,
    s.benefits
FROM patient_supplement_routines psr
JOIN supplements s ON s.id = psr.supplement_id
LEFT JOIN supplement_stacks ss ON ss.id = psr.stack_id
WHERE psr.is_active = true
AND s.is_active = true
ORDER BY
    CASE psr.timing
        WHEN 'morning' THEN 1
        WHEN 'with_meal' THEN 2
        WHEN 'pre_workout' THEN 3
        WHEN 'afternoon' THEN 4
        WHEN 'post_workout' THEN 5
        WHEN 'evening' THEN 6
        WHEN 'before_bed' THEN 7
        ELSE 8
    END;

COMMENT ON VIEW vw_patient_supplement_schedule IS 'Patient supplement schedule with timing and details';

-- View for compliance summary
CREATE OR REPLACE VIEW vw_supplement_compliance_summary AS
SELECT
    patient_id,
    date,
    planned_supplements,
    taken_supplements,
    compliance_rate,
    CASE
        WHEN compliance_rate >= 90 THEN 'excellent'
        WHEN compliance_rate >= 70 THEN 'good'
        WHEN compliance_rate >= 50 THEN 'moderate'
        ELSE 'low'
    END AS compliance_tier
FROM supplement_compliance
ORDER BY date DESC;

COMMENT ON VIEW vw_supplement_compliance_summary IS 'Supplement compliance with tier classification';

COMMIT;
