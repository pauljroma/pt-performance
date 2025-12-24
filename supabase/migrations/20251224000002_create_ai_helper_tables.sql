-- Migration: Create AI Helper tables
-- Build: 77
-- Date: 2025-12-24
-- Description: Foundation for AI-Driven Program Intelligence (MVP)

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- Table: ai_chat_sessions
-- Purpose: Track AI chat conversations with patients
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    ended_at TIMESTAMPTZ,
    message_count INTEGER DEFAULT 0,
    total_tokens_used INTEGER DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),

    -- Index for fast athlete lookup
    CONSTRAINT ai_chat_sessions_athlete_idx UNIQUE (athlete_id, started_at)
);

CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_athlete
    ON ai_chat_sessions(athlete_id, started_at DESC);

-- ============================================================
-- Table: ai_chat_messages
-- Purpose: Store individual chat messages
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    session_id UUID NOT NULL REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tokens_used INTEGER DEFAULT 0,
    model TEXT,  -- e.g., 'gpt-4-turbo-preview'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_session
    ON ai_chat_messages(session_id, created_at ASC);

-- ============================================================
-- Table: ai_exercise_substitutions
-- Purpose: Track AI-suggested exercise alternatives
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_exercise_substitutions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    original_exercise_id UUID NOT NULL REFERENCES exercises(id),
    suggested_exercise_id UUID NOT NULL REFERENCES exercises(id),
    reason TEXT NOT NULL,  -- "No barbell available", "Shoulder injury contraindication"
    ai_confidence DECIMAL(5,2) CHECK (ai_confidence >= 0 AND ai_confidence <= 100),
    accepted BOOLEAN DEFAULT NULL,  -- NULL = pending, TRUE = accepted, FALSE = rejected
    accepted_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_substitutions_athlete
    ON ai_exercise_substitutions(athlete_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_ai_substitutions_pending
    ON ai_exercise_substitutions(athlete_id)
    WHERE accepted IS NULL;

-- ============================================================
-- Table: ai_safety_checks
-- Purpose: Store AI-detected contraindications and warnings
-- ============================================================

CREATE TABLE IF NOT EXISTS ai_safety_checks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    athlete_id UUID NOT NULL REFERENCES athletes(id) ON DELETE CASCADE,
    exercise_id UUID REFERENCES exercises(id),
    warning_level TEXT NOT NULL CHECK (warning_level IN ('info', 'caution', 'warning', 'danger')),
    reason TEXT NOT NULL,
    ai_analysis JSONB,  -- Full AI response with reasoning
    dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ai_safety_athlete_active
    ON ai_safety_checks(athlete_id, created_at DESC)
    WHERE dismissed = FALSE;

CREATE INDEX IF NOT EXISTS idx_ai_safety_level
    ON ai_safety_checks(warning_level)
    WHERE dismissed = FALSE AND warning_level IN ('warning', 'danger');

-- ============================================================
-- Row Level Security (RLS) Policies
-- ============================================================

ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_exercise_substitutions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_safety_checks ENABLE ROW LEVEL SECURITY;

-- ai_chat_sessions policies
CREATE POLICY "Athletes can view their own chat sessions"
    ON ai_chat_sessions FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "System can create chat sessions"
    ON ai_chat_sessions FOR INSERT
    WITH CHECK (true);

CREATE POLICY "System can update chat sessions"
    ON ai_chat_sessions FOR UPDATE
    USING (true);

-- ai_chat_messages policies
CREATE POLICY "Athletes can view their own chat messages"
    ON ai_chat_messages FOR SELECT
    USING (session_id IN (
        SELECT id FROM ai_chat_sessions WHERE athlete_id = auth.uid()
    ));

CREATE POLICY "System can insert chat messages"
    ON ai_chat_messages FOR INSERT
    WITH CHECK (true);

-- ai_exercise_substitutions policies
CREATE POLICY "Athletes can view their own substitutions"
    ON ai_exercise_substitutions FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "Athletes can accept/reject substitutions"
    ON ai_exercise_substitutions FOR UPDATE
    USING (athlete_id = auth.uid());

CREATE POLICY "System can create substitutions"
    ON ai_exercise_substitutions FOR INSERT
    WITH CHECK (true);

-- ai_safety_checks policies
CREATE POLICY "Athletes can view their own safety checks"
    ON ai_safety_checks FOR SELECT
    USING (athlete_id = auth.uid());

CREATE POLICY "Athletes can dismiss safety warnings"
    ON ai_safety_checks FOR UPDATE
    USING (athlete_id = auth.uid());

CREATE POLICY "System can create safety checks"
    ON ai_safety_checks FOR INSERT
    WITH CHECK (true);

-- ============================================================
-- Triggers
-- ============================================================

-- Update session message count when messages are added
CREATE OR REPLACE FUNCTION update_session_message_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ai_chat_sessions
    SET message_count = message_count + 1,
        total_tokens_used = total_tokens_used + COALESCE(NEW.tokens_used, 0)
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_session_count
    AFTER INSERT ON ai_chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_session_message_count();

-- ============================================================
-- Comments
-- ============================================================

COMMENT ON TABLE ai_chat_sessions IS 'AI chat conversations between patients and AI assistant';
COMMENT ON TABLE ai_chat_messages IS 'Individual messages in AI chat sessions';
COMMENT ON TABLE ai_exercise_substitutions IS 'AI-suggested exercise alternatives based on equipment/injuries';
COMMENT ON TABLE ai_safety_checks IS 'AI-detected contraindications and safety warnings';

COMMENT ON COLUMN ai_exercise_substitutions.reason IS 'Human-readable reason for substitution (e.g., "No barbell available")';
COMMENT ON COLUMN ai_exercise_substitutions.ai_confidence IS 'AI confidence score 0-100 for this substitution';
COMMENT ON COLUMN ai_safety_checks.warning_level IS 'Severity: info (FYI), caution (careful), warning (risky), danger (stop)';
COMMENT ON COLUMN ai_safety_checks.ai_analysis IS 'Full JSON response from Claude with detailed reasoning';
