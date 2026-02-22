// AI Progressive Overload Handler
// Provides AI-powered load progression suggestions based on training history, readiness, and fatigue
// Part of the Auto-Regulation System
// Uses Anthropic Claude for intelligent recommendations

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limit.ts'
import { corsHeaders, handleCors } from '../_shared/cors.ts'

// MARK: - Request/Response Interfaces

interface PerformanceEntry {
  date: string
  load: number
  reps: number[]
  rpe: number
}

interface ProgressiveOverloadRequest {
  patient_id: string
  exercise_template_id: string
  recent_performance: PerformanceEntry[]
  // Legacy support
  current_load?: number
  current_reps?: number
  recent_rpe?: number
}

interface PerformanceAnalysis {
  trend: 'improving' | 'plateaued' | 'declining'
  estimated_1rm: number
  velocity_trend: string
  fatigue_impact: string
}

interface ProgressiveOverloadResponse {
  id: string
  next_load: number
  next_reps: number
  confidence: number  // 0-100
  reasoning: string
  progression_type: 'increase' | 'hold' | 'decrease' | 'deload'
  analysis: PerformanceAnalysis
}

// MARK: - Data Models

interface ExerciseHistory {
  id: string
  patient_id: string
  exercise_template_id: string
  session_id: string | null
  logged_at: string
  current_load: number
  load_unit: string
  actual_rpe: number
  reps_completed: number | null
  sets_completed: number | null
  progression_action: string | null
}

interface ExerciseTemplate {
  id: string
  name: string
  category: string | null
  primary_muscle_group: string | null
  is_compound: boolean | null
}

interface DailyReadiness {
  readiness_score: number | null
  energy_level: number | null
  sleep_hours: number | null
  soreness_level: number | null
  stress_level: number | null
}

interface FatigueData {
  fatigue_score: number | null
  fatigue_band: string | null
  acute_chronic_ratio: number | null
}

// MARK: - Helper Functions

/**
 * Calculate readiness band from score
 */
function calculateReadinessBand(score: number | null): string | null {
  if (score === null) return null
  if (score >= 80) return 'green'
  if (score >= 60) return 'yellow'
  if (score >= 40) return 'orange'
  return 'red'
}

/**
 * Calculate estimated 1RM using Epley formula
 * 1RM = weight * (1 + reps / 30)
 * More accurate for higher rep ranges than Brzycki
 */
function calculateEstimated1RM(weight: number, reps: number): number {
  if (reps <= 0 || weight <= 0) return 0
  if (reps === 1) return weight

  // Use Epley formula
  const oneRM = weight * (1 + reps / 30)
  return Math.round(oneRM * 10) / 10  // Round to 1 decimal
}

/**
 * Determine trend from performance entries
 */
function determineTrend(performance: PerformanceEntry[]): 'improving' | 'plateaued' | 'declining' {
  if (performance.length < 2) return 'improving'  // Not enough data

  // Sort by date (most recent first)
  const sorted = [...performance].sort((a, b) =>
    new Date(b.date).getTime() - new Date(a.date).getTime()
  )

  // Get the most recent and oldest entries
  const recent = sorted.slice(0, Math.min(3, sorted.length))
  const older = sorted.slice(Math.min(3, sorted.length))

  if (older.length === 0) {
    // Only have recent data, check load progression
    const loads = recent.map(p => p.load)
    if (loads[0] > loads[loads.length - 1]) return 'improving'
    if (loads[0] < loads[loads.length - 1]) return 'declining'
    return 'plateaued'
  }

  // Calculate average RPE for recent vs older
  const recentAvgRpe = recent.reduce((sum, p) => sum + p.rpe, 0) / recent.length
  const olderAvgRpe = older.reduce((sum, p) => sum + p.rpe, 0) / older.length

  // Calculate average load
  const recentAvgLoad = recent.reduce((sum, p) => sum + p.load, 0) / recent.length
  const olderAvgLoad = older.reduce((sum, p) => sum + p.load, 0) / older.length

  // If load increased with same or lower RPE, improving
  if (recentAvgLoad > olderAvgLoad && recentAvgRpe <= olderAvgRpe + 0.5) {
    return 'improving'
  }

  // If RPE increased significantly without load increase, declining
  if (recentAvgRpe > olderAvgRpe + 1.0 && recentAvgLoad <= olderAvgLoad) {
    return 'declining'
  }

  // If load and RPE relatively stable, plateaued
  if (Math.abs(recentAvgRpe - olderAvgRpe) <= 0.5 && Math.abs(recentAvgLoad - olderAvgLoad) < 5) {
    return 'plateaued'
  }

  return 'improving'
}

