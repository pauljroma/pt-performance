-- 20251219120002_setup_workload_flags_cron.sql
-- Build 69: Setup Cron Job for Automated Workload Flag Generation
-- Agent 8: Safety & Audit - Backend
--
-- Sets up daily cron job to generate workload flags for all active patients
-- Runs at 2 AM daily to analyze previous day's training data
--
-- Requires: pg_cron extension (standard on Supabase)
-- Depends on: 20251219120001_create_workload_flags.sql

-- ============================================================================
-- ENABLE PG_CRON EXTENSION
-- ============================================================================
-- pg_cron is used to schedule recurring jobs in PostgreSQL
-- On Supabase, this is typically pre-enabled

CREATE EXTENSION IF NOT EXISTS pg_cron;

-- ============================================================================
-- CREATE CRON JOB FOR WORKLOAD FLAG GENERATION
-- ============================================================================
-- Schedule: Daily at 2:00 AM UTC
-- Why 2 AM? Low traffic time, after midnight session completion cutoff

-- First, remove any existing job with the same name
SELECT cron.unschedule('generate-workload-flags-daily')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'generate-workload-flags-daily'
);

-- Create the daily cron job
-- Note: This calls the database function directly instead of the Edge Function
-- For Edge Function approach, see alternative method below
SELECT cron.schedule(
  'generate-workload-flags-daily',     -- Job name
  '0 2 * * *',                         -- Cron expression: 2 AM daily
  $$
  -- Execute the workload flag generation for all patients
  SELECT * FROM generate_workload_flags_all_patients();
  $$
);

COMMENT ON EXTENSION pg_cron IS 'Job scheduler for PostgreSQL - used for automated workload flag generation';

-- ============================================================================
-- MONITORING: Create job execution log table
-- ============================================================================
-- Track cron job executions for monitoring and debugging

CREATE TABLE IF NOT EXISTS workload_flags_job_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  job_name text NOT NULL,
  started_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  status text CHECK (status IN ('running', 'success', 'error')),
  patients_processed int,
  errors_count int,
  high_risk_count int,
  error_message text,
  execution_time_ms int
);

CREATE INDEX IF NOT EXISTS idx_workload_flags_job_log_started
ON workload_flags_job_log(started_at DESC);

COMMENT ON TABLE workload_flags_job_log IS
'Execution log for workload flag generation cron jobs';

-- ============================================================================
-- WRAPPER FUNCTION: Execute with logging
-- ============================================================================
-- Wraps the generation function with execution logging

CREATE OR REPLACE FUNCTION execute_workload_flags_job()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  job_id uuid;
  start_time timestamptz;
  end_time timestamptz;
  result_count int := 0;
  error_count int := 0;
  high_risk_count int := 0;
  execution_ms int;
BEGIN
  -- Create job log entry
  INSERT INTO workload_flags_job_log (job_name, started_at, status)
  VALUES ('generate-workload-flags-daily', now(), 'running')
  RETURNING id INTO job_id;

  start_time := clock_timestamp();

  -- Execute the workload flag generation
  BEGIN
    -- Count results
    SELECT COUNT(*)
    INTO result_count
    FROM generate_workload_flags_all_patients();

    -- Count errors and high risk patients
    SELECT
      COUNT(*) FILTER (WHERE deload_triggered = true OR high_acwr = true),
      COUNT(*) FILTER (WHERE acwr > 1.5)
    INTO error_count, high_risk_count
    FROM workload_flags
    WHERE calculated_at >= start_time;

    end_time := clock_timestamp();
    execution_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;

    -- Update job log with success
    UPDATE workload_flags_job_log
    SET
      completed_at = end_time,
      status = 'success',
      patients_processed = result_count,
      errors_count = error_count,
      high_risk_count = high_risk_count,
      execution_time_ms = execution_ms
    WHERE id = job_id;

    RAISE NOTICE 'Workload flags job completed: % patients, % high risk, % ms',
      result_count, high_risk_count, execution_ms;

  EXCEPTION WHEN OTHERS THEN
    end_time := clock_timestamp();
    execution_ms := EXTRACT(EPOCH FROM (end_time - start_time)) * 1000;

    -- Update job log with error
    UPDATE workload_flags_job_log
    SET
      completed_at = end_time,
      status = 'error',
      error_message = SQLERRM,
      execution_time_ms = execution_ms
    WHERE id = job_id;

    RAISE WARNING 'Workload flags job failed: %', SQLERRM;
  END;
