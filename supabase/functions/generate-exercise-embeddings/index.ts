// Generate Exercise Embeddings
// RAG Exercise Library — Populates vector embeddings for semantic search
// Uses OpenAI text-embedding-3-small (1536 dimensions) to embed exercise content
//
// SETUP REQUIRED:
//   1. Set OPENAI_API_KEY in Supabase Edge Function secrets:
//      supabase secrets set OPENAI_API_KEY=sk-...
//   2. Run the 20260220110000_exercise_embeddings.sql migration first
//   3. Invoke this function to populate embeddings:
//      curl -X POST https://<project>.supabase.co/functions/v1/generate-exercise-embeddings \
//        -H "Authorization: Bearer <service_role_key>" \
//        -H "Content-Type: application/json" \
//        -d '{"batch_size": 50}'
//
// This function is idempotent — it only generates embeddings for exercises that
// do not already have one in exercise_embeddings.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// OpenAI embedding model — 1536 dimensions, cost-effective for search
const EMBEDDING_MODEL = 'text-embedding-3-small'
const EMBEDDING_DIMENSIONS = 1536

// Maximum exercises to process in one invocation (avoid timeouts)
const DEFAULT_BATCH_SIZE = 50

interface ExerciseTemplate {
  id: string
  name: string
  category: string | null
  body_region: string | null
  primary_muscle_group: string | null
  target_muscles: string[] | null
  secondary_muscles: string[] | null
  equipment_required: string[] | null
  equipment_type: string | null
  movement_pattern: string | null
  difficulty_level: string | number | null
  technique_cues: Record<string, string[]> | null
  common_mistakes: string | null
  safety_notes: string | null
  why_this_exercise: string | null
  clinical_tags: unknown | null
}

interface EmbeddingRow {
  exercise_template_id: string
  content: string
  embedding: number[]
  muscle_groups: string[]
  equipment: string[]
  difficulty: string | null
  contraindications: string[]
  safe_for: string[]
  movement_pattern: string | null
}

/**
 * Build the content string for embedding from exercise template data.
 * This is the text that gets vectorized — it should capture everything
 * a therapist might search for.
 */
function buildContentString(exercise: ExerciseTemplate): string {
  const parts: string[] = []

  // Exercise name (most important)
  parts.push(`Exercise: ${exercise.name}`)

  // Category and body region
  if (exercise.category) {
    parts.push(`Category: ${exercise.category}`)
  }
  if (exercise.body_region) {
    parts.push(`Body Region: ${exercise.body_region}`)
  }

  // Movement pattern
  if (exercise.movement_pattern) {
    parts.push(`Movement Pattern: ${exercise.movement_pattern}`)
  }

  // Muscles
  const allMuscles: string[] = []
  if (exercise.primary_muscle_group) allMuscles.push(exercise.primary_muscle_group)
  if (exercise.target_muscles?.length) allMuscles.push(...exercise.target_muscles)
  if (exercise.secondary_muscles?.length) allMuscles.push(...exercise.secondary_muscles)

  if (allMuscles.length > 0) {
    const unique = [...new Set(allMuscles)]
    parts.push(`Muscles: ${unique.join(', ')}`)
  }

  // Equipment
  const allEquipment: string[] = []
  if (exercise.equipment_required?.length) allEquipment.push(...exercise.equipment_required)
  if (exercise.equipment_type) allEquipment.push(exercise.equipment_type)
  if (allEquipment.length > 0) {
    const unique = [...new Set(allEquipment)]
    parts.push(`Equipment: ${unique.join(', ')}`)
  } else {
    parts.push('Equipment: bodyweight / none required')
  }

  // Difficulty
  if (exercise.difficulty_level != null) {
    const diffStr = typeof exercise.difficulty_level === 'number'
      ? ['beginner', 'beginner', 'intermediate', 'intermediate', 'advanced', 'advanced'][exercise.difficulty_level] || 'intermediate'
      : exercise.difficulty_level
    parts.push(`Difficulty: ${diffStr}`)
  }

  // Why this exercise (clinical rationale)
  if (exercise.why_this_exercise) {
    parts.push(`Rationale: ${exercise.why_this_exercise}`)
  }

  // Technique cues (flattened)
  if (exercise.technique_cues) {
    const cueTexts: string[] = []
    for (const [phase, cues] of Object.entries(exercise.technique_cues)) {
      if (Array.isArray(cues)) {
        cueTexts.push(`${phase}: ${cues.join('. ')}`)
      }
    }
    if (cueTexts.length > 0) {
      parts.push(`Technique: ${cueTexts.join('. ')}`)
    }
  }

  // Safety notes and contraindications
  if (exercise.safety_notes) {
    parts.push(`Safety: ${exercise.safety_notes}`)
  }

  // Common mistakes
  if (exercise.common_mistakes) {
    parts.push(`Common Mistakes: ${exercise.common_mistakes}`)
  }

  // Clinical tags
  if (exercise.clinical_tags && Array.isArray(exercise.clinical_tags)) {
    parts.push(`Clinical Tags: ${(exercise.clinical_tags as string[]).join(', ')}`)
  }

  return parts.join('\n')
}

