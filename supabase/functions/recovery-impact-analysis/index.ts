// ============================================================================
// Recovery Impact Analysis Edge Function
// Health Intelligence Platform - Recovery Modality Effectiveness
// ============================================================================
// Analyzes the impact of recovery sessions (sauna, cold plunge, massage,
// stretching, etc.) on HRV, sleep quality, and overall readiness. Provides
// insights into which recovery modalities are most effective for each patient.
//
// Date: 2026-02-03
// Ticket: ACP-1201
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Anthropic from "npm:@anthropic-ai/sdk@0.24.3"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface RecoveryImpactRequest {
  patient_id: string
  lookback_days?: number  // Default 30 days
}

interface RecoverySession {
  id: string
  session_type: string
  duration_minutes: number
  logged_at: string
  notes: string | null
  rating: number | null
}

interface DailyMetrics {
  date: string
  readiness_score: number | null
  sleep_hours: number | null
  hrv_rmssd: number | null
  resting_hr: number | null
  soreness_level: number | null
  energy_level: number | null
  stress_level: number | null
}

interface ModalityImpact {
  modality: string
  session_count: number
  avg_duration_minutes: number
  avg_next_day_hrv_change: number | null
  avg_next_day_readiness_change: number | null
  avg_next_day_sleep_change: number | null
  effectiveness_score: number
  best_duration_range: string
  best_timing: string
  notes: string[]
}

interface CorrelationInsight {
  finding: string
  strength: 'strong' | 'moderate' | 'weak'
  recommendation: string
  data_points: number
}

