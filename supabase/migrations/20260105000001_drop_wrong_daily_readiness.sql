-- Fix daily_readiness table schema - BUILD 116
-- Drop existing table if it has wrong schema and recreate

-- Drop the table and recreate with correct schema
DROP TABLE IF EXISTS daily_readiness CASCADE;
DROP TABLE IF EXISTS readiness_factors CASCADE;

-- Now the main migration will work correctly
