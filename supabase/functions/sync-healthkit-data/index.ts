// Sync HealthKit Data Handler
// ACP-474 - HealthKit to Supabase Sync
// Receives aggregated HealthKit data pushed from iOS app and stores in readiness_metrics
// Unlike WHOOP (server-side OAuth pull), HealthKit data lives on-device so iOS pushes here

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireAuth, createAuthenticatedClient, verifyPatientOwnership, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const CACHE_DURATION_HOURS = 1 // Don't sync more than once per hour per day

// Input shape from iOS app (matches HealthKitDayData structure)
interface HealthKitPayload {
  patient_id: string
  recorded_at: string  // ISO8601
  metric_date: string  // yyyy-MM-dd
  hrv_ms: number | null
  resting_heart_rate: number | null
  sleep_hours: number | null
  deep_sleep_minutes: number | null
  rem_sleep_minutes: number | null
  light_sleep_minutes: number | null
  active_energy_kcal: number | null
  steps: number | null
  workout_minutes: number | null
  device_name: string | null
}

interface SyncResponse {
  recovery_score: number | null
  hrv_score: number | null
  sleep_score: number | null
  synced_at: string
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Require authentication
    const authResult = await requireAuth(req)
    if (authResult instanceof Response) {
      return authResult  // Return 401 if not authenticated
    }
    const authUser = authResult as AuthUser

    const payload = await req.json() as HealthKitPayload

