-- 20251213000003_seed_winter_lift_program.sql
-- Create "Winter Lift 3x/week" program for Nic Roma
-- Zone-7 (Data Access), Zone-8 (Data Ingestion)
-- ACP-123: Program Seed Migration for Auto-Regulation System
--
-- Structure:
-- 1 Program: Winter Lift 3x/week (12 weeks, 3 phases)
-- 3 Phases: Foundation, Build, Intensify (4 weeks each)
-- 9 Sessions: 3 per phase (Day 1: Anterior, Day 2: Combo, Day 3: Posterior)
-- Full JSON stored in programs.metadata for archival
--
-- Run after: 20251213000001_seed_nic_roma_patient.sql

-- ============================================================================
-- SCHEMA ENHANCEMENT: Add block_number to session_exercises
-- ============================================================================
-- Winter Lift program uses "blocks" to group exercises within sessions
-- (e.g., Block 1: Primary lifts, Block 2: Secondary work, Block 3: Accessories)

DO $$ BEGIN
  ALTER TABLE session_exercises ADD COLUMN IF NOT EXISTS block_number INT;
  ALTER TABLE session_exercises ADD COLUMN IF NOT EXISTS block_label TEXT;
EXCEPTION WHEN duplicate_column THEN NULL; END $$;

COMMENT ON COLUMN session_exercises.block_number IS 'Exercise grouping within session (e.g., 1=Primary, 2=Secondary, 3=Accessories)';
COMMENT ON COLUMN session_exercises.block_label IS 'Human-readable block name (e.g., "Block 1", "Block 2A")';

-- ============================================================================
-- 1. PROGRAM: Winter Lift 3x/week
-- ============================================================================

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
    },
    "phase_structure": {
      "total_phases": 3,
      "weeks_per_phase": 4,
      "advancement_criteria": "completion_and_performance"
    }
  }'::jsonb,
  '2025-01-13 08:00:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 2. PHASES (3 phases x 4 weeks each)
-- ============================================================================

-- Phase 1: Foundation (Weeks 1-4)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000401'::uuid,
  '00000000-0000-0000-0000-000000000300'::uuid,
  'Phase 1: Foundation',
  1,
  '2025-01-13'::date,
  '2025-02-09'::date,
  4,
  'Build base strength, establish movement patterns, develop work capacity. Focus on movement quality and RPE calibration.',
  '{
    "max_intensity_pct": 75,
    "rpe_range": [6, 7],
    "required_movement_patterns": ["squat", "hinge", "push", "pull", "carry"],
    "progression_criteria": {
      "adherence_pct": 90,
      "rpe_accuracy": "within_range",
      "pain_threshold": 3,
      "form_quality": "good"
    }
  }'::jsonb,
  'Focus: Base building, movement quality, RPE calibration. No maximal efforts.',
  '2025-01-13 08:01:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- Phase 2: Build (Weeks 5-8)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000402'::uuid,
  '00000000-0000-0000-0000-000000000300'::uuid,
  'Phase 2: Build',
  2,
  '2025-02-10'::date,
  '2025-03-09'::date,
  4,
  'Increase load capacity, improve time under tension, develop strength endurance. Progressive overload on primary lifts.',
  '{
    "max_intensity_pct": 88,
    "rpe_range": [7, 9],
    "required_movement_patterns": ["squat", "hinge", "push", "pull", "unilateral"],
    "progression_criteria": {
      "adherence_pct": 90,
      "progressive_overload": true,
      "pain_threshold": 3,
      "rpe_management": "consistent"
    }
  }'::jsonb,
  'Focus: Load progression, hypertrophy emphasis, introduce tempo variations.',
  '2025-01-13 08:02:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- Phase 3: Intensify (Weeks 9-12)
INSERT INTO phases (
  id,
  program_id,
  name,
  sequence,
  start_date,
  end_date,
  duration_weeks,
  goals,
  constraints,
  notes,
  created_at
)
VALUES (
  '00000000-0000-0000-0000-000000000403'::uuid,
  '00000000-0000-0000-0000-000000000300'::uuid,
  'Phase 3: Intensify',
  3,
  '2025-03-10'::date,
  '2025-04-06'::date,
  4,
  'Peak strength development, explosive power, work capacity maintenance. Higher intensities with auto-regulation.',
  '{
    "max_intensity_pct": 92,
    "rpe_range": [8, 9],
    "required_movement_patterns": ["squat", "hinge", "push", "pull", "explosive"],
    "progression_criteria": {
      "adherence_pct": 90,
      "strength_gains": true,
      "pain_threshold": 2,
      "bar_speed_maintained": true
    }
  }'::jsonb,
  'Focus: Peak strength, explosive variations, deload as needed based on readiness.',
  '2025-01-13 08:03:00'::timestamptz
)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 3. SESSIONS (3 per phase = 9 total)
-- ============================================================================

