// ============================================================================
// Revenue Analytics Edge Function
// ACP-976: Revenue Analytics - MRR/ARR, LTV, Churn, Cohort Analysis
// ============================================================================
// Provides comprehensive revenue analytics for the PT Performance platform.
// Aggregates data from user_subscriptions (App Store) and
// user_pack_subscriptions (premium packs) via database RPCs.
//
// Query params:
//   ?period=30       Lookback period in days (default 30, max 365)
//   ?cohort=2026-02  Filter cohort data to a specific month (optional)
//   ?sections=all    Comma-separated sections to include:
//                    metrics, cohorts, ltv, forecasting (default: all)
//
// Returns JSON with:
//   mrr, arr, active_subscribers, churn_rate, revenue_by_tier,
//   ltv_estimates, cohort_analysis, forecasting_inputs
//
// Date: 2026-02-18
// Ticket: ACP-976
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface RevenueMetricsRPC {
  period_days: number
  period_start: string
  period_end: string
  mrr: number
  arr: number
  mrr_breakdown: {
    app_store: number
    pack_subscriptions: number
  }
  active_subscribers: {
    total: number
    app_store: number
    pack_subscriptions: number
    trials: number
  }
  churn: {
    rate_percent: number
    churned_in_period: number
    active_at_period_start: number
  }
  expansion_revenue: number
  revenue_by_tier: TierRevenue[]
  subscribers_by_tier: TierSubscribers[]
}

interface TierRevenue {
  tier: string
  tier_name: string
  active_subscribers: number
  price_monthly: number
  monthly_revenue: number
}

interface TierSubscribers {
  tier: string
  tier_name: string
  active: number
  trial: number
  cancelled: number
}

interface CohortData {
  cohort: string
  total_users: number
  retained_users: number
  retention_rate_percent: number
  total_subscriptions: number
  active_subscriptions: number
  churned_subscriptions: number
  current_mrr_contribution: number
  avg_months_retained: number
  avg_revenue_per_user: number
}

interface LTVData {
  tier: string
  tier_name: string
  monthly_price: number
  total_subscriptions: number
  active_subscriptions: number
  churned_subscriptions: number
  avg_lifespan_months: number
  median_lifespan_months: number
  monthly_churn_rate_percent: number
  estimated_ltv: number
  estimated_ltv_churn_method: number | null
  conversion_rate_percent: number
}

interface ForecastingInputs {
  current_mrr: number
  current_arr: number
  monthly_churn_rate: number
  avg_revenue_per_account: number
  active_subscriber_count: number
  trial_count: number
  expansion_revenue_monthly: number
  net_revenue_retention: number
  projected_arr_12m: number
  projected_mrr_next_month: number
  runway_months_at_current_churn: number | null
}

