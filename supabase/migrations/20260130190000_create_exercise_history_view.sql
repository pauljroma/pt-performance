-- BUILD 333: Create exercise history view for quick lookup
-- Aggregates exercise performance data by exercise name per patient

-- Drop existing view if it exists
DROP VIEW IF EXISTS vw_exercise_history;

-- Create comprehensive exercise history view
CREATE OR REPLACE VIEW vw_exercise_history AS
SELECT
    ms.patient_id::text as patient_id,
    mse.exercise_name,
    mse.exercise_template_id::text as exercise_template_id,

    -- Aggregations
    COUNT(DISTINCT ms.id) as session_count,
    MAX(ms.completed_at) as last_performed,
    MIN(ms.completed_at) as first_performed,

    -- Weight stats (when available)
    AVG(mse.target_load) FILTER (WHERE mse.target_load IS NOT NULL) as avg_weight,
    MAX(mse.target_load) FILTER (WHERE mse.target_load IS NOT NULL) as max_weight,
    MIN(mse.target_load) FILTER (WHERE mse.target_load IS NOT NULL) as min_weight,

    -- Volume calculation (sets * reps * weight approximation)
    SUM(
        COALESCE(mse.target_sets, 3) *
        COALESCE(
            -- Try to parse reps as number, default to 10
            CASE
                WHEN mse.target_reps ~ '^[0-9]+$' THEN mse.target_reps::integer
                WHEN mse.target_reps ~ '^[0-9]+-[0-9]+$' THEN
                    -- For ranges like "8-12", take average
                    (split_part(mse.target_reps, '-', 1)::integer +
                     split_part(mse.target_reps, '-', 2)::integer) / 2
                ELSE 10
            END,
            10
        ) *
        COALESCE(mse.target_load, 0)
    ) as total_volume,

    -- Trend calculation (compare recent vs older sessions)
    CASE
        WHEN COUNT(*) FILTER (WHERE ms.completed_at > NOW() - INTERVAL '30 days') > 0
             AND COUNT(*) FILTER (WHERE ms.completed_at <= NOW() - INTERVAL '30 days') > 0
        THEN
            (AVG(mse.target_load) FILTER (WHERE ms.completed_at > NOW() - INTERVAL '30 days' AND mse.target_load IS NOT NULL) -
             AVG(mse.target_load) FILTER (WHERE ms.completed_at <= NOW() - INTERVAL '30 days' AND mse.target_load IS NOT NULL)) /
            NULLIF(AVG(mse.target_load) FILTER (WHERE ms.completed_at <= NOW() - INTERVAL '30 days' AND mse.target_load IS NOT NULL), 0)
        ELSE 0
    END as improvement_ratio,

    -- Most common load unit
    MODE() WITHIN GROUP (ORDER BY mse.load_unit) as load_unit

FROM manual_session_exercises mse
JOIN manual_sessions ms ON mse.manual_session_id = ms.id
WHERE ms.completed_at IS NOT NULL
GROUP BY ms.patient_id, mse.exercise_name, mse.exercise_template_id;

-- Create index for fast lookups
CREATE INDEX IF NOT EXISTS idx_manual_session_exercises_name
ON manual_session_exercises(exercise_name);

CREATE INDEX IF NOT EXISTS idx_manual_sessions_patient_completed
ON manual_sessions(patient_id, completed_at)
WHERE completed_at IS NOT NULL;

-- Grant access
GRANT SELECT ON vw_exercise_history TO authenticated;
GRANT SELECT ON vw_exercise_history TO anon;

-- Create function to get detailed exercise history with recent sessions
CREATE OR REPLACE FUNCTION get_exercise_history_detail(
    p_patient_id UUID,
    p_exercise_name TEXT,
    p_limit INTEGER DEFAULT 10
)
RETURNS TABLE (
    session_date TIMESTAMPTZ,
    sets INTEGER,
    reps TEXT,
    weight NUMERIC,
    load_unit TEXT,
    notes TEXT,
    is_personal_record BOOLEAN
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ms.completed_at as session_date,
        mse.target_sets as sets,
        mse.target_reps as reps,
        mse.target_load as weight,
        mse.load_unit,
        mse.notes,
        -- Mark as PR if it's the highest weight for this exercise
        mse.target_load = (
            SELECT MAX(mse2.target_load)
            FROM manual_session_exercises mse2
            JOIN manual_sessions ms2 ON mse2.manual_session_id = ms2.id
            WHERE ms2.patient_id = p_patient_id
              AND mse2.exercise_name = p_exercise_name
              AND ms2.completed_at IS NOT NULL
        ) AND mse.target_load IS NOT NULL as is_personal_record
    FROM manual_session_exercises mse
    JOIN manual_sessions ms ON mse.manual_session_id = ms.id
    WHERE ms.patient_id = p_patient_id
      AND mse.exercise_name = p_exercise_name
      AND ms.completed_at IS NOT NULL
    ORDER BY ms.completed_at DESC
    LIMIT p_limit;
END;
$$;

-- Grant execute
GRANT EXECUTE ON FUNCTION get_exercise_history_detail TO authenticated;

-- Verify
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_views WHERE viewname = 'vw_exercise_history') THEN
        RAISE NOTICE 'Successfully created vw_exercise_history view';
    ELSE
        RAISE WARNING 'vw_exercise_history view creation may have failed';
    END IF;
END $$;
