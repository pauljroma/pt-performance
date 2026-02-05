-- ============================================================================
-- FIX: Drop ALL duplicate upsert_daily_readiness functions
-- ============================================================================
-- Error: "Could not choose the best candidate function between..."
-- Two signatures exist:
--   1. (uuid, date, double precision, integer, integer, integer, text)
--   2. (text, text, numeric, integer, integer, integer, text)
-- ============================================================================

-- Drop ALL possible signatures to ensure clean slate
DROP FUNCTION IF EXISTS upsert_daily_readiness(uuid, date, double precision, integer, integer, integer, text);
DROP FUNCTION IF EXISTS upsert_daily_readiness(uuid, date, numeric, integer, integer, integer, text);
DROP FUNCTION IF EXISTS upsert_daily_readiness(text, text, double precision, integer, integer, integer, text);
DROP FUNCTION IF EXISTS upsert_daily_readiness(text, text, numeric, integer, integer, integer, text);

-- Also drop get_daily_readiness duplicates
DROP FUNCTION IF EXISTS get_daily_readiness(uuid, date);
DROP FUNCTION IF EXISTS get_daily_readiness(text, text);

-- ============================================================================
-- Recreate ONLY the TEXT versions (matches iOS Swift client expectations)
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

-- Grant permissions
GRANT EXECUTE ON FUNCTION get_daily_readiness(TEXT, TEXT) TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_daily_readiness(TEXT, TEXT, NUMERIC, INTEGER, INTEGER, INTEGER, TEXT) TO authenticated;

-- Verify only one version exists
DO $$
DECLARE
    func_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO func_count
    FROM pg_proc p
    JOIN pg_namespace n ON p.pronamespace = n.oid
    WHERE n.nspname = 'public' AND p.proname = 'upsert_daily_readiness';

    IF func_count > 1 THEN
        RAISE EXCEPTION 'Multiple upsert_daily_readiness functions still exist: %', func_count;
    END IF;

    RAISE NOTICE 'Success: Only % version of upsert_daily_readiness exists', func_count;
END $$;
