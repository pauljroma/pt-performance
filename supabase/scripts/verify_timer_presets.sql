-- ============================================================================
-- VERIFY TIMER PRESETS - BUILD 116 AGENT 4
-- ============================================================================
-- Comprehensive verification of timer presets seed data
--
-- Date: 2026-01-03
-- Linear: BUILD 116
-- Agent: 4
-- ============================================================================

\echo ''
\echo '============================================================================'
\echo 'TIMER PRESETS VERIFICATION REPORT'
\echo '============================================================================'
\echo ''

-- ============================================================================
-- 1. PRESET COUNT BY CATEGORY
-- ============================================================================

\echo '1. Preset count by category:'
\echo '----------------------------'

SELECT
    category,
    COUNT(*) as preset_count,
    CASE
        WHEN COUNT(*) >= 3 THEN '✅ PASS'
        ELSE '❌ FAIL (need 3+ per category)'
    END as status
FROM timer_presets
GROUP BY category
ORDER BY category;

\echo ''

-- ============================================================================
-- 2. TOTAL PRESET COUNT
-- ============================================================================

\echo '2. Total preset count:'
\echo '----------------------'

SELECT
    COUNT(*) as total_presets,
    CASE
        WHEN COUNT(*) >= 20 THEN '✅ PASS (20+ presets required)'
        ELSE '❌ FAIL (need 20+ presets)'
    END as status
FROM timer_presets;

\echo ''

-- ============================================================================
-- 3. TEMPLATE JSON VALIDATION
-- ============================================================================

\echo '3. Template JSON validation:'
\echo '----------------------------'

SELECT
    COUNT(*) as total_presets,
    COUNT(*) FILTER (WHERE template_json ? 'type') as has_type,
    COUNT(*) FILTER (WHERE template_json ? 'work_seconds') as has_work_seconds,
    COUNT(*) FILTER (WHERE template_json ? 'rest_seconds') as has_rest_seconds,
    COUNT(*) FILTER (WHERE template_json ? 'rounds') as has_rounds,
    COUNT(*) FILTER (WHERE template_json ? 'cycles') as has_cycles,
    COUNT(*) FILTER (WHERE template_json ? 'total_duration') as has_total_duration,
    COUNT(*) FILTER (WHERE template_json ? 'difficulty') as has_difficulty,
    COUNT(*) FILTER (WHERE template_json ? 'equipment') as has_equipment,
    CASE
        WHEN COUNT(*) = COUNT(*) FILTER (
            WHERE template_json ? 'type'
            AND template_json ? 'work_seconds'
            AND template_json ? 'rest_seconds'
            AND template_json ? 'rounds'
        ) THEN '✅ PASS (all have required fields)'
        ELSE '❌ FAIL (missing required fields)'
    END as validation_status
FROM timer_presets;

\echo ''

-- ============================================================================
-- 4. PRESET DETAILS BY CATEGORY
-- ============================================================================

\echo '4. Cardio presets:'
\echo '------------------'

SELECT
    name,
    description,
    template_json->>'difficulty' as difficulty,
    template_json->>'total_duration' as duration_seconds
FROM timer_presets
WHERE category = 'cardio'
ORDER BY name;

\echo ''
\echo '5. Strength presets:'
\echo '--------------------'

SELECT
    name,
    description,
    template_json->>'difficulty' as difficulty,
    template_json->>'total_duration' as duration_seconds
FROM timer_presets
WHERE category = 'strength'
ORDER BY name;

\echo ''
\echo '6. Warmup presets:'
\echo '------------------'

SELECT
    name,
    description,
    template_json->>'difficulty' as difficulty,
    template_json->>'total_duration' as duration_seconds
FROM timer_presets
WHERE category = 'warmup'
ORDER BY name;

\echo ''
\echo '7. Cooldown presets:'
\echo '--------------------'

SELECT
    name,
    description,
    template_json->>'difficulty' as difficulty,
    template_json->>'total_duration' as duration_seconds
FROM timer_presets
WHERE category = 'cooldown'
ORDER BY name;

\echo ''
\echo '8. Recovery presets:'
\echo '--------------------'

SELECT
    name,
    description,
    template_json->>'difficulty' as difficulty,
    template_json->>'total_duration' as duration_seconds
FROM timer_presets
WHERE category = 'recovery'
ORDER BY name;

