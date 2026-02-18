-- Migration: Analytics Data Pipeline
-- ACP-962: Server-side event enrichment, data warehouse integration,
-- ETL for combining app + backend events, data quality monitoring,
-- and historical backfill capability.
--
-- Creates:
-- - analytics_events table for ingested and enriched events
-- - analytics_pipeline_status table for pipeline run tracking
-- - enrich_analytics_event(event_id UUID) function for user context enrichment
-- - get_pipeline_health() function for monitoring
-- - RLS policies for service_role read/write and authenticated user insert

-- =============================================================================
-- ANALYTICS EVENTS TABLE
-- =============================================================================
-- Stores all ingested analytics events with enrichment columns.
-- Events flow: ingest -> insert -> enrich -> mark processed -> export to warehouse.

CREATE TABLE IF NOT EXISTS analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_name TEXT NOT NULL,
    user_id TEXT NOT NULL,
    properties JSONB DEFAULT '{}'::JSONB,
    enriched_properties JSONB DEFAULT '{}'::JSONB,
    session_id TEXT,
    timestamp TIMESTAMPTZ NOT NULL,
    received_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    processed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE analytics_events IS 'ACP-962: Analytics pipeline events with server-side enrichment';
COMMENT ON COLUMN analytics_events.event_name IS 'Event identifier (e.g. session_started, workout_completed)';
COMMENT ON COLUMN analytics_events.user_id IS 'User or patient identifier (auth.users.id as TEXT)';
COMMENT ON COLUMN analytics_events.properties IS 'Raw event properties sent by the client';
COMMENT ON COLUMN analytics_events.enriched_properties IS 'Server-enriched context (subscription tier, cohort, etc.)';
COMMENT ON COLUMN analytics_events.session_id IS 'Client-generated session identifier for grouping events';
COMMENT ON COLUMN analytics_events.timestamp IS 'Client-reported event timestamp';
COMMENT ON COLUMN analytics_events.received_at IS 'Server-side timestamp when the event was received';
COMMENT ON COLUMN analytics_events.processed IS 'Whether the event has been enriched and exported';

-- =============================================================================
-- ANALYTICS PIPELINE STATUS TABLE
-- =============================================================================
-- Tracks each pipeline run for health monitoring and debugging.

