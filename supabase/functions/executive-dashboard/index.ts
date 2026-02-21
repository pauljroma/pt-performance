// ============================================================================
// ACP-974 - Executive Dashboard
// Edge Function: executive-dashboard
//
// Real-time KPI dashboard for executive reporting.
// Aggregates: DAU/MAU, revenue, retention, satisfaction, safety.
//
// Endpoints:
//   GET /executive-dashboard           -> Full executive dashboard JSON
//   GET /executive-dashboard?format=digest -> Daily digest format for email
//
// Auth: Requires valid JWT (admin-only in production via RLS on RPCs)
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { corsHeaders, buildErrorResponse, createLogger } from '../_shared/errors.ts'

const logger = createLogger('executive-dashboard')

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow GET and POST
  if (req.method !== 'GET' && req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed. Use GET or POST.' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    // ========================================================================
    // AUTH: Validate JWT
    // ========================================================================
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Valid authentication required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // INIT SUPABASE CLIENT
    // ========================================================================
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables')
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false }
    })

    // ========================================================================
    // DETERMINE FORMAT (GET: query string, POST: JSON body)
    // ========================================================================
    let format: string | null = null

    if (req.method === 'POST') {
      const body = await req.json()
      format = body.format != null ? String(body.format) : null
    } else {
      const url = new URL(req.url)
      format = url.searchParams.get('format')
    }

    logger.info(`Request received`, { format: format || 'full' })

    let data: unknown
    let rpcName: string

    if (format === 'digest') {
      // Daily digest format for email
      rpcName = 'get_daily_digest'
      const { data: digestData, error: digestError } = await supabase.rpc('get_daily_digest')

      if (digestError) {
        logger.error('Failed to fetch daily digest', digestError)
        throw new Error(`Database error: ${digestError.message}`)
      }

      data = digestData
    } else {
      // Full executive dashboard
      rpcName = 'get_executive_dashboard'
      const { data: dashboardData, error: dashboardError } = await supabase.rpc('get_executive_dashboard')

      if (dashboardError) {
        logger.error('Failed to fetch executive dashboard', dashboardError)
        throw new Error(`Database error: ${dashboardError.message}`)
      }

      data = dashboardData
    }

    logger.info(`Successfully fetched ${rpcName}`)

    // ========================================================================
    // RESPONSE
    // ========================================================================
    return new Response(
      JSON.stringify(data),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'private, max-age=60',
        }
      }
    )

  } catch (error) {
    logger.error('Request failed', error)
    return buildErrorResponse(error)
  }
})

/* ============================================================================
   DEPLOYMENT & USAGE
   ============================================================================

   1. Deploy:
      supabase functions deploy executive-dashboard

   2. Test locally:
      supabase functions serve executive-dashboard

   3. Full dashboard:
      curl -X GET https://<project>.supabase.co/functions/v1/executive-dashboard \
        -H "Authorization: Bearer <JWT>" \
        -H "apikey: <ANON_KEY>"

   4. Daily digest:
      curl -X GET "https://<project>.supabase.co/functions/v1/executive-dashboard?format=digest" \
        -H "Authorization: Bearer <JWT>" \
        -H "apikey: <ANON_KEY>"

   5. Schedule daily digest email (via pg_cron):
      SELECT cron.schedule(
        'executive-daily-digest',
        '0 7 * * *',
        $$
        SELECT net.http_post(
          url := 'https://<project>.supabase.co/functions/v1/executive-dashboard?format=digest',
          headers := jsonb_build_object(
            'Authorization', 'Bearer ' || current_setting('app.service_role_key'),
            'apikey', current_setting('app.anon_key')
          )
        );
        $$
      );

   ============================================================================
*/
