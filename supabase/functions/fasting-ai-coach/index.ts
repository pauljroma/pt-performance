// ============================================================================
// Fasting AI Coach Edge Function
// Health Intelligence Platform - Personalized Fasting Guidance
// ============================================================================
// Provides personalized fasting advice using Claude AI based on the patient's
// fasting history, current status, goals, and context. Supports various
// fasting scenarios: starting a fast, during a fast, or breaking a fast.
//
// Features:
// - Context-aware responses (starting/during/breaking fast)
// - Personalized advice based on fasting history
// - Science-backed recommendations
// - Integration with patient's health data
// - Safety-first approach
//
// Date: 2026-02-03
// Ticket: ACP-429
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface FastingAICoachRequest {
  patient_id: string
  question: string
  context: 'starting' | 'during' | 'breaking' | 'general'
  current_fast_id?: string
}

interface FastingLog {
  id: string
  started_at: string
  ended_at: string | null
  planned_hours: number
  actual_hours: number | null
  protocol_type: string | null
  completed: boolean
  notes: string | null
  break_reason: string | null
}

interface PatientGoal {
  category: string
  title: string
  status: string
}

interface DailyReadinessData {
  date: string
  sleep_hours: number | null
  energy_level: number | null
  readiness_score: number | null
}

interface FastingContext {
  current_fast: FastingLog | null
  recent_fasts: FastingLog[]
  goals: PatientGoal[]
  recent_readiness: DailyReadinessData[]
  fasting_stats: {
    total_fasts_30d: number
    completed_fasts_30d: number
    average_duration: number
    longest_fast: number
    preferred_protocol: string | null
    compliance_rate: number
  }
}

interface CoachResponse {
  answer: string
  tips: string[]
  warnings: string[]
  suggested_actions: string[]
}

interface FastingAICoachResponse {
  response_id: string
  patient_id: string
  context: string
  current_fasting_status: {
    is_fasting: boolean
    hours_fasted: number | null
    protocol: string | null
    planned_duration: number | null
  }
  coach_response: CoachResponse
  follow_up_questions: string[]
  disclaimer: string
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function calculateFastingHours(startedAt: string): number {
  const start = new Date(startedAt)
  const now = new Date()
  const diffMs = now.getTime() - start.getTime()
  return diffMs / (1000 * 60 * 60)
}

async function gatherFastingContext(
  supabaseClient: ReturnType<typeof createClient>,
  patient_id: string
): Promise<FastingContext> {
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

  // Fetch data in parallel
  const [
    currentFastResult,
    recentFastsResult,
    goalsResult,
    readinessResult
  ] = await Promise.all([
    // Current ongoing fast
    supabaseClient
      .from('fasting_logs')
      .select('*')
      .eq('patient_id', patient_id)
      .is('ended_at', null)
      .order('started_at', { ascending: false })
      .limit(1)
      .maybeSingle(),

    // Recent fasts (last 30 days)
    supabaseClient
      .from('fasting_logs')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('started_at', thirtyDaysAgo)
      .order('started_at', { ascending: false })
      .limit(20),

    // Patient goals
    supabaseClient
      .from('patient_goals')
      .select('category, title, status')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(10),

    // Recent readiness data
    supabaseClient
      .from('daily_readiness')
      .select('date, sleep_hours, energy_level, readiness_score')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo.split('T')[0])
      .order('date', { ascending: false })
      .limit(7)
  ])

  const currentFast: FastingLog | null = currentFastResult.data
  const recentFasts: FastingLog[] = recentFastsResult.data || []
  const goals: PatientGoal[] = goalsResult.data || []
  const recentReadiness: DailyReadinessData[] = readinessResult.data || []

  // Calculate fasting stats
  const completedFasts = recentFasts.filter(f => f.completed)
  const durations = completedFasts.map(f => f.actual_hours || f.planned_hours).filter(d => d > 0)

  // Find most used protocol
  const protocolCounts = new Map<string, number>()
  for (const fast of recentFasts) {
    if (fast.protocol_type) {
      protocolCounts.set(fast.protocol_type, (protocolCounts.get(fast.protocol_type) || 0) + 1)
    }
  }
  let preferredProtocol: string | null = null
  let maxCount = 0
  for (const [protocol, count] of protocolCounts) {
    if (count > maxCount) {
      maxCount = count
      preferredProtocol = protocol
    }
  }

  const fastingStats = {
    total_fasts_30d: recentFasts.length,
    completed_fasts_30d: completedFasts.length,
    average_duration: durations.length > 0
      ? Math.round((durations.reduce((a, b) => a + b, 0) / durations.length) * 10) / 10
      : 0,
    longest_fast: durations.length > 0 ? Math.max(...durations) : 0,
    preferred_protocol: preferredProtocol,
    compliance_rate: recentFasts.length > 0
      ? Math.round((completedFasts.length / recentFasts.length) * 100)
      : 0
  }

