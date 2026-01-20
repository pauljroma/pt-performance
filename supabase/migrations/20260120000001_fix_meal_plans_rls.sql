-- Migration: Fix meal_plans RLS policies
-- Created: 2026-01-20
-- Description: Fix RLS to check patient via auth_user_id instead of assuming patient_id = auth.uid()

-- Drop existing patient policies
DROP POLICY IF EXISTS "Patients can view their own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Patients can create their own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Patients can update their own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Patients can delete their own meal plans" ON meal_plans;

-- Recreate with correct auth check via patients table
CREATE POLICY "Patients can view their own meal plans"
    ON meal_plans FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = meal_plans.patient_id
            AND p.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can create their own meal plans"
    ON meal_plans FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = patient_id
            AND p.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can update their own meal plans"
    ON meal_plans FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = meal_plans.patient_id
            AND p.auth_user_id = auth.uid()
        )
    );

CREATE POLICY "Patients can delete their own meal plans"
    ON meal_plans FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = meal_plans.patient_id
            AND p.auth_user_id = auth.uid()
        )
    );
