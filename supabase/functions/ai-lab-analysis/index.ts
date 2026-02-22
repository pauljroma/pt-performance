// ============================================================================
// AI Lab Analysis Edge Function
// Health Intelligence Platform - Biomarker Analysis
// ============================================================================
// Analyzes patient lab results against reference ranges using Claude AI
// Returns personalized insights, recommendations, and correlations with
// training/sleep data.
//
// Date: 2026-02-02
// Ticket: ACP-1201
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { checkRateLimit, rateLimitResponse } from '../_shared/rate-limit.ts'
import { corsHeaders, handleCors } from '../_shared/cors.ts'

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface LabAnalysisRequest {
  patient_id: string
  lab_result_id: string
}

interface BiomarkerValue {
  id: string
  biomarker_type: string
  value: number
  unit: string
  is_flagged: boolean
}

interface BiomarkerReference {
  biomarker_type: string
  name: string
  category: string
  optimal_low: number | null
  optimal_high: number | null
  normal_low: number | null
  normal_high: number | null
  unit: string
  description: string | null
}

interface BiomarkerAnalysis {
  biomarker_type: string
  name: string
  value: number
  unit: string
  status: 'optimal' | 'normal' | 'low' | 'high' | 'critical'
  interpretation: string
}

interface TrainingCorrelation {
  factor: string
  relationship: string
  recommendation: string
}

interface LabAnalysisResponse {
  analysis_id: string
  analysis_text: string
  recommendations: string[]
  biomarker_analyses: BiomarkerAnalysis[]
  training_correlations: TrainingCorrelation[]
  sleep_correlations: TrainingCorrelation[]
  overall_health_score: number
  priority_actions: string[]
  medical_disclaimer: string
  cached: boolean
}

interface ReadinessData {
  date: string
  readiness_score: number | null
  sleep_hours: number | null
  soreness_level: number | null
  energy_level: number | null
  stress_level: number | null
}

