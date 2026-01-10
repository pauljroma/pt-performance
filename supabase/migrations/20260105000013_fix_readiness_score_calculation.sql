-- Fix readiness score calculation - BUILD 116
-- The trigger was trying to query the table before the row was inserted

-- Drop the old trigger and function
DROP TRIGGER IF EXISTS auto_calculate_readiness_trigger ON daily_readiness;
DROP FUNCTION IF EXISTS auto_calculate_readiness_score();

-- Create new function that calculates inline without querying
CREATE OR REPLACE FUNCTION auto_calculate_readiness_score()
RETURNS TRIGGER AS $$
DECLARE
    v_sleep_score numeric;
    v_soreness_score numeric;
    v_energy_score numeric;
    v_stress_score numeric;
    v_total_score numeric;
BEGIN
    -- Only calculate if we have at least one metric
    IF NEW.sleep_hours IS NULL AND
       NEW.soreness_level IS NULL AND
       NEW.energy_level IS NULL AND
       NEW.stress_level IS NULL THEN
        RETURN NEW;
    END IF;

    -- Calculate component scores (normalize to 0-100)
    -- Sleep: optimal is 7-9 hours
    v_sleep_score = CASE
        WHEN NEW.sleep_hours IS NULL THEN 50
        WHEN NEW.sleep_hours >= 7 AND NEW.sleep_hours <= 9 THEN 100
        WHEN NEW.sleep_hours >= 6 AND NEW.sleep_hours < 7 THEN 80
        WHEN NEW.sleep_hours > 9 AND NEW.sleep_hours <= 10 THEN 80
        WHEN NEW.sleep_hours >= 5 AND NEW.sleep_hours < 6 THEN 60
        WHEN NEW.sleep_hours > 10 AND NEW.sleep_hours <= 11 THEN 60
        ELSE 40
    END;

    -- Soreness: inverse score (lower soreness = higher score)
    v_soreness_score = CASE
        WHEN NEW.soreness_level IS NULL THEN 50
        ELSE 100 - ((NEW.soreness_level - 1) * 11.11)
    END;

    -- Energy: direct score (higher energy = higher score)
    v_energy_score = CASE
        WHEN NEW.energy_level IS NULL THEN 50
        ELSE (NEW.energy_level - 1) * 11.11
    END;

    -- Stress: inverse score (lower stress = higher score)
    v_stress_score = CASE
        WHEN NEW.stress_level IS NULL THEN 50
        ELSE 100 - ((NEW.stress_level - 1) * 11.11)
    END;

    -- Calculate weighted total using default weights
    v_total_score =
        (v_sleep_score * 0.35) +
        (v_soreness_score * 0.25) +
        (v_energy_score * 0.20) +
        (v_stress_score * 0.15);

    -- Round to 1 decimal place
    NEW.readiness_score = ROUND(v_total_score, 1);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Recreate the trigger
CREATE TRIGGER auto_calculate_readiness_trigger
    BEFORE INSERT OR UPDATE ON daily_readiness
    FOR EACH ROW
    EXECUTE FUNCTION auto_calculate_readiness_score();

COMMENT ON FUNCTION auto_calculate_readiness_score IS
    'Automatically calculate and update readiness score inline (BUILD 116 fix)';
