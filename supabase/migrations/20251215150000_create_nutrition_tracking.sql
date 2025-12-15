-- Migration: Create nutrition tracking tables
-- Date: 2025-12-15
-- Author: Build 46 Swarm Agent 5
-- Description: Enable basic nutrition tracking for patients

BEGIN;

-- Create nutrition_logs table
CREATE TABLE IF NOT EXISTS nutrition_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    log_date DATE NOT NULL DEFAULT CURRENT_DATE,
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other')),
    description TEXT NOT NULL,
    calories INTEGER CHECK (calories >= 0),
    protein_grams DECIMAL(6,2) CHECK (protein_grams >= 0),
    carbs_grams DECIMAL(6,2) CHECK (carbs_grams >= 0),
    fats_grams DECIMAL(6,2) CHECK (fats_grams >= 0),
    photo_url TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create nutrition_goals table
CREATE TABLE IF NOT EXISTS nutrition_goals (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    daily_calories INTEGER CHECK (daily_calories > 0),
    daily_protein_grams DECIMAL(6,2) CHECK (daily_protein_grams >= 0),
    daily_carbs_grams DECIMAL(6,2) CHECK (daily_carbs_grams >= 0),
    daily_fats_grams DECIMAL(6,2) CHECK (daily_fats_grams >= 0),
    set_by UUID REFERENCES patients(id), -- therapist who set goals
    notes TEXT,
    active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- Only one active goal per patient
    UNIQUE(patient_id, active) WHERE active = TRUE
);

-- Create indexes for performance
CREATE INDEX idx_nutrition_logs_patient ON nutrition_logs(patient_id);
CREATE INDEX idx_nutrition_logs_date ON nutrition_logs(log_date);
CREATE INDEX idx_nutrition_logs_patient_date ON nutrition_logs(patient_id, log_date);
CREATE INDEX idx_nutrition_logs_meal_type ON nutrition_logs(meal_type);

CREATE INDEX idx_nutrition_goals_patient ON nutrition_goals(patient_id);
CREATE INDEX idx_nutrition_goals_active ON nutrition_goals(patient_id, active) WHERE active = TRUE;

-- Enable RLS
ALTER TABLE nutrition_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE nutrition_goals ENABLE ROW LEVEL SECURITY;

-- RLS Policies for nutrition_logs

-- Patients can view their own nutrition logs
CREATE POLICY "Patients view own nutrition logs"
    ON nutrition_logs FOR SELECT
    USING (patient_id = auth.uid());

-- Patients can create their own nutrition logs
CREATE POLICY "Patients create own nutrition logs"
    ON nutrition_logs FOR INSERT
    WITH CHECK (patient_id = auth.uid());

-- Patients can update their own nutrition logs
CREATE POLICY "Patients update own nutrition logs"
    ON nutrition_logs FOR UPDATE
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Patients can delete their own nutrition logs
CREATE POLICY "Patients delete own nutrition logs"
    ON nutrition_logs FOR DELETE
    USING (patient_id = auth.uid());

