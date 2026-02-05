-- Fix RLS policies for workout_prescriptions table
-- Allow inserts where therapist_id matches a therapist who owns the patient
-- This supports both authenticated sessions AND demo mode

-- Drop existing insert policy
DROP POLICY IF EXISTS therapist_create_prescriptions ON workout_prescriptions;

-- Create updated insert policy
-- Allows insert if EITHER:
-- 1. The authenticated user (auth.uid()) owns the patient
-- 2. The therapist_id being inserted owns the patient (for demo mode)
CREATE POLICY therapist_create_prescriptions ON workout_prescriptions
    FOR INSERT TO authenticated
    WITH CHECK (
        -- Standard case: authenticated user owns the patient
        patient_id IN (SELECT id FROM patients WHERE therapist_id = auth.uid())
        OR
        -- Demo mode case: the therapist_id field matches someone who owns the patient
        (
            therapist_id IS NOT NULL
            AND patient_id IN (SELECT id FROM patients WHERE therapist_id = workout_prescriptions.therapist_id)
        )
    );

-- Also update select policy to support demo mode
DROP POLICY IF EXISTS therapist_view_prescriptions ON workout_prescriptions;

CREATE POLICY therapist_view_prescriptions ON workout_prescriptions
    FOR SELECT TO authenticated
    USING (
        therapist_id = auth.uid()
        OR patient_id IN (SELECT id FROM patients WHERE therapist_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE therapist_id = workout_prescriptions.therapist_id)
    );

-- Update update policy too
DROP POLICY IF EXISTS therapist_update_prescriptions ON workout_prescriptions;

CREATE POLICY therapist_update_prescriptions ON workout_prescriptions
    FOR UPDATE TO authenticated
    USING (
        therapist_id = auth.uid()
        OR patient_id IN (SELECT id FROM patients WHERE therapist_id = workout_prescriptions.therapist_id)
    );
