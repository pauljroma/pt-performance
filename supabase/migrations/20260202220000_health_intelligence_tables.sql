-- ============================================================================
-- HEALTH INTELLIGENCE TABLES MIGRATION
-- ============================================================================
-- Creates tables for lab results, biomarkers, recovery protocols, fasting,
-- and supplement tracking for the health intelligence features.
--
-- Date: 2026-02-02
-- ============================================================================

BEGIN;

-- ============================================================================
-- CUSTOM TYPES (ENUMS)
-- ============================================================================

-- Lab provider enum
DO $$ BEGIN
    CREATE TYPE lab_provider AS ENUM ('quest', 'labcorp', 'other');
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Recovery session type enum
DO $$ BEGIN
    CREATE TYPE recovery_session_type AS ENUM (
        'sauna_traditional',
        'sauna_infrared',
        'sauna_steam',
        'cold_plunge',
        'cold_shower',
        'ice_bath',
        'contrast'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- Supplement timing enum
DO $$ BEGIN
    CREATE TYPE supplement_timing AS ENUM (
        'morning',
        'afternoon',
        'evening',
        'pre_workout',
        'post_workout',
        'with_meal',
        'before_bed'
    );
EXCEPTION
    WHEN duplicate_object THEN NULL;
END $$;

-- ============================================================================
-- LAB RESULTS TABLES
-- ============================================================================

-- Main lab results table
CREATE TABLE IF NOT EXISTS lab_results (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    test_date DATE NOT NULL,
    provider lab_provider NOT NULL DEFAULT 'other',
    pdf_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE lab_results IS 'Lab test results from various providers (Quest, LabCorp, etc.)';
COMMENT ON COLUMN lab_results.patient_id IS 'Patient who received the lab test';
COMMENT ON COLUMN lab_results.test_date IS 'Date the lab test was performed';
COMMENT ON COLUMN lab_results.provider IS 'Lab provider (quest, labcorp, other)';
COMMENT ON COLUMN lab_results.pdf_url IS 'URL to the PDF of the lab results';
COMMENT ON COLUMN lab_results.notes IS 'Notes about the lab results';

-- Biomarker values from lab results
CREATE TABLE IF NOT EXISTS biomarker_values (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lab_result_id UUID NOT NULL REFERENCES lab_results(id) ON DELETE CASCADE,
    biomarker_type TEXT NOT NULL,
    value NUMERIC NOT NULL,
    unit TEXT NOT NULL,
    is_flagged BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE biomarker_values IS 'Individual biomarker values extracted from lab results';
COMMENT ON COLUMN biomarker_values.lab_result_id IS 'Reference to the parent lab result';
COMMENT ON COLUMN biomarker_values.biomarker_type IS 'Type of biomarker (e.g., testosterone_total, vitamin_d)';
COMMENT ON COLUMN biomarker_values.value IS 'Measured value of the biomarker';
COMMENT ON COLUMN biomarker_values.unit IS 'Unit of measurement (e.g., ng/dL, ng/mL)';
COMMENT ON COLUMN biomarker_values.is_flagged IS 'Whether the value is outside normal range';

-- Reference ranges for biomarkers
CREATE TABLE IF NOT EXISTS biomarker_reference_ranges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    biomarker_type TEXT NOT NULL UNIQUE,
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    optimal_low NUMERIC,
    optimal_high NUMERIC,
    normal_low NUMERIC,
    normal_high NUMERIC,
    unit TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE biomarker_reference_ranges IS 'Reference ranges for biomarkers (optimal and normal ranges)';
COMMENT ON COLUMN biomarker_reference_ranges.biomarker_type IS 'Unique identifier for the biomarker type';
COMMENT ON COLUMN biomarker_reference_ranges.name IS 'Human-readable name of the biomarker';
COMMENT ON COLUMN biomarker_reference_ranges.category IS 'Category of biomarker (hormones, vitamins, inflammation, etc.)';
COMMENT ON COLUMN biomarker_reference_ranges.optimal_low IS 'Lower bound of optimal range';
COMMENT ON COLUMN biomarker_reference_ranges.optimal_high IS 'Upper bound of optimal range';
COMMENT ON COLUMN biomarker_reference_ranges.normal_low IS 'Lower bound of normal range';
COMMENT ON COLUMN biomarker_reference_ranges.normal_high IS 'Upper bound of normal range';

-- Indexes for lab results
CREATE INDEX IF NOT EXISTS idx_lab_results_patient_id ON lab_results(patient_id);
CREATE INDEX IF NOT EXISTS idx_lab_results_test_date ON lab_results(test_date DESC);
CREATE INDEX IF NOT EXISTS idx_lab_results_patient_date ON lab_results(patient_id, test_date DESC);
CREATE INDEX IF NOT EXISTS idx_biomarker_values_lab_result_id ON biomarker_values(lab_result_id);
CREATE INDEX IF NOT EXISTS idx_biomarker_values_type ON biomarker_values(biomarker_type);
CREATE INDEX IF NOT EXISTS idx_biomarker_reference_ranges_type ON biomarker_reference_ranges(biomarker_type);
CREATE INDEX IF NOT EXISTS idx_biomarker_reference_ranges_category ON biomarker_reference_ranges(category);

-- ============================================================================
-- RECOVERY PROTOCOL TABLES
-- ============================================================================

-- Recovery sessions (patient log entries)
CREATE TABLE IF NOT EXISTS recovery_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    session_type recovery_session_type NOT NULL,
    duration_minutes INTEGER NOT NULL CHECK (duration_minutes > 0),
    temperature_f NUMERIC(5,1),
    notes TEXT,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE recovery_sessions IS 'Patient-logged recovery sessions (sauna, cold plunge, etc.)';
COMMENT ON COLUMN recovery_sessions.session_type IS 'Type of recovery session';
COMMENT ON COLUMN recovery_sessions.duration_minutes IS 'Duration of the session in minutes';
COMMENT ON COLUMN recovery_sessions.temperature_f IS 'Temperature in Fahrenheit (if applicable)';
COMMENT ON COLUMN recovery_sessions.logged_at IS 'When the session was performed';

-- Recovery protocols (templates/recommendations)
CREATE TABLE IF NOT EXISTS recovery_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    description TEXT,
    phases JSONB NOT NULL DEFAULT '[]'::jsonb,
    recommended_frequency TEXT,
    created_by UUID REFERENCES patients(id) ON DELETE SET NULL,
    is_public BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE recovery_protocols IS 'Recovery protocol templates with phases and recommendations';
COMMENT ON COLUMN recovery_protocols.name IS 'Name of the protocol';
COMMENT ON COLUMN recovery_protocols.description IS 'Description of the protocol and its benefits';
COMMENT ON COLUMN recovery_protocols.phases IS 'JSONB array of phases with duration, type, temperature, etc.';
COMMENT ON COLUMN recovery_protocols.recommended_frequency IS 'How often to perform the protocol (e.g., 3x per week)';
COMMENT ON COLUMN recovery_protocols.created_by IS 'User who created the protocol (null for system protocols)';
COMMENT ON COLUMN recovery_protocols.is_public IS 'Whether the protocol is visible to all users';

-- Indexes for recovery tables
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_patient_id ON recovery_sessions(patient_id);
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_logged_at ON recovery_sessions(logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_patient_logged ON recovery_sessions(patient_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_recovery_sessions_type ON recovery_sessions(session_type);
CREATE INDEX IF NOT EXISTS idx_recovery_protocols_public ON recovery_protocols(is_public) WHERE is_public = true;
CREATE INDEX IF NOT EXISTS idx_recovery_protocols_created_by ON recovery_protocols(created_by);

-- ============================================================================
-- FASTING TABLES
-- ============================================================================

-- Fasting protocols (templates)
CREATE TABLE IF NOT EXISTS fasting_protocols (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    eating_window_hours INTEGER NOT NULL CHECK (eating_window_hours >= 0 AND eating_window_hours <= 24),
    fasting_hours INTEGER NOT NULL CHECK (fasting_hours >= 0 AND fasting_hours <= 168),
    description TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE fasting_protocols IS 'Fasting protocol templates (16:8, OMAD, etc.)';
COMMENT ON COLUMN fasting_protocols.eating_window_hours IS 'Hours per day for eating window';
COMMENT ON COLUMN fasting_protocols.fasting_hours IS 'Hours of fasting in the protocol';

-- Fasting logs (patient entries)
CREATE TABLE IF NOT EXISTS fasting_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ NOT NULL,
    ended_at TIMESTAMPTZ,
    planned_hours INTEGER NOT NULL CHECK (planned_hours > 0),
    actual_hours NUMERIC(5,2),
    protocol_type TEXT,
    notes TEXT,
    completed BOOLEAN NOT NULL DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE fasting_logs IS 'Patient-logged fasting sessions';
COMMENT ON COLUMN fasting_logs.started_at IS 'When the fast started';
COMMENT ON COLUMN fasting_logs.ended_at IS 'When the fast ended (null if ongoing)';
COMMENT ON COLUMN fasting_logs.planned_hours IS 'Planned fasting duration in hours';
COMMENT ON COLUMN fasting_logs.actual_hours IS 'Actual fasting duration in hours';
COMMENT ON COLUMN fasting_logs.protocol_type IS 'Type of fasting protocol followed';
COMMENT ON COLUMN fasting_logs.completed IS 'Whether the fast was completed as planned';

-- Indexes for fasting tables
CREATE INDEX IF NOT EXISTS idx_fasting_logs_patient_id ON fasting_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_fasting_logs_started_at ON fasting_logs(started_at DESC);
CREATE INDEX IF NOT EXISTS idx_fasting_logs_patient_started ON fasting_logs(patient_id, started_at DESC);
CREATE INDEX IF NOT EXISTS idx_fasting_logs_completed ON fasting_logs(completed);
CREATE INDEX IF NOT EXISTS idx_fasting_protocols_name ON fasting_protocols(name);

-- ============================================================================
-- SUPPLEMENT TABLES
-- ============================================================================

-- Supplements catalog
CREATE TABLE IF NOT EXISTS supplements (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    category TEXT NOT NULL,
    description TEXT,
    evidence_rating INTEGER NOT NULL CHECK (evidence_rating >= 1 AND evidence_rating <= 5),
    dosage_info TEXT,
    timing_recommendation TEXT,
    interactions JSONB DEFAULT '[]'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE supplements IS 'Supplement catalog with evidence ratings and information';
COMMENT ON COLUMN supplements.name IS 'Name of the supplement';
COMMENT ON COLUMN supplements.category IS 'Category (vitamins, minerals, amino acids, herbs, etc.)';
COMMENT ON COLUMN supplements.evidence_rating IS 'Evidence rating (1=minimal, 5=strong evidence)';
COMMENT ON COLUMN supplements.dosage_info IS 'Recommended dosage information';
COMMENT ON COLUMN supplements.timing_recommendation IS 'When to take the supplement';
COMMENT ON COLUMN supplements.interactions IS 'JSONB array of known interactions';

-- Supplement logs (individual doses taken)
CREATE TABLE IF NOT EXISTS supplement_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    supplement_id UUID NOT NULL REFERENCES supplements(id) ON DELETE CASCADE,
    dosage NUMERIC NOT NULL CHECK (dosage > 0),
    dosage_unit TEXT NOT NULL,
    timing supplement_timing NOT NULL,
    logged_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE supplement_logs IS 'Patient-logged supplement doses';
COMMENT ON COLUMN supplement_logs.supplement_id IS 'Reference to the supplement taken';
COMMENT ON COLUMN supplement_logs.dosage IS 'Amount taken';
COMMENT ON COLUMN supplement_logs.dosage_unit IS 'Unit of dosage (mg, g, IU, etc.)';
COMMENT ON COLUMN supplement_logs.timing IS 'When the supplement was taken';
COMMENT ON COLUMN supplement_logs.logged_at IS 'When the dose was logged';

-- Patient supplement stacks (ongoing regimen)
CREATE TABLE IF NOT EXISTS patient_supplement_stacks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    supplement_id UUID NOT NULL REFERENCES supplements(id) ON DELETE CASCADE,
    dosage NUMERIC NOT NULL CHECK (dosage > 0),
    dosage_unit TEXT NOT NULL,
    frequency TEXT NOT NULL,
    timing supplement_timing NOT NULL,
    is_active BOOLEAN NOT NULL DEFAULT true,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    ended_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(patient_id, supplement_id) WHERE is_active = true
);

COMMENT ON TABLE patient_supplement_stacks IS 'Patient ongoing supplement regimens';
COMMENT ON COLUMN patient_supplement_stacks.dosage IS 'Standard dosage amount';
COMMENT ON COLUMN patient_supplement_stacks.dosage_unit IS 'Unit of dosage (mg, g, IU, etc.)';
COMMENT ON COLUMN patient_supplement_stacks.frequency IS 'How often to take (daily, twice daily, etc.)';
COMMENT ON COLUMN patient_supplement_stacks.timing IS 'When to take the supplement';
COMMENT ON COLUMN patient_supplement_stacks.is_active IS 'Whether currently taking this supplement';
COMMENT ON COLUMN patient_supplement_stacks.started_at IS 'When the patient started this supplement';

-- Indexes for supplement tables
CREATE INDEX IF NOT EXISTS idx_supplements_category ON supplements(category);
CREATE INDEX IF NOT EXISTS idx_supplements_evidence ON supplements(evidence_rating DESC);
CREATE INDEX IF NOT EXISTS idx_supplement_logs_patient_id ON supplement_logs(patient_id);
CREATE INDEX IF NOT EXISTS idx_supplement_logs_logged_at ON supplement_logs(logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_supplement_logs_patient_logged ON supplement_logs(patient_id, logged_at DESC);
CREATE INDEX IF NOT EXISTS idx_supplement_logs_supplement_id ON supplement_logs(supplement_id);
CREATE INDEX IF NOT EXISTS idx_patient_supplement_stacks_patient_id ON patient_supplement_stacks(patient_id);
CREATE INDEX IF NOT EXISTS idx_patient_supplement_stacks_active ON patient_supplement_stacks(patient_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_patient_supplement_stacks_supplement_id ON patient_supplement_stacks(supplement_id);

-- ============================================================================
-- UPDATED_AT TRIGGERS
-- ============================================================================

CREATE OR REPLACE FUNCTION update_health_intelligence_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Lab results triggers
CREATE TRIGGER update_lab_results_timestamp
    BEFORE UPDATE ON lab_results
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

CREATE TRIGGER update_biomarker_values_timestamp
    BEFORE UPDATE ON biomarker_values
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

CREATE TRIGGER update_biomarker_reference_ranges_timestamp
    BEFORE UPDATE ON biomarker_reference_ranges
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

-- Recovery triggers
CREATE TRIGGER update_recovery_sessions_timestamp
    BEFORE UPDATE ON recovery_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

CREATE TRIGGER update_recovery_protocols_timestamp
    BEFORE UPDATE ON recovery_protocols
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

-- Fasting triggers
CREATE TRIGGER update_fasting_logs_timestamp
    BEFORE UPDATE ON fasting_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

CREATE TRIGGER update_fasting_protocols_timestamp
    BEFORE UPDATE ON fasting_protocols
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

-- Supplement triggers
CREATE TRIGGER update_supplements_timestamp
    BEFORE UPDATE ON supplements
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

CREATE TRIGGER update_supplement_logs_timestamp
    BEFORE UPDATE ON supplement_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

CREATE TRIGGER update_patient_supplement_stacks_timestamp
    BEFORE UPDATE ON patient_supplement_stacks
    FOR EACH ROW
    EXECUTE FUNCTION update_health_intelligence_timestamp();

-- ============================================================================
-- ROW-LEVEL SECURITY (RLS)
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE lab_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE biomarker_values ENABLE ROW LEVEL SECURITY;
ALTER TABLE biomarker_reference_ranges ENABLE ROW LEVEL SECURITY;
ALTER TABLE recovery_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE recovery_protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE fasting_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE fasting_protocols ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplements ENABLE ROW LEVEL SECURITY;
ALTER TABLE supplement_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE patient_supplement_stacks ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- LAB RESULTS RLS POLICIES
-- ============================================================================

-- Patients can view their own lab results
CREATE POLICY "Patients view own lab results"
    ON lab_results FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can insert their own lab results
CREATE POLICY "Patients insert own lab results"
    ON lab_results FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own lab results
CREATE POLICY "Patients update own lab results"
    ON lab_results FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Patients can delete their own lab results
CREATE POLICY "Patients delete own lab results"
    ON lab_results FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view their patients' lab results
CREATE POLICY "Therapists view patient lab results"
    ON lab_results FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = lab_results.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Biomarker values: inherit access from parent lab result
CREATE POLICY "Patients view own biomarker values"
    ON biomarker_values FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = auth.uid()
        )
    );

CREATE POLICY "Patients insert own biomarker values"
    ON biomarker_values FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = auth.uid()
        )
    );

CREATE POLICY "Patients update own biomarker values"
    ON biomarker_values FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = auth.uid()
        )
    );

CREATE POLICY "Patients delete own biomarker values"
    ON biomarker_values FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM lab_results lr
            WHERE lr.id = biomarker_values.lab_result_id
            AND lr.patient_id = auth.uid()
        )
    );