-- Therapists can view all nutrition logs for their patients
CREATE POLICY "Therapists view patient nutrition logs"
    ON nutrition_logs FOR SELECT
    USING (
        auth.role() = 'therapist' OR
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = nutrition_logs.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- RLS Policies for nutrition_goals

-- Patients can view their own nutrition goals
CREATE POLICY "Patients view own nutrition goals"
    ON nutrition_goals FOR SELECT
    USING (patient_id = auth.uid());

-- Therapists can view nutrition goals for their patients
CREATE POLICY "Therapists view patient nutrition goals"
    ON nutrition_goals FOR SELECT
    USING (
        auth.role() = 'therapist' OR
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = nutrition_goals.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Therapists can create nutrition goals for their patients
CREATE POLICY "Therapists create nutrition goals"
    ON nutrition_goals FOR INSERT
    WITH CHECK (
        auth.role() = 'therapist' AND
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = nutrition_goals.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Therapists can update nutrition goals for their patients
CREATE POLICY "Therapists update nutrition goals"
    ON nutrition_goals FOR UPDATE
    USING (
        auth.role() = 'therapist' AND
        EXISTS (
            SELECT 1 FROM patients
            WHERE patients.id = nutrition_goals.patient_id
            AND patients.therapist_id = auth.uid()
        )
    );

-- Create triggers for updated_at timestamps
CREATE OR REPLACE FUNCTION update_nutrition_logs_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER nutrition_logs_updated_at
    BEFORE UPDATE ON nutrition_logs
    FOR EACH ROW
    EXECUTE FUNCTION update_nutrition_logs_updated_at();

CREATE OR REPLACE FUNCTION update_nutrition_goals_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER nutrition_goals_updated_at
    BEFORE UPDATE ON nutrition_goals
    FOR EACH ROW
    EXECUTE FUNCTION update_nutrition_goals_updated_at();

-- Create view for daily nutrition summary
CREATE OR REPLACE VIEW daily_nutrition_summary AS
SELECT
    patient_id,
    log_date,
    COUNT(*) as meal_count,
    SUM(calories) as total_calories,
    SUM(protein_grams) as total_protein,
    SUM(carbs_grams) as total_carbs,
    SUM(fats_grams) as total_fats,
    -- Compare to goals
    (
        SELECT daily_calories
        FROM nutrition_goals ng
        WHERE ng.patient_id = nutrition_logs.patient_id
        AND ng.active = TRUE
        LIMIT 1
    ) as goal_calories,
    (
        SELECT daily_protein_grams
        FROM nutrition_goals ng
        WHERE ng.patient_id = nutrition_logs.patient_id
        AND ng.active = TRUE
        LIMIT 1
    ) as goal_protein,
    (
        SELECT daily_carbs_grams
        FROM nutrition_goals ng
        WHERE ng.patient_id = nutrition_logs.patient_id
        AND ng.active = TRUE
        LIMIT 1
    ) as goal_carbs,
    (
        SELECT daily_fats_grams
        FROM nutrition_goals ng
        WHERE ng.patient_id = nutrition_logs.patient_id
        AND ng.active = TRUE
        LIMIT 1
    ) as goal_fats
FROM nutrition_logs
GROUP BY patient_id, log_date
ORDER BY log_date DESC;

-- Create function to get nutrition summary for date range
CREATE OR REPLACE FUNCTION get_nutrition_summary(
    p_patient_id UUID,
    p_start_date DATE,
    p_end_date DATE
)
RETURNS TABLE (
    log_date DATE,
    meal_count BIGINT,
    total_calories NUMERIC,
    total_protein NUMERIC,
    total_carbs NUMERIC,
    total_fats NUMERIC,
    goal_calories INTEGER,
    goal_protein DECIMAL,
    goal_carbs DECIMAL,
    goal_fats DECIMAL,
    calories_percentage NUMERIC,
    protein_percentage NUMERIC,
    carbs_percentage NUMERIC,
    fats_percentage NUMERIC
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        dns.log_date,
        dns.meal_count,
        dns.total_calories,
        dns.total_protein,
        dns.total_carbs,
        dns.total_fats,
        dns.goal_calories,
        dns.goal_protein,
        dns.goal_carbs,
        dns.goal_fats,
        CASE
            WHEN dns.goal_calories IS NOT NULL AND dns.goal_calories > 0
            THEN ROUND((dns.total_calories::NUMERIC / dns.goal_calories) * 100, 1)
            ELSE NULL
        END as calories_percentage,
        CASE
            WHEN dns.goal_protein IS NOT NULL AND dns.goal_protein > 0
            THEN ROUND((dns.total_protein::NUMERIC / dns.goal_protein) * 100, 1)
            ELSE NULL
        END as protein_percentage,
        CASE
            WHEN dns.goal_carbs IS NOT NULL AND dns.goal_carbs > 0
            THEN ROUND((dns.total_carbs::NUMERIC / dns.goal_carbs) * 100, 1)
            ELSE NULL
        END as carbs_percentage,
        CASE
            WHEN dns.goal_fats IS NOT NULL AND dns.goal_fats > 0
            THEN ROUND((dns.total_fats::NUMERIC / dns.goal_fats) * 100, 1)
            ELSE NULL
        END as fats_percentage
    FROM daily_nutrition_summary dns
    WHERE dns.patient_id = p_patient_id
    AND dns.log_date BETWEEN p_start_date AND p_end_date
    ORDER BY dns.log_date DESC;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

COMMIT;

-- Sample data (comment out for production)
-- INSERT INTO nutrition_goals (patient_id, daily_calories, daily_protein_grams, daily_carbs_grams, daily_fats_grams)
-- SELECT
--     id,
--     2000,
--     150.0,
--     200.0,
--     65.0
-- FROM patients
-- LIMIT 1;