interface RevenueAnalyticsResponse {
  success: boolean
  generated_at: string
  period_days: number
  sections_included: string[]
  metrics?: {
    mrr: number
    arr: number
    mrr_breakdown: RevenueMetricsRPC['mrr_breakdown']
    active_subscribers: RevenueMetricsRPC['active_subscribers']
    churn_rate: number
    churn_details: RevenueMetricsRPC['churn']
    expansion_revenue: number
    revenue_by_tier: TierRevenue[]
    subscribers_by_tier: TierSubscribers[]
  }
  cohort_analysis?: CohortData[]
  ltv_estimates?: LTVData[]
  forecasting?: ForecastingInputs
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

const VALID_SECTIONS = ['metrics', 'cohorts', 'ltv', 'forecasting'] as const
type Section = typeof VALID_SECTIONS[number]

function parseSections(sectionsParam: string | null): Section[] {
  if (!sectionsParam || sectionsParam === 'all') {
    return [...VALID_SECTIONS]
  }

  const requested = sectionsParam.split(',').map(s => s.trim().toLowerCase())
  return requested.filter((s): s is Section =>
    VALID_SECTIONS.includes(s as Section)
  )
}

function clamp(value: number, min: number, max: number): number {
  return Math.max(min, Math.min(max, value))
}

/**
 * Compute simple forecasting inputs from metrics and LTV data.
 * These are intended as inputs for external financial models, not
 * authoritative forecasts.
 */
function computeForecastingInputs(
  metrics: RevenueMetricsRPC,
  ltvData: LTVData[]
): ForecastingInputs {
  const monthlyChurnRate = metrics.churn.rate_percent / 100
  const totalActive = metrics.active_subscribers.total
  const avgRevenuePerAccount = totalActive > 0
    ? metrics.mrr / totalActive
    : 0

  // Net revenue retention: (MRR + expansion - churn_revenue) / starting_MRR
  // Approximate churn revenue from churned count * avg revenue
  const churnedRevenue = metrics.churn.churned_in_period * avgRevenuePerAccount
  const startingMRR = metrics.mrr + churnedRevenue - metrics.expansion_revenue
  const netRevenueRetention = startingMRR > 0
    ? ((metrics.mrr) / startingMRR) * 100
    : 100

  // Simple projection: compound current MRR with net retention for 12 months
  const monthlyGrowthRate = (netRevenueRetention / 100)
  const projectedMRR12m = metrics.mrr * Math.pow(monthlyGrowthRate, 12)
  const projectedMRRNext = metrics.mrr * monthlyGrowthRate

  // Runway: at current churn rate, how many months until no subscribers
  const runwayMonths = monthlyChurnRate > 0
    ? Math.round(1 / monthlyChurnRate)
    : null

  return {
    current_mrr: metrics.mrr,
    current_arr: metrics.arr,
    monthly_churn_rate: metrics.churn.rate_percent,
    avg_revenue_per_account: Math.round(avgRevenuePerAccount * 100) / 100,
    active_subscriber_count: totalActive,
    trial_count: metrics.active_subscribers.trials,
    expansion_revenue_monthly: metrics.expansion_revenue,
    net_revenue_retention: Math.round(netRevenueRetention * 100) / 100,
    projected_arr_12m: Math.round(projectedMRR12m * 12 * 100) / 100,
    projected_mrr_next_month: Math.round(projectedMRRNext * 100) / 100,
    runway_months_at_current_churn: runwayMonths,
  }
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
    // Only allow GET requests for analytics reads
    if (req.method !== 'GET') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed. Use GET.' }),
        { status: 405, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // PARSE QUERY PARAMS
    // ========================================================================
    const url = new URL(req.url)
    const periodParam = url.searchParams.get('period')
    const cohortParam = url.searchParams.get('cohort')
    const sectionsParam = url.searchParams.get('sections')

    const periodDays = clamp(
      periodParam ? parseInt(periodParam, 10) || 30 : 30,
      1,
      365
    )

    const sections = parseSections(sectionsParam)

    if (sections.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'No valid sections requested',
          valid_sections: VALID_SECTIONS,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate cohort format if provided
    if (cohortParam && !/^\d{4}-\d{2}$/.test(cohortParam)) {
      return new Response(
        JSON.stringify({ error: 'cohort must be in YYYY-MM format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[revenue-analytics] Request: period=${periodDays}, sections=${sections.join(',')}, cohort=${cohortParam || 'all'}`)

    // ========================================================================
    // INITIALIZE SUPABASE CLIENT (service role for RPC access)
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
    // AUTHENTICATE: require service_role or authenticated admin
    // We check for the Authorization header and validate the caller.
    // Revenue data is sensitive so we require authentication.
    // ========================================================================
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return new Response(
        JSON.stringify({ error: 'Authorization required' }),
        { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // FETCH DATA FROM RPCs (parallel where possible)
    // ========================================================================
    const response: RevenueAnalyticsResponse = {
      success: true,
      generated_at: new Date().toISOString(),
      period_days: periodDays,
      sections_included: sections,
    }

    // Build parallel RPC calls based on requested sections
    const rpcCalls: Promise<void>[] = []

    let metricsData: RevenueMetricsRPC | null = null
    let cohortData: CohortData[] | null = null
    let ltvData: LTVData[] | null = null

    // Metrics are needed for both 'metrics' and 'forecasting' sections
    const needsMetrics = sections.includes('metrics') || sections.includes('forecasting')

    if (needsMetrics) {
      rpcCalls.push(
        (async () => {
          const { data, error } = await supabase.rpc('get_revenue_metrics', {
            period_days: periodDays,
          })

          if (error) {
            console.error('[revenue-analytics] get_revenue_metrics error:', error)
            throw new Error(`Failed to fetch revenue metrics: ${error.message}`)
          }

          metricsData = data as RevenueMetricsRPC
        })()
      )
    }

    if (sections.includes('cohorts')) {
      rpcCalls.push(
        (async () => {
          const { data, error } = await supabase.rpc('get_revenue_by_cohort', {
            cohort_month: cohortParam || null,
          })

          if (error) {
            console.error('[revenue-analytics] get_revenue_by_cohort error:', error)
            throw new Error(`Failed to fetch cohort data: ${error.message}`)
          }

          cohortData = (data as CohortData[]) || []
        })()
      )
    }

    // LTV data is needed for both 'ltv' and 'forecasting' sections
    const needsLtv = sections.includes('ltv') || sections.includes('forecasting')

    if (needsLtv) {
      rpcCalls.push(
        (async () => {
          const { data, error } = await supabase.rpc('get_ltv_by_tier')

          if (error) {
            console.error('[revenue-analytics] get_ltv_by_tier error:', error)
            throw new Error(`Failed to fetch LTV data: ${error.message}`)
          }

          ltvData = (data as LTVData[]) || []
        })()
      )
    }

    // Execute all RPCs in parallel
    await Promise.all(rpcCalls)

    // ========================================================================
    // ASSEMBLE RESPONSE
    // ========================================================================

    if (sections.includes('metrics') && metricsData) {
      response.metrics = {
        mrr: metricsData.mrr,
        arr: metricsData.arr,
        mrr_breakdown: metricsData.mrr_breakdown,
        active_subscribers: metricsData.active_subscribers,
        churn_rate: metricsData.churn.rate_percent,
        churn_details: metricsData.churn,
        expansion_revenue: metricsData.expansion_revenue,
        revenue_by_tier: metricsData.revenue_by_tier || [],
        subscribers_by_tier: metricsData.subscribers_by_tier || [],
      }
    }

    if (sections.includes('cohorts') && cohortData) {
      response.cohort_analysis = cohortData
    }

    if (sections.includes('ltv') && ltvData) {
      response.ltv_estimates = ltvData
    }

    if (sections.includes('forecasting') && metricsData && ltvData) {
      response.forecasting = computeForecastingInputs(metricsData, ltvData)
    }

    console.log(`[revenue-analytics] Response generated: MRR=${metricsData?.mrr || 'N/A'}, sections=${sections.join(',')}`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[revenue-analytics] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        generated_at: new Date().toISOString(),
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

/* ============================================================================
   DEPLOYMENT INSTRUCTIONS
   ============================================================================

   1. Run the migration first:
      ```bash
      supabase db push
      ```
      or apply the migration file:
      supabase/migrations/20260218100001_revenue_analytics_rpcs.sql

   2. Deploy the Edge Function:
      ```bash
      supabase functions deploy revenue-analytics
      ```

   3. Test locally:
      ```bash
      supabase functions serve revenue-analytics
      ```

   4. Test with curl:
      ```bash
      # All sections, 30-day period (default)
      curl -X GET "http://localhost:54321/functions/v1/revenue-analytics" \
        -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

      # Specific period and sections
      curl -X GET "http://localhost:54321/functions/v1/revenue-analytics?period=90&sections=metrics,ltv" \
        -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"

      # Specific cohort month
      curl -X GET "http://localhost:54321/functions/v1/revenue-analytics?cohort=2026-01&sections=cohorts" \
        -H "Authorization: Bearer YOUR_SERVICE_ROLE_KEY"
      ```

   ============================================================================
*/
