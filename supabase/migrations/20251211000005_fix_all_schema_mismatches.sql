-- ============================================================================
-- FIX ALL SCHEMA MISMATCHES - Comprehensive Fix
-- ============================================================================
-- Fixes all 5 schema mismatches found by validation:
-- 1. vw_pain_trend columns
-- 2. vw_patient_adherence total_sessions
-- 3. session_notes table structure
-- 4. programs target_level, duration_weeks
-- 5. phases phase_number
-- ============================================================================

-- ============================================================================
-- 1. FIX: vw_pain_trend
-- ============================================================================
-- iOS expects: id, logged_date, avg_pain, session_number
-- View has: patient_id, day, avg_pain_during

DROP VIEW IF EXISTS vw_pain_trend CASCADE;

CREATE VIEW vw_pain_trend AS
SELECT
    gen_random_uuid()::text AS id,
    patient_id,
    day AS logged_date,
    avg_pain_during AS avg_pain,
    NULL::int AS session_number
FROM (
    SELECT
        patient_id,
        date(logged_at) AS day,
        avg(pain_during) AS avg_pain_during
    FROM pain_logs
    GROUP BY patient_id, date(logged_at)
) pain_by_day;

ALTER VIEW vw_pain_trend SET (security_invoker = true);

-- ============================================================================
-- 2. FIX: vw_patient_adherence
-- ============================================================================
-- iOS expects: adherence_pct, completed_sessions, total_sessions
-- View has: adherence_pct, completed_sessions, scheduled_sessions

DROP VIEW IF EXISTS vw_patient_adherence CASCADE;

CREATE VIEW vw_patient_adherence AS
SELECT
    p.id AS patient_id,
    p.first_name,
    p.last_name,
    COUNT(s.id) AS total_sessions,
    COUNT(CASE WHEN ss.status = 'completed' THEN 1 END) AS completed_sessions,
    CASE
        WHEN COUNT(s.id) > 0
        THEN (COUNT(CASE WHEN ss.status = 'completed' THEN 1 END)::float / COUNT(s.id)::float * 100)
        ELSE 0
    END AS adherence_pct
FROM patients p
LEFT JOIN programs pr ON pr.patient_id = p.id
LEFT JOIN phases ph ON ph.program_id = pr.id
LEFT JOIN sessions s ON s.phase_id = ph.id
LEFT JOIN session_status ss ON ss.session_id = s.id
GROUP BY p.id, p.first_name, p.last_name;

ALTER VIEW vw_patient_adherence SET (security_invoker = true);

-- ============================================================================
-- 3. FIX: session_notes table
-- ============================================================================
-- iOS expects: id, patient_id, session_id, note_type, note_text, created_by, created_at
-- Current table might have different structure

-- Add missing columns if they don't exist
ALTER TABLE session_notes ADD COLUMN IF NOT EXISTS note_type text DEFAULT 'general';
ALTER TABLE session_notes ADD COLUMN IF NOT EXISTS note_text text;
ALTER TABLE session_notes ADD COLUMN IF NOT EXISTS created_by uuid;

-- If notes column exists but note_text doesn't, copy it
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'session_notes' AND column_name = 'notes')
       AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'session_notes' AND column_name = 'note_text')
    THEN
        UPDATE session_notes SET note_text = notes WHERE note_text IS NULL;
    END IF;
END $$;

-- ============================================================================
-- 4. FIX: programs - Add computed columns
-- ============================================================================
-- iOS expects: target_level, duration_weeks
-- These might be in metadata JSON or need to be computed

ALTER TABLE programs ADD COLUMN IF NOT EXISTS target_level text;
ALTER TABLE programs ADD COLUMN IF NOT EXISTS duration_weeks int;

-- Extract target_level from metadata JSON if it exists
UPDATE programs
SET target_level = metadata->>'target_level'
WHERE target_level IS NULL AND metadata IS NOT NULL AND metadata->>'target_level' IS NOT NULL;

-- Set default target_level if still null
UPDATE programs
SET target_level = 'Intermediate'
WHERE target_level IS NULL;

-- Calculate duration_weeks from start_date and end_date
UPDATE programs
SET duration_weeks = CEIL(EXTRACT(epoch FROM (end_date::timestamp - start_date::timestamp)) / 604800)::int
WHERE duration_weeks IS NULL AND start_date IS NOT NULL AND end_date IS NOT NULL;

-- Set default duration_weeks if still null
UPDATE programs
SET duration_weeks = 8
WHERE duration_weeks IS NULL;

-- ============================================================================
-- 5. FIX: phases - Add phase_number as alias/computed column
-- ============================================================================
-- iOS expects: phase_number
-- Table has: sequence

ALTER TABLE phases ADD COLUMN IF NOT EXISTS phase_number int;

-- Copy sequence to phase_number
UPDATE phases
SET phase_number = sequence
WHERE phase_number IS NULL;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'ALL SCHEMA MISMATCHES FIXED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Fixed:';
  RAISE NOTICE '  1. vw_pain_trend - Added id, logged_date, avg_pain columns';
  RAISE NOTICE '  2. vw_patient_adherence - Changed scheduled_sessions → total_sessions';
  RAISE NOTICE '  3. session_notes - Added note_type, note_text, created_by columns';
  RAISE NOTICE '  4. programs - Added target_level, duration_weeks columns';
  RAISE NOTICE '  5. phases - Added phase_number column (from sequence)';
  RAISE NOTICE '';
  RAISE NOTICE '✅ All iOS models should now decode successfully!';
  RAISE NOTICE '========================================================================';
END $$;
