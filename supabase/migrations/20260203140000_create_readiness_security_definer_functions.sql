-- BUILD 404: Create SECURITY DEFINER functions for daily_readiness
-- These functions bypass RLS to allow demo patient access

-- ============================================================================
-- FUNCTION: get_daily_readiness
-- ============================================================================
-- Returns readiness data for a specific patient and date
-- Uses SECURITY DEFINER to bypass RLS restrictions

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
    SELECT row_to_json(dr.*)
    INTO result
    FROM daily_readiness dr
    WHERE dr.patient_id = p_patient_id::uuid
      AND dr.date = p_date::date;

    RETURN result;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION get_daily_readiness(TEXT, TEXT) TO authenticated;

-- ============================================================================
-- FUNCTION: upsert_daily_readiness
-- ============================================================================
-- Inserts or updates readiness data for a patient
-- Uses SECURITY DEFINER to bypass RLS restrictions
-- Returns the upserted record

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

    -- Return the upserted record
    SELECT row_to_json(dr.*)
    INTO result
    FROM daily_readiness dr
    WHERE dr.patient_id = v_patient_id
      AND dr.date = v_date;

    RETURN result;
END;
$$;

-- Grant execute to authenticated users
GRANT EXECUTE ON FUNCTION upsert_daily_readiness(TEXT, TEXT, NUMERIC, INTEGER, INTEGER, INTEGER, TEXT) TO authenticated;

COMMENT ON FUNCTION get_daily_readiness(TEXT, TEXT) IS 'BUILD 404: SECURITY DEFINER function to read daily readiness bypassing RLS';
COMMENT ON FUNCTION upsert_daily_readiness(TEXT, TEXT, NUMERIC, INTEGER, INTEGER, INTEGER, TEXT) IS 'BUILD 404: SECURITY DEFINER function to write daily readiness bypassing RLS';
