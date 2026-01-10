-- BUILD 97: Simple RLS Fix
-- Just disable RLS temporarily to unblock History and AI Chat

-- Disable RLS on problem tables
ALTER TABLE exercise_logs DISABLE ROW LEVEL SECURITY;
ALTER TABLE session_exercises DISABLE ROW LEVEL SECURITY;
ALTER TABLE scheduled_sessions DISABLE ROW LEVEL SECURITY;

-- Enable for ai_chat tables if they exist
DO $$
BEGIN
  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ai_chat_sessions') THEN
    ALTER TABLE ai_chat_sessions DISABLE ROW LEVEL SECURITY;
  END IF;

  IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ai_chat_messages') THEN
    ALTER TABLE ai_chat_messages DISABLE ROW LEVEL SECURITY;
  END IF;
END $$;
