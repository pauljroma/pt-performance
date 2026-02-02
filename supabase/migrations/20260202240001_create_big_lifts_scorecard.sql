-- Migration: Create Big Lifts Scorecard Infrastructure
-- Created: 2026-02-02
-- Purpose: Provide RPC function and view for tracking big compound lifts (Bench Press, Squat, Deadlift)
--
-- This migration creates:
--   1. get_big_lifts_summary() - RPC function returning scorecard data for big lifts
--   2. vw_big_lifts_history - View for time-series data of big lifts only
--
-- Big lifts defined as:
--   - Bench Press (including variations)
--   - Barbell Squat (including Back Squat, Front Squat)
--   - Deadlift (including variations)
--   - Optionally: Overhead Press, Barbell Row

-- ============================================================================
-- 1. DROP EXISTING OBJECTS (for clean slate / idempotency)
-- ============================================================================

DROP FUNCTION IF EXISTS get_big_lifts_summary(UUID);
DROP VIEW IF EXISTS vw_big_lifts_history;

-- ============================================================================
-- 2. CREATE BIG LIFTS HISTORY VIEW
-- ============================================================================

-- View for time-series data of big lifts only
-- Useful for charting progression over time
CREATE OR REPLACE VIEW vw_big_lifts_history AS
SELECT
    ms.patient_id::text AS patient_id,
    mse.exercise_name,
    mse.exercise_template_id::text AS exercise_template_id,
    ms.completed_at::date AS workout_date,
    ms.id::text AS session_id,

    -- Weight and reps data
    COALESCE(mse.target_load, 0) AS weight,
    COALESCE(mse.target_sets, 3) AS sets,
    CASE
        WHEN mse.target_reps ~ '^[0-9]+$' THEN mse.target_reps::integer
        WHEN mse.target_reps ~ '^[0-9]+-[0-9]+$' THEN
            (split_part(mse.target_reps, '-', 1)::integer +
             split_part(mse.target_reps, '-', 2)::integer) / 2
        ELSE 10
    END AS reps,

    -- Calculate estimated 1RM using Epley formula: weight * (1 + reps/30)
    CASE
        WHEN mse.target_load IS NOT NULL AND mse.target_load > 0 THEN
            ROUND(
                mse.target_load * (1 +
                    CASE
                        WHEN mse.target_reps ~ '^[0-9]+$' THEN mse.target_reps::numeric
                        WHEN mse.target_reps ~ '^[0-9]+-[0-9]+$' THEN
                            (split_part(mse.target_reps, '-', 1)::numeric +
                             split_part(mse.target_reps, '-', 2)::numeric) / 2
                        ELSE 10
                    END / 30.0
                ),
                2
            )
        ELSE NULL
    END AS estimated_1rm,

    -- Volume calculation (sets * reps * weight)
    COALESCE(mse.target_sets, 3) *
    CASE
        WHEN mse.target_reps ~ '^[0-9]+$' THEN mse.target_reps::integer
        WHEN mse.target_reps ~ '^[0-9]+-[0-9]+$' THEN
            (split_part(mse.target_reps, '-', 1)::integer +
             split_part(mse.target_reps, '-', 2)::integer) / 2
        ELSE 10
    END * COALESCE(mse.target_load, 0) AS volume,

    -- Load unit
    COALESCE(mse.load_unit, 'lbs') AS load_unit,

    -- Notes
    mse.notes,

    -- Big lift category
    CASE
        WHEN LOWER(mse.exercise_name) LIKE '%bench press%' THEN 'Bench Press'
        WHEN LOWER(mse.exercise_name) LIKE '%squat%' AND LOWER(mse.exercise_name) NOT LIKE '%split%' THEN 'Squat'
        WHEN LOWER(mse.exercise_name) LIKE '%deadlift%' THEN 'Deadlift'
        WHEN LOWER(mse.exercise_name) LIKE '%overhead press%' OR LOWER(mse.exercise_name) LIKE '%ohp%' OR LOWER(mse.exercise_name) LIKE '%military press%' THEN 'Overhead Press'
        WHEN LOWER(mse.exercise_name) LIKE '%barbell row%' OR LOWER(mse.exercise_name) LIKE '%bent over row%' THEN 'Barbell Row'
        ELSE 'Other'
    END AS lift_category

FROM manual_session_exercises mse
JOIN manual_sessions ms ON mse.manual_session_id = ms.id
WHERE ms.completed_at IS NOT NULL
  AND (
      -- Filter to big lifts only
      LOWER(mse.exercise_name) LIKE '%bench press%'
      OR (LOWER(mse.exercise_name) LIKE '%squat%' AND LOWER(mse.exercise_name) NOT LIKE '%split%')
      OR LOWER(mse.exercise_name) LIKE '%deadlift%'
      OR LOWER(mse.exercise_name) LIKE '%overhead press%'
      OR LOWER(mse.exercise_name) LIKE '%ohp%'
      OR LOWER(mse.exercise_name) LIKE '%military press%'
      OR LOWER(mse.exercise_name) LIKE '%barbell row%'
      OR LOWER(mse.exercise_name) LIKE '%bent over row%'
  )
