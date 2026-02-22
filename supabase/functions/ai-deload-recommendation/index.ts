// ============================================================================
// AI Deload Recommendation Edge Function
// Smart Recovery Sprint - Anthropic Claude Integration
// ============================================================================
// Analyzes fatigue accumulation and generates deload recommendations
// Uses calculate_accumulated_fatigue RPC and Claude AI for intelligent analysis
//
// Date: 2026-02-01
// Agent: 2
// Sprint: Smart Recovery
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limit.ts'
import { corsHeaders, handleCors } from '../_shared/cors.ts'

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface DeloadRecommendationRequest {
  patient_id: string
  force_refresh?: boolean  // Skip cache and generate new recommendation
}

interface FatigueSummary {
  fatigue_score: number
  fatigue_band: 'low' | 'moderate' | 'high' | 'critical'
  avg_readiness_7d: number | null
  acute_chronic_ratio: number | null
  consecutive_low_days: number
  contributing_factors: string[]
}

interface DeloadPrescription {
  duration_days: number        // 3-14 days
  load_reduction_pct: number   // 20-80%
  volume_reduction_pct: number // 20-70%
  focus: 'technique' | 'mobility' | 'active_recovery' | 'complete_rest'
  suggested_start_date: string
}

interface DeloadRecommendationResponse {
  recommendation_id: string
  deload_recommended: boolean
  urgency: 'suggested' | 'recommended' | 'required' | null
  reasoning: string
  fatigue_summary: FatigueSummary
  prescription: DeloadPrescription | null
  in_active_deload: boolean
  active_deload_info: {
    deload_period_id: string
    start_date: string
    end_date: string
    days_remaining: number
  } | null
  cached: boolean
}

interface FatigueAccumulationRecord {
  id: string
  patient_id: string
  calculation_date: string
  avg_readiness_7d: number | null
  avg_readiness_14d: number | null
  training_load_7d: number | null
  training_load_14d: number | null
  acute_chronic_ratio: number | null
  consecutive_low_readiness: number
  missed_reps_count_7d: number
  high_rpe_count_7d: number
  pain_reports_7d: number
  fatigue_score: number
  fatigue_band: string
  deload_recommended: boolean
  deload_urgency: string
  created_at: string
}

interface ReadinessEntry {
  date: string
  readiness_score: number | null
  sleep_hours: number | null
  soreness_level: number | null
  energy_level: number | null
  stress_level: number | null
}

