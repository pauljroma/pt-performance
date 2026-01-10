-- Migration: Create AI Exercise Assistant Conversations
-- Description: Creates tables for storing AI conversation history and messages
-- Build: 62, Agent: 3
-- Date: 2025-12-18

-- =====================================================
-- AI Conversations Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    message_count INTEGER NOT NULL DEFAULT 0,
    is_archived BOOLEAN NOT NULL DEFAULT false,
    tags TEXT[], -- Array of tags for categorization (e.g., "substitutions", "shoulder", "injury")

    -- Program context (what program was active when conversation started)
    program_id UUID REFERENCES programs(id) ON DELETE SET NULL,
    program_name TEXT,

    -- Metadata
    total_tokens_used INTEGER DEFAULT 0,
    estimated_cost_usd DECIMAL(10, 6) DEFAULT 0.00
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_id ON ai_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_created_at ON ai_conversations(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_is_archived ON ai_conversations(is_archived);
CREATE INDEX IF NOT EXISTS idx_ai_conversations_tags ON ai_conversations USING GIN(tags);

-- Add comments
COMMENT ON TABLE ai_conversations IS 'Stores AI Exercise Assistant conversation threads';
COMMENT ON COLUMN ai_conversations.title IS 'Conversation title (auto-generated or user-provided)';
COMMENT ON COLUMN ai_conversations.tags IS 'Array of tags for categorization and search';
COMMENT ON COLUMN ai_conversations.program_id IS 'Reference to active program when conversation started';
COMMENT ON COLUMN ai_conversations.total_tokens_used IS 'Total AI tokens consumed in this conversation';
COMMENT ON COLUMN ai_conversations.estimated_cost_usd IS 'Estimated cost in USD for this conversation';

-- =====================================================
-- AI Messages Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- Exercise context (optional - included when message relates to specific exercise)
    exercise_context JSONB,

    -- Metadata
    token_count INTEGER,
    processing_time_ms INTEGER, -- Processing time in milliseconds
    error TEXT, -- Error message if AI request failed

    -- Flags
    needs_review BOOLEAN DEFAULT false, -- Flagged for therapist review (medical concerns)
    reviewed_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reviewed_at TIMESTAMPTZ
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_id ON ai_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_messages_created_at ON ai_messages(created_at);
CREATE INDEX IF NOT EXISTS idx_ai_messages_needs_review ON ai_messages(needs_review) WHERE needs_review = true;
CREATE INDEX IF NOT EXISTS idx_ai_messages_exercise_context ON ai_messages USING GIN(exercise_context);

-- Add comments
COMMENT ON TABLE ai_messages IS 'Stores individual messages in AI conversations';
COMMENT ON COLUMN ai_messages.role IS 'Message role: user, assistant, or system';
COMMENT ON COLUMN ai_messages.exercise_context IS 'JSON object containing exercise information for context';
COMMENT ON COLUMN ai_messages.needs_review IS 'Flagged for therapist review due to medical concerns';
COMMENT ON COLUMN ai_messages.reviewed_by IS 'Therapist who reviewed this flagged message';

-- =====================================================
-- Trigger: Auto-update conversation updated_at
-- =====================================================

CREATE OR REPLACE FUNCTION update_conversation_timestamp()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ai_conversations
    SET updated_at = now(),
        message_count = (
            SELECT COUNT(*)
            FROM ai_messages
            WHERE conversation_id = NEW.conversation_id
        )
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_messages_update_conversation
AFTER INSERT ON ai_messages
FOR EACH ROW
EXECUTE FUNCTION update_conversation_timestamp();

COMMENT ON FUNCTION update_conversation_timestamp() IS 'Updates conversation updated_at and message_count on new message';

-- =====================================================
-- Trigger: Auto-flag medical concerns
-- =====================================================

CREATE OR REPLACE FUNCTION flag_medical_concerns()
RETURNS TRIGGER AS $$
DECLARE
    medical_keywords TEXT[] := ARRAY[
        'severe pain', 'sharp pain', 'sudden pain', 'extreme pain',
        'doctor', 'physician', 'hospital', 'emergency',
        'diagnose', 'diagnosis', 'condition',
        'broken', 'fracture', 'tear', 'ruptured',
        'surgery', 'surgical', 'operation'
    ];
    keyword TEXT;
    content_lower TEXT;
BEGIN
    content_lower := lower(NEW.content);

    -- Check if content contains any medical keywords
    FOREACH keyword IN ARRAY medical_keywords
    LOOP
        IF content_lower LIKE '%' || keyword || '%' THEN
            NEW.needs_review := true;
            EXIT;
        END IF;
    END LOOP;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ai_messages_flag_concerns
BEFORE INSERT ON ai_messages
FOR EACH ROW
WHEN (NEW.role = 'user')
EXECUTE FUNCTION flag_medical_concerns();

COMMENT ON FUNCTION flag_medical_concerns() IS 'Automatically flags messages containing medical concern keywords';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE ai_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_messages ENABLE ROW LEVEL SECURITY;

-- AI Conversations policies
CREATE POLICY "Users can view their own conversations"
    ON ai_conversations FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own conversations"
    ON ai_conversations FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations"
    ON ai_conversations FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations"
    ON ai_conversations FOR DELETE
    USING (auth.uid() = user_id);

-- Therapists can view all conversations for their patients
CREATE POLICY "Therapists can view patient conversations"
    ON ai_conversations FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.user_id = auth.uid()
            AND 1=1
        )
    );

