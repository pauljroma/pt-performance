-- 20251213130000_fix_workload_flags_and_seed_winter_lift.sql
-- Fix missing workload_flags.resolved column and insert Winter Lift program
-- Zone-7 (Data Access), Zone-8 (Data Ingestion)

-- ============================================================================
-- 1. ADD MISSING RESOLVED COLUMN TO WORKLOAD_FLAGS
-- ============================================================================

ALTER TABLE public.workload_flags ADD COLUMN IF NOT EXISTS resolved boolean DEFAULT false;
COMMENT ON COLUMN public.workload_flags.resolved IS 'Whether the workload flag has been addressed/resolved';

-- ============================================================================
-- 2. ADD MISSING COLUMNS TO SESSION_EXERCISES (for Winter Lift blocks)
-- ============================================================================

DO $$ BEGIN
  ALTER TABLE session_exercises ADD COLUMN IF NOT EXISTS block_number INT;
  ALTER TABLE session_exercises ADD COLUMN IF NOT EXISTS block_label TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

COMMENT ON COLUMN session_exercises.block_number IS 'Exercise grouping within session (e.g., 1=Primary, 2=Secondary, 3=Accessories)';
COMMENT ON COLUMN session_exercises.block_label IS 'Human-readable block name (e.g., "Block 1", "Block 2A")';

-- ============================================================================
-- 3. INSERT WINTER LIFT PROGRAM
-- ============================================================================

-- Delete any existing Winter Lift program first (in case of partial data)
DELETE FROM programs WHERE id = '00000000-0000-0000-0000-000000000300';

INSERT INTO programs (
  id,
  patient_id,
  name,
  description,
  start_date,
  end_date,
  status,
  metadata,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000300'::uuid,
  '27d60616-8cb9-4434-b2b9-e84476788e08'::uuid,  -- Nic Roma
  'Winter Lift 3x/week',
  'Progressive 12-week strength building program with 3 training days per week. Focuses on compound lifts, hypertrophy work, and auto-regulated load progression.',
  '2025-01-13'::date,
  '2025-04-06'::date,
  'active',
  '{
    "frequency_per_week": 3,
    "target_level": "Intermediate",
    "program_type": "strength_building",
    "session_pattern": ["Day 1: Anterior Chain", "Day 2: Combo", "Day 3: Posterior Chain"],
    "auto_regulation": {
      "enabled": true,
      "load_progression": "rpe_based",
      "deload_frequency": "as_needed",
      "readiness_tracking": true
    }
  }'::jsonb,
  '2025-01-13 08:00:00'::timestamptz
);

-- ============================================================================
-- 4. INSERT PHASES
-- ============================================================================

INSERT INTO phases (id, program_id, name, sequence, start_date, end_date, duration_weeks, goals, created_at) VALUES
  ('00000000-0000-0000-0000-000000000401'::uuid, '00000000-0000-0000-0000-000000000300'::uuid,
   'Phase 1: Foundation', 1, '2025-01-13'::date, '2025-02-09'::date, 4,
   'Build base strength, establish movement patterns, develop work capacity.',
   '2025-01-13 08:01:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000402'::uuid, '00000000-0000-0000-0000-000000000300'::uuid,
   'Phase 2: Build', 2, '2025-02-10'::date, '2025-03-09'::date, 4,
   'Increase load capacity, progressive overload on primary lifts.',
   '2025-01-13 08:02:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000403'::uuid, '00000000-0000-0000-0000-000000000300'::uuid,
   'Phase 3: Intensify', 3, '2025-03-10'::date, '2025-04-06'::date, 4,
   'Peak strength development, explosive power, auto-regulation.',
   '2025-01-13 08:03:00'::timestamptz);

-- ============================================================================
-- 5. INSERT SESSIONS
-- ============================================================================