CREATE POLICY "Therapists view patient biomarker values"
    ON biomarker_values FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM lab_results lr
            JOIN therapist_patients tp ON tp.patient_id = lr.patient_id
            WHERE lr.id = biomarker_values.lab_result_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Biomarker reference ranges: public read access
CREATE POLICY "Anyone can read biomarker reference ranges"
    ON biomarker_reference_ranges FOR SELECT
    TO authenticated
    USING (true);

-- Service role can manage reference ranges
CREATE POLICY "Service role can manage biomarker reference ranges"
    ON biomarker_reference_ranges FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- RECOVERY SESSION RLS POLICIES
-- ============================================================================

-- Patients can CRUD their own recovery sessions
CREATE POLICY "Patients view own recovery sessions"
    ON recovery_sessions FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients insert own recovery sessions"
    ON recovery_sessions FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients update own recovery sessions"
    ON recovery_sessions FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients delete own recovery sessions"
    ON recovery_sessions FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view their patients' recovery sessions
CREATE POLICY "Therapists view patient recovery sessions"
    ON recovery_sessions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = recovery_sessions.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Recovery protocols: public protocols visible to all, private to creator
CREATE POLICY "Users can view public recovery protocols"
    ON recovery_protocols FOR SELECT
    USING (is_public = true);

