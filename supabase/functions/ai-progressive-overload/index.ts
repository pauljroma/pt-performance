// AI Progressive Overload Handler
// Provides AI-powered load progression suggestions based on training history, readiness, and fatigue
// Part of the Auto-Regulation System

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// MARK: - Request/Response Interfaces

interface ProgressiveOverloadRequest {
  patient_id: string
  exercise_template_id: string
  current_load: number
  current_reps: number
  recent_rpe: number
}

interface ProgressionSuggestion {
  next_load: number
  next_reps: number
  confidence: number  // 0-100
  reasoning: string
  progression_type: 'increase' | 'hold' | 'decrease' | 'deload'
}

interface ProgressionAnalysis {
  trend: 'improving' | 'plateaued' | 'declining'
  estimated_1rm: number
  sessions_at_weight: number
  fatigue_impact: string
}

interface ProgressiveOverloadResponse {
  suggestion: ProgressionSuggestion
  analysis: ProgressionAnalysis
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
  current_fatigue: number | null
  fatigue_trend: string | null
  recovery_status: string | null
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
 * Calculate estimated 1RM using Brzycki formula
 * 1RM = weight / (1.0278 - 0.0278 * reps)
 * Valid for reps 1-10
 */
function calculateEstimated1RM(weight: number, reps: number): number {
  if (reps <= 0 || weight <= 0) return 0
  if (reps === 1) return weight
  if (reps > 10) reps = 10  // Cap at 10 reps for accuracy

  const oneRM = weight / (1.0278 - 0.0278 * reps)
  return Math.round(oneRM * 10) / 10  // Round to 1 decimal
}

/**
 * Determine trend from RPE progression
 */
function determineTrend(history: ExerciseHistory[]): 'improving' | 'plateaued' | 'declining' {
  if (history.length < 3) return 'improving'  // Not enough data

  // Get last 5 sessions or all if less
  const recent = history.slice(0, Math.min(5, history.length))

  // Calculate average RPE for first half vs second half
  const mid = Math.floor(recent.length / 2)
  const olderSessions = recent.slice(mid)
  const newerSessions = recent.slice(0, mid)

  const olderAvgRpe = olderSessions.reduce((sum, h) => sum + h.actual_rpe, 0) / olderSessions.length
  const newerAvgRpe = newerSessions.reduce((sum, h) => sum + h.actual_rpe, 0) / newerSessions.length

  // Also check load progression
  const loadIncreased = newerSessions.some(h => h.current_load > olderSessions[0]?.current_load)

  // If load increased with same or lower RPE, improving
  if (loadIncreased && newerAvgRpe <= olderAvgRpe + 0.5) {
    return 'improving'
  }

  // If RPE increased significantly without load increase, declining
  if (newerAvgRpe > olderAvgRpe + 1.0 && !loadIncreased) {
    return 'declining'
  }

  // If load and RPE stable, plateaued
  if (Math.abs(newerAvgRpe - olderAvgRpe) <= 0.5) {
    return 'plateaued'
  }

  return 'improving'
}

/**
 * Count consecutive sessions at the same weight
 */
function countSessionsAtWeight(history: ExerciseHistory[], currentLoad: number): number {
  let count = 0
  for (const session of history) {
    if (Math.abs(session.current_load - currentLoad) < 0.5) {
      count++
    } else {
      break
    }
  }
  return count
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
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestBody: ProgressiveOverloadRequest = await req.json()
    const { patient_id, exercise_template_id, current_load, current_reps, recent_rpe } = requestBody

    // Validate required fields
    if (!patient_id || !exercise_template_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id and exercise_template_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (current_load === undefined || current_reps === undefined || recent_rpe === undefined) {
      return new Response(
        JSON.stringify({ error: 'current_load, current_reps, and recent_rpe are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // --- GATHER CONTEXT ---

    // 1. Fetch exercise history (last 8 sessions for this exercise)
    const { data: historyData } = await supabaseClient
      .from('load_progression_history')
      .select('*')
      .eq('patient_id', patient_id)
      .eq('exercise_template_id', exercise_template_id)
      .order('logged_at', { ascending: false })
      .limit(8)

    const exerciseHistory: ExerciseHistory[] = historyData || []

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

    // 4. Fetch current fatigue level from workload_analytics view if available
    const { data: fatigueData } = await supabaseClient
      .from('workload_analytics')
      .select('fatigue_score, recovery_status')
      .eq('patient_id', patient_id)
      .order('calculated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    const fatigue: FatigueData = {
      current_fatigue: fatigueData?.fatigue_score ?? null,
      fatigue_trend: null,
      recovery_status: fatigueData?.recovery_status ?? null
    }

    // --- CALCULATE ANALYSIS ---

    const trend = determineTrend(exerciseHistory)
    const estimated1RM = calculateEstimated1RM(current_load, current_reps)
    const sessionsAtWeight = countSessionsAtWeight(exerciseHistory, current_load)
    const exerciseType = determineExerciseType(exerciseTemplate)

    // Determine fatigue impact
    let fatigueImpact = 'minimal'
    if (fatigue.current_fatigue !== null) {
      if (fatigue.current_fatigue >= 70) {
        fatigueImpact = 'high - consider deload'
      } else if (fatigue.current_fatigue >= 50) {
        fatigueImpact = 'moderate - maintain or reduce volume'
      } else {
        fatigueImpact = 'low - good for progression'
      }
    }

    // --- HANDLE EDGE CASES ---

    // New exercise - no history
    if (exerciseHistory.length === 0) {
      const suggestion: ProgressionSuggestion = {
        next_load: current_load,
        next_reps: current_reps,
        confidence: 60,
        reasoning: 'This is the first session for this exercise. Maintain current load to establish baseline performance and RPE calibration.',
        progression_type: 'hold'
      }

      const analysis: ProgressionAnalysis = {
        trend: 'improving',
        estimated_1rm: estimated1RM,
        sessions_at_weight: 0,
        fatigue_impact: fatigueImpact
      }

      return new Response(
        JSON.stringify({ suggestion, analysis }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- BUILD AI PROMPT ---

    const systemPrompt = `You are an expert strength and conditioning coach specializing in progressive overload programming. Your task is to analyze a patient's exercise performance data and provide a smart load progression recommendation.

CRITICAL RULES:
1. Safety first - never recommend increases that could lead to injury
2. Consider readiness band and fatigue levels when making recommendations
3. For primary lifts, recommend 2.5-5 lb increases for upper body, 5-10 lb for lower body
4. For accessory work, recommend smaller increments (2.5 lb) or rep increases
5. If RPE is above 9, always recommend hold or decrease
6. If readiness is red/orange, lean toward holding or decreasing
7. After 3+ sessions at same weight with good RPE, consider progression
8. Be specific in your reasoning

READINESS BAND INTERPRETATION:
- Green (80-100): Full progression appropriate
- Yellow (60-79): Conservative progression, prefer rep increases
- Orange (40-59): Hold current load, reduce volume if needed
- Red (0-39): Deload recommended, reduce load 10-15%

PROGRESSION TYPE DEFINITIONS:
- increase: Raise load or reps
- hold: Maintain current prescription
- decrease: Reduce load slightly (5-10%)
- deload: Significant reduction (10-20%) for recovery`

    const historyDescription = exerciseHistory.map((h, i) =>
      `Session ${i + 1} (${new Date(h.logged_at).toLocaleDateString()}): ${h.current_load} lbs x ${h.reps_completed ?? 'N/A'} reps @ RPE ${h.actual_rpe}`
    ).join('\n')

    const userPrompt = `
PATIENT CONTEXT:
- Exercise: ${exerciseTemplate?.name || 'Unknown Exercise'}
- Exercise Type: ${exerciseType}
- Muscle Group: ${exerciseTemplate?.primary_muscle_group || 'Unknown'}
- Is Compound: ${exerciseTemplate?.is_compound ? 'Yes' : 'No'}

CURRENT SESSION:
- Current Load: ${current_load} lbs
- Current Reps: ${current_reps}
- Recent RPE: ${recent_rpe}

READINESS STATE:
- Readiness Band: ${readinessBand || 'Unknown'}
- Readiness Score: ${readiness?.readiness_score ?? 'N/A'}/100
- Energy Level: ${readiness?.energy_level ?? 'N/A'}/10
- Sleep: ${readiness?.sleep_hours ?? 'N/A'} hours
- Soreness: ${readiness?.soreness_level ?? 'N/A'}/10
- Stress: ${readiness?.stress_level ?? 'N/A'}/10

FATIGUE STATUS:
- Current Fatigue: ${fatigue.current_fatigue ?? 'Unknown'}%
- Impact: ${fatigueImpact}

EXERCISE HISTORY (Last 8 Sessions):
${historyDescription || 'No previous sessions recorded'}

CALCULATED METRICS:
- Trend: ${trend}
- Estimated 1RM: ${estimated1RM} lbs
- Sessions at Current Weight: ${sessionsAtWeight}

TASK: Provide a load progression recommendation. Consider the patient's readiness, fatigue, RPE trend, and exercise history.

Respond with valid JSON ONLY (no markdown, no explanation outside JSON):
{
  "next_load": <number>,
  "next_reps": <number>,
  "confidence": <0-100>,
  "reasoning": "<1-2 sentence explanation>",
  "progression_type": "increase" | "hold" | "decrease" | "deload"
}`

    // --- CALL OPENAI ---

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        max_tokens: 500,
        temperature: 0.3,  // Lower temperature for more consistent recommendations
        response_format: { type: 'json_object' }
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('OpenAI API error:', error)

      // Fallback to rule-based recommendation
      return generateFallbackRecommendation(
        current_load,
        current_reps,
        recent_rpe,
        readinessBand,
        trend,
        estimated1RM,
        sessionsAtWeight,
        fatigueImpact,
        exerciseType
      )
    }

    const completion = await openaiResponse.json()
    const aiResponse = JSON.parse(completion.choices[0].message.content)

    // Validate AI response
    if (!aiResponse.next_load || !aiResponse.progression_type) {
      return generateFallbackRecommendation(
        current_load,
        current_reps,
        recent_rpe,
        readinessBand,
        trend,
        estimated1RM,
        sessionsAtWeight,
        fatigueImpact,
        exerciseType
      )
    }

    // Build response
    const suggestion: ProgressionSuggestion = {
      next_load: aiResponse.next_load,
      next_reps: aiResponse.next_reps || current_reps,
      confidence: aiResponse.confidence || 75,
      reasoning: aiResponse.reasoning || 'AI-generated progression recommendation',
      progression_type: aiResponse.progression_type
    }

    const analysis: ProgressionAnalysis = {
      trend,
      estimated_1rm: estimated1RM,
      sessions_at_weight: sessionsAtWeight,
      fatigue_impact: fatigueImpact
    }

    const response: ProgressiveOverloadResponse = {
      suggestion,
      analysis
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in ai-progressive-overload:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        details: error.toString()
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
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
  estimated1RM: number,
  sessionsAtWeight: number,
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
    nextLoad = Math.round(currentLoad * 0.85)
    progressionType = 'deload'
    reasoning = 'Low readiness or high fatigue detected. Recommending deload to support recovery.'
    confidence = 80
  }
  // RPE too high -> decrease
  else if (recentRpe >= 9.5) {
    nextLoad = Math.round(currentLoad * 0.95)
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
  // RPE good and multiple sessions at weight -> increase
  else if (recentRpe <= 7.5 && sessionsAtWeight >= 2) {
    nextLoad = currentLoad + loadIncrement
    progressionType = 'increase'
    reasoning = `RPE indicates capacity for progression. After ${sessionsAtWeight} sessions at this weight, recommending ${loadIncrement}lb increase.`
    confidence = 80
  }
  // RPE moderate, try rep increase first
  else if (recentRpe <= 8 && currentReps < 12) {
    nextReps = currentReps + 1
    progressionType = 'increase'
    reasoning = 'Good RPE but limited sessions at this weight. Recommending rep increase before load increase.'
    confidence = 75
  }
  // Default -> hold
  else {
    progressionType = 'hold'
    reasoning = 'Maintaining current prescription to gather more performance data.'
    confidence = 65
  }

  const suggestion: ProgressionSuggestion = {
    next_load: nextLoad,
    next_reps: nextReps,
    confidence,
    reasoning,
    progression_type: progressionType
  }

  const analysis: ProgressionAnalysis = {
    trend,
    estimated_1rm: estimated1RM,
    sessions_at_weight: sessionsAtWeight,
    fatigue_impact: fatigueImpact
  }

  return new Response(
    JSON.stringify({ suggestion, analysis }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}
