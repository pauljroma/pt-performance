-- Migration: Fix Arm Care Assessments RLS for Demo Patient
-- Date: 2026-02-02
-- Purpose: Add demo patient policies to bypass cascading RLS issue
-- Same pattern as daily_readiness fix

-- ============================================================================
-- DEMO PATIENT RLS POLICIES
-- ============================================================================

-- Allow any authenticated user to view demo patient's arm care assessments
CREATE POLICY "arm_care_demo_patient_select"
    ON public.arm_care_assessments
    FOR SELECT
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Allow any authenticated user to insert demo patient's arm care assessments
CREATE POLICY "arm_care_demo_patient_insert"
    ON public.arm_care_assessments
    FOR INSERT
    TO authenticated
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Allow any authenticated user to update demo patient's arm care assessments
CREATE POLICY "arm_care_demo_patient_update"
    ON public.arm_care_assessments
    FOR UPDATE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid)
    WITH CHECK (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- Allow any authenticated user to delete demo patient's arm care assessments
CREATE POLICY "arm_care_demo_patient_delete"
    ON public.arm_care_assessments
    FOR DELETE
    TO authenticated
    USING (patient_id = '00000000-0000-0000-0000-000000000001'::uuid);

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
    -- Verify policies were created
    IF EXISTS (
        SELECT 1 FROM pg_policies
        WHERE tablename = 'arm_care_assessments'
          AND policyname LIKE 'arm_care_demo_patient%'
    ) THEN
        RAISE NOTICE '✅ Arm care demo patient policies created successfully';
    ELSE
        RAISE EXCEPTION 'Failed to create arm care demo patient policies';
    END IF;
END $$;
