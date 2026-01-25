-- Migration: Fix meal_plan_items RLS policies
-- Created: 2026-01-20
-- Description: Use JWT email for patient identification instead of auth.uid()
-- Same fix as meal_plans RLS - patient_id is from patients table, not auth.users

-- Drop existing policies
DROP POLICY IF EXISTS "Patients can view their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients and therapists can manage meal plan items" ON meal_plan_items;

-- Create new policies using JWT email (patient-only for now)
CREATE POLICY "Patients can view their own meal plan items"
    ON meal_plan_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "Patients can insert their own meal plan items"
    ON meal_plan_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "Patients can update their own meal plan items"
    ON meal_plan_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "Patients can delete their own meal plan items"
    ON meal_plan_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );
