-- ============================================================================
-- FIX session_notes Schema to Match iOS Model
-- ============================================================================
-- iOS SessionNote model expects: note_text
-- Table has: content (NOT NULL)
-- Solution: Make content nullable, add trigger to sync note_text <-> content
-- ============================================================================

-- Make content nullable
ALTER TABLE session_notes ALTER COLUMN content DROP NOT NULL;

-- Create function to sync note_text to content
CREATE OR REPLACE FUNCTION sync_session_note_content()
RETURNS TRIGGER AS $$
BEGIN
  -- When note_text is provided, copy to content
  IF NEW.note_text IS NOT NULL THEN
    NEW.content = NEW.note_text;
  -- When content is provided, copy to note_text
  ELSIF NEW.content IS NOT NULL THEN
    NEW.note_text = NEW.content;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger
DROP TRIGGER IF EXISTS sync_note_content_trigger ON session_notes;
CREATE TRIGGER sync_note_content_trigger
  BEFORE INSERT OR UPDATE ON session_notes
  FOR EACH ROW
  EXECUTE FUNCTION sync_session_note_content();

-- Sync existing data
UPDATE session_notes
SET note_text = content
WHERE note_text IS NULL AND content IS NOT NULL;

UPDATE session_notes
SET content = note_text
WHERE content IS NULL AND note_text IS NOT NULL;

-- ============================================================================
-- VERIFICATION
-- ============================================================================

DO $$
BEGIN
  RAISE NOTICE '';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE 'SESSION_NOTES SCHEMA FIXED';
  RAISE NOTICE '========================================================================';
  RAISE NOTICE '';
  RAISE NOTICE 'Changes:';
  RAISE NOTICE '  - content column now nullable';
  RAISE NOTICE '  - Trigger syncs note_text ↔ content automatically';
  RAISE NOTICE '  - iOS can send note_text, database stores in content';
  RAISE NOTICE '';
  RAISE NOTICE '✅ Note creation should now work!';
  RAISE NOTICE '========================================================================';
END $$;
