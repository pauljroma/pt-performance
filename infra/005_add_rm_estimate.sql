-- =====================================================
-- 005_add_rm_estimate.sql
-- Add rm_estimate column to exercise_logs with backfill
-- =====================================================
-- Purpose: Track estimated 1RM for each exercise log entry
-- Uses: Epley formula for consistent estimation
-- Related: ACP-59, ACP-58
-- =====================================================

-- 1. Add rm_estimate column to exercise_logs table
ALTER TABLE exercise_logs
ADD COLUMN IF NOT EXISTS rm_estimate DECIMAL(10,2);

COMMENT ON COLUMN exercise_logs.rm_estimate IS 'Estimated 1RM calculated using Epley formula: weight × (1 + reps / 30)';

-- 2. Create calculation function using Epley formula
CREATE OR REPLACE FUNCTION calculate_rm_estimate(weight DECIMAL, reps INT)
RETURNS DECIMAL AS $$
BEGIN
    -- Guard against invalid inputs
    IF weight IS NULL OR weight <= 0 OR reps IS NULL OR reps <= 0 THEN
        RETURN NULL;
    END IF;

    -- Epley formula: 1RM = weight × (1 + reps / 30)
    RETURN ROUND(weight * (1 + reps / 30.0), 2);
END;
$$ LANGUAGE plpgsql IMMUTABLE;

COMMENT ON FUNCTION calculate_rm_estimate IS 'Calculate estimated 1RM using Epley formula';

-- 3. Create trigger function to auto-calculate rm_estimate
CREATE OR REPLACE FUNCTION update_rm_estimate()
RETURNS TRIGGER AS $$
BEGIN
    -- Only calculate if we have valid load and reps
    IF NEW.actual_load IS NOT NULL AND NEW.actual_load > 0 THEN
        -- Use the first rep count if actual_reps is an array
        -- In PostgreSQL with JSONB array: actual_reps[0]
        -- For simplicity, use actual_sets as proxy for single set reps
        IF NEW.actual_reps IS NOT NULL THEN
            -- If actual_reps is stored as integer (single value)
            IF pg_typeof(NEW.actual_reps) = 'integer'::regtype THEN
                NEW.rm_estimate = calculate_rm_estimate(NEW.actual_load, NEW.actual_reps);
            -- If actual_reps is stored as JSONB array, extract first value
            ELSIF pg_typeof(NEW.actual_reps) = 'jsonb'::regtype THEN
                NEW.rm_estimate = calculate_rm_estimate(
                    NEW.actual_load,
                    (NEW.actual_reps->0)::int
                );
            END IF;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION update_rm_estimate IS 'Trigger function to auto-calculate rm_estimate on insert/update';

-- 4. Create trigger on exercise_logs
DROP TRIGGER IF EXISTS exercise_logs_rm_estimate ON exercise_logs;

CREATE TRIGGER exercise_logs_rm_estimate
BEFORE INSERT OR UPDATE ON exercise_logs
FOR EACH ROW EXECUTE FUNCTION update_rm_estimate();

-- 5. Backfill rm_estimate for existing logs
UPDATE exercise_logs
SET rm_estimate = calculate_rm_estimate(
    actual_load,
    CASE
        -- Handle different storage types for actual_reps
        WHEN pg_typeof(actual_reps) = 'integer'::regtype THEN actual_reps
        WHEN pg_typeof(actual_reps) = 'jsonb'::regtype THEN (actual_reps->0)::int
        ELSE NULL
    END
)
WHERE actual_load IS NOT NULL
  AND actual_load > 0
  AND actual_reps IS NOT NULL
  AND rm_estimate IS NULL;

-- 6. Create index for rm_estimate queries
CREATE INDEX IF NOT EXISTS idx_exercise_logs_rm_estimate
ON exercise_logs(patient_id, rm_estimate DESC)
WHERE rm_estimate IS NOT NULL;

COMMENT ON INDEX idx_exercise_logs_rm_estimate IS 'Index for querying patient 1RM progression';

-- 7. Create view for 1RM progression tracking
CREATE OR REPLACE VIEW vw_rm_progression AS
SELECT
    el.patient_id,
    se.exercise_template_id,
    et.exercise_name,
    DATE(el.logged_at) as log_date,
    el.actual_load,
    el.actual_reps,
    el.rm_estimate,
    MAX(el.rm_estimate) OVER (
        PARTITION BY el.patient_id, se.exercise_template_id
        ORDER BY el.logged_at
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) as max_rm_to_date,
    RANK() OVER (
        PARTITION BY el.patient_id, se.exercise_template_id
        ORDER BY el.rm_estimate DESC
    ) as rm_rank
FROM exercise_logs el
JOIN session_exercises se ON el.session_exercise_id = se.id
JOIN exercise_templates et ON se.exercise_template_id = et.id
WHERE el.rm_estimate IS NOT NULL
ORDER BY el.patient_id, et.exercise_name, el.logged_at DESC;

COMMENT ON VIEW vw_rm_progression IS 'Track 1RM progression by patient and exercise';

-- 8. Create function to get current 1RM for an exercise
CREATE OR REPLACE FUNCTION get_current_1rm(
    p_patient_id UUID,
    p_exercise_name TEXT
)
RETURNS TABLE (
    exercise_name TEXT,
    current_1rm DECIMAL,
    max_1rm DECIMAL,
    logged_at TIMESTAMPTZ,
    days_ago INT
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        et.exercise_name,
        el.rm_estimate as current_1rm,
        MAX(el.rm_estimate) OVER (PARTITION BY et.id) as max_1rm,
        el.logged_at,
        EXTRACT(DAY FROM NOW() - el.logged_at)::INT as days_ago
    FROM exercise_logs el
    JOIN session_exercises se ON el.session_exercise_id = se.id
    JOIN exercise_templates et ON se.exercise_template_id = et.id
    WHERE el.patient_id = p_patient_id
      AND et.exercise_name ILIKE '%' || p_exercise_name || '%'
      AND el.rm_estimate IS NOT NULL
    ORDER BY el.logged_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql;

COMMENT ON FUNCTION get_current_1rm IS 'Get most recent 1RM estimate for a patient and exercise';

-- 9. Validation query
DO $$
DECLARE
    backfilled_count INT;
    total_count INT;
BEGIN
    SELECT COUNT(*) INTO backfilled_count
    FROM exercise_logs
    WHERE rm_estimate IS NOT NULL;

    SELECT COUNT(*) INTO total_count
    FROM exercise_logs
    WHERE actual_load IS NOT NULL AND actual_load > 0;

    RAISE NOTICE '✅ Backfilled % out of % eligible exercise logs with rm_estimate',
        backfilled_count, total_count;

    IF backfilled_count = 0 AND total_count > 0 THEN
        RAISE WARNING '⚠️  No rm_estimate values calculated. Check actual_reps column type.';
    END IF;
END $$;

-- =====================================================
-- Example queries
-- =====================================================

/*
-- Get 1RM progression for a patient's back squat
SELECT * FROM vw_rm_progression
WHERE patient_id = 'patient-uuid'
  AND exercise_name ILIKE '%squat%'
ORDER BY log_date DESC
LIMIT 10;

-- Get current 1RM for bench press
SELECT * FROM get_current_1rm(
    'patient-uuid',
    'bench press'
);

-- Manual calculation for specific log
SELECT
    actual_load,
    actual_reps,
    calculate_rm_estimate(actual_load, actual_reps) as estimated_1rm
FROM exercise_logs
WHERE id = 'log-uuid';
*/
