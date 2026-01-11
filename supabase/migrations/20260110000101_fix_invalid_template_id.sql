-- Fix invalid template_id foreign key violations
-- BUILD 143 passes non-existent template UUIDs, set them to NULL automatically

-- Create trigger function to nullify invalid template_id
CREATE OR REPLACE FUNCTION nullify_invalid_template_id()
RETURNS TRIGGER AS $$
BEGIN
    -- If template_id is provided but doesn't exist in interval_templates, set to NULL
    IF NEW.template_id IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM interval_templates WHERE id = NEW.template_id
        ) THEN
            RAISE NOTICE 'Template ID % not found, setting to NULL', NEW.template_id;
            NEW.template_id := NULL;
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on workout_timers
DROP TRIGGER IF EXISTS trg_nullify_invalid_template_id ON workout_timers;
CREATE TRIGGER trg_nullify_invalid_template_id
    BEFORE INSERT OR UPDATE ON workout_timers
    FOR EACH ROW
    EXECUTE FUNCTION nullify_invalid_template_id();

-- Comment
COMMENT ON FUNCTION nullify_invalid_template_id IS 'Automatically set template_id to NULL if it references non-existent template (BUILD 143 compatibility)';
