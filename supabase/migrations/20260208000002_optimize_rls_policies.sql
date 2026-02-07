-- Optimize RLS policies to fix N+1 query patterns
-- Replace IN (SELECT...) with EXISTS for better performance

-- ============================================================
-- HELPER FUNCTION: Get patient ID for authenticated user
-- This function is cached and avoids repeated subqueries
-- ============================================================

CREATE OR REPLACE FUNCTION get_patient_id_for_auth_user()
RETURNS UUID AS $$
DECLARE
    patient_id UUID;
BEGIN
    -- Try by user_id first (fastest)
    SELECT id INTO patient_id
    FROM patients
    WHERE user_id = auth.uid()
    LIMIT 1;

    -- Fallback to email if needed
    IF patient_id IS NULL THEN
        SELECT id INTO patient_id
        FROM patients
        WHERE email = (auth.jwt() ->> 'email')
        LIMIT 1;
    END IF;

    RETURN patient_id;
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_patient_id_for_auth_user() TO authenticated;

-- ============================================================
-- OPTIMIZE workout_prescriptions RLS (if table exists)
-- ============================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'workout_prescriptions') THEN
        -- Drop existing policies
        DROP POLICY IF EXISTS "patient_view_own_prescriptions" ON workout_prescriptions;
        DROP POLICY IF EXISTS "therapist_view_prescriptions" ON workout_prescriptions;

        -- Recreate with optimized pattern
        CREATE POLICY "patient_view_own_prescriptions"
            ON workout_prescriptions FOR SELECT
            USING (patient_id = get_patient_id_for_auth_user());

        CREATE POLICY "therapist_view_prescriptions"
            ON workout_prescriptions FOR SELECT
            USING (EXISTS (
                SELECT 1 FROM therapist_patients tp
                WHERE tp.patient_id = workout_prescriptions.patient_id
                AND tp.therapist_id = auth.uid()
            ));
    END IF;
END $$;

-- ============================================================
-- OPTIMIZE daily_readiness RLS (if table exists)
-- ============================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'daily_readiness') THEN
        DROP POLICY IF EXISTS "Users can view own readiness" ON daily_readiness;
        DROP POLICY IF EXISTS "Users can insert own readiness" ON daily_readiness;

        CREATE POLICY "Users can view own readiness"
            ON daily_readiness FOR SELECT
            USING (patient_id = get_patient_id_for_auth_user());

        CREATE POLICY "Users can insert own readiness"
            ON daily_readiness FOR INSERT
            WITH CHECK (patient_id = get_patient_id_for_auth_user());
    END IF;
END $$;

-- ============================================================
-- OPTIMIZE body_comp_goals RLS (if table exists)
-- ============================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'body_comp_goals') THEN
        DROP POLICY IF EXISTS "Users can view own body comp goals" ON body_comp_goals;

        CREATE POLICY "Users can view own body comp goals"
            ON body_comp_goals FOR SELECT
            USING (patient_id = get_patient_id_for_auth_user());
    END IF;
END $$;

-- ============================================================
-- OPTIMIZE soap_notes RLS (if table exists)
-- ============================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'soap_notes') THEN
        DROP POLICY IF EXISTS "Patients can view own SOAP notes" ON soap_notes;
        DROP POLICY IF EXISTS "Therapists can view patient SOAP notes" ON soap_notes;

        CREATE POLICY "Patients can view own SOAP notes"
            ON soap_notes FOR SELECT
            USING (patient_id = get_patient_id_for_auth_user());

        CREATE POLICY "Therapists can view patient SOAP notes"
            ON soap_notes FOR SELECT
            USING (EXISTS (
                SELECT 1 FROM therapist_patients tp
                WHERE tp.patient_id = soap_notes.patient_id
                AND tp.therapist_id = auth.uid()
            ));
    END IF;
END $$;

-- ============================================================
-- OPTIMIZE clinical_assessments RLS (if table exists)
-- ============================================================

DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'clinical_assessments') THEN
        DROP POLICY IF EXISTS "Patients can view own clinical assessments" ON clinical_assessments;
        DROP POLICY IF EXISTS "Therapists can view patient clinical assessments" ON clinical_assessments;

        CREATE POLICY "Patients can view own clinical assessments"
            ON clinical_assessments FOR SELECT
            USING (patient_id = get_patient_id_for_auth_user());

        CREATE POLICY "Therapists can view patient clinical assessments"
            ON clinical_assessments FOR SELECT
            USING (EXISTS (
                SELECT 1 FROM therapist_patients tp
                WHERE tp.patient_id = clinical_assessments.patient_id
                AND tp.therapist_id = auth.uid()
            ));
    END IF;
END $$;

-- ============================================================
-- ADD INDEXES FOR RLS FUNCTION PERFORMANCE
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_patients_user_id
    ON patients(user_id);

CREATE INDEX IF NOT EXISTS idx_patients_email
    ON patients(email);

CREATE INDEX IF NOT EXISTS idx_therapist_patients_lookup
    ON therapist_patients(patient_id, therapist_id);

COMMENT ON FUNCTION get_patient_id_for_auth_user() IS 'Cached function to get patient ID for RLS - avoids N+1 queries';