INSERT INTO sessions (id, phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes, created_at) VALUES
  -- Phase 1
  ('00000000-0000-0000-0000-000000000501'::uuid, '00000000-0000-0000-0000-000000000401'::uuid,
   'Phase 1 - Day 1: Anterior Chain', 1, 1, 7, false, 'Squat variations, pressing, anterior core. RPE 6-7.', now()),
  ('00000000-0000-0000-0000-000000000502'::uuid, '00000000-0000-0000-0000-000000000401'::uuid,
   'Phase 1 - Day 2: Combo', 2, 3, 6, false, 'Unilateral work, rotational movements. Lower intensity.', now()),
  ('00000000-0000-0000-0000-000000000503'::uuid, '00000000-0000-0000-0000-000000000401'::uuid,
   'Phase 1 - Day 3: Posterior Chain', 3, 5, 7, false, 'Hinge variations, pulling, posterior core. RPE 6-7.', now()),

  -- Phase 2
  ('00000000-0000-0000-0000-000000000504'::uuid, '00000000-0000-0000-0000-000000000402'::uuid,
   'Phase 2 - Day 1: Anterior Chain', 4, 1, 8, false, 'Increased load on squats, pressing. RPE 7-9.', now()),
  ('00000000-0000-0000-0000-000000000505'::uuid, '00000000-0000-0000-0000-000000000402'::uuid,
   'Phase 2 - Day 2: Combo', 5, 3, 7, false, 'Tempo work, unilateral patterns, time under tension.', now()),
  ('00000000-0000-0000-0000-000000000506'::uuid, '00000000-0000-0000-0000-000000000402'::uuid,
   'Phase 2 - Day 3: Posterior Chain', 6, 5, 8, false, 'Progressive hinge loading, pulling volume. RPE 7-9.', now()),

  -- Phase 3
  ('00000000-0000-0000-0000-000000000507'::uuid, '00000000-0000-0000-0000-000000000403'::uuid,
   'Phase 3 - Day 1: Anterior Chain', 7, 1, 9, false, 'Peak squat loads, explosive pressing. RPE 8-9.', now()),
  ('00000000-0000-0000-0000-000000000508'::uuid, '00000000-0000-0000-0000-000000000403'::uuid,
   'Phase 3 - Day 2: Combo', 8, 3, 7, false, 'Explosive unilateral work, rotational power.', now()),
  ('00000000-0000-0000-0000-000000000509'::uuid, '00000000-0000-0000-0000-000000000403'::uuid,
   'Phase 3 - Day 3: Posterior Chain', 9, 5, 9, false, 'Peak hinge loads, high-velocity pulls. RPE 8-9.', now());

-- ============================================================================
-- 6. EXERCISE TEMPLATES (Key exercises for Winter Lift)
-- ============================================================================

INSERT INTO exercise_templates (id, name, category, body_region, equipment, load_type, created_at) VALUES
  ('00000000-0000-0000-0001-000000000001'::uuid, 'Safety Bar Split Squat', 'strength', 'lower_body', 'safety_squat_bar', 'weight', now()),
  ('00000000-0000-0000-0001-000000000002'::uuid, 'Thoracic Rotation Press', 'strength', 'upper_body', 'dumbbell', 'weight', now()),
  ('00000000-0000-0000-0001-000000000010'::uuid, 'Long Bar Rotation Press', 'strength', 'core', 'barbell', 'weight', now()),
  ('00000000-0000-0000-0001-000000000020'::uuid, 'RDL', 'strength', 'lower_body', 'barbell', 'weight', now())
ON CONFLICT (id) DO NOTHING;

-- ============================================================================
-- 7. SESSION EXERCISES (Sample for Phase 1 Day 1)
-- ============================================================================

INSERT INTO session_exercises (
  session_id, exercise_template_id, sequence, block_number, block_label,
  target_sets, target_reps, target_load, target_rpe, notes, created_at
) VALUES
  ('00000000-0000-0000-0000-000000000501'::uuid, '00000000-0000-0000-0001-000000000001'::uuid,
   1, 1, 'Block 1', 3, 6, NULL, 6.5, 'Primary compound. Auto-regulate load to RPE 6-7.', now()),
  ('00000000-0000-0000-0000-000000000501'::uuid, '00000000-0000-0000-0001-000000000002'::uuid,
   2, 1, 'Block 1', 3, 8, NULL, 6.5, 'Primary upper body. Bilateral work.', now());

-- ============================================================================
-- 8. VALIDATION
-- ============================================================================

DO $$
DECLARE
  program_exists boolean;
  phase_count int;
  session_count int;
  resolved_col_exists boolean;
BEGIN
  -- Check program
  SELECT EXISTS(
    SELECT 1 FROM programs WHERE id = '00000000-0000-0000-0000-000000000300'
  ) INTO program_exists;

  -- Count phases
  SELECT COUNT(*) INTO phase_count
  FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300';

  -- Count sessions
  SELECT COUNT(*) INTO session_count
  FROM sessions WHERE phase_id IN (
    SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300'
  );

  -- Check resolved column
  SELECT EXISTS(
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'workload_flags' AND column_name = 'resolved'
  ) INTO resolved_col_exists;

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'WINTER LIFT + WORKLOAD FLAGS FIX';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'Winter Lift program: %', CASE WHEN program_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE 'Phases: % (expected 3)', phase_count;
  RAISE NOTICE 'Sessions: % (expected 9)', session_count;
  RAISE NOTICE 'workload_flags.resolved: %', CASE WHEN resolved_col_exists THEN '✅ EXISTS' ELSE '❌ MISSING' END;
  RAISE NOTICE '============================================';
END $$;
