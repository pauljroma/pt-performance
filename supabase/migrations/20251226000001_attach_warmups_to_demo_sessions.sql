-- Migration: Attach interval block warmups to demo sessions
-- Date: 2025-12-26
-- Issue: ACP-505 - Timer not discoverable
-- Description: Attaches Classic Tabata warmup to all demo program sessions

-- Attach Classic Tabata warmup to all sessions in demo program (8-Week On-Ramp)
-- This makes the interval timer feature discoverable for demo patients
INSERT INTO session_interval_blocks (
    session_id,
    template_id,
    name,
    description,
    block_type,
    sort_order,
    work_duration,
    rest_duration,
    rounds,
    exercises,
    completed
)
SELECT
    s.id as session_id,
    t.id as template_id,
    t.name,
    t.description,
    t.block_type,
    0 as sort_order,  -- Warmup goes before exercises (sort_order 0)
    t.work_duration,
    t.rest_duration,
    t.rounds,
    t.exercises,
    false as completed
FROM sessions s
CROSS JOIN interval_block_templates t
WHERE s.phase_id IN (
    SELECT id FROM phases
    WHERE program_id = '00000000-0000-0000-0000-000000000200'::uuid  -- Demo program: 8-Week On-Ramp
)
AND t.name = 'Classic Tabata'  -- Attach Classic Tabata to all demo sessions
ON CONFLICT DO NOTHING;

-- Verification query (should show count of attached warmups)
DO $$
DECLARE
    warmup_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO warmup_count
    FROM session_interval_blocks
    WHERE template_id IN (SELECT id FROM interval_block_templates WHERE name = 'Classic Tabata');

    RAISE NOTICE '✅ Attached % Classic Tabata warmups to demo sessions', warmup_count;
END $$;
