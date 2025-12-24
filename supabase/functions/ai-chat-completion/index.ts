// AI Chat Completion Handler
// Build 77 - AI Helper MVP
// Provides GPT-4 powered chat assistance for patients

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

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { athlete_id, message, session_id } = await req.json()

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

    // Get conversation history
    const { data: history, error: historyError } = await supabaseClient
      .from('ai_chat_messages')
      .select('role, content')
      .eq('session_id', currentSessionId)
      .order('created_at', { ascending: true })
      .limit(20)  // Last 20 messages for context

    if (historyError) throw historyError

    // Build messages array for OpenAI
    const messages: ChatMessage[] = [
      {
        role: 'system',
        content: `You are a knowledgeable physical therapy assistant helping patients understand their rehabilitation program.

Your role:
- Answer questions about exercises, form, and programming
- Explain the "why" behind PT prescriptions
- Encourage adherence and motivation
- Provide educational context

Important rules:
- ALWAYS prioritize safety over performance
- NEVER contradict the prescribing PT's instructions
- DEFER medical questions to the PT (e.g., "Ask your PT about...")
- Keep responses under 150 words
- Use simple, encouraging language
- If unsure, say "I recommend asking your PT about that"

You are helpful, supportive, and safety-focused.`
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
        max_tokens: 500,
        temperature: 0.7,
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
        content: assistantMessage,
        tokens_used: tokensUsed,
        model: 'gpt-4-turbo-preview',
      })

    return new Response(
      JSON.stringify({
        success: true,
        session_id: currentSessionId,
        message: assistantMessage,
        tokens_used: tokensUsed,
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
