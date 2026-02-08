-- Migration: Add injury_type and target_level columns to patients table
-- These columns are needed for therapist patient creation flow

-- Add injury_type column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients' AND column_name = 'injury_type'
    ) THEN
        ALTER TABLE patients ADD COLUMN injury_type TEXT;
        COMMENT ON COLUMN patients.injury_type IS 'Type of injury being treated, e.g., "UCL Reconstruction", "ACL Tear"';
        RAISE NOTICE '✅ Added injury_type column to patients table';
    ELSE
        RAISE NOTICE 'injury_type column already exists';
    END IF;
END $$;

-- Add target_level column
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_name = 'patients' AND column_name = 'target_level'
    ) THEN
        ALTER TABLE patients ADD COLUMN target_level TEXT DEFAULT 'Recreational';
        COMMENT ON COLUMN patients.target_level IS 'Target athletic level: Recreational, Competitive, Professional';
        RAISE NOTICE '✅ Added target_level column to patients table';
    ELSE
        RAISE NOTICE 'target_level column already exists';
    END IF;
END $$;

-- Add index for injury_type lookups (useful for RTS module queries)
CREATE INDEX IF NOT EXISTS idx_patients_injury_type
    ON patients(injury_type)
    WHERE injury_type IS NOT NULL;

-- Verify columns were added
SELECT
    column_name,
    data_type,
    column_default,
    is_nullable
FROM information_schema.columns
WHERE table_name = 'patients'
AND column_name IN ('injury_type', 'target_level');