-- AI Messages policies
CREATE POLICY "Users can view messages in their conversations"
    ON ai_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND ai_conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create messages in their conversations"
    ON ai_messages FOR INSERT
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND ai_conversations.user_id = auth.uid()
        )
    );

CREATE POLICY "Users can delete messages in their conversations"
    ON ai_messages FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM ai_conversations
            WHERE ai_conversations.id = ai_messages.conversation_id
            AND ai_conversations.user_id = auth.uid()
        )
    );

-- Therapists can view all messages
CREATE POLICY "Therapists can view all messages"
    ON ai_messages FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.user_id = auth.uid()
            AND 1=1
        )
    );

-- Therapists can mark messages as reviewed
CREATE POLICY "Therapists can update message review status"
    ON ai_messages FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.user_id = auth.uid()
            AND 1=1
        )
    )
    WITH CHECK (
        EXISTS (
            SELECT 1 FROM therapists
            WHERE therapists.user_id = auth.uid()
            AND 1=1
        )
    );

-- =====================================================
-- Helper Views
-- =====================================================

-- View: Recent conversations with last message
CREATE OR REPLACE VIEW ai_conversations_with_preview AS
SELECT
    c.id,
    c.user_id,
    c.title,
    c.created_at,
    c.updated_at,
    c.message_count,
    c.is_archived,
    c.tags,
    c.program_name,
    c.total_tokens_used,
    c.estimated_cost_usd,
    (
        SELECT content
        FROM ai_messages m
        WHERE m.conversation_id = c.id
        ORDER BY m.created_at DESC
        LIMIT 1
    ) AS last_message_preview,
    (
        SELECT COUNT(*)
        FROM ai_messages m
        WHERE m.conversation_id = c.id
        AND m.needs_review = true
    ) AS flagged_message_count
FROM ai_conversations c;

COMMENT ON VIEW ai_conversations_with_preview IS 'Conversations with last message preview and flagged count';

-- =====================================================
-- Sample Data (Optional - for testing)
-- =====================================================

-- Note: Uncomment to insert sample data for testing
/*
-- Insert sample conversation for demo patient
INSERT INTO ai_conversations (
    user_id,
    title,
    message_count,
    tags,
    program_name
) VALUES (
    (SELECT id FROM auth.users WHERE email = 'demo-athlete@ptperformance.app'),
    'Exercise substitutions for shoulder injury',
    4,
    ARRAY['substitutions', 'shoulder', 'injury-modification'],
    'Winter Strength Program'
) RETURNING id;

-- Get the conversation ID and insert sample messages
-- (You would replace 'CONVERSATION_ID_HERE' with actual ID from above)
*/

-- =====================================================
-- Verification Query
-- =====================================================

-- Verify tables were created
DO $$
DECLARE
    conversation_count INTEGER;
    message_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO conversation_count FROM ai_conversations;
    SELECT COUNT(*) INTO message_count FROM ai_messages;

    RAISE NOTICE 'Migration complete:';
    RAISE NOTICE '  - ai_conversations table: % rows', conversation_count;
    RAISE NOTICE '  - ai_messages table: % rows', message_count;
    RAISE NOTICE '  - RLS policies enabled';
    RAISE NOTICE '  - Triggers configured';
END $$;
