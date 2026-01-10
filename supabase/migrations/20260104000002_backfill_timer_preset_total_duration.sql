-- Backfill missing total_duration in timer_presets template_json
-- BUILD 136: Fix timer preset decoding errors

-- Update records where total_duration is missing
UPDATE timer_presets
SET template_json = template_json || jsonb_build_object(
    'total_duration',
    (
        (template_json->>'work_seconds')::int +
        (template_json->>'rest_seconds')::int
    ) *
    (template_json->>'rounds')::int *
    (template_json->>'cycles')::int
)
WHERE NOT (template_json ? 'total_duration');

-- Log completion
DO $$
DECLARE
    updated_count integer;
BEGIN
    SELECT COUNT(*) INTO updated_count
    FROM timer_presets
    WHERE template_json ? 'total_duration';

    RAISE NOTICE 'BUILD 136: Timer presets backfill complete';
    RAISE NOTICE '  ✅ %% presets now have total_duration', updated_count;
END $$;
