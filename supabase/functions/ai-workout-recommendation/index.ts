// AI Workout Recommendation Handler
// Build 352 - AI Quick Pick Feature
// Provides context-aware workout recommendations based on readiness, history, goals

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WorkoutRecommendationRequest {
  patient_id: string
  category_preferences?: string[]  // e.g., ["push", "pull", "legs"]
  duration_preference?: number     // minutes
  time_of_day?: string             // "morning" | "afternoon" | "evening"
}

interface WorkoutRecommendationItem {
  template_id: string
  template_name: string
  match_score: number
  reasoning: string
  category: string | null
  duration_minutes: number | null
  difficulty: string | null
}

interface WorkoutRecommendationResponse {
  recommendation_id: string
  recommendations: WorkoutRecommendationItem[]
  reasoning: string
  context_summary: {
    readiness_band: string | null
    readiness_score: number | null
    recent_workout_count: number
    active_goals: string[]
  }
  cached?: boolean
}

interface SystemTemplate {
  id: string
  name: string
  description: string | null
  category: string | null
  difficulty: string | null
  duration_minutes: number | null
  tags: string[] | null
}

interface RecentWorkout {
  name: string
  category: string | null
  avg_rpe: number | null
  avg_pain: number | null
  completed_at: string
}

interface PatientGoal {
  category: string
  title: string
  progress: number
}

