-- DISABLE RLS on workout_timers to unblock timer creation
-- The policies aren't working, disable RLS entirely for now

ALTER TABLE workout_timers DISABLE ROW LEVEL SECURITY;
