-- Add gender field to patients table for patient profile
-- BUILD 96 - Patient Profile Feature
-- Date: 2025-12-28

-- ============================================================================
-- ADD GENDER FIELD
-- ============================================================================

-- Add gender column (optional, defaults to null for existing records)
ALTER TABLE patients
ADD COLUMN IF NOT EXISTS gender TEXT
CHECK (gender IN ('Male', 'Female', 'Other', 'Prefer not to say'));

-- Add comment for documentation
COMMENT ON COLUMN patients.gender IS 'Patient gender - optional field for demographic information';

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Verify column was added
DO $$
DECLARE
  column_exists BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM information_schema.columns
    WHERE table_schema = 'public'
      AND table_name = 'patients'
      AND column_name = 'gender'
  ) INTO column_exists;

  IF column_exists THEN
    RAISE NOTICE '✅ gender column added successfully to patients table';
  ELSE
    RAISE EXCEPTION '❌ Failed to add gender column';
  END IF;
END $$;