interface PatientGoal {
  category: string
  title: string
  target_date: string | null
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function calculateFatigueBand(score: number): 'low' | 'moderate' | 'high' | 'critical' {
  if (score >= 76) return 'critical'
  if (score >= 51) return 'high'
  if (score >= 26) return 'moderate'
  return 'low'
}

function determineUrgency(
  fatigueScore: number,
  consecutiveLowDays: number,
  acuteChronicRatio: number | null
): 'suggested' | 'recommended' | 'required' | null {
  // Required: Critical fatigue or dangerous acute:chronic ratio
  if (fatigueScore >= 80 || (acuteChronicRatio && acuteChronicRatio >= 1.5) || consecutiveLowDays >= 5) {
    return 'required'
  }
  // Recommended: High fatigue or elevated acute:chronic ratio
  if (fatigueScore >= 65 || (acuteChronicRatio && acuteChronicRatio >= 1.3) || consecutiveLowDays >= 4) {
    return 'recommended'
  }
  // Suggested: Moderate fatigue indicators
  if (fatigueScore >= 50 || (acuteChronicRatio && acuteChronicRatio >= 1.2) || consecutiveLowDays >= 3) {
    return 'suggested'
  }
  // No deload needed
  return null
}

function identifyContributingFactors(
  readinessEntries: ReadinessEntry[],
  fatigueData: FatigueAccumulationRecord | null,
  consecutiveLowDays: number,
  acuteChronicRatio: number | null
): string[] {
  const factors: string[] = []

  // Sleep analysis
  const sleepHours = readinessEntries
    .filter(r => r.sleep_hours !== null)
    .map(r => r.sleep_hours as number)
  if (sleepHours.length > 0) {
    const avgSleep = sleepHours.reduce((a, b) => a + b, 0) / sleepHours.length
    if (avgSleep < 5.5) factors.push('severe_sleep_deficit')
    else if (avgSleep < 6.5) factors.push('sleep_deficit')
  }

  // Soreness analysis
  const sorenessLevels = readinessEntries
    .filter(r => r.soreness_level !== null)
    .map(r => r.soreness_level as number)
  if (sorenessLevels.length > 0) {
    const avgSoreness = sorenessLevels.reduce((a, b) => a + b, 0) / sorenessLevels.length
    if (avgSoreness >= 7) factors.push('high_soreness')
    else if (avgSoreness >= 5) factors.push('elevated_soreness')
  }

  // Energy analysis
  const energyLevels = readinessEntries
    .filter(r => r.energy_level !== null)
    .map(r => r.energy_level as number)
  if (energyLevels.length > 0) {
    const avgEnergy = energyLevels.reduce((a, b) => a + b, 0) / energyLevels.length
    if (avgEnergy <= 3) factors.push('very_low_energy')
    else if (avgEnergy <= 4) factors.push('low_energy')
  }

  // Stress analysis
  const stressLevels = readinessEntries
    .filter(r => r.stress_level !== null)
    .map(r => r.stress_level as number)
  if (stressLevels.length > 0) {
    const avgStress = stressLevels.reduce((a, b) => a + b, 0) / stressLevels.length
    if (avgStress >= 8) factors.push('high_stress')
    else if (avgStress >= 6) factors.push('elevated_stress')
  }

  // Training load factors from fatigue data
  if (fatigueData) {
    if (fatigueData.high_rpe_count_7d >= 3) factors.push('high_rpe_sessions')
    if (fatigueData.pain_reports_7d >= 2) factors.push('pain_reports')
    if (fatigueData.missed_reps_count_7d >= 10) factors.push('performance_decline')
  }

  // Acute:chronic ratio
  if (acuteChronicRatio && acuteChronicRatio >= 1.4) factors.push('training_spike')
  else if (acuteChronicRatio && acuteChronicRatio >= 1.25) factors.push('elevated_training_load')

  // Consecutive low days
  if (consecutiveLowDays >= 4) factors.push('accumulated_fatigue')
  else if (consecutiveLowDays >= 2) factors.push('recent_low_readiness')

  return factors
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = corsHeaders(origin)

  try {
    const requestBody: DeloadRecommendationRequest = await req.json()
    const { patient_id, force_refresh } = requestBody

    // Rate limit: 10 requests/minute for AI endpoints
    const rateLimitKey = patient_id || req.headers.get('x-forwarded-for') || 'anonymous'
    const { allowed, resetMs } = checkRateLimit(`ai-deload:${rateLimitKey}`, { windowMs: 60_000, maxRequests: 10 })
    if (!allowed) return rateLimitResponse(resetMs)

    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id required' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // CHECK IF PATIENT IS IN ACTIVE DELOAD
    // ========================================================================
    const { data: deloadStatus } = await supabaseClient
      .rpc('is_in_deload_period', { p_patient_id: patient_id })
      .maybeSingle()

    if (deloadStatus?.in_deload) {
      // Patient is already in a deload period
      console.log('[ai-deload-recommendation] Patient is in active deload period')

      return new Response(
        JSON.stringify({
          recommendation_id: null,
          deload_recommended: false,
          urgency: null,
          reasoning: 'You are currently in an active deload period. Continue with reduced intensity as planned.',
          fatigue_summary: {
            fatigue_score: 0,
            fatigue_band: 'low',
            avg_readiness_7d: null,
            acute_chronic_ratio: null,
            consecutive_low_days: 0,
            contributing_factors: []
          },
          prescription: null,
          in_active_deload: true,
          active_deload_info: {
            deload_period_id: deloadStatus.deload_period_id,
            start_date: deloadStatus.start_date,
            end_date: deloadStatus.end_date,
            days_remaining: deloadStatus.days_remaining
          },
          cached: false
        } as DeloadRecommendationResponse),
        { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // CHECK FOR CACHED RECOMMENDATION (6 hour cache)
    // ========================================================================
    if (!force_refresh) {
      const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString()
      const { data: recentRecommendation } = await supabaseClient
        .from('deload_recommendations')
        .select('*')
        .eq('patient_id', patient_id)
        .eq('status', 'pending')
        .gte('created_at', sixHoursAgo)
        .order('created_at', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (recentRecommendation) {
        console.log('[ai-deload-recommendation] Returning cached recommendation')

        const fatigueSummary: FatigueSummary = {
          fatigue_score: recentRecommendation.fatigue_score || 0,
          fatigue_band: recentRecommendation.fatigue_band || 'low',
          avg_readiness_7d: recentRecommendation.avg_readiness_7d,
          acute_chronic_ratio: recentRecommendation.acute_chronic_ratio,
          consecutive_low_days: 0,
          contributing_factors: recentRecommendation.contributing_factors || []
        }

        const prescription: DeloadPrescription | null = recentRecommendation.urgency ? {
          duration_days: recentRecommendation.duration_days,
          load_reduction_pct: recentRecommendation.load_reduction_pct,
          volume_reduction_pct: recentRecommendation.volume_reduction_pct,
          focus: recentRecommendation.focus,
          suggested_start_date: recentRecommendation.suggested_start_date
        } : null

        return new Response(
          JSON.stringify({
            recommendation_id: recentRecommendation.id,
            deload_recommended: !!recentRecommendation.urgency,
            urgency: recentRecommendation.urgency,
            reasoning: recentRecommendation.reasoning,
            fatigue_summary: fatigueSummary,
            prescription: prescription,
            in_active_deload: false,
            active_deload_info: null,
            cached: true
          } as DeloadRecommendationResponse),
          { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
        )
      }
    }

    // ========================================================================
    // CALL CALCULATE_ACCUMULATED_FATIGUE RPC
    // ========================================================================
    console.log('[ai-deload-recommendation] Calling calculate_accumulated_fatigue RPC')

    let fatigueData: FatigueAccumulationRecord | null = null
    const { data: calculatedFatigue, error: fatigueRpcError } = await supabaseClient
      .rpc('calculate_accumulated_fatigue', { p_patient_id: patient_id })
      .maybeSingle()

    if (!fatigueRpcError && calculatedFatigue) {
      fatigueData = calculatedFatigue as FatigueAccumulationRecord
      console.log('[ai-deload-recommendation] Fatigue score from RPC:', fatigueData.fatigue_score)
    } else {
      console.log('[ai-deload-recommendation] RPC error or no data, checking fatigue_accumulation table')

      // Fallback: read from fatigue_accumulation table
      const { data: storedFatigue } = await supabaseClient
        .from('fatigue_accumulation')
        .select('*')
        .eq('patient_id', patient_id)
        .order('calculation_date', { ascending: false })
        .limit(1)
        .maybeSingle()

      if (storedFatigue) {
        fatigueData = storedFatigue as FatigueAccumulationRecord
        console.log('[ai-deload-recommendation] Fatigue score from table:', fatigueData.fatigue_score)
      }
    }

    // ========================================================================
    // GATHER CONTEXT DATA
    // ========================================================================

    // Get readiness data for last 7 days
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo)
      .order('date', { ascending: false })
      .limit(7)

    const readinessEntries: ReadinessEntry[] = readinessData || []

    // Get recent workout count
    const { data: recentWorkouts } = await supabaseClient
      .from('manual_sessions')
      .select('id')
      .eq('patient_id', patient_id)
      .eq('completed', true)
      .gte('completed_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())

    const workoutCount7d = recentWorkouts?.length || 0

    // Get patient goals for context
    const { data: goalsData } = await supabaseClient
      .from('patient_goals')
      .select('category, title, target_date')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(5)

    const activeGoals: PatientGoal[] = (goalsData || []).map((g: any) => ({
      category: g.category || 'general',
      title: g.title,
      target_date: g.target_date
    }))

    // Get patient training age
    const { data: patientData } = await supabaseClient
      .from('patients')
      .select('id, created_at')
      .eq('id', patient_id)
      .maybeSingle()

    const trainingAgeDays = patientData?.created_at
      ? Math.floor((Date.now() - new Date(patientData.created_at).getTime()) / (1000 * 60 * 60 * 24))
      : 0

    // ========================================================================
    // CALCULATE METRICS
    // ========================================================================

    // Average readiness (7 days)
    const readinessScores = readinessEntries
      .filter(r => r.readiness_score !== null)
      .map(r => r.readiness_score as number)
    const avgReadiness7d = readinessScores.length > 0
      ? readinessScores.reduce((a, b) => a + b, 0) / readinessScores.length
      : null

    // Consecutive low readiness days (below 60)
    let consecutiveLowDays = 0
    for (const entry of readinessEntries) {
      if (entry.readiness_score !== null && entry.readiness_score < 60) {
        consecutiveLowDays++
      } else {
        break
      }
    }

    // Get values from fatigue data or use calculated
    const fatigueScore = fatigueData?.fatigue_score ?? (avgReadiness7d ? Math.round(100 - avgReadiness7d) : 30)
    const fatigueBand = fatigueData?.fatigue_band as 'low' | 'moderate' | 'high' | 'critical' || calculateFatigueBand(fatigueScore)
    const acuteChronicRatio = fatigueData?.acute_chronic_ratio ?? null

    // Determine urgency based on data
    const calculatedUrgency = determineUrgency(fatigueScore, consecutiveLowDays, acuteChronicRatio)

    // Identify contributing factors
    const contributingFactors = identifyContributingFactors(
      readinessEntries,
      fatigueData,
      consecutiveLowDays,
      acuteChronicRatio
    )

    // ========================================================================
    // BUILD AI PROMPT IF DELOAD MAY BE NEEDED
    // ========================================================================

    // If urgency is null (no deload needed), we can skip AI call
    if (!calculatedUrgency) {
      console.log('[ai-deload-recommendation] No deload needed based on metrics')

      // Still save a record for tracking
      const { data: savedRec } = await supabaseClient
        .from('deload_recommendations')
        .insert({
          patient_id,
          urgency: 'suggested', // Minimum required by schema
          reasoning: 'Current fatigue levels are within normal range. Continue with your regular training program.',
          fatigue_score: fatigueScore,
          fatigue_band: fatigueBand,
          avg_readiness_7d: avgReadiness7d,
          acute_chronic_ratio: acuteChronicRatio,
          contributing_factors: [],
          duration_days: 5,
          load_reduction_pct: 40,
          volume_reduction_pct: 30,
          focus: 'active_recovery',
          suggested_start_date: new Date().toISOString().split('T')[0],
          status: 'dismissed', // Auto-dismiss since not needed
          dismissed_at: new Date().toISOString(),
          dismissed_reason: 'auto_dismissed_no_deload_needed'
        })
        .select()
        .single()

      const fatigueSummary: FatigueSummary = {
        fatigue_score: fatigueScore,
        fatigue_band: fatigueBand,
        avg_readiness_7d: avgReadiness7d,
        acute_chronic_ratio: acuteChronicRatio,
        consecutive_low_days: consecutiveLowDays,
        contributing_factors: contributingFactors
      }

      return new Response(
        JSON.stringify({
          recommendation_id: savedRec?.id || null,
          deload_recommended: false,
          urgency: null,
          reasoning: 'Current fatigue levels are within normal range. Continue with your regular training program.',
          fatigue_summary: fatigueSummary,
          prescription: null,
          in_active_deload: false,
          active_deload_info: null,
          cached: false
        } as DeloadRecommendationResponse),
        { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // CALL ANTHROPIC CLAUDE API
    // ========================================================================

    const systemPrompt = `You are a sports science and physical therapy deload recommendation expert. Your task is to analyze fatigue indicators and recommend appropriate deload strategies.

CRITICAL RULES:
1. A deload is a planned reduction in training volume and intensity to allow recovery
2. Only recommend deloads when data clearly supports the need
3. Consider upcoming goals when timing deload recommendations
4. Be specific about the focus area based on contributing factors

URGENCY LEVELS:
- suggested: Mild fatigue detected, patient may benefit from lighter week
- recommended: Significant fatigue detected, deload strongly advised
- required: Critical fatigue levels, deload is essential to prevent overtraining/injury

DELOAD PARAMETERS:
- duration_days: 5-7 days for most cases, up to 10-14 for severe fatigue
- load_reduction_pct: 40-60% (how much to reduce weight/intensity)
- volume_reduction_pct: 30-50% (how much to reduce sets/reps)
- focus options:
  - "technique": Skill work at light weights, perfect form
  - "mobility": Flexibility, movement quality, active stretching
  - "active_recovery": Light activity, walking, swimming, easy cardio
  - "complete_rest": Full rest for severe cases (use sparingly)

FATIGUE BAND MEANING:
- low (0-25): Well recovered
- moderate (26-50): Normal training fatigue
- high (51-75): Significant accumulation, attention needed
- critical (76-100): Dangerous levels, immediate action needed

TRAINING AGE CONSIDERATIONS:
- Newer trainees (<3 months) may need more frequent deloads
- Intermediate (3-12 months) every 4-6 weeks
- Advanced (12+ months) can push further but still need periodic deloads`

    const userPrompt = `
PATIENT FATIGUE ANALYSIS:

Fatigue Score: ${fatigueScore}/100
Fatigue Band: ${fatigueBand}
Pre-calculated Urgency: ${calculatedUrgency}

READINESS DATA (Last 7 Days):
${readinessEntries.length > 0
  ? readinessEntries.map(r =>
      `- ${r.date}: Score ${r.readiness_score ?? 'N/A'}, Sleep ${r.sleep_hours ?? 'N/A'}h, ` +
      `Soreness ${r.soreness_level ?? 'N/A'}/10, Energy ${r.energy_level ?? 'N/A'}/10, Stress ${r.stress_level ?? 'N/A'}/10`
    ).join('\n')
  : 'No readiness data available'}

KEY METRICS:
- Average Readiness (7d): ${avgReadiness7d?.toFixed(1) ?? 'N/A'}/100
- Consecutive Low Readiness Days: ${consecutiveLowDays}
- Acute:Chronic Training Ratio: ${acuteChronicRatio?.toFixed(2) ?? 'N/A'} (optimal: 0.8-1.3, concerning: >1.3)
- Workouts Last 7 Days: ${workoutCount7d}
- Training Age: ${trainingAgeDays} days

CONTRIBUTING FACTORS:
${contributingFactors.length > 0 ? contributingFactors.map(f => `- ${f}`).join('\n') : '- None identified'}

ACTIVE GOALS:
${activeGoals.length > 0
  ? activeGoals.map(g => `- ${g.category}: ${g.title}${g.target_date ? ` (target: ${g.target_date})` : ''}`).join('\n')
  : '- No active goals'}

TODAY: ${new Date().toISOString().split('T')[0]}

TASK: Analyze the data and provide a deload recommendation. Consider the pre-calculated urgency but adjust if your analysis differs.

Respond with ONLY valid JSON (no markdown, no explanation):
{
  "urgency": "suggested" | "recommended" | "required",
  "reasoning": "2-3 sentences explaining your recommendation based on the specific data",
  "prescription": {
    "duration_days": 5-14,
    "load_reduction_pct": 40-60,
    "volume_reduction_pct": 30-50,
    "focus": "technique" | "mobility" | "active_recovery" | "complete_rest",
    "suggested_start_date": "YYYY-MM-DD"
  }
}`

    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[ai-deload-recommendation] Calling Anthropic Claude API...')

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1024,
        messages: [
          {
            role: 'user',
            content: `${systemPrompt}\n\n${userPrompt}`
          }
        ],
        temperature: 0.3,
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[ai-deload-recommendation] Anthropic API error:', anthropicResponse.status, error)
      throw new Error(`Anthropic API error (${anthropicResponse.status}): ${error.substring(0, 200)}`)
    }

    const completion = await anthropicResponse.json()
    const responseText = completion.content?.[0]?.text

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[ai-deload-recommendation] Received response from Claude')

    // Parse AI response
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[ai-deload-recommendation] Failed to parse AI response:', responseText)
      throw new Error('Failed to parse AI response as JSON')
    }

    // ========================================================================
    // VALIDATE AND SAVE RECOMMENDATION
    // ========================================================================

    // Validate urgency
    const validUrgencies = ['suggested', 'recommended', 'required']
    const finalUrgency = validUrgencies.includes(aiResponse.urgency) ? aiResponse.urgency : calculatedUrgency

    // Validate and clamp prescription values
    const rx = aiResponse.prescription || {}
    const prescription: DeloadPrescription = {
      duration_days: Math.min(Math.max(rx.duration_days || 7, 3), 14),
      load_reduction_pct: Math.min(Math.max(rx.load_reduction_pct || 50, 20), 80),
      volume_reduction_pct: Math.min(Math.max(rx.volume_reduction_pct || 40, 20), 70),
      focus: ['technique', 'mobility', 'active_recovery', 'complete_rest'].includes(rx.focus)
        ? rx.focus
        : 'active_recovery',
      suggested_start_date: rx.suggested_start_date || new Date().toISOString().split('T')[0]
    }

    // Save to database
    const { data: savedRecommendation, error: saveError } = await supabaseClient
      .from('deload_recommendations')
      .insert({
        patient_id,
        urgency: finalUrgency,
        reasoning: aiResponse.reasoning || 'AI-generated deload recommendation based on fatigue analysis.',
        fatigue_score: fatigueScore,
        fatigue_band: fatigueBand,
        avg_readiness_7d: avgReadiness7d,
        acute_chronic_ratio: acuteChronicRatio,
        contributing_factors: contributingFactors,
        duration_days: prescription.duration_days,
        load_reduction_pct: prescription.load_reduction_pct,
        volume_reduction_pct: prescription.volume_reduction_pct,
        focus: prescription.focus,
        suggested_start_date: prescription.suggested_start_date,
        status: 'pending',
        expires_at: new Date(Date.now() + 48 * 60 * 60 * 1000).toISOString()
      })
      .select()
      .single()

    if (saveError) {
      console.error('[ai-deload-recommendation] Error saving recommendation:', saveError)
      // Continue without saving - still return the recommendation
    } else {
      console.log(`[ai-deload-recommendation] Recommendation saved: ${savedRecommendation.id}`)
    }

    // ========================================================================
    // RETURN RESPONSE
    // ========================================================================

    const fatigueSummary: FatigueSummary = {
      fatigue_score: fatigueScore,
      fatigue_band: fatigueBand,
      avg_readiness_7d: avgReadiness7d,
      acute_chronic_ratio: acuteChronicRatio,
      consecutive_low_days: consecutiveLowDays,
      contributing_factors: contributingFactors
    }

    const response: DeloadRecommendationResponse = {
      recommendation_id: savedRecommendation?.id || crypto.randomUUID(),
      deload_recommended: true,
      urgency: finalUrgency,
      reasoning: aiResponse.reasoning || 'Deload recommended based on fatigue analysis.',
      fatigue_summary: fatigueSummary,
      prescription: prescription,
      in_active_deload: false,
      active_deload_info: null,
      cached: false
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-deload-recommendation] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    // Return error with fallback data
    return new Response(
      JSON.stringify({
        error: errorMessage,
        recommendation_id: null,
        deload_recommended: false,
        urgency: null,
        reasoning: 'Unable to analyze fatigue data. Continue with normal training and monitor how you feel.',
        fatigue_summary: {
          fatigue_score: 0,
          fatigue_band: 'low',
          avg_readiness_7d: null,
          acute_chronic_ratio: null,
          consecutive_low_days: 0,
          contributing_factors: []
        },
        prescription: null,
        in_active_deload: false,
        active_deload_info: null,
        cached: false
      } as DeloadRecommendationResponse),
      { status: 500, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  }
})
