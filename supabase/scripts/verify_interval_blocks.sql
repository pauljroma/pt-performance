-- Verification Script for Interval Blocks Fetching
-- Run this after applying migration 20251226000001_attach_warmups_to_demo_sessions.sql
-- Issue: ACP-505 - Timer not discoverable

-- 1. Check that interval block templates exist (should be 6)
SELECT
    'Templates' as check_type,
    COUNT(*) as count,
    CASE
        WHEN COUNT(*) >= 6 THEN '✅ PASS'
        ELSE '❌ FAIL - Expected 6 templates'
    END as status
FROM interval_block_templates;

-- 2. List all available templates
SELECT
    name,
    block_type,
    work_duration || 's work, ' || rest_duration || 's rest' as timing,
    rounds || ' rounds' as rounds,
    created_at
FROM interval_block_templates
ORDER BY created_at;

-- 3. Check session interval blocks exist (should be >0 after migration)
SELECT
    'Session Blocks Attached' as check_type,
    COUNT(*) as count,
    CASE
        WHEN COUNT(*) > 0 THEN '✅ PASS'
        ELSE '❌ FAIL - No blocks attached to sessions'
    END as status
FROM session_interval_blocks;

-- 4. Verify demo program sessions have warmups attached
SELECT
    p.name as program_name,
    ph.name as phase_name,
    s.name as session_name,
    COUNT(sib.id) as warmup_count
FROM programs p
JOIN phases ph ON ph.program_id = p.id
JOIN sessions s ON s.phase_id = ph.id
LEFT JOIN session_interval_blocks sib ON sib.session_id = s.id
WHERE p.id = '00000000-0000-0000-0000-000000000200'::uuid  -- Demo program
GROUP BY p.name, ph.name, s.name, s.sequence
ORDER BY ph.sequence, s.sequence;

-- 5. Show sample session interval block (what the iOS app will fetch)
SELECT
    sib.id,
    sib.session_id,
    sib.name,
    sib.description,
    sib.block_type,
    sib.work_duration,
    sib.rest_duration,
    sib.rounds,
    sib.exercises,
    sib.completed,
    sib.sort_order
FROM session_interval_blocks sib
LIMIT 1;

-- 6. Simulate iOS fetch query for a specific session
-- Replace {SESSION_ID} with actual session ID from demo program
WITH demo_session AS (
    SELECT s.id
    FROM sessions s
    JOIN phases ph ON s.phase_id = ph.id
    WHERE ph.program_id = '00000000-0000-0000-0000-000000000200'::uuid
    LIMIT 1
)
SELECT
    'iOS Fetch Simulation' as check_type,
    COUNT(*) as blocks_returned,
    CASE
        WHEN COUNT(*) > 0 THEN '✅ PASS - iOS app will show warmup'
        ELSE '❌ FAIL - iOS app will not show warmup'
    END as status
FROM session_interval_blocks sib
WHERE sib.session_id IN (SELECT id FROM demo_session)
ORDER BY sib.sort_order;

-- 7. RLS Policy Check - Can patients see interval blocks?
-- This checks if the RLS policies allow patients to query their blocks
SELECT
    'RLS Policy' as check_type,
    COUNT(*) as policies_found,
    CASE
        WHEN COUNT(*) >= 1 THEN '✅ PASS - Patients can view blocks'
        ELSE '⚠️ WARNING - Check RLS policies'
    END as status
FROM pg_policies
WHERE tablename = 'session_interval_blocks'
AND policyname LIKE '%Patients%';

-- 8. Summary Report
SELECT
    '========================================' as divider
UNION ALL
SELECT 'INTERVAL BLOCKS VERIFICATION SUMMARY'
UNION ALL
SELECT '========================================'
UNION ALL
SELECT ''
UNION ALL
SELECT 'Templates Available: ' || (SELECT COUNT(*)::text FROM interval_block_templates)
UNION ALL
SELECT 'Session Blocks Attached: ' || (SELECT COUNT(*)::text FROM session_interval_blocks)
UNION ALL
SELECT 'Demo Sessions with Warmups: ' ||
    (SELECT COUNT(DISTINCT sib.session_id)::text
     FROM session_interval_blocks sib
     JOIN sessions s ON s.id = sib.session_id
     JOIN phases ph ON s.phase_id = ph.id
     WHERE ph.program_id = '00000000-0000-0000-0000-000000000200'::uuid)
UNION ALL
SELECT ''
UNION ALL
SELECT 'Status: ' ||
    CASE
        WHEN (SELECT COUNT(*) FROM session_interval_blocks) > 0
        THEN '✅ Ready for iOS testing'
        ELSE '❌ Run migration first'
    END;
