-- BUILD 128: Backfill exercise_logs.session_id from session_exercises
-- This migration populates the session_id column for existing exercise logs
-- using the foreign key relationship through session_exercises

-- Step 1: Backfill session_id for exercise logs that have a session_exercise_id
UPDATE exercise_logs el
SET session_id = se.session_id
FROM session_exercises se
WHERE el.session_exercise_id::uuid = se.id
  AND el.session_id IS NULL;

-- Step 2: Verify backfill results
DO $$
DECLARE
    total_logs INTEGER;
    backfilled_logs INTEGER;
    orphaned_logs INTEGER;
BEGIN
    -- Count total logs
    SELECT COUNT(*) INTO total_logs FROM exercise_logs;

    -- Count backfilled logs
    SELECT COUNT(*) INTO backfilled_logs FROM exercise_logs WHERE session_id IS NOT NULL;

    -- Count orphaned logs (no session_id)
    SELECT COUNT(*) INTO orphaned_logs FROM exercise_logs WHERE session_id IS NULL;

    -- Log results
    RAISE NOTICE 'Backfill Results:';
    RAISE NOTICE '  Total exercise logs: %', total_logs;
    RAISE NOTICE '  Backfilled with session_id: % (%.1f%%)',
        backfilled_logs,
        CASE WHEN total_logs > 0 THEN (backfilled_logs::float / total_logs::float * 100) ELSE 0 END;
    RAISE NOTICE '  Orphaned (no session_id): % (%.1f%%)',
        orphaned_logs,
        CASE WHEN total_logs > 0 THEN (orphaned_logs::float / total_logs::float * 100) ELSE 0 END;

    -- Warn if orphaned logs exceed 5%
    IF total_logs > 0 AND (orphaned_logs::float / total_logs::float) > 0.05 THEN
        RAISE WARNING 'More than 5%% of exercise logs could not be linked to sessions';
    END IF;
END $$;

-- Step 3: Create index on session_id for performance
CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_id ON exercise_logs(session_id);

-- Step 4: Add comment
COMMENT ON COLUMN exercise_logs.session_id IS 'Foreign key to sessions table - links exercise log to workout session (BUILD 128)';
