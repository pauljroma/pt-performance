-- 005_seed_session_exercises.sql
-- Session Exercise Prescriptions
-- Agent 3 - Phase 1: Data Layer
--
-- Links exercises from the library to specific sessions in the 8-week program
-- Creates realistic prescriptions with sets, reps, load, RPE
--
-- Run after: 004_seed_exercise_library.sql, 003_seed_demo_data.sql

-- ============================================================================
-- PHASE 1 - FOUNDATION (Weeks 1-2)
-- Focus: Base strength, mobility, tissue capacity
-- Sessions: Week 1 Session 1-3, Week 2 Session 1-3
-- ============================================================================

-- Week 1, Session 1: Introduction to program. Movement assessment.
-- Session ID: '00000000-0000-0000-0000-000000000401'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000401'::uuid, '10000000-0000-0000-0000-000000000050'::uuid, 2, 10, NULL, 4, 'slow', 'Thoracic mobility work', 1),
  ('00000000-0000-0000-0000-000000000401'::uuid, '10000000-0000-0000-0000-000000000024'::uuid, 3, 10, NULL, 3, '2020', 'Scapular mobility', 2),
  ('00000000-0000-0000-0000-000000000401'::uuid, '10000000-0000-0000-0000-000000000042'::uuid, 3, 10, NULL, 4, 'slow', 'Core activation', 3),
  ('00000000-0000-0000-0000-000000000401'::uuid, '10000000-0000-0000-0000-000000000022'::uuid, 3, 15, 2.5, 5, '2121', 'Scapular retraction', 4),
  ('00000000-0000-0000-0000-000000000401'::uuid, '10000000-0000-0000-0000-000000000023'::uuid, 3, 15, 2.5, 5, '2121', 'Lower trap work', 5),
  ('00000000-0000-0000-0000-000000000401'::uuid, '10000000-0000-0000-0000-000000000020'::uuid, 3, 12, 5, 4, '2020', 'External rotation', 6)
ON CONFLICT DO NOTHING;

-- Week 1, Session 2: Build strength foundation
-- Session ID: '00000000-0000-0000-0000-000000000402'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000402'::uuid, '10000000-0000-0000-0000-000000000010'::uuid, 3, 8, 135, 6, '3010', 'Build squat base', 1),
  ('00000000-0000-0000-0000-000000000402'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 3, 8, 95, 6, '3010', 'Bench press intro', 2),
  ('00000000-0000-0000-0000-000000000402'::uuid, '10000000-0000-0000-0000-000000000004'::uuid, 3, 8, 75, 6, '2010', 'Barbell row', 3),
  ('00000000-0000-0000-0000-000000000402'::uuid, '10000000-0000-0000-0000-000000000040'::uuid, 3, 45, NULL, 5, 'static', 'Core stability', 4),
  ('00000000-0000-0000-0000-000000000402'::uuid, '10000000-0000-0000-0000-000000000025'::uuid, 3, 15, NULL, 4, '2020', 'Shoulder health', 5)
ON CONFLICT DO NOTHING;

-- Week 1, Session 3: Mobility and activation work
-- Session ID: '00000000-0000-0000-0000-000000000403'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000403'::uuid, '10000000-0000-0000-0000-000000000052'::uuid, 2, 12, NULL, 3, 'slow', 'Spinal mobility', 1),
  ('00000000-0000-0000-0000-000000000403'::uuid, '10000000-0000-0000-0000-000000000051'::uuid, 2, 60, NULL, 4, 'static', 'Hip mobility', 2),
  ('00000000-0000-0000-0000-000000000403'::uuid, '10000000-0000-0000-0000-000000000053'::uuid, 2, 5, NULL, 5, 'slow', 'Full body mobility', 3),
  ('00000000-0000-0000-0000-000000000403'::uuid, '10000000-0000-0000-0000-000000000061'::uuid, 3, 15, 30, 5, '2020', 'Rear delt work', 4),
  ('00000000-0000-0000-0000-000000000403'::uuid, '10000000-0000-0000-0000-000000000041'::uuid, 3, 30, NULL, 5, 'static', 'Lateral core stability', 5),
  ('00000000-0000-0000-0000-000000000403'::uuid, '10000000-0000-0000-0000-000000000054'::uuid, 2, 45, NULL, 4, 'static', 'Shoulder IR stretch', 6)
ON CONFLICT DO NOTHING;

