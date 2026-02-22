// AI Safety Check Handler
// Build 77 - AI Helper MVP
// Uses Claude to detect contraindications and safety issues

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limit.ts'
import { corsHeaders, handleCors } from '../_shared/cors.ts'

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = corsHeaders(origin)

  try {
    const { athlete_id, exercise_id, context } = await req.json()

    // Rate limit: 10 requests/minute for AI endpoints
    const rateLimitKey = athlete_id || req.headers.get('x-forwarded-for') || 'anonymous'
    const { allowed, resetMs } = checkRateLimit(`ai-safety-check:${rateLimitKey}`, { windowMs: 60_000, maxRequests: 10 })
    if (!allowed) return rateLimitResponse(resetMs)

    if (!athlete_id || !exercise_id) {
      return new Response(
        JSON.stringify({ error: 'athlete_id and exercise_id required' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Get exercise details
    const { data: exercise, error: exerciseError } = await supabaseClient
      .from('exercises')
      .select('*')
      .eq('id', exercise_id)
      .single()

    if (exerciseError) throw exerciseError

    // Get athlete profile
    const { data: athlete, error: athleteError } = await supabaseClient
      .from('athletes')
      .select('injuries, medical_history, age')
      .eq('id', athlete_id)
      .single()

    if (athleteError) throw athleteError

    // Get WHOOP recovery if available
    const { data: recovery } = await supabaseClient
      .from('whoop_recovery')
      .select('recovery_score, readiness_band')
      .eq('athlete_id', athlete_id)
      .order('date', { ascending: false })
      .limit(1)
      .single()

    // Build safety analysis prompt
    const prompt = `You are a medical safety analyzer specializing in physical therapy contraindications.

EXERCISE:
Name: ${exercise.name}
Category: ${exercise.category || 'Unknown'}
Equipment: ${exercise.equipment || 'None'}
Primary Muscles: ${exercise.primary_muscles || 'Unknown'}
Description: ${exercise.description || 'Not provided'}

PATIENT PROFILE:
Age: ${athlete.age || 'Unknown'}
Injuries: ${athlete.injuries || 'None reported'}
Medical History: ${athlete.medical_history || 'None reported'}
Current Recovery: ${recovery ? `${recovery.recovery_score}% (${recovery.readiness_band})` : 'Unknown'}

CONTEXT: ${context || 'Standard rehabilitation session'}

ANALYZE FOR:
1. Injury contraindications (will this exercise aggravate existing injuries?)
2. Medical contraindications (any medical conditions that make this unsafe?)
3. Overtraining risk (recovery status vs exercise demand)
4. Form/technique risks (common injury patterns with this movement)

Provide your analysis as JSON:
{
  "safe": true/false,
  "warning_level": "info|caution|warning|danger",
  "risks": ["List specific risks"],
  "recommendations": ["Modifications or alternatives"],
  "rationale": "Detailed explanation"
}`

    // Call Anthropic Claude API
    const claudeResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': Deno.env.get('ANTHROPIC_API_KEY') || '',
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-3-5-sonnet-20241022',
        max_tokens: 1000,
        temperature: 0.3,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ]
      }),
    })

    if (!claudeResponse.ok) {
      const error = await claudeResponse.text()
      console.error('Claude API error:', error)
      throw new Error('Failed to get safety analysis')
    }

    const completion = await claudeResponse.json()
    const analysisText = completion.content[0].text

    // Extract JSON from response (Claude sometimes wraps it in markdown)
    const jsonMatch = analysisText.match(/\{[\s\S]*\}/)
    const analysis = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(analysisText)

    // Save safety check to database if not safe
    if (!analysis.safe || analysis.warning_level !== 'info') {
      await supabaseClient
        .from('ai_safety_checks')
        .insert({
          athlete_id: athlete_id,
          exercise_id: exercise_id,
          warning_level: analysis.warning_level,
          reason: analysis.risks.join('; '),
          ai_analysis: analysis,
          dismissed: false,
        })
    }

    return new Response(
      JSON.stringify({
        success: true,
        safe: analysis.safe,
        warning_level: analysis.warning_level,
        analysis: analysis,
      }),
      { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in ai-safety-check:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  }
})
