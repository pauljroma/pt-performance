-- RAG Exercise Library — Semantic search for exercise recommendations
-- Enables AI Quick Pick to find exercises by description, not just name
-- Migration: 20260220110000_exercise_embeddings.sql
-- Date: 2026-02-20

-- ============================================================================
-- 1. Enable pgvector extension
-- ============================================================================
CREATE EXTENSION IF NOT EXISTS vector;

-- ============================================================================
-- 2. Exercise embeddings table
-- Stores vector embeddings for semantic search over exercise library
-- ============================================================================
CREATE TABLE IF NOT EXISTS exercise_embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    exercise_template_id UUID REFERENCES exercise_templates(id) ON DELETE CASCADE,

    -- Searchable content (combined text used to generate embedding)
    content TEXT NOT NULL,

    -- Vector embedding (1536 dimensions for text-embedding-3-small)
    embedding vector(1536),

    -- Metadata for filtering
    muscle_groups TEXT[] DEFAULT '{}',
    equipment TEXT[] DEFAULT '{}',
    difficulty TEXT CHECK (difficulty IN ('beginner', 'intermediate', 'advanced')),
    contraindications TEXT[] DEFAULT '{}',  -- injuries/conditions where this exercise is NOT safe
    safe_for TEXT[] DEFAULT '{}',           -- injuries/conditions where this exercise IS safe
    movement_pattern TEXT,                  -- push, pull, hinge, squat, lunge, carry, rotation

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),

    -- One embedding per exercise template
    CONSTRAINT unique_exercise_embedding UNIQUE (exercise_template_id)
);

-- ============================================================================
-- 3. HNSW index for fast approximate nearest-neighbor search
-- m=16: max connections per node (higher = more accurate, more memory)
-- ef_construction=64: build-time search width (higher = better index, slower build)
-- ============================================================================
CREATE INDEX IF NOT EXISTS idx_exercise_embeddings_hnsw
    ON exercise_embeddings USING hnsw (embedding vector_cosine_ops)
    WITH (m = 16, ef_construction = 64);

-- Indexes for metadata filtering
CREATE INDEX IF NOT EXISTS idx_exercise_embeddings_muscle_groups
    ON exercise_embeddings USING GIN (muscle_groups);
CREATE INDEX IF NOT EXISTS idx_exercise_embeddings_equipment
    ON exercise_embeddings USING GIN (equipment);
CREATE INDEX IF NOT EXISTS idx_exercise_embeddings_safe_for
    ON exercise_embeddings USING GIN (safe_for);
CREATE INDEX IF NOT EXISTS idx_exercise_embeddings_movement_pattern
    ON exercise_embeddings (movement_pattern);
CREATE INDEX IF NOT EXISTS idx_exercise_embeddings_difficulty
    ON exercise_embeddings (difficulty);

-- ============================================================================
-- 4. Row Level Security
-- ============================================================================
ALTER TABLE exercise_embeddings ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read exercise embeddings (exercise library is shared)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'authenticated_read_embeddings' AND tablename = 'exercise_embeddings'
    ) THEN
        CREATE POLICY "authenticated_read_embeddings" ON exercise_embeddings
            FOR SELECT
            USING (auth.role() = 'authenticated' OR auth.role() = 'service_role');
    END IF;
END $$;

-- Only service role can write (edge functions populate embeddings via service_role key)
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE policyname = 'service_role_write_embeddings' AND tablename = 'exercise_embeddings'
    ) THEN
        CREATE POLICY "service_role_write_embeddings" ON exercise_embeddings
            FOR ALL
            USING (auth.role() = 'service_role');
    END IF;
END $$;

-- ============================================================================
-- 5. Updated_at trigger
-- ============================================================================
DROP TRIGGER IF EXISTS update_exercise_embeddings_updated_at ON exercise_embeddings;
CREATE TRIGGER update_exercise_embeddings_updated_at
    BEFORE UPDATE ON exercise_embeddings
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- ============================================================================
-- 6. Semantic search function
-- Called by the search-exercises edge function after embedding the query
-- ============================================================================
CREATE OR REPLACE FUNCTION search_exercises(
    query_embedding vector(1536),
    match_threshold float DEFAULT 0.7,
    match_count int DEFAULT 10,
    filter_muscle_groups text[] DEFAULT NULL,
    filter_equipment text[] DEFAULT NULL,
    filter_safe_for text[] DEFAULT NULL,
    filter_movement_pattern text DEFAULT NULL,
    filter_difficulty text DEFAULT NULL
)
RETURNS TABLE (
    exercise_template_id UUID,
    content TEXT,
    muscle_groups TEXT[],
    equipment TEXT[],
    difficulty TEXT,
    safe_for TEXT[],
    contraindications TEXT[],
    movement_pattern TEXT,
    similarity float
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ee.exercise_template_id,
        ee.content,
        ee.muscle_groups,
        ee.equipment,
        ee.difficulty,
        ee.safe_for,
        ee.contraindications,
        ee.movement_pattern,
        1 - (ee.embedding <=> query_embedding) AS similarity
    FROM exercise_embeddings ee
    WHERE
        -- Minimum similarity threshold
        1 - (ee.embedding <=> query_embedding) > match_threshold
        -- Optional: filter by muscle groups (overlap check)
        AND (filter_muscle_groups IS NULL OR ee.muscle_groups && filter_muscle_groups)
        -- Optional: filter by equipment (overlap check)
        AND (filter_equipment IS NULL OR ee.equipment && filter_equipment)
        -- Optional: filter by safe_for conditions (overlap check)
        AND (filter_safe_for IS NULL OR ee.safe_for && filter_safe_for)
        -- Optional: filter by movement pattern (exact match)
        AND (filter_movement_pattern IS NULL OR ee.movement_pattern = filter_movement_pattern)
        -- Optional: filter by difficulty (exact match)
        AND (filter_difficulty IS NULL OR ee.difficulty = filter_difficulty)
    ORDER BY ee.embedding <=> query_embedding
    LIMIT match_count;
END;
$$;

-- Grant execute to authenticated users (called via RPC from edge functions)
GRANT EXECUTE ON FUNCTION search_exercises TO authenticated;
GRANT EXECUTE ON FUNCTION search_exercises TO service_role;

-- ============================================================================
-- 7. Verification
-- ============================================================================
DO $$
BEGIN
    -- Verify extension
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'vector') THEN
        RAISE NOTICE 'SUCCESS: pgvector extension enabled';
    ELSE
        RAISE WARNING 'MISSING: pgvector extension';
    END IF;

    -- Verify table
    IF EXISTS (
        SELECT 1 FROM information_schema.tables
        WHERE table_name = 'exercise_embeddings'
    ) THEN
        RAISE NOTICE 'SUCCESS: exercise_embeddings table created';
    ELSE
        RAISE WARNING 'MISSING: exercise_embeddings table';
    END IF;

    -- Verify function
    IF EXISTS (
        SELECT 1 FROM pg_proc WHERE proname = 'search_exercises'
    ) THEN
        RAISE NOTICE 'SUCCESS: search_exercises function created';
    ELSE
        RAISE WARNING 'MISSING: search_exercises function';
    END IF;

    -- Verify HNSW index
    IF EXISTS (
        SELECT 1 FROM pg_indexes
        WHERE tablename = 'exercise_embeddings'
        AND indexname = 'idx_exercise_embeddings_hnsw'
    ) THEN
        RAISE NOTICE 'SUCCESS: HNSW index created';
    ELSE
        RAISE WARNING 'MISSING: HNSW index';
    END IF;
END $$;
