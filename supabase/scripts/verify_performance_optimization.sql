-- Verify performance optimization was applied

-- 1. Check indexes exist
SELECT
    schemaname,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE tablename = 'session_exercises'
AND indexname LIKE 'idx_session_exercises%'
ORDER BY indexname;

-- 2. Check view exists
SELECT
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE viewname = 'vw_session_exercises_with_templates';

-- 3. Test view performance with sample query
EXPLAIN ANALYZE
SELECT * FROM vw_session_exercises_with_templates
WHERE session_id IN (
    SELECT id FROM sessions LIMIT 24
)
ORDER BY session_id, order_index;

-- 4. Count total exercises in view
SELECT COUNT(*) as total_exercises FROM vw_session_exercises_with_templates;
