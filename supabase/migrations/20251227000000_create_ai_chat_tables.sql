-- Migration: Create AI Chat Tables for Build 88
-- Description: Creates ai_chat_sessions and ai_chat_messages tables for AI Assistant
-- Build: 88, Agent: 6 - Phase 2
-- Date: 2025-12-27

-- =====================================================
-- AI Chat Sessions Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL,
    started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    message_count INTEGER NOT NULL DEFAULT 0,
    total_tokens INTEGER DEFAULT 0,

    CONSTRAINT fk_athlete_id FOREIGN KEY (athlete_id)
        REFERENCES patients(id) ON DELETE CASCADE
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_athlete_id ON ai_chat_sessions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_started_at ON ai_chat_sessions(started_at DESC);

-- Add comments
COMMENT ON TABLE ai_chat_sessions IS 'AI chat sessions for PT Performance AI Assistant';
COMMENT ON COLUMN ai_chat_sessions.athlete_id IS 'Patient ID (references patients table)';
COMMENT ON COLUMN ai_chat_sessions.message_count IS 'Total number of messages in this session';
COMMENT ON COLUMN ai_chat_sessions.total_tokens IS 'Total tokens used in this session';

-- =====================================================
-- AI Chat Messages Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    tokens_used INTEGER,
    model TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_session_id FOREIGN KEY (session_id)
        REFERENCES ai_chat_sessions(id) ON DELETE CASCADE
);

-- Add indexes for performance
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_session_id ON ai_chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_created_at ON ai_chat_messages(created_at);

-- Add comments
COMMENT ON TABLE ai_chat_messages IS 'Individual messages in AI chat sessions';
COMMENT ON COLUMN ai_chat_messages.role IS 'Message role: user, assistant, or system';
COMMENT ON COLUMN ai_chat_messages.tokens_used IS 'Number of tokens used for this message';
COMMENT ON COLUMN ai_chat_messages.model IS 'AI model used (e.g., gpt-4-turbo-preview)';

-- =====================================================
-- Trigger: Auto-update session on new message
-- =====================================================

CREATE OR REPLACE FUNCTION trigger_update_session_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE ai_chat_sessions
    SET
        updated_at = now(),
        message_count = (
            SELECT COUNT(*)
            FROM ai_chat_messages
            WHERE session_id = NEW.session_id
        ),
        total_tokens = COALESCE((
            SELECT SUM(tokens_used)
            FROM ai_chat_messages
            WHERE session_id = NEW.session_id
        ), 0)
    WHERE id = NEW.session_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_session_on_message
AFTER INSERT ON ai_chat_messages
FOR EACH ROW
EXECUTE FUNCTION trigger_update_session_count();

COMMENT ON FUNCTION trigger_update_session_count() IS 'Updates session stats when new message is added';

-- =====================================================
-- AI Safety Checks Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_safety_checks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL,
    exercise_id UUID,
    warning_level TEXT NOT NULL CHECK (warning_level IN ('info', 'caution', 'warning', 'danger')),
    reason TEXT NOT NULL,
    ai_analysis JSONB,
    dismissed BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_safety_athlete_id FOREIGN KEY (athlete_id)
        REFERENCES patients(id) ON DELETE CASCADE
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_ai_safety_checks_athlete_id ON ai_safety_checks(athlete_id);
CREATE INDEX IF NOT EXISTS idx_ai_safety_checks_dismissed ON ai_safety_checks(dismissed) WHERE dismissed = false;

-- Add comments
COMMENT ON TABLE ai_safety_checks IS 'AI-detected safety warnings for exercises';
COMMENT ON COLUMN ai_safety_checks.warning_level IS 'Severity: info, caution, warning, danger';
COMMENT ON COLUMN ai_safety_checks.ai_analysis IS 'Full AI safety analysis as JSON';

-- =====================================================
-- AI Exercise Substitutions Table
-- =====================================================

CREATE TABLE IF NOT EXISTS ai_exercise_substitutions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    athlete_id UUID NOT NULL,
    original_exercise_id UUID,
    suggested_exercise_id UUID,
    reason TEXT NOT NULL,
    confidence_score INTEGER CHECK (confidence_score >= 0 AND confidence_score <= 100),
    rationale TEXT,
    accepted BOOLEAN DEFAULT false,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT fk_substitution_athlete_id FOREIGN KEY (athlete_id)
        REFERENCES patients(id) ON DELETE CASCADE
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_ai_substitutions_athlete_id ON ai_exercise_substitutions(athlete_id);
CREATE INDEX IF NOT EXISTS idx_ai_substitutions_accepted ON ai_exercise_substitutions(accepted);

