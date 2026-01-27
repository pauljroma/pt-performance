-- BUILD 286: Fix patient_workout_templates RLS policies
-- Error: "new row violates row-level security policy for table patient_workout_templates"
-- Root cause: INSERT policy may not exist or RLS may block without policies

-- Ensure RLS is enabled
ALTER TABLE IF EXISTS patient_workout_templates ENABLE ROW LEVEL SECURITY;

-- Drop existing policies to recreate cleanly
DROP POLICY IF EXISTS "patient_workout_templates_insert" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_select" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_update" ON patient_workout_templates;
DROP POLICY IF EXISTS "patient_workout_templates_delete" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_insert" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_select" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_update" ON patient_workout_templates;
DROP POLICY IF EXISTS "patients_own_workout_templates_delete" ON patient_workout_templates;

-- INSERT: Patients can create templates for themselves
-- Uses email-based matching: auth JWT email -> patients.email -> patients.id
CREATE POLICY "patient_workout_templates_insert"
ON patient_workout_templates
FOR INSERT
TO authenticated
WITH CHECK (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- SELECT: Patients can view their own templates
CREATE POLICY "patient_workout_templates_select"
ON patient_workout_templates
FOR SELECT
TO authenticated
USING (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- UPDATE: Patients can update their own templates
CREATE POLICY "patient_workout_templates_update"
ON patient_workout_templates
FOR UPDATE
TO authenticated
USING (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- DELETE: Patients can delete their own templates
CREATE POLICY "patient_workout_templates_delete"
ON patient_workout_templates
FOR DELETE
TO authenticated
USING (
    patient_id IN (
        SELECT p.id
        FROM patients p
        WHERE p.email = (auth.jwt() ->> 'email')
    )
);

-- Ensure grants
GRANT SELECT, INSERT, UPDATE, DELETE ON patient_workout_templates TO authenticated;
