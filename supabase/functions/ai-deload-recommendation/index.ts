// AI Deload Recommendation Handler
// Build 352 - AI Deload Analysis Feature
// Analyzes fatigue accumulation and recommends deload periods when needed

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface DeloadRecommendationRequest {
  patient_id: string
}

interface FatigueSummary {
  fatigue_score: number
  fatigue_band: string
  avg_readiness_7d: number
  acute_chronic_ratio: number
  consecutive_low_days: number
  contributing_factors: string[]
}

interface DeloadPrescription {
  duration_days: number        // 5-7 days
  load_reduction_pct: number   // 40-60%
  volume_reduction_pct: number // 30-50%
  focus: string                // "technique", "mobility", "active_recovery"
  suggested_start_date: string
}

interface DeloadRecommendationResponse {
  recommendation_id: string
  deload_recommended: boolean
  urgency: 'none' | 'suggested' | 'recommended' | 'required'
  reasoning: string
  fatigue_summary: FatigueSummary
  deload_prescription: DeloadPrescription | null
}

interface ReadinessEntry {
  date: string
  readiness_score: number | null
  sleep_hours: number | null
  soreness_level: number | null
  energy_level: number | null
  stress_level: number | null
}

interface WorkoutEntry {
  completed_at: string
  duration_minutes: number | null
  rpe: number | null
  category: string | null
}

interface PatientGoal {
  category: string
  title: string
  target_date: string | null
}

function calculateFatigueBand(score: number): string {
  if (score >= 80) return 'critical'
  if (score >= 60) return 'high'
  if (score >= 40) return 'moderate'
  if (score >= 20) return 'low'
  return 'minimal'
}