ORDER BY ms.patient_id, mse.exercise_name, ms.completed_at DESC;

COMMENT ON VIEW vw_big_lifts_history IS
'Time-series view of big compound lifts (Bench Press, Squat, Deadlift, Overhead Press, Barbell Row).
Includes estimated 1RM using Epley formula and volume calculations.
Use this view for charting progression over time.';

-- ============================================================================
-- 3. CREATE BIG LIFTS SUMMARY RPC FUNCTION
-- ============================================================================

-- Function to get big lifts scorecard data for a patient
CREATE OR REPLACE FUNCTION get_big_lifts_summary(p_patient_id UUID)
RETURNS TABLE (
    exercise_name TEXT,
    current_max_weight NUMERIC,
    estimated_1rm NUMERIC,
    last_pr_date DATE,
    pr_count INTEGER,
    last_performed DATE,
    improvement_pct_30d NUMERIC,
    total_volume NUMERIC,
    load_unit TEXT
)
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    WITH big_lift_exercises AS (
        -- Get all big lift exercise records for the patient
        SELECT
            mse.exercise_name,
            mse.target_load,
            mse.target_sets,
            mse.target_reps,
            mse.load_unit,
            ms.completed_at,
            -- Calculate estimated 1RM using Epley formula
            CASE
                WHEN mse.target_load IS NOT NULL AND mse.target_load > 0 THEN
                    ROUND(
                        mse.target_load * (1 +
                            CASE
                                WHEN mse.target_reps ~ '^[0-9]+$' THEN mse.target_reps::numeric
                                WHEN mse.target_reps ~ '^[0-9]+-[0-9]+$' THEN
                                    (split_part(mse.target_reps, '-', 1)::numeric +
                                     split_part(mse.target_reps, '-', 2)::numeric) / 2
                                ELSE 10
                            END / 30.0
                        ),
                        2
                    )
                ELSE NULL
            END AS calc_estimated_1rm,
            -- Parse reps for volume calculation
            CASE
                WHEN mse.target_reps ~ '^[0-9]+$' THEN mse.target_reps::integer
                WHEN mse.target_reps ~ '^[0-9]+-[0-9]+$' THEN
                    (split_part(mse.target_reps, '-', 1)::integer +
                     split_part(mse.target_reps, '-', 2)::integer) / 2
                ELSE 10
            END AS parsed_reps
        FROM manual_session_exercises mse
        JOIN manual_sessions ms ON mse.manual_session_id = ms.id
        WHERE ms.patient_id = p_patient_id
          AND ms.completed_at IS NOT NULL
          AND (
              -- Filter to big lifts only
              LOWER(mse.exercise_name) LIKE '%bench press%'
              OR (LOWER(mse.exercise_name) LIKE '%squat%' AND LOWER(mse.exercise_name) NOT LIKE '%split%')
              OR LOWER(mse.exercise_name) LIKE '%deadlift%'
              OR LOWER(mse.exercise_name) LIKE '%overhead press%'
              OR LOWER(mse.exercise_name) LIKE '%ohp%'
              OR LOWER(mse.exercise_name) LIKE '%military press%'
              OR LOWER(mse.exercise_name) LIKE '%barbell row%'
              OR LOWER(mse.exercise_name) LIKE '%bent over row%'
          )
    ),
    exercise_summary AS (
        -- Aggregate by exercise name
        SELECT
            ble.exercise_name,
            MAX(ble.target_load) AS max_weight,
            MAX(ble.calc_estimated_1rm) AS max_estimated_1rm,
            MAX(ble.completed_at)::date AS last_performed_date,
            MODE() WITHIN GROUP (ORDER BY ble.load_unit) AS common_load_unit,
            SUM(COALESCE(ble.target_sets, 3) * ble.parsed_reps * COALESCE(ble.target_load, 0)) AS total_vol
        FROM big_lift_exercises ble
        GROUP BY ble.exercise_name
    ),
    pr_data AS (
        -- Calculate PR dates and counts
        -- A PR is when the weight equals the max weight for that exercise
        SELECT
            ble.exercise_name,
            MIN(ble.completed_at)::date AS first_pr_date,
            COUNT(*) FILTER (
                WHERE ble.target_load = (
                    SELECT MAX(ble2.target_load)
                    FROM big_lift_exercises ble2
                    WHERE ble2.exercise_name = ble.exercise_name
                )
            )::integer AS pr_hits
        FROM big_lift_exercises ble
        WHERE ble.target_load IS NOT NULL
        GROUP BY ble.exercise_name
    ),
    improvement_calc AS (
        -- Calculate 30-day improvement percentage
        SELECT
            ble.exercise_name,
            CASE
                WHEN COUNT(*) FILTER (WHERE ble.completed_at > NOW() - INTERVAL '30 days') > 0
                     AND COUNT(*) FILTER (WHERE ble.completed_at <= NOW() - INTERVAL '30 days') > 0
                THEN
                    ROUND(
                        (
                            (AVG(ble.target_load) FILTER (WHERE ble.completed_at > NOW() - INTERVAL '30 days' AND ble.target_load IS NOT NULL) -
                             AVG(ble.target_load) FILTER (WHERE ble.completed_at <= NOW() - INTERVAL '30 days' AND ble.target_load IS NOT NULL)) /
                            NULLIF(AVG(ble.target_load) FILTER (WHERE ble.completed_at <= NOW() - INTERVAL '30 days' AND ble.target_load IS NOT NULL), 0)
                        ) * 100,
                        2
                    )
                ELSE 0
            END AS improvement_pct
        FROM big_lift_exercises ble
        GROUP BY ble.exercise_name
    ),
    last_pr_calc AS (
        -- Find the most recent date where they hit their current max weight
        SELECT DISTINCT ON (ble.exercise_name)
            ble.exercise_name,
            ble.completed_at::date AS last_pr_hit_date
        FROM big_lift_exercises ble
        WHERE ble.target_load = (
            SELECT MAX(ble2.target_load)
            FROM big_lift_exercises ble2
            WHERE ble2.exercise_name = ble.exercise_name
        )
        AND ble.target_load IS NOT NULL
        ORDER BY ble.exercise_name, ble.completed_at DESC
    )
    SELECT
        es.exercise_name,
        COALESCE(es.max_weight, 0) AS current_max_weight,
        COALESCE(es.max_estimated_1rm, 0) AS estimated_1rm,
        lpr.last_pr_hit_date AS last_pr_date,
        COALESCE(pr.pr_hits, 0) AS pr_count,
        es.last_performed_date AS last_performed,
        COALESCE(ic.improvement_pct, 0) AS improvement_pct_30d,
        COALESCE(es.total_vol, 0) AS total_volume,
        COALESCE(es.common_load_unit, 'lbs') AS load_unit
    FROM exercise_summary es
    LEFT JOIN pr_data pr ON pr.exercise_name = es.exercise_name
    LEFT JOIN improvement_calc ic ON ic.exercise_name = es.exercise_name
    LEFT JOIN last_pr_calc lpr ON lpr.exercise_name = es.exercise_name
    ORDER BY es.exercise_name;
