// ============================================================================
// ACP-970: Engagement Scoring Edge Function
// Calculates user engagement scores to identify at-risk users before churn.
//
// Endpoints:
// - GET:  Returns engagement scores for all patients or a single patient
//         Query params: ?patient_id=<uuid> (optional)
// - POST: Triggers batch recalculation of all engagement scores
//         Body: { "patient_id"?: "<uuid>", "threshold"?: 30 }
//
// Score Components (weighted composite, 0-100):
// - workout_frequency (40%): sessions in last 14 days / expected
// - streak_consistency (20%): current_streak / 14
// - feature_breadth (20%): distinct features used / 4
// - recency (20%): linear decay from last activity (0d=1.0, 14d+=0.0)
//
// Risk Levels:
// - high_risk (0-29), at_risk (30-49), moderate (50-69),
//   engaged (70-89), highly_engaged (90-100)
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// ============================================================================
// CORS HEADERS
// ============================================================================

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface EngagementScoreRow {
  id: string
  patient_id: string
  score: number
  risk_level: string
  components: {
    workout_frequency: {
      raw_value: number
      weight: number
      weighted_value: number
      sessions_completed: number
      expected_sessions: number
    }
    streak_consistency: {
      raw_value: number
      weight: number
      weighted_value: number
      current_streak: number
    }
    feature_breadth: {
      raw_value: number
      weight: number
      weighted_value: number
      features_used: number
      features_total: number
    }
    recency: {
      raw_value: number
      weight: number
      weighted_value: number
      days_since_last_activity: number
    }
  }
  calculated_at: string
}

interface BatchResult {
  total_patients: number
  successful: number
  errors: number
  execution_time_ms: number
  results: EngagementScoreRow[]
}

interface AtRiskUser {
  patient_id: string
  score: number
  risk_level: string
  components: Record<string, unknown>
  calculated_at: string
  days_since_last_activity: number
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  const startTime = Date.now()

