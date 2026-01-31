-- BUILD 347 Fix: Re-apply RLS policies for program_enrollments
-- The previous migration was marked as applied but policies may not be correctly set

-- ============================================================================
-- 1. Drop ALL existing policies to start fresh
-- ============================================================================

DROP POLICY IF EXISTS "Patients can view own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can insert own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can update own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can delete own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Therapists can view patient enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Allow patients to enroll" ON program_enrollments;
DROP POLICY IF EXISTS "Allow all inserts for testing" ON program_enrollments;

-- ============================================================================
-- 2. Ensure RLS is enabled
-- ============================================================================

ALTER TABLE program_enrollments ENABLE ROW LEVEL SECURITY;

-- ============================================================================
-- 3. Create policies that work with the patients.user_id mapping
-- ============================================================================

-- Patients can view their own enrollments
-- auth.uid() = patients.user_id, not patients.id
CREATE POLICY "Patients can view own enrollments"
    ON program_enrollments FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Patients can insert their own enrollments
CREATE POLICY "Patients can insert own enrollments"
    ON program_enrollments FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Patients can update their own enrollments
CREATE POLICY "Patients can update own enrollments"
    ON program_enrollments FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Patients can delete their own enrollments
CREATE POLICY "Patients can delete own enrollments"
    ON program_enrollments FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE user_id = auth.uid()
        )
    );

-- Therapists can view their patients' enrollments
CREATE POLICY "Therapists can view patient enrollments"
    ON program_enrollments FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients WHERE therapist_id = auth.uid()
        )
    );

-- ============================================================================
-- 4. IMPORTANT: Update seed patient to have correct user_id
-- This ensures the logged-in user is linked to the seed patient
-- ============================================================================

-- First, let's create a function that updates the patient's user_id
-- when a user logs in and their patient record exists but has no user_id
CREATE OR REPLACE FUNCTION link_patient_to_user()
RETURNS TRIGGER AS $$
BEGIN
    -- If a patient record exists with this email but no user_id, link it
    UPDATE patients
    SET user_id = NEW.id
    WHERE email = NEW.email
    AND user_id IS NULL;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create trigger on auth.users (if it doesn't exist)
DROP TRIGGER IF EXISTS on_auth_user_created_link_patient ON auth.users;
CREATE TRIGGER on_auth_user_created_link_patient
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION link_patient_to_user();

-- ============================================================================
-- 5. Verify
-- ============================================================================

DO $$
DECLARE
    policy_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO policy_count
    FROM pg_policies
    WHERE tablename = 'program_enrollments';

    RAISE NOTICE 'Program enrollments now has % RLS policies', policy_count;
END $$;