END;
$$;

COMMENT ON FUNCTION execute_workload_flags_job IS
'Wrapper function for workload flag generation with execution logging';

-- ============================================================================
-- UPDATE CRON JOB TO USE LOGGING WRAPPER
-- ============================================================================

SELECT cron.unschedule('generate-workload-flags-daily')
WHERE EXISTS (
  SELECT 1 FROM cron.job WHERE jobname = 'generate-workload-flags-daily'
);

SELECT cron.schedule(
  'generate-workload-flags-daily',
  '0 2 * * *',  -- 2 AM daily
  $$SELECT execute_workload_flags_job();$$
);

-- ============================================================================
-- ALTERNATIVE: Edge Function Approach (Comment in if needed)
-- ============================================================================
-- If you prefer to call the Edge Function via HTTP instead of database function:
-- Requires pg_net extension for HTTP requests from database

/*
CREATE EXTENSION IF NOT EXISTS pg_net;

SELECT cron.schedule(
  'generate-workload-flags-daily-edge',
  '0 2 * * *',
  $$
  SELECT net.http_post(
    url := 'https://YOUR_PROJECT.supabase.co/functions/v1/generate-workload-flags',
    headers := jsonb_build_object(
      'Content-Type', 'application/json',
      'Authorization', 'Bearer ' || current_setting('app.settings.service_role_key', true)
    ),
    body := jsonb_build_object(
      'trigger_type', 'cron',
      'timestamp', now()
    )
  ) AS request_id;
  $$
);
*/

-- ============================================================================
-- MANUAL TRIGGER FUNCTION
-- ============================================================================
-- Allows manual execution via SQL for testing

CREATE OR REPLACE FUNCTION trigger_workload_flags_manual()
RETURNS TABLE(
  patient_id uuid,
  status text,
  acwr numeric,
  deload_triggered boolean
)
LANGUAGE plpgsql
AS $$
BEGIN
  RAISE NOTICE 'Manual workload flag generation triggered at %', now();

  RETURN QUERY
  SELECT * FROM generate_workload_flags_all_patients();
END;
$$;

COMMENT ON FUNCTION trigger_workload_flags_manual IS
'Manually trigger workload flag generation for testing. Usage: SELECT * FROM trigger_workload_flags_manual();';

-- ============================================================================
-- POST-SESSION TRIGGER (Optional)
-- ============================================================================
-- Automatically generate workload flags when a session is completed
-- This provides real-time updates instead of waiting for daily cron

CREATE OR REPLACE FUNCTION trigger_workload_flags_on_session_complete()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
  patient_id_var uuid;
BEGIN
  -- Only trigger if session was just marked as completed
  IF NEW.completed = true AND (OLD.completed = false OR OLD.completed IS NULL) THEN

    -- Get patient_id from the session's program
    SELECT pr.patient_id INTO patient_id_var
    FROM phases ph
    JOIN programs pr ON pr.id = ph.program_id
    WHERE ph.id = NEW.phase_id;

    -- Generate workload flags for this patient
    IF patient_id_var IS NOT NULL THEN
      PERFORM generate_workload_flags_for_patient(patient_id_var);

      RAISE NOTICE 'Workload flags updated for patient % after session completion', patient_id_var;
    END IF;
  END IF;

  RETURN NEW;
END;
$$;

-- Create the trigger on sessions table
DROP TRIGGER IF EXISTS after_session_completed_workload_flags ON sessions;

CREATE TRIGGER after_session_completed_workload_flags
AFTER UPDATE ON sessions
FOR EACH ROW
WHEN (NEW.completed = true)
EXECUTE FUNCTION trigger_workload_flags_on_session_complete();

COMMENT ON TRIGGER after_session_completed_workload_flags ON sessions IS
'Automatically generates workload flags when a session is marked as completed';

-- ============================================================================
-- MONITORING VIEWS
-- ============================================================================

-- View recent job executions
CREATE OR REPLACE VIEW vw_workload_flags_job_history AS
SELECT
  job_name,
  started_at,
  completed_at,
  status,
  patients_processed,
  high_risk_count,
  execution_time_ms,
  error_message,
  (completed_at - started_at) as duration
FROM workload_flags_job_log
ORDER BY started_at DESC;

COMMENT ON VIEW vw_workload_flags_job_history IS
'Recent workload flag job executions with performance metrics';

