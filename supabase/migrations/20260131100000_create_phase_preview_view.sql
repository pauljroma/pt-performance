-- Create view for phase preview with workout counts
-- Used by ProgramDetailSheet to show phases before enrollment

CREATE OR REPLACE VIEW vw_phase_preview AS
SELECT
    p.id,
    p.program_id,
    p.name as phase_name,
    p.sequence as phase_number,
    -- Calculate week_start based on sequence and duration_weeks
    COALESCE(
        (SELECT SUM(p2.duration_weeks) + 1
         FROM phases p2
         WHERE p2.program_id = p.program_id AND p2.sequence < p.sequence),
        1
    )::integer as week_start,
    -- Calculate week_end
    COALESCE(
        (SELECT SUM(p2.duration_weeks)
         FROM phases p2
         WHERE p2.program_id = p.program_id AND p2.sequence <= p.sequence),
        p.duration_weeks
    )::integer as week_end,
    p.notes as description,
    COALESCE(COUNT(pwa.id), 0)::integer as workout_count
FROM phases p
LEFT JOIN program_workout_assignments pwa ON pwa.phase_id = p.id
GROUP BY p.id, p.program_id, p.name, p.sequence, p.duration_weeks, p.notes
ORDER BY p.sequence;

-- Grant access to the view
GRANT SELECT ON vw_phase_preview TO authenticated;
GRANT SELECT ON vw_phase_preview TO anon;

-- Notify
DO $$
BEGIN
    RAISE NOTICE 'Created vw_phase_preview view for program phase display';
END $$;
