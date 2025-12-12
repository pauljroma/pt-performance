-- Force PostgREST to reload schema cache
-- Run this in Supabase SQL Editor

-- Method 1: NOTIFY command (preferred)
NOTIFY pgrst, 'reload schema';

-- Method 2: Verify table exists
SELECT
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name = 'exercise_logs'
ORDER BY ordinal_position;

-- Method 3: Check if RLS is enabled
SELECT
    schemaname,
    tablename,
    rowsecurity
FROM pg_tables
WHERE tablename = 'exercise_logs';