/**
 * Analyze velocity trend from rep completion patterns
 */
function analyzeVelocityTrend(performance: PerformanceEntry[]): string {
  if (performance.length < 2) return 'stable'

  // Sort by date (most recent first)
  const sorted = [...performance].sort((a, b) =>
    new Date(b.date).getTime() - new Date(a.date).getTime()
  )

  // Compare rep completion rates between sessions
  const recentEntry = sorted[0]
  const olderEntry = sorted[sorted.length - 1]

  const recentTotalReps = recentEntry.reps.reduce((a, b) => a + b, 0)
  const olderTotalReps = olderEntry.reps.reduce((a, b) => a + b, 0)

  // Normalize by load
  const recentVolumePerLb = recentTotalReps / (recentEntry.load || 1)
  const olderVolumePerLb = olderTotalReps / (olderEntry.load || 1)

  const changePercent = ((recentVolumePerLb - olderVolumePerLb) / olderVolumePerLb) * 100

  if (changePercent > 5) return 'increasing'
  if (changePercent < -5) return 'decreasing'
  return 'stable'
}

/**
 * Format performance data for AI prompt
 */
function formatPerformance(performance: PerformanceEntry[]): string {
  if (performance.length === 0) return 'No previous sessions recorded'

  // Sort by date (most recent first)
  const sorted = [...performance].sort((a, b) =>
    new Date(b.date).getTime() - new Date(a.date).getTime()
  )

  return sorted.map((p, i) => {
    const date = new Date(p.date).toLocaleDateString()
    const repsStr = p.reps.join(', ')
    return `Session ${i + 1} (${date}): ${p.load} lbs x [${repsStr}] reps @ RPE ${p.rpe}`
  }).join('\n')
}

/**
 * Determine if exercise is primary or accessory based on template
 */
function determineExerciseType(template: ExerciseTemplate | null): 'primary' | 'accessory' {
  if (!template) return 'accessory'

  // Compound movements are typically primary
  if (template.is_compound) return 'primary'

  // Check category
  const primaryCategories = ['strength', 'powerlifting', 'compound']
  if (template.category && primaryCategories.includes(template.category.toLowerCase())) {
    return 'primary'
  }

  return 'accessory'
}