function calculateReadinessBand(score: number | null): string | null {
  if (score === null) return null
  if (score >= 80) return 'green'
  if (score >= 60) return 'yellow'
  if (score >= 40) return 'orange'
  return 'red'
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestBody: WorkoutRecommendationRequest = await req.json()
    const { patient_id, category_preferences, duration_preference, time_of_day } = requestBody

    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Check if we have a recent recommendation (cache for 15 minutes)
    const fifteenMinutesAgo = new Date(Date.now() - 15 * 60 * 1000).toISOString()
    const { data: recentRecommendation } = await supabaseClient
      .from('workout_recommendations')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('created_at', fifteenMinutesAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (recentRecommendation) {
      // Return cached recommendation
      return new Response(
        JSON.stringify({
          recommendation_id: recentRecommendation.id,
          recommendations: recentRecommendation.recommendations,
          reasoning: recentRecommendation.reasoning,
          context_summary: recentRecommendation.context?.context_summary || {
            readiness_band: null,
            readiness_score: null,
            recent_workout_count: 0,
            active_goals: []
          },
          cached: true
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- GATHER CONTEXT ---

    // 1. Get today's readiness
    const today = new Date().toISOString().split('T')[0]
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .eq('date', today)
      .maybeSingle()

    const readinessScore = readinessData?.readiness_score ?? null
    const readinessBand = calculateReadinessBand(readinessScore)

    // 2. Get recent workout history (last 7 days)
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
    const { data: recentWorkouts } = await supabaseClient
      .from('manual_sessions')
      .select(`
        id,
        completed_at,
        source_template_id,
        system_workout_templates(name, category)
      `)
      .eq('patient_id', patient_id)
      .eq('completed', true)
      .gte('completed_at', sevenDaysAgo)
      .order('completed_at', { ascending: false })
      .limit(10)

    const workoutHistory: RecentWorkout[] = (recentWorkouts || []).map((w: any) => ({
      name: w.system_workout_templates?.name || 'Manual Workout',
      category: w.system_workout_templates?.category || null,
      avg_rpe: null, // Could be computed from exercise_logs if needed
      avg_pain: null,
      completed_at: w.completed_at
    }))

    // 3. Get active patient goals
    const { data: goalsData } = await supabaseClient
      .from('patient_goals')
      .select('category, title, current_value, target_value')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(10)

    const activeGoals: PatientGoal[] = (goalsData || []).map((g: any) => ({
      category: g.category || 'general',
      title: g.title,
      progress: g.target_value > 0 ? (g.current_value || 0) / g.target_value : 0
    }))

    // 4. Get available workout templates
    let templateQuery = supabaseClient
      .from('system_workout_templates')
      .select('id, name, description, category, difficulty, duration_minutes, tags')
      .limit(100)

    // Apply duration filter if provided (±15 min tolerance)
    if (duration_preference) {
      const minDuration = duration_preference - 15
      const maxDuration = duration_preference + 15
      templateQuery = templateQuery
        .gte('duration_minutes', minDuration)
        .lte('duration_minutes', maxDuration)
    }

    const { data: templates } = await templateQuery

    if (!templates || templates.length === 0) {
      return new Response(
        JSON.stringify({
          error: 'No workout templates available',
          recommendation_id: null,
          recommendations: [],
          reasoning: 'No templates match the specified criteria.',
          context_summary: {
            readiness_band: readinessBand,
            readiness_score: readinessScore,
            recent_workout_count: workoutHistory.length,
            active_goals: activeGoals.map(g => g.category)
          }
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- BUILD AI PROMPT ---

    const systemPrompt = `You are a sports science and physical therapy workout recommendation expert. Your task is to select the BEST workout templates for a patient based on their current recovery state, training history, and goals.

CRITICAL RULES:
1. ONLY recommend workouts from the provided template list - use EXACT template IDs
2. Consider recovery status - fatigued patients need lighter workouts or mobility
3. Avoid repeating the same workout categories from recent history (last 3-4 days)
4. Align recommendations with patient's active goals when possible
5. Return EXACTLY 3 recommendations, ranked by suitability (best first)
6. Be specific in your reasoning - explain why each workout fits

READINESS BAND INTERPRETATION:
- Green (80-100): Full intensity workouts appropriate, any category
- Yellow (60-79): Can train normally but consider moderate intensity
- Orange (40-59): Reduced volume/intensity - prioritize mobility, light cardio, technique work
- Red (0-39): Recovery-focused ONLY - mobility, yoga, stretching, light walking

TIME OF DAY CONSIDERATIONS:
- Morning: Great for strength, HIIT, energizing workouts
- Afternoon: Peak performance time, good for any workout type
- Evening: Consider recovery-focused or moderate intensity to not disrupt sleep`

    const userPrompt = `
PATIENT CONTEXT:
- Readiness Score: ${readinessScore !== null ? `${readinessScore}/100` : 'Unknown (treat as yellow band)'}
- Readiness Band: ${readinessBand || 'Unknown'}
- Time of Day: ${time_of_day || 'Unknown'}
${readinessData ? `- Sleep: ${readinessData.sleep_hours ?? 'N/A'} hours
- Soreness: ${readinessData.soreness_level ?? 'N/A'}/10
- Energy: ${readinessData.energy_level ?? 'N/A'}/10
- Stress: ${readinessData.stress_level ?? 'N/A'}/10` : '- No detailed readiness data available'}

RECENT WORKOUT HISTORY (Last 7 Days):
${workoutHistory.length > 0
  ? workoutHistory.map(w => `- ${w.name} (${w.category || 'general'}) - ${new Date(w.completed_at).toLocaleDateString()}`).join('\n')
  : 'No recent workouts - patient may be returning from break'}

ACTIVE GOALS:
${activeGoals.length > 0
  ? activeGoals.map(g => `- ${g.category}: ${g.title} (${Math.round(g.progress * 100)}% complete)`).join('\n')
  : 'No active goals set - focus on general fitness and recovery'}

USER PREFERENCES:
- Preferred Categories: ${category_preferences?.length ? category_preferences.join(', ') : 'Any (no specific preference)'}
- Preferred Duration: ${duration_preference ? `~${duration_preference} minutes` : 'Any duration'}

AVAILABLE WORKOUT TEMPLATES (Select from these ONLY):
${templates.map((t: SystemTemplate) => `
ID: ${t.id}
Name: ${t.name}
Category: ${t.category || 'general'}
Duration: ${t.duration_minutes || 'N/A'} min
Difficulty: ${t.difficulty || 'moderate'}
Tags: ${t.tags?.join(', ') || 'none'}
Description: ${t.description ? t.description.substring(0, 100) + '...' : 'N/A'}
---`).join('')}

TASK: Select the 3 BEST workouts for this patient RIGHT NOW. Consider their recovery state, recent training, and goals.

Respond with valid JSON ONLY (no markdown, no explanation outside JSON):
{
  "recommendations": [
    {
      "template_id": "exact-uuid-from-list-above",
      "template_name": "exact workout name",
      "match_score": 85,
      "reasoning": "1-2 sentence explanation of why this workout is ideal for the patient right now"
    },
    {
      "template_id": "second-best-uuid",
      "template_name": "workout name",
      "match_score": 75,
      "reasoning": "explanation"
    },
    {
      "template_id": "third-best-uuid",
      "template_name": "workout name",
      "match_score": 65,
      "reasoning": "explanation"
    }
  ],
  "overall_reasoning": "2-3 sentence summary of why these workouts are optimal given patient's current state, recent history, and goals"
}`

    // --- CALL OPENAI ---

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4o',  // Latest GPT-4 model with better performance
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: userPrompt }
        ],
        max_tokens: 1200,
        temperature: 0.4,  // Balanced: some variety but mostly consistent
        response_format: { type: 'json_object' }
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('OpenAI API error:', openaiResponse.status, error)
      throw new Error(`OpenAI API error (${openaiResponse.status}): ${error.substring(0, 200)}`)
    }

    const completion = await openaiResponse.json()
    const aiResponse = JSON.parse(completion.choices[0].message.content)

    // --- VALIDATE AI RESPONSE ---

    if (!aiResponse.recommendations || !Array.isArray(aiResponse.recommendations)) {
      throw new Error('Invalid AI response: missing recommendations array')
    }

    // Validate each recommendation references a real template
    const validatedRecommendations: WorkoutRecommendationItem[] = []
    for (const rec of aiResponse.recommendations) {
      const matchedTemplate = templates.find((t: SystemTemplate) => t.id === rec.template_id)
      if (!matchedTemplate) {
        console.warn(`AI selected invalid template ID: ${rec.template_id}, attempting name match`)
        // Try to find by name as fallback
        const nameMatch = templates.find((t: SystemTemplate) =>
          t.name.toLowerCase() === rec.template_name?.toLowerCase()
        )
        if (nameMatch) {
          validatedRecommendations.push({
            template_id: nameMatch.id,
            template_name: nameMatch.name,
            match_score: rec.match_score || 70,
            reasoning: rec.reasoning || 'AI recommended this workout',
            category: nameMatch.category,
            duration_minutes: nameMatch.duration_minutes,
            difficulty: nameMatch.difficulty
          })
        }
      } else {
        validatedRecommendations.push({
          template_id: matchedTemplate.id,
          template_name: matchedTemplate.name,
          match_score: rec.match_score || 70,
          reasoning: rec.reasoning || 'AI recommended this workout',
          category: matchedTemplate.category,
          duration_minutes: matchedTemplate.duration_minutes,
          difficulty: matchedTemplate.difficulty
        })
      }
    }

    // Ensure we have at least 1 recommendation
    if (validatedRecommendations.length === 0) {
      // Fallback: pick first 3 templates that match preferences
      const fallbacks = templates.slice(0, 3)
      for (const fb of fallbacks) {
        validatedRecommendations.push({
          template_id: fb.id,
          template_name: fb.name,
          match_score: 50,
          reasoning: 'Suggested based on your preferences',
          category: fb.category,
          duration_minutes: fb.duration_minutes,
          difficulty: fb.difficulty
        })
      }
    }

    // --- BUILD CONTEXT SUMMARY ---

    const contextSummary = {
      readiness_band: readinessBand,
      readiness_score: readinessScore,
      recent_workout_count: workoutHistory.length,
      active_goals: activeGoals.map(g => g.category)
    }

    // --- SAVE TO DATABASE ---

    const { data: savedRecommendation, error: saveError } = await supabaseClient
      .from('workout_recommendations')
      .insert({
        patient_id,
        recommendations: validatedRecommendations,
        reasoning: aiResponse.overall_reasoning || 'AI-generated workout recommendations',
        context: {
          category_preferences,
          duration_preference,
          time_of_day,
          context_summary: contextSummary,
          workout_history_count: workoutHistory.length,
          goals_count: activeGoals.length
        }
      })
      .select()
      .single()

    if (saveError) {
      console.error('Error saving recommendation:', saveError)
      // Continue without saving - don't fail the request
    }

    // --- RETURN RESPONSE ---

    const response: WorkoutRecommendationResponse = {
      recommendation_id: savedRecommendation?.id || crypto.randomUUID(),
      recommendations: validatedRecommendations,
      reasoning: aiResponse.overall_reasoning || 'Workouts selected based on your readiness and preferences',
      context_summary: contextSummary
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in ai-workout-recommendation:', error)
    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        details: error.toString()
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