CREATE POLICY "Users can view own recovery protocols"
    ON recovery_protocols FOR SELECT
    USING (created_by = auth.uid());

CREATE POLICY "Users can insert recovery protocols"
    ON recovery_protocols FOR INSERT
    WITH CHECK (created_by = auth.uid() OR created_by IS NULL);

CREATE POLICY "Users can update own recovery protocols"
    ON recovery_protocols FOR UPDATE
    USING (created_by = auth.uid())
    WITH CHECK (created_by = auth.uid());

CREATE POLICY "Users can delete own recovery protocols"
    ON recovery_protocols FOR DELETE
    USING (created_by = auth.uid());

CREATE POLICY "Service role can manage recovery protocols"
    ON recovery_protocols FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- ============================================================================
-- FASTING RLS POLICIES
-- ============================================================================

-- Fasting protocols: public read access
CREATE POLICY "Anyone can read fasting protocols"
    ON fasting_protocols FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Service role can manage fasting protocols"
    ON fasting_protocols FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Fasting logs: patients CRUD own, therapists view
CREATE POLICY "Patients view own fasting logs"
    ON fasting_logs FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients insert own fasting logs"
    ON fasting_logs FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients update own fasting logs"
    ON fasting_logs FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients delete own fasting logs"
    ON fasting_logs FOR DELETE
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists view patient fasting logs"
    ON fasting_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = fasting_logs.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- ============================================================================
