// ============================================================================
// Analytics Data Pipeline Edge Function
// ACP-962: Server-side event enrichment, data warehouse integration,
// ETL for combining app + backend events, data quality monitoring,
// and historical backfill capability.
// ============================================================================
//
// Endpoints:
//   POST /ingest   — Accepts a batch of events, inserts and enriches them
//   GET  /health   — Returns pipeline health metrics
//   POST /backfill — Triggers enrichment of all unprocessed events
//
// Date: 2026-02-18
// Ticket: ACP-962
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

// ============================================================================
// CORS HEADERS
// ============================================================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface AnalyticsEvent {
  event_name: string
  user_id: string
  properties?: Record<string, unknown>
  session_id?: string
  timestamp?: string
}

interface IngestRequest {
  events: AnalyticsEvent[]
}

interface BackfillRequest {
  limit?: number
}

interface IngestResult {
  inserted: number
  enriched: number
  failed: number
  errors: string[]
}

interface BackfillResult {
  processed: number
  failed: number
  errors: string[]
  pipeline_run_id: string
}

interface PipelineHealth {
  unprocessed_event_count: number
  total_event_count: number
  last_run_at: string | null
  last_run_status: string | null
  error_rate: number
  recent_processed_total: number
  recent_failed_total: number
  recent_runs: unknown[]
  checked_at: string
}

// ============================================================================
// CONSTANTS
// ============================================================================

const MAX_BATCH_SIZE = 500
const DEFAULT_BACKFILL_LIMIT = 1000

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function createServiceClient(): SupabaseClient {
  return createClient(
    Deno.env.get('SUPABASE_URL') ?? '',
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
    { auth: { persistSession: false } }
  )
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(
    JSON.stringify(data),
    { status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ success: false, error: message }, status)
}

function isValidTimestamp(value: string): boolean {
  const date = new Date(value)
  return date instanceof Date && !isNaN(date.getTime())
}

function getPathSegment(req: Request): string {
  const url = new URL(req.url)
  const pathParts = url.pathname.split('/')
  // Edge function URLs: /analytics-pipeline/ingest, /analytics-pipeline/health, etc.
  // The last segment is the route
  return pathParts[pathParts.length - 1] || ''
}

// ============================================================================
// ROUTE: POST /ingest
// ============================================================================
// Accepts a batch of analytics events, inserts them, and enriches each one.
// Expects JSON body: { events: [{ event_name, user_id, properties?, session_id?, timestamp? }] }

