// ============================================================================
// Training Outcome Analytics Edge Function
// ACP-981: Correlate training inputs with outcomes
// ============================================================================
// Provides two endpoints:
//   GET ?patient_id=UUID&period=90  - Individual training outcomes
//   GET ?aggregate=true             - Program effectiveness rankings
//
// Leverages database RPCs:
//   - get_training_outcomes(p_patient_id, period_days)
//   - get_program_effectiveness()
//
// Date: 2026-02-18
// Ticket: ACP-981
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function jsonResponse(data: unknown, status = 200): Response {
  return new Response(
    JSON.stringify(data),
    {
      status,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  )
}

function errorResponse(message: string, status = 400): Response {
  return jsonResponse({ success: false, error: message }, status)
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept GET and POST requests
  if (req.method !== 'GET' && req.method !== 'POST') {
    return errorResponse('Method not allowed. Use GET or POST.', 405)
  }

  try {
    // Parse parameters (GET: query string, POST: JSON body)
    let patientId: string | null = null
    let periodParam: string | null = null
    let aggregateParam: string | null = null

    if (req.method === 'POST') {
      const body = await req.json()
      patientId = body.patient_id != null ? String(body.patient_id) : null
      periodParam = body.period != null ? String(body.period) : null
      aggregateParam = body.aggregate != null ? String(body.aggregate) : null
    } else {
      const url = new URL(req.url)
      patientId = url.searchParams.get('patient_id')
      periodParam = url.searchParams.get('period')
      aggregateParam = url.searchParams.get('aggregate')
    }

    // Validate the Authorization header
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse('Missing or invalid Authorization header', 401)
    }

    // Initialize Supabase client with service role for RPC calls
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      console.error('[training-outcomes] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY')
      return errorResponse('Server configuration error', 500)
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey, {
      auth: { persistSession: false },
    })

    // ======================================================================
    // ROUTE: Program Effectiveness Rankings (aggregate=true)
    // ======================================================================
    if (aggregateParam === 'true') {
      console.log('[training-outcomes] Fetching program effectiveness rankings')

      const { data, error } = await supabase.rpc('get_program_effectiveness')

      if (error) {
        console.error('[training-outcomes] RPC error (get_program_effectiveness):', error)
        return errorResponse(`Database error: ${error.message}`, 500)
      }

      console.log(
        '[training-outcomes] Program effectiveness returned:',
        data?.programs?.length ?? 0,
        'programs'
      )

      return jsonResponse({
        success: true,
        type: 'program_effectiveness',
        ...data,
      })
    }

    // ======================================================================
    // ROUTE: Individual Training Outcomes (patient_id required)
    // ======================================================================
    if (!patientId) {
      return errorResponse(
        'Missing required parameter: patient_id. Use ?patient_id=UUID&period=90 for individual outcomes or ?aggregate=true for program rankings.'
      )
    }

    if (!isValidUUID(patientId)) {
      return errorResponse('Invalid patient_id format. Must be a valid UUID.')
    }

    // Parse and validate period
    const period = periodParam ? parseInt(periodParam, 10) : 90
    if (isNaN(period) || period < 7 || period > 365) {
      return errorResponse('Invalid period. Must be an integer between 7 and 365.')
    }

    console.log(
      `[training-outcomes] Fetching outcomes for patient ${patientId}, period ${period} days`
    )

    const { data, error } = await supabase.rpc('get_training_outcomes', {
      p_patient_id: patientId,
      period_days: period,
    })

    if (error) {
      console.error('[training-outcomes] RPC error (get_training_outcomes):', error)
      return errorResponse(`Database error: ${error.message}`, 500)
    }

    // Check for application-level errors from the RPC
    if (data && data.error) {
      return errorResponse(data.error, 404)
    }

    // Compute summary statistics for the response
    const summary = computeSummary(data)

    console.log(
      `[training-outcomes] Results: ${data?.strength_gains?.length ?? 0} exercises with strength data, ` +
      `${data?.volume_progression?.length ?? 0} weeks of volume data`
    )

    return jsonResponse({
      success: true,
      type: 'individual_outcomes',
      summary,
      data,
    })

  } catch (error) {
    console.error('[training-outcomes] Unexpected error:', error)

    const message = error instanceof Error ? error.message : 'Internal server error'
    return errorResponse(message, 500)
  }
})

// ============================================================================
// SUMMARY COMPUTATION
// ============================================================================

interface StrengthGain {
  exercise_name: string
  start_load: number
  current_load: number
  pct_change: number
  data_points: number
}

interface WeeklyVolume {
  week_start: string
  total_volume: number
  log_count: number
}

interface WeeklyPain {
  week_start: string
  avg_pain: number
  sample_count: number
}

