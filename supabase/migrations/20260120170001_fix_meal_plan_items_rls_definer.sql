-- Migration: Fix meal_plan_items RLS with SECURITY DEFINER function
-- Created: 2026-01-20
-- Description: Use SECURITY DEFINER function to avoid RLS recursion issue
-- Problem: meal_plan_items RLS policy queries meal_plans which has RLS,
--          causing the policy check to fail due to recursive RLS evaluation.

-- Create a SECURITY DEFINER function that can check ownership without RLS interference
CREATE OR REPLACE FUNCTION public.user_owns_meal_plan(check_meal_plan_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM meal_plans mp
    JOIN patients p ON p.id = mp.patient_id
    WHERE mp.id = check_meal_plan_id
    AND p.email = (auth.jwt() ->> 'email')
  )
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION public.user_owns_meal_plan(UUID) TO authenticated;

-- Drop all existing policies on meal_plan_items
DROP POLICY IF EXISTS "meal_plan_items_select" ON meal_plan_items;
DROP POLICY IF EXISTS "meal_plan_items_insert" ON meal_plan_items;
DROP POLICY IF EXISTS "meal_plan_items_update" ON meal_plan_items;
DROP POLICY IF EXISTS "meal_plan_items_delete" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can view their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can insert their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can update their own meal plan items" ON meal_plan_items;
DROP POLICY IF EXISTS "Patients can delete their own meal plan items" ON meal_plan_items;

-- Create new policies using the SECURITY DEFINER function
CREATE POLICY "meal_plan_items_select"
    ON meal_plan_items FOR SELECT
    USING (user_owns_meal_plan(meal_plan_id));

CREATE POLICY "meal_plan_items_insert"
    ON meal_plan_items FOR INSERT
    WITH CHECK (user_owns_meal_plan(meal_plan_id));

CREATE POLICY "meal_plan_items_update"
    ON meal_plan_items FOR UPDATE
    USING (user_owns_meal_plan(meal_plan_id));

CREATE POLICY "meal_plan_items_delete"
    ON meal_plan_items FOR DELETE
    USING (user_owns_meal_plan(meal_plan_id));