// MARK: - Main Handler

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = corsHeaders(origin)

  try {
    const requestBody: ProgressiveOverloadRequest = await req.json()
    const { patient_id, exercise_template_id, recent_performance } = requestBody

    // Rate limit: 10 requests/minute for AI endpoints
    const rateLimitKey = patient_id || req.headers.get('x-forwarded-for') || 'anonymous'
    const { allowed, resetMs } = checkRateLimit(`ai-progressive:${rateLimitKey}`, { windowMs: 60_000, maxRequests: 10 })
    if (!allowed) return rateLimitResponse(resetMs)

    // Validate required fields
    if (!patient_id || !exercise_template_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id and exercise_template_id are required' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // Handle legacy request format
    let performanceData: PerformanceEntry[] = recent_performance || []
    if (performanceData.length === 0 && requestBody.current_load !== undefined) {
      performanceData = [{
        date: new Date().toISOString(),
        load: requestBody.current_load,
        reps: [requestBody.current_reps || 8],
        rpe: requestBody.recent_rpe || 7
      }]
    }

    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // --- GATHER CONTEXT ---

    // 1. Fetch exercise history (last 8 sessions for this exercise) if not provided
    let exerciseHistory: ExerciseHistory[] = []
    if (performanceData.length < 3) {
      const { data: historyData } = await supabaseClient
        .from('load_progression_history')
        .select('*')
        .eq('patient_id', patient_id)
        .eq('exercise_template_id', exercise_template_id)
        .order('logged_at', { ascending: false })
        .limit(8)

      exerciseHistory = historyData || []
    }

    // 2. Fetch exercise template details
    const { data: templateData } = await supabaseClient
      .from('exercise_templates')
      .select('id, name, category, primary_muscle_group, is_compound')
      .eq('id', exercise_template_id)
      .maybeSingle()

    const exerciseTemplate: ExerciseTemplate | null = templateData

    // 3. Fetch today's readiness
    const today = new Date().toISOString().split('T')[0]
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('readiness_score, energy_level, sleep_hours, soreness_level, stress_level')
      .eq('patient_id', patient_id)
      .eq('date', today)
      .maybeSingle()

    const readiness: DailyReadiness | null = readinessData
    const readinessBand = calculateReadinessBand(readiness?.readiness_score ?? null)

    // 4. Fetch current fatigue level
    const { data: fatigueData } = await supabaseClient
      .from('fatigue_accumulation')
      .select('fatigue_score, fatigue_band, acute_chronic_ratio')
      .eq('patient_id', patient_id)
      .order('calculated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    const fatigue: FatigueData = {
      fatigue_score: fatigueData?.fatigue_score ?? null,
      fatigue_band: fatigueData?.fatigue_band ?? null,
      acute_chronic_ratio: fatigueData?.acute_chronic_ratio ?? null
    }

    // --- CALCULATE ANALYSIS ---

    const trend = determineTrend(performanceData)
    const velocityTrend = analyzeVelocityTrend(performanceData)
    const exerciseType = determineExerciseType(exerciseTemplate)

    // Get current load and reps from most recent performance
    const currentLoad = performanceData.length > 0 ? performanceData[0].load : 0
    const currentReps = performanceData.length > 0
      ? Math.round(performanceData[0].reps.reduce((a, b) => a + b, 0) / performanceData[0].reps.length)
      : 8
    const currentRpe = performanceData.length > 0 ? performanceData[0].rpe : 7

    // Calculate estimated 1RM
    const estimated1RM = calculateEstimated1RM(currentLoad, currentReps)

    // Determine fatigue impact
    let fatigueImpact = 'minimal - good for progression'
    if (fatigue.fatigue_score !== null) {
      if (fatigue.fatigue_score >= 70) {
        fatigueImpact = 'high - consider deload'
      } else if (fatigue.fatigue_score >= 50) {
        fatigueImpact = 'moderate - maintain or reduce volume'
      } else {
        fatigueImpact = 'low - good for progression'
      }
    }

    // --- HANDLE EDGE CASES ---

    // New exercise - no history and no performance data
    if (performanceData.length === 0 && exerciseHistory.length === 0) {
      const analysis: PerformanceAnalysis = {
        trend: 'improving',
        estimated_1rm: 0,
        velocity_trend: 'stable',
        fatigue_impact: fatigueImpact
      }

      const response: ProgressiveOverloadResponse = {
        id: crypto.randomUUID(),
        next_load: 0,
        next_reps: 8,
        confidence: 50,
        reasoning: 'No performance data available. Start with a conservative load to establish baseline.',
        progression_type: 'hold',
        analysis
      }

      return new Response(
        JSON.stringify(response),
        { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // --- BUILD AI PROMPT ---

    const systemPrompt = `You are an expert strength and conditioning coach specializing in progressive overload programming. Your task is to analyze a patient's exercise performance data and provide smart load progression recommendations.

CRITICAL RULES:
1. Safety first - never recommend increases that could lead to injury
2. Consider readiness band and fatigue levels when making recommendations
3. For primary lifts, recommend 2.5-5 lb increases for upper body, 5-10 lb for lower body
4. For accessory work, recommend smaller increments (2.5 lb) or rep increases
5. If RPE is above 9, always recommend hold or decrease
6. If readiness is red/orange, lean toward holding or decreasing
7. After 2-3+ sessions at same weight with good RPE (7-8), consider progression
8. Be specific in your reasoning

RPE TARGET ZONES:
- RPE 7-8: Ideal training zone, progression appropriate
- RPE 8-9: Hard effort, consider holding before progressing
- RPE 9+: Maximum effort, do not increase load

READINESS BAND INTERPRETATION:
- Green (80-100): Full progression appropriate
- Yellow (60-79): Conservative progression, prefer rep increases
- Orange (40-59): Hold current load, reduce volume if needed
- Red (0-39): Deload recommended, reduce load 10-15%

PROGRESSION TYPE DEFINITIONS:
- increase: Raise load or reps (2.5-5% load increase typical)
- hold: Maintain current prescription
- decrease: Reduce load slightly (5-10%)
- deload: Significant reduction (10-20%) for recovery`

    const userPrompt = `
PATIENT CONTEXT:
- Exercise: ${exerciseTemplate?.name || 'Unknown Exercise'}
- Exercise Type: ${exerciseType}
- Muscle Group: ${exerciseTemplate?.primary_muscle_group || 'Unknown'}
- Is Compound: ${exerciseTemplate?.is_compound ? 'Yes' : 'No'}

RECENT PERFORMANCE DATA:
${formatPerformance(performanceData)}

READINESS STATE:
- Readiness Band: ${readinessBand || 'Unknown'}
- Readiness Score: ${readiness?.readiness_score ?? 'N/A'}/100
- Energy Level: ${readiness?.energy_level ?? 'N/A'}/10
- Sleep: ${readiness?.sleep_hours ?? 'N/A'} hours
- Soreness: ${readiness?.soreness_level ?? 'N/A'}/10
- Stress: ${readiness?.stress_level ?? 'N/A'}/10

FATIGUE STATUS:
- Fatigue Score: ${fatigue.fatigue_score ?? 'Unknown'}%
- Fatigue Band: ${fatigue.fatigue_band ?? 'Unknown'}
- Acute:Chronic Ratio: ${fatigue.acute_chronic_ratio?.toFixed(2) ?? 'Unknown'}
- Impact Assessment: ${fatigueImpact}

CALCULATED METRICS:
- Performance Trend: ${trend}
- Velocity Trend: ${velocityTrend}
- Estimated 1RM: ${estimated1RM} lbs

TASK: Analyze the performance trend and recommend the next session's load progression.

Consider:
- RPE trends (target 7-8, overshoot indicates fatigue)
- Rep completion rate across sets
- Load progression history
- Current fatigue accumulation
- Safe progression limits (2.5-5% load increases max)

Respond with valid JSON ONLY (no markdown, no explanation outside JSON):
{
  "next_load": <number - recommended load in lbs>,
  "next_reps": <number - target reps per set>,
  "confidence": <0-100 - your confidence in this recommendation>,
  "reasoning": "<1-2 sentence explanation of your recommendation>",
  "progression_type": "increase" | "hold" | "decrease" | "deload"
}`

    // --- CALL ANTHROPIC CLAUDE ---

    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      console.error('[ai-progressive-overload] ANTHROPIC_API_KEY not set, using fallback')
      return generateFallbackRecommendation(
        currentLoad,
        currentReps,
        currentRpe,
        readinessBand,
        trend,
        velocityTrend,
        estimated1RM,
        fatigueImpact,
        exerciseType
      )
    }

    console.log('[ai-progressive-overload] Calling Anthropic Claude API...')

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
        temperature: 0.3,  // Lower temperature for more consistent recommendations
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[ai-progressive-overload] Anthropic API error:', anthropicResponse.status, error)

      // Fallback to rule-based recommendation
      return generateFallbackRecommendation(
        currentLoad,
        currentReps,
        currentRpe,
        readinessBand,
        trend,
        velocityTrend,
        estimated1RM,
        fatigueImpact,
        exerciseType
      )
    }

    const completion = await anthropicResponse.json()

    // Extract text content from Anthropic response
    const responseText = completion.content?.[0]?.text
    if (!responseText) {
      console.error('[ai-progressive-overload] No text content in Anthropic response')
      return generateFallbackRecommendation(
        currentLoad,
        currentReps,
        currentRpe,
        readinessBand,
        trend,
        velocityTrend,
        estimated1RM,
        fatigueImpact,
        exerciseType
      )
    }

    console.log('[ai-progressive-overload] Received response from Claude')

    // Parse JSON from AI response (handle potential markdown wrapping)
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[ai-progressive-overload] Failed to parse AI response:', responseText)
      return generateFallbackRecommendation(
        currentLoad,
        currentReps,
        currentRpe,
        readinessBand,
        trend,
        velocityTrend,
        estimated1RM,
        fatigueImpact,
        exerciseType
      )
    }

    // Validate AI response
    if (!aiResponse.next_load || !aiResponse.progression_type) {
      console.error('[ai-progressive-overload] Invalid AI response structure')
      return generateFallbackRecommendation(
        currentLoad,
        currentReps,
        currentRpe,
        readinessBand,
        trend,
        velocityTrend,
        estimated1RM,
        fatigueImpact,
        exerciseType
      )
    }

    // Build analysis
    const analysis: PerformanceAnalysis = {
      trend,
      estimated_1rm: estimated1RM,
      velocity_trend: velocityTrend,
      fatigue_impact: fatigueImpact
    }

    // Generate suggestion ID and optionally save to database
    const suggestionId = crypto.randomUUID()

    // Save suggestion to database for tracking
    const { error: insertError } = await supabaseClient
      .from('progression_suggestions')
      .insert({
        id: suggestionId,
        patient_id,
        exercise_template_id,
        next_load: aiResponse.next_load,
        next_reps: aiResponse.next_reps || currentReps,
        confidence: aiResponse.confidence || 75,
        reasoning: aiResponse.reasoning || 'AI-generated progression recommendation',
        progression_type: aiResponse.progression_type,
        analysis,
        status: 'pending'
      })

    if (insertError) {
      console.warn('[ai-progressive-overload] Failed to save suggestion:', insertError.message)
      // Continue anyway - don't fail the request
    }

    // Build response
    const response: ProgressiveOverloadResponse = {
      id: suggestionId,
      next_load: aiResponse.next_load,
      next_reps: aiResponse.next_reps || currentReps,
      confidence: aiResponse.confidence || 75,
      reasoning: aiResponse.reasoning || 'AI-generated progression recommendation',
      progression_type: aiResponse.progression_type,
      analysis
    }

    console.log(`[ai-progressive-overload] Suggestion: ${response.progression_type} to ${response.next_load} lbs`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-progressive-overload] Error:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        details: error.toString()
      }),
      { status: 500, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  }
})

