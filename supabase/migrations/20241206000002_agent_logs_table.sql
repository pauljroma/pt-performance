-- 007_agent_logs_table.sql
-- Agent 3 Phase 2: Observability Infrastructure
-- Create agent_logs table for endpoint logging
-- ACP-74: Add logging to endpoints

-- ============================================================================
-- AGENT LOGS TABLE
-- ============================================================================

CREATE TABLE IF NOT EXISTS agent_logs (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Request metadata
  endpoint TEXT NOT NULL,
  method TEXT NOT NULL CHECK (method IN ('GET', 'POST', 'PUT', 'DELETE', 'PATCH')),
  patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,

  -- Performance metrics
  response_time_ms NUMERIC,
  status_code INT,

  -- Error tracking
  error_message TEXT,
  error_stack TEXT,

  -- Context
  request_body JSONB,
  response_body JSONB,

  -- Timestamps
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- Indexes for common queries
  CONSTRAINT valid_status_code CHECK (status_code >= 100 AND status_code < 600)
);

-- ============================================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================================

CREATE INDEX IF NOT EXISTS idx_agent_logs_endpoint
  ON agent_logs(endpoint);

CREATE INDEX IF NOT EXISTS idx_agent_logs_patient_id
  ON agent_logs(patient_id) WHERE patient_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_agent_logs_created_at
  ON agent_logs(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_agent_logs_errors
  ON agent_logs(endpoint, created_at DESC)
  WHERE error_message IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY
-- ============================================================================

ALTER TABLE agent_logs ENABLE ROW LEVEL SECURITY;

-- Therapists can see logs for their patients
DO $$ BEGIN
  CREATE POLICY agent_logs_therapist_read ON agent_logs
    FOR SELECT USING (
      patient_id IN (
        SELECT p.id FROM patients p
        WHERE p.therapist_id IN (
          SELECT id FROM therapists WHERE user_id = auth.uid()
        )
      )
      OR patient_id IS NULL  -- System logs visible to all therapists
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- Service role can write all logs
DO $$ BEGIN
  CREATE POLICY agent_logs_service_write ON agent_logs
    FOR ALL USING (
      auth.role() = 'service_role'
    );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ============================================================================
-- HELPER VIEWS
-- ============================================================================

-- View for error summary
CREATE OR REPLACE VIEW vw_agent_error_summary AS
SELECT
  endpoint,
  DATE(created_at) as error_date,
  COUNT(*) as error_count,
  AVG(response_time_ms) as avg_response_time_ms,
  ARRAY_AGG(DISTINCT error_message) as error_messages
FROM agent_logs
WHERE error_message IS NOT NULL
GROUP BY endpoint, DATE(created_at)
ORDER BY error_date DESC, error_count DESC;

-- View for endpoint performance
CREATE OR REPLACE VIEW vw_agent_endpoint_performance AS
SELECT
  endpoint,
  method,
  COUNT(*) as request_count,
  AVG(response_time_ms) as avg_response_time_ms,
  MAX(response_time_ms) as max_response_time_ms,
  MIN(response_time_ms) as min_response_time_ms,
  COUNT(*) FILTER (WHERE status_code >= 500) as server_error_count,
  COUNT(*) FILTER (WHERE status_code >= 400 AND status_code < 500) as client_error_count,
  COUNT(*) FILTER (WHERE status_code >= 200 AND status_code < 300) as success_count
FROM agent_logs
GROUP BY endpoint, method
ORDER BY request_count DESC;

-- ============================================================================
-- COMMENTS
-- ============================================================================

COMMENT ON TABLE agent_logs IS
  'Agent backend endpoint logging for observability, performance tracking, and debugging';

COMMENT ON COLUMN agent_logs.endpoint IS
  'API endpoint path (e.g., /patient-summary/:patientId)';

COMMENT ON COLUMN agent_logs.response_time_ms IS
  'Total request duration in milliseconds';

COMMENT ON COLUMN agent_logs.error_stack IS
  'Full stack trace for debugging (only populated on errors)';

COMMENT ON VIEW vw_agent_error_summary IS
  'Daily error summary by endpoint for monitoring and alerting';

COMMENT ON VIEW vw_agent_endpoint_performance IS
  'Endpoint performance metrics and success rates';
