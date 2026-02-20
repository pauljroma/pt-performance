// Search Exercises — Semantic search over exercise library
// RAG Exercise Library — Used by AI Quick Pick to find exercises by natural language query
//
// Usage:
//   POST /functions/v1/search-exercises
//   {
//     "query": "lower body exercise safe for knee rehab",
//     "match_count": 10,
//     "match_threshold": 0.7,
//     "filters": {
//       "muscle_groups": ["quads", "glutes"],
//       "equipment": ["bodyweight"],
//       "safe_for": ["knee injury"],
//       "movement_pattern": "squat",
//       "difficulty": "beginner"
//     }
//   }
//
// Returns ranked exercise results with similarity scores.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

const EMBEDDING_MODEL = 'text-embedding-3-small'
const EMBEDDING_DIMENSIONS = 1536

interface SearchRequest {
  query: string
  match_count?: number       // default 10
  match_threshold?: number   // default 0.7
  filters?: {
    muscle_groups?: string[]
    equipment?: string[]
    safe_for?: string[]
    movement_pattern?: string
    difficulty?: string
  }
  include_template_data?: boolean  // default true — join exercise_templates for full info
}

interface SearchResult {
  exercise_template_id: string
  content: string
  muscle_groups: string[]
  equipment: string[]
  difficulty: string | null
  safe_for: string[]
  contraindications: string[]
  movement_pattern: string | null
  similarity: number
  // Populated if include_template_data is true
  template?: {
    name: string
    category: string | null
    body_region: string | null
    video_url: string | null
    video_thumbnail_url: string | null
    technique_cues: unknown | null
    common_mistakes: string | null
    safety_notes: string | null
    why_this_exercise: string | null
  }
}

/**
 * Generate an embedding for a single query string.
 */
async function embedQuery(query: string, openaiKey: string): Promise<number[]> {
  const response = await fetch('https://api.openai.com/v1/embeddings', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${openaiKey}`,
    },
    body: JSON.stringify({
      model: EMBEDDING_MODEL,
      input: query,
      dimensions: EMBEDDING_DIMENSIONS,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    throw new Error(`OpenAI Embeddings API failed (${response.status}): ${error}`)
  }

  const result = await response.json()
  return result.data[0].embedding
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Parse request
    const body: SearchRequest = await req.json()

    if (!body.query || typeof body.query !== 'string' || body.query.trim().length === 0) {
      return new Response(
        JSON.stringify({ error: 'query is required and must be a non-empty string' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const query = body.query.trim()
    const matchCount = Math.min(body.match_count || 10, 50) // Cap at 50
    const matchThreshold = body.match_threshold ?? 0.7
    const includeTemplateData = body.include_template_data !== false
    const filters = body.filters || {}

    // Verify OpenAI API key
    const openaiKey = Deno.env.get('OPENAI_API_KEY')
    if (!openaiKey) {
      return new Response(
        JSON.stringify({
          error: 'OPENAI_API_KEY not configured',
          setup: 'Run: supabase secrets set OPENAI_API_KEY=sk-your-key-here',
        }),
        { status: 503, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[search-exercises] Query: "${query}" (threshold=${matchThreshold}, count=${matchCount})`)

    // Step 1: Generate embedding for the search query
    const queryEmbedding = await embedQuery(query, openaiKey)

    console.log(`[search-exercises] Query embedded (${queryEmbedding.length} dimensions)`)

    // Step 2: Create Supabase client
    // Use the user's JWT for RLS if provided, otherwise service role
    const authHeader = req.headers.get('Authorization')
    const supabase = authHeader
      ? createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_ANON_KEY') ?? '',
          {
            global: { headers: { Authorization: authHeader } },
            auth: { persistSession: false },
          }
        )
      : createClient(
          Deno.env.get('SUPABASE_URL') ?? '',
          Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
          { auth: { persistSession: false } }
        )

    // Step 3: Call the search_exercises Postgres function via RPC
    const { data: searchResults, error: searchError } = await supabase
      .rpc('search_exercises', {
        query_embedding: queryEmbedding,
        match_threshold: matchThreshold,
        match_count: matchCount,
        filter_muscle_groups: filters.muscle_groups || null,
        filter_equipment: filters.equipment || null,
        filter_safe_for: filters.safe_for || null,
        filter_movement_pattern: filters.movement_pattern || null,
        filter_difficulty: filters.difficulty || null,
      })

    if (searchError) {
      console.error('[search-exercises] RPC error:', searchError)
      throw new Error(`search_exercises RPC failed: ${searchError.message}`)
    }

    console.log(`[search-exercises] Found ${searchResults?.length || 0} results`)

    // Step 4: Optionally enrich with full exercise template data
    let results: SearchResult[] = searchResults || []

    if (includeTemplateData && results.length > 0) {
      const templateIds = results.map((r: SearchResult) => r.exercise_template_id)

      const { data: templates, error: templateError } = await supabase
        .from('exercise_templates')
        .select(`
          id, name, category, body_region,
          video_url, video_thumbnail_url,
          technique_cues, common_mistakes, safety_notes,
          why_this_exercise
        `)
        .in('id', templateIds)

      if (templateError) {
        console.warn('[search-exercises] Template enrichment failed:', templateError.message)
        // Continue without template data rather than failing
      } else if (templates) {
        const templateMap: Record<string, typeof templates[0]> = {}
        for (const t of templates) {
          templateMap[t.id] = t
        }

        results = results.map((result: SearchResult) => ({
          ...result,
          template: templateMap[result.exercise_template_id]
            ? {
                name: templateMap[result.exercise_template_id].name,
                category: templateMap[result.exercise_template_id].category,
                body_region: templateMap[result.exercise_template_id].body_region,
                video_url: templateMap[result.exercise_template_id].video_url,
                video_thumbnail_url: templateMap[result.exercise_template_id].video_thumbnail_url,
                technique_cues: templateMap[result.exercise_template_id].technique_cues,
                common_mistakes: templateMap[result.exercise_template_id].common_mistakes,
                safety_notes: templateMap[result.exercise_template_id].safety_notes,
                why_this_exercise: templateMap[result.exercise_template_id].why_this_exercise,
              }
            : undefined,
        }))
      }
    }

    return new Response(
      JSON.stringify({
        success: true,
        query,
        results,
        result_count: results.length,
        filters_applied: Object.keys(filters).length > 0 ? filters : null,
        model: EMBEDDING_MODEL,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[search-exercises] Error:', error)
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