\echo ''

-- ============================================================================
-- 9. DIFFICULTY DISTRIBUTION
-- ============================================================================

\echo '9. Difficulty distribution:'
\echo '---------------------------'

SELECT
    template_json->>'difficulty' as difficulty,
    COUNT(*) as preset_count
FROM timer_presets
WHERE template_json ? 'difficulty'
GROUP BY template_json->>'difficulty'
ORDER BY
    CASE template_json->>'difficulty'
        WHEN 'very_easy' THEN 1
        WHEN 'easy' THEN 2
        WHEN 'moderate' THEN 3
        WHEN 'hard' THEN 4
        WHEN 'very_hard' THEN 5
        ELSE 6
    END;

\echo ''

-- ============================================================================
-- 10. EQUIPMENT REQUIREMENTS
-- ============================================================================

\echo '10. Equipment requirements:'
\echo '---------------------------'

SELECT
    template_json->>'equipment' as equipment,
    COUNT(*) as preset_count
FROM timer_presets
WHERE template_json ? 'equipment'
GROUP BY template_json->>'equipment'
ORDER BY COUNT(*) DESC;

\echo ''

-- ============================================================================
-- 11. TIMER TYPE DISTRIBUTION
-- ============================================================================

\echo '11. Timer type distribution:'
\echo '----------------------------'

SELECT
    template_json->>'type' as timer_type,
    COUNT(*) as preset_count
FROM timer_presets
GROUP BY template_json->>'type'
ORDER BY COUNT(*) DESC;

\echo ''

-- ============================================================================
-- 12. DURATION ANALYSIS
-- ============================================================================

\echo '12. Duration analysis:'
\echo '----------------------'

SELECT
    category,
    ROUND(AVG((template_json->>'total_duration')::numeric), 0) as avg_duration_seconds,
    MIN((template_json->>'total_duration')::numeric) as min_duration,
    MAX((template_json->>'total_duration')::numeric) as max_duration
FROM timer_presets
WHERE template_json ? 'total_duration'
GROUP BY category
ORDER BY category;

\echo ''

-- ============================================================================
-- 13. SAMPLE PRESET RETRIEVAL TEST
-- ============================================================================

\echo '13. Sample preset retrieval (cardio Tabata):'
\echo '---------------------------------------------'

SELECT
    name,
    description,
    template_json
FROM timer_presets
WHERE category = 'cardio'
AND template_json->>'type' = 'tabata'
LIMIT 1;

\echo ''

-- ============================================================================
-- 14. FINAL VALIDATION SUMMARY
-- ============================================================================

\echo '14. Final validation summary:'
\echo '-----------------------------'

SELECT
    'Total presets' as metric,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) >= 20 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM timer_presets

UNION ALL

SELECT
    'Categories with 3+ presets' as metric,
    COUNT(*)::text as value,
    CASE WHEN COUNT(*) = 5 THEN '✅ PASS' ELSE '❌ FAIL' END as status
FROM (
    SELECT category, COUNT(*) as cnt
    FROM timer_presets
    GROUP BY category
    HAVING COUNT(*) >= 3
) category_counts

UNION ALL

SELECT
    'Valid JSON templates' as metric,
    COUNT(*)::text as value,
    CASE
        WHEN COUNT(*) = (SELECT COUNT(*) FROM timer_presets)
        THEN '✅ PASS'
        ELSE '❌ FAIL'
    END as status
FROM timer_presets
WHERE template_json ? 'type'
AND template_json ? 'work_seconds'
AND template_json ? 'rest_seconds'
AND template_json ? 'rounds'

UNION ALL

SELECT
    'Presets with difficulty' as metric,
    COUNT(*)::text as value,
    CASE
        WHEN COUNT(*) >= 20
        THEN '✅ PASS'
        ELSE '⚠️  WARNING'
    END as status
FROM timer_presets
WHERE template_json ? 'difficulty'

UNION ALL

SELECT
    'Presets with equipment' as metric,
    COUNT(*)::text as value,
    CASE
        WHEN COUNT(*) >= 20
        THEN '✅ PASS'
        ELSE '⚠️  WARNING'
    END as status
FROM timer_presets
WHERE template_json ? 'equipment';

\echo ''
\echo '============================================================================'
\echo 'VERIFICATION COMPLETE'
\echo '============================================================================'
\echo ''