-- View current high-risk patients
CREATE OR REPLACE VIEW vw_high_risk_patients AS
SELECT
  p.id,
  p.first_name,
  p.last_name,
  p.email,
  wf.acwr,
  wf.acute_workload,
  wf.chronic_workload,
  wf.high_acwr,
  wf.deload_triggered,
  wf.deload_reason,
  wf.severity,
  wf.calculated_at,
  t.first_name as therapist_first_name,
  t.last_name as therapist_last_name,
  t.email as therapist_email
FROM workload_flags wf
JOIN patients p ON p.id = wf.patient_id
LEFT JOIN therapists t ON t.id = p.therapist_id
WHERE wf.high_acwr = true
   OR wf.deload_triggered = true
   OR wf.acwr > 1.5
ORDER BY
  CASE
    WHEN wf.acwr > 1.5 THEN 1
    WHEN wf.deload_triggered THEN 2
    ELSE 3
  END,
  wf.acwr DESC NULLS LAST;

COMMENT ON VIEW vw_high_risk_patients IS
'Current high-risk patients requiring attention (ACWR > 1.5 or deload triggered)';

-- Grant permissions
GRANT SELECT ON vw_workload_flags_job_history TO authenticated;
GRANT SELECT ON vw_high_risk_patients TO authenticated;

-- ============================================================================
-- CLEANUP OLD LOGS (Keep last 90 days)
-- ============================================================================

CREATE OR REPLACE FUNCTION cleanup_old_workload_job_logs()
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
  deleted_count int;
BEGIN
  DELETE FROM workload_flags_job_log
  WHERE started_at < now() - interval '90 days';

  GET DIAGNOSTICS deleted_count = ROW_COUNT;

  RAISE NOTICE 'Cleaned up % old workload flag job logs', deleted_count;
END;
$$;

-- Schedule cleanup monthly
SELECT cron.schedule(
  'cleanup-workload-job-logs',
  '0 3 1 * *',  -- 3 AM on first day of month
  $$SELECT cleanup_old_workload_job_logs();$$
);

-- ============================================================================
-- VALIDATION
-- ============================================================================

DO $$
DECLARE
  cron_enabled boolean;
  job_scheduled boolean;
  trigger_exists boolean;
BEGIN
  -- Check if pg_cron is enabled
  SELECT EXISTS(
    SELECT 1 FROM pg_extension WHERE extname = 'pg_cron'
  ) INTO cron_enabled;

  -- Check if job is scheduled
  SELECT EXISTS(
    SELECT 1 FROM cron.job WHERE jobname = 'generate-workload-flags-daily'
  ) INTO job_scheduled;

  -- Check if post-session trigger exists
  SELECT EXISTS(
    SELECT 1 FROM pg_trigger
    WHERE tgname = 'after_session_completed_workload_flags'
  ) INTO trigger_exists;

  RAISE NOTICE '';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'WORKLOAD FLAGS AUTOMATION SETUP';
  RAISE NOTICE '============================================';
  RAISE NOTICE 'pg_cron extension: %', CASE WHEN cron_enabled THEN '✅ ENABLED' ELSE '❌ DISABLED' END;
  RAISE NOTICE 'Daily cron job: %', CASE WHEN job_scheduled THEN '✅ SCHEDULED (2 AM daily)' ELSE '❌ NOT SCHEDULED' END;
  RAISE NOTICE 'Post-session trigger: %', CASE WHEN trigger_exists THEN '✅ ACTIVE' ELSE '❌ NOT ACTIVE' END;
  RAISE NOTICE '';
  RAISE NOTICE 'Monitoring:';
  RAISE NOTICE '  • Job history: SELECT * FROM vw_workload_flags_job_history;';
  RAISE NOTICE '  • High-risk patients: SELECT * FROM vw_high_risk_patients;';
  RAISE NOTICE '  • Manual trigger: SELECT * FROM trigger_workload_flags_manual();';
  RAISE NOTICE '';
  RAISE NOTICE 'Next scheduled run:';

  -- Show next scheduled execution
  SELECT RAISE NOTICE '  • %',
    (SELECT schedule FROM cron.job WHERE jobname = 'generate-workload-flags-daily');

  RAISE NOTICE '============================================';
  RAISE NOTICE '';
  RAISE NOTICE 'ACP-192: Auto-generation cron job ✅ COMPLETE';
  RAISE NOTICE '============================================';
END $$;
