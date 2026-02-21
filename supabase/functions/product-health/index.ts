// ============================================================================
// Product Health Metrics Edge Function
// ACP-975: Product health dashboard - feature adoption, satisfaction, safety
// ============================================================================
// GET ?period=30 returns the product health dashboard JSON
//
// Calls the get_product_health(period_days) RPC which aggregates:
// - Engagement: DAU/WAU/MAU counts and trends
// - Feature adoption: sessions, manual_workouts, readiness, streaks, ai_chat
// - Satisfaction: average app_feedback rating, NPS proxy
// - Safety: open incident count by severity
// - Subscription health: trials, conversions, cancellations, churn
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only allow GET and POST requests
  if (req.method !== 'GET' && req.method !== 'POST') {
    return new Response(
      JSON.stringify({ error: 'Method not allowed', message: 'Use GET with ?period=30 or POST with JSON body' }),
      { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }

  try {
    // ========================================================================
    // AUTHENTICATION
    // ========================================================================
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized', message: 'Valid authentication required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // PARSE PARAMETERS (GET: query string, POST: JSON body)
    // ========================================================================
    let periodParam: string | null = null

    if (req.method === 'POST') {
      const body = await req.json()
      periodParam = body.period != null ? String(body.period) : null
    } else {
      const url = new URL(req.url)
      periodParam = url.searchParams.get('period')
    }
    let periodDays = 30

    if (periodParam !== null) {
      const parsed = parseInt(periodParam, 10)
      if (isNaN(parsed) || parsed < 1 || parsed > 365) {
        return new Response(
          JSON.stringify({
            error: 'Invalid period parameter',
            message: 'period must be an integer between 1 and 365',
          }),
          { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
      periodDays = parsed
    }

    console.log(`[product-health] Fetching product health metrics for ${periodDays} day period`)

    // ========================================================================
    // INITIALIZE SUPABASE CLIENT
    // ========================================================================
    // Use service role key to bypass RLS - this is an admin/internal dashboard query
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // CALL RPC
    // ========================================================================
    const { data, error } = await supabaseClient.rpc('get_product_health', {
      period_days: periodDays,
    })

    if (error) {
      console.error('[product-health] RPC error:', error)
      return new Response(
        JSON.stringify({
          error: 'Failed to fetch product health metrics',
          details: error.message,
          code: error.code,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[product-health] Successfully fetched metrics for ${periodDays} day period`)

    // ========================================================================
    // RETURN RESPONSE
    // ========================================================================
    return new Response(
      JSON.stringify(data),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'private, max-age=300', // Cache for 5 minutes
        },
      }
    )

  } catch (error) {
    console.error('[product-health] Unexpected error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({ error: errorMessage }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
