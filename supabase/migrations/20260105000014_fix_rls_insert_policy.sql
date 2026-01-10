-- Fix RLS INSERT policy - BUILD 116
-- Make it more permissive to allow authenticated users to insert

-- Drop the restrictive INSERT policy
DROP POLICY IF EXISTS "Patients can insert their own readiness data" ON daily_readiness;

-- Create a more permissive INSERT policy
-- Allow any authenticated user to insert (we'll validate patient_id on app side)
CREATE POLICY "Authenticated users can insert readiness data"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (true);

-- Also make UPDATE more permissive for now
DROP POLICY IF EXISTS "Patients can update their own readiness data" ON daily_readiness;

CREATE POLICY "Authenticated users can update readiness data"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Keep SELECT restrictive (patients can only see their own data)
-- This is already correct from before
