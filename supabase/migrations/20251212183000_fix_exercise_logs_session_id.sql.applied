-- Fix exercise_logs schema - handle session_id column
-- Error: null value in column "session_id" violates not-null constraint
-- Either add session_id or make it nullable, or derive from session_exercise_id

DO $$
BEGIN
    -- Check if session_id column exists
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'exercise_logs' AND column_name = 'session_id'
    ) THEN
        -- Column exists - make it nullable (it can be derived from session_exercise_id)
        ALTER TABLE exercise_logs ALTER COLUMN session_id DROP NOT NULL;
        RAISE NOTICE 'Made session_id column nullable';
    ELSE
        -- Column doesn't exist - add it as nullable
        ALTER TABLE exercise_logs ADD COLUMN session_id UUID REFERENCES sessions(id) ON DELETE CASCADE;
        RAISE NOTICE 'Added session_id column as nullable';
    END IF;

    -- Create index for performance
    CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_id ON exercise_logs(session_id);

    RAISE NOTICE 'exercise_logs session_id fix complete';
END $$;

COMMENT ON COLUMN exercise_logs.session_id IS 'Optional - can be derived from session_exercise_id → session_exercises → sessions';