-- SUPPLEMENT RLS POLICIES
-- ============================================================================

-- Supplements catalog: public read access
CREATE POLICY "Anyone can read supplements"
    ON supplements FOR SELECT
    TO authenticated
    USING (true);

CREATE POLICY "Service role can manage supplements"
    ON supplements FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Supplement logs: patients CRUD own, therapists view
CREATE POLICY "Patients view own supplement logs"
    ON supplement_logs FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients insert own supplement logs"
    ON supplement_logs FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients update own supplement logs"
    ON supplement_logs FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients delete own supplement logs"
    ON supplement_logs FOR DELETE
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists view patient supplement logs"
    ON supplement_logs FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = supplement_logs.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- Patient supplement stacks: patients CRUD own, therapists view
CREATE POLICY "Patients view own supplement stacks"
    ON patient_supplement_stacks FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients insert own supplement stacks"
    ON patient_supplement_stacks FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients update own supplement stacks"
    ON patient_supplement_stacks FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients delete own supplement stacks"
    ON patient_supplement_stacks FOR DELETE
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists view patient supplement stacks"
    ON patient_supplement_stacks FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapist_patients tp
            WHERE tp.patient_id = patient_supplement_stacks.patient_id
            AND tp.therapist_id = auth.uid()
            AND tp.active = true
        )
    );