interface WorkoutData {
  completed_at: string
  name: string | null
  duration_minutes: number | null
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function determineBiomarkerStatus(
  value: number,
  reference: BiomarkerReference
): 'optimal' | 'normal' | 'low' | 'high' | 'critical' {
  const { optimal_low, optimal_high, normal_low, normal_high } = reference

  // Check for critical values (significantly outside normal range)
  if (normal_low !== null && value < normal_low * 0.7) return 'critical'
  if (normal_high !== null && value > normal_high * 1.3) return 'critical'

  // Check optimal range
  if (optimal_low !== null && optimal_high !== null) {
    if (value >= optimal_low && value <= optimal_high) return 'optimal'
  }

  // Check normal range
  if (normal_low !== null && value < normal_low) return 'low'
  if (normal_high !== null && value > normal_high) return 'high'

  return 'normal'
}

function calculateHealthScore(biomarkerAnalyses: BiomarkerAnalysis[]): number {
  if (biomarkerAnalyses.length === 0) return 75 // Default score

  let score = 100
  for (const analysis of biomarkerAnalyses) {
    switch (analysis.status) {
      case 'optimal': score += 0; break
      case 'normal': score -= 2; break
      case 'low': score -= 8; break
      case 'high': score -= 8; break
      case 'critical': score -= 15; break
    }
  }

  return Math.max(0, Math.min(100, score))
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  const corsResponse = handleCors(req)
  if (corsResponse) return corsResponse

  const origin = req.headers.get('Origin')
  const headers = corsHeaders(origin)

  try {
    const { patient_id, lab_result_id } = await req.json() as LabAnalysisRequest

    // Rate limit: 10 requests/minute for AI endpoints
    const rateLimitKey = patient_id || req.headers.get('x-forwarded-for') || 'anonymous'
    const { allowed, resetMs } = checkRateLimit(`ai-lab-analysis:${rateLimitKey}`, { windowMs: 60_000, maxRequests: 10 })
    if (!allowed) return rateLimitResponse(resetMs)

    // Validate required fields
    if (!patient_id || !lab_result_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id and lab_result_id are required' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // Validate UUID formats
    if (!isValidUUID(patient_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid patient_id format' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    if (!isValidUUID(lab_result_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid lab_result_id format' }),
        { status: 400, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[ai-lab-analysis] Processing analysis for patient ${patient_id}, lab result ${lab_result_id}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // CHECK FOR CACHED ANALYSIS (24 hour cache)
    // ========================================================================
    const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString()
    const { data: cachedAnalysis } = await supabaseClient
      .from('lab_analyses')
      .select('*')
      .eq('lab_result_id', lab_result_id)
      .gte('created_at', twentyFourHoursAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (cachedAnalysis) {
      console.log('[ai-lab-analysis] Returning cached analysis')
      return new Response(
        JSON.stringify({
          analysis_id: cachedAnalysis.id,
          analysis_text: cachedAnalysis.analysis_text,
          recommendations: cachedAnalysis.recommendations,
          biomarker_analyses: cachedAnalysis.biomarker_analyses,
          training_correlations: cachedAnalysis.training_correlations,
          sleep_correlations: cachedAnalysis.sleep_correlations,
          overall_health_score: cachedAnalysis.overall_health_score,
          priority_actions: cachedAnalysis.priority_actions,
          medical_disclaimer: cachedAnalysis.medical_disclaimer,
          cached: true
        } as LabAnalysisResponse),
        { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // FETCH LAB RESULT AND BIOMARKER VALUES
    // ========================================================================
    const { data: labResult, error: labError } = await supabaseClient
      .from('lab_results')
      .select('*')
      .eq('id', lab_result_id)
      .eq('patient_id', patient_id)
      .single()

    if (labError || !labResult) {
      console.error('[ai-lab-analysis] Lab result not found:', labError)
      return new Response(
        JSON.stringify({ error: 'Lab result not found' }),
        { status: 404, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    const { data: biomarkerValues, error: biomarkersError } = await supabaseClient
      .from('biomarker_values')
      .select('*')
      .eq('lab_result_id', lab_result_id)

    if (biomarkersError) {
      console.error('[ai-lab-analysis] Error fetching biomarkers:', biomarkersError)
      throw new Error(`Failed to fetch biomarker values: ${biomarkersError.message}`)
    }

    if (!biomarkerValues || biomarkerValues.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No biomarker values found for this lab result' }),
        { status: 404, headers: { ...headers, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // FETCH REFERENCE RANGES
    // ========================================================================
    const biomarkerTypes = biomarkerValues.map((bv: BiomarkerValue) => bv.biomarker_type)
    const { data: referenceRanges, error: refError } = await supabaseClient
      .from('biomarker_reference_ranges')
      .select('*')
      .in('biomarker_type', biomarkerTypes)

    if (refError) {
      console.error('[ai-lab-analysis] Error fetching reference ranges:', refError)
    }

    const referenceMap: Record<string, BiomarkerReference> = {}
    if (referenceRanges) {
      for (const ref of referenceRanges) {
        referenceMap[ref.biomarker_type] = ref as BiomarkerReference
      }
    }

    // ========================================================================
    // FETCH TRAINING AND SLEEP DATA FOR CORRELATIONS
    // ========================================================================
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()

    // Fetch readiness/sleep data
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', thirtyDaysAgo.split('T')[0])
      .order('date', { ascending: false })
      .limit(30)

    // Fetch recent workouts
    const { data: workoutData } = await supabaseClient
      .from('manual_sessions')
      .select('completed_at, name, duration_minutes')
      .eq('patient_id', patient_id)
      .eq('completed', true)
      .gte('completed_at', thirtyDaysAgo)
      .order('completed_at', { ascending: false })
      .limit(30)

    // ========================================================================
    // PRE-ANALYZE BIOMARKERS
    // ========================================================================
    const biomarkerAnalyses: BiomarkerAnalysis[] = []

    for (const bv of biomarkerValues as BiomarkerValue[]) {
      const reference = referenceMap[bv.biomarker_type]
      const status = reference
        ? determineBiomarkerStatus(bv.value, reference)
        : (bv.is_flagged ? 'high' : 'normal')

      biomarkerAnalyses.push({
        biomarker_type: bv.biomarker_type,
        name: reference?.name || bv.biomarker_type,
        value: bv.value,
        unit: bv.unit,
        status,
        interpretation: '' // Will be filled by AI
      })
    }

    const overallHealthScore = calculateHealthScore(biomarkerAnalyses)

    // Calculate training stats
    const avgSleep = readinessData && readinessData.length > 0
      ? (readinessData as ReadinessData[])
          .filter(r => r.sleep_hours !== null)
          .reduce((sum, r) => sum + (r.sleep_hours || 0), 0) / readinessData.filter(r => r.sleep_hours !== null).length
      : null

    const avgReadiness = readinessData && readinessData.length > 0
      ? (readinessData as ReadinessData[])
          .filter(r => r.readiness_score !== null)
          .reduce((sum, r) => sum + (r.readiness_score || 0), 0) / readinessData.filter(r => r.readiness_score !== null).length
      : null

    const workoutCount = workoutData?.length || 0

    // ========================================================================
    // CALL CLAUDE API FOR DETAILED ANALYSIS
    // ========================================================================
    const systemPrompt = `You are an advanced health and fitness biomarker analyst. Your role is to analyze lab results and provide actionable insights for athletes and fitness enthusiasts.

CRITICAL RULES:
1. Provide evidence-based interpretations only
2. Always contextualize results for active individuals (athletes have different optimal ranges)
3. Consider interactions between biomarkers
4. Relate findings to training and sleep data when available
5. Be specific with recommendations (not generic advice)
6. Flag any concerning patterns that need medical attention

BIOMARKER CATEGORIES TO CONSIDER:
- Hormones: testosterone, cortisol, thyroid function
- Inflammation: CRP, homocysteine
- Metabolic: glucose, HbA1c, lipid panel
- Vitamins/Minerals: vitamin D, B12, iron, ferritin
- Kidney/Liver: creatinine, eGFR, ALT, AST

TRAINING CONTEXT CONSIDERATIONS:
- High training volume can elevate AST/ALT, creatinine
- Overtraining may show elevated cortisol, suppressed testosterone
- Poor sleep impacts glucose regulation and inflammation
- Dehydration affects kidney markers`

    const userPrompt = `PATIENT LAB RESULTS (Test Date: ${labResult.test_date}):

BIOMARKER VALUES:
${biomarkerAnalyses.map(b => {
  const ref = referenceMap[b.biomarker_type]
  return `- ${b.name}: ${b.value} ${b.unit} [Status: ${b.status.toUpperCase()}]
    ${ref ? `Reference: Optimal ${ref.optimal_low}-${ref.optimal_high}, Normal ${ref.normal_low}-${ref.normal_high} ${ref.unit}` : 'No reference range available'}
    ${ref?.description ? `Description: ${ref.description}` : ''}`
}).join('\n')}

TRAINING CONTEXT (Last 30 Days):
- Workouts completed: ${workoutCount}
- Average sleep: ${avgSleep ? `${avgSleep.toFixed(1)} hours` : 'No data'}
- Average readiness score: ${avgReadiness ? `${avgReadiness.toFixed(0)}/100` : 'No data'}

TASK: Provide a comprehensive analysis of these lab results.

Respond with valid JSON ONLY:
{
  "analysis_text": "2-3 paragraph comprehensive analysis of the lab results, key findings, and overall health status",
  "biomarker_interpretations": {
    "biomarker_type": "Specific interpretation for this marker",
    ...
  },
  "recommendations": [
    "Specific, actionable recommendation 1",
    "Specific, actionable recommendation 2",
    ...
  ],
  "training_correlations": [
    {
      "factor": "Training Volume",
      "relationship": "How this biomarker relates to training",
      "recommendation": "Specific training adjustment"
    }
  ],
  "sleep_correlations": [
    {
      "factor": "Sleep Duration",
      "relationship": "How this biomarker relates to sleep",
      "recommendation": "Specific sleep optimization"
    }
  ],
  "priority_actions": [
    "Most urgent action to take",
    "Second priority action"
  ],
  "concerns": ["Any findings requiring medical attention"]
}`

    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[ai-lab-analysis] Calling Anthropic Claude API...')

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 2048,
        messages: [
          {
            role: 'user',
            content: `${systemPrompt}\n\n${userPrompt}`
          }
        ],
        temperature: 0.3,
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[ai-lab-analysis] Anthropic API error:', anthropicResponse.status, error)
      throw new Error(`Anthropic API error (${anthropicResponse.status}): ${error.substring(0, 200)}`)
    }

    const completion = await anthropicResponse.json()
    const responseText = completion.content?.[0]?.text

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[ai-lab-analysis] Received response from Claude')

    // Parse AI response
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[ai-lab-analysis] Failed to parse AI response:', responseText)
      throw new Error('Failed to parse AI response as JSON')
    }

    // ========================================================================
    // MERGE AI INTERPRETATIONS WITH BIOMARKER ANALYSES
    // ========================================================================
    const finalBiomarkerAnalyses = biomarkerAnalyses.map(analysis => ({
      ...analysis,
      interpretation: aiResponse.biomarker_interpretations?.[analysis.biomarker_type] ||
                      `${analysis.name} is ${analysis.status}`
    }))

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const medicalDisclaimer = `IMPORTANT MEDICAL DISCLAIMER: This analysis is provided for informational and educational purposes only. It is not a substitute for professional medical advice, diagnosis, or treatment. Lab results should always be reviewed by a qualified healthcare provider who can consider your complete medical history. If you have concerns about any values, please consult your physician. Do not make changes to medications or treatment plans based solely on this analysis.`

    const response: LabAnalysisResponse = {
      analysis_id: crypto.randomUUID(),
      analysis_text: aiResponse.analysis_text || 'Analysis completed. Please review the biomarker details.',
      recommendations: aiResponse.recommendations || [],
      biomarker_analyses: finalBiomarkerAnalyses,
      training_correlations: aiResponse.training_correlations || [],
      sleep_correlations: aiResponse.sleep_correlations || [],
      overall_health_score: overallHealthScore,
      priority_actions: aiResponse.priority_actions || [],
      medical_disclaimer: medicalDisclaimer,
      cached: false
    }

    // ========================================================================
    // SAVE ANALYSIS TO DATABASE
    // ========================================================================
    const { data: savedAnalysis, error: saveError } = await supabaseClient
      .from('lab_analyses')
      .insert({
        lab_result_id: lab_result_id,
        patient_id: patient_id,
        analysis_text: response.analysis_text,
        recommendations: response.recommendations,
        biomarker_analyses: response.biomarker_analyses,
        training_correlations: response.training_correlations,
        sleep_correlations: response.sleep_correlations,
        overall_health_score: response.overall_health_score,
        priority_actions: response.priority_actions,
        medical_disclaimer: response.medical_disclaimer
      })
      .select()
      .single()

    if (saveError) {
      console.error('[ai-lab-analysis] Error saving analysis:', saveError)
      // Continue without saving - still return the analysis
    } else if (savedAnalysis) {
      response.analysis_id = savedAnalysis.id
      console.log(`[ai-lab-analysis] Analysis saved: ${savedAnalysis.id}`)
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...headers, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-lab-analysis] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        medical_disclaimer: 'This service encountered an error. Please consult a healthcare provider for lab result interpretation.'
      }),
      { status: 500, headers: { ...headers, 'Content-Type': 'application/json' } }
    )
  }
})