-- PHASE 1 SESSIONS (Foundation)
INSERT INTO sessions (id, phase_id, name, sequence, weekday, intensity_rating, is_throwing_day, notes, created_at) VALUES
  ('00000000-0000-0000-0000-000000000501'::uuid, '00000000-0000-0000-0000-000000000401'::uuid,
   'Phase 1 - Day 1: Anterior Chain', 1, 1, 7, false,
   'Focus: Squat variations, pressing, anterior core. RPE 6-7 range.',
   '2025-01-13 08:10:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000502'::uuid, '00000000-0000-0000-0000-000000000401'::uuid,
   'Phase 1 - Day 2: Combo', 2, 3, 6, false,
   'Focus: Unilateral work, rotational movements, mixed patterns. Lower intensity.',
   '2025-01-13 08:11:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000503'::uuid, '00000000-0000-0000-0000-000000000401'::uuid,
   'Phase 1 - Day 3: Posterior Chain', 3, 5, 7, false,
   'Focus: Hinge variations, pulling, posterior core. RPE 6-7 range.',
   '2025-01-13 08:12:00'::timestamptz),

-- PHASE 2 SESSIONS (Build)
  ('00000000-0000-0000-0000-000000000504'::uuid, '00000000-0000-0000-0000-000000000402'::uuid,
   'Phase 2 - Day 1: Anterior Chain', 4, 1, 8, false,
   'Focus: Increased load on squat variations, pressing. RPE 7-9 range.',
   '2025-01-13 08:13:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000505'::uuid, '00000000-0000-0000-0000-000000000402'::uuid,
   'Phase 2 - Day 2: Combo', 5, 3, 7, false,
   'Focus: Tempo work, unilateral patterns, time under tension.',
   '2025-01-13 08:14:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000506'::uuid, '00000000-0000-0000-0000-000000000402'::uuid,
   'Phase 2 - Day 3: Posterior Chain', 6, 5, 8, false,
   'Focus: Progressive hinge loading, pulling volume. RPE 7-9 range.',
   '2025-01-13 08:15:00'::timestamptz),

-- PHASE 3 SESSIONS (Intensify)
  ('00000000-0000-0000-0000-000000000507'::uuid, '00000000-0000-0000-0000-000000000403'::uuid,
   'Phase 3 - Day 1: Anterior Chain', 7, 1, 9, false,
   'Focus: Peak squat loads, explosive pressing. RPE 8-9 range.',
   '2025-01-13 08:16:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000508'::uuid, '00000000-0000-0000-0000-000000000403'::uuid,
   'Phase 3 - Day 2: Combo', 8, 3, 7, false,
   'Focus: Explosive unilateral work, rotational power.',
   '2025-01-13 08:17:00'::timestamptz),

  ('00000000-0000-0000-0000-000000000509'::uuid, '00000000-0000-0000-0000-000000000403'::uuid,
   'Phase 3 - Day 3: Posterior Chain', 9, 5, 9, false,
   'Focus: Peak hinge loads, high-velocity pulls. RPE 8-9 range.',
   '2025-01-13 08:18:00'::timestamptz)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 4. EXERCISE TEMPLATES (Sample exercises for Winter Lift)
-- ============================================================================
-- Create commonly used exercises if they don't exist
-- Note: In production, you would reference existing exercise_template_id values

-- Phase 1 - Day 1 Primary Exercises
INSERT INTO exercise_templates (id, name, category, body_region, equipment, load_type, cueing, created_at) VALUES
  ('00000000-0000-0000-0001-000000000001'::uuid, 'Safety Bar Split Squat', 'strength', 'lower_body', 'safety_squat_bar', 'weight', 'Upright torso, drive through heel', now()),
  ('00000000-0000-0000-0001-000000000002'::uuid, 'Thoracic Rotation Press', 'strength', 'upper_body', 'dumbbell', 'weight', 'Rotate through thoracic spine, stable pelvis', now()),
  ('00000000-0000-0000-0001-000000000003'::uuid, 'Landmine Lateral Lunge', 'strength', 'lower_body', 'barbell', 'weight', 'Load lateral hip, knee tracking toes', now()),
  ('00000000-0000-0000-0001-000000000004'::uuid, 'Tall Sit Banded Arnold Press', 'strength', 'upper_body', 'band', 'weight', 'Tall spine, controlled rotation', now())
ON CONFLICT DO NOTHING;

