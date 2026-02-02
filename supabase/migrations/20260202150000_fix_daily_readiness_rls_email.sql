-- BUILD 385: Fix daily_readiness RLS with email fallback
-- Same pattern as notification tables - use email fallback for legacy patients

BEGIN;

-- Drop existing policies
DROP POLICY IF EXISTS "daily_readiness_patient_access" ON daily_readiness;
DROP POLICY IF EXISTS "daily_readiness_therapist_view" ON daily_readiness;

-- Patient SELECT: Can view their own readiness
CREATE POLICY "daily_readiness_select"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patient INSERT: Can create their own readiness
CREATE POLICY "daily_readiness_insert"
    ON daily_readiness FOR INSERT
    TO authenticated
    WITH CHECK (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patient UPDATE: Can update their own readiness
CREATE POLICY "daily_readiness_update"
    ON daily_readiness FOR UPDATE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- Patient DELETE: Can delete their own readiness
CREATE POLICY "daily_readiness_delete"
    ON daily_readiness FOR DELETE
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            WHERE p.user_id = auth.uid()
               OR p.email = (auth.jwt() ->> 'email')
        )
    );

-- Therapist access: can view readiness for their patients
CREATE POLICY "daily_readiness_therapist_view"
    ON daily_readiness FOR SELECT
    TO authenticated
    USING (
        patient_id IN (
            SELECT p.id FROM patients p
            JOIN therapists t ON p.therapist_id = t.id
            WHERE t.user_id = auth.uid()
               OR t.email = (auth.jwt() ->> 'email')
        )
    );

COMMIT;