-- ============================================================================
-- GRANTS
-- ============================================================================

-- Grant permissions to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON lab_results TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON biomarker_values TO authenticated;
GRANT SELECT ON biomarker_reference_ranges TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON recovery_sessions TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON recovery_protocols TO authenticated;
GRANT SELECT ON fasting_protocols TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON fasting_logs TO authenticated;
GRANT SELECT ON supplements TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON supplement_logs TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_supplement_stacks TO authenticated;

-- Grant full access to service role
GRANT ALL ON lab_results TO service_role;
GRANT ALL ON biomarker_values TO service_role;
GRANT ALL ON biomarker_reference_ranges TO service_role;
GRANT ALL ON recovery_sessions TO service_role;
GRANT ALL ON recovery_protocols TO service_role;
GRANT ALL ON fasting_protocols TO service_role;
GRANT ALL ON fasting_logs TO service_role;
GRANT ALL ON supplements TO service_role;
GRANT ALL ON supplement_logs TO service_role;
GRANT ALL ON patient_supplement_stacks TO service_role;

-- ============================================================================
-- SEED DATA: BIOMARKER REFERENCE RANGES
-- ============================================================================

INSERT INTO biomarker_reference_ranges (biomarker_type, name, category, optimal_low, optimal_high, normal_low, normal_high, unit, description)
VALUES
    -- Hormones
    ('testosterone_total', 'Total Testosterone', 'hormones', 500, 900, 300, 1000, 'ng/dL', 'Primary male sex hormone, important for muscle mass, energy, and mood'),
    ('testosterone_free', 'Free Testosterone', 'hormones', 15, 25, 9, 30, 'pg/mL', 'Bioavailable testosterone not bound to proteins'),
    ('estradiol', 'Estradiol (E2)', 'hormones', 20, 35, 10, 50, 'pg/mL', 'Primary estrogen, important for bone health and cardiovascular function'),
    ('dhea_s', 'DHEA-Sulfate', 'hormones', 300, 450, 100, 600, 'ug/dL', 'Precursor hormone for testosterone and estrogen'),
    ('cortisol_am', 'Cortisol (AM)', 'hormones', 10, 18, 6, 23, 'ug/dL', 'Stress hormone, should be highest in morning'),
    ('thyroid_tsh', 'TSH', 'hormones', 1.0, 2.5, 0.4, 4.5, 'mIU/L', 'Thyroid stimulating hormone'),
    ('thyroid_free_t3', 'Free T3', 'hormones', 3.0, 4.0, 2.3, 4.2, 'pg/mL', 'Active thyroid hormone'),
    ('thyroid_free_t4', 'Free T4', 'hormones', 1.2, 1.5, 0.8, 1.8, 'ng/dL', 'Thyroid hormone precursor'),
    ('igf1', 'IGF-1', 'hormones', 150, 250, 100, 350, 'ng/mL', 'Insulin-like growth factor 1, marker of growth hormone'),

    -- Vitamins
    ('vitamin_d', 'Vitamin D (25-OH)', 'vitamins', 50, 80, 30, 100, 'ng/mL', 'Essential for bone health, immune function, and mood'),
    ('vitamin_b12', 'Vitamin B12', 'vitamins', 500, 900, 200, 1100, 'pg/mL', 'Essential for nerve function and red blood cell formation'),
    ('folate', 'Folate', 'vitamins', 10, 20, 3, 20, 'ng/mL', 'B vitamin important for cell division and DNA synthesis'),
    ('ferritin', 'Ferritin', 'vitamins', 75, 150, 30, 300, 'ng/mL', 'Iron storage protein, marker of iron status'),
    ('iron', 'Iron', 'vitamins', 80, 120, 60, 170, 'ug/dL', 'Essential mineral for oxygen transport'),

    -- Inflammation
    ('crp', 'C-Reactive Protein (hs-CRP)', 'inflammation', 0, 1.0, 0, 3.0, 'mg/L', 'Marker of systemic inflammation'),
    ('homocysteine', 'Homocysteine', 'inflammation', 5, 9, 4, 15, 'umol/L', 'Amino acid linked to cardiovascular risk when elevated'),
    ('esr', 'Erythrocyte Sedimentation Rate', 'inflammation', 0, 10, 0, 20, 'mm/hr', 'Non-specific marker of inflammation'),
    ('fibrinogen', 'Fibrinogen', 'inflammation', 200, 350, 150, 400, 'mg/dL', 'Blood clotting factor, elevated in inflammation'),

    -- Metabolic
    ('glucose_fasting', 'Fasting Glucose', 'metabolic', 70, 90, 65, 100, 'mg/dL', 'Blood sugar level after fasting'),
    ('hba1c', 'Hemoglobin A1c', 'metabolic', 4.5, 5.4, 4.0, 5.7, '%', 'Average blood sugar over 2-3 months'),
    ('insulin_fasting', 'Fasting Insulin', 'metabolic', 2, 6, 2, 19, 'uIU/mL', 'Hormone regulating blood sugar'),
    ('triglycerides', 'Triglycerides', 'metabolic', 50, 100, 0, 150, 'mg/dL', 'Blood fat, elevated by sugar and refined carbs'),
    ('hdl', 'HDL Cholesterol', 'metabolic', 60, 100, 40, 100, 'mg/dL', 'Good cholesterol, higher is better'),
    ('ldl', 'LDL Cholesterol', 'metabolic', 70, 100, 0, 130, 'mg/dL', 'Bad cholesterol when oxidized'),
    ('total_cholesterol', 'Total Cholesterol', 'metabolic', 150, 200, 125, 240, 'mg/dL', 'Sum of all cholesterol types'),
    ('apolipoprotein_b', 'Apolipoprotein B', 'metabolic', 60, 80, 40, 100, 'mg/dL', 'Better marker of cardiovascular risk than LDL'),

    -- Liver
    ('alt', 'ALT (SGPT)', 'liver', 10, 25, 7, 56, 'U/L', 'Liver enzyme, elevated in liver damage'),
    ('ast', 'AST (SGOT)', 'liver', 10, 25, 8, 48, 'U/L', 'Liver enzyme, also found in muscle'),
    ('ggt', 'GGT', 'liver', 10, 30, 8, 61, 'U/L', 'Liver enzyme sensitive to alcohol'),
    ('alkaline_phosphatase', 'Alkaline Phosphatase', 'liver', 40, 80, 30, 120, 'U/L', 'Enzyme from liver and bone'),

    -- Kidney
    ('creatinine', 'Creatinine', 'kidney', 0.8, 1.1, 0.7, 1.3, 'mg/dL', 'Waste product from muscle metabolism'),
    ('bun', 'Blood Urea Nitrogen', 'kidney', 10, 18, 7, 25, 'mg/dL', 'Waste product from protein metabolism'),
    ('egfr', 'eGFR', 'kidney', 90, 120, 60, 120, 'mL/min/1.73m2', 'Estimated kidney filtration rate'),
    ('uric_acid', 'Uric Acid', 'kidney', 3.5, 6.0, 2.5, 8.0, 'mg/dL', 'Waste product, elevated in gout'),

    -- Blood Count
    ('hemoglobin', 'Hemoglobin', 'blood_count', 14, 16, 13.5, 17.5, 'g/dL', 'Oxygen-carrying protein in red blood cells'),
    ('hematocrit', 'Hematocrit', 'blood_count', 42, 48, 38.5, 50, '%', 'Percentage of blood that is red blood cells'),
    ('rbc', 'Red Blood Cell Count', 'blood_count', 4.5, 5.5, 4.0, 5.9, 'M/uL', 'Number of red blood cells'),
    ('wbc', 'White Blood Cell Count', 'blood_count', 5, 8, 4, 11, 'K/uL', 'Immune cells'),
    ('platelets', 'Platelets', 'blood_count', 200, 300, 150, 400, 'K/uL', 'Blood clotting cells'),

    -- Electrolytes
    ('sodium', 'Sodium', 'electrolytes', 138, 142, 136, 145, 'mEq/L', 'Essential electrolyte for fluid balance'),
    ('potassium', 'Potassium', 'electrolytes', 4.0, 4.8, 3.5, 5.2, 'mEq/L', 'Essential for heart and muscle function'),
    ('magnesium', 'Magnesium', 'electrolytes', 2.0, 2.4, 1.7, 2.5, 'mg/dL', 'Essential for muscle and nerve function'),
    ('calcium', 'Calcium', 'electrolytes', 9.2, 10.0, 8.6, 10.4, 'mg/dL', 'Essential for bone, muscle, and nerve function'),
    ('phosphorus', 'Phosphorus', 'electrolytes', 3.0, 4.0, 2.5, 4.5, 'mg/dL', 'Important for bone and energy metabolism')