interface RecoveryImpactResponse {
  analysis_id: string
  patient_id: string
  analysis_period: {
    start_date: string
    end_date: string
    total_days: number
  }
  total_recovery_sessions: number
  modality_impacts: ModalityImpact[]
  correlation_insights: CorrelationInsight[]
  overall_recommendations: string[]
  optimal_recovery_protocol: {
    weekly_frequency: Record<string, number>
    timing_recommendations: string[]
    combination_synergies: string[]
  }
  ai_analysis: string
  data_quality: {
    hrv_data_completeness: number
    sleep_data_completeness: number
    readiness_data_completeness: number
  }
  disclaimer: string
  cached: boolean
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function calculateChange(before: number | null, after: number | null): number | null {
  if (before === null || after === null) return null
  return after - before
}

function calculateAverage(values: number[]): number | null {
  const validValues = values.filter(v => v !== null && !isNaN(v))
  if (validValues.length === 0) return null
  return validValues.reduce((a, b) => a + b, 0) / validValues.length
}

function getDateString(date: Date): string {
  return date.toISOString().split('T')[0]
}

function addDays(dateStr: string, days: number): string {
  const date = new Date(dateStr)
  date.setDate(date.getDate() + days)
  return getDateString(date)
}

interface SessionWithMetrics {
  session: RecoverySession
  dayBeforeMetrics: DailyMetrics | null
  dayOfMetrics: DailyMetrics | null
  dayAfterMetrics: DailyMetrics | null
}

function analyzeModalityImpact(
  sessions: SessionWithMetrics[],
  modality: string
): ModalityImpact {
  const modalitySessions = sessions.filter(s =>
    s.session.session_type.toLowerCase() === modality.toLowerCase()
  )

  if (modalitySessions.length === 0) {
    return {
      modality,
      session_count: 0,
      avg_duration_minutes: 0,
      avg_next_day_hrv_change: null,
      avg_next_day_readiness_change: null,
      avg_next_day_sleep_change: null,
      effectiveness_score: 0,
      best_duration_range: 'N/A',
      best_timing: 'N/A',
      notes: ['No sessions recorded for this modality']
    }
  }

  // Calculate HRV changes
  const hrvChanges: number[] = []
  const readinessChanges: number[] = []
  const sleepChanges: number[] = []
  const durations: number[] = []

  for (const s of modalitySessions) {
    durations.push(s.session.duration_minutes)

    // Compare day before to day after (to see recovery impact)
    if (s.dayBeforeMetrics && s.dayAfterMetrics) {
      const hrvChange = calculateChange(
        s.dayBeforeMetrics.hrv_rmssd,
        s.dayAfterMetrics.hrv_rmssd
      )
      if (hrvChange !== null) hrvChanges.push(hrvChange)

      const readinessChange = calculateChange(
        s.dayBeforeMetrics.readiness_score,
        s.dayAfterMetrics.readiness_score
      )
      if (readinessChange !== null) readinessChanges.push(readinessChange)

      const sleepChange = calculateChange(
        s.dayBeforeMetrics.sleep_hours,
        s.dayAfterMetrics.sleep_hours
      )
      if (sleepChange !== null) sleepChanges.push(sleepChange)
    }
  }

  // Calculate effectiveness score (0-100)
  let effectivenessScore = 50 // Base score

  const avgHrvChange = calculateAverage(hrvChanges)
  if (avgHrvChange !== null) {
    effectivenessScore += Math.min(20, Math.max(-20, avgHrvChange / 2))
  }

  const avgReadinessChange = calculateAverage(readinessChanges)
  if (avgReadinessChange !== null) {
    effectivenessScore += Math.min(15, Math.max(-15, avgReadinessChange / 2))
  }

  const avgSleepChange = calculateAverage(sleepChanges)
  if (avgSleepChange !== null) {
    effectivenessScore += Math.min(15, Math.max(-15, avgSleepChange * 5))
  }

  effectivenessScore = Math.max(0, Math.min(100, effectivenessScore))

  // Determine best duration range
  const avgDuration = calculateAverage(durations) || 0
  const minDuration = Math.min(...durations)
  const maxDuration = Math.max(...durations)
  const bestDurationRange = `${minDuration}-${maxDuration} minutes (avg: ${Math.round(avgDuration)})`

  // Determine best timing based on session timestamps
  const hours = modalitySessions.map(s => new Date(s.session.logged_at).getHours())
  const avgHour = Math.round(calculateAverage(hours) || 12)
  let bestTiming = 'Morning'
  if (avgHour >= 12 && avgHour < 17) bestTiming = 'Afternoon'
  else if (avgHour >= 17 && avgHour < 21) bestTiming = 'Evening'
  else if (avgHour >= 21) bestTiming = 'Night'

  // Generate notes
  const notes: string[] = []
  if (avgHrvChange !== null && avgHrvChange > 5) {
    notes.push(`HRV improved by average of ${avgHrvChange.toFixed(1)} ms after ${modality} sessions`)
  } else if (avgHrvChange !== null && avgHrvChange < -5) {
    notes.push(`HRV decreased by average of ${Math.abs(avgHrvChange).toFixed(1)} ms - may indicate overuse`)
  }

  if (avgReadinessChange !== null && avgReadinessChange > 3) {
    notes.push(`Readiness improved by ${avgReadinessChange.toFixed(0)} points on average`)
  }

  if (avgSleepChange !== null && avgSleepChange > 0.3) {
    notes.push(`Sleep duration increased by ${(avgSleepChange * 60).toFixed(0)} minutes on average`)
  }

  return {
    modality,
    session_count: modalitySessions.length,
    avg_duration_minutes: Math.round(avgDuration),
    avg_next_day_hrv_change: avgHrvChange !== null ? Math.round(avgHrvChange * 10) / 10 : null,
    avg_next_day_readiness_change: avgReadinessChange !== null ? Math.round(avgReadinessChange * 10) / 10 : null,
    avg_next_day_sleep_change: avgSleepChange !== null ? Math.round(avgSleepChange * 100) / 100 : null,
    effectiveness_score: Math.round(effectivenessScore),
    best_duration_range: bestDurationRange,
    best_timing: bestTiming,
    notes: notes.length > 0 ? notes : ['Insufficient data for detailed analysis']
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
    const { patient_id, lookback_days = 30 } = await req.json() as RecoveryImpactRequest

    // Validate required fields
    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate UUID format
    if (!isValidUUID(patient_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid patient_id format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate lookback_days
    const validLookbackDays = Math.min(Math.max(7, lookback_days), 90)

    console.log(`[recovery-impact-analysis] Analyzing ${validLookbackDays} days for patient ${patient_id}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // CHECK FOR CACHED ANALYSIS (24 hour cache)
    // ========================================================================
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    const { data: cachedAnalysis } = await supabaseClient
      .from('recovery_impact_analyses')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('created_at', twentyFourHoursAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (cachedAnalysis) {
      console.log('[recovery-impact-analysis] Returning cached analysis')
      return new Response(
        JSON.stringify({ ...cachedAnalysis, cached: true }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // FETCH RECOVERY SESSIONS
    // ========================================================================
    const startDate = new Date(Date.now() - validLookbackDays * 24 * 60 * 60 * 1000)
    const endDate = new Date()

    const { data: recoverySessions, error: recoveryError } = await supabaseClient
      .from('recovery_sessions')
      .select('id, session_type, duration_minutes, logged_at, notes, rating')
      .eq('patient_id', patient_id)
      .gte('logged_at', startDate.toISOString())
      .lte('logged_at', endDate.toISOString())
      .order('logged_at', { ascending: true })

    if (recoveryError) {
      console.error('[recovery-impact-analysis] Error fetching recovery sessions:', recoveryError)
      throw new Error(`Failed to fetch recovery sessions: ${recoveryError.message}`)
    }

    if (!recoverySessions || recoverySessions.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'No recovery sessions found in the specified period',
          analysis_id: crypto.randomUUID(),
          patient_id,
          analysis_period: {
            start_date: getDateString(startDate),
            end_date: getDateString(endDate),
            total_days: validLookbackDays
          },
          total_recovery_sessions: 0,
          modality_impacts: [],
          correlation_insights: [],
          overall_recommendations: ['Start logging recovery sessions to track their impact on your health metrics'],
          optimal_recovery_protocol: {
            weekly_frequency: {},
            timing_recommendations: [],
            combination_synergies: []
          },
          ai_analysis: 'Insufficient data for analysis. Please log recovery sessions to enable impact tracking.',
          data_quality: {
            hrv_data_completeness: 0,
            sleep_data_completeness: 0,
            readiness_data_completeness: 0
          },
          disclaimer: 'No recovery data available for analysis.',
          cached: false
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // FETCH DAILY METRICS (HRV, Sleep, Readiness)
    // ========================================================================
    const metricsStartDate = new Date(startDate)
    metricsStartDate.setDate(metricsStartDate.getDate() - 1) // Include day before first session

    const { data: dailyMetrics, error: metricsError } = await supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, whoop_hrv_rmssd, whoop_resting_hr, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', getDateString(metricsStartDate))
      .lte('date', getDateString(endDate))
      .order('date', { ascending: true })

    if (metricsError) {
      console.error('[recovery-impact-analysis] Error fetching daily metrics:', metricsError)
    }

    // Create a map of date -> metrics for easy lookup
    const metricsMap: Record<string, DailyMetrics> = {}
    for (const m of (dailyMetrics || [])) {
      metricsMap[m.date] = {
        date: m.date,
        readiness_score: m.readiness_score,
        sleep_hours: m.sleep_hours,
        hrv_rmssd: m.whoop_hrv_rmssd,
        resting_hr: m.whoop_resting_hr,
        soreness_level: m.soreness_level,
        energy_level: m.energy_level,
        stress_level: m.stress_level
      }
    }

    // ========================================================================
    // CORRELATE SESSIONS WITH METRICS
    // ========================================================================
    const sessionsWithMetrics: SessionWithMetrics[] = recoverySessions.map((session: any) => {
      const sessionDate = getDateString(new Date(session.logged_at))
      const dayBefore = addDays(sessionDate, -1)
      const dayAfter = addDays(sessionDate, 1)

      return {
        session: session as RecoverySession,
        dayBeforeMetrics: metricsMap[dayBefore] || null,
        dayOfMetrics: metricsMap[sessionDate] || null,
        dayAfterMetrics: metricsMap[dayAfter] || null
      }
    })

    // ========================================================================
    // ANALYZE EACH MODALITY
    // ========================================================================
    const uniqueModalities = [...new Set(recoverySessions.map((s: any) => s.session_type))]
    const modalityImpacts: ModalityImpact[] = uniqueModalities.map(modality =>
      analyzeModalityImpact(sessionsWithMetrics, modality)
    )

    // Sort by effectiveness score
    modalityImpacts.sort((a, b) => b.effectiveness_score - a.effectiveness_score)

    // ========================================================================
    // CALCULATE DATA QUALITY
    // ========================================================================
    const totalDays = validLookbackDays
    const daysWithHrv = Object.values(metricsMap).filter(m => m.hrv_rmssd !== null).length
    const daysWithSleep = Object.values(metricsMap).filter(m => m.sleep_hours !== null).length
    const daysWithReadiness = Object.values(metricsMap).filter(m => m.readiness_score !== null).length

    const dataQuality = {
      hrv_data_completeness: Math.round((daysWithHrv / totalDays) * 100),
      sleep_data_completeness: Math.round((daysWithSleep / totalDays) * 100),
      readiness_data_completeness: Math.round((daysWithReadiness / totalDays) * 100)
    }

    // ========================================================================
    // CALL AI FOR DEEP ANALYSIS
    // ========================================================================
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[recovery-impact-analysis] Calling Anthropic Claude API...')

    const anthropic = new Anthropic({ apiKey: anthropicApiKey })

    const systemPrompt = `You are an expert sports scientist and recovery specialist. Analyze recovery session data and their impact on HRV, sleep, and readiness metrics. Provide evidence-based insights and recommendations.

RECOVERY MODALITY KNOWLEDGE:
- Sauna: Increases growth hormone, improves cardiovascular health, aids muscle recovery. Best: 15-20 min at 170-185F, 3-4x/week
- Cold Plunge/Ice Bath: Reduces inflammation, increases dopamine, improves stress resilience. Best: 2-5 min at 40-55F, post-workout
- Massage: Reduces muscle tension, improves circulation, aids lymphatic drainage
- Stretching/Mobility: Improves flexibility, reduces injury risk, aids recovery
- Compression: Improves blood flow, reduces swelling
- Sleep: Foundation of all recovery
- Meditation/Breathwork: Reduces cortisol, improves HRV, aids parasympathetic activation

ANALYSIS GUIDELINES:
1. Look for patterns between recovery modalities and next-day metrics
2. Consider timing (morning vs evening sessions)
3. Identify potential overuse (too frequent = diminishing returns)
4. Note synergies between modalities
5. Consider individual response patterns`

    const userPrompt = `RECOVERY SESSION DATA (Last ${validLookbackDays} Days):

SESSIONS BY MODALITY:
${modalityImpacts.map(m => `
${m.modality}:
- Sessions: ${m.session_count}
- Avg Duration: ${m.avg_duration_minutes} minutes
- Avg HRV Change (next day): ${m.avg_next_day_hrv_change !== null ? `${m.avg_next_day_hrv_change > 0 ? '+' : ''}${m.avg_next_day_hrv_change} ms` : 'N/A'}
- Avg Readiness Change: ${m.avg_next_day_readiness_change !== null ? `${m.avg_next_day_readiness_change > 0 ? '+' : ''}${m.avg_next_day_readiness_change} points` : 'N/A'}
- Avg Sleep Change: ${m.avg_next_day_sleep_change !== null ? `${m.avg_next_day_sleep_change > 0 ? '+' : ''}${(m.avg_next_day_sleep_change * 60).toFixed(0)} minutes` : 'N/A'}
- Effectiveness Score: ${m.effectiveness_score}/100
- Typical Timing: ${m.best_timing}
`).join('')}

DATA QUALITY:
- HRV data completeness: ${dataQuality.hrv_data_completeness}%
- Sleep data completeness: ${dataQuality.sleep_data_completeness}%
- Readiness data completeness: ${dataQuality.readiness_data_completeness}%

TASK: Analyze this recovery data and provide:
1. Key insights about which modalities are working
2. Specific recommendations for optimizing recovery
3. Suggested weekly recovery protocol
4. Any concerning patterns or overuse indicators

Respond with valid JSON ONLY:
{
  "analysis_summary": "2-3 paragraph comprehensive analysis of the recovery patterns and their impacts",
  "correlation_insights": [
    {
      "finding": "What you discovered",
      "strength": "strong|moderate|weak",
      "recommendation": "What to do about it",
      "data_points": number
    }
  ],
  "overall_recommendations": [
    "Top priority recommendation",
    "Second recommendation",
    "Third recommendation"
  ],
  "optimal_protocol": {
    "weekly_frequency": {
      "modality_name": suggested_times_per_week
    },
    "timing_recommendations": [
      "Specific timing advice"
    ],
    "combination_synergies": [
      "Which modalities work well together"
    ]
  }
}`

    const completion = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      system: systemPrompt,
      messages: [{ role: 'user', content: userPrompt }],
      temperature: 0.3,
    })

    const responseText = completion.content[0].type === 'text'
      ? completion.content[0].text
      : ''

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[recovery-impact-analysis] Received response from Claude')

    // Parse AI response
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[recovery-impact-analysis] Failed to parse AI response:', responseText)
      aiResponse = {
        analysis_summary: 'Analysis completed but response parsing failed. Review modality impacts above for insights.',
        correlation_insights: [],
        overall_recommendations: ['Continue logging recovery sessions for better analysis'],
        optimal_protocol: {
          weekly_frequency: {},
          timing_recommendations: [],
          combination_synergies: []
        }
      }
    }

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const disclaimer = `RECOVERY ANALYSIS DISCLAIMER: This analysis is based on correlations in your logged data and general sports science principles. Individual responses to recovery modalities vary significantly. The effectiveness scores and recommendations are for informational purposes only. Consult with healthcare professionals or certified trainers before making significant changes to your recovery protocols, especially if you have medical conditions.`

    const response: RecoveryImpactResponse = {
      analysis_id: crypto.randomUUID(),
      patient_id,
      analysis_period: {
        start_date: getDateString(startDate),
        end_date: getDateString(endDate),
        total_days: validLookbackDays
      },
      total_recovery_sessions: recoverySessions.length,
      modality_impacts: modalityImpacts,
      correlation_insights: aiResponse.correlation_insights || [],
      overall_recommendations: aiResponse.overall_recommendations || [],
      optimal_recovery_protocol: {
        weekly_frequency: aiResponse.optimal_protocol?.weekly_frequency || {},
        timing_recommendations: aiResponse.optimal_protocol?.timing_recommendations || [],
        combination_synergies: aiResponse.optimal_protocol?.combination_synergies || []
      },
      ai_analysis: aiResponse.analysis_summary || 'Analysis completed.',
      data_quality: dataQuality,
      disclaimer,
      cached: false
    }

    // ========================================================================
    // SAVE ANALYSIS TO DATABASE
    // ========================================================================
    try {
      const { error: saveError } = await supabaseClient
        .from('recovery_impact_analyses')
        .insert({
          patient_id,
          analysis_period: response.analysis_period,
          total_recovery_sessions: response.total_recovery_sessions,
          modality_impacts: response.modality_impacts,
          correlation_insights: response.correlation_insights,
          overall_recommendations: response.overall_recommendations,
          optimal_recovery_protocol: response.optimal_recovery_protocol,
          ai_analysis: response.ai_analysis,
          data_quality: response.data_quality,
          disclaimer: response.disclaimer
        })

      if (saveError) {
        console.error('[recovery-impact-analysis] Error saving analysis:', saveError)
        // Continue without saving
      } else {
        console.log('[recovery-impact-analysis] Analysis saved successfully')
      }
    } catch (saveError) {
      console.error('[recovery-impact-analysis] Error saving analysis:', saveError)
    }

    console.log(`[recovery-impact-analysis] Generated analysis with ${modalityImpacts.length} modalities, ${response.correlation_insights.length} insights`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[recovery-impact-analysis] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        disclaimer: 'Recovery analysis encountered an error. Please try again or consult with a healthcare provider.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