-- Week 2, Session 1: Increase volume slightly
-- Session ID: '00000000-0000-0000-0000-000000000404'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000404'::uuid, '10000000-0000-0000-0000-000000000010'::uuid, 4, 8, 145, 6, '3010', 'Progress load', 1),
  ('00000000-0000-0000-0000-000000000404'::uuid, '10000000-0000-0000-0000-000000000013'::uuid, 3, 10, 95, 6, '3010', 'RDL for hamstrings', 2),
  ('00000000-0000-0000-0000-000000000404'::uuid, '10000000-0000-0000-0000-000000000003'::uuid, 3, 8, 0, 6, '2010', 'Bodyweight pull-ups', 3),
  ('00000000-0000-0000-0000-000000000404'::uuid, '10000000-0000-0000-0000-000000000060'::uuid, 3, 10, 40, 6, '2010', 'Single-arm row', 4),
  ('00000000-0000-0000-0000-000000000404'::uuid, '10000000-0000-0000-0000-000000000043'::uuid, 3, 12, 40, 6, '2020', 'Anti-rotation core', 5)
ON CONFLICT DO NOTHING;

-- Week 2, Session 2: Progressive overload
-- Session ID: '00000000-0000-0000-0000-000000000405'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000405'::uuid, '10000000-0000-0000-0000-000000000011'::uuid, 3, 5, 185, 7, '2010', 'Deadlift progression', 1),
  ('00000000-0000-0000-0000-000000000405'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 4, 8, 105, 7, '3010', 'Bench volume', 2),
  ('00000000-0000-0000-0000-000000000405'::uuid, '10000000-0000-0000-0000-000000000012'::uuid, 3, 10, 30, 7, '2010', 'Bulgarian split squat', 3),
  ('00000000-0000-0000-0000-000000000405'::uuid, '10000000-0000-0000-0000-000000000062'::uuid, 3, 12, 12.5, 6, '2020', 'Lateral raise', 4),
  ('00000000-0000-0000-0000-000000000405'::uuid, '10000000-0000-0000-0000-000000000044'::uuid, 3, 10, 0, 7, '2010', 'Hanging leg raise', 5)
ON CONFLICT DO NOTHING;

-- Week 2, Session 3: Recovery and mobility
-- Session ID: '00000000-0000-0000-0000-000000000406'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000406'::uuid, '10000000-0000-0000-0000-000000000080'::uuid, 1, 1200, NULL, 4, 'steady', '20min steady bike', 1),
  ('00000000-0000-0000-0000-000000000406'::uuid, '10000000-0000-0000-0000-000000000050'::uuid, 2, 12, NULL, 3, 'slow', 'T-spine mobility', 2),
  ('00000000-0000-0000-0000-000000000406'::uuid, '10000000-0000-0000-0000-000000000051'::uuid, 2, 60, NULL, 3, 'static', 'Hip stretching', 3),
  ('00000000-0000-0000-0000-000000000406'::uuid, '10000000-0000-0000-0000-000000000022'::uuid, 3, 20, 2.5, 3, '2020', 'Light arm care', 4),
  ('00000000-0000-0000-0000-000000000406'::uuid, '10000000-0000-0000-0000-000000000020'::uuid, 3, 15, 5, 3, '2020', 'External rotation', 5)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PHASE 2 - BUILD (Weeks 3-4)
-- Focus: Load tolerance, light plyometrics
-- Sessions: Week 3 Session 1-3, Week 4 Session 1-3
-- ============================================================================

-- Week 3, Session 1: Introduce plyo drills
-- Session ID: '00000000-0000-0000-0000-000000000407'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000407'::uuid, '10000000-0000-0000-0000-000000000030'::uuid, 3, 10, NULL, 6, 'explosive', 'Med ball chest pass 6lb', 1),
  ('00000000-0000-0000-0000-000000000407'::uuid, '10000000-0000-0000-0000-000000000032'::uuid, 3, 10, NULL, 6, 'explosive', 'Rotational throws 8lb', 2),
  ('00000000-0000-0000-0000-000000000407'::uuid, '10000000-0000-0000-0000-000000000010'::uuid, 4, 6, 155, 7, '3010', 'Squat strength', 3),
  ('00000000-0000-0000-0000-000000000407'::uuid, '10000000-0000-0000-0000-000000000005'::uuid, 3, 10, 35, 7, '3010', 'Incline DB press', 4),
  ('00000000-0000-0000-0000-000000000407'::uuid, '10000000-0000-0000-0000-000000000061'::uuid, 3, 15, 35, 6, '2020', 'Face pulls', 5)
ON CONFLICT DO NOTHING;

-- Week 3, Session 2: Strength + plyo combo
-- Session ID: '00000000-0000-0000-0000-000000000408'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000408'::uuid, '10000000-0000-0000-0000-000000000011'::uuid, 3, 5, 205, 7, '2010', 'Deadlift build', 1),
  ('00000000-0000-0000-0000-000000000408'::uuid, '10000000-0000-0000-0000-000000000001'::uuid, 4, 6, 115, 7, '3010', 'Bench heavy sets', 2),
  ('00000000-0000-0000-0000-000000000408'::uuid, '10000000-0000-0000-0000-000000000031'::uuid, 3, 8, NULL, 7, 'explosive', 'Med ball slam 10lb', 3),
  ('00000000-0000-0000-0000-000000000408'::uuid, '10000000-0000-0000-0000-000000000014'::uuid, 3, 12, 25, 6, '2010', 'Walking lunges', 4),
  ('00000000-0000-0000-0000-000000000408'::uuid, '10000000-0000-0000-0000-000000000043'::uuid, 3, 15, 50, 7, '2020', 'Pallof press', 5)
