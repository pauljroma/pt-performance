-- Build 446: Fix program_enrollments RLS with email fallback
--
-- Problem: program_enrollments RLS only checks user_id = auth.uid()
-- but paul@romatech.com's patient record may not have user_id linked
-- Solution: Add email fallback pattern like other RLS policies

-- ============================================================================
-- Drop existing SELECT policy and recreate with email fallback
-- ============================================================================

DROP POLICY IF EXISTS "Patients can view own enrollments" ON program_enrollments;

CREATE POLICY "Patients can view own enrollments"
    ON program_enrollments FOR SELECT
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- Also fix UPDATE policy
DROP POLICY IF EXISTS "Patients can update own enrollments" ON program_enrollments;

CREATE POLICY "Patients can update own enrollments"
    ON program_enrollments FOR UPDATE
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- Also fix DELETE policy
DROP POLICY IF EXISTS "Patients can delete own enrollments" ON program_enrollments;

CREATE POLICY "Patients can delete own enrollments"
    ON program_enrollments FOR DELETE
    USING (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- Also fix INSERT policy with email fallback
DROP POLICY IF EXISTS "Patients can insert own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Allow authenticated users to enroll" ON program_enrollments;

CREATE POLICY "Patients can insert own enrollments"
    ON program_enrollments FOR INSERT
    WITH CHECK (
        patient_id IN (
            SELECT id FROM patients
            WHERE user_id = auth.uid()
               OR email = (auth.jwt() ->> 'email')
        )
    );

-- ============================================================================
-- Verify the fix
-- ============================================================================

DO $$
DECLARE
    v_count INT;
    v_patient_id UUID := '743bbbd4-771a-418e-b161-a7a9e88c83e7'::UUID;
BEGIN
    -- Count enrollments for paul@romatech.com
    SELECT COUNT(*) INTO v_count
    FROM program_enrollments
    WHERE patient_id = v_patient_id;

    RAISE NOTICE 'program_enrollments for paul@romatech.com: % rows', v_count;

    -- List enrolled programs
    PERFORM pe.id, pl.title
    FROM program_enrollments pe
    JOIN program_library pl ON pl.id = pe.program_library_id
    WHERE pe.patient_id = v_patient_id
      AND pe.status = 'active';

    RAISE NOTICE 'Active enrollments found: %', FOUND;
END $$;
