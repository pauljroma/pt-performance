-- 008_seed_high_severity_flags.sql
-- Seed data for HIGH severity flag testing
-- Creates scenarios that should trigger auto-PCR creation
-- Agent 2 - Phase 2: Risk Engine Testing

-- ============================================================================
-- SCENARIO 1: HIGH PAIN (pain > 5)
-- Update most recent pain log to trigger HIGH pain flag
-- ============================================================================

-- Insert high pain session for John Brebbia
INSERT INTO pain_logs (patient_id, session_id, logged_at, pain_rest, pain_during, pain_after, notes)
VALUES
  ('00000000-0000-0000-0000-000000000001'::uuid, '00000000-0000-0000-0000-000000000412'::uuid, '2025-03-15 15:30:00'::timestamptz, 3, 7, 8, 'Sharp pain during exercises, especially overhead work')
ON CONFLICT DO NOTHING;

-- ============================================================================
-- SCENARIO 2: CRITICAL VELOCITY DROP (> 5 mph)
-- Add recent bullpen session with severe velocity loss
-- ============================================================================

-- Add recent sessions with critical velocity drop
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
  -- Recent session: Critical velocity drop from 94 mph baseline to 88 mph
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-14 14:00:00'::timestamptz, '4-FB', 88, 15, 8, 7, 53.3, 88, 6, 'Arm feels dead, velocity way down'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-14 14:15:00'::timestamptz, 'SL', 81, 10, 4, 6, 40.0, 81, 6, 'No zip on pitches'),

  -- Most recent session: Velocity still down, pain increasing
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-15 14:00:00'::timestamptz, '4-FB', 87, 12, 6, 6, 50.0, 87, 7, 'Elbow pain during throwing, velocity not coming back'),
  ('00000000-0000-0000-0000-000000000001'::uuid, '2025-03-15 14:15:00'::timestamptz, 'SL', 80, 8, 3, 5, 37.5, 80, 7, 'Stopped early due to pain')

ON CONFLICT DO NOTHING;

-- ============================================================================
-- SCENARIO 3: HIGH THROWING PAIN (bullpen pain > 6)
-- Already seeded above - pain_score of 7 in latest bullpen session
-- ============================================================================

-- ============================================================================
-- Expected Flags from this data:
-- ============================================================================
-- 1. HIGH: Pain > 5 (from pain_logs - pain_during=7, pain_after=8)
-- 2. HIGH: Critical velocity drop > 5 mph (94 mph baseline to 87-88 mph recent)
-- 3. HIGH: Throwing pain > 6 (pain_score=7 in latest bullpen)
-- 4. MEDIUM: Command decline > 20% (from 75% to 50-53%)
--
-- These HIGH flags should trigger automatic Linear PCR creation
-- ============================================================================

-- Validation query to check flags will be triggered:
-- SELECT
--   'Pain Logs' as source,
--   logged_at,
--   pain_during,
--   pain_after,
--   notes
-- FROM pain_logs
-- WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
-- ORDER BY logged_at DESC
-- LIMIT 5;
--
-- SELECT
--   'Bullpen Logs' as source,
--   logged_at,
--   pitch_type,
--   velocity,
--   hit_spot_pct,
--   pain_score,
--   notes
-- FROM bullpen_logs
-- WHERE patient_id = '00000000-0000-0000-0000-000000000001'::uuid
-- ORDER BY logged_at DESC
-- LIMIT 10;
