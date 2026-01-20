-- Migration: Fix meal_plans RLS policies
-- Created: 2026-01-20
-- Description: Fix RLS to check patient via email from JWT token

-- Drop existing patient policies
DROP POLICY IF EXISTS "Patients can view their own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Patients can create their own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Patients can update their own meal plans" ON meal_plans;
DROP POLICY IF EXISTS "Patients can delete their own meal plans" ON meal_plans;

-- Recreate with correct auth check via patients.email = JWT email
-- Use auth.jwt() ->> 'email' to get email from token without querying auth.users
CREATE POLICY "Patients can view their own meal plans"
    ON meal_plans FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = meal_plans.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "Patients can create their own meal plans"
    ON meal_plans FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "Patients can update their own meal plans"
    ON meal_plans FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = meal_plans.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

CREATE POLICY "Patients can delete their own meal plans"
    ON meal_plans FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = meal_plans.patient_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );
