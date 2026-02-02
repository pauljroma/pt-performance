-- ============================================================================
-- AUTOMATION WEBHOOK TRIGGERS - Make.com Integration
-- ============================================================================
-- Creates webhook triggers for key events to integrate with Make.com automations
--
-- Date: 2026-02-01
-- Purpose: Enable Make.com webhooks to be triggered on key patient events:
--   - Patient created (on_patient_created)
--   - Program completed (on_program_completed)
--   - Readiness logged (on_readiness_logged)
--   - Session completed (on_session_completed)
-- ============================================================================

-- ============================================================================
-- 1. Enable pg_net Extension for HTTP Requests
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- ============================================================================
-- 2. Create Webhook Configuration Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS automation_webhooks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT UNIQUE NOT NULL,
    webhook_url TEXT NOT NULL,
    is_active BOOLEAN DEFAULT true,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index for active webhooks lookup
CREATE INDEX IF NOT EXISTS idx_automation_webhooks_active
    ON automation_webhooks(name)
    WHERE is_active = true;

COMMENT ON TABLE automation_webhooks IS 'Configuration table for Make.com webhook URLs. Each webhook can be enabled/disabled independently.';
COMMENT ON COLUMN automation_webhooks.name IS 'Unique webhook identifier (e.g., on_patient_created, on_session_completed)';
COMMENT ON COLUMN automation_webhooks.webhook_url IS 'Full Make.com webhook URL to call';
COMMENT ON COLUMN automation_webhooks.is_active IS 'Toggle to enable/disable individual webhooks';

-- Insert placeholder webhook configurations (URLs to be updated with actual Make.com webhook URLs)
INSERT INTO automation_webhooks (name, webhook_url, description) VALUES
    ('on_patient_created', 'https://hook.make.com/PLACEHOLDER_PATIENT_CREATED', 'Triggered when a new patient is created'),
    ('on_program_completed', 'https://hook.make.com/PLACEHOLDER_PROGRAM_COMPLETED', 'Triggered when a patient completes a program enrollment'),
    ('on_readiness_logged', 'https://hook.make.com/PLACEHOLDER_READINESS_LOGGED', 'Triggered when a patient logs daily readiness'),
    ('on_session_completed', 'https://hook.make.com/PLACEHOLDER_SESSION_COMPLETED', 'Triggered when a scheduled session is marked as completed')
ON CONFLICT (name) DO UPDATE SET
    description = EXCLUDED.description,
    updated_at = NOW();

-- ============================================================================
-- 3. Create Automation Logs Table
-- ============================================================================

CREATE TABLE IF NOT EXISTS automation_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_type TEXT NOT NULL,
    patient_id UUID REFERENCES patients(id) ON DELETE SET NULL,
    payload JSONB,
    webhook_response JSONB,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'sent', 'failed', 'skipped')),
    error_message TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create indexes for automation_logs
