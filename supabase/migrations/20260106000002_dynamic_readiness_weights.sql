-- BUILD 118: Dynamic Readiness Factor Weights
-- Update trigger to query readiness_factors table instead of hard-coded weights

-- ============================================================================
-- UPDATE TRIGGER FUNCTION
-- ============================================================================

CREATE OR REPLACE FUNCTION auto_calculate_readiness_score()
RETURNS TRIGGER AS $$
DECLARE
    v_sleep_score numeric;
    v_soreness_score numeric;
    v_energy_score numeric;
    v_stress_score numeric;
    v_total_score numeric;

    -- Dynamic weights from readiness_factors table
    v_sleep_weight numeric := 0.35;    -- Default fallback
    v_soreness_weight numeric := 0.25;
    v_energy_weight numeric := 0.20;
    v_stress_weight numeric := 0.15;

    v_factors_found boolean := false;
BEGIN
    -- Only calculate if we have at least one metric
    IF NEW.sleep_hours IS NULL AND
       NEW.soreness_level IS NULL AND
       NEW.energy_level IS NULL AND
       NEW.stress_level IS NULL THEN
        RETURN NEW;
    END IF;

    -- ========================================================================
    -- QUERY ACTIVE READINESS FACTORS FOR DYNAMIC WEIGHTS
    -- ========================================================================

    BEGIN
        -- Get weights for active factors
        SELECT
            MAX(CASE WHEN factor_name = 'sleep_hours' THEN weight END),
            MAX(CASE WHEN factor_name = 'soreness_level' THEN weight END),
            MAX(CASE WHEN factor_name = 'energy_level' THEN weight END),
            MAX(CASE WHEN factor_name = 'stress_level' THEN weight END)
        INTO
            v_sleep_weight,
            v_soreness_weight,
            v_energy_weight,
            v_stress_weight
        FROM readiness_factors
        WHERE is_active = true;

        -- Check if we got any weights
        IF v_sleep_weight IS NOT NULL OR
           v_soreness_weight IS NOT NULL OR
           v_energy_weight IS NOT NULL OR
           v_stress_weight IS NOT NULL THEN
            v_factors_found := true;

            -- Use defaults for any NULL weights
            v_sleep_weight := COALESCE(v_sleep_weight, 0.35);
            v_soreness_weight := COALESCE(v_soreness_weight, 0.25);
            v_energy_weight := COALESCE(v_energy_weight, 0.20);
            v_stress_weight := COALESCE(v_stress_weight, 0.15);
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            -- If readiness_factors query fails, use default weights
            v_factors_found := false;
            v_sleep_weight := 0.35;
            v_soreness_weight := 0.25;
            v_energy_weight := 0.20;
            v_stress_weight := 0.15;
    END;

    -- ========================================================================
    -- CALCULATE COMPONENT SCORES (same as BUILD 117)
    -- ========================================================================

    -- Sleep hours score (0-100)
    v_sleep_score := CASE
        WHEN NEW.sleep_hours IS NULL THEN 50
        WHEN NEW.sleep_hours >= 7 AND NEW.sleep_hours <= 9 THEN 100
        WHEN NEW.sleep_hours >= 6 AND NEW.sleep_hours < 7 THEN 80
        WHEN NEW.sleep_hours > 9 AND NEW.sleep_hours <= 10 THEN 80
        WHEN NEW.sleep_hours >= 5 AND NEW.sleep_hours < 6 THEN 60
        WHEN NEW.sleep_hours > 10 AND NEW.sleep_hours <= 11 THEN 60
        WHEN NEW.sleep_hours >= 4 AND NEW.sleep_hours < 5 THEN 40
        WHEN NEW.sleep_hours > 11 THEN 40
        ELSE 20
    END;

    -- Soreness level score (1-10 scale, inverted to 0-100)
    v_soreness_score := CASE
        WHEN NEW.soreness_level IS NULL THEN 50
        WHEN NEW.soreness_level = 1 THEN 100
        WHEN NEW.soreness_level = 2 THEN 90
        WHEN NEW.soreness_level = 3 THEN 80
        WHEN NEW.soreness_level = 4 THEN 70
        WHEN NEW.soreness_level = 5 THEN 60
        WHEN NEW.soreness_level = 6 THEN 50
        WHEN NEW.soreness_level = 7 THEN 40
        WHEN NEW.soreness_level = 8 THEN 30
        WHEN NEW.soreness_level = 9 THEN 20
        WHEN NEW.soreness_level = 10 THEN 10
        ELSE 50
    END;

    -- Energy level score (1-10 scale, direct to 0-100)
    v_energy_score := CASE
        WHEN NEW.energy_level IS NULL THEN 50
        WHEN NEW.energy_level = 10 THEN 100
        WHEN NEW.energy_level = 9 THEN 90
        WHEN NEW.energy_level = 8 THEN 80
        WHEN NEW.energy_level = 7 THEN 70
        WHEN NEW.energy_level = 6 THEN 60
        WHEN NEW.energy_level = 5 THEN 50
        WHEN NEW.energy_level = 4 THEN 40
        WHEN NEW.energy_level = 3 THEN 30
        WHEN NEW.energy_level = 2 THEN 20
        WHEN NEW.energy_level = 1 THEN 10
        ELSE 50
    END;

    -- Stress level score (1-10 scale, inverted to 0-100)
    v_stress_score := CASE
        WHEN NEW.stress_level IS NULL THEN 50
        WHEN NEW.stress_level = 1 THEN 100
        WHEN NEW.stress_level = 2 THEN 90
        WHEN NEW.stress_level = 3 THEN 80
        WHEN NEW.stress_level = 4 THEN 70
        WHEN NEW.stress_level = 5 THEN 60
        WHEN NEW.stress_level = 6 THEN 50
        WHEN NEW.stress_level = 7 THEN 40
        WHEN NEW.stress_level = 8 THEN 30
        WHEN NEW.stress_level = 9 THEN 20
        WHEN NEW.stress_level = 10 THEN 10
        ELSE 50
    END;

    -- ========================================================================
    -- CALCULATE WEIGHTED TOTAL (using dynamic or default weights)
    -- ========================================================================

    v_total_score :=
        (v_sleep_score * v_sleep_weight) +
        (v_soreness_score * v_soreness_weight) +
        (v_energy_score * v_energy_weight) +
        (v_stress_score * v_stress_weight);

    -- Normalize to remaining weight if not all factors provided
    -- (This ensures score is still 0-100 even with missing data)
    DECLARE
        v_provided_weight numeric := 0;
    BEGIN
        IF NEW.sleep_hours IS NOT NULL THEN
            v_provided_weight := v_provided_weight + v_sleep_weight;
        END IF;
        IF NEW.soreness_level IS NOT NULL THEN
            v_provided_weight := v_provided_weight + v_soreness_weight;
        END IF;
        IF NEW.energy_level IS NOT NULL THEN
            v_provided_weight := v_provided_weight + v_energy_weight;
        END IF;
        IF NEW.stress_level IS NOT NULL THEN
            v_provided_weight := v_provided_weight + v_stress_weight;
        END IF;

        -- Normalize if we don't have all factors
        IF v_provided_weight > 0 AND v_provided_weight < 1.0 THEN
            v_total_score := v_total_score / v_provided_weight;
        END IF;
    END;

    -- Round to 1 decimal place and ensure 0-100 range
    NEW.readiness_score := ROUND(LEAST(GREATEST(v_total_score, 0), 100), 1);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Ensure trigger exists
DO $check$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_trigger WHERE tgname = 'calculate_readiness_score_trigger'
    ) THEN
        -- Create trigger if it doesn't exist
        CREATE TRIGGER calculate_readiness_score_trigger
            BEFORE INSERT OR UPDATE ON daily_readiness
            FOR EACH ROW
            EXECUTE FUNCTION auto_calculate_readiness_score();
    END IF;
END $check$;

-- Add helpful comment
COMMENT ON FUNCTION auto_calculate_readiness_score() IS
'BUILD 118 - Calculates readiness score using dynamic weights from readiness_factors table. Falls back to defaults (0.35/0.25/0.20/0.15) if factors not found.';

-- ============================================================================
-- ROLLBACK PLAN
-- ============================================================================

-- To rollback to BUILD 117 hard-coded weights, run migration 20260105000013
