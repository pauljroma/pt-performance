// ============================================================================
// AI Coach Edge Function
// Health Intelligence Platform - Conversational Health Coach
// ============================================================================
// Provides personalized health coaching by gathering comprehensive patient
// context (workouts, sleep, HRV, labs, fasting, supplements) and using
// Claude AI to deliver actionable insights and guidance.
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

interface AICoachRequest {
  patient_id: string
  message: string
  session_id?: string
}

interface WorkoutData {
  id: string
  name: string | null
  completed_at: string
  duration_minutes: number | null
  category: string | null
}

interface SleepData {
  date: string
  sleep_hours: number | null
  sleep_quality: number | null
}

interface HRVData {
  date: string
  hrv_rmssd: number | null
  resting_hr: number | null
}

interface LabData {
  test_date: string
  biomarkers: {
    biomarker_type: string
    value: number
    unit: string
    is_flagged: boolean
  }[]
}

interface FastingData {
  started_at: string
  ended_at: string | null
  planned_hours: number
  completed: boolean
  protocol_type: string | null
}

interface SupplementData {
  name: string
  dosage: string
  dosage_unit: string
  timing: string
}

interface PatientContext {
  workouts: WorkoutData[]
  sleep: SleepData[]
  hrv: HRVData[]
  labs: LabData | null
  fasting: FastingData[]
  supplements: SupplementData[]
  goals: { category: string; title: string; status: string }[]
  readiness: { date: string; readiness_score: number | null }[]
}

interface CoachingInsight {
  category: string
  observation: string
  recommendation: string
  priority: 'high' | 'medium' | 'low'
}

interface AICoachResponse {
  session_id: string
  response: string
  insights: CoachingInsight[]
  suggested_questions: string[]
  context_summary: {
    workouts_7d: number
    avg_sleep_7d: number | null
    avg_hrv_7d: number | null
    current_fasting: boolean
    active_supplements: number
  }
  disclaimer: string
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

async function gatherPatientContext(
  supabaseClient: ReturnType<typeof createClient>,
  patient_id: string
): Promise<PatientContext> {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()

  // Gather all data in parallel
  const [
    workoutsResult,
    readinessResult,
    hrvResult,
    labsResult,
    fastingResult,
    supplementsResult,
    goalsResult
  ] = await Promise.all([
    // Workouts (last 14 days)
    supabaseClient
      .from('manual_sessions')
      .select('id, name, completed_at, duration_minutes')
      .eq('patient_id', patient_id)
      .eq('completed', true)
      .gte('completed_at', new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString())
      .order('completed_at', { ascending: false })
      .limit(20),

    // Sleep/Readiness (last 7 days)
    supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo.split('T')[0])
      .order('date', { ascending: false })
      .limit(7),

    // HRV data (last 7 days)
    supabaseClient
      .from('daily_readiness')
      .select('date, whoop_hrv_rmssd, whoop_resting_hr')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo.split('T')[0])
      .not('whoop_hrv_rmssd', 'is', null)
      .order('date', { ascending: false })
      .limit(7),

    // Most recent lab results
    supabaseClient
      .from('lab_results')
      .select(`
        id,
        test_date,
        biomarker_values (
          biomarker_type,
          value,
          unit,
          is_flagged
        )
      `)
      .eq('patient_id', patient_id)
      .order('test_date', { ascending: false })
      .limit(1)
      .maybeSingle(),

    // Fasting logs (last 30 days)
    supabaseClient
      .from('fasting_logs')
      .select('started_at, ended_at, planned_hours, completed, protocol_type')
      .eq('patient_id', patient_id)
      .gte('started_at', thirtyDaysAgo)
      .order('started_at', { ascending: false })
      .limit(10),

    // Active supplements
    supabaseClient
      .from('patient_supplement_stacks')
      .select(`
        dosage,
        dosage_unit,
        timing,
        supplements (name)
      `)
      .eq('patient_id', patient_id)
      .eq('is_active', true)
      .limit(20),

    // Active goals
    supabaseClient
      .from('patient_goals')
      .select('category, title, status')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(10)
  ])

  // Process workouts
  const workouts: WorkoutData[] = (workoutsResult.data || []).map((w: any) => ({
    id: w.id,
    name: w.name,
    completed_at: w.completed_at,
    duration_minutes: w.duration_minutes,
    category: null
  }))

  // Process sleep data
  const sleep: SleepData[] = (readinessResult.data || []).map((r: any) => ({
    date: r.date,
    sleep_hours: r.sleep_hours,
    sleep_quality: null
  }))

  // Process HRV data
  const hrv: HRVData[] = (hrvResult.data || []).map((h: any) => ({
    date: h.date,
    hrv_rmssd: h.whoop_hrv_rmssd,
    resting_hr: h.whoop_resting_hr
  }))

  // Process labs
  const labs: LabData | null = labsResult.data ? {
    test_date: labsResult.data.test_date,
    biomarkers: (labsResult.data.biomarker_values || []).map((b: any) => ({
      biomarker_type: b.biomarker_type,
      value: b.value,
      unit: b.unit,
      is_flagged: b.is_flagged
    }))
  } : null

  // Process fasting
  const fasting: FastingData[] = (fastingResult.data || []).map((f: any) => ({
    started_at: f.started_at,
    ended_at: f.ended_at,
    planned_hours: f.planned_hours,
    completed: f.completed,
    protocol_type: f.protocol_type
  }))

  // Process supplements
  const supplements: SupplementData[] = (supplementsResult.data || []).map((s: any) => ({
    name: s.supplements?.name || 'Unknown',
    dosage: String(s.dosage || ''),
    dosage_unit: s.dosage_unit || '',
    timing: s.timing || 'as directed'
  }))

  // Process goals
  const goals = (goalsResult.data || []).map((g: any) => ({
    category: g.category,
    title: g.title,
    status: g.status
  }))

  // Process readiness
  const readiness = (readinessResult.data || []).map((r: any) => ({
    date: r.date,
    readiness_score: r.readiness_score
  }))

  return {
    workouts,
    sleep,
    hrv,
    labs,
    fasting,
    supplements,
    goals,
    readiness
  }
}

