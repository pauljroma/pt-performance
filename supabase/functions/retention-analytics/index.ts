// ============================================================================
// Retention Cohort Analysis Edge Function
// Health Intelligence Platform - User Retention & Churn Analytics
// ============================================================================
// Provides cohort-based retention analysis (D1/D7/D30/D90), identifies
// retention drivers from first-week feature usage, tracks resurrected users,
// and supplies churn prediction model inputs.
//
// Endpoints via query params:
//   GET ?months=6          — Full retention analysis (cohorts + drivers + resurrections)
//   GET ?type=cohorts      — Cohort retention matrix only
//   GET ?type=drivers      — Retention driver analysis only
//   GET ?type=resurrected  — Resurrected users only
//
// Date: 2026-02-18
// Ticket: ACP-969
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface CohortRow {
  cohort_month: string
  cohort_size: number
  d1_retention_pct: number | null
  d1_retained: number
  d7_retention_pct: number | null
  d7_retained: number
  d30_retention_pct: number | null
  d30_retained: number
  d90_retention_pct: number | null
  d90_retained: number
}

interface RetentionDriver {
  feature: string
  total_users: number
  users_with_feature: number
  users_without_feature: number
  retained_with_feature: number
  retained_without_feature: number
  retention_rate_with_pct: number
  retention_rate_without_pct: number
  lift_pct: number
}

interface ResurrectedUser {
  patient_id: string
  resurrected_at: string
  last_active_at: string
  inactive_days: number
  return_session_type: string
  signup_date: string
  days_since_signup: number
}

interface ChurnPredictionInputs {
  total_users_analyzed: number
  overall_d30_retention_pct: number
  highest_impact_feature: string | null
  highest_impact_lift_pct: number
  avg_inactive_days_before_resurrection: number
  resurrection_count: number
  cohort_trend: 'improving' | 'declining' | 'stable'
}

