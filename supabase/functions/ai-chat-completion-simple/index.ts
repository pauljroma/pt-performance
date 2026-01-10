// Build 79: Simplified AI Chat (works without patients table)
// Temporary workaround until patients table is populated

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const openaiApiKey = Deno.env.get('OPENAI_API_KEY')

const GPT_MODEL = 'gpt-4-turbo-preview'
const MAX_TOKENS = 500
const TEMPERATURE = 0.7

interface ChatRequest {
  session_id?: string
  message: string
  athlete_id: string
}

serve(async (req) => {
  try {
    // CORS
    if (req.method === 'OPTIONS') {
      return new Response(null, {
        headers: {
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'POST, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization',
        }
      })
    }

    if (req.method !== 'POST') {
      return new Response(
        JSON.stringify({ error: 'Method not allowed' }),
        { status: 405, headers: { 'Content-Type': 'application/json' } }
      )
    }

    if (!openaiApiKey) {
      return new Response(
        JSON.stringify({ error: 'OpenAI API key not configured' }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const body: ChatRequest = await req.json()
    const { message, athlete_id } = body

    if (!message || !athlete_id) {
      return new Response(
        JSON.stringify({ error: 'message and athlete_id required' }),
        { status: 400, headers: { 'Content-Type': 'application/json' } }
      )
    }

    console.log('AI chat request:', { athlete_id, message_length: message.length })

    // Simple system prompt (no patient context needed)
    const systemPrompt = `You are a knowledgeable and supportive physical therapy assistant.

GUIDELINES:
1. Be encouraging, supportive, and empathetic
2. Keep responses concise (2-3 sentences max)
3. ALWAYS prioritize safety - defer to PT for medical questions
4. Focus on exercise technique, motivation, and general wellness
5. If asked about pain or symptoms, advise them to contact their PT
6. Never diagnose or recommend changing prescribed programs
7. Use simple, patient-friendly language

TONE: Friendly, encouraging, professional but warm`

    // Call OpenAI
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${openaiApiKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        model: GPT_MODEL,
        messages: [
          { role: 'system', content: systemPrompt },
          { role: 'user', content: message }
        ],
        max_tokens: MAX_TOKENS,
        temperature: TEMPERATURE,
      }),
    })

    if (!openaiResponse.ok) {
      const errorData = await openaiResponse.json()
      console.error('OpenAI error:', errorData)
      return new Response(
        JSON.stringify({ error: 'OpenAI request failed', details: errorData.error?.message }),
        { status: 500, headers: { 'Content-Type': 'application/json' } }
      )
    }

    const completion = await openaiResponse.json()
    const assistantMessage = completion.choices[0].message.content
    const tokensUsed = completion.usage?.total_tokens || 0

    console.log('OpenAI response:', { tokens_used: tokensUsed })

    // Generate session ID if needed
    const sessionId = body.session_id || crypto.randomUUID()

    return new Response(
      JSON.stringify({
        success: true,
        session_id: sessionId,
        message: assistantMessage,
        tokens_used: tokensUsed,
        model: GPT_MODEL
      }),
      {
        status: 200,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        status: 500,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*'
        }
      }
    )
  }
})