-- Phase 1 - Day 2 Exercises
INSERT INTO exercise_templates (id, name, category, body_region, equipment, load_type, cueing, created_at) VALUES
  ('00000000-0000-0000-0001-000000000010'::uuid, 'Long Bar Rotation Press', 'strength', 'core', 'barbell', 'weight', 'Anti-rotation control, stable hips', now()),
  ('00000000-0000-0000-0001-000000000011'::uuid, 'Banded Bench Press', 'strength', 'upper_body', 'band', 'weight', 'Accommodating resistance, full ROM', now()),
  ('00000000-0000-0000-0001-000000000012'::uuid, 'Pallof Press Staggered', 'core', 'core', 'cable', 'weight', 'Anti-rotation, tall posture', now())
ON CONFLICT DO NOTHING;

-- Phase 1 - Day 3 Exercises
INSERT INTO exercise_templates (id, name, category, body_region, equipment, load_type, cueing, created_at) VALUES
  ('00000000-0000-0000-0001-000000000020'::uuid, 'RDL', 'strength', 'lower_body', 'barbell', 'weight', 'Hip hinge, neutral spine, tension', now()),
  ('00000000-0000-0000-0001-000000000021'::uuid, 'Chest Supported Row', 'strength', 'upper_body', 'dumbbell', 'weight', 'Scapular retraction, elbow path', now()),
  ('00000000-0000-0000-0001-000000000022'::uuid, 'Suitcase Carry', 'strength', 'core', 'dumbbell', 'weight', 'Anti-lateral flexion, tall spine', now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 5. SESSION EXERCISES (Sample structure for Phase 1 - Day 1)
-- ============================================================================
-- This demonstrates the block structure pattern
-- Full program would include all ~120 exercises across all 9 sessions

-- Phase 1, Day 1, Block 1 (Primary Compound)
INSERT INTO session_exercises (
  session_id,
  exercise_template_id,
  sequence,
  block_number,
  block_label,
  target_sets,
  target_reps,
  target_load,
  target_rpe,
  tempo,
  notes,
  created_at
) VALUES
  ('00000000-0000-0000-0000-000000000501'::uuid,
   '00000000-0000-0000-0001-000000000001'::uuid,  -- Safety Bar Split Squat
   1, 1, 'Block 1',
   3, 6, NULL, 6.5,
   NULL,
   'Primary compound. Auto-regulate load to hit RPE 6-7. Record last set RPE.',
   now()),

  ('00000000-0000-0000-0000-000000000501'::uuid,
   '00000000-0000-0000-0001-000000000002'::uuid,  -- Thoracic Rotation Press
   2, 1, 'Block 1',
   3, 8, NULL, 6.5,
   NULL,
   'Primary upper body. Bilateral work. RPE 6-7.',
   now()),

-- Phase 1, Day 1, Block 2 (Secondary Unilateral)
  ('00000000-0000-0000-0000-000000000501'::uuid,
   '00000000-0000-0000-0001-000000000003'::uuid,  -- Landmine Lateral Lunge
   3, 2, 'Block 2',
   3, 8, NULL, 7.0,
   NULL,
   'Unilateral lower body. Control eccentric, drive concentrically.',
   now()),

  ('00000000-0000-0000-0000-000000000501'::uuid,
   '00000000-0000-0000-0001-000000000004'::uuid,  -- Tall Sit Banded Arnold
   4, 2, 'Block 2',
   3, 10, NULL, 6.0,
   NULL,
   'Accessory pressing volume. Focus on quality movement.',
   now())
ON CONFLICT DO NOTHING;

-- Phase 1, Day 2 sample exercises
INSERT INTO session_exercises (
  session_id,
  exercise_template_id,
  sequence,
  block_number,
  block_label,
  target_sets,
  target_reps,
  target_load,
  target_rpe,
  notes,
  created_at
) VALUES
  ('00000000-0000-0000-0000-000000000502'::uuid,
   '00000000-0000-0000-0001-000000000010'::uuid,  -- Long Bar Rotation Press
   1, 1, 'Block 1',
   3, 6, NULL, 6.5,
   'Anti-rotation emphasis. Control throughout ROM.',
   now()),

  ('00000000-0000-0000-0000-000000000502'::uuid,
   '00000000-0000-0000-0001-000000000011'::uuid,  -- Banded Bench
   2, 2, 'Block 2',
   3, 8, NULL, 7.0,
   'Accommodating resistance. Pause at chest.',
   now()),

  ('00000000-0000-0000-0000-000000000502'::uuid,
   '00000000-0000-0000-0001-000000000012'::uuid,  -- Pallof Press
   3, 3, 'Block 3',
   3, 10, NULL, 5.0,
   'Core stability. Maintain neutral spine.',
   now())
ON CONFLICT DO NOTHING;

-- Phase 1, Day 3 sample exercises
INSERT INTO session_exercises (
  session_id,
  exercise_template_id,
  sequence,
  block_number,
  block_label,
  target_sets,
  target_reps,
  target_load,
  target_rpe,
  notes,
  created_at
) VALUES
  ('00000000-0000-0000-0000-000000000503'::uuid,
   '00000000-0000-0000-0001-000000000020'::uuid,  -- RDL
   1, 1, 'Block 1',
   3, 6, NULL, 6.5,
   'Primary hinge. Maintain tension throughout. RPE 6-7.',
   now()),

  ('00000000-0000-0000-0000-000000000503'::uuid,
   '00000000-0000-0000-0001-000000000021'::uuid,  -- Chest Supported Row
   2, 2, 'Block 2',
   3, 8, NULL, 7.0,
   'Pulling volume. Scapular control.',
   now()),

  ('00000000-0000-0000-0000-000000000503'::uuid,
   '00000000-0000-0000-0001-000000000022'::uuid,  -- Suitcase Carry
   3, 3, 'Block 3',
   3, 30, NULL, 6.0,
   'Anti-lateral flexion. Distance or time based.',
   now())
ON CONFLICT DO NOTHING;

-- ============================================================================
-- 6. FULL PROGRAM JSON (stored in metadata for archival)
-- ============================================================================
-- Store complete program structure in JSONB for export/archival purposes

UPDATE programs
SET metadata = metadata || '{
  "full_program_json_version": "1.0",
  "program_structure": {
    "name": "Winter Lift 3x/week",
    "duration_weeks": 12,
    "frequency_per_week": 3,
    "phases": [
      {
        "phase_number": 1,
        "name": "Foundation",
        "duration_weeks": 4,
        "rpe_range": [6, 7],
        "focus": "Base building, movement quality, RPE calibration",
        "days": ["Day 1: Anterior Chain", "Day 2: Combo", "Day 3: Posterior Chain"]
      },
      {
        "phase_number": 2,
        "name": "Build",
        "duration_weeks": 4,
        "rpe_range": [7, 9],
        "focus": "Load progression, hypertrophy emphasis, tempo variations",
        "days": ["Day 1: Anterior Chain", "Day 2: Combo", "Day 3: Posterior Chain"]
      },
      {
        "phase_number": 3,
        "name": "Intensify",
        "duration_weeks": 4,
        "rpe_range": [8, 9],
        "focus": "Peak strength, explosive variations, auto-regulation",
        "days": ["Day 1: Anterior Chain", "Day 2: Combo", "Day 3: Posterior Chain"]
      }
    ],
    "auto_regulation_features": {
      "load_progression": {
        "method": "rpe_based",
        "rules": {
          "if_rpe_low": "increase_load",
          "if_rpe_high": "decrease_load",
          "if_rpe_in_range": "maintain_load"
        }
      },
      "readiness_modifications": {
        "green_band": "full_prescription",
        "yellow_band": "reduce_top_set_5_8_pct",
        "orange_band": "skip_top_set",
        "red_band": "technique_only"
      },
      "deload_triggers": [
        "missed_reps_primary",
        "rpe_overshoot",
        "joint_pain",
        "readiness_low"
      ]
    }
  }
}'::jsonb
WHERE id = '00000000-0000-0000-0000-000000000300';