CREATE INDEX IF NOT EXISTS idx_automation_logs_event_type
    ON automation_logs(event_type, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_logs_patient_id
    ON automation_logs(patient_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_logs_status
    ON automation_logs(status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_automation_logs_created_at
    ON automation_logs(created_at DESC);

COMMENT ON TABLE automation_logs IS 'Audit log for all automation webhook calls. Tracks payloads sent and responses received.';
COMMENT ON COLUMN automation_logs.event_type IS 'Type of event that triggered the webhook (matches automation_webhooks.name)';
COMMENT ON COLUMN automation_logs.payload IS 'JSON payload sent to the webhook';
COMMENT ON COLUMN automation_logs.webhook_response IS 'Response received from the webhook (if any)';
COMMENT ON COLUMN automation_logs.status IS 'Status of the webhook call: pending, sent, failed, skipped';

-- ============================================================================
-- 4. Helper Function: Send Automation Webhook
-- ============================================================================

CREATE OR REPLACE FUNCTION send_automation_webhook(
    webhook_name TEXT,
    payload JSONB
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_webhook_url TEXT;
    v_is_active BOOLEAN;
    v_log_id UUID;
    v_patient_id UUID;
BEGIN
    -- Get webhook configuration
    SELECT webhook_url, is_active
    INTO v_webhook_url, v_is_active
    FROM automation_webhooks
    WHERE name = webhook_name;

    -- Extract patient_id from payload if present
    v_patient_id := (payload->>'patient_id')::UUID;

    -- Create log entry
    INSERT INTO automation_logs (event_type, patient_id, payload, status)
    VALUES (webhook_name, v_patient_id, payload, 'pending')
    RETURNING id INTO v_log_id;

    -- Check if webhook exists and is active
    IF v_webhook_url IS NULL THEN
        UPDATE automation_logs
        SET status = 'skipped', error_message = 'Webhook not configured'
        WHERE id = v_log_id;
        RETURN;
    END IF;

    IF NOT v_is_active THEN
        UPDATE automation_logs
        SET status = 'skipped', error_message = 'Webhook is disabled'
        WHERE id = v_log_id;
        RETURN;
    END IF;

    -- Send HTTP POST request to webhook using pg_net
    -- Note: pg_net.http_post is asynchronous and non-blocking
    PERFORM net.http_post(
        url := v_webhook_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'X-Webhook-Source', 'pt-performance',
            'X-Event-Type', webhook_name,
            'X-Log-Id', v_log_id::TEXT
        ),
        body := payload
    );

    -- Update log status to sent (response will be logged separately if needed)
    UPDATE automation_logs
    SET status = 'sent'
    WHERE id = v_log_id;

EXCEPTION WHEN OTHERS THEN
    -- Log the error but don't fail the original transaction
    UPDATE automation_logs
    SET status = 'failed', error_message = SQLERRM
    WHERE id = v_log_id;
END;
$$;

COMMENT ON FUNCTION send_automation_webhook IS
    'Sends a JSON payload to a configured Make.com webhook. Logs all attempts for auditing.';

-- ============================================================================
-- 5. Trigger Function: On Patient Created
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_on_patient_created()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payload JSONB;
BEGIN
    -- Build payload with patient data
    v_payload := jsonb_build_object(
        'event', 'patient_created',
        'timestamp', NOW(),
        'table_name', TG_TABLE_NAME,
        'operation', TG_OP,
        'patient_id', NEW.id,
        'patient', row_to_json(NEW)::JSONB
    );

    -- Send webhook asynchronously
    PERFORM send_automation_webhook('on_patient_created', v_payload);

    RETURN NEW;
END;
$$;

-- Create trigger on patients table
DROP TRIGGER IF EXISTS automation_on_patient_created ON patients;
CREATE TRIGGER automation_on_patient_created
    AFTER INSERT ON patients
    FOR EACH ROW
    EXECUTE FUNCTION trigger_on_patient_created();

COMMENT ON FUNCTION trigger_on_patient_created IS
    'Trigger function that fires on INSERT to patients table and sends webhook to Make.com';

-- ============================================================================
-- 6. Trigger Function: On Program Completed
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_on_program_completed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payload JSONB;
    v_program_info JSONB;
BEGIN
    -- Only fire when status changes to 'completed'
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN

        -- Get program library info
        SELECT jsonb_build_object(
            'program_library_id', pl.id,
            'title', pl.title,
            'category', pl.category,
            'duration_weeks', pl.duration_weeks,
            'difficulty_level', pl.difficulty_level
        )
        INTO v_program_info
        FROM program_library pl
        WHERE pl.id = NEW.program_library_id;

        -- Build payload
        v_payload := jsonb_build_object(
            'event', 'program_completed',
            'timestamp', NOW(),
            'table_name', TG_TABLE_NAME,
            'operation', TG_OP,
            'patient_id', NEW.patient_id,
            'enrollment_id', NEW.id,
            'enrollment', row_to_json(NEW)::JSONB,
            'program', COALESCE(v_program_info, '{}'::JSONB),
            'completed_at', NEW.completed_at,
            'progress_percentage', NEW.progress_percentage
        );

        -- Send webhook asynchronously
        PERFORM send_automation_webhook('on_program_completed', v_payload);
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger on program_enrollments table
DROP TRIGGER IF EXISTS automation_on_program_completed ON program_enrollments;
CREATE TRIGGER automation_on_program_completed
    AFTER UPDATE ON program_enrollments
    FOR EACH ROW
    EXECUTE FUNCTION trigger_on_program_completed();

COMMENT ON FUNCTION trigger_on_program_completed IS
    'Trigger function that fires when program_enrollments status changes to completed';

-- ============================================================================
-- 7. Trigger Function: On Readiness Logged
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_on_readiness_logged()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payload JSONB;
    v_patient_info JSONB;
BEGIN
    -- Get patient info
    SELECT jsonb_build_object(
        'id', p.id,
        'first_name', p.first_name,
        'last_name', p.last_name,
        'email', p.email
    )
    INTO v_patient_info
    FROM patients p
    WHERE p.id = NEW.patient_id;

    -- Build payload with readiness data
    v_payload := jsonb_build_object(
        'event', 'readiness_logged',
        'timestamp', NOW(),
        'table_name', TG_TABLE_NAME,
        'operation', TG_OP,
        'patient_id', NEW.patient_id,
        'patient', COALESCE(v_patient_info, '{}'::JSONB),
        'readiness_id', NEW.id,
        'readiness', jsonb_build_object(
            'date', NEW.date,
            'sleep_hours', NEW.sleep_hours,
            'soreness_level', NEW.soreness_level,
            'energy_level', NEW.energy_level,
            'stress_level', NEW.stress_level,
            'readiness_score', NEW.readiness_score,
            'notes', NEW.notes
        )
    );

    -- Send webhook asynchronously
    PERFORM send_automation_webhook('on_readiness_logged', v_payload);

    RETURN NEW;
END;
$$;

-- Create trigger on daily_readiness table
DROP TRIGGER IF EXISTS automation_on_readiness_logged ON daily_readiness;
CREATE TRIGGER automation_on_readiness_logged
    AFTER INSERT ON daily_readiness
    FOR EACH ROW
    EXECUTE FUNCTION trigger_on_readiness_logged();

COMMENT ON FUNCTION trigger_on_readiness_logged IS
    'Trigger function that fires on INSERT to daily_readiness table and sends webhook to Make.com';

-- ============================================================================
-- 8. Trigger Function: On Session Completed
-- ============================================================================

CREATE OR REPLACE FUNCTION trigger_on_session_completed()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    v_payload JSONB;
    v_session_info JSONB;
    v_patient_info JSONB;
BEGIN
    -- Only fire when status changes to 'completed'
    IF NEW.status = 'completed' AND (OLD.status IS NULL OR OLD.status != 'completed') THEN

        -- Get session info
        SELECT jsonb_build_object(
            'session_id', s.id,
            'session_name', s.name,
            'phase_id', s.phase_id,
            'phase_name', ph.name,
            'program_name', pr.name
        )
        INTO v_session_info
        FROM sessions s
        LEFT JOIN phases ph ON ph.id = s.phase_id
        LEFT JOIN programs pr ON pr.id = ph.program_id
        WHERE s.id = NEW.session_id;

        -- Get patient info
        SELECT jsonb_build_object(
            'id', p.id,
            'first_name', p.first_name,
            'last_name', p.last_name,
            'email', p.email
        )
        INTO v_patient_info
        FROM patients p
        WHERE p.id = NEW.patient_id;

        -- Build payload
        v_payload := jsonb_build_object(
            'event', 'session_completed',
            'timestamp', NOW(),
            'table_name', TG_TABLE_NAME,
            'operation', TG_OP,
            'patient_id', NEW.patient_id,
            'patient', COALESCE(v_patient_info, '{}'::JSONB),
            'scheduled_session_id', NEW.id,
            'scheduled_session', row_to_json(NEW)::JSONB,
            'session', COALESCE(v_session_info, '{}'::JSONB),
            'completed_at', NEW.completed_at,
            'scheduled_date', NEW.scheduled_date,
            'scheduled_time', NEW.scheduled_time
        );

        -- Send webhook asynchronously
        PERFORM send_automation_webhook('on_session_completed', v_payload);
    END IF;

    RETURN NEW;
END;
$$;

-- Create trigger on scheduled_sessions table
DROP TRIGGER IF EXISTS automation_on_session_completed ON scheduled_sessions;
CREATE TRIGGER automation_on_session_completed
    AFTER UPDATE ON scheduled_sessions
    FOR EACH ROW
    EXECUTE FUNCTION trigger_on_session_completed();

COMMENT ON FUNCTION trigger_on_session_completed IS
    'Trigger function that fires when scheduled_sessions status changes to completed';

-- ============================================================================
-- 9. Row Level Security (RLS) Policies
-- ============================================================================

-- Enable RLS on automation tables
ALTER TABLE automation_webhooks ENABLE ROW LEVEL SECURITY;
ALTER TABLE automation_logs ENABLE ROW LEVEL SECURITY;

-- automation_webhooks: Service role only (backend operations)
CREATE POLICY "Service role full access to automation_webhooks"
    ON automation_webhooks FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- automation_logs: Service role only for write operations
CREATE POLICY "Service role full access to automation_logs"
    ON automation_logs FOR ALL
    TO service_role
    USING (true)
    WITH CHECK (true);

-- Therapists can view automation logs (read-only) for debugging
CREATE POLICY "Therapists can view automation_logs"
    ON automation_logs FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- Therapists can view webhook configurations (read-only)
CREATE POLICY "Therapists can view automation_webhooks"
    ON automation_webhooks FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM auth.users
            WHERE auth.users.id = auth.uid()
            AND auth.users.raw_user_meta_data->>'role' = 'therapist'
        )
    );

-- ============================================================================
-- 10. Grant Permissions
-- ============================================================================

GRANT SELECT ON automation_webhooks TO authenticated;
GRANT ALL ON automation_webhooks TO service_role;

GRANT SELECT ON automation_logs TO authenticated;
GRANT ALL ON automation_logs TO service_role;

GRANT EXECUTE ON FUNCTION send_automation_webhook TO service_role;
GRANT EXECUTE ON FUNCTION trigger_on_patient_created TO service_role;
GRANT EXECUTE ON FUNCTION trigger_on_program_completed TO service_role;
GRANT EXECUTE ON FUNCTION trigger_on_readiness_logged TO service_role;
GRANT EXECUTE ON FUNCTION trigger_on_session_completed TO service_role;

-- ============================================================================
-- 11. Helper Function: Update Webhook URL
-- ============================================================================

CREATE OR REPLACE FUNCTION update_automation_webhook(
    p_webhook_name TEXT,
    p_webhook_url TEXT,
    p_is_active BOOLEAN DEFAULT true
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE automation_webhooks
    SET
        webhook_url = p_webhook_url,
        is_active = p_is_active,
        updated_at = NOW()
    WHERE name = p_webhook_name;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Webhook with name % not found', p_webhook_name;
    END IF;
END;
$$;

COMMENT ON FUNCTION update_automation_webhook IS
    'Update the URL and active status of an automation webhook by name';

GRANT EXECUTE ON FUNCTION update_automation_webhook TO service_role;

-- ============================================================================
-- 12. Verification
-- ============================================================================

DO $$
DECLARE
    v_webhook_count INTEGER;
    v_trigger_count INTEGER;
BEGIN
    -- Count webhooks
    SELECT COUNT(*) INTO v_webhook_count FROM automation_webhooks;

    -- Count triggers
    SELECT COUNT(*) INTO v_trigger_count
    FROM pg_trigger
    WHERE tgname LIKE 'automation_on_%';

    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE 'AUTOMATION WEBHOOK TRIGGERS CREATED';
    RAISE NOTICE '============================================================================';
    RAISE NOTICE '';
    RAISE NOTICE 'Tables Created:';
    RAISE NOTICE '  - automation_webhooks (% webhooks configured)', v_webhook_count;
    RAISE NOTICE '  - automation_logs (audit trail for all webhook calls)';
    RAISE NOTICE '';
    RAISE NOTICE 'Triggers Created (% total):', v_trigger_count;
    RAISE NOTICE '  - automation_on_patient_created (INSERT on patients)';
    RAISE NOTICE '  - automation_on_program_completed (UPDATE on program_enrollments)';
    RAISE NOTICE '  - automation_on_readiness_logged (INSERT on daily_readiness)';
    RAISE NOTICE '  - automation_on_session_completed (UPDATE on scheduled_sessions)';
    RAISE NOTICE '';
    RAISE NOTICE 'Functions Created:';
    RAISE NOTICE '  - send_automation_webhook(webhook_name, payload)';
    RAISE NOTICE '  - update_automation_webhook(name, url, is_active)';
    RAISE NOTICE '  - trigger_on_patient_created()';
    RAISE NOTICE '  - trigger_on_program_completed()';
    RAISE NOTICE '  - trigger_on_readiness_logged()';
    RAISE NOTICE '  - trigger_on_session_completed()';
    RAISE NOTICE '';
    RAISE NOTICE 'RLS Policies:';
    RAISE NOTICE '  - Service role: Full access to automation tables';
    RAISE NOTICE '  - Therapists: Read-only access for debugging';
    RAISE NOTICE '';
    RAISE NOTICE 'NEXT STEPS:';
    RAISE NOTICE '  1. Create webhooks in Make.com for each event type';
    RAISE NOTICE '  2. Update webhook URLs using:';
    RAISE NOTICE '     SELECT update_automation_webhook(';
    RAISE NOTICE '       ''on_patient_created'',';
    RAISE NOTICE '       ''https://hook.make.com/YOUR_ACTUAL_WEBHOOK_URL''';
    RAISE NOTICE '     );';
    RAISE NOTICE '';
    RAISE NOTICE '============================================================================';
END $$;
