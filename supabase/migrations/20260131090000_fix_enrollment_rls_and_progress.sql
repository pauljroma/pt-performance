-- BUILD 341 Fix: RLS policies for program_enrollments and progress tracking

-- ============================================================================
-- 1. Fix RLS policies for program_enrollments
-- ============================================================================

-- Drop existing policies (they reference auth.uid() but patients use patients.id)
DROP POLICY IF EXISTS "Patients can view own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can insert own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can update own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Patients can delete own enrollments" ON program_enrollments;
DROP POLICY IF EXISTS "Therapists can view patient enrollments" ON program_enrollments;

-- Recreate policies using the patients table to get the actual patient record
-- Patient's auth.uid() maps to patients.user_id, not patients.id

-- Patients can view their own enrollments
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
-- 2. Add program_library_id to program_workout_assignments for progress tracking
-- ============================================================================

-- The progress tracking query needs to find which program_library entry a template belongs to
-- program_workout_assignments has program_id (references programs table)
-- program_library has program_id (references programs table)
-- So we need to join through programs, not add a new column

-- Actually, the service code is wrong - it's looking for program_library_id
-- but the table uses program_id which references the programs table
-- The fix should be in the Swift code, but let's also create a view for easier querying

-- Create a view that joins program_workout_assignments with program_library
CREATE OR REPLACE VIEW vw_program_template_assignments AS
SELECT
    pwa.id,
    pwa.program_id,
    pwa.template_id,
    pwa.phase_id,
    pwa.week_number,
    pwa.day_of_week,
    pwa.sequence,
    pl.id as program_library_id,
    pl.title as program_title,
    pl.category as program_category
FROM program_workout_assignments pwa
JOIN program_library pl ON pl.program_id = pwa.program_id;

-- Grant access to the view
GRANT SELECT ON vw_program_template_assignments TO authenticated;
GRANT SELECT ON vw_program_template_assignments TO anon;

-- ============================================================================
-- 3. Verify policies
-- ============================================================================

DO $$
BEGIN
    RAISE NOTICE 'RLS policies updated for program_enrollments';
    RAISE NOTICE 'Created vw_program_template_assignments view for progress tracking';
END $$;