function determineUrgency(fatigueScore: number, consecutiveLowDays: number, acuteChronicRatio: number): 'none' | 'suggested' | 'recommended' | 'required' {
  // Required: Critical fatigue or dangerous acute:chronic ratio
  if (fatigueScore >= 80 || acuteChronicRatio >= 1.5 || consecutiveLowDays >= 5) {
    return 'required'
  }
  // Recommended: High fatigue or elevated acute:chronic ratio
  if (fatigueScore >= 60 || acuteChronicRatio >= 1.3 || consecutiveLowDays >= 4) {
    return 'recommended'
  }
  // Suggested: Moderate fatigue indicators
  if (fatigueScore >= 40 || acuteChronicRatio >= 1.2 || consecutiveLowDays >= 3) {
    return 'suggested'
  }
  return 'none'
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestBody: DeloadRecommendationRequest = await req.json()
    const { patient_id } = requestBody

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

    // Check for recent recommendation (cache for 6 hours)
    const sixHoursAgo = new Date(Date.now() - 6 * 60 * 60 * 1000).toISOString()
    const { data: recentRecommendation } = await supabaseClient
      .from('deload_recommendations')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('created_at', sixHoursAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (recentRecommendation) {
      // Return cached recommendation
      return new Response(
        JSON.stringify({
          recommendation_id: recentRecommendation.id,
          deload_recommended: recentRecommendation.deload_recommended,
          urgency: recentRecommendation.urgency,
          reasoning: recentRecommendation.reasoning,
          fatigue_summary: recentRecommendation.fatigue_summary,
          deload_prescription: recentRecommendation.prescription,
          cached: true
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // --- GATHER CONTEXT ---

    // 1. Get readiness data for last 7 days
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo)
      .order('date', { ascending: false })
      .limit(7)

    const readinessEntries: ReadinessEntry[] = readinessData || []

    // 2. Get readiness data for last 28 days (for acute:chronic calculation)
    const twentyEightDaysAgo = new Date(Date.now() - 28 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const { data: readinessData28d } = await supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score')
      .eq('patient_id', patient_id)
      .gte('date', twentyEightDaysAgo)
      .order('date', { ascending: false })

    // 3. Get recent workout history (last 7 days)
    const { data: recentWorkouts } = await supabaseClient
      .from('manual_sessions')
      .select(`
        id,
        completed_at,
        duration_minutes,
        system_workout_templates(category)
      `)
      .eq('patient_id', patient_id)
      .eq('completed', true)
      .gte('completed_at', new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString())
      .order('completed_at', { ascending: false })
      .limit(14)

    // 4. Get workout history for last 28 days (for acute:chronic calculation)
    const { data: workouts28d } = await supabaseClient
      .from('manual_sessions')
      .select('id, completed_at, duration_minutes')
      .eq('patient_id', patient_id)
      .eq('completed', true)
      .gte('completed_at', new Date(Date.now() - 28 * 24 * 60 * 60 * 1000).toISOString())

    // 5. Get patient goals for context
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

    // 6. Get patient profile for training age context
    const { data: patientData } = await supabaseClient
      .from('patients')
      .select('id, created_at')
      .eq('id', patient_id)
      .maybeSingle()

    // --- CALCULATE FATIGUE METRICS ---

    // Calculate average readiness over 7 days
    const readinessScores7d = readinessEntries
      .filter(r => r.readiness_score !== null)
      .map(r => r.readiness_score as number)
    const avgReadiness7d = readinessScores7d.length > 0
      ? readinessScores7d.reduce((a, b) => a + b, 0) / readinessScores7d.length
      : 50 // Default if no data

    // Calculate consecutive low readiness days (below 60)
    let consecutiveLowDays = 0
    for (const entry of readinessEntries) {
      if (entry.readiness_score !== null && entry.readiness_score < 60) {
        consecutiveLowDays++
      } else {
        break
      }
    }

    // Calculate acute:chronic training load ratio
    // Acute = last 7 days, Chronic = last 28 days average
    const workoutCount7d = recentWorkouts?.length || 0
    const workoutCount28d = workouts28d?.length || 0
    const avgWorkoutsPerWeek28d = workoutCount28d / 4 // 4 weeks

    // Acute:Chronic ratio (training frequency based)
    const acuteChronicRatio = avgWorkoutsPerWeek28d > 0
      ? workoutCount7d / avgWorkoutsPerWeek28d
      : workoutCount7d > 3 ? 1.3 : 1.0 // If no history, estimate based on current week

    // Identify contributing factors
    const contributingFactors: string[] = []

    // Sleep analysis
    const avgSleep = readinessEntries
      .filter(r => r.sleep_hours !== null)
      .map(r => r.sleep_hours as number)
    if (avgSleep.length > 0) {
      const avgSleepHours = avgSleep.reduce((a, b) => a + b, 0) / avgSleep.length
      if (avgSleepHours < 6) contributingFactors.push('severe_sleep_deficit')
      else if (avgSleepHours < 7) contributingFactors.push('sleep_deficit')
    }

    // Soreness analysis
    const sorenessLevels = readinessEntries
      .filter(r => r.soreness_level !== null)
      .map(r => r.soreness_level as number)
    if (sorenessLevels.length > 0) {
      const avgSoreness = sorenessLevels.reduce((a, b) => a + b, 0) / sorenessLevels.length
      if (avgSoreness >= 7) contributingFactors.push('high_soreness')
      else if (avgSoreness >= 5) contributingFactors.push('elevated_soreness')
    }

    // Energy analysis
    const energyLevels = readinessEntries
      .filter(r => r.energy_level !== null)
      .map(r => r.energy_level as number)
    if (energyLevels.length > 0) {
      const avgEnergy = energyLevels.reduce((a, b) => a + b, 0) / energyLevels.length
      if (avgEnergy <= 4) contributingFactors.push('low_energy')
    }

    // Stress analysis
    const stressLevels = readinessEntries
      .filter(r => r.stress_level !== null)
      .map(r => r.stress_level as number)
    if (stressLevels.length > 0) {
      const avgStress = stressLevels.reduce((a, b) => a + b, 0) / stressLevels.length
      if (avgStress >= 7) contributingFactors.push('high_stress')
    }

    // Training load factors
    if (acuteChronicRatio >= 1.3) contributingFactors.push('high_training_load')
    if (workoutCount7d >= 6) contributingFactors.push('high_training_frequency')
    if (consecutiveLowDays >= 3) contributingFactors.push('accumulated_fatigue')

    // Calculate composite fatigue score (0-100)
    // Higher = more fatigued, needs deload more urgently
    let fatigueScore = 0

    // Base score from inverted readiness (lower readiness = higher fatigue)
    fatigueScore += (100 - avgReadiness7d) * 0.35

    // Consecutive low days contribution
    fatigueScore += Math.min(consecutiveLowDays * 8, 25)

    // Acute:Chronic ratio contribution
    if (acuteChronicRatio >= 1.5) fatigueScore += 25
    else if (acuteChronicRatio >= 1.3) fatigueScore += 15
    else if (acuteChronicRatio >= 1.2) fatigueScore += 10

    // Contributing factors add to score
    fatigueScore += Math.min(contributingFactors.length * 5, 20)

    // Cap at 100
    fatigueScore = Math.min(Math.round(fatigueScore), 100)

    const fatigueBand = calculateFatigueBand(fatigueScore)
    const urgency = determineUrgency(fatigueScore, consecutiveLowDays, acuteChronicRatio)

    // --- BUILD AI PROMPT ---

    const systemPrompt = `You are a sports science and physical therapy deload recommendation expert. Your task is to analyze fatigue indicators and recommend appropriate deload strategies when needed.

CRITICAL RULES:
1. A deload is a planned reduction in training volume and intensity to allow recovery
2. Recommend deloads conservatively - only when data strongly supports it
3. Consider upcoming goals when timing deload recommendations
4. Deload duration should be 5-7 days
5. Load reduction should be 40-60% of normal intensity
6. Volume reduction should be 30-50% of normal sets/reps
7. Focus options: "technique" (skill work), "mobility" (flexibility/movement), "active_recovery" (light activity)

URGENCY LEVELS:
- none: No deload needed, continue normal training
- suggested: Mild fatigue detected, patient may benefit from lighter week
- recommended: Significant fatigue detected, deload strongly advised
- required: Critical fatigue levels, deload is essential to prevent overtraining/injury

FATIGUE BAND INTERPRETATION:
- minimal (0-19): Well recovered, full training appropriate
- low (20-39): Minor fatigue, normal training with awareness
- moderate (40-59): Notable fatigue accumulation, monitor closely
- high (60-79): Significant overreach, deload recommended
- critical (80-100): Dangerous fatigue levels, deload required

TRAINING AGE CONSIDERATIONS:
- Newer trainees (<6 months) may need more frequent deloads
- Experienced trainees can tolerate higher loads but still need periodic deloads
- Always err on the side of caution for injury prevention`

    const userPrompt = `
PATIENT FATIGUE ANALYSIS:

Fatigue Score: ${fatigueScore}/100
Fatigue Band: ${fatigueBand}
Calculated Urgency: ${urgency}

READINESS TREND (Last 7 Days):
${readinessEntries.length > 0
    ? readinessEntries.map(r => `- ${r.date}: Score ${r.readiness_score ?? 'N/A'}, Sleep ${r.sleep_hours ?? 'N/A'}h, Soreness ${r.soreness_level ?? 'N/A'}/10, Energy ${r.energy_level ?? 'N/A'}/10, Stress ${r.stress_level ?? 'N/A'}/10`).join('\n')
    : 'No readiness data available - assume moderate fatigue'}

KEY METRICS:
- Average Readiness (7d): ${avgReadiness7d.toFixed(1)}/100
- Consecutive Low Readiness Days: ${consecutiveLowDays}
- Acute:Chronic Training Ratio: ${acuteChronicRatio.toFixed(2)} (>1.3 is concerning)
- Workouts Last 7 Days: ${workoutCount7d}
- Workouts Last 28 Days: ${workoutCount28d}

CONTRIBUTING FACTORS:
${contributingFactors.length > 0 ? contributingFactors.map(f => `- ${f}`).join('\n') : '- No significant contributing factors identified'}

TRAINING HISTORY:
- Account Age: ${patientData?.created_at ? Math.floor((Date.now() - new Date(patientData.created_at).getTime()) / (1000 * 60 * 60 * 24)) : 'Unknown'} days
- Recent Workouts: ${recentWorkouts?.length || 0} in last 7 days

ACTIVE GOALS:
${activeGoals.length > 0
    ? activeGoals.map(g => `- ${g.category}: ${g.title}${g.target_date ? ` (target: ${g.target_date})` : ''}`).join('\n')
    : 'No active goals - focus on general recovery and injury prevention'}

TASK: Analyze the fatigue data and determine if a deload is needed. If urgency is "none", no prescription is needed. Otherwise, provide specific deload parameters.

Today's date: ${new Date().toISOString().split('T')[0]}

Respond with valid JSON ONLY (no markdown, no explanation outside JSON):
{
  "deload_recommended": true/false,
  "urgency": "none" | "suggested" | "recommended" | "required",
  "reasoning": "2-3 sentence explanation of your recommendation based on the fatigue indicators",
  "deload_prescription": {
    "duration_days": 5-7,
    "load_reduction_pct": 40-60,
    "volume_reduction_pct": 30-50,
    "focus": "technique" | "mobility" | "active_recovery",
    "suggested_start_date": "YYYY-MM-DD"
  } // OR null if no deload recommended
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
        max_tokens: 800,
        temperature: 0.3, // Lower temperature for more consistent recommendations
        response_format: { type: 'json_object' }
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('OpenAI API error:', error)
      throw new Error('Failed to generate deload recommendation')
    }

    const completion = await openaiResponse.json()
    const aiResponse = JSON.parse(completion.choices[0].message.content)

    // --- VALIDATE AND STRUCTURE RESPONSE ---

    const deloadRecommended = aiResponse.deload_recommended === true
    const finalUrgency = aiResponse.urgency || urgency

    // Build fatigue summary
    const fatigueSummary: FatigueSummary = {
      fatigue_score: fatigueScore,
      fatigue_band: fatigueBand,
      avg_readiness_7d: Math.round(avgReadiness7d * 10) / 10,
      acute_chronic_ratio: Math.round(acuteChronicRatio * 100) / 100,
      consecutive_low_days: consecutiveLowDays,
      contributing_factors: contributingFactors
    }

    // Validate deload prescription if provided
    let deloadPrescription: DeloadPrescription | null = null
    if (deloadRecommended && aiResponse.deload_prescription) {
      const rx = aiResponse.deload_prescription
      deloadPrescription = {
        duration_days: Math.min(Math.max(rx.duration_days || 5, 5), 7),
        load_reduction_pct: Math.min(Math.max(rx.load_reduction_pct || 50, 40), 60),
        volume_reduction_pct: Math.min(Math.max(rx.volume_reduction_pct || 40, 30), 50),
        focus: ['technique', 'mobility', 'active_recovery'].includes(rx.focus) ? rx.focus : 'active_recovery',
        suggested_start_date: rx.suggested_start_date || new Date().toISOString().split('T')[0]
      }
    }

    // --- SAVE TO DATABASE ---

    const { data: savedRecommendation, error: saveError } = await supabaseClient
      .from('deload_recommendations')
      .insert({
        patient_id,
        fatigue_summary: fatigueSummary,
        prescription: deloadPrescription,
        deload_recommended: deloadRecommended,
        urgency: finalUrgency,
        reasoning: aiResponse.reasoning || 'AI-generated deload recommendation'
      })
      .select()
      .single()

    if (saveError) {
      console.error('Error saving recommendation:', saveError)
      // Continue without saving - don't fail the request
    }

    // --- RETURN RESPONSE ---

    const response: DeloadRecommendationResponse = {
      recommendation_id: savedRecommendation?.id || crypto.randomUUID(),
      deload_recommended: deloadRecommended,
      urgency: finalUrgency as 'none' | 'suggested' | 'recommended' | 'required',
      reasoning: aiResponse.reasoning || 'Recommendation based on fatigue analysis',
      fatigue_summary: fatigueSummary,
      deload_prescription: deloadPrescription
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in ai-deload-recommendation:', error)

    // Return sensible defaults on error
    const defaultFatigueSummary: FatigueSummary = {
      fatigue_score: 0,
      fatigue_band: 'minimal',
      avg_readiness_7d: 70,
      acute_chronic_ratio: 1.0,
      consecutive_low_days: 0,
      contributing_factors: []
    }

    return new Response(
      JSON.stringify({
        error: error.message || 'Internal server error',
        recommendation_id: crypto.randomUUID(),
        deload_recommended: false,
        urgency: 'none',
        reasoning: 'Unable to analyze fatigue data. Continue with normal training and monitor how you feel.',
        fatigue_summary: defaultFatigueSummary,
        deload_prescription: null
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