-- ============================================================================
-- VALIDATION QUERIES (for testing)
-- ============================================================================

-- Count check
-- SELECT 'Programs' as entity, count(*) from programs WHERE id = '00000000-0000-0000-0000-000000000300'
-- UNION ALL
-- SELECT 'Phases', count(*) from phases WHERE program_id = '00000000-0000-0000-0000-000000000300'
-- UNION ALL
-- SELECT 'Sessions', count(*) from sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300')
-- UNION ALL
-- SELECT 'Exercises', count(*) from session_exercises WHERE session_id IN (SELECT id FROM sessions WHERE phase_id IN (SELECT id FROM phases WHERE program_id = '00000000-0000-0000-0000-000000000300'));

-- Program summary
-- SELECT
--   pr.name as program,
--   ph.name as phase,
--   s.name as session,
--   COUNT(DISTINCT se.id) as exercise_count
-- FROM programs pr
-- JOIN phases ph ON ph.program_id = pr.id
-- JOIN sessions s ON s.phase_id = ph.id
-- LEFT JOIN session_exercises se ON se.session_id = s.id
-- WHERE pr.id = '00000000-0000-0000-0000-000000000300'
-- GROUP BY pr.name, ph.name, ph.sequence, s.name, s.sequence
-- ORDER BY ph.sequence, s.sequence;

-- Block structure check
-- SELECT
--   s.name as session,
--   se.block_number,
--   se.block_label,
--   et.name as exercise,
--   se.target_sets || 'x' || se.target_reps as prescription,
--   se.target_rpe as rpe
-- FROM sessions s
-- JOIN session_exercises se ON se.session_id = s.id
-- JOIN exercise_templates et ON et.id = se.exercise_template_id
-- WHERE s.id = '00000000-0000-0000-0000-000000000501'
-- ORDER BY se.sequence;
