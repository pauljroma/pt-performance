-- ============================================================================
-- VALIDATION QUERIES - INTERVAL TIMERS
-- ============================================================================
-- Date: 2026-01-03
-- Migration: 20260103000002_create_interval_timers.sql
-- ============================================================================

-- Check enum types exist
SELECT 'timer_type enum values:' as check_name, enumlabel as value
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'timer_type'
ORDER BY e.enumsortorder;

SELECT 'timer_category enum values:' as check_name, enumlabel as value
FROM pg_enum e
JOIN pg_type t ON e.enumtypid = t.oid
WHERE t.typname = 'timer_category'
ORDER BY e.enumsortorder;

-- Check tables exist
SELECT
    'Tables created:' as check_name,
    table_name,
    (SELECT COUNT(*) FROM information_schema.columns c WHERE c.table_name = t.table_name) as column_count
FROM information_schema.tables t
WHERE table_schema = 'public'
AND table_name IN ('interval_templates', 'workout_timers', 'timer_presets')
ORDER BY table_name;

-- Validation Query 1: Check Tabata templates
SELECT
    'Tabata Templates:' as query_name,
    id,
    name,
    type,
    work_seconds,
    rest_seconds,
    rounds,
    cycles,
    is_public
FROM interval_templates
WHERE type = 'tabata'
ORDER BY created_at;

-- Validation Query 2: Check cardio presets
SELECT
    'Cardio Presets:' as query_name,
    id,
    name,
    description,
    category,
    template_json
FROM timer_presets
WHERE category = 'cardio'
ORDER BY created_at;

-- Check all preset categories
SELECT
    'Preset Category Summary:' as check_name,
    category,
    COUNT(*) as preset_count
FROM timer_presets
GROUP BY category
ORDER BY category;

-- Check RLS policies
SELECT
    'RLS Policies:' as check_name,
    schemaname,
    tablename,
    policyname,
    cmd,
    roles
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('interval_templates', 'workout_timers', 'timer_presets')
ORDER BY tablename, policyname;

-- Count total policies
SELECT
    'Total RLS Policies:' as check_name,
    tablename,
    COUNT(*) as policy_count
FROM pg_policies
WHERE schemaname = 'public'
AND tablename IN ('interval_templates', 'workout_timers', 'timer_presets')
GROUP BY tablename
ORDER BY tablename;

-- Check functions exist
SELECT
    'Functions created:' as check_name,
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines
WHERE routine_schema = 'public'
AND routine_name IN ('create_tabata_preset', 'log_timer_session')
ORDER BY routine_name;

-- Check indexes
SELECT
    'Indexes created:' as check_name,
    tablename,
    indexname,
    indexdef
FROM pg_indexes
WHERE schemaname = 'public'
AND tablename IN ('interval_templates', 'workout_timers', 'timer_presets')
ORDER BY tablename, indexname;

-- Test create_tabata_preset function (will create a template)
-- Uncomment to test:
-- SELECT 'Test create_tabata_preset:' as test_name, create_tabata_preset(20, 10, 8) as template_id;

-- Test log_timer_session function (requires patient and template)
-- Uncomment to test with real IDs:
-- SELECT 'Test log_timer_session:' as test_name;
-- SELECT log_timer_session(
--     (SELECT id FROM patients LIMIT 1),
--     (SELECT id FROM interval_templates LIMIT 1),
--     240
-- );

-- Summary verification
SELECT
    'Migration Summary:' as summary,
    (SELECT COUNT(*) FROM interval_templates) as template_count,
    (SELECT COUNT(*) FROM timer_presets) as preset_count,
    (SELECT COUNT(*) FROM workout_timers) as workout_timer_count,
    (SELECT COUNT(*) FROM pg_policies WHERE tablename IN ('interval_templates', 'workout_timers', 'timer_presets')) as policy_count;

-- Expected results:
-- - timer_type enum: 5 values (tabata, emom, amrap, intervals, custom)
-- - timer_category enum: 5 values (cardio, strength, warmup, cooldown, recovery)
-- - 3 tables created
-- - 8+ RLS policies (4 for interval_templates, 4 for workout_timers, 1 for timer_presets)
-- - 2 functions created
-- - 10 timer presets seeded
