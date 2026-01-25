-- Migration: Simplified meal_plan_items SELECT policy
-- Created: 2026-01-20
-- Description: Add a simpler SELECT policy for debugging

-- Drop all existing policies on meal_plan_items to start fresh
DROP POLICY IF EXISTS "Patients can view their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can insert their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can update their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can delete their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients and therapists can manage meal plan items" ON meal_plan_items;

-- Simpler SELECT policy - just check if meal_plan belongs to the user
CREATE POLICY "meal_plan_items_select"
    ON meal_plan_items FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- INSERT policy
CREATE POLICY "meal_plan_items_insert"
    ON meal_plan_items FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- UPDATE policy
CREATE POLICY "meal_plan_items_update"
    ON meal_plan_items FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );

-- DELETE policy
CREATE POLICY "meal_plan_items_delete"
    ON meal_plan_items FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM meal_plans mp
            JOIN patients p ON p.id = mp.patient_id
            WHERE mp.id = meal_plan_items.meal_plan_id
            AND p.email = (auth.jwt() ->> 'email')
        )
    );
