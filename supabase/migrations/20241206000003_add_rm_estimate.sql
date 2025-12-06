-- Add rm_estimate column to exercise_logs
ALTER TABLE exercise_logs
ADD COLUMN IF NOT EXISTS rm_estimate DECIMAL(10,2);

COMMENT ON COLUMN exercise_logs.rm_estimate IS 'Estimated 1RM calculated using Epley formula: weight × (1 + reps / 30)';

-- Create calculation function using Epley formula
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

-- Create trigger function to auto-calculate rm_estimate
CREATE OR REPLACE FUNCTION update_rm_estimate()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.actual_load IS NOT NULL AND NEW.actual_load > 0 AND NEW.actual_reps IS NOT NULL THEN
        NEW.rm_estimate = calculate_rm_estimate(NEW.actual_load, NEW.actual_reps);
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

-- Backfill rm_estimate for existing logs
UPDATE exercise_logs
SET rm_estimate = calculate_rm_estimate(actual_load, actual_reps)
WHERE actual_load IS NOT NULL
  AND actual_load > 0
  AND actual_reps IS NOT NULL
  AND rm_estimate IS NULL;

-- 6. Create index for rm_estimate queries
CREATE INDEX IF NOT EXISTS idx_exercise_logs_rm_estimate
ON exercise_logs(patient_id, rm_estimate DESC)
WHERE rm_estimate IS NOT NULL;

COMMENT ON INDEX idx_exercise_logs_rm_estimate IS 'Index for querying patient 1RM progression';

-- View creation removed due to schema differences
-- Can be added later after verifying column names

-- Additional functions and views removed due to schema differences
-- Core functionality (column, trigger, backfill, index) deployed successfully