function buildContextSummary(context: PatientContext): AICoachResponse['context_summary'] {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)

  // Workouts in last 7 days
  const workouts7d = context.workouts.filter(w =>
    new Date(w.completed_at) >= sevenDaysAgo
  ).length

  // Average sleep
  const sleepValues = context.sleep
    .filter(s => s.sleep_hours !== null)
    .map(s => s.sleep_hours as number)
  const avgSleep = sleepValues.length > 0
    ? sleepValues.reduce((a, b) => a + b, 0) / sleepValues.length
    : null

  // Average HRV
  const hrvValues = context.hrv
    .filter(h => h.hrv_rmssd !== null)
    .map(h => h.hrv_rmssd as number)
  const avgHrv = hrvValues.length > 0
    ? hrvValues.reduce((a, b) => a + b, 0) / hrvValues.length
    : null

  // Current fasting state
  const currentFasting = context.fasting.some(f => !f.ended_at)

  return {
    workouts_7d: workouts7d,
    avg_sleep_7d: avgSleep ? Math.round(avgSleep * 10) / 10 : null,
    avg_hrv_7d: avgHrv ? Math.round(avgHrv) : null,
    current_fasting: currentFasting,
    active_supplements: context.supplements.length
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
    const { patient_id, message, session_id } = await req.json() as AICoachRequest

    // Validate required fields
    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!message || message.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'message is required' }),
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

    console.log(`[ai-coach] Processing message for patient ${patient_id}: "${message.substring(0, 50)}..."`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // GET OR CREATE SESSION
    // ========================================================================
    let currentSessionId = session_id
    if (!currentSessionId) {
      const { data: newSession, error: sessionError } = await supabaseClient
        .from('ai_chat_sessions')
        .insert({
          athlete_id: patient_id,
          started_at: new Date().toISOString(),
        })
        .select()
        .single()

      if (sessionError) {
        console.error('[ai-coach] Failed to create session:', sessionError)
        currentSessionId = crypto.randomUUID() // Fallback to generated ID
      } else {
        currentSessionId = newSession.id
      }
    }

    // ========================================================================
    // GATHER PATIENT CONTEXT
    // ========================================================================
    console.log('[ai-coach] Gathering patient context...')
    const context = await gatherPatientContext(supabaseClient, patient_id)
    const contextSummary = buildContextSummary(context)
    console.log('[ai-coach] Context gathered successfully')

    // ========================================================================
    // GET CONVERSATION HISTORY
    // ========================================================================
    let conversationHistory: { role: string; content: string }[] = []
    if (session_id) {
      const { data: history } = await supabaseClient
        .from('ai_chat_messages')
        .select('role, content')
        .eq('session_id', session_id)
        .order('created_at', { ascending: true })
        .limit(10)

      if (history) {
        conversationHistory = history.map((h: any) => ({
          role: h.role,
          content: h.content
        }))
      }
    }

    // ========================================================================
    // BUILD SYSTEM PROMPT
    // ========================================================================
    const systemPrompt = `You are an expert AI health coach with deep knowledge in exercise science, nutrition, sleep optimization, and longevity medicine. Your approach combines:
- Dr. Andrew Huberman's science-based optimization protocols
- Dr. Peter Attia's longevity and metabolic health focus
- Andy Galpin's exercise physiology expertise

YOUR ROLE:
1. Answer questions based on the patient's actual health data
2. Identify patterns and correlations across different health metrics
3. Provide actionable, personalized recommendations
4. Explain the science behind your recommendations when helpful
5. Flag any concerning patterns that warrant attention

PATIENT CONTEXT AVAILABLE:
- Workout history (training load, frequency, types)
- Sleep data (duration, quality trends)
- HRV data (autonomic nervous system recovery)
- Lab results (biomarkers, flagged values)
- Fasting history (protocols, adherence)
- Supplement stack (what they're taking)
- Active goals (what they're working toward)

COMMUNICATION STYLE:
- Be conversational but knowledgeable
- Use "you" language - make it personal
- Reference specific data points when relevant
- Keep responses focused and actionable
- Avoid generic advice - be specific to their data
- If you don't have enough data, acknowledge it

IMPORTANT GUIDELINES:
- Never provide medical diagnoses
- Recommend consulting healthcare providers for medical concerns
- Base insights on their actual data, not assumptions
- Prioritize safety over performance`

    // ========================================================================
    // BUILD USER CONTEXT
    // ========================================================================
    const userContext = `CURRENT PATIENT DATA:

=== WORKOUTS (Last 14 Days) ===
${context.workouts.length > 0
  ? context.workouts.map(w => `- ${new Date(w.completed_at).toLocaleDateString()}: ${w.name || 'Workout'}${w.duration_minutes ? ` (${w.duration_minutes} min)` : ''}`).join('\n')
  : 'No recent workouts logged'}

=== SLEEP (Last 7 Days) ===
${context.sleep.length > 0
  ? context.sleep.map(s => `- ${s.date}: ${s.sleep_hours !== null ? `${s.sleep_hours} hours` : 'No data'}`).join('\n')
  : 'No sleep data available'}
Average: ${contextSummary.avg_sleep_7d !== null ? `${contextSummary.avg_sleep_7d} hours` : 'N/A'}

=== HRV (Last 7 Days) ===
${context.hrv.length > 0
  ? context.hrv.map(h => `- ${h.date}: ${h.hrv_rmssd !== null ? `${h.hrv_rmssd} ms RMSSD` : 'No data'}${h.resting_hr ? `, ${h.resting_hr} bpm RHR` : ''}`).join('\n')
  : 'No HRV data available'}
Average: ${contextSummary.avg_hrv_7d !== null ? `${contextSummary.avg_hrv_7d} ms` : 'N/A'}

=== LAB RESULTS ===
${context.labs
  ? `Test Date: ${context.labs.test_date}
Biomarkers:
${context.labs.biomarkers.map(b => `- ${b.biomarker_type}: ${b.value} ${b.unit}${b.is_flagged ? ' [FLAGGED]' : ''}`).join('\n')}`
  : 'No lab data available'}

=== FASTING (Last 30 Days) ===
${context.fasting.length > 0
  ? `Fasts: ${context.fasting.length}
Completed: ${context.fasting.filter(f => f.completed).length}
Currently fasting: ${contextSummary.current_fasting ? 'Yes' : 'No'}
Protocols used: ${[...new Set(context.fasting.map(f => f.protocol_type).filter(Boolean))].join(', ') || 'Various'}`
  : 'No fasting data available'}

=== SUPPLEMENTS ===
${context.supplements.length > 0
  ? context.supplements.map(s => `- ${s.name}: ${s.dosage} ${s.dosage_unit} (${s.timing})`).join('\n')
  : 'No supplements tracked'}

=== ACTIVE GOALS ===
${context.goals.length > 0
  ? context.goals.map(g => `- ${g.category}: ${g.title}`).join('\n')
  : 'No active goals set'}

=== READINESS (Last 7 Days) ===
${context.readiness.length > 0
  ? context.readiness.map(r => `- ${r.date}: ${r.readiness_score !== null ? `${r.readiness_score}/100` : 'No data'}`).join('\n')
  : 'No readiness data available'}

---

USER MESSAGE: ${message}

---

Respond with valid JSON ONLY:
{
  "response": "Your conversational response to their message (2-4 paragraphs, be specific to their data)",
  "insights": [
    {
      "category": "training|recovery|nutrition|sleep|labs|supplements|general",
      "observation": "What you noticed in their data",
      "recommendation": "Specific action to take",
      "priority": "high|medium|low"
    }
  ],
  "suggested_questions": [
    "A follow-up question they might want to ask",
    "Another relevant question based on their data"
  ]
}`

    // ========================================================================
    // CALL ANTHROPIC API
    // ========================================================================
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[ai-coach] Calling Anthropic Claude API...')

    const anthropic = new Anthropic({ apiKey: anthropicApiKey })

    // Build messages array with history
    const messages: Anthropic.MessageParam[] = [
      ...conversationHistory.map(h => ({
        role: h.role as 'user' | 'assistant',
        content: h.content
      })),
      {
        role: 'user' as const,
        content: userContext
      }
    ]

    const completion = await anthropic.messages.create({
      model: 'claude-sonnet-4-20250514',
      max_tokens: 2048,
      system: systemPrompt,
      messages: messages,
      temperature: 0.5,
    })

    const responseText = completion.content[0].type === 'text'
      ? completion.content[0].text
      : ''

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[ai-coach] Received response from Claude')

    // Parse AI response
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[ai-coach] Failed to parse AI response:', responseText)
      // Fallback to using the raw response
      aiResponse = {
        response: responseText,
        insights: [],
        suggested_questions: []
      }
    }

    // ========================================================================
    // SAVE MESSAGES TO DATABASE
    // ========================================================================
    try {
      // Save user message
      await supabaseClient
        .from('ai_chat_messages')
        .insert({
          session_id: currentSessionId,
          role: 'user',
          content: message,
          tokens_used: 0,
          model: 'user-input',
        })

      // Save assistant message
      await supabaseClient
        .from('ai_chat_messages')
        .insert({
          session_id: currentSessionId,
          role: 'assistant',
          content: aiResponse.response,
          tokens_used: completion.usage?.output_tokens || 0,
          model: 'claude-sonnet-4-20250514',
        })
    } catch (saveError) {
      console.error('[ai-coach] Failed to save messages:', saveError)
      // Continue without saving
    }

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const disclaimer = `AI HEALTH COACHING DISCLAIMER: This response is generated by an AI system and is for informational and educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Always consult with qualified healthcare providers before making changes to your health, fitness, or nutrition regimen. If you have medical concerns or experience symptoms, seek appropriate medical care.`

    const response: AICoachResponse = {
      session_id: currentSessionId,
      response: aiResponse.response || 'I analyzed your data and have some insights for you.',
      insights: aiResponse.insights || [],
      suggested_questions: aiResponse.suggested_questions || [
        'How can I improve my sleep quality?',
        'What should I focus on this week?'
      ],
      context_summary: contextSummary,
      disclaimer
    }

    console.log(`[ai-coach] Generated response with ${response.insights.length} insights`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-coach] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        session_id: null,
        response: 'I encountered an issue processing your request. Please try again.',
        insights: [],
        suggested_questions: [],
        context_summary: {
          workouts_7d: 0,
          avg_sleep_7d: null,
          avg_hrv_7d: null,
          current_fasting: false,
          active_supplements: 0
        },
        disclaimer: 'AI Coaching is temporarily unavailable. Please consult a healthcare provider for guidance.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
