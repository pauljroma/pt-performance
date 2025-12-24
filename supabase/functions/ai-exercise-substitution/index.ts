// AI Exercise Substitution Handler
// Build 77 - AI Helper MVP
// Suggests alternative exercises based on equipment/injuries

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { athlete_id, exercise_id, reason } = await req.json()

    if (!athlete_id || !exercise_id || !reason) {
      return new Response(
        JSON.stringify({ error: 'athlete_id, exercise_id, and reason required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Get original exercise details
    const { data: exercise, error: exerciseError } = await supabaseClient
      .from('exercises')
      .select('*')
      .eq('id', exercise_id)
      .single()

    if (exerciseError) throw exerciseError

    // Get athlete injuries/constraints
    const { data: athlete, error: athleteError } = await supabaseClient
      .from('athletes')
      .select('injuries, equipment_available')
      .eq('id', athlete_id)
      .single()

    if (athleteError) throw athleteError

    // Call OpenAI for substitution
    const prompt = `You are a physical therapy exercise specialist. Suggest alternative exercises.

Original Exercise: ${exercise.name}
Category: ${exercise.category || 'Unknown'}
Equipment: ${exercise.equipment || 'None'}
Muscle Groups: ${exercise.primary_muscles || 'Unknown'}

Reason for substitution: ${reason}
Patient injuries: ${athlete.injuries || 'None reported'}
Available equipment: ${athlete.equipment_available || 'Standard gym'}

Provide 3 alternative exercises that:
1. Target the same muscle groups
2. Accommodate the stated reason
3. Are biomechanically similar
4. Are safe for patient's injuries

Format your response as JSON:
{
  "substitutions": [
    {
      "exercise_name": "Exercise Name",
      "rationale": "Why this works as a substitute",
      "confidence": 85
    }
  ]
}`

    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        messages: [
          { role: 'system', content: 'You are an expert physical therapy exercise specialist.' },
          { role: 'user', content: prompt }
        ],
        max_tokens: 800,
        temperature: 0.5,
        response_format: { type: "json_object" }
      }),
    })

    if (!openaiResponse.ok) {
      throw new Error('OpenAI API failed')
    }

    const completion = await openaiResponse.json()
    const suggestions = JSON.parse(completion.choices[0].message.content)

    // Match suggestions to existing exercises in database
    const substitutionRecords = []
    for (const suggestion of suggestions.substitutions) {
      // Try to find matching exercise
      const { data: matchedExercise } = await supabaseClient
        .from('exercises')
        .select('id')
        .ilike('name', `%${suggestion.exercise_name}%`)
        .limit(1)
        .single()

      if (matchedExercise) {
        // Save substitution suggestion
        const { data: substitution } = await supabaseClient
          .from('ai_exercise_substitutions')
          .insert({
            athlete_id: athlete_id,
            original_exercise_id: exercise_id,
            suggested_exercise_id: matchedExercise.id,
            reason: `${reason}: ${suggestion.rationale}`,
            ai_confidence: suggestion.confidence,
            accepted: null,
          })
          .select()
          .single()

        substitutionRecords.push(substitution)
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        substitutions: substitutionRecords,
        suggestions: suggestions.substitutions,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in ai-exercise-substitution:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
