-- Fix Daily Readiness RPC to explicitly include all required fields
-- The iOS app requires created_at and updated_at fields
-- Using explicit JSON construction ensures all fields are present

-- ============================================================================
-- FUNCTION: get_daily_readiness (fixed version)
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

-- ============================================================================
-- FUNCTION: upsert_daily_readiness (fixed version)
-- ============================================================================
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
    -- Upsert the readiness record
    INSERT INTO daily_readiness (
        patient_id,
        date,
        sleep_hours,
        soreness_level,
        energy_level,
        stress_level,
        notes
    )
    VALUES (
        v_patient_id,
        v_date,
        p_sleep_hours,
        p_soreness_level,
        p_energy_level,
        p_stress_level,
        p_notes
    )
    ON CONFLICT (patient_id, date)
    DO UPDATE SET
        sleep_hours = COALESCE(EXCLUDED.sleep_hours, daily_readiness.sleep_hours),
        soreness_level = COALESCE(EXCLUDED.soreness_level, daily_readiness.soreness_level),
        energy_level = COALESCE(EXCLUDED.energy_level, daily_readiness.energy_level),
        stress_level = COALESCE(EXCLUDED.stress_level, daily_readiness.stress_level),
        notes = COALESCE(EXCLUDED.notes, daily_readiness.notes),
        updated_at = now();

    -- Return the upserted record with explicit fields
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

-- Grant execute permissions
GRANT EXECUTE ON FUNCTION get_daily_readiness(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_daily_readiness(TEXT, TEXT, NUMERIC, INTEGER, INTEGER, INTEGER, TEXT) TO authenticated;

-- Add comments
COMMENT ON FUNCTION get_daily_readiness(TEXT, TEXT) IS 'Build 417: Fixed SECURITY DEFINER function with explicit JSON fields for iOS compatibility';
COMMENT ON FUNCTION upsert_daily_readiness(TEXT, TEXT, NUMERIC, INTEGER, INTEGER, INTEGER, TEXT) IS 'Build 417: Fixed SECURITY DEFINER function with explicit JSON fields for iOS compatibility';

DO $$
BEGIN
    RAISE NOTICE 'Fixed Daily Readiness RPC functions:';
    RAISE NOTICE '  - get_daily_readiness: Now returns all fields explicitly including created_at/updated_at';
    RAISE NOTICE '  - upsert_daily_readiness: Now returns all fields explicitly';
END $$;