CREATE TABLE IF NOT EXISTS analytics_pipeline_status (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    pipeline_run_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    events_processed INT NOT NULL DEFAULT 0,
    events_failed INT NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'running' CHECK (status IN ('running', 'completed', 'failed', 'partial')),
    error_message TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE analytics_pipeline_status IS 'ACP-962: Pipeline run history for health monitoring';
COMMENT ON COLUMN analytics_pipeline_status.status IS 'Run status: running, completed, failed, partial';
COMMENT ON COLUMN analytics_pipeline_status.events_processed IS 'Number of events successfully enriched in this run';
COMMENT ON COLUMN analytics_pipeline_status.events_failed IS 'Number of events that failed enrichment in this run';

-- =============================================================================
-- INDEXES
-- =============================================================================

-- Fast lookup for unprocessed events (backfill and pipeline processing)
CREATE INDEX idx_analytics_events_unprocessed
    ON analytics_events (processed, received_at ASC)
    WHERE processed = FALSE;

-- Lookup events by user for enrichment and querying
CREATE INDEX idx_analytics_events_user_id
    ON analytics_events (user_id, timestamp DESC);

-- Lookup events by name for aggregation
CREATE INDEX idx_analytics_events_name_timestamp
    ON analytics_events (event_name, timestamp DESC);

-- Lookup events by session for session-level analysis
CREATE INDEX idx_analytics_events_session_id
    ON analytics_events (session_id, timestamp ASC)
    WHERE session_id IS NOT NULL;

-- Pipeline status lookup for health checks
CREATE INDEX idx_analytics_pipeline_status_run_at
    ON analytics_pipeline_status (pipeline_run_at DESC);

-- =============================================================================
-- ROW LEVEL SECURITY
-- =============================================================================

ALTER TABLE analytics_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE analytics_pipeline_status ENABLE ROW LEVEL SECURITY;

-- Service role (used by edge functions) has full read/write on analytics_events
CREATE POLICY "service_role_all_analytics_events" ON analytics_events
    FOR ALL
    TO service_role
    USING (TRUE)
    WITH CHECK (TRUE);

-- Authenticated users can insert their own events
CREATE POLICY "authenticated_insert_own_analytics_events" ON analytics_events
    FOR INSERT
    TO authenticated
    WITH CHECK (user_id = auth.uid()::TEXT);

-- Authenticated users can read their own events
CREATE POLICY "authenticated_select_own_analytics_events" ON analytics_events
    FOR SELECT
    TO authenticated
    USING (user_id = auth.uid()::TEXT);

-- Service role has full access to pipeline status
CREATE POLICY "service_role_all_pipeline_status" ON analytics_pipeline_status
    FOR ALL
    TO service_role
    USING (TRUE)
    WITH CHECK (TRUE);

-- =============================================================================
-- FUNCTION: enrich_analytics_event
-- =============================================================================
-- Enriches a single analytics event with user context:
-- subscription_tier, signup_cohort, days_since_signup, platform.
-- Pulls data from auth.users, patients, and user_subscriptions.

CREATE OR REPLACE FUNCTION enrich_analytics_event(p_event_id UUID)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_user_id TEXT;
    v_user_uuid UUID;
    v_enriched JSONB;
    v_signup_date TIMESTAMPTZ;
    v_subscription_tier TEXT;
    v_platform TEXT;
    v_days_since_signup INT;
    v_signup_cohort TEXT;
BEGIN
    -- Get the user_id from the event
    SELECT user_id INTO v_user_id
    FROM analytics_events
    WHERE id = p_event_id;

    IF v_user_id IS NULL THEN
        RETURN jsonb_build_object('error', 'Event not found');
    END IF;

    -- Attempt to cast user_id to UUID for lookups
    BEGIN
        v_user_uuid := v_user_id::UUID;
    EXCEPTION WHEN others THEN
        -- user_id is not a valid UUID; enrich with what we can
        v_enriched := jsonb_build_object(
            'subscription_tier', 'unknown',
            'signup_cohort', 'unknown',
            'days_since_signup', NULL,
            'platform', 'unknown',
            'enriched_at', NOW()
        );

        UPDATE analytics_events
        SET enriched_properties = v_enriched,
            processed = TRUE
        WHERE id = p_event_id;

        RETURN v_enriched;
    END;

    -- Get signup date from auth.users
    SELECT created_at INTO v_signup_date
    FROM auth.users
    WHERE id = v_user_uuid;

    -- Calculate days since signup
    IF v_signup_date IS NOT NULL THEN
        v_days_since_signup := EXTRACT(DAY FROM (NOW() - v_signup_date))::INT;
        -- Build cohort label: YYYY-WNN (year + ISO week)
        v_signup_cohort := TO_CHAR(v_signup_date, 'IYYY') || '-W' || TO_CHAR(v_signup_date, 'IW');
    ELSE
        v_days_since_signup := NULL;
        v_signup_cohort := 'unknown';
    END IF;

    -- Get subscription tier from user_subscriptions
    SELECT
        CASE
            WHEN us.status = 'active' AND us.is_trial = TRUE THEN 'trial'
            WHEN us.status = 'active' THEN 'premium'
            WHEN us.status = 'expired' THEN 'expired'
            WHEN us.status = 'cancelled' THEN 'cancelled'
            ELSE 'free'
        END INTO v_subscription_tier
    FROM user_subscriptions us
    WHERE us.user_id = v_user_uuid;

    IF v_subscription_tier IS NULL THEN
        v_subscription_tier := 'free';
    END IF;

    -- Determine platform from event properties if available, fallback to 'unknown'
    SELECT COALESCE(
        ae.properties->>'platform',
        ae.properties->>'os',
        'unknown'
    ) INTO v_platform
    FROM analytics_events ae
    WHERE ae.id = p_event_id;

    -- Build enriched properties
    v_enriched := jsonb_build_object(
        'subscription_tier', v_subscription_tier,
        'signup_cohort', v_signup_cohort,
        'days_since_signup', v_days_since_signup,
        'platform', v_platform,
        'enriched_at', NOW()
    );

    -- Update the event with enriched properties and mark as processed
    UPDATE analytics_events
    SET enriched_properties = v_enriched,
        processed = TRUE
    WHERE id = p_event_id;

    RETURN v_enriched;
END;
$$;

GRANT EXECUTE ON FUNCTION enrich_analytics_event(UUID) TO service_role;

COMMENT ON FUNCTION enrich_analytics_event IS 'ACP-962: Enriches an analytics event with user context (subscription tier, signup cohort, days_since_signup, platform)';

-- =============================================================================
-- FUNCTION: get_pipeline_health
-- =============================================================================
-- Returns current pipeline health metrics:
-- unprocessed_event_count, last_run_time, error_rate, recent_runs.

CREATE OR REPLACE FUNCTION get_pipeline_health()
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_unprocessed_count INT;
    v_total_events INT;
    v_last_run_at TIMESTAMPTZ;
    v_last_run_status TEXT;
    v_error_rate FLOAT;
    v_total_processed INT;
    v_total_failed INT;
    v_recent_runs JSONB;
BEGIN
    -- Count unprocessed events
    SELECT COUNT(*) INTO v_unprocessed_count
    FROM analytics_events
    WHERE processed = FALSE;

    -- Count total events
    SELECT COUNT(*) INTO v_total_events
    FROM analytics_events;

    -- Get last pipeline run info
    SELECT pipeline_run_at, status
    INTO v_last_run_at, v_last_run_status
    FROM analytics_pipeline_status
    ORDER BY pipeline_run_at DESC
    LIMIT 1;

    -- Calculate error rate from last 10 pipeline runs
    SELECT
        COALESCE(SUM(events_processed), 0),
        COALESCE(SUM(events_failed), 0)
    INTO v_total_processed, v_total_failed
    FROM (
        SELECT events_processed, events_failed
        FROM analytics_pipeline_status
        ORDER BY pipeline_run_at DESC
        LIMIT 10
    ) recent;

    IF (v_total_processed + v_total_failed) > 0 THEN
        v_error_rate := v_total_failed::FLOAT / (v_total_processed + v_total_failed);
    ELSE
        v_error_rate := 0;
    END IF;

    -- Get recent pipeline runs
    SELECT COALESCE(jsonb_agg(run_data), '[]'::JSONB)
    INTO v_recent_runs
    FROM (
        SELECT jsonb_build_object(
            'id', id,
            'pipeline_run_at', pipeline_run_at,
            'events_processed', events_processed,
            'events_failed', events_failed,
            'status', status,
            'error_message', error_message
        ) AS run_data
        FROM analytics_pipeline_status
        ORDER BY pipeline_run_at DESC
        LIMIT 10
    ) runs;

    RETURN jsonb_build_object(
        'unprocessed_event_count', v_unprocessed_count,
        'total_event_count', v_total_events,
        'last_run_at', v_last_run_at,
        'last_run_status', v_last_run_status,
        'error_rate', ROUND(v_error_rate::NUMERIC, 4),
        'recent_processed_total', v_total_processed,
        'recent_failed_total', v_total_failed,
        'recent_runs', v_recent_runs,
        'checked_at', NOW()
    );
END;
$$;

GRANT EXECUTE ON FUNCTION get_pipeline_health() TO service_role;
GRANT EXECUTE ON FUNCTION get_pipeline_health() TO authenticated;

COMMENT ON FUNCTION get_pipeline_health IS 'ACP-962: Returns pipeline health metrics — unprocessed count, last run time, error rate, recent runs';