ON CONFLICT (biomarker_type) DO NOTHING;

-- ============================================================================
-- SEED DATA: FASTING PROTOCOLS
-- ============================================================================

INSERT INTO fasting_protocols (name, eating_window_hours, fasting_hours, description)
VALUES
    ('16:8 Intermittent Fasting', 8, 16, 'The most popular intermittent fasting protocol. Fast for 16 hours, eat within an 8-hour window. Example: eat between 12pm-8pm, fast from 8pm-12pm.'),
    ('18:6 Intermittent Fasting', 6, 18, 'A slightly more advanced protocol with an 18-hour fast and 6-hour eating window. Example: eat between 12pm-6pm.'),
    ('20:4 Warrior Diet', 4, 20, 'A challenging protocol with a 20-hour fast and 4-hour eating window. Often one large meal and small snacks.'),
    ('OMAD (One Meal a Day)', 1, 23, 'One meal per day, typically eaten within a 1-hour window. Advanced protocol requiring careful nutrition planning.'),
    ('5:2 Diet', 24, 0, 'Eat normally 5 days per week, restrict to 500-600 calories on 2 non-consecutive days.'),
    ('24-Hour Fast', 0, 24, 'A full 24-hour fast done once or twice per week. Example: dinner to dinner.'),
    ('36-Hour Fast', 0, 36, 'Extended fast from dinner one day to breakfast two days later. More advanced, done weekly or monthly.'),
    ('48-Hour Fast', 0, 48, 'Two-day fast done monthly for deeper autophagy benefits. Requires careful refeeding.'),
    ('72-Hour Fast', 0, 72, 'Three-day extended fast done quarterly. Significant autophagy and immune reset benefits. Requires medical consideration.')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SEED DATA: RECOVERY PROTOCOLS