-- Add comments
COMMENT ON TABLE ai_exercise_substitutions IS 'AI-suggested exercise substitutions';
COMMENT ON COLUMN ai_exercise_substitutions.confidence_score IS 'AI confidence in substitution (0-100)';
COMMENT ON COLUMN ai_exercise_substitutions.accepted IS 'Whether patient accepted the substitution';

-- =====================================================
-- Row-Level Security (RLS)
-- =====================================================

-- Enable RLS
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_safety_checks ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_exercise_substitutions ENABLE ROW LEVEL SECURITY;

-- Sessions: Patients can only see their own
CREATE POLICY "Patients can view their own chat sessions"
    ON ai_chat_sessions FOR SELECT
    USING (
        athlete_id IN (
            SELECT id FROM patients WHERE id = athlete_id
        )
    );

CREATE POLICY "Patients can create their own chat sessions"
    ON ai_chat_sessions FOR INSERT
    WITH CHECK (
        athlete_id IN (
            SELECT id FROM patients WHERE id = athlete_id
        )
    );

-- Messages: Patients can only see messages from their sessions
CREATE POLICY "Patients can view messages from their sessions"
    ON ai_chat_messages FOR SELECT
    USING (
        session_id IN (
            SELECT id FROM ai_chat_sessions WHERE athlete_id IN (
                SELECT id FROM patients WHERE id = ai_chat_sessions.athlete_id
            )
        )
    );

CREATE POLICY "Patients can create messages in their sessions"
    ON ai_chat_messages FOR INSERT
    WITH CHECK (
        session_id IN (
            SELECT id FROM ai_chat_sessions WHERE athlete_id IN (
                SELECT id FROM patients WHERE id = ai_chat_sessions.athlete_id
            )
        )
    );

-- Safety checks: Patients can view their own
CREATE POLICY "Patients can view their own safety checks"
    ON ai_safety_checks FOR SELECT
    USING (
        athlete_id IN (
            SELECT id FROM patients WHERE id = athlete_id
        )
    );

CREATE POLICY "Patients can dismiss their own safety checks"
    ON ai_safety_checks FOR UPDATE
    USING (
        athlete_id IN (
            SELECT id FROM patients WHERE id = athlete_id
        )
    );

-- Substitutions: Patients can view their own
CREATE POLICY "Patients can view their own substitutions"
    ON ai_exercise_substitutions FOR SELECT
    USING (
        athlete_id IN (
            SELECT id FROM patients WHERE id = athlete_id
        )
    );

CREATE POLICY "Patients can accept their own substitutions"
    ON ai_exercise_substitutions FOR UPDATE
    USING (
        athlete_id IN (
            SELECT id FROM patients WHERE id = athlete_id
        )
    );

-- Service role can do everything (for Edge Functions)
CREATE POLICY "Service role can manage all AI data"
    ON ai_chat_sessions FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role can manage all messages"
    ON ai_chat_messages FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role can manage all safety checks"
    ON ai_safety_checks FOR ALL
    USING (true)
    WITH CHECK (true);

CREATE POLICY "Service role can manage all substitutions"
    ON ai_exercise_substitutions FOR ALL
    USING (true)
    WITH CHECK (true);

-- =====================================================
-- Verification
-- =====================================================

DO $$
DECLARE
    session_count INTEGER;
    message_count INTEGER;
    safety_count INTEGER;
    substitution_count INTEGER;
BEGIN
    SELECT COUNT(*) INTO session_count FROM ai_chat_sessions;
    SELECT COUNT(*) INTO message_count FROM ai_chat_messages;
    SELECT COUNT(*) INTO safety_count FROM ai_safety_checks;
    SELECT COUNT(*) INTO substitution_count FROM ai_exercise_substitutions;

    RAISE NOTICE 'AI Chat Tables Migration Complete:';
    RAISE NOTICE '  - ai_chat_sessions: % rows', session_count;
    RAISE NOTICE '  - ai_chat_messages: % rows', message_count;
    RAISE NOTICE '  - ai_safety_checks: % rows', safety_count;
    RAISE NOTICE '  - ai_exercise_substitutions: % rows', substitution_count;
    RAISE NOTICE '  - RLS policies enabled on all tables';
    RAISE NOTICE '  - Triggers configured';
    RAISE NOTICE '';
    RAISE NOTICE 'Build 88 AI Chat System Ready!';
END $$;
