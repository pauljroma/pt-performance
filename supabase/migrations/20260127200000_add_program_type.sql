-- Build 294: Add program_type column to programs and program_library
-- Supports 3 program types: rehab, performance, lifestyle
-- Backward-compatible: existing programs default to 'rehab'

-- Add program_type to programs table
ALTER TABLE programs
ADD COLUMN IF NOT EXISTS program_type TEXT NOT NULL DEFAULT 'rehab';

-- Add CHECK constraint separately (IF NOT EXISTS not supported for constraints)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'programs_program_type_check'
    ) THEN
        ALTER TABLE programs
        ADD CONSTRAINT programs_program_type_check
        CHECK (program_type IN ('rehab', 'performance', 'lifestyle'));
    END IF;
END $$;

-- Add program_type to program_library table
ALTER TABLE program_library
ADD COLUMN IF NOT EXISTS program_type TEXT NOT NULL DEFAULT 'lifestyle';

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'program_library_program_type_check'
    ) THEN
        ALTER TABLE program_library
        ADD CONSTRAINT program_library_program_type_check
        CHECK (program_type IN ('rehab', 'performance', 'lifestyle'));
    END IF;
END $$;

-- Indexes for filtering
CREATE INDEX IF NOT EXISTS idx_programs_program_type ON programs(program_type);
CREATE INDEX IF NOT EXISTS idx_program_library_program_type ON program_library(program_type);
