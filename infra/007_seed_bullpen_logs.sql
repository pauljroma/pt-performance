-- 007_seed_bullpen_logs.sql
-- Seed bullpen logs for John Brebbia to test velocity and command flags
-- Agent 2 - Phase 2: Risk Engine Testing

-- ============================================================================
-- BULLPEN LOGS FOR JOHN BREBBIA
-- Demonstrates velocity drops and command issues
-- ============================================================================

-- Week 5 - First throwing sessions (baseline velocity)
INSERT INTO bullpen_logs (
  patient_id,
  logged_at,
  pitch_type,
  velocity,
  pitch_count,
  hit_spot_count,
  missed_spot_count,
  hit_spot_pct,
  avg_velocity,
  pain_score,
  notes
) VALUES
  -- Session 1: Baseline (good velocity, moderate command)
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-01 14:00:00'::timestamptz, '4-FB', 92, 15, 10, 5, 66.7, 92, 2, 'First bullpen - felt good'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-01 14:15:00'::timestamptz, 'SL', 84, 10, 7, 3, 70.0, 84, 2, 'Slider command solid'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-01 14:25:00'::timestamptz, 'CH', 82, 10, 5, 5, 50.0, 82, 2, 'Changeup needs work'),

  -- Session 2: Good progression
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-03 14:00:00'::timestamptz, '4-FB', 93, 20, 14, 6, 70.0, 93, 1, 'Velocity up, feeling strong'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-03 14:20:00'::timestamptz, 'SL', 85, 12, 9, 3, 75.0, 85, 1, 'Command improving'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-03 14:35:00'::timestamptz, 'CH', 83, 10, 6, 4, 60.0, 83, 1, 'Better changeup command'),

  -- Session 3: Peak velocity
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-05 14:00:00'::timestamptz, '4-FB', 94, 20, 15, 5, 75.0, 94, 1, 'Peak velocity reached'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-05 14:20:00'::timestamptz, 'SL', 86, 12, 10, 2, 83.3, 86, 1, 'Slider command excellent'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-05 14:35:00'::timestamptz, 'CH', 84, 10, 7, 3, 70.0, 84, 2, 'Good changeup'),

-- Week 6 - Moderate velocity drop (should trigger MEDIUM flag)
  -- Session 4: Small drop
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-08 14:00:00'::timestamptz, '4-FB', 91, 20, 13, 7, 65.0, 91, 3, 'Felt a bit tired'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-08 14:20:00'::timestamptz, 'SL', 84, 12, 8, 4, 66.7, 84, 3, 'Command slipping'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-08 14:35:00'::timestamptz, 'CH', 82, 10, 5, 5, 50.0, 82, 3, 'Changeup inconsistent'),

  -- Session 5: Further drop (should trigger MEDIUM velocity flag)
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-10 14:00:00'::timestamptz, '4-FB', 90, 20, 12, 8, 60.0, 90, 4, 'Velocity down, arm feeling heavy'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-10 14:20:00'::timestamptz, 'SL', 83, 12, 7, 5, 58.3, 83, 4, 'Command issues'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-10 14:35:00'::timestamptz, 'CH', 81, 10, 4, 6, 40.0, 81, 4, 'Struggling with changeup'),

  -- Session 6: Command decline (should trigger MEDIUM command flag)
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-12 14:00:00'::timestamptz, '4-FB', 89, 20, 10, 10, 50.0, 89, 5, 'Command really off today'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-12 14:20:00'::timestamptz, 'SL', 82, 12, 5, 7, 41.7, 82, 5, 'Missing spots badly'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-12 14:35:00'::timestamptz, 'CH', 80, 10, 3, 7, 30.0, 80, 5, 'Changeup not working')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- VALIDATION QUERY
-- ============================================================================
-- SELECT
--   logged_at::date as date,
--   pitch_type,
--   velocity,
--   hit_spot_pct,
--   pain_score,
--   notes
-- FROM bullpen_logs
-- WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
-- ORDER BY logged_at;
