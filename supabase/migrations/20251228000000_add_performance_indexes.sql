-- Build 96: Performance Optimization - Add Database Indexes
-- Date: 2025-12-28
-- Purpose: Add missing indexes to improve query performance for frequently accessed columns

-- Index for patients table (therapist_id is heavily queried)
CREATE INDEX IF NOT EXISTS idx_patients_therapist_id
ON patients(therapist_id);

CREATE INDEX IF NOT EXISTS idx_patients_email
ON patients(email);

CREATE INDEX IF NOT EXISTS idx_patients_auth_user_id
ON patients(auth_user_id);

-- Index for therapists table (email lookup on auth)
CREATE INDEX IF NOT EXISTS idx_therapists_email
ON therapists(email);

CREATE INDEX IF NOT EXISTS idx_therapists_auth_user_id
ON therapists(auth_user_id);

-- Index for programs table (patient_id and status are frequently filtered)
CREATE INDEX IF NOT EXISTS idx_programs_patient_id
ON programs(patient_id);

CREATE INDEX IF NOT EXISTS idx_programs_status
ON programs(status);

CREATE INDEX IF NOT EXISTS idx_programs_patient_status
ON programs(patient_id, status);

-- Index for phases table (program_id for joins)
CREATE INDEX IF NOT EXISTS idx_phases_program_id
ON phases(program_id);

-- Index for sessions table (phase_id and completed status)
CREATE INDEX IF NOT EXISTS idx_sessions_phase_id
ON sessions(phase_id);

CREATE INDEX IF NOT EXISTS idx_sessions_completed
ON sessions(completed);

-- Index for session_exercises (session_id and sequence for ordering)
CREATE INDEX IF NOT EXISTS idx_session_exercises_session_id
ON session_exercises(session_id);

CREATE INDEX IF NOT EXISTS idx_session_exercises_sequence
ON session_exercises(session_id, sequence);

CREATE INDEX IF NOT EXISTS idx_session_exercises_template
ON session_exercises(exercise_template_id);

-- Index for exercise_logs (patient_id and logged_at for history queries)
CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_id
ON exercise_logs(patient_id);

CREATE INDEX IF NOT EXISTS idx_exercise_logs_session_exercise
ON exercise_logs(session_exercise_id);

CREATE INDEX IF NOT EXISTS idx_exercise_logs_logged_at
ON exercise_logs(logged_at DESC);

CREATE INDEX IF NOT EXISTS idx_exercise_logs_patient_date
ON exercise_logs(patient_id, logged_at DESC);

-- Index for workload_flags (already has idx_workload_flags_patient_id)
-- Adding composite index for unresolved flags
CREATE INDEX IF NOT EXISTS idx_workload_flags_patient_resolved
ON workload_flags(patient_id, is_resolved);

CREATE INDEX IF NOT EXISTS idx_workload_flags_severity_resolved
ON workload_flags(severity, is_resolved) WHERE is_resolved = false;

-- Index for patient_flags (patient_id and severity)
CREATE INDEX IF NOT EXISTS idx_patient_flags_patient_id
ON patient_flags(patient_id);

CREATE INDEX IF NOT EXISTS idx_patient_flags_resolved
ON patient_flags(patient_id, resolved_at) WHERE resolved_at IS NULL;

CREATE INDEX IF NOT EXISTS idx_patient_flags_severity
ON patient_flags(severity, created_at DESC);

-- Index for scheduled_sessions (patient_id and scheduled_for)
CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_patient_id
ON scheduled_sessions(patient_id);

CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_scheduled_for
ON scheduled_sessions(scheduled_for);

CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_patient_date
ON scheduled_sessions(patient_id, scheduled_for);

CREATE INDEX IF NOT EXISTS idx_scheduled_sessions_completed
ON scheduled_sessions(completed);

-- Index for session_interval_blocks (session_id and sort_order)
CREATE INDEX IF NOT EXISTS idx_session_interval_blocks_session_id
ON session_interval_blocks(session_id);

CREATE INDEX IF NOT EXISTS idx_session_interval_blocks_sort_order
ON session_interval_blocks(session_id, sort_order);

-- Index for ai_conversations (user_id and created_at)
CREATE INDEX IF NOT EXISTS idx_ai_conversations_user_created
ON ai_conversations(user_id, created_at DESC);

-- Index for ai_messages (conversation_id for fetching chat history)
CREATE INDEX IF NOT EXISTS idx_ai_messages_conversation_created
ON ai_messages(conversation_id, created_at);

-- Index for help_articles (category and published status)
CREATE INDEX IF NOT EXISTS idx_help_articles_category
ON help_articles(category);

CREATE INDEX IF NOT EXISTS idx_help_articles_published
ON help_articles(is_published) WHERE is_published = true;

CREATE INDEX IF NOT EXISTS idx_help_articles_category_published
ON help_articles(category, sort_order) WHERE is_published = true;

-- Composite index for common query patterns (programs -> phases -> sessions)
-- This helps with the nested query in TodaySessionViewModel
CREATE INDEX IF NOT EXISTS idx_sessions_phase_sequence
ON sessions(phase_id, sequence);

-- Performance note: These indexes will improve query performance but increase write overhead slightly
-- Monitor index usage with: SELECT * FROM pg_stat_user_indexes WHERE schemaname = 'public';
-- Check for unused indexes periodically and drop if not used

-- Add comments for documentation
COMMENT ON INDEX idx_patients_therapist_id IS 'Optimize therapist -> patients lookup (PatientListViewModel)';
COMMENT ON INDEX idx_programs_patient_status IS 'Optimize active program lookup (TodaySessionViewModel)';
COMMENT ON INDEX idx_exercise_logs_patient_date IS 'Optimize patient history queries (HistoryViewModel)';
COMMENT ON INDEX idx_workload_flags_patient_resolved IS 'Optimize unresolved flags lookup (PatientDetailViewModel)';
COMMENT ON INDEX idx_sessions_phase_sequence IS 'Optimize session ordering in programs (TodaySessionViewModel)';

-- Analyze tables to update query planner statistics
ANALYZE patients;
ANALYZE programs;
ANALYZE phases;
ANALYZE sessions;
ANALYZE session_exercises;
ANALYZE exercise_logs;
ANALYZE workload_flags;
ANALYZE patient_flags;
ANALYZE scheduled_sessions;
ANALYZE session_interval_blocks;
