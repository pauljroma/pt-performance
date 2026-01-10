// Generate Equipment Substitution Handler
// BUILD 138 - Exercise Substitution System
// Uses OpenAI to select BEST pre-vetted substitution candidate based on equipment and recovery

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Request interface
interface GenerateSubstitutionRequest {
  patient_id: string
  session_id: string
  scheduled_date: string
  equipment_available: string[]
  intensity_preference: 'recovery' | 'standard' | 'go_hard'
  readiness_score?: number
  whoop_recovery_score?: number
}

// Session exercise from database
interface SessionExercise {
  id: string
  exercise_id: string
  exercise_name: string
  prescribed_sets: number
  prescribed_reps: number
  prescribed_rpe?: number
  equipment_required?: string[]
}

// Substitution candidate from database
interface SubstitutionCandidate {
  substitute_id: string
  substitute_name: string
  equipment_required: string[]
  difficulty_delta: number
  notes: string | null
}

// JSONB patch structure
interface SubstitutionPatch {
  exercise_substitutions: {
    original_exercise_id: string
    original_exercise_name: string
    substitute_exercise_id: string
    substitute_exercise_name: string
    reason: string
  }[]
  intensity_adjustments: {
    exercise_id: string
    exercise_name: string
    original_sets: number
    adjusted_sets: number
    original_reps: number
    adjusted_reps: number
    original_rpe?: number
    adjusted_rpe?: number
    reason: string
  }[]
}

// Response interface
interface GenerateSubstitutionResponse {
  recommendation_id: string
  patch: SubstitutionPatch
  rationale: string
  status: 'pending'
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const {
      patient_id,
      session_id,
      scheduled_date,
      equipment_available,
      intensity_preference,
      readiness_score,
      whoop_recovery_score
    } = await req.json() as GenerateSubstitutionRequest