async function handleIngest(req: Request): Promise<Response> {
  let body: IngestRequest

  try {
    body = await req.json() as IngestRequest
  } catch {
    return errorResponse('Invalid JSON body')
  }

  // Validate events array
  if (!body.events || !Array.isArray(body.events)) {
    return errorResponse('Request body must contain an "events" array')
  }

  if (body.events.length === 0) {
    return errorResponse('Events array cannot be empty')
  }

  if (body.events.length > MAX_BATCH_SIZE) {
    return errorResponse(`Batch size exceeds maximum of ${MAX_BATCH_SIZE} events`)
  }

  // Validate each event
  const validationErrors: string[] = []
  for (let i = 0; i < body.events.length; i++) {
    const event = body.events[i]
    if (!event.event_name || typeof event.event_name !== 'string') {
      validationErrors.push(`Event[${i}]: event_name is required and must be a string`)
    }
    if (!event.user_id || typeof event.user_id !== 'string') {
      validationErrors.push(`Event[${i}]: user_id is required and must be a string`)
    }
    if (event.timestamp && !isValidTimestamp(event.timestamp)) {
      validationErrors.push(`Event[${i}]: timestamp must be a valid ISO 8601 date string`)
    }
  }

  if (validationErrors.length > 0) {
    return jsonResponse({
      success: false,
      error: 'Validation failed',
      validation_errors: validationErrors,
    }, 400)
  }

  const supabase = createServiceClient()
  const result: IngestResult = {
    inserted: 0,
    enriched: 0,
    failed: 0,
    errors: [],
  }

  const now = new Date().toISOString()

  // Prepare rows for batch insert
  const rows = body.events.map((event) => ({
    event_name: event.event_name,
    user_id: event.user_id,
    properties: event.properties || {},
    session_id: event.session_id || null,
    timestamp: event.timestamp || now,
    received_at: now,
    processed: false,
  }))

  // Batch insert all events
  const { data: insertedEvents, error: insertError } = await supabase
    .from('analytics_events')
    .insert(rows)
    .select('id')

  if (insertError) {
    console.error('[analytics-pipeline] Batch insert error:', insertError)
    return jsonResponse({
      success: false,
      error: 'Failed to insert events',
      details: insertError.message,
    }, 500)
  }

  result.inserted = insertedEvents?.length || 0
  console.log(`[analytics-pipeline] Inserted ${result.inserted} events`)

  // Enrich each inserted event
  if (insertedEvents && insertedEvents.length > 0) {
    for (const event of insertedEvents) {
      try {
        const { error: enrichError } = await supabase
          .rpc('enrich_analytics_event', { p_event_id: event.id })

        if (enrichError) {
          console.error(`[analytics-pipeline] Enrichment error for ${event.id}:`, enrichError)
          result.failed++
          result.errors.push(`Failed to enrich event ${event.id}: ${enrichError.message}`)
        } else {
          result.enriched++
        }
      } catch (err) {
        const errMsg = err instanceof Error ? err.message : String(err)
        console.error(`[analytics-pipeline] Enrichment exception for ${event.id}:`, errMsg)
        result.failed++
        result.errors.push(`Exception enriching event ${event.id}: ${errMsg}`)
      }
    }
  }

  console.log(`[analytics-pipeline] Ingest complete: ${result.inserted} inserted, ${result.enriched} enriched, ${result.failed} failed`)

  return jsonResponse({
    success: true,
    data: result,
  })
}

// ============================================================================
// ROUTE: GET /health
// ============================================================================
// Returns pipeline health metrics by calling the get_pipeline_health() RPC.

async function handleHealth(): Promise<Response> {
  const supabase = createServiceClient()

  const { data, error } = await supabase
    .rpc('get_pipeline_health')

  if (error) {
    console.error('[analytics-pipeline] Health check error:', error)
    return jsonResponse({
      success: false,
      error: 'Failed to retrieve pipeline health',
      details: error.message,
    }, 500)
  }

  const health = data as PipelineHealth

  // Determine overall status based on metrics
  let overallStatus: 'healthy' | 'degraded' | 'unhealthy' = 'healthy'

  if (health.error_rate > 0.1) {
    overallStatus = 'unhealthy'
  } else if (health.error_rate > 0.05 || health.unprocessed_event_count > 1000) {
    overallStatus = 'degraded'
  }

  // Check if pipeline has not run recently (more than 1 hour)
  if (health.last_run_at) {
    const lastRunAge = Date.now() - new Date(health.last_run_at).getTime()
    const oneHourMs = 60 * 60 * 1000
    if (lastRunAge > oneHourMs && health.unprocessed_event_count > 0) {
      overallStatus = 'degraded'
    }
  }

  return jsonResponse({
    success: true,
    status: overallStatus,
    data: health,
  })
}

// ============================================================================
// ROUTE: POST /backfill
// ============================================================================
// Triggers enrichment of unprocessed events. Optionally accepts a limit.
// Expects JSON body: { limit?: number } (defaults to 1000)

