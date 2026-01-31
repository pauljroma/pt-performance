-- ============================================================================
-- CREATE BODY COMPOSITION GOALS TABLE (Part 1: Table + RLS)
-- ============================================================================

CREATE TABLE IF NOT EXISTS body_comp_goals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    target_weight DECIMAL(5,2),
    target_body_fat_percentage DECIMAL(4,1),
    target_muscle_mass DECIMAL(5,2),
    target_bmi DECIMAL(4,1),
    starting_weight DECIMAL(5,2),
    starting_body_fat_percentage DECIMAL(4,1),
    starting_muscle_mass DECIMAL(5,2),
    target_date DATE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    status VARCHAR(20) DEFAULT 'active' CHECK (status IN ('active', 'achieved', 'paused', 'cancelled')),
    achieved_at TIMESTAMPTZ,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE UNIQUE INDEX IF NOT EXISTS idx_body_comp_goals_one_active_per_patient
    ON body_comp_goals(patient_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_body_comp_goals_patient ON body_comp_goals(patient_id);
CREATE INDEX IF NOT EXISTS idx_body_comp_goals_status ON body_comp_goals(status);

-- Enable RLS
ALTER TABLE body_comp_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Patients can view own goals"
    ON body_comp_goals FOR SELECT TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Patients can insert own goals"
    ON body_comp_goals FOR INSERT TO authenticated
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Patients can update own goals"
    ON body_comp_goals FOR UPDATE TO authenticated
    USING (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()))
    WITH CHECK (patient_id IN (SELECT id FROM patients WHERE user_id = auth.uid()));

CREATE POLICY "Therapists can view patient goals"
    ON body_comp_goals FOR SELECT TO authenticated
    USING (patient_id IN (
        SELECT id FROM patients WHERE therapist_id IN (
            SELECT id FROM therapists WHERE user_id = auth.uid()
        )
    ));

CREATE POLICY "Service role can manage all body comp goals"
    ON body_comp_goals FOR ALL TO service_role
    USING (true) WITH CHECK (true);

-- Grant permissions
GRANT SELECT, INSERT, UPDATE ON body_comp_goals TO authenticated;
GRANT ALL ON body_comp_goals TO service_role;

-- Updated at trigger
CREATE OR REPLACE FUNCTION update_body_comp_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_body_comp_goals_updated_at ON body_comp_goals;
CREATE TRIGGER trg_body_comp_goals_updated_at
    BEFORE UPDATE ON body_comp_goals
    FOR EACH ROW EXECUTE FUNCTION update_body_comp_goals_updated_at();

DO $$ BEGIN RAISE NOTICE 'body_comp_goals table created successfully'; END $$;