    if (!payload.patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!payload.metric_date) {
      return new Response(
        JSON.stringify({ error: 'metric_date required (yyyy-MM-dd format)' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate numeric fields
    if (payload.hrv_ms != null && (typeof payload.hrv_ms !== 'number' || payload.hrv_ms < 0 || payload.hrv_ms > 500)) {
      return new Response(
        JSON.stringify({ error: 'Invalid hrv_ms value: must be a number between 0 and 500' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (payload.resting_heart_rate != null && (typeof payload.resting_heart_rate !== 'number' || payload.resting_heart_rate < 20 || payload.resting_heart_rate > 250)) {
      return new Response(
        JSON.stringify({ error: 'Invalid resting_heart_rate value: must be a number between 20 and 250' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (payload.sleep_hours != null && (typeof payload.sleep_hours !== 'number' || payload.sleep_hours < 0 || payload.sleep_hours > 24)) {
      return new Response(
        JSON.stringify({ error: 'Invalid sleep_hours value: must be a number between 0 and 24' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (payload.steps != null && (typeof payload.steps !== 'number' || payload.steps < 0)) {
      return new Response(
        JSON.stringify({ error: 'Invalid steps value: must be a non-negative number' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Use authenticated client (enforces RLS)
    const supabaseClient = createAuthenticatedClient(req)

    // Verify user owns this patient record
    const isOwner = await verifyPatientOwnership(supabaseClient, payload.patient_id, authUser.user_id)
    if (!isOwner) {
      return new Response(
        JSON.stringify({ error: 'Forbidden', message: 'You do not have access to this patient' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ============================================================================
    // 1. Check cache - don't sync same date + source more than once per hour
    // ============================================================================

    const metricDate = payload.metric_date

    const { data: existingMetric } = await supabaseClient
      .from('readiness_metrics')
      .select('id, recorded_at, recovery_score')
      .eq('patient_id', payload.patient_id)
      .eq('metric_date', metricDate)
      .eq('source', 'apple_watch')
      .single()

    if (existingMetric?.recorded_at) {
      const recordedAt = new Date(existingMetric.recorded_at)
      const hoursSinceSync = (Date.now() - recordedAt.getTime()) / (1000 * 60 * 60)

      if (hoursSinceSync < CACHE_DURATION_HOURS) {
        return new Response(
          JSON.stringify({
            success: true,
            cached: true,
            message: `HealthKit data synced ${Math.round(hoursSinceSync * 60)} minutes ago. Using cached data.`,
            next_sync_available_in_minutes: Math.round((CACHE_DURATION_HOURS - hoursSinceSync) * 60),
            data: {
              recovery_score: existingMetric.recovery_score,
              synced_at: existingMetric.recorded_at,
            }
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // ============================================================================
    // 2. Fetch 7-day baseline for HRV and resting HR (for recovery score calc)
    // ============================================================================

    const baselineData = await fetch7DayBaseline(supabaseClient, payload.patient_id, metricDate)

    // ============================================================================
    // 3. Calculate normalized scores from raw HealthKit data
    // ============================================================================

    const hrvScore = calculateHRVScore(payload.hrv_ms, baselineData.hrvBaseline)
    const sleepScore = calculateSleepScore(
      payload.sleep_hours,
      payload.deep_sleep_minutes,
      payload.rem_sleep_minutes
    )
    const rhrScore = calculateRHRScore(payload.resting_heart_rate, baselineData.rhrBaseline)

    // Composite recovery score: weighted average of available scores
    const recoveryScore = calculateRecoveryScore(hrvScore, sleepScore, rhrScore)

    // ============================================================================
    // 4. Calculate total sleep duration in minutes
    // ============================================================================

    let totalSleepMinutes: number | null = null
    if (payload.sleep_hours != null) {
      totalSleepMinutes = Math.round(payload.sleep_hours * 60)
    }

    // Sleep efficiency: only meaningful when actual in-bed time is available.
    // HealthKit does not provide in-bed time separately in this payload, so we skip
    // the calculation rather than return a fixed ~87% estimate that adds no value.
    const sleepEfficiency: number | null = null

    // ============================================================================
    // 5. Upsert into readiness_metrics with source='apple_watch'
    // ============================================================================

    const sourceMetadata: Record<string, unknown> = {}
    if (payload.device_name) {
      sourceMetadata.device_name = payload.device_name
    }
    if (payload.steps != null) {
      sourceMetadata.steps = payload.steps
    }
    if (payload.active_energy_kcal != null) {
      sourceMetadata.active_energy_kcal = payload.active_energy_kcal
    }
    if (payload.light_sleep_minutes != null) {
      sourceMetadata.light_sleep_minutes = payload.light_sleep_minutes
    }

    const upsertData = {
      patient_id: payload.patient_id,
      recorded_at: payload.recorded_at || new Date().toISOString(),
      metric_date: metricDate,
      recovery_score: recoveryScore,
      hrv_score: hrvScore,
      sleep_score: sleepScore,
      resting_heart_rate: payload.resting_heart_rate,
      total_sleep_duration_minutes: totalSleepMinutes,
      deep_sleep_duration_minutes: payload.deep_sleep_minutes,
      rem_sleep_duration_minutes: payload.rem_sleep_minutes,
      sleep_efficiency_pct: sleepEfficiency,
      hrv_rmssd: null,  // Apple Watch provides SDNN, not RMSSD
      hrv_avg: payload.hrv_ms,  // Store SDNN in hrv_avg column
      strain_score: null,  // Not available from Apple Watch directly
      activity_minutes: payload.workout_minutes,
      calories_burned: payload.active_energy_kcal != null ? Math.round(payload.active_energy_kcal) : null,
      source: 'apple_watch',
      source_metadata: sourceMetadata,
    }

    const { data: upsertedMetric, error: upsertError } = await supabaseClient
      .from('readiness_metrics')
      .upsert(upsertData, {
        onConflict: 'patient_id,metric_date,source'
      })
      .select()
      .single()

    if (upsertError) {
      console.error('Upsert error:', upsertError)
      throw new Error('Failed to upsert readiness_metrics')
    }

    // ============================================================================
    // 6. Return the stored record with calculated scores
    // ============================================================================

    const response: SyncResponse = {
      recovery_score: recoveryScore,
      hrv_score: hrvScore,
      sleep_score: sleepScore,
      synced_at: new Date().toISOString(),
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: response,
        stored_metric: upsertedMetric,
        baseline_used: {
          hrv_baseline_ms: baselineData.hrvBaseline,
          rhr_baseline_bpm: baselineData.rhrBaseline,
          baseline_days: baselineData.daysAvailable,
        }
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in sync-healthkit-data:', error)

    const isDev = Deno.env.get('ENVIRONMENT') === 'development'
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'

    const responseBody: Record<string, string> = {
      error: isDev ? errorMessage : 'Internal server error',
    }
    if (isDev) {
      responseBody.details = error instanceof Error ? error.toString() : String(error)
    }

    return new Response(
      JSON.stringify(responseBody),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// ============================================================================
// Helper: Fetch 7-day baseline from existing readiness_metrics
// ============================================================================

interface BaselineData {
  hrvBaseline: number | null
  rhrBaseline: number | null
  daysAvailable: number
}

async function fetch7DayBaseline(
  supabaseClient: SupabaseClient,
  patientId: string,
  currentDate: string
): Promise<BaselineData> {
  try {
    // Fetch the last 7 days of apple_watch data (excluding current date)
    const { data: historicalMetrics, error } = await supabaseClient
      .from('readiness_metrics')
      .select('hrv_avg, resting_heart_rate, metric_date')
      .eq('patient_id', patientId)
      .eq('source', 'apple_watch')
      .lt('metric_date', currentDate)
      .order('metric_date', { ascending: false })
      .limit(7)

    if (error || !historicalMetrics || historicalMetrics.length === 0) {
      return { hrvBaseline: null, rhrBaseline: null, daysAvailable: 0 }
    }

    // Calculate averages from available data
    const hrvValues = historicalMetrics
      .map((m: any) => m.hrv_avg)
      .filter((v: any) => v != null && v > 0) as number[]

    const rhrValues = historicalMetrics
      .map((m: any) => m.resting_heart_rate)
      .filter((v: any) => v != null && v > 0) as number[]

    const hrvBaseline = hrvValues.length >= 3
      ? hrvValues.reduce((sum: number, v: number) => sum + v, 0) / hrvValues.length
      : null

    const rhrBaseline = rhrValues.length >= 3
      ? rhrValues.reduce((sum: number, v: number) => sum + v, 0) / rhrValues.length
      : null

    return {
      hrvBaseline,
      rhrBaseline,
      daysAvailable: historicalMetrics.length,
    }
  } catch (error) {
    console.error('Error fetching baseline:', error)
    return { hrvBaseline: null, rhrBaseline: null, daysAvailable: 0 }
  }
}

// ============================================================================
// Helper: Calculate HRV Score (0-100) based on deviation from baseline
// ============================================================================

function calculateHRVScore(hrvMs: number | null, baseline: number | null): number | null {
  if (hrvMs == null || hrvMs <= 0) {
    return null
  }

  // If no baseline available, use population norms
  // Typical HRV (SDNN) for adults: 30-100ms, athletic: 60-120ms
  if (baseline == null) {
    // Normalize against a general population reference of 60ms
    const referenceHRV = 60
    const score = Math.min(100, Math.max(0,
      50 + ((hrvMs - referenceHRV) / referenceHRV) * 50
    ))
    return Math.round(score * 10) / 10
  }

  // Compare to personal baseline
  // HRV at baseline = 70 points
  // HRV 20% above baseline = 90 points
  // HRV 20% below baseline = 50 points
  const deviationPercent = ((hrvMs - baseline) / baseline) * 100
  const score = Math.min(100, Math.max(0,
    70 + deviationPercent
  ))

  return Math.round(score * 10) / 10
}

// ============================================================================
// Helper: Calculate Sleep Score (0-100) based on duration and quality
// ============================================================================

function calculateSleepScore(
  sleepHours: number | null,
  deepSleepMinutes: number | null,
  remSleepMinutes: number | null
): number | null {
  if (sleepHours == null || sleepHours <= 0) {
    return null
  }

  // Duration score (0-60 points): 7-9 hours is optimal
  let durationScore: number
  if (sleepHours >= 7 && sleepHours <= 9) {
    durationScore = 60  // Optimal
  } else if (sleepHours >= 6 && sleepHours < 7) {
    durationScore = 45  // Adequate
  } else if (sleepHours > 9 && sleepHours <= 10) {
    durationScore = 50  // Slightly over
  } else if (sleepHours >= 5 && sleepHours < 6) {
    durationScore = 30  // Poor
  } else if (sleepHours > 10) {
    durationScore = 35  // Too much
  } else {
    durationScore = 15  // Very poor (<5 hours)
  }

  // Quality score from sleep stages (0-40 points)
  let qualityScore = 0
  const totalSleepMinutes = sleepHours * 60

  if (deepSleepMinutes != null && totalSleepMinutes > 0) {
    // Deep sleep should be 15-25% of total sleep
    const deepPct = (deepSleepMinutes / totalSleepMinutes) * 100
    if (deepPct >= 15 && deepPct <= 25) {
      qualityScore += 20  // Optimal deep sleep
    } else if (deepPct >= 10 && deepPct < 15) {
      qualityScore += 12  // Slightly low
    } else if (deepPct > 25 && deepPct <= 30) {
      qualityScore += 15  // Slightly high
    } else {
      qualityScore += 5   // Poor ratio
    }
  } else {
    // No stage data - give moderate score
    qualityScore += 10
  }

  if (remSleepMinutes != null && totalSleepMinutes > 0) {
    // REM should be 20-25% of total sleep
    const remPct = (remSleepMinutes / totalSleepMinutes) * 100
    if (remPct >= 20 && remPct <= 25) {
      qualityScore += 20  // Optimal REM
    } else if (remPct >= 15 && remPct < 20) {
      qualityScore += 12  // Slightly low
    } else if (remPct > 25 && remPct <= 30) {
      qualityScore += 15  // Slightly high
    } else {
      qualityScore += 5   // Poor ratio
    }
  } else {
    // No stage data - give moderate score
    qualityScore += 10
  }

  const totalScore = Math.min(100, durationScore + qualityScore)
  return Math.round(totalScore * 10) / 10
}

// ============================================================================
// Helper: Calculate Resting HR Score (0-100)
// ============================================================================

function calculateRHRScore(rhr: number | null, baseline: number | null): number | null {
  if (rhr == null || rhr <= 0) {
    return null
  }

  // Lower resting HR generally indicates better cardiovascular fitness
  if (baseline == null) {
    // Use population norms: excellent <60, good 60-70, average 70-80, poor >80
    if (rhr < 50) return 95
    if (rhr < 55) return 90
    if (rhr < 60) return 85
    if (rhr < 65) return 75
    if (rhr < 70) return 65
    if (rhr < 75) return 55
    if (rhr < 80) return 45
    return 30
  }

  // Compare to personal baseline
  // RHR at baseline = 70 points
  // RHR lower than baseline = better recovery (higher score)
  // RHR higher than baseline = worse recovery (lower score)
  const deviationPercent = ((rhr - baseline) / baseline) * 100
  // Invert: higher RHR = lower score
  const score = Math.min(100, Math.max(0,
    70 - deviationPercent * 2  // 2x multiplier since RHR changes are subtle
  ))

  return Math.round(score * 10) / 10
}

// ============================================================================
// Helper: Calculate Composite Recovery Score
// ============================================================================

function calculateRecoveryScore(
  hrvScore: number | null,
  sleepScore: number | null,
  rhrScore: number | null
): number | null {
  const scores: { value: number; weight: number }[] = []

  // Weighted contributions:
  // HRV: 40% (most reliable recovery indicator)
  // Sleep: 35% (critical for recovery)
  // Resting HR: 25% (supportive indicator)
  if (hrvScore != null) {
    scores.push({ value: hrvScore, weight: 0.40 })
  }
  if (sleepScore != null) {
    scores.push({ value: sleepScore, weight: 0.35 })
  }
  if (rhrScore != null) {
    scores.push({ value: rhrScore, weight: 0.25 })
  }

  if (scores.length === 0) {
    return null
  }

  // Normalize weights to sum to 1.0
  const totalWeight = scores.reduce((sum, s) => sum + s.weight, 0)
  const weightedSum = scores.reduce((sum, s) => sum + (s.value * (s.weight / totalWeight)), 0)

  return Math.round(weightedSum * 10) / 10
}
