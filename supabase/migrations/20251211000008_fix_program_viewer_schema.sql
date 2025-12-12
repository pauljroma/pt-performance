-- ============================================================================
-- FIX Program Viewer Schema Mismatches
-- ============================================================================
-- iOS ProgramViewModel expects:
--   1. sessions.session_number (table has: sequence)
--   2. exercise_templates.exercise_name (table has: name)
-- ============================================================================

-- 1. Add session_number as alias for sequence
ALTER TABLE sessions ADD COLUMN IF NOT EXISTS session_number int;

-- Sync session_number with sequence
UPDATE sessions SET session_number = sequence WHERE session_number IS NULL;

-- Create trigger to keep them in sync
CREATE OR REPLACE FUNCTION sync_session_number()
RETURNS TRIGGER AS $$
BEGIN
  -- When sequence is set, copy to session_number
  IF NEW.sequence IS NOT NULL THEN
    NEW.session_number = NEW.sequence;
  -- When session_number is set, copy to sequence
  ELSIF NEW.session_number IS NOT NULL THEN
    NEW.sequence = NEW.session_number;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_session_number_trigger ON sessions;
CREATE TRIGGER sync_session_number_trigger
  BEFORE INSERT OR UPDATE ON sessions
  FOR EACH ROW
  EXECUTE FUNCTION sync_session_number();

-- ============================================================================
-- 2. Add exercise_name as alias for name
-- ============================================================================

ALTER TABLE exercise_templates ADD COLUMN IF NOT EXISTS exercise_name text;

-- Sync exercise_name with name
UPDATE exercise_templates SET exercise_name = name WHERE exercise_name IS NULL;

-- Create trigger to keep them in sync
CREATE OR REPLACE FUNCTION sync_exercise_name()
RETURNS TRIGGER AS $$
BEGIN
  -- When name is set, copy to exercise_name
  IF NEW.name IS NOT NULL THEN
    NEW.exercise_name = NEW.name;
  -- When exercise_name is set, copy to name
  ELSIF NEW.exercise_name IS NOT NULL THEN
    NEW.name = NEW.exercise_name;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS sync_exercise_name_trigger ON exercise_templates;
CREATE TRIGGER sync_exercise_name_trigger
  BEFORE INSERT OR UPDATE ON exercise_templates
  FOR EACH ROW
  EXECUTE FUNCTION sync_exercise_name();

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
DECLARE
  session_count int;
  exercise_count int;
BEGIN
  SELECT COUNT(*) INTO session_count FROM sessions WHERE session_number IS NOT NULL;
  SELECT COUNT(*) INTO exercise_count FROM exercise_templates WHERE exercise_name IS NOT NULL;

  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'PROGRAM VIEWER SCHEMA FIXED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Fixed:';
  RAISE NOTICE '  1. sessions.session_number added (% rows synced)', session_count;
  RAISE NOTICE '  2. exercise_templates.exercise_name added (% rows synced)', exercise_count;
  RAISE NOTICE '';
  RAISE NOTICE 'Triggers created to keep columns in sync automatically.';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Program viewer should now work!';
  RAISE NOTICE '========================================================================';
END $$;
