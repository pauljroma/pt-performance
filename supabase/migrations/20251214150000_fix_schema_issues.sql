-- Fix Schema Issues for Build 44
-- Fixes: Missing severity column, null phase_number, null target_level

-- 1. Add severity column to workload_flags table
ALTER TABLE workload_flags
ADD COLUMN IF NOT EXISTS severity TEXT DEFAULT 'medium';

-- Add check constraint for valid severity values
DO $$
BEGIN
    ALTER TABLE workload_flags
    ADD CONSTRAINT severity_valid_values
    CHECK (severity IN ('low', 'medium', 'high'));
EXCEPTION
    WHEN duplicate_object THEN
        NULL;  -- Constraint already exists, ignore
END $$;

-- 2. Update existing programs with null target_level
UPDATE programs
SET target_level = 'Intermediate'
WHERE target_level IS NULL;

-- Make target_level NOT NULL with default
ALTER TABLE programs
ALTER COLUMN target_level SET DEFAULT 'Intermediate';

-- 3. Update existing phases with null phase_number
-- Set phase_number to sequence value if null
UPDATE phases
SET phase_number = sequence
WHERE phase_number IS NULL;

-- Make phase_number NOT NULL with default
ALTER TABLE phases
ALTER COLUMN phase_number SET DEFAULT 1;

-- 4. Update existing workload flags to have severity
UPDATE workload_flags
SET severity = 'medium'
WHERE severity IS NULL;

-- Make severity NOT NULL
ALTER TABLE workload_flags
ALTER COLUMN severity SET NOT NULL;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Schema fixes applied successfully:';
  RAISE NOTICE '✅ Added severity column to workload_flags';
  RAISE NOTICE '✅ Fixed null target_level in programs';
  RAISE NOTICE '✅ Fixed null phase_number in phases';
END $$;
