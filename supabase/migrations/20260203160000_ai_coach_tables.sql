-- ============================================================================
-- AI COACH TABLES MIGRATION
-- ============================================================================
-- Date: 2026-02-03
-- Description: Add AI Coach conversation tables for Health Intelligence Platform
-- Note: Other Health Intelligence tables (labs, recovery, fasting, supplements) already exist
-- ============================================================================

BEGIN;

-- ============================================================================
-- AI COACH TABLES
-- ============================================================================

-- AI Coach conversations table
CREATE TABLE IF NOT EXISTS ai_coach_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    title TEXT,
    conversation_type TEXT DEFAULT 'general_wellness',
    started_at TIMESTAMPTZ DEFAULT NOW(),
    last_message_at TIMESTAMPTZ DEFAULT NOW(),
    context_summary TEXT,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- AI Coach messages table
CREATE TABLE IF NOT EXISTS ai_coach_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    conversation_id UUID NOT NULL REFERENCES ai_coach_conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    insights JSONB,
    suggested_questions TEXT[],
    tokens_used INTEGER,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- INDEXES
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_ai_coach_conversations_patient
    ON ai_coach_conversations(patient_id);
CREATE INDEX IF NOT EXISTS idx_ai_coach_conversations_active
    ON ai_coach_conversations(patient_id, is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_ai_coach_messages_conversation
    ON ai_coach_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_ai_coach_messages_created
    ON ai_coach_messages(conversation_id, created_at DESC);

-- ============================================================================
-- RLS POLICIES
-- ============================================================================

ALTER TABLE ai_coach_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_coach_messages ENABLE ROW LEVEL SECURITY;

-- Patients can only access their own conversations
DROP POLICY IF EXISTS "Users can view own conversations" ON ai_coach_conversations;
CREATE POLICY "Users can view own conversations" ON ai_coach_conversations
    FOR SELECT USING (patient_id = auth.uid());

DROP POLICY IF EXISTS "Users can create own conversations" ON ai_coach_conversations;
CREATE POLICY "Users can create own conversations" ON ai_coach_conversations
    FOR INSERT WITH CHECK (patient_id = auth.uid());

DROP POLICY IF EXISTS "Users can update own conversations" ON ai_coach_conversations;
CREATE POLICY "Users can update own conversations" ON ai_coach_conversations
    FOR UPDATE USING (patient_id = auth.uid());

-- Messages: access through conversation ownership
DROP POLICY IF EXISTS "Users can view messages in own conversations" ON ai_coach_messages;
CREATE POLICY "Users can view messages in own conversations" ON ai_coach_messages
    FOR SELECT USING (
        conversation_id IN (
            SELECT id FROM ai_coach_conversations WHERE patient_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Users can create messages in own conversations" ON ai_coach_messages;
CREATE POLICY "Users can create messages in own conversations" ON ai_coach_messages
    FOR INSERT WITH CHECK (
        conversation_id IN (
            SELECT id FROM ai_coach_conversations WHERE patient_id = auth.uid()
        )
    );

-- Service role bypass for edge functions
DROP POLICY IF EXISTS "Service role full access conversations" ON ai_coach_conversations;
CREATE POLICY "Service role full access conversations" ON ai_coach_conversations
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

DROP POLICY IF EXISTS "Service role full access messages" ON ai_coach_messages;
CREATE POLICY "Service role full access messages" ON ai_coach_messages
    FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- ============================================================================
-- TRIGGERS
-- ============================================================================

-- Update conversation's last_message_at when new message added
CREATE OR REPLACE FUNCTION update_conversation_last_message()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ai_coach_conversations
    SET last_message_at = NOW(), updated_at = NOW()
    WHERE id = NEW.conversation_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_conversation_last_message ON ai_coach_messages;
CREATE TRIGGER trigger_update_conversation_last_message
    AFTER INSERT ON ai_coach_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_conversation_last_message();

COMMIT;