  return {
    current_fast: currentFast,
    recent_fasts: recentFasts,
    goals,
    recent_readiness: recentReadiness,
    fasting_stats: fastingStats
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
    const { patient_id, question, context, current_fast_id } = await req.json() as FastingAICoachRequest

    // ========================================================================
    // VALIDATION
    // ========================================================================

    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!isValidUUID(patient_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid patient_id format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!question || question.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'question is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (question.length > 1000) {
      return new Response(
        JSON.stringify({ error: 'question exceeds maximum length of 1000 characters' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const validContexts = ['starting', 'during', 'breaking', 'general']
    if (!context || !validContexts.includes(context)) {
      return new Response(
        JSON.stringify({
          error: 'Invalid context',
          valid_contexts: validContexts
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[fasting-ai-coach] Processing question for patient ${patient_id}, context: ${context}`)

    // ========================================================================
    // INITIALIZE SUPABASE CLIENT
    // ========================================================================
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // GATHER FASTING CONTEXT
    // ========================================================================
    const fastingContext = await gatherFastingContext(supabaseClient, patient_id)
    console.log(`[fasting-ai-coach] Gathered context: ${fastingContext.fasting_stats.total_fasts_30d} fasts in 30 days`)

    // Determine current fasting status
    const currentFastingHours = fastingContext.current_fast
      ? calculateFastingHours(fastingContext.current_fast.started_at)
      : null

    const currentFastingStatus = {
      is_fasting: !!fastingContext.current_fast,
      hours_fasted: currentFastingHours ? Math.round(currentFastingHours * 10) / 10 : null,
      protocol: fastingContext.current_fast?.protocol_type || null,
      planned_duration: fastingContext.current_fast?.planned_hours || null
    }

    // ========================================================================
    // BUILD AI PROMPT
    // ========================================================================
    const systemPrompt = `You are an expert fasting coach with deep knowledge in:
- Intermittent fasting protocols (16:8, 18:6, 20:4, OMAD, 5:2, etc.)
- Metabolic health and autophagy
- Exercise and fasting interactions
- Circadian rhythm optimization
- Electrolyte management during fasts
- Breaking fasts properly

Your approach combines:
- Dr. Jason Fung's therapeutic fasting expertise
- Dr. Satchin Panda's circadian biology research
- Dr. Peter Attia's metabolic health focus
- Dr. Rhonda Patrick's cellular health insights

COMMUNICATION STYLE:
- Warm, supportive, and encouraging
- Science-backed but accessible
- Practical and actionable
- Safety-first mindset
- Personalized to their data

CRITICAL GUIDELINES:
1. Never encourage fasting that could be dangerous
2. Recommend breaking the fast if they report concerning symptoms
3. Consider their goals when giving advice
4. Account for their fasting history and patterns
5. Be specific to their current context (starting/during/breaking/general)

For symptoms like dizziness, extreme fatigue, rapid heartbeat, or confusion - ALWAYS recommend breaking the fast immediately.`

    // Build context-specific user prompt
    let contextDescription = ''
    switch (context) {
      case 'starting':
        contextDescription = 'The user is about to START a new fast.'
        break
      case 'during':
        contextDescription = `The user is CURRENTLY FASTING (${currentFastingHours?.toFixed(1) || 'unknown'} hours in).`
        break
      case 'breaking':
        contextDescription = 'The user is about to BREAK their fast.'
        break
      case 'general':
        contextDescription = 'The user has a general question about fasting.'
        break
    }

    const userPrompt = `${contextDescription}

=== PATIENT FASTING PROFILE ===
Total fasts (30 days): ${fastingContext.fasting_stats.total_fasts_30d}
Completed fasts: ${fastingContext.fasting_stats.completed_fasts_30d}
Compliance rate: ${fastingContext.fasting_stats.compliance_rate}%
Average duration: ${fastingContext.fasting_stats.average_duration} hours
Longest fast: ${fastingContext.fasting_stats.longest_fast} hours
Preferred protocol: ${fastingContext.fasting_stats.preferred_protocol || 'Not established'}

=== CURRENT FASTING STATUS ===
Currently fasting: ${currentFastingStatus.is_fasting ? 'Yes' : 'No'}
${currentFastingStatus.is_fasting ? `
Hours fasted: ${currentFastingStatus.hours_fasted}
Protocol: ${currentFastingStatus.protocol || 'Not specified'}
Planned duration: ${currentFastingStatus.planned_duration || 'Not specified'} hours
` : ''}

=== PATIENT GOALS ===
${fastingContext.goals.length > 0
  ? fastingContext.goals.map(g => `- ${g.category}: ${g.title}`).join('\n')
  : 'No specific goals set'}

=== RECENT READINESS (Last 7 Days) ===
${fastingContext.recent_readiness.length > 0
  ? fastingContext.recent_readiness.map(r => `- ${r.date}: Sleep ${r.sleep_hours || 'N/A'}h, Energy ${r.energy_level || 'N/A'}/10`).join('\n')
  : 'No readiness data available'}

=== RECENT FASTS ===
${fastingContext.recent_fasts.slice(0, 5).map(f => {
  const duration = f.actual_hours || f.planned_hours
  const status = f.completed ? 'Completed' : `Incomplete${f.break_reason ? ` (${f.break_reason})` : ''}`
  return `- ${f.started_at.split('T')[0]}: ${duration}h ${f.protocol_type || ''} - ${status}`
}).join('\n') || 'No recent fasts'}

=== USER QUESTION ===
"${question}"

---

Respond with valid JSON ONLY:
{
  "answer": "Your conversational response (2-4 paragraphs, personalized to their data and context)",
  "tips": ["Practical tip 1", "Practical tip 2", "..."],
  "warnings": ["Any safety warnings if applicable (empty array if none)"],
  "suggested_actions": ["Specific action 1", "Specific action 2", "..."]
}`

    // ========================================================================
    // CALL CLAUDE API
    // ========================================================================
    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[fasting-ai-coach] Calling Claude API...')

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 1500,
        system: systemPrompt,
        messages: [
          {
            role: 'user',
            content: userPrompt
          }
        ],
        temperature: 0.6,
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[fasting-ai-coach] Anthropic API error:', anthropicResponse.status, error)
      throw new Error(`AI service error: ${anthropicResponse.status}`)
    }

    const completion = await anthropicResponse.json()
    const responseText = completion.content?.[0]?.text

    if (!responseText) {
      throw new Error('No text content in AI response')
    }

    console.log('[fasting-ai-coach] Received response from Claude')

    // Parse AI response
    let aiResponse: CoachResponse
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      const parsed = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
      aiResponse = {
        answer: parsed.answer || responseText,
        tips: Array.isArray(parsed.tips) ? parsed.tips : [],
        warnings: Array.isArray(parsed.warnings) ? parsed.warnings : [],
        suggested_actions: Array.isArray(parsed.suggested_actions) ? parsed.suggested_actions : []
      }
    } catch (parseError) {
      console.error('[fasting-ai-coach] Failed to parse AI response, using raw text')
      aiResponse = {
        answer: responseText,
        tips: [],
        warnings: [],
        suggested_actions: []
      }
    }

    // ========================================================================
    // GENERATE FOLLOW-UP QUESTIONS
    // ========================================================================
    const followUpQuestions: string[] = []

    switch (context) {
      case 'starting':
        followUpQuestions.push(
          'What should I eat before starting my fast?',
          'How do I handle hunger in the first few hours?',
          'What drinks are allowed during the fast?'
        )
        break
      case 'during':
        followUpQuestions.push(
          'Is it normal to feel [current sensation] at this point?',
          'Can I exercise while fasting?',
          'What electrolytes should I take?',
          'How do I know if I should break my fast early?'
        )
        break
      case 'breaking':
        followUpQuestions.push(
          'What are the best foods to break my fast with?',
          'How much should I eat when breaking my fast?',
          'How long should I wait before eating a full meal?'
        )
        break
      case 'general':
        followUpQuestions.push(
          'What fasting protocol is best for my goals?',
          'How can I improve my fasting consistency?',
          'Should I fast before or after workouts?'
        )
        break
    }

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const disclaimer = `FASTING COACH DISCLAIMER: This AI-generated advice is for informational and educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Fasting may not be appropriate for everyone, particularly those with diabetes, eating disorders, pregnancy, or other medical conditions. Always consult with a healthcare provider before starting or modifying a fasting protocol. If you experience concerning symptoms such as dizziness, extreme fatigue, rapid heartbeat, or confusion, break your fast immediately and seek medical attention if symptoms persist.`

    const response: FastingAICoachResponse = {
      response_id: crypto.randomUUID(),
      patient_id,
      context,
      current_fasting_status: currentFastingStatus,
      coach_response: aiResponse,
      follow_up_questions: followUpQuestions,
      disclaimer
    }

    console.log(`[fasting-ai-coach] Generated response with ${aiResponse.tips.length} tips, ${aiResponse.warnings.length} warnings`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[fasting-ai-coach] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        coach_response: {
          answer: 'I apologize, but I encountered an issue processing your question. Please try again in a moment.',
          tips: ['Stay hydrated during your fast', 'Listen to your body'],
          warnings: ['If you feel unwell, consider breaking your fast'],
          suggested_actions: ['Try asking your question again', 'Consult with a healthcare provider for personalized advice']
        },
        disclaimer: 'AI coaching is temporarily unavailable. Please consult a healthcare provider for fasting guidance.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
