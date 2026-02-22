// AI Nutrition Recommendation Handler
// Build 138 - Nutrition Tracking Enhancement
// Provides context-aware nutrition recommendations based on workouts, recovery, and daily intake

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limit.ts'
import { corsHeaders, handleCors } from '../_shared/cors.ts'

interface NutritionRecommendationRequest {
  patient_id: string
  time_of_day: string  // e.g., '2:00 PM'
  available_foods?: string[]
  context?: {
    next_workout_time?: string
    workout_type?: string
  }
}

interface NutritionRecommendationResponse {
  recommendation_id: string
  recommendation_text: string
  target_macros: {
    protein: number
    carbs: number
    fats: number
    calories: number
  }
  reasoning: string
  suggested_timing: string
}

interface DailyNutritionSummary {
  total_calories: number
  total_protein: number
  total_carbs: number
  total_fats: number
  goal_calories: number
  goal_protein: number
  goal_carbs: number
  goal_fats: number
  calories_remaining: number
  protein_remaining: number
  carbs_remaining: number
  fats_remaining: number
}

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = corsHeaders(origin)

  try {
    const requestBody: NutritionRecommendationRequest = await req.json()
    const { patient_id, time_of_day, available_foods, context } = requestBody

    // Rate limit: 10 requests/minute for AI endpoints
    const rateLimitKey = patient_id || req.headers.get('x-forwarded-for') || 'anonymous'
    const { allowed, resetMs } = checkRateLimit(`ai-nutrition-rec:${rateLimitKey}`, { windowMs: 60_000, maxRequests: 10 })
    if (!allowed) return rateLimitResponse(resetMs)

    if (!patient_id || !time_of_day) {
      return new Response(
        JSON.stringify({ error: 'patient_id and time_of_day required' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Check if we have a recent recommendation (cache for 30 minutes)
    const thirtyMinutesAgo = new Date(Date.now() - 30 * 60 * 1000).toISOString()
    const { data: recentRecommendation } = await supabaseClient
      .from('nutrition_recommendations')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('created_at', thirtyMinutesAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (recentRecommendation) {
      // Return cached recommendation
      return new Response(
        JSON.stringify({
          recommendation_id: recentRecommendation.id,
          recommendation_text: recentRecommendation.recommendation_text,
          target_macros: recentRecommendation.target_macros,
          reasoning: recentRecommendation.reasoning,
          suggested_timing: time_of_day,
          cached: true
        }),
        { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // Get today's nutrition summary
    const today = new Date().toISOString().split('T')[0]
    const { data: nutritionSummary, error: summaryError } = await supabaseClient
      .rpc('get_daily_nutrition_summary', {
        p_patient_id: patient_id,
        p_date: today
      })

    if (summaryError) {
      console.error('Error fetching nutrition summary:', summaryError)
      throw summaryError
    }

    const summary: DailyNutritionSummary = nutritionSummary[0] || {
      total_calories: 0,
      total_protein: 0,
      total_carbs: 0,
      total_fats: 0,
      goal_calories: 2000,
      goal_protein: 150,
      goal_carbs: 200,
      goal_fats: 65,
      calories_remaining: 2000,
      protein_remaining: 150,
      carbs_remaining: 200,
      fats_remaining: 65
    }

    // Get today's scheduled sessions
    const { data: scheduledSessions } = await supabaseClient
      .from('scheduled_sessions')
      .select('scheduled_time, sessions(name, description)')
      .eq('patient_id', patient_id)
      .eq('scheduled_date', today)
      .eq('status', 'scheduled')
      .order('scheduled_time', { ascending: true })

    // Find next workout
    let nextWorkout = null
    let hoursUntilWorkout = null
    if (scheduledSessions && scheduledSessions.length > 0) {
      const currentTime = new Date()
      for (const session of scheduledSessions) {
        const workoutTime = new Date(`${today}T${session.scheduled_time}`)
        if (workoutTime > currentTime) {
          nextWorkout = session
          hoursUntilWorkout = (workoutTime.getTime() - currentTime.getTime()) / (1000 * 60 * 60)
          break
        }
      }
    }

    // Get latest daily readiness
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .order('date', { ascending: false })
      .limit(1)
      .maybeSingle()

    // Build context for OpenAI
    const workoutContext = context?.next_workout_time || context?.workout_type
      ? `Next workout: ${context.workout_type || 'session'} at ${context.next_workout_time || 'unknown time'}`
      : nextWorkout
        ? `Next workout: "${nextWorkout.sessions.name}" in ${hoursUntilWorkout?.toFixed(1)} hours (${nextWorkout.scheduled_time})`
        : 'No upcoming workouts scheduled today'

    const recoveryContext = readinessData
      ? `Recovery Status:
- Readiness Score: ${readinessData.readiness_score}/100
- Sleep: ${readinessData.sleep_hours || 'N/A'} hours
- Soreness: ${readinessData.soreness_level || 'N/A'}/10
- Energy: ${readinessData.energy_level || 'N/A'}/10
- Stress: ${readinessData.stress_level || 'N/A'}/10`
      : 'No recovery data available'

    const availableFoodsText = available_foods && available_foods.length > 0
      ? `Available foods: ${available_foods.join(', ')}`
      : 'No specific food preferences provided'

    // Build OpenAI prompt
    const prompt = `You are a sports nutritionist helping a physical therapy patient optimize their nutrition for recovery and performance.

CURRENT TIME: ${time_of_day}

DAILY NUTRITION STATUS:
- Consumed: ${summary.total_calories} calories, ${summary.total_protein}g protein, ${summary.total_carbs}g carbs, ${summary.total_fats}g fats
- Goals: ${summary.goal_calories} calories, ${summary.goal_protein}g protein, ${summary.goal_carbs}g carbs, ${summary.goal_fats}g fats
- Remaining: ${summary.calories_remaining} calories, ${summary.protein_remaining}g protein, ${summary.carbs_remaining}g carbs, ${summary.fats_remaining}g fats

${workoutContext}

${recoveryContext}

${availableFoodsText}

TASK: Recommend a specific meal or snack for RIGHT NOW (${time_of_day}).

GUIDELINES:
1. Consider macro distribution based on remaining daily needs
2. If workout is within 2 hours: prioritize easily digestible carbs (30-40g) + moderate protein (15-20g)
3. If workout is 2-4 hours away: balanced meal with protein (25-35g) + complex carbs (40-60g)
4. Post-workout (within 2 hours): protein-rich (30-40g) + fast carbs (40-50g) for recovery
5. If low recovery score (<60): lighter portions, easily digestible foods
6. If high soreness (>7): anti-inflammatory foods, adequate protein
7. If low energy (<5): quick energy sources, B vitamins
8. Don't exceed remaining macros unless patient is severely under-eating

RESPONSE FORMAT (JSON):
{
  "recommendation_text": "Specific meal suggestion with portion sizes and foods",
  "target_macros": {
    "protein": <grams>,
    "carbs": <grams>,
    "fats": <grams>,
    "calories": <total>
  },
  "reasoning": "Brief explanation of why this meal is optimal right now (2-3 sentences)",
  "suggested_timing": "When to eat this (e.g., 'Eat now', 'Within 30 minutes', 'In 1-2 hours before workout')"
}

Be specific, practical, and focused on recovery and performance. Keep recommendations realistic and achievable.`

    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o-mini',  // Cheaper and faster model
        messages: [
          {
            role: 'system',
            content: 'You are a sports nutritionist specializing in physical therapy and athletic recovery. Always respond with valid JSON only.'
          },
          {
            role: 'user',
            content: prompt
          }
        ],
        max_tokens: 800,
        temperature: 0.7,
        response_format: { type: 'json_object' }
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('OpenAI API error:', error)
      throw new Error('Failed to generate nutrition recommendation')
    }

    const completion = await openaiResponse.json()
    const aiResponse = JSON.parse(completion.choices[0].message.content)

    // Validate AI response structure
    if (!aiResponse.recommendation_text || !aiResponse.target_macros || !aiResponse.reasoning) {
      throw new Error('Invalid AI response format')
    }

    // Build context object for storage
    const contextData = {
      time_of_day,
      next_workout_time: context?.next_workout_time || nextWorkout?.scheduled_time || null,
      workout_type: context?.workout_type || nextWorkout?.sessions?.name || null,
      hours_until_workout: hoursUntilWorkout,
      readiness_score: readinessData?.readiness_score || null,
      sleep_hours: readinessData?.sleep_hours || null,
      soreness_level: readinessData?.soreness_level || null,
      energy_level: readinessData?.energy_level || null,
      calories_remaining: summary.calories_remaining,
      protein_remaining: summary.protein_remaining,
      available_foods: available_foods || null
    }

    // Save recommendation to database
    const { data: savedRecommendation, error: saveError } = await supabaseClient
      .from('nutrition_recommendations')
      .insert({
        patient_id,
        recommendation_text: aiResponse.recommendation_text,
        target_macros: aiResponse.target_macros,
        reasoning: aiResponse.reasoning,
        context: contextData
      })
      .select()
      .single()

    if (saveError) {
      console.error('Error saving recommendation:', saveError)
      throw saveError
    }

    // Return recommendation
    const response: NutritionRecommendationResponse = {
      recommendation_id: savedRecommendation.id,
      recommendation_text: aiResponse.recommendation_text,
      target_macros: aiResponse.target_macros,
      reasoning: aiResponse.reasoning,
      suggested_timing: aiResponse.suggested_timing || 'Eat now'
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in ai-nutrition-recommendation:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        details: error.toString()
      }),
      { status: 500, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  }
})
