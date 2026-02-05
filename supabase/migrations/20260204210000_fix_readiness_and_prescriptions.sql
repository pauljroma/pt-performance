-- ============================================================================
-- COMBINED MIGRATION: Fix Readiness RPC + Workout Prescriptions RLS
-- ============================================================================

-- ============================================================================
-- PART 1: Fix Daily Readiness RPC Functions
-- ============================================================================

CREATE OR REPLACE FUNCTION get_daily_readiness(
    p_patient_id TEXT,
    p_date TEXT
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result json;
BEGIN
    SELECT json_build_object(
        'id', dr.id,
        'patient_id', dr.patient_id,
        'date', dr.date,
        'sleep_hours', dr.sleep_hours,
        'soreness_level', dr.soreness_level,
        'energy_level', dr.energy_level,
        'stress_level', dr.stress_level,
        'readiness_score', dr.readiness_score,
        'notes', dr.notes,
        'created_at', dr.created_at,
        'updated_at', dr.updated_at
    )
    INTO result
    FROM daily_readiness dr
    WHERE dr.patient_id = p_patient_id::uuid
      AND dr.date = p_date::date;

    RETURN result;
END;
$$;

CREATE OR REPLACE FUNCTION upsert_daily_readiness(
    p_patient_id TEXT,
    p_date TEXT,
    p_sleep_hours NUMERIC DEFAULT NULL,
    p_soreness_level INTEGER DEFAULT NULL,
    p_energy_level INTEGER DEFAULT NULL,
    p_stress_level INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result json;
    v_patient_id uuid := p_patient_id::uuid;
    v_date date := p_date::date;
BEGIN
    INSERT INTO daily_readiness (
        patient_id, date, sleep_hours, soreness_level, energy_level, stress_level, notes
    )
    VALUES (
        v_patient_id, v_date, p_sleep_hours, p_soreness_level, p_energy_level, p_stress_level, p_notes
    )
    ON CONFLICT (patient_id, date)
    DO UPDATE SET
        sleep_hours = COALESCE(EXCLUDED.sleep_hours, daily_readiness.sleep_hours),
        soreness_level = COALESCE(EXCLUDED.soreness_level, daily_readiness.soreness_level),
        energy_level = COALESCE(EXCLUDED.energy_level, daily_readiness.energy_level),
        stress_level = COALESCE(EXCLUDED.stress_level, daily_readiness.stress_level),
        notes = COALESCE(EXCLUDED.notes, daily_readiness.notes),
        updated_at = now();

    SELECT json_build_object(
        'id', dr.id,
        'patient_id', dr.patient_id,
        'date', dr.date,
        'sleep_hours', dr.sleep_hours,
        'soreness_level', dr.soreness_level,
        'energy_level', dr.energy_level,
        'stress_level', dr.stress_level,
        'readiness_score', dr.readiness_score,
        'notes', dr.notes,
        'created_at', dr.created_at,
        'updated_at', dr.updated_at
    )
    INTO result
    FROM daily_readiness dr
    WHERE dr.patient_id = v_patient_id
      AND dr.date = v_date;

    RETURN result;
END;
$$;

GRANT EXECUTE ON FUNCTION get_daily_readiness(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_daily_readiness(TEXT, TEXT, NUMERIC, INTEGER, INTEGER, INTEGER, TEXT) TO authenticated;

-- ============================================================================
-- PART 2: Fix Workout Prescriptions RLS for Demo Mode
-- ============================================================================

DROP POLICY IF EXISTS therapist_create_prescriptions ON workout_prescriptions;

CREATE POLICY therapist_create_prescriptions ON workout_prescriptions
    FOR INSERT TO authenticated
    WITH CHECK (
        patient_id IN (SELECT id FROM patients WHERE therapist_id = auth.uid())
        OR
        (
            therapist_id IS NOT NULL
            AND patient_id IN (SELECT id FROM patients WHERE therapist_id = workout_prescriptions.therapist_id)
        )
    );

DROP POLICY IF EXISTS therapist_view_prescriptions ON workout_prescriptions;

CREATE POLICY therapist_view_prescriptions ON workout_prescriptions
    FOR SELECT TO authenticated
    USING (
        therapist_id = auth.uid()
        OR patient_id IN (SELECT id FROM patients WHERE therapist_id = auth.uid())
        OR patient_id IN (SELECT id FROM patients WHERE therapist_id = workout_prescriptions.therapist_id)
    );

DROP POLICY IF EXISTS therapist_update_prescriptions ON workout_prescriptions;

CREATE POLICY therapist_update_prescriptions ON workout_prescriptions
    FOR UPDATE TO authenticated
    USING (
        therapist_id = auth.uid()
        OR patient_id IN (SELECT id FROM patients WHERE therapist_id = workout_prescriptions.therapist_id)
    );

-- ============================================================================
-- Verification
-- ============================================================================
DO $$
BEGIN
    RAISE NOTICE 'Applied fixes:';
    RAISE NOTICE '  1. get_daily_readiness - Returns all fields explicitly';
    RAISE NOTICE '  2. upsert_daily_readiness - Returns all fields explicitly';
    RAISE NOTICE '  3. workout_prescriptions RLS - Supports demo mode';
END $$;