/**
 * Extract structured metadata from exercise template for filtering columns.
 */
function extractMetadata(exercise: ExerciseTemplate): {
  muscle_groups: string[]
  equipment: string[]
  difficulty: string | null
  safe_for: string[]
  contraindications: string[]
  movement_pattern: string | null
} {
  // Muscle groups
  const muscles: string[] = []
  if (exercise.primary_muscle_group) muscles.push(exercise.primary_muscle_group)
  if (exercise.target_muscles?.length) muscles.push(...exercise.target_muscles)
  const uniqueMuscles = [...new Set(muscles)]

  // Equipment
  const equipment: string[] = []
  if (exercise.equipment_required?.length) equipment.push(...exercise.equipment_required)
  if (exercise.equipment_type && !equipment.includes(exercise.equipment_type)) {
    equipment.push(exercise.equipment_type)
  }

  // Difficulty — normalize to the enum values
  let difficulty: string | null = null
  if (exercise.difficulty_level != null) {
    if (typeof exercise.difficulty_level === 'number') {
      if (exercise.difficulty_level <= 2) difficulty = 'beginner'
      else if (exercise.difficulty_level <= 3) difficulty = 'intermediate'
      else difficulty = 'advanced'
    } else if (['beginner', 'intermediate', 'advanced'].includes(exercise.difficulty_level)) {
      difficulty = exercise.difficulty_level
    }
  }

  // Safe-for and contraindications derived from safety_notes and clinical_tags
  const safe_for: string[] = []
  const contraindications: string[] = []

  // Parse safety notes for common rehab keywords
  const safetyText = (exercise.safety_notes || '').toLowerCase()
  const clinicalText = JSON.stringify(exercise.clinical_tags || '').toLowerCase()
  const combinedText = `${safetyText} ${clinicalText} ${(exercise.why_this_exercise || '').toLowerCase()}`

  // Safe-for inference from positive mentions
  if (combinedText.includes('shoulder-friendly') || combinedText.includes('shoulder safe')) {
    safe_for.push('shoulder injury')
  }
  if (combinedText.includes('knee-friendly') || combinedText.includes('knee safe') || combinedText.includes('safer for knees')) {
    safe_for.push('knee injury')
  }
  if (combinedText.includes('back-friendly') || combinedText.includes('lower back safe') || combinedText.includes('protect lower back')) {
    safe_for.push('lower back pain')
  }
  if (combinedText.includes('bodyweight') || combinedText.includes('no equipment')) {
    safe_for.push('home workout')
  }
  if (combinedText.includes('beginner') || combinedText.includes('rehab') || combinedText.includes('recovery')) {
    safe_for.push('rehab')
  }

  // Contraindication inference from warning mentions
  if (combinedText.includes('avoid if') && combinedText.includes('shoulder')) {
    contraindications.push('shoulder impingement')
  }
  if (combinedText.includes('stop if') && combinedText.includes('back')) {
    contraindications.push('acute lower back pain')
  }
  if (combinedText.includes('not recommended') && combinedText.includes('knee')) {
    contraindications.push('acute knee injury')
  }

  return {
    muscle_groups: uniqueMuscles,
    equipment,
    difficulty,
    safe_for,
    contraindications,
    movement_pattern: exercise.movement_pattern || exercise.category || null,
  }
}

/**
 * Call OpenAI Embeddings API for a batch of content strings.
 * Returns an array of embedding vectors in the same order as the input.
 */