async function handleBackfill(req: Request): Promise<Response> {
  let limit = DEFAULT_BACKFILL_LIMIT

  try {
    const body = await req.json() as BackfillRequest
    if (body.limit && typeof body.limit === 'number' && body.limit > 0) {
      limit = Math.min(body.limit, 5000) // Hard cap at 5000 per backfill run
    }
  } catch {
    // No body or invalid JSON is fine; use default limit
  }

  const supabase = createServiceClient()

  // Create a pipeline run record
  const { data: pipelineRun, error: runError } = await supabase
    .from('analytics_pipeline_status')
    .insert({
      status: 'running',
      events_processed: 0,
      events_failed: 0,
    })
    .select('id')
    .single()

  if (runError || !pipelineRun) {
    console.error('[analytics-pipeline] Failed to create pipeline run:', runError)
    return jsonResponse({
      success: false,
      error: 'Failed to initialize pipeline run',
      details: runError?.message,
    }, 500)
  }

  const pipelineRunId = pipelineRun.id
  console.log(`[analytics-pipeline] Starting backfill run ${pipelineRunId}, limit: ${limit}`)

  // Fetch unprocessed events
  const { data: unprocessedEvents, error: fetchError } = await supabase
    .from('analytics_events')
    .select('id')
    .eq('processed', false)
    .order('received_at', { ascending: true })
    .limit(limit)

  if (fetchError) {
    console.error('[analytics-pipeline] Failed to fetch unprocessed events:', fetchError)

    await supabase
      .from('analytics_pipeline_status')
      .update({
        status: 'failed',
        error_message: `Failed to fetch unprocessed events: ${fetchError.message}`,
      })
      .eq('id', pipelineRunId)

    return jsonResponse({
      success: false,
      error: 'Failed to fetch unprocessed events',
      details: fetchError.message,
      pipeline_run_id: pipelineRunId,
    }, 500)
  }

  const events = unprocessedEvents || []
  console.log(`[analytics-pipeline] Found ${events.length} unprocessed events to backfill`)

  const result: BackfillResult = {
    processed: 0,
    failed: 0,
    errors: [],
    pipeline_run_id: pipelineRunId,
  }

  // Process each event
  for (const event of events) {
    try {
      const { error: enrichError } = await supabase
        .rpc('enrich_analytics_event', { p_event_id: event.id })

      if (enrichError) {
        console.error(`[analytics-pipeline] Backfill enrichment error for ${event.id}:`, enrichError)
        result.failed++
        if (result.errors.length < 50) {
          result.errors.push(`Event ${event.id}: ${enrichError.message}`)
        }
      } else {
        result.processed++
      }
    } catch (err) {
      const errMsg = err instanceof Error ? err.message : String(err)
      console.error(`[analytics-pipeline] Backfill exception for ${event.id}:`, errMsg)
      result.failed++
      if (result.errors.length < 50) {
        result.errors.push(`Event ${event.id}: ${errMsg}`)
      }
    }
  }

  // Update pipeline run record
  const finalStatus = result.failed === 0
    ? 'completed'
    : result.processed === 0
      ? 'failed'
      : 'partial'

  const { error: updateError } = await supabase
    .from('analytics_pipeline_status')
    .update({
      events_processed: result.processed,
      events_failed: result.failed,
      status: finalStatus,
      error_message: result.errors.length > 0
        ? `${result.errors.length} errors. First: ${result.errors[0]}`
        : null,
    })
    .eq('id', pipelineRunId)

  if (updateError) {
    console.error('[analytics-pipeline] Failed to update pipeline run:', updateError)
  }

  console.log(`[analytics-pipeline] Backfill run ${pipelineRunId} complete: ${result.processed} processed, ${result.failed} failed`)

  return jsonResponse({
    success: true,
    data: result,
  })
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const route = getPathSegment(req)

    // Route: POST /ingest
    if (route === 'ingest' && req.method === 'POST') {
      return await handleIngest(req)
    }

    // Route: GET /health
    if (route === 'health' && req.method === 'GET') {
      return await handleHealth()
    }

    // Route: POST /backfill
    if (route === 'backfill' && req.method === 'POST') {
      return await handleBackfill(req)
    }

    // Default: return function info on root GET
    if ((route === 'analytics-pipeline' || route === '') && req.method === 'GET') {
      return jsonResponse({
        function: 'analytics-pipeline',
        version: '1.0.0',
        ticket: 'ACP-962',
        endpoints: [
          { method: 'POST', path: '/ingest', description: 'Ingest a batch of analytics events' },
          { method: 'GET', path: '/health', description: 'Get pipeline health metrics' },
          { method: 'POST', path: '/backfill', description: 'Trigger enrichment of unprocessed events' },
        ],
      })
    }

    // Unknown route
    return errorResponse(`Unknown route: ${req.method} /${route}`, 404)

  } catch (error) {
    console.error('[analytics-pipeline] Unhandled error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return jsonResponse({
      success: false,
      error: errorMessage,
    }, 500)
  }
})
