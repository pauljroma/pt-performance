-- Fix remaining schema issues for Build 44
-- 1. Rename 'resolved' to 'is_resolved' in workload_flags (for Swift CodingKeys)
-- 2. Fix null duration_weeks in programs

-- 1. Rename resolved column to is_resolved
-- Swift auto-converts isResolved -> is_resolved in snake_case, but we have 'resolved'
ALTER TABLE workload_flags
RENAME COLUMN resolved TO is_resolved;

-- 2. Update Winter Lift program duration_weeks
UPDATE programs
SET duration_weeks = 12
WHERE name = 'Winter Lift 3x/week' AND duration_weeks IS NULL;

-- Set default for future programs
ALTER TABLE programs
ALTER COLUMN duration_weeks SET DEFAULT 4;

-- Success message
DO $$
BEGIN
  RAISE NOTICE 'Final schema fixes applied:';
  RAISE NOTICE '✅ Renamed workload_flags.resolved → is_resolved';
  RAISE NOTICE '✅ Fixed Winter Lift duration_weeks (NULL → 12)';
  RAISE NOTICE '✅ Set default duration_weeks = 4';
END $$;
