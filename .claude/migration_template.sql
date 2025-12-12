-- Migration: [Brief description of what this migration does]
-- Build: [Build number - e.g., 33]
-- Date: [YYYY-MM-DD]
-- Purpose: [Detailed explanation of why this change is needed]

-- ============================================================================
-- Table Creation
-- ============================================================================

CREATE TABLE IF NOT EXISTS [table_name] (
    -- Primary key
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

    -- Foreign keys
    [foreign_key]_id UUID NOT NULL REFERENCES [other_table](id) ON DELETE CASCADE,

    -- Data columns
    [column_name] TEXT NOT NULL,
    [another_column] INT,
    [optional_column] NUMERIC(10,2),

    -- Audit columns
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ============================================================================
-- Indexes
-- ============================================================================

-- Primary foreign key index
CREATE INDEX IF NOT EXISTS idx_[table]_[foreign_key]
    ON [table_name]([foreign_key]_id);

-- Commonly queried columns
CREATE INDEX IF NOT EXISTS idx_[table]_[column]
    ON [table_name]([column_name]);

-- Composite index for common query patterns
CREATE INDEX IF NOT EXISTS idx_[table]_[col1]_[col2]
    ON [table_name]([column1], [column2]);

-- Timestamp index for sorting/filtering
CREATE INDEX IF NOT EXISTS idx_[table]_created_at
    ON [table_name](created_at DESC);

-- ============================================================================
-- Row-Level Security (RLS)
-- ============================================================================

ALTER TABLE [table_name] ENABLE ROW LEVEL SECURITY;

-- Policy: Users can view their own records
CREATE POLICY "[table]_select_own" ON [table_name]
    FOR SELECT
    USING (user_id = auth.uid());

-- Policy: Users can insert their own records
CREATE POLICY "[table]_insert_own" ON [table_name]
    FOR INSERT
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can update their own records
CREATE POLICY "[table]_update_own" ON [table_name]
    FOR UPDATE
    USING (user_id = auth.uid())
    WITH CHECK (user_id = auth.uid());

-- Policy: Users can delete their own records
CREATE POLICY "[table]_delete_own" ON [table_name]
    FOR DELETE
    USING (user_id = auth.uid());

-- Policy: Therapists can view records for their patients
CREATE POLICY "[table]_select_therapist" ON [table_name]
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM patients p
            WHERE p.id = [table_name].patient_id
            AND p.therapist_id = (
                SELECT id FROM therapists WHERE user_id = auth.uid()
            )
        )
    );

-- ============================================================================
-- Grants
-- ============================================================================

-- Grant access to authenticated users
GRANT SELECT, INSERT, UPDATE, DELETE ON [table_name] TO authenticated;

-- Grant read-only access to anonymous users (if needed for demos)
GRANT SELECT ON [table_name] TO anon;

-- ============================================================================
-- Comments
-- ============================================================================

COMMENT ON TABLE [table_name] IS '[Description of table purpose and usage]';
COMMENT ON COLUMN [table_name].[column_name] IS '[Description of what this column stores]';

-- ============================================================================
-- Example Usage
-- ============================================================================

/*
-- Insert example
INSERT INTO [table_name] (
    [foreign_key]_id,
    [column_name],
    [another_column]
) VALUES (
    '[UUID]',
    'Sample value',
    42
);

-- Query example
SELECT * FROM [table_name]
WHERE user_id = auth.uid()
ORDER BY created_at DESC;
*/

-- ============================================================================
-- Rollback
-- ============================================================================

/*
-- To rollback this migration, run:
DROP TABLE IF EXISTS [table_name] CASCADE;
*/
