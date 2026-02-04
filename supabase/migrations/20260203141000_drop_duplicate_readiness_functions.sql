-- BUILD 404: Drop duplicate readiness functions (keep TEXT versions only)

-- Drop the old UUID/DATE parameter versions
DROP FUNCTION IF EXISTS get_daily_readiness(uuid, date);
DROP FUNCTION IF EXISTS upsert_daily_readiness(uuid, date, numeric, integer, integer, integer, text);
