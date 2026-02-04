-- Session Source Tracking Migration
-- ACP-XXX: Synchronize session metadata for prescribed vs chosen workouts
--
-- This migration adds tracking for workout source:
-- - program: Part of structured program
-- - prescribed: Trainer assigned specific workout
-- - chosen: Athlete self-selected from library
-- - quick_pick: Used Quick Pick feature

-- Add session_source enum type
DO $$ BEGIN
    CREATE TYPE session_source_type AS ENUM ('program', 'prescribed', 'chosen', 'quick_pick');
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;

-- Add columns to manual_sessions
ALTER TABLE manual_sessions
ADD COLUMN IF NOT EXISTS assigned_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS session_source session_source_type DEFAULT 'chosen';

-- Add index for filtering by source
CREATE INDEX IF NOT EXISTS idx_manual_sessions_source ON manual_sessions(session_source);

-- Add partial index for assigned sessions (only index non-null values)
CREATE INDEX IF NOT EXISTS idx_manual_sessions_assigned_by ON manual_sessions(assigned_by_user_id)
WHERE assigned_by_user_id IS NOT NULL;

-- Backfill existing records to 'chosen' (default for self-selected)
UPDATE manual_sessions SET session_source = 'chosen' WHERE session_source IS NULL;

-- Add comment for documentation
COMMENT ON COLUMN manual_sessions.session_source IS 'Identifies how the workout was initiated: program (from structured program), prescribed (trainer assigned), chosen (self-selected from library), quick_pick (via Quick Pick feature)';
COMMENT ON COLUMN manual_sessions.assigned_by_user_id IS 'Auth user ID of trainer/therapist who assigned this workout (NULL for self-selected)';