-- ============================================================================

INSERT INTO recovery_protocols (name, description, phases, recommended_frequency, is_public)
VALUES
    (
        'Huberman Sauna Protocol',
        'Based on Dr. Andrew Huberman''s recommendations for sauna use to increase growth hormone and improve cardiovascular health. Research shows significant benefits from regular sauna exposure.',
        '[
            {"order": 1, "type": "sauna_traditional", "duration_minutes": 20, "temperature_f": 176, "notes": "Enter dry sauna at 80°C (176°F)"},
            {"order": 2, "type": "rest", "duration_minutes": 5, "notes": "Cool down period - room temperature or cool shower"},
            {"order": 3, "type": "sauna_traditional", "duration_minutes": 20, "temperature_f": 176, "notes": "Second sauna session"},
            {"order": 4, "type": "rest", "duration_minutes": 5, "notes": "Cool down period"},
            {"order": 5, "type": "sauna_traditional", "duration_minutes": 20, "temperature_f": 176, "notes": "Third sauna session - optional for growth hormone boost"}
        ]'::jsonb,
        '2-3 times per week',
        true
    ),
    (
        'Deliberate Cold Exposure Protocol',
        'Based on research by Dr. Susanna Soeberg and promoted by Dr. Andrew Huberman. Cold exposure increases dopamine, norepinephrine, and metabolic rate while improving mental resilience.',
        '[
            {"order": 1, "type": "cold_plunge", "duration_minutes": 2, "temperature_f": 50, "notes": "Enter cold water (50°F/10°C or colder). Focus on controlling breathing."},
            {"order": 2, "type": "rest", "duration_minutes": 3, "notes": "Allow natural rewarming - do NOT use hot shower immediately"},
            {"order": 3, "type": "cold_plunge", "duration_minutes": 2, "temperature_f": 50, "notes": "Second cold exposure - work up to 11 minutes total per week"}
        ]'::jsonb,
        '3-4 times per week, 11 minutes total weekly',
        true
    ),
    (
        'Contrast Therapy Protocol',
        'Alternating between hot and cold exposure for enhanced recovery, reduced inflammation, and improved circulation. The contrast creates a vascular "pump" effect.',
        '[
            {"order": 1, "type": "sauna_traditional", "duration_minutes": 15, "temperature_f": 176, "notes": "Start with heat to vasodilate"},
            {"order": 2, "type": "cold_plunge", "duration_minutes": 1, "temperature_f": 50, "notes": "Brief cold exposure to vasoconstrict"},
            {"order": 3, "type": "sauna_traditional", "duration_minutes": 10, "temperature_f": 176, "notes": "Return to heat"},
            {"order": 4, "type": "cold_plunge", "duration_minutes": 1, "temperature_f": 50, "notes": "Second cold exposure"},
            {"order": 5, "type": "sauna_traditional", "duration_minutes": 10, "temperature_f": 176, "notes": "Final heat session"},
            {"order": 6, "type": "cold_plunge", "duration_minutes": 2, "temperature_f": 50, "notes": "End on cold for optimal dopamine boost"}
        ]'::jsonb,
        '2-3 times per week',
        true
    ),
    (
        'Infrared Sauna Recovery',
        'Lower temperature infrared sauna protocol for those who prefer gentler heat. Infrared penetrates deeper into tissue while being more comfortable than traditional sauna.',
        '[
            {"order": 1, "type": "sauna_infrared", "duration_minutes": 30, "temperature_f": 140, "notes": "Infrared sauna at 140°F (60°C)"},
            {"order": 2, "type": "rest", "duration_minutes": 10, "notes": "Cool down and hydrate"},
            {"order": 3, "type": "sauna_infrared", "duration_minutes": 20, "temperature_f": 140, "notes": "Optional second session"}
        ]'::jsonb,
        '3-4 times per week',
        true
    ),
    (
        'Cold Shower Protocol',
        'A simple cold exposure protocol for those without access to cold plunge. Research shows benefits begin at end-of-shower cold exposure.',
        '[
            {"order": 1, "type": "cold_shower", "duration_minutes": 1, "temperature_f": 60, "notes": "Start with 30 seconds, work up to 1-2 minutes"},
            {"order": 2, "type": "rest", "duration_minutes": 5, "notes": "Allow natural rewarming - feel the ''rewarming glow''"}
        ]'::jsonb,
        'Daily, ideally in morning',
        true
    )