interface WeeklyAdherence {
  week_start: string
  sessions_completed: number
  sessions_scheduled: number
  adherence_pct: number
}

interface TrainingOutcomes {
  volume_progression: WeeklyVolume[]
  strength_gains: StrengthGain[]
  pain_trend: WeeklyPain[]
  adherence: WeeklyAdherence[]
  recovery_correlation: Record<string, unknown>
}

interface OutcomeSummary {
  total_exercises_tracked: number
  exercises_with_gains: number
  avg_strength_gain_pct: number | null
  best_strength_gain: StrengthGain | null
  volume_trend: 'increasing' | 'decreasing' | 'stable' | 'insufficient_data'
  pain_trend: 'improving' | 'worsening' | 'stable' | 'insufficient_data'
  overall_adherence_pct: number | null
  weeks_of_data: number
}

function computeSummary(data: TrainingOutcomes | null): OutcomeSummary {
  if (!data) {
    return {
      total_exercises_tracked: 0,
      exercises_with_gains: 0,
      avg_strength_gain_pct: null,
      best_strength_gain: null,
      volume_trend: 'insufficient_data',
      pain_trend: 'insufficient_data',
      overall_adherence_pct: null,
      weeks_of_data: 0,
    }
  }

  const strengthGains = data.strength_gains || []
  const volumeProgression = data.volume_progression || []
  const painTrend = data.pain_trend || []
  const adherence = data.adherence || []

  // Strength summary
  const exercisesWithGains = strengthGains.filter(
    (sg: StrengthGain) => sg.pct_change > 0
  )
  const avgGain = strengthGains.length > 0
    ? Math.round(
        (strengthGains.reduce((sum: number, sg: StrengthGain) => sum + sg.pct_change, 0) /
          strengthGains.length) * 10
      ) / 10
    : null

  const bestGain = strengthGains.length > 0
    ? strengthGains.reduce(
        (best: StrengthGain, sg: StrengthGain) =>
          sg.pct_change > best.pct_change ? sg : best,
        strengthGains[0]
      )
    : null

  // Volume trend (compare first half average to second half average)
  let volumeTrend: OutcomeSummary['volume_trend'] = 'insufficient_data'
  if (volumeProgression.length >= 4) {
    const mid = Math.floor(volumeProgression.length / 2)
    const firstHalf = volumeProgression.slice(0, mid)
    const secondHalf = volumeProgression.slice(mid)
    const firstAvg =
      firstHalf.reduce((s: number, w: WeeklyVolume) => s + w.total_volume, 0) / firstHalf.length
    const secondAvg =
      secondHalf.reduce((s: number, w: WeeklyVolume) => s + w.total_volume, 0) / secondHalf.length

    const changePct = firstAvg > 0 ? ((secondAvg - firstAvg) / firstAvg) * 100 : 0
    if (changePct > 10) volumeTrend = 'increasing'
    else if (changePct < -10) volumeTrend = 'decreasing'
    else volumeTrend = 'stable'
  }

  // Pain trend (compare first half to second half -- lower is better)
  let painTrendResult: OutcomeSummary['pain_trend'] = 'insufficient_data'
  if (painTrend.length >= 4) {
    const mid = Math.floor(painTrend.length / 2)
    const firstHalf = painTrend.slice(0, mid)
    const secondHalf = painTrend.slice(mid)
    const firstAvg =
      firstHalf.reduce((s: number, w: WeeklyPain) => s + w.avg_pain, 0) / firstHalf.length
    const secondAvg =
      secondHalf.reduce((s: number, w: WeeklyPain) => s + w.avg_pain, 0) / secondHalf.length

    if (secondAvg < firstAvg - 0.3) painTrendResult = 'improving'
    else if (secondAvg > firstAvg + 0.3) painTrendResult = 'worsening'
    else painTrendResult = 'stable'
  }

  // Overall adherence
  const totalCompleted = adherence.reduce(
    (s: number, w: WeeklyAdherence) => s + w.sessions_completed, 0
  )
  const totalScheduled = adherence.reduce(
    (s: number, w: WeeklyAdherence) => s + w.sessions_scheduled, 0
  )
  const overallAdherence = totalScheduled > 0
    ? Math.round((totalCompleted / totalScheduled) * 1000) / 10
    : null

  return {
    total_exercises_tracked: strengthGains.length,
    exercises_with_gains: exercisesWithGains.length,
    avg_strength_gain_pct: avgGain,
    best_strength_gain: bestGain,
    volume_trend: volumeTrend,
    pain_trend: painTrendResult,
    overall_adherence_pct: overallAdherence,
    weeks_of_data: volumeProgression.length,
  }
}
