-- Fix workload_flags schema to match iOS model
-- The iOS WorkloadFlag model expects different columns than what currently exists

-- 1. Add missing columns required by iOS model
ALTER TABLE workload_flags
ADD COLUMN IF NOT EXISTS flag_type TEXT,
ADD COLUMN IF NOT EXISTS message TEXT,
ADD COLUMN IF NOT EXISTS value NUMERIC,
ADD COLUMN IF NOT EXISTS threshold NUMERIC,
ADD COLUMN IF NOT EXISTS timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 2. Drop old severity check constraint first
ALTER TABLE workload_flags
DROP CONSTRAINT IF EXISTS severity_valid_values;

-- 3. Update severity values to match iOS enum ("yellow" or "red" instead of "low", "medium", "high")
-- Map: low -> yellow, medium -> yellow, high -> red
UPDATE workload_flags
SET severity = CASE
    WHEN severity = 'high' THEN 'red'
    WHEN severity = 'medium' THEN 'yellow'
    WHEN severity = 'low' THEN 'yellow'
    ELSE 'yellow'
END;

-- 4. Add new severity check constraint
DO $$
BEGIN
    ALTER TABLE workload_flags
    ADD CONSTRAINT severity_valid_values
    CHECK (severity IN ('yellow', 'red'));
EXCEPTION
    WHEN duplicate_object THEN
        NULL;  -- Constraint already exists, ignore
END $$;

-- 5. Populate the new columns with data derived from existing boolean flags
-- Determine flag_type based on which boolean is true
UPDATE workload_flags
SET
    flag_type = CASE
        WHEN high_acwr THEN 'high_workload'
        WHEN low_acwr THEN 'velocity_drop'
        WHEN joint_pain THEN 'pain_increase'
        WHEN rpe_overshoot THEN 'high_workload'
        WHEN missed_reps THEN 'velocity_drop'
        WHEN readiness_low THEN 'consecutive_days'
        WHEN deload_triggered THEN 'high_workload'
        ELSE 'high_workload'
    END,
    message = CASE
        WHEN high_acwr THEN CONCAT('High acute:chronic workload ratio (ACWR: ', ROUND(acwr::numeric, 2), ')')
        WHEN low_acwr THEN CONCAT('Low acute:chronic workload ratio (ACWR: ', ROUND(acwr::numeric, 2), ')')
        WHEN joint_pain THEN 'Joint pain reported during session'
        WHEN rpe_overshoot THEN 'RPE exceeded target intensity'
        WHEN missed_reps THEN 'Missed prescribed reps - possible fatigue'
        WHEN readiness_low THEN 'Low readiness score detected'
        WHEN deload_triggered THEN CONCAT('Deload period triggered', COALESCE(': ' || deload_reason, ''))
        ELSE 'Workload monitoring flag'
    END,
    value = COALESCE(acwr, chronic_workload, acute_workload, 0),
    threshold = CASE
        WHEN high_acwr THEN 1.5
        WHEN low_acwr THEN 0.8
        ELSE 1.0
    END,
    timestamp = COALESCE(calculated_at, created_at, NOW())
WHERE flag_type IS NULL;

-- 6. Make the new columns NOT NULL with defaults for future inserts
ALTER TABLE workload_flags
ALTER COLUMN flag_type SET DEFAULT 'high_workload';

ALTER TABLE workload_flags
ALTER COLUMN message SET DEFAULT 'Workload monitoring flag';

ALTER TABLE workload_flags
ALTER COLUMN value SET DEFAULT 0;

ALTER TABLE workload_flags
ALTER COLUMN threshold SET DEFAULT 1.0;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Workload flags schema updated successfully:';
  RAISE NOTICE '✅ Added flag_type, message, value, threshold, timestamp columns';
  RAISE NOTICE '✅ Updated severity values to match iOS enum (yellow/red)';
  RAISE NOTICE '✅ Populated new columns from existing boolean flags';
END $$;