  try {
    // Initialize Supabase client with service role (bypasses RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables: SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY')
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // Route based on HTTP method
    if (req.method === 'GET') {
      return await handleGet(supabase, req, startTime)
    } else if (req.method === 'POST') {
      return await handlePost(supabase, req, startTime)
    } else {
      return new Response(
        JSON.stringify({ error: `Method ${req.method} not allowed. Use GET or POST.` }),
        {
          status: 405,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }
  } catch (error) {
    console.error('Error in engagement-scoring:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message,
        execution_time_ms: Date.now() - startTime,
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

// ============================================================================
// GET HANDLER
// ============================================================================
// Returns engagement scores for all patients, or a single patient if
// ?patient_id=<uuid> is provided. Always returns the most recent score.

async function handleGet(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  startTime: number
): Promise<Response> {
  const url = new URL(req.url)
  const patientId = url.searchParams.get('patient_id')
  const includeAtRisk = url.searchParams.get('at_risk') === 'true'
  const threshold = parseInt(url.searchParams.get('threshold') || '30', 10)

  // If requesting at-risk users specifically
  if (includeAtRisk) {
    const { data, error } = await supabase.rpc('get_at_risk_users', {
      threshold,
    })

    if (error) {
      throw new Error(`Failed to fetch at-risk users: ${error.message}`)
    }

    return new Response(
      JSON.stringify({
        success: true,
        at_risk_users: data as AtRiskUser[],
        threshold,
        count: (data as AtRiskUser[]).length,
        execution_time_ms: Date.now() - startTime,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }

  // Single patient lookup
  if (patientId) {
    const { data, error } = await supabase
      .from('engagement_scores')
      .select('*')
      .eq('patient_id', patientId)
      .order('calculated_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (error) {
      throw new Error(`Failed to fetch engagement score: ${error.message}`)
    }

    if (!data) {
      return new Response(
        JSON.stringify({
          success: true,
          data: null,
          message: 'No engagement score found for this patient. Trigger a POST to calculate.',
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: data as EngagementScoreRow,
        execution_time_ms: Date.now() - startTime,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }

  // All patients — fetch the latest score per patient
  const { data, error } = await supabase
    .from('engagement_scores')
    .select('*')
    .order('calculated_at', { ascending: false })

  if (error) {
    throw new Error(`Failed to fetch engagement scores: ${error.message}`)
  }

  // Deduplicate to latest score per patient
  const latestByPatient = new Map<string, EngagementScoreRow>()
  for (const row of (data || []) as EngagementScoreRow[]) {
    if (!latestByPatient.has(row.patient_id)) {
      latestByPatient.set(row.patient_id, row)
    }
  }

  const scores = Array.from(latestByPatient.values())

  // Build summary statistics
  const summary = {
    total_patients: scores.length,
    highly_engaged: scores.filter((s) => s.risk_level === 'highly_engaged').length,
    engaged: scores.filter((s) => s.risk_level === 'engaged').length,
    moderate: scores.filter((s) => s.risk_level === 'moderate').length,
    at_risk: scores.filter((s) => s.risk_level === 'at_risk').length,
    high_risk: scores.filter((s) => s.risk_level === 'high_risk').length,
    average_score:
      scores.length > 0
        ? Math.round(scores.reduce((sum, s) => sum + s.score, 0) / scores.length)
        : 0,
  }

  return new Response(
    JSON.stringify({
      success: true,
      summary,
      data: scores,
      execution_time_ms: Date.now() - startTime,
    }),
    {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  )
}

// ============================================================================
// POST HANDLER
// ============================================================================
// Triggers engagement score recalculation.
// Body options:
//   { "patient_id": "<uuid>" }  — calculate for one patient
//   {}                          — batch calculate for all patients

async function handlePost(
  supabase: ReturnType<typeof createClient>,
  req: Request,
  startTime: number
): Promise<Response> {
  const body = await req.json().catch(() => ({}))
  const { patient_id, threshold } = body

  console.log('Engagement score calculation triggered:', {
    patient_id: patient_id || 'all',
    timestamp: new Date().toISOString(),
  })

  // Single patient calculation
  if (patient_id) {
    const { data, error } = await supabase.rpc('calculate_engagement_score', {
      p_patient_id: patient_id,
    })

    if (error) {
      throw new Error(`Failed to calculate engagement score: ${error.message}`)
    }

    const result = data as EngagementScoreRow

    console.log('Single patient score calculated:', {
      patient_id,
      score: result?.score,
      risk_level: result?.risk_level,
    })

    return new Response(
      JSON.stringify({
        success: true,
        data: result,
        execution_time_ms: Date.now() - startTime,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }

  // Batch calculation for all patients
  const { data, error } = await supabase.rpc('calculate_all_engagement_scores')

  if (error) {
    throw new Error(`Failed to calculate engagement scores: ${error.message}`)
  }

  const batchResult = data as BatchResult

  console.log('Batch engagement score calculation complete:', {
    total_patients: batchResult.total_patients,
    successful: batchResult.successful,
    errors: batchResult.errors,
    execution_time_ms: batchResult.execution_time_ms,
  })

  // If a threshold was provided, also return at-risk users
  let atRiskUsers: AtRiskUser[] | null = null
  if (threshold !== undefined) {
    const { data: riskData, error: riskError } = await supabase.rpc('get_at_risk_users', {
      threshold: threshold || 30,
    })

    if (!riskError) {
      atRiskUsers = riskData as AtRiskUser[]
    }
  }

  const response: Record<string, unknown> = {
    success: true,
    total_patients: batchResult.total_patients,
    successful: batchResult.successful,
    errors: batchResult.errors,
    batch_execution_time_ms: batchResult.execution_time_ms,
    execution_time_ms: Date.now() - startTime,
  }

  if (atRiskUsers !== null) {
    response.at_risk_users = atRiskUsers
    response.at_risk_count = atRiskUsers.length
    response.at_risk_threshold = threshold || 30
  }

  return new Response(JSON.stringify(response), {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  })
}

/* ============================================================================
   DEPLOYMENT INSTRUCTIONS
   ============================================================================

   1. Apply the migration first:
      ```bash
      supabase db push
      ```
      Or apply manually:
      ```bash
      supabase migration up
      ```

   2. Deploy this Edge Function:
      ```bash
      supabase functions deploy engagement-scoring
      ```

   3. Test locally:
      ```bash
      supabase functions serve engagement-scoring
      ```

   4. Test with curl:

      # Get all scores
      curl http://localhost:54321/functions/v1/engagement-scoring \
        -H "Authorization: Bearer YOUR_ANON_KEY"

      # Get single patient score
      curl "http://localhost:54321/functions/v1/engagement-scoring?patient_id=UUID_HERE" \
        -H "Authorization: Bearer YOUR_ANON_KEY"

      # Get at-risk users
      curl "http://localhost:54321/functions/v1/engagement-scoring?at_risk=true&threshold=30" \
        -H "Authorization: Bearer YOUR_ANON_KEY"

      # Trigger batch recalculation
      curl -X POST http://localhost:54321/functions/v1/engagement-scoring \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer YOUR_ANON_KEY" \
        -d '{}'

      # Calculate for single patient
      curl -X POST http://localhost:54321/functions/v1/engagement-scoring \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer YOUR_ANON_KEY" \
        -d '{"patient_id": "UUID_HERE"}'

      # Batch recalculate and return at-risk users
      curl -X POST http://localhost:54321/functions/v1/engagement-scoring \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer YOUR_ANON_KEY" \
        -d '{"threshold": 30}'

   5. Set up daily cron job for automated scoring:
      ```sql
      SELECT cron.schedule(
        'engagement-scoring-daily',
        '0 3 * * *', -- Run at 3 AM daily
        $$
        SELECT net.http_post(
          url := 'https://your-project.supabase.co/functions/v1/engagement-scoring',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.service_role_key')
          ),
          body := jsonb_build_object('threshold', 30)
        );
        $$
      );
      ```

   ============================================================================
*/
