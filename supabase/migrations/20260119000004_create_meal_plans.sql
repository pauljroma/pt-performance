-- Migration: Create meal_plans and meal_plan_items tables
-- Created: 2026-01-19
-- Description: Tables for scheduling and managing patient nutrition meal plans

-- Meal plans for scheduling nutrition
CREATE TABLE meal_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    plan_type TEXT CHECK (plan_type IN ('daily', 'weekly')),
    is_active BOOLEAN DEFAULT TRUE,
    start_date DATE,
    end_date DATE,
    created_by UUID REFERENCES auth.users(id), -- therapist or patient
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Individual meals within a plan
CREATE TABLE meal_plan_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    meal_plan_id UUID NOT NULL REFERENCES meal_plans(id) ON DELETE CASCADE,
    day_of_week INT CHECK (day_of_week >= 0 AND day_of_week <= 6), -- 0=Sunday
    meal_type TEXT NOT NULL CHECK (meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'pre_workout', 'post_workout')),
    meal_time TIME, -- suggested time
    food_items JSONB NOT NULL DEFAULT '[]', -- array of {food_item_id, servings, notes}
    recipe_name TEXT, -- optional recipe name
    recipe_instructions TEXT,
    estimated_calories INT,
    estimated_protein_g DOUBLE PRECISION,
    estimated_carbs_g DOUBLE PRECISION,
    estimated_fat_g DOUBLE PRECISION,
    notes TEXT,
    sequence INT DEFAULT 0, -- order within the day
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_meal_plans_patient_id ON meal_plans(patient_id);
CREATE INDEX idx_meal_plans_active ON meal_plans(is_active) WHERE is_active = TRUE;
CREATE INDEX idx_meal_plan_items_plan_id ON meal_plan_items(meal_plan_id);
CREATE INDEX idx_meal_plan_items_day ON meal_plan_items(day_of_week);

-- Enable RLS
ALTER TABLE meal_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE meal_plan_items ENABLE ROW LEVEL SECURITY;

-- Meal Plans RLS
CREATE POLICY "Patients can view their own meal plans"
    ON meal_plans FOR SELECT
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can create their own meal plans"
    ON meal_plans FOR INSERT
    WITH CHECK (patient_id = auth.uid());

CREATE POLICY "Patients can update their own meal plans"
    ON meal_plans FOR UPDATE
    USING (patient_id = auth.uid());

CREATE POLICY "Patients can delete their own meal plans"
    ON meal_plans FOR DELETE
    USING (patient_id = auth.uid());

CREATE POLICY "Therapists can manage patient meal plans"
    ON meal_plans FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM patient_therapist_assignments pta
            WHERE pta.patient_id = meal_plans.patient_id
            AND pta.therapist_id = auth.uid()
        )
    );

-- Meal Plan Items RLS (follows parent plan)
CREATE POLICY "Users can view meal plan items through plan access"
    ON meal_plan_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND (mp.patient_id = auth.uid() OR EXISTS (
                SELECT 1 FROM patient_therapist_assignments pta
                WHERE pta.patient_id = mp.patient_id
                AND pta.therapist_id = auth.uid()
            ))
        )
    );

CREATE POLICY "Users can manage meal plan items through plan access"
    ON meal_plan_items FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND (mp.patient_id = auth.uid() OR EXISTS (
                SELECT 1 FROM patient_therapist_assignments pta
                WHERE pta.patient_id = mp.patient_id
                AND pta.therapist_id = auth.uid()
            ))
        )
    );

-- Grant permissions
GRANT SELECT, INSERT, UPDATE, DELETE ON meal_plans TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON meal_plan_items TO authenticated;