    // Validate required fields
    if (!patient_id || !session_id || !scheduled_date || !equipment_available) {
      return new Response(
        JSON.stringify({ error: 'patient_id, session_id, scheduled_date, and equipment_available required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[generate-equipment-substitution] Processing request for patient ${patient_id}, session ${session_id}`)

    // Create Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Fetch session exercises
    const { data: sessionExercises, error: sessionError } = await supabaseClient
      .from('session_exercises')
      .select(`
        id,
        exercise_id,
        exercise_templates!inner(name, equipment_required),
        prescribed_sets,
        prescribed_reps,
        prescribed_rpe
      `)
      .eq('session_id', session_id)

    if (sessionError) {
      console.error('[generate-equipment-substitution] Error fetching session exercises:', sessionError)
      throw new Error(`Failed to fetch session exercises: ${sessionError.message}`)
    }

    if (!sessionExercises || sessionExercises.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No exercises found for this session' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[generate-equipment-substitution] Found ${sessionExercises.length} exercises`)

    // Detect equipment mismatches
    const exercisesNeedingSubstitution: SessionExercise[] = []

    for (const exercise of sessionExercises) {
      const exerciseData = exercise as any
      const exerciseEquipment = exerciseData.exercise_templates.equipment_required || []

      // Check if exercise equipment is available
      const hasAllEquipment = exerciseEquipment.every((eq: string) =>
        equipment_available.includes(eq)
      )

      if (!hasAllEquipment) {
        exercisesNeedingSubstitution.push({
          id: exerciseData.id,
          exercise_id: exerciseData.exercise_id,
          exercise_name: exerciseData.exercise_templates.name,
          prescribed_sets: exerciseData.prescribed_sets,
          prescribed_reps: exerciseData.prescribed_reps,
          prescribed_rpe: exerciseData.prescribed_rpe,
          equipment_required: exerciseEquipment
        })
      }
    }

    console.log(`[generate-equipment-substitution] ${exercisesNeedingSubstitution.length} exercises need substitution`)

    if (exercisesNeedingSubstitution.length === 0) {
      return new Response(
        JSON.stringify({
          message: 'No equipment mismatches detected - all exercises can be performed',
          exercises_checked: sessionExercises.length
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get substitution candidates for each exercise
    const substitutionMap: Record<string, SubstitutionCandidate[]> = {}

    for (const exercise of exercisesNeedingSubstitution) {
      const { data: candidates, error: candidatesError } = await supabaseClient
        .rpc('get_substitution_candidates', {
          p_original_exercise_id: exercise.exercise_id,
          p_equipment_available: equipment_available
        })

      if (candidatesError) {
        console.error(`[generate-equipment-substitution] Error fetching candidates for ${exercise.exercise_name}:`, candidatesError)
        continue
      }

      if (candidates && candidates.length > 0) {
        substitutionMap[exercise.exercise_id] = candidates
        console.log(`[generate-equipment-substitution] Found ${candidates.length} candidates for ${exercise.exercise_name}`)
      } else {
        console.warn(`[generate-equipment-substitution] No candidates found for ${exercise.exercise_name}`)
      }
    }

    // Check if we have candidates for all exercises
    const exercisesWithoutCandidates = exercisesNeedingSubstitution.filter(
      ex => !substitutionMap[ex.exercise_id] || substitutionMap[ex.exercise_id].length === 0
    )

    if (exercisesWithoutCandidates.length > 0) {
      const names = exercisesWithoutCandidates.map(ex => ex.exercise_name).join(', ')
      return new Response(
        JSON.stringify({
          error: `No pre-vetted substitution candidates found for: ${names}`,
          exercises_without_candidates: exercisesWithoutCandidates.length
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Build AI prompt with ONLY pre-vetted candidates (rules-first approach)
    const promptParts = [`You are a physical therapy exercise substitution assistant. Your task is to select the BEST substitute exercise from pre-vetted candidates and adjust intensity based on patient recovery status.

CRITICAL RULES:
- You MUST select from the provided candidate list ONLY
- NEVER suggest exercises not in the candidate list
- Apply conservative intensity adjustments if recovery is low

PATIENT CONTEXT:
- Intensity Preference: ${intensity_preference}
- Readiness Score: ${readiness_score ?? 'Unknown'}
- WHOOP Recovery Score: ${whoop_recovery_score ?? 'Unknown'}
- Equipment Available: ${equipment_available.join(', ')}

EXERCISES NEEDING SUBSTITUTION:
`]

    exercisesNeedingSubstitution.forEach((exercise, idx) => {
      const candidates = substitutionMap[exercise.exercise_id]
      promptParts.push(`
${idx + 1}. ${exercise.exercise_name}
   Current Prescription: ${exercise.prescribed_sets} sets x ${exercise.prescribed_reps} reps${exercise.prescribed_rpe ? ` @ RPE ${exercise.prescribed_rpe}` : ''}
   Missing Equipment: ${exercise.equipment_required?.join(', ') || 'Unknown'}

   PRE-VETTED CANDIDATES:`)

      candidates.forEach((candidate, cidx) => {
        promptParts.push(`   ${cidx + 1}. ${candidate.substitute_name}
      - Equipment: ${candidate.equipment_required.join(', ')}
      - Difficulty: ${candidate.difficulty_delta > 0 ? '+' : ''}${candidate.difficulty_delta} (${candidate.difficulty_delta < 0 ? 'easier' : candidate.difficulty_delta > 0 ? 'harder' : 'similar'})
      - Notes: ${candidate.notes || 'None'}`)
      })
    })

    promptParts.push(`
TASK:
1. For each exercise, select the BEST candidate considering:
   - Equipment availability (already filtered)
   - Difficulty level appropriate for recovery status
   - Movement pattern similarity
   - Clinical appropriateness

2. Adjust sets/reps/RPE if needed based on:
   - WHOOP recovery < 60: Reduce by 10-20%
   - Intensity preference = 'recovery': Reduce RPE by 1-2
   - Intensity preference = 'go_hard': Can increase RPE by 1 if recovery > 80

Respond with valid JSON ONLY:
{
  "exercise_substitutions": [
    {
      "original_exercise_id": "uuid",
      "original_exercise_name": "name",
      "substitute_exercise_id": "uuid",
      "substitute_exercise_name": "name",
      "reason": "why this candidate was selected"
    }
  ],
  "intensity_adjustments": [
    {
      "exercise_id": "uuid (substitute_exercise_id)",
      "exercise_name": "name",
      "original_sets": 3,
      "adjusted_sets": 3,
      "original_reps": 10,
      "adjusted_reps": 8,
      "original_rpe": 7,
      "adjusted_rpe": 6,
      "reason": "why adjustment was made"
    }
  ],
  "rationale": "Overall explanation for the substitution plan"
}`)

    const prompt = promptParts.join('\n')

    console.log('[generate-equipment-substitution] Calling OpenAI API...')

    // Call OpenAI API
    const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
      },
      body: JSON.stringify({
        model: 'gpt-4-turbo-preview',
        temperature: 0.3,
        max_tokens: 2000,
        messages: [
          {
            role: 'system',
            content: 'You are a physical therapy exercise substitution expert. Always respond with valid JSON only. Select ONLY from provided pre-vetted candidates.'
          },
          {
            role: 'user',
            content: prompt
          }
        ]
      }),
    })

    if (!openaiResponse.ok) {
      const error = await openaiResponse.text()
      console.error('[generate-equipment-substitution] OpenAI API error:', error)
      throw new Error(`OpenAI API failed: ${error}`)
    }

    const completion = await openaiResponse.json()
    const aiResponseText = completion.choices[0].message.content
    const tokensUsed = completion.usage.total_tokens

    console.log(`[generate-equipment-substitution] OpenAI response received (${tokensUsed} tokens)`)

    // Parse JSON from AI response (handle markdown wrapping)
    let aiResponse: any
    try {
      const jsonMatch = aiResponseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(aiResponseText)
    } catch (parseError) {
      console.error('[generate-equipment-substitution] Failed to parse AI response:', aiResponseText)
      const errorMsg = parseError instanceof Error ? parseError.message : 'Unknown parse error'
      throw new Error(`Failed to parse AI response: ${errorMsg}`)
    }

    // Validate that AI selected from candidates only
    for (const sub of aiResponse.exercise_substitutions) {
      const originalExercise = exercisesNeedingSubstitution.find(ex => ex.exercise_id === sub.original_exercise_id)
      if (!originalExercise) {
        throw new Error(`AI selected invalid original exercise: ${sub.original_exercise_id}`)
      }

      const candidates = substitutionMap[sub.original_exercise_id]
      const isValid = candidates.some(c => c.substitute_id === sub.substitute_exercise_id)

      if (!isValid) {
        throw new Error(`AI selected exercise not in pre-vetted candidates: ${sub.substitute_exercise_name}`)
      }
    }

    console.log('[generate-equipment-substitution] AI response validated successfully')

    // Build final patch
    const patch: SubstitutionPatch = {
      exercise_substitutions: aiResponse.exercise_substitutions,
      intensity_adjustments: aiResponse.intensity_adjustments || []
    }

    // Save recommendation to database
    const { data: recommendation, error: insertError } = await supabaseClient
      .from('recommendations')
      .insert({
        patient_id: patient_id,
        session_id: session_id,
        scheduled_date: scheduled_date,
        recommendation_type: 'equipment_substitution',
        patch: patch,
        rationale: aiResponse.rationale,
        status: 'pending'
      })
      .select()
      .single()

    if (insertError) {
      console.error('[generate-equipment-substitution] Error saving recommendation:', insertError)
      throw new Error(`Failed to save recommendation: ${insertError.message}`)
    }

    console.log(`[generate-equipment-substitution] Recommendation saved: ${recommendation.id}`)

    // Return response
    const response: GenerateSubstitutionResponse = {
      recommendation_id: recommendation.id,
      patch: patch,
      rationale: aiResponse.rationale,
      status: 'pending'
    }

    return new Response(
      JSON.stringify({
        success: true,
        ...response,
        tokens_used: tokensUsed,
        exercises_substituted: patch.exercise_substitutions.length
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[generate-equipment-substitution] Error:', error)
    const errorMsg = error instanceof Error ? error.message : 'Unknown error'
    const errorStack = error instanceof Error ? error.stack : undefined
    return new Response(
      JSON.stringify({
        error: errorMsg,
        details: errorStack
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