async function generateEmbeddings(
  contents: string[],
  openaiKey: string
): Promise<number[][]> {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${openaiKey}`,
    },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: contents,
      dimensions: EMBEDDING_DIMENSIONS,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OpenAI Embeddings API failed (${response.status}): ${error}`)
  }

  const result = await response.json()

  // OpenAI returns embeddings sorted by index
  const sorted = result.data.sort((a: { index: number }, b: { index: number }) => a.index - b.index)
  return sorted.map((item: { embedding: number[] }) => item.embedding)
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse optional parameters
    let batchSize = DEFAULT_BATCH_SIZE
    let forceRegenerate = false

    if (req.method === 'POST') {
      try {
        const body = await req.json()
        if (body.batch_size && typeof body.batch_size === 'number') {
          batchSize = Math.min(body.batch_size, 200) // Cap at 200
        }
        if (body.force_regenerate === true) {
          forceRegenerate = true
        }
      } catch {
        // No body or invalid JSON — use defaults
      }
    }

    // Verify OpenAI API key is configured
    const openaiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiKey) {
      return new Response(
        JSON.stringify({
          error: 'OPENAI_API_KEY not configured',
          setup: 'Run: supabase secrets set OPENAI_API_KEY=sk-your-key-here',
          docs: 'https://platform.openai.com/api-keys',
        }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create Supabase client with service role (needed to write embeddings)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Fetch exercise templates that need embeddings
    let query = supabase
      .from('exercise_templates')
      .select(`
        id, name, category, body_region,
        primary_muscle_group, target_muscles, secondary_muscles,
        equipment_required, equipment_type,
        movement_pattern, difficulty_level,
        technique_cues, common_mistakes, safety_notes,
        why_this_exercise, clinical_tags
      `)
      .order('name')
      .limit(batchSize)

    // Unless force-regenerating, only process exercises without embeddings
    if (!forceRegenerate) {
      // Get IDs that already have embeddings
      const { data: existingEmbeddings } = await supabase
        .from('exercise_embeddings')
        .select('exercise_template_id')

      const existingIds = (existingEmbeddings || []).map(
        (e: { exercise_template_id: string }) => e.exercise_template_id
      )

      if (existingIds.length > 0) {
        query = query.not('id', 'in', `(${existingIds.join(',')})`)
      }
    }

    const { data: exercises, error: fetchError } = await query

    if (fetchError) {
      throw new Error(`Failed to fetch exercise templates: ${fetchError.message}`)
    }

    if (!exercises || exercises.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'All exercise templates already have embeddings',
          processed: 0,
          total_with_embeddings: (await supabase.from('exercise_embeddings').select('id', { count: 'exact', head: true })).count || 0,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[generate-exercise-embeddings] Processing ${exercises.length} exercises`)

    // Build content strings for all exercises
    const contentStrings: string[] = exercises.map((ex: ExerciseTemplate) => buildContentString(ex))
    const metadataList = exercises.map((ex: ExerciseTemplate) => extractMetadata(ex))

    // Generate embeddings via OpenAI (batched — the API handles up to 2048 inputs)
    console.log(`[generate-exercise-embeddings] Calling OpenAI Embeddings API for ${contentStrings.length} texts`)
    const embeddings = await generateEmbeddings(contentStrings, openaiKey)

    console.log(`[generate-exercise-embeddings] Received ${embeddings.length} embeddings`)

    // Build rows for upsert
    const rows: EmbeddingRow[] = exercises.map((ex: ExerciseTemplate, i: number) => ({
      exercise_template_id: ex.id,
      content: contentStrings[i],
      embedding: embeddings[i],
      muscle_groups: metadataList[i].muscle_groups,
      equipment: metadataList[i].equipment,
      difficulty: metadataList[i].difficulty,
      safe_for: metadataList[i].safe_for,
      contraindications: metadataList[i].contraindications,
      movement_pattern: metadataList[i].movement_pattern,
    }))

    // Upsert into exercise_embeddings (ON CONFLICT update)
    const { error: upsertError, count } = await supabase
      .from('exercise_embeddings')
      .upsert(rows, {
        onConflict: 'exercise_template_id',
        count: 'exact',
      })

    if (upsertError) {
      throw new Error(`Failed to upsert embeddings: ${upsertError.message}`)
    }

    console.log(`[generate-exercise-embeddings] Upserted ${count} embeddings`)

    // Get total count of embeddings
    const { count: totalCount } = await supabase
      .from('exercise_embeddings')
      .select('id', { count: 'exact', head: true })

    return new Response(
      JSON.stringify({
        success: true,
        processed: exercises.length,
        upserted: count,
        total_with_embeddings: totalCount,
        model: EMBEDDING_MODEL,
        dimensions: EMBEDDING_DIMENSIONS,
        exercises_processed: exercises.map((ex: ExerciseTemplate) => ({
          id: ex.id,
          name: ex.name,
          content_length: contentStrings[exercises.indexOf(ex)].length,
        })),
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[generate-exercise-embeddings] Error:', error)
    const errorMsg = error instanceof Error ? error.message : 'Unknown error'
    const errorStack = error instanceof Error ? error.stack : undefined
    return new Response(
      JSON.stringify({
        error: errorMsg,
        details: errorStack,
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