ON CONFLICT DO NOTHING;

-- Week 4, Session 1: Increase plyo intensity
-- Session ID: '00000000-0000-0000-0000-000000000410'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000410'::uuid, '10000000-0000-0000-0000-000000000033'::uuid, 3, 8, NULL, 7, 'explosive', 'Plyo ball 2oz throws', 1),
  ('00000000-0000-0000-0000-000000000410'::uuid, '10000000-0000-0000-0000-000000000074'::uuid, 2, 10, NULL, 5, 'controlled', 'Towel drill mechanics', 2),
  ('00000000-0000-0000-0000-000000000410'::uuid, '10000000-0000-0000-0000-000000000010'::uuid, 4, 5, 165, 8, '3010', 'Squat near max', 3),
  ('00000000-0000-0000-0000-000000000410'::uuid, '10000000-0000-0000-0000-000000000004'::uuid, 4, 8, 95, 7, '2010', 'Barbell row volume', 4),
  ('00000000-0000-0000-0000-000000000410'::uuid, '10000000-0000-0000-0000-000000000082'::uuid, 4, 40, NULL, 7, 'explosive', 'Sled push 40m', 5)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PHASE 3 - INTENSIFY (Weeks 5-6)
-- Focus: Progressive throwing volume
-- Sessions include structured throwing
-- ============================================================================

-- Week 5, Session 1: First structured throwing session
-- Session ID: '00000000-0000-0000-0000-000000000413'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000413'::uuid, '10000000-0000-0000-0000-000000000074'::uuid, 2, 10, NULL, 4, 'controlled', 'Warm-up: towel drill', 1),
  ('00000000-0000-0000-0000-000000000413'::uuid, '10000000-0000-0000-0000-000000000071'::uuid, 1, 25, NULL, 6, 'controlled', 'Flat ground 60ft', 2),
  ('00000000-0000-0000-0000-000000000413'::uuid, '10000000-0000-0000-0000-000000000070'::uuid, 1, 15, NULL, 6, 'controlled', 'Long toss to 120ft', 3),
  ('00000000-0000-0000-0000-000000000413'::uuid, '10000000-0000-0000-0000-000000000020'::uuid, 3, 12, 7.5, 5, '2020', 'Post-throw arm care', 4),
  ('00000000-0000-0000-0000-000000000413'::uuid, '10000000-0000-0000-0000-000000000021'::uuid, 3, 12, 20, 5, '2020', 'Internal rotation', 5)
ON CONFLICT DO NOTHING;

-- Week 5, Session 2: Throwing + strength
-- Session ID: '00000000-0000-0000-0000-000000000414'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000414'::uuid, '10000000-0000-0000-0000-000000000071'::uuid, 1, 30, NULL, 7, 'controlled', 'Flat ground throwing', 1),
  ('00000000-0000-0000-0000-000000000414'::uuid, '10000000-0000-0000-0000-000000000073'::uuid, 1, 12, NULL, 6, 'controlled', 'Rocker drill', 2),
  ('00000000-0000-0000-0000-000000000414'::uuid, '10000000-0000-0000-0000-000000000010'::uuid, 3, 5, 175, 8, '3010', 'Lower body strength', 3),
  ('00000000-0000-0000-0000-000000000414'::uuid, '10000000-0000-0000-0000-000000000013'::uuid, 3, 8, 115, 7, '3010', 'RDL', 4),
  ('00000000-0000-0000-0000-000000000414'::uuid, '10000000-0000-0000-0000-000000000025'::uuid, 3, 20, NULL, 5, '2020', 'Band pull-aparts', 5)
ON CONFLICT DO NOTHING;

-- Week 6, Session 2: Peak throwing intensity
-- Session ID: '00000000-0000-0000-0000-000000000417'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000417'::uuid, '10000000-0000-0000-0000-000000000072'::uuid, 1, 30, NULL, 8, 'max intent', 'First bullpen session', 1),
  ('00000000-0000-0000-0000-000000000417'::uuid, '10000000-0000-0000-0000-000000000034'::uuid, 3, 6, NULL, 7, 'controlled', 'Heavy plyo ball 14oz', 2),
  ('00000000-0000-0000-0000-000000000417'::uuid, '10000000-0000-0000-0000-000000000020'::uuid, 3, 15, 7.5, 4, '2020', 'External rotation recovery', 3),
  ('00000000-0000-0000-0000-000000000417'::uuid, '10000000-0000-0000-0000-000000000054'::uuid, 2, 45, NULL, 4, 'static', 'Sleeper stretch', 4)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- PHASE 4 - RETURN TO PERFORMANCE (Weeks 7-8)