interface RetentionAnalyticsResponse {
  analysis_id: string
  generated_at: string
  months_analyzed: number
  cohorts: CohortRow[]
  drivers: RetentionDriver[]
  resurrected_users: ResurrectedUser[]
  churn_prediction_inputs: ChurnPredictionInputs
  summary: {
    total_cohort_users: number
    latest_cohort_d1_pct: number | null
    latest_cohort_d7_pct: number | null
    best_retention_month: string | null
    top_retention_driver: string | null
    total_resurrections: number
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function computeChurnInputs(
  cohorts: CohortRow[],
  drivers: RetentionDriver[],
  resurrected: ResurrectedUser[]
): ChurnPredictionInputs {
  // Overall D30 retention across all cohorts with data
  const cohortsWithD30 = cohorts.filter(c => c.d30_retention_pct !== null)
  const overallD30 = cohortsWithD30.length > 0
    ? Math.round(
        (cohortsWithD30.reduce((sum, c) => sum + (c.d30_retention_pct || 0), 0)
        / cohortsWithD30.length) * 10
      ) / 10
    : 0

  // Highest-impact feature (greatest lift)
  const sortedDrivers = [...drivers].sort((a, b) => b.lift_pct - a.lift_pct)
  const topDriver = sortedDrivers.length > 0 ? sortedDrivers[0] : null

  // Average inactive days before resurrection
  const avgInactiveDays = resurrected.length > 0
    ? Math.round(
        resurrected.reduce((sum, r) => sum + r.inactive_days, 0) / resurrected.length
      )
    : 0

  // Cohort trend: compare first half vs second half of D7 retention
  let cohortTrend: 'improving' | 'declining' | 'stable' = 'stable'
  const cohortsWithD7 = cohorts.filter(c => c.d7_retention_pct !== null)
  if (cohortsWithD7.length >= 4) {
    const midpoint = Math.floor(cohortsWithD7.length / 2)
    const firstHalf = cohortsWithD7.slice(0, midpoint)
    const secondHalf = cohortsWithD7.slice(midpoint)
    const firstAvg = firstHalf.reduce((s, c) => s + (c.d7_retention_pct || 0), 0) / firstHalf.length
    const secondAvg = secondHalf.reduce((s, c) => s + (c.d7_retention_pct || 0), 0) / secondHalf.length
    if (secondAvg > firstAvg + 5) cohortTrend = 'improving'
    else if (secondAvg < firstAvg - 5) cohortTrend = 'declining'
  }

  const totalUsersAnalyzed = cohorts.reduce((sum, c) => sum + c.cohort_size, 0)

  return {
    total_users_analyzed: totalUsersAnalyzed,
    overall_d30_retention_pct: overallD30,
    highest_impact_feature: topDriver?.feature || null,
    highest_impact_lift_pct: topDriver?.lift_pct || 0,
    avg_inactive_days_before_resurrection: avgInactiveDays,
    resurrection_count: resurrected.length,
    cohort_trend: cohortTrend,
  }
}

function buildSummary(
  cohorts: CohortRow[],
  drivers: RetentionDriver[],
  resurrected: ResurrectedUser[]
) {
  const totalUsers = cohorts.reduce((sum, c) => sum + c.cohort_size, 0)

  // Latest cohort with data
  const latestCohort = cohorts.length > 0 ? cohorts[cohorts.length - 1] : null

  // Best retention month (highest D7 retention)
  const cohortsWithD7 = cohorts.filter(c => c.d7_retention_pct !== null)
  let bestMonth: string | null = null
  if (cohortsWithD7.length > 0) {
    const best = cohortsWithD7.reduce((a, b) =>
      (a.d7_retention_pct || 0) > (b.d7_retention_pct || 0) ? a : b
    )
    bestMonth = best.cohort_month
  }

  // Top retention driver
  const sortedDrivers = [...drivers].sort((a, b) => b.lift_pct - a.lift_pct)
  const topDriver = sortedDrivers.length > 0 ? sortedDrivers[0].feature : null

  return {
    total_cohort_users: totalUsers,
    latest_cohort_d1_pct: latestCohort?.d1_retention_pct ?? null,
    latest_cohort_d7_pct: latestCohort?.d7_retention_pct ?? null,
    best_retention_month: bestMonth,
    top_retention_driver: topDriver,
    total_resurrections: resurrected.length,
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
    // Parse parameters (GET: query string, POST: JSON body)
    let monthsParam: string | null = null
    let typeParam: string | null = null
    let periodParam: string | null = null

    if (req.method === 'POST') {
      const body = await req.json()
      monthsParam = body.months != null ? String(body.months) : null
      typeParam = body.type != null ? String(body.type) : null
      periodParam = body.period != null ? String(body.period) : null
    } else {
      const url = new URL(req.url)
      monthsParam = url.searchParams.get('months')
      typeParam = url.searchParams.get('type')
      periodParam = url.searchParams.get('period')
    }

    // Validate months parameter
    const months = monthsParam ? parseInt(monthsParam, 10) : 6
    if (isNaN(months) || months < 1 || months > 24) {
      return new Response(
        JSON.stringify({ error: 'months must be between 1 and 24' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate period parameter for resurrected users
    const period = periodParam ? parseInt(periodParam, 10) : 30
    if (isNaN(period) || period < 7 || period > 365) {
      return new Response(
        JSON.stringify({ error: 'period must be between 7 and 365' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[retention-analytics] Request: type=${typeParam || 'all'}, months=${months}, period=${period}`)

    // Initialize Supabase client with service role for admin-level access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // FETCH DATA VIA RPC CALLS
    // ========================================================================

    let cohorts: CohortRow[] = []
    let drivers: RetentionDriver[] = []
    let resurrected: ResurrectedUser[] = []

    const fetchCohorts = !typeParam || typeParam === 'cohorts'
    const fetchDrivers = !typeParam || typeParam === 'drivers'
    const fetchResurrected = !typeParam || typeParam === 'resurrected'

    // Run applicable RPC calls in parallel
    const promises: Promise<void>[] = []

    if (fetchCohorts) {
      promises.push(
        (async () => {
          console.log(`[retention-analytics] Fetching cohorts for ${months} months back`)
          const { data, error } = await supabaseClient.rpc('get_retention_cohorts', {
            months_back: months,
          })
          if (error) {
            console.error('[retention-analytics] Error fetching cohorts:', error)
            throw new Error(`Failed to fetch retention cohorts: ${error.message}`)
          }
          cohorts = (data as CohortRow[]) || []
          console.log(`[retention-analytics] Fetched ${cohorts.length} cohorts`)
        })()
      )
    }

    if (fetchDrivers) {
      promises.push(
        (async () => {
          console.log('[retention-analytics] Fetching retention drivers')
          const { data, error } = await supabaseClient.rpc('get_retention_drivers')
          if (error) {
            console.error('[retention-analytics] Error fetching drivers:', error)
            throw new Error(`Failed to fetch retention drivers: ${error.message}`)
          }
          drivers = (data as RetentionDriver[]) || []
          console.log(`[retention-analytics] Fetched ${drivers.length} driver features`)
        })()
      )
    }

    if (fetchResurrected) {
      promises.push(
        (async () => {
          console.log(`[retention-analytics] Fetching resurrected users (gap >= ${period} days)`)
          const { data, error } = await supabaseClient.rpc('get_resurrected_users', {
            period_days: period,
          })
          if (error) {
            console.error('[retention-analytics] Error fetching resurrected users:', error)
            throw new Error(`Failed to fetch resurrected users: ${error.message}`)
          }
          resurrected = (data as ResurrectedUser[]) || []
          console.log(`[retention-analytics] Fetched ${resurrected.length} resurrection events`)
        })()
      )
    }

    await Promise.all(promises)

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================

    const churnInputs = computeChurnInputs(cohorts, drivers, resurrected)
    const summary = buildSummary(cohorts, drivers, resurrected)

    const response: RetentionAnalyticsResponse = {
      analysis_id: crypto.randomUUID(),
      generated_at: new Date().toISOString(),
      months_analyzed: months,
      cohorts,
      drivers,
      resurrected_users: resurrected,
      churn_prediction_inputs: churnInputs,
      summary,
    }

    console.log(`[retention-analytics] Analysis complete: ${cohorts.length} cohorts, ${drivers.length} drivers, ${resurrected.length} resurrections`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[retention-analytics] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        details: 'Retention analytics encountered an error. Please try again.',
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