ON CONFLICT DO NOTHING;

COMMIT;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_lab_results_count integer;
    v_biomarker_ranges_count integer;
    v_recovery_protocols_count integer;
    v_fasting_protocols_count integer;
BEGIN
    SELECT COUNT(*) INTO v_biomarker_ranges_count FROM biomarker_reference_ranges;
    SELECT COUNT(*) INTO v_recovery_protocols_count FROM recovery_protocols;
    SELECT COUNT(*) INTO v_fasting_protocols_count FROM fasting_protocols;

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'HEALTH INTELLIGENCE TABLES MIGRATION COMPLETE';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '  Lab Results:';
    RAISE NOTICE '    - lab_results';
    RAISE NOTICE '    - biomarker_values';
    RAISE NOTICE '    - biomarker_reference_ranges (% seed records)', v_biomarker_ranges_count;
    RAISE NOTICE '';
    RAISE NOTICE '  Recovery:';
    RAISE NOTICE '    - recovery_sessions';
    RAISE NOTICE '    - recovery_protocols (% seed records)', v_recovery_protocols_count;
    RAISE NOTICE '';
    RAISE NOTICE '  Fasting:';
    RAISE NOTICE '    - fasting_logs';
    RAISE NOTICE '    - fasting_protocols (% seed records)', v_fasting_protocols_count;
    RAISE NOTICE '';
    RAISE NOTICE '  Supplements:';
    RAISE NOTICE '    - supplements';
    RAISE NOTICE '    - supplement_logs';
    RAISE NOTICE '    - patient_supplement_stacks';
    RAISE NOTICE '';
    RAISE NOTICE 'Custom Types Created:';
    RAISE NOTICE '  - lab_provider (quest, labcorp, other)';
    RAISE NOTICE '  - recovery_session_type (sauna_*, cold_*, contrast)';
    RAISE NOTICE '  - supplement_timing (morning, afternoon, evening, etc.)';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies: Patients see own data, therapists see their patients';
    RAISE NOTICE 'Indexes: Optimized for patient_id + date range queries';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