// MARK: - Fallback Logic

/**
 * Generate rule-based recommendation when AI is unavailable
 */
function generateFallbackRecommendation(
  currentLoad: number,
  currentReps: number,
  recentRpe: number,
  readinessBand: string | null,
  trend: 'improving' | 'plateaued' | 'declining',
  velocityTrend: string,
  estimated1RM: number,
  fatigueImpact: string,
  exerciseType: 'primary' | 'accessory'
): Response {
  let nextLoad = currentLoad
  let nextReps = currentReps
  let confidence = 70
  let reasoning = ''
  let progressionType: 'increase' | 'hold' | 'decrease' | 'deload' = 'hold'

  // Determine load increment based on exercise type
  const loadIncrement = exerciseType === 'primary' ? 5 : 2.5

  // Red band or high fatigue -> deload
  if (readinessBand === 'red' || fatigueImpact.includes('high')) {
    nextLoad = Math.round(currentLoad * 0.85 * 2) / 2  // Round to nearest 2.5
    progressionType = 'deload'
    reasoning = 'Low readiness or high fatigue detected. Recommending deload to support recovery.'
    confidence = 80
  }
  // RPE too high -> decrease
  else if (recentRpe >= 9.5) {
    nextLoad = Math.round(currentLoad * 0.95 * 2) / 2  // Round to nearest 2.5
    progressionType = 'decrease'
    reasoning = 'RPE is at maximum. Reducing load slightly to maintain quality movement and prevent burnout.'
    confidence = 85
  }
  // Orange band or moderate fatigue -> hold
  else if (readinessBand === 'orange' || fatigueImpact.includes('moderate')) {
    progressionType = 'hold'
    reasoning = 'Moderate readiness/fatigue suggests maintaining current load for this session.'
    confidence = 75
  }
  // Declining trend -> hold or decrease
  else if (trend === 'declining') {
    if (recentRpe >= 8.5) {
      nextLoad = Math.round(currentLoad * 0.95 * 2) / 2
      progressionType = 'decrease'
      reasoning = 'Performance declining with high RPE. Reducing load to rebuild momentum.'
    } else {
      progressionType = 'hold'
      reasoning = 'Performance trend declining. Maintaining load to stabilize before progressing.'
    }
    confidence = 75
  }
  // Good RPE and improving/plateaued -> increase
  else if (recentRpe <= 7.5 && (trend === 'improving' || trend === 'plateaued')) {
    nextLoad = currentLoad + loadIncrement
    progressionType = 'increase'
    reasoning = `RPE indicates capacity for progression. Recommending ${loadIncrement}lb increase for continued adaptation.`
    confidence = 80
  }
  // RPE moderate, try rep increase first
  else if (recentRpe <= 8 && currentReps < 12) {
    nextReps = currentReps + 1
    progressionType = 'increase'
    reasoning = 'Good RPE with room for rep progression. Recommending rep increase before load increase.'
    confidence = 75
  }
  // Default -> hold
  else {
    progressionType = 'hold'
    reasoning = 'Maintaining current prescription to consolidate gains and gather more data.'
    confidence = 65
  }

  const analysis: PerformanceAnalysis = {
    trend,
    estimated_1rm: estimated1RM,
    velocity_trend: velocityTrend,
    fatigue_impact: fatigueImpact
  }

  const response: ProgressiveOverloadResponse = {
    id: crypto.randomUUID(),
    next_load: nextLoad,
    next_reps: nextReps,
    confidence,
    reasoning,
    progression_type: progressionType,
    analysis
  }

  return new Response(
    JSON.stringify(response),
    { status: 200, headers: { ...corsHeaders(), 'Content-Type': 'application/json' } }
  )
}