END;
$$;

COMMENT ON FUNCTION get_big_lifts_summary(UUID) IS
'Returns scorecard data for big compound lifts (Bench Press, Squat, Deadlift, OHP, Barbell Row).
Includes current max weight, estimated 1RM (Epley formula), PR tracking, and 30-day improvement.
SECURITY DEFINER to allow proper RLS bypass for aggregation queries.';

-- ============================================================================
-- 4. CREATE INDEXES FOR PERFORMANCE
-- ============================================================================

-- Index for exercise name pattern matching (lower case)
CREATE INDEX IF NOT EXISTS idx_manual_session_exercises_name_lower
ON manual_session_exercises(LOWER(exercise_name));

-- Composite index for big lifts queries
CREATE INDEX IF NOT EXISTS idx_manual_sessions_patient_completed_date
ON manual_sessions(patient_id, completed_at DESC)
WHERE completed_at IS NOT NULL;

-- ============================================================================
-- 5. GRANT PERMISSIONS
-- ============================================================================

-- Grant access to the view
GRANT SELECT ON vw_big_lifts_history TO authenticated;
GRANT SELECT ON vw_big_lifts_history TO anon;

-- Grant execute on the function
GRANT EXECUTE ON FUNCTION get_big_lifts_summary(UUID) TO authenticated;

-- ============================================================================
-- 6. VERIFICATION
-- ============================================================================

DO $$
DECLARE
    v_view_exists BOOLEAN;
    v_function_exists BOOLEAN;
    v_function_security TEXT;
BEGIN
    -- Check if view exists
    SELECT EXISTS (
        SELECT 1 FROM pg_views
        WHERE schemaname = 'public' AND viewname = 'vw_big_lifts_history'
    ) INTO v_view_exists;

    IF NOT v_view_exists THEN
        RAISE EXCEPTION 'FAILED: vw_big_lifts_history view was not created';
    END IF;

    -- Check if function exists
    SELECT EXISTS (
        SELECT 1 FROM information_schema.routines
        WHERE routine_schema = 'public' AND routine_name = 'get_big_lifts_summary'
    ) INTO v_function_exists;

    IF NOT v_function_exists THEN
        RAISE EXCEPTION 'FAILED: get_big_lifts_summary function was not created';
    END IF;

    -- Check function security
    SELECT security_type FROM information_schema.routines
    WHERE routine_schema = 'public' AND routine_name = 'get_big_lifts_summary'
    INTO v_function_security;

    IF v_function_security != 'DEFINER' THEN
        RAISE EXCEPTION 'FAILED: get_big_lifts_summary function is not SECURITY DEFINER';
    END IF;

    RAISE NOTICE 'SUCCESS: Big Lifts Scorecard infrastructure created';
    RAISE NOTICE '  - vw_big_lifts_history view: %', v_view_exists;
    RAISE NOTICE '  - get_big_lifts_summary function: %', v_function_exists;
    RAISE NOTICE '  - Function security: %', v_function_security;
END $$;
