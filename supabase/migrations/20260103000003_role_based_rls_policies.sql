-- Migration: Refine RLS Policies with Role-Based Access
-- Build: 119
-- Date: 2026-01-03
-- Purpose: Replace BUILD 118 permissive authenticated policies with role-based access control

-- ============================================================================
-- DAILY_READINESS TABLE - Role-Based RLS Policies
-- ============================================================================

-- Drop BUILD 118 permissive authenticated policies
DROP POLICY IF EXISTS "Authenticated users can insert readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Authenticated users can view readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Authenticated users can update readiness" ON daily_readiness;
DROP POLICY IF EXISTS "Authenticated users can delete readiness" ON daily_readiness;

-- Patient INSERT Policy: Can only insert own data
CREATE POLICY "Patients can insert own readiness"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = auth.uid());

-- Patient SELECT Policy: Can only view own data
CREATE POLICY "Patients can view own readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (patient_id = auth.uid());

-- Patient UPDATE Policy: Can only update own data
CREATE POLICY "Patients can update own readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (patient_id = auth.uid())
    WITH CHECK (patient_id = auth.uid());

-- Patient DELETE Policy: Can only delete own data
CREATE POLICY "Patients can delete own readiness"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (patient_id = auth.uid());

-- Therapist INSERT Policy: Can insert for assigned patients
CREATE POLICY "Therapists can insert for assigned patients"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (
        is_therapist(auth.uid()) = true
        AND (
            patient_id = auth.uid()
            OR is_assigned_therapist(auth.uid(), patient_id) = true
        )
    );

-- Therapist SELECT Policy: Can view assigned patients' data
CREATE POLICY "Therapists can view assigned patients readiness"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        is_therapist(auth.uid()) = true
        AND (
            patient_id = auth.uid()
            OR is_assigned_therapist(auth.uid(), patient_id) = true
        )
    );

-- Therapist UPDATE Policy: Can update assigned patients' data
CREATE POLICY "Therapists can update assigned patients readiness"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (
        is_therapist(auth.uid()) = true
        AND is_assigned_therapist(auth.uid(), patient_id) = true
    )
    WITH CHECK (
        is_therapist(auth.uid()) = true
        AND is_assigned_therapist(auth.uid(), patient_id) = true
    );

-- ============================================================================
-- READINESS_FACTORS TABLE - Role-Based RLS Policies
-- ============================================================================

-- Patients can view all factors (read-only configuration)
CREATE POLICY "Patients can view readiness factors"
    ON readiness_factors FOR SELECT
    TO authenticated
    USING (true);

-- Therapists can view all factors
CREATE POLICY "Therapists can view readiness factors"
    ON readiness_factors FOR SELECT
    TO authenticated
    USING (is_therapist(auth.uid()) = true);

-- Only admins can modify factors (via backend for now)
CREATE POLICY "Admins can modify readiness factors"
    ON readiness_factors FOR ALL
    TO authenticated
    USING (false)  -- Requires admin role (future enhancement)
    WITH CHECK (false);

-- Comment
COMMENT ON POLICY "Patients can insert own readiness" ON daily_readiness IS 'BUILD 119: RBAC - Patients can only insert own data';
COMMENT ON POLICY "Therapists can insert for assigned patients" ON daily_readiness IS 'BUILD 119: RBAC - Therapists can insert for assigned patients';
COMMENT ON POLICY "Therapists can view assigned patients readiness" ON daily_readiness IS 'BUILD 119: RBAC - Therapists can view assigned patients data';