-- Focus: Full velocity, game simulation
-- ============================================================================

-- Week 7, Session 1: Full velocity throwing
-- Session ID: '00000000-0000-0000-0000-000000000419'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000419'::uuid, '10000000-0000-0000-0000-000000000072'::uuid, 1, 35, NULL, 9, 'max intent', 'Full bullpen - all pitches', 1),
  ('00000000-0000-0000-0000-000000000419'::uuid, '10000000-0000-0000-0000-000000000020'::uuid, 3, 12, 7.5, 4, '2020', 'Post-throw care', 2),
  ('00000000-0000-0000-0000-000000000419'::uuid, '10000000-0000-0000-0000-000000000061'::uuid, 3, 15, 40, 5, '2020', 'Face pulls', 3)
ON CONFLICT DO NOTHING;

-- Week 7, Session 2: Simulated game conditions
-- Session ID: '00000000-0000-0000-0000-000000000420'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000420'::uuid, '10000000-0000-0000-0000-000000000072'::uuid, 1, 35, NULL, 9, 'game simulation', 'Simulate 1 inning work', 1),
  ('00000000-0000-0000-0000-000000000420'::uuid, '10000000-0000-0000-0000-000000000010'::uuid, 3, 5, 185, 8, '3010', 'Maintain strength', 2),
  ('00000000-0000-0000-0000-000000000420'::uuid, '10000000-0000-0000-0000-000000000013'::uuid, 3, 6, 125, 8, '3010', 'RDL strength', 3),
  ('00000000-0000-0000-0000-000000000420'::uuid, '10000000-0000-0000-0000-000000000025'::uuid, 3, 20, NULL, 4, '2020', 'Recovery work', 4)
ON CONFLICT DO NOTHING;

-- Week 8, Session 2: Final assessment bullpen
-- Session ID: '00000000-0000-0000-0000-000000000423'
INSERT INTO session_exercises (session_id, exercise_template_id, target_sets, target_reps, target_load, target_rpe, tempo, notes, sequence) VALUES
  ('00000000-0000-0000-0000-000000000423'::uuid, '10000000-0000-0000-0000-000000000072'::uuid, 1, 35, NULL, 9, 'assessment', 'Final velocity check', 1),
  ('00000000-0000-0000-0000-000000000423'::uuid, '10000000-0000-0000-0000-000000000020'::uuid, 3, 15, 7.5, 4, '2020', 'Arm care', 2),
  ('00000000-0000-0000-0000-000000000423'::uuid, '10000000-0000-0000-0000-000000000054'::uuid, 2, 60, NULL, 4, 'static', 'Final stretching', 3)
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SAMPLE EXERCISE LOGS (for completed sessions)
-- ============================================================================

-- Week 1, Session 1 logs
INSERT INTO exercise_logs (patient_id, session_id, session_exercise_id, performed_at, set_number, actual_reps, actual_load, rpe, pain_score, notes)
SELECT
  '00000000-0000-0000-0000-000000000001'::uuid as patient_id,
  '00000000-0000-0000-0000-000000000401'::uuid as session_id,
  se.id as session_exercise_id,
  '2025-02-03 14:30:00'::timestamptz as performed_at,
  1 as set_number,
  se.target_reps as actual_reps,
  se.target_load as actual_load,
  se.target_rpe as rpe,
  0 as pain_score,
  'First session - good form' as notes
FROM session_exercises se
WHERE se.session_id = '00000000-0000-0000-0000-000000000401'::uuid
ON CONFLICT DO NOTHING;

-- ============================================================================
-- VALIDATION QUERIES
-- ============================================================================

-- Count session_exercises by phase
SELECT
  ph.name as phase,
  count(distinct se.id) as exercise_count,
  count(distinct se.session_id) as session_count
FROM session_exercises se
JOIN sessions s ON s.id = se.session_id
JOIN phases ph ON ph.id = s.phase_id
GROUP BY ph.name, ph.sequence
ORDER BY ph.sequence;

-- List exercises by session for Week 1
SELECT
  s.name as session,
  et.name as exercise,
  se.target_sets as sets,
  se.target_reps as reps,
  se.target_load as load,
  se.target_rpe as rpe,
  se.sequence
FROM session_exercises se
JOIN sessions s ON s.id = se.session_id
JOIN exercise_templates et ON et.id = se.exercise_template_id
WHERE s.sequence <= 3
ORDER BY s.sequence, se.sequence;
