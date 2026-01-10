-- BUILD 124: Add started_at column to sessions table
-- Enables accurate workout duration tracking from actual start/end times

-- Add started_at column to sessions table
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS started_at TIMESTAMPTZ;

-- Add helpful comment
COMMENT ON COLUMN sessions.started_at IS 'Actual workout session start time (when user clicked Start Workout button)';

-- Create index for queries filtering by start time
CREATE INDEX IF NOT EXISTS idx_sessions_started_at ON sessions(started_at);

-- Update existing completed sessions to estimate start time from completion time
-- (Subtract duration_minutes from completed_at if both exist)
UPDATE sessions
SET started_at = completed_at - (duration_minutes || ' minutes')::INTERVAL
WHERE
    completed = true
    AND completed_at IS NOT NULL
    AND duration_minutes IS NOT NULL
    AND started_at IS NULL;
