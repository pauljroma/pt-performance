-- Fix program_enrollments RLS to include email fallback
-- Build 441+ - Fix: Users matched by email (legacy records) can see enrollments
--
-- Problem: paul@romatech.com's patient record may not have user_id set,
-- so the RLS policy (user_id = auth.uid()) fails even though email matches.
-- Solution: Add email fallback like other tables use.

-- ============================================================================
-- Drop existing policies
-- ============================================================================

DROP POLICY IF EXISTS "Patients can view own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can insert own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can update own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can delete own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Therapists can view patient enrollments" ON program_enrollments;

-- ============================================================================
-- Recreate policies with email fallback
-- ============================================================================

-- Patients can view their own enrollments (user_id OR email match)
CREATE POLICY "Patients can view own enrollments"
    ON program_enrollments FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can insert their own enrollments
CREATE POLICY "Patients can insert own enrollments"
    ON program_enrollments FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can update their own enrollments
CREATE POLICY "Patients can update own enrollments"
    ON program_enrollments FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- Patients can delete their own enrollments
CREATE POLICY "Patients can delete own enrollments"
    ON program_enrollments FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
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
-- Also fix user_id for paul@romatech.com if missing
-- ============================================================================

-- Update patients records to set user_id from auth.users if email matches
UPDATE patients p
SET user_id = au.id
FROM auth.users au
WHERE p.email = au.email
  AND p.user_id IS NULL;

-- ============================================================================
-- Summary
-- ============================================================================

DO $$
DECLARE
    updated_count INT;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM patients
    WHERE user_id IS NOT NULL;

    RAISE NOTICE 'Program enrollments RLS policies updated with email fallback';
    RAISE NOTICE 'Patients with user_id set: %', updated_count;
END $$;
