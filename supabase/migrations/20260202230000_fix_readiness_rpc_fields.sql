-- BUILD 386: Fix get_daily_readiness RPC to include all required fields
-- The iOS DailyReadiness model requires created_at and updated_at fields

-- Recreate the get_daily_readiness function with all fields
CREATE OR REPLACE FUNCTION get_daily_readiness(
    p_patient_id UUID,
    p_date DATE
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'id', id,
        'patient_id', patient_id,
        'date', date,
        'sleep_hours', sleep_hours,
        'soreness_level', soreness_level,
        'energy_level', energy_level,
        'stress_level', stress_level,
        'readiness_score', readiness_score,
        'notes', notes,
        'created_at', created_at,
        'updated_at', updated_at
    )
    INTO result
    FROM daily_readiness
    WHERE patient_id = p_patient_id AND date = p_date;

    RETURN result;
END;
$$;

-- Also fix upsert_daily_readiness to include all fields
CREATE OR REPLACE FUNCTION upsert_daily_readiness(
    p_patient_id UUID,
    p_date DATE,
    p_sleep_hours DOUBLE PRECISION DEFAULT NULL,
    p_soreness_level INTEGER DEFAULT NULL,
    p_energy_level INTEGER DEFAULT NULL,
    p_stress_level INTEGER DEFAULT NULL,
    p_notes TEXT DEFAULT NULL
)
RETURNS JSON
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    result JSON;
BEGIN
    -- Insert or update the readiness record
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
        p_patient_id,
        p_date,
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
        updated_at = NOW()
    RETURNING json_build_object(
        'id', id,
        'patient_id', patient_id,
        'date', date,
        'sleep_hours', sleep_hours,
        'soreness_level', soreness_level,
        'energy_level', energy_level,
        'stress_level', stress_level,
        'readiness_score', readiness_score,
        'notes', notes,
        'created_at', created_at,
        'updated_at', updated_at
    ) INTO result;

    RETURN result;
END;
$$;

-- Ensure grants
GRANT EXECUTE ON FUNCTION get_daily_readiness TO authenticated;
GRANT EXECUTE ON FUNCTION upsert_daily_readiness TO authenticated;
