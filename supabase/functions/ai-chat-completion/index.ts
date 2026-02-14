// AI Chat Completion Handler
// Build 77 - AI Helper MVP
// Updated: ACP-1023 - Enhanced personalization, user context, follow-up suggestions
// Provides AI-powered chat assistance for patients with full user context

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ChatMessage {
  role: 'user' | 'assistant' | 'system'
  content: string
}

interface ChatRequest {
  athlete_id: string
  message: string
  session_id?: string
  // ACP-1023: Client-provided context for faster personalization
  user_context?: {
    recent_workouts?: string[]
    readiness_score?: number
    goals?: string[]
    injury_type?: string
    current_program?: string
  }
}

// ACP-1023: Fetch user context from the database for personalized responses
async function fetchUserContext(
  supabaseClient: ReturnType<typeof createClient>,
  athleteId: string
): Promise<string> {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()

  // Fetch context in parallel for speed
  const [workoutsResult, readinessResult, goalsResult, patientResult] = await Promise.all([
    // Recent workouts (last 7 days)
    supabaseClient
      .from('manual_sessions')
      .select('name, completed_at, duration_minutes')
      .eq('patient_id', athleteId)
      .eq('completed', true)
      .gte('completed_at', sevenDaysAgo)
      .order('completed_at', { ascending: false })
      .limit(5),

    // Latest readiness
    supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, energy_level, stress_level')
      .eq('patient_id', athleteId)
      .order('date', { ascending: false })
      .limit(3),

    // Active goals
    supabaseClient
      .from('patient_goals')
      .select('category, title')
      .eq('patient_id', athleteId)
      .eq('status', 'active')
      .limit(5),

    // Patient info (injury context)
    supabaseClient
      .from('patients')
      .select('injury_type, target_level')
      .eq('id', athleteId)
      .single()
  ])

  const parts: string[] = []

  // Injury context
  if (patientResult.data?.injury_type) {
    parts.push(`Injury/Condition: ${patientResult.data.injury_type}`)
  }
  if (patientResult.data?.target_level) {
    parts.push(`Target Level: ${patientResult.data.target_level}`)
  }

  // Recent workouts
  if (workoutsResult.data && workoutsResult.data.length > 0) {
    const workoutLines = workoutsResult.data.map((w: any) =>
      `- ${w.name || 'Workout'} (${new Date(w.completed_at).toLocaleDateString()}${w.duration_minutes ? `, ${w.duration_minutes}min` : ''})`
    )
    parts.push(`Recent Workouts:\n${workoutLines.join('\n')}`)
  }

  // Readiness
  if (readinessResult.data && readinessResult.data.length > 0) {
    const latest = readinessResult.data[0]
    const readinessLines = [
      `Readiness: ${latest.readiness_score !== null ? `${latest.readiness_score}/100` : 'N/A'}`,
      latest.sleep_hours !== null ? `Sleep: ${latest.sleep_hours}h` : null,
      latest.energy_level !== null ? `Energy: ${latest.energy_level}/10` : null,
    ].filter(Boolean)
    parts.push(readinessLines.join(' | '))
  }

  // Goals
  if (goalsResult.data && goalsResult.data.length > 0) {
    const goalLines = goalsResult.data.map((g: any) => `- ${g.category}: ${g.title}`)
    parts.push(`Active Goals:\n${goalLines.join('\n')}`)
  }

  return parts.length > 0 ? parts.join('\n\n') : ''
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { athlete_id, message, session_id, user_context } = await req.json() as ChatRequest

    if (!athlete_id || !message) {
      return new Response(
        JSON.stringify({ error: 'athlete_id and message required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Get or create session
    let currentSessionId = session_id
    if (!currentSessionId) {
      const { data: newSession, error: sessionError } = await supabaseClient
        .from('ai_chat_sessions')
        .insert({
          athlete_id: athlete_id,
          started_at: new Date().toISOString(),
        })
        .select()
        .single()

      if (sessionError) throw sessionError
      currentSessionId = newSession.id
    }

    // ACP-1023: Fetch user context and conversation history in parallel
    const [historyResult, serverContext] = await Promise.all([
      // Get conversation history
      supabaseClient
        .from('ai_chat_messages')
        .select('role, content')
        .eq('session_id', currentSessionId)
        .order('created_at', { ascending: true })
        .limit(10),  // Reduced from 20 to 10 for faster responses

      // Fetch user context from database
      fetchUserContext(supabaseClient, athlete_id)
    ])

    if (historyResult.error) throw historyResult.error
    const history = historyResult.data

    // ACP-1023: Build client context string from provided user_context
    let clientContextStr = ''
    if (user_context) {
      const parts: string[] = []
      if (user_context.injury_type) parts.push(`Injury: ${user_context.injury_type}`)
      if (user_context.readiness_score) parts.push(`Current Readiness: ${user_context.readiness_score}/100`)
      if (user_context.current_program) parts.push(`Program: ${user_context.current_program}`)
      if (user_context.goals?.length) parts.push(`Goals: ${user_context.goals.join(', ')}`)
      if (user_context.recent_workouts?.length) parts.push(`Recent Workouts: ${user_context.recent_workouts.join(', ')}`)
      clientContextStr = parts.join('\n')
    }

    // ACP-1023: Combine server and client context
    const combinedContext = [serverContext, clientContextStr].filter(Boolean).join('\n\n')

    // Build messages array for OpenAI
    // ACP-1023: Enhanced system prompt with personalization and form explanations
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: `You are a knowledgeable physical therapy and performance coach assistant helping patients understand their rehabilitation and training program.

Your role:
- Answer questions about exercises, form, and programming
- Explain the "why" behind PT prescriptions and training choices
- Encourage adherence and motivation
- Provide educational context
- Give personalized advice based on the patient's data

EXERCISE FORM EXPLANATIONS:
When asked about exercise form or technique, structure your response:
1. **Setup**: Starting position, stance, grip
2. **Execution**: Step-by-step movement cues, tempo
3. **Breathing**: When to inhale/exhale
4. **Common Mistakes**: Top 2-3 errors to avoid
5. **Feel It Here**: Where they should feel the exercise

Important rules:
- ALWAYS prioritize safety over performance
- NEVER contradict the prescribing PT's instructions
- DEFER medical questions to the PT (e.g., "Ask your PT about...")
- Keep responses concise but thorough (under 200 words)
- Use simple, encouraging language
- If unsure, say "I recommend asking your PT about that"
- Reference the patient's specific data when available
- If they have an injury, always consider it in your advice
- End each response with 3 brief follow-up suggestions the patient might want to ask, formatted as:
  ---
  You might also want to ask:
  1. [specific follow-up question]
  2. [specific follow-up question]
  3. [specific follow-up question]

You are helpful, supportive, safety-focused, and personalized.${combinedContext ? `\n\nPATIENT CONTEXT:\n${combinedContext}` : ''}`
      },
      ...(history as ChatMessage[]),
      {
        role: 'user',
        content: message
      }
    ]

    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: messages,
        max_tokens: 600,
        temperature: 0.6,
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('OpenAI API error:', error)
      throw new Error('Failed to get AI response')
    }

    const completion = await openaiResponse.json()
    const assistantMessage = completion.choices[0].message.content
    const tokensUsed = completion.usage.total_tokens

    // ACP-1023: Extract follow-up suggestions from the response
    let responseText = assistantMessage
    let followUpSuggestions: string[] = []

    const followUpMatch = assistantMessage.match(/---\s*\n\s*You might also want to ask:\s*\n([\s\S]*?)$/i)
    if (followUpMatch) {
      responseText = assistantMessage.substring(0, followUpMatch.index).trim()
      const suggestions = followUpMatch[1].match(/\d+\.\s*(.+)/g)
      if (suggestions) {
        followUpSuggestions = suggestions.map((s: string) => s.replace(/^\d+\.\s*/, '').trim())
      }
    }

    // Save user message and assistant message in parallel
    await Promise.all([
      supabaseClient
        .from('ai_chat_messages')
        .insert({
          session_id: currentSessionId,
          role: 'user',
          content: message,
          tokens_used: 0,
          model: 'user-input',
        }),
      supabaseClient
        .from('ai_chat_messages')
        .insert({
          session_id: currentSessionId,
          role: 'assistant',
          content: responseText,
          tokens_used: tokensUsed,
          model: 'gpt-4-turbo-preview',
        })
    ])

    return new Response(
      JSON.stringify({
        success: true,
        session_id: currentSessionId,
        message: responseText,
        tokens_used: tokensUsed,
        // ACP-1023: Include follow-up suggestions in the response
        follow_up_suggestions: followUpSuggestions,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in ai-chat-completion:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
