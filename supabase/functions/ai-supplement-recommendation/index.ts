// ============================================================================
// AI Supplement Recommendation Edge Function
// Health Intelligence Platform - Personalized Supplement Stack
// ============================================================================
// Analyzes patient goals, lab results, sleep data, and recovery needs to
// provide personalized supplement recommendations with Momentous products.
//
// Date: 2026-02-02
// Ticket: ACP-1201
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface SupplementRecommendationRequest {
  patient_id: string
}

interface SupplementRecommendation {
  supplement_id: string | null
  name: string
  brand: string
  category: string
  dosage: string
  timing: string
  evidence_rating: number // 1-5 stars
  rationale: string
  goal_alignment: string[]
  purchase_url: string | null
  priority: 'essential' | 'recommended' | 'optional'
  warnings: string[]
}

interface SupplementRecommendationResponse {
  recommendation_id: string
  recommendations: SupplementRecommendation[]
  stack_summary: string
  total_daily_cost_estimate: string
  goal_coverage: Record<string, string[]>
  interaction_warnings: string[]
  timing_schedule: TimingSchedule
  disclaimer: string
  cached: boolean
}

interface TimingSchedule {
  morning: SupplementTiming[]
  pre_workout: SupplementTiming[]
  post_workout: SupplementTiming[]
  evening: SupplementTiming[]
  with_meals: SupplementTiming[]
}

interface SupplementTiming {
  name: string
  dosage: string
  notes: string
}

interface PatientGoal {
  id: string
  category: string
  title: string
  target_date: string | null
  status: string
}

interface LabResult {
  test_date: string
  biomarkers: {
    biomarker_type: string
    value: number
    unit: string
    is_flagged: boolean
  }[]
}

interface SleepData {
  avg_sleep_hours: number
  avg_sleep_quality: number | null
  days_below_7_hours: number
}

interface RecoveryData {
  avg_readiness: number
  avg_soreness: number
  avg_energy: number
  avg_stress: number
}

interface Supplement {
  id: string
  name: string
  category: string
  evidence_rating: number
  dosage_info: string | null
  timing_recommendation: string | null
  interactions: any
}

// ============================================================================
// MOMENTOUS PRODUCT CATALOG
// ============================================================================
const MOMENTOUS_PRODUCTS: Record<string, {
  name: string
  category: string
  url: string
  standard_dose: string
  best_timing: string
  price_per_serving: number
}> = {
  'creatine': {
    name: 'Momentous Creatine',
    category: 'performance',
    url: 'https://www.livemomentous.com/products/creatine',
    standard_dose: '5g',
    best_timing: 'Any time, with or without food',
    price_per_serving: 0.50
  },
  'vitamin_d3': {
    name: 'Momentous Vitamin D3',
    category: 'vitamins',
    url: 'https://www.livemomentous.com/products/vitamin-d3',
    standard_dose: '5000 IU',
    best_timing: 'Morning with fat-containing meal',
    price_per_serving: 0.35
  },
  'omega3': {
    name: 'Momentous Omega-3',
    category: 'essential_fatty_acids',
    url: 'https://www.livemomentous.com/products/omega-3',
    standard_dose: '2g EPA/DHA',
    best_timing: 'With meals',
    price_per_serving: 1.00
  },
  'magnesium': {
    name: 'Momentous Magnesium L-Threonate',
    category: 'minerals',
    url: 'https://www.livemomentous.com/products/magnesium-l-threonate',
    standard_dose: '144mg elemental magnesium',
    best_timing: '30-60 minutes before bed',
    price_per_serving: 1.50
  },
  'sleep_pack': {
    name: 'Momentous Elite Sleep',
    category: 'sleep',
    url: 'https://www.livemomentous.com/products/elite-sleep',
    standard_dose: 'As directed',
    best_timing: '30-60 minutes before bed',
    price_per_serving: 2.00
  },
  'whey_protein': {
    name: 'Momentous Grass-Fed Whey Protein',
    category: 'protein',
    url: 'https://www.livemomentous.com/products/grass-fed-whey-protein',
    standard_dose: '25g protein',
    best_timing: 'Post-workout or between meals',
    price_per_serving: 2.50
  },
  'collagen': {
    name: 'Momentous Collagen Peptides',
    category: 'recovery',
    url: 'https://www.livemomentous.com/products/collagen-peptides',
    standard_dose: '15g',
    best_timing: '30-60 minutes before exercise or morning',
    price_per_serving: 1.75
  },
  'ashwagandha': {
    name: 'Momentous Ashwagandha',
    category: 'adaptogens',
    url: 'https://www.livemomentous.com/products/ashwagandha',
    standard_dose: '600mg KSM-66',
    best_timing: 'Evening, with or without food',
    price_per_serving: 0.75
  },
  'tongkat_ali': {
    name: 'Momentous Tongkat Ali',
    category: 'hormonal_support',
    url: 'https://www.livemomentous.com/products/tongkat-ali',
    standard_dose: '400mg',
    best_timing: 'Morning, cycle 5 days on/2 off',
    price_per_serving: 1.25
  },
  'fadogia': {
    name: 'Momentous Fadogia Agrestis',
    category: 'hormonal_support',
    url: 'https://www.livemomentous.com/products/fadogia-agrestis',
    standard_dose: '600mg',
    best_timing: 'Morning, cycle 8-12 weeks',
    price_per_serving: 1.00
  },
  'tyrosine': {
    name: 'Momentous Tyrosine',
    category: 'cognitive',
    url: 'https://www.livemomentous.com/products/tyrosine',
    standard_dose: '500mg',
    best_timing: 'Morning on empty stomach',
    price_per_serving: 0.40
  },
  'alpha_gpc': {
    name: 'Momentous Alpha-GPC',
    category: 'cognitive',
    url: 'https://www.livemomentous.com/products/alpha-gpc',
    standard_dose: '300mg',
    best_timing: '30-60 minutes before exercise or cognitive work',
    price_per_serving: 0.65
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function calculateSleepData(readinessEntries: any[]): SleepData {
  const sleepHours = readinessEntries
    .filter(r => r.sleep_hours !== null)
    .map(r => r.sleep_hours as number)

  if (sleepHours.length === 0) {
    return { avg_sleep_hours: 0, avg_sleep_quality: null, days_below_7_hours: 0 }
  }

  return {
    avg_sleep_hours: sleepHours.reduce((a, b) => a + b, 0) / sleepHours.length,
    avg_sleep_quality: null, // Could be calculated from readiness if tracked
    days_below_7_hours: sleepHours.filter(h => h < 7).length
  }
}

function calculateRecoveryData(readinessEntries: any[]): RecoveryData {
  const readinessScores = readinessEntries.filter(r => r.readiness_score !== null)
  const sorenessLevels = readinessEntries.filter(r => r.soreness_level !== null)
  const energyLevels = readinessEntries.filter(r => r.energy_level !== null)
  const stressLevels = readinessEntries.filter(r => r.stress_level !== null)

  return {
    avg_readiness: readinessScores.length > 0
      ? readinessScores.reduce((sum, r) => sum + r.readiness_score, 0) / readinessScores.length
      : 70,
    avg_soreness: sorenessLevels.length > 0
      ? sorenessLevels.reduce((sum, r) => sum + r.soreness_level, 0) / sorenessLevels.length
      : 3,
    avg_energy: energyLevels.length > 0
      ? energyLevels.reduce((sum, r) => sum + r.energy_level, 0) / energyLevels.length
      : 5,
    avg_stress: stressLevels.length > 0
      ? stressLevels.reduce((sum, r) => sum + r.stress_level, 0) / stressLevels.length
      : 4
  }
}

function buildTimingSchedule(recommendations: SupplementRecommendation[]): TimingSchedule {
  const schedule: TimingSchedule = {
    morning: [],
    pre_workout: [],
    post_workout: [],
    evening: [],
    with_meals: []
  }

  for (const rec of recommendations) {
    const timing: SupplementTiming = {
      name: rec.name,
      dosage: rec.dosage,
      notes: rec.rationale.substring(0, 100)
    }

    const timingLower = rec.timing.toLowerCase()
    if (timingLower.includes('morning') || timingLower.includes('am')) {
      schedule.morning.push(timing)
    } else if (timingLower.includes('pre-workout') || timingLower.includes('before exercise')) {
      schedule.pre_workout.push(timing)
    } else if (timingLower.includes('post-workout') || timingLower.includes('after exercise')) {
      schedule.post_workout.push(timing)
    } else if (timingLower.includes('evening') || timingLower.includes('bed') || timingLower.includes('night')) {
      schedule.evening.push(timing)
    } else if (timingLower.includes('meal') || timingLower.includes('food')) {
      schedule.with_meals.push(timing)
    } else {
      // Default to morning for unspecified
      schedule.morning.push(timing)
    }
  }

  return schedule
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { patient_id } = await req.json() as SupplementRecommendationRequest

    // Validate required fields
    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate UUID format
    if (!isValidUUID(patient_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid patient_id format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[ai-supplement-recommendation] Processing request for patient ${patient_id}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // CHECK FOR CACHED RECOMMENDATION (7 day cache - supplements don't change often)
    // ========================================================================
    const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
    const { data: cachedRecommendation } = await supabaseClient
      .from('supplement_recommendations')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('created_at', sevenDaysAgo)
      .order('created_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (cachedRecommendation) {
      console.log('[ai-supplement-recommendation] Returning cached recommendation')
      return new Response(
        JSON.stringify({
          recommendation_id: cachedRecommendation.id,
          recommendations: cachedRecommendation.recommendations,
          stack_summary: cachedRecommendation.stack_summary,
          total_daily_cost_estimate: cachedRecommendation.total_daily_cost_estimate,
          goal_coverage: cachedRecommendation.goal_coverage,
          interaction_warnings: cachedRecommendation.interaction_warnings,
          timing_schedule: cachedRecommendation.timing_schedule,
          disclaimer: cachedRecommendation.disclaimer,
          cached: true
        } as SupplementRecommendationResponse),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // GATHER PATIENT DATA
    // ========================================================================

    // 1. Get patient goals
    const { data: goalsData } = await supabaseClient
      .from('patient_goals')
      .select('id, category, title, target_date, status')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(10)

    const patientGoals: PatientGoal[] = goalsData || []

    // 2. Get recent lab results with biomarkers
    const { data: labResultsData } = await supabaseClient
      .from('lab_results')
      .select(`
        id,
        test_date,
        biomarker_values (
          biomarker_type,
          value,
          unit,
          is_flagged
        )
      `)
      .eq('patient_id', patient_id)
      .order('test_date', { ascending: false })
      .limit(1)

    const recentLabResult: LabResult | null = labResultsData && labResultsData.length > 0
      ? {
          test_date: (labResultsData[0] as any).test_date,
          biomarkers: (labResultsData[0] as any).biomarker_values || []
        }
      : null

    // 3. Get sleep/readiness data (last 14 days)
    const fourteenDaysAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]
    const { data: readinessData } = await supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', fourteenDaysAgo)
      .order('date', { ascending: false })

    const sleepData = calculateSleepData(readinessData || [])
    const recoveryData = calculateRecoveryData(readinessData || [])

    // 4. Get current supplement stack
    const { data: currentStack } = await supabaseClient
      .from('patient_supplement_stacks')
      .select(`
        id,
        dosage,
        dosage_unit,
        frequency,
        timing,
        supplements (
          id,
          name,
          category
        )
      `)
      .eq('patient_id', patient_id)
      .eq('is_active', true)

    // 5. Get available supplements from catalog
    const { data: supplementsCatalog } = await supabaseClient
      .from('supplements')
      .select('*')
      .order('evidence_rating', { ascending: false })

    // ========================================================================
    // BUILD AI PROMPT
    // ========================================================================
    const systemPrompt = `You are an expert sports nutrition and supplement advisor, similar to Dr. Andrew Huberman's approach. You recommend evidence-based supplements for performance, recovery, sleep, and longevity.

CRITICAL RULES:
1. Only recommend supplements with strong scientific evidence (rating 3+ out of 5)
2. Consider potential interactions and contraindications
3. Prioritize foundational supplements before specialized ones
4. Recommend Momentous products when available (premium, Huberman-endorsed)
5. Always consider the patient's specific goals, lab results, and recovery metrics
6. Provide specific dosing and timing recommendations
7. Include warnings for any supplements that require caution

EVIDENCE RATING SCALE:
5 = Strong evidence (multiple RCTs, meta-analyses)
4 = Good evidence (several RCTs)
3 = Moderate evidence (some RCTs, strong mechanistic rationale)
2 = Limited evidence (preliminary studies only)
1 = Minimal evidence (theoretical or anecdotal)

FOUNDATIONAL SUPPLEMENTS (Most people benefit):
- Vitamin D3 (5000 IU/day if levels unknown or <50 ng/mL)
- Omega-3 (2g EPA/DHA daily)
- Magnesium (200-400mg, preferably L-threonate for sleep/cognitive)
- Creatine (5g daily - most researched performance supplement)

GOAL-SPECIFIC CONSIDERATIONS:
- Muscle building: Creatine, protein, potentially tongkat ali
- Fat loss: Foundationals only, no magic pills
- Sleep: Magnesium L-threonate, apigenin, theanine (avoid melatonin long-term)
- Cognitive: Alpha-GPC, tyrosine, omega-3
- Testosterone optimization: Tongkat ali, fadogia (with caution), vitamin D, zinc
- Recovery: Collagen, omega-3, magnesium
- Stress/cortisol: Ashwagandha (KSM-66)`

    const userPrompt = `PATIENT PROFILE:

ACTIVE GOALS:
${patientGoals.length > 0
  ? patientGoals.map(g => `- ${g.category}: ${g.title}`).join('\n')
  : '- General health and fitness optimization'}

LAB RESULTS (${recentLabResult ? `Test Date: ${recentLabResult.test_date}` : 'No recent labs'}):
${recentLabResult && recentLabResult.biomarkers.length > 0
  ? recentLabResult.biomarkers.map(b =>
      `- ${b.biomarker_type}: ${b.value} ${b.unit} ${b.is_flagged ? '[FLAGGED]' : ''}`
    ).join('\n')
  : 'No lab data available'}

SLEEP DATA (14-day average):
- Average sleep: ${sleepData.avg_sleep_hours.toFixed(1)} hours
- Days below 7 hours: ${sleepData.days_below_7_hours} of 14

RECOVERY DATA (14-day average):
- Readiness score: ${recoveryData.avg_readiness.toFixed(0)}/100
- Soreness level: ${recoveryData.avg_soreness.toFixed(1)}/10
- Energy level: ${recoveryData.avg_energy.toFixed(1)}/10
- Stress level: ${recoveryData.avg_stress.toFixed(1)}/10

CURRENT SUPPLEMENT STACK:
${currentStack && currentStack.length > 0
  ? currentStack.map((s: any) => `- ${s.supplements.name}: ${s.dosage} ${s.dosage_unit} ${s.timing}`).join('\n')
  : 'No current supplements tracked'}

AVAILABLE MOMENTOUS PRODUCTS:
${Object.entries(MOMENTOUS_PRODUCTS).map(([key, prod]) =>
  `- ${prod.name} (${prod.category}): ${prod.standard_dose}, ${prod.best_timing}`
).join('\n')}

TASK: Create a personalized supplement stack recommendation.

Respond with valid JSON ONLY:
{
  "stack_summary": "2-3 sentence summary of the recommended stack and rationale",
  "recommendations": [
    {
      "supplement_key": "momentous_product_key or 'custom'",
      "custom_name": "name if custom",
      "priority": "essential" | "recommended" | "optional",
      "rationale": "Why this supplement for this patient",
      "goal_alignment": ["goal1", "goal2"],
      "dosage_adjustment": "any modification from standard dose",
      "timing_notes": "specific timing for this patient",
      "warnings": ["any warnings or contraindications"]
    }
  ],
  "interaction_warnings": ["any supplement-supplement or supplement-condition interactions"],
  "goal_coverage": {
    "goal_name": ["supplement1", "supplement2"]
  }
}`

    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[ai-supplement-recommendation] Calling Anthropic Claude API...')

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
        temperature: 0.4,
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[ai-supplement-recommendation] Anthropic API error:', anthropicResponse.status, error)
      throw new Error(`Anthropic API error (${anthropicResponse.status}): ${error.substring(0, 200)}`)
    }

    const completion = await anthropicResponse.json()
    const responseText = completion.content?.[0]?.text

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[ai-supplement-recommendation] Received response from Claude')

    // Parse AI response
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[ai-supplement-recommendation] Failed to parse AI response:', responseText)
      throw new Error('Failed to parse AI response as JSON')
    }

    // ========================================================================
    // BUILD FINAL RECOMMENDATIONS
    // ========================================================================
    let totalDailyCost = 0
    const finalRecommendations: SupplementRecommendation[] = []

    for (const rec of aiResponse.recommendations || []) {
      const momentousProduct = MOMENTOUS_PRODUCTS[rec.supplement_key]

      // Find matching supplement in catalog for ID
      const catalogMatch = supplementsCatalog?.find(
        (s: Supplement) => s.name.toLowerCase().includes(rec.custom_name?.toLowerCase() || rec.supplement_key)
      )

      const recommendation: SupplementRecommendation = {
        supplement_id: catalogMatch?.id || null,
        name: momentousProduct?.name || rec.custom_name || rec.supplement_key,
        brand: momentousProduct ? 'Momentous' : 'Generic',
        category: momentousProduct?.category || catalogMatch?.category || 'general',
        dosage: rec.dosage_adjustment || momentousProduct?.standard_dose || 'As directed',
        timing: rec.timing_notes || momentousProduct?.best_timing || 'As directed',
        evidence_rating: catalogMatch?.evidence_rating || 4,
        rationale: rec.rationale,
        goal_alignment: rec.goal_alignment || [],
        purchase_url: momentousProduct?.url || null,
        priority: rec.priority || 'recommended',
        warnings: rec.warnings || []
      }

      finalRecommendations.push(recommendation)

      if (momentousProduct) {
        totalDailyCost += momentousProduct.price_per_serving
      }
    }

    const timingSchedule = buildTimingSchedule(finalRecommendations)

    const disclaimer = `SUPPLEMENT DISCLAIMER: These recommendations are for informational purposes only and are not intended to diagnose, treat, cure, or prevent any disease. Always consult with a qualified healthcare provider before starting any supplement regimen, especially if you have medical conditions, take medications, or are pregnant/nursing. Supplement quality varies significantly - we recommend pharmaceutical-grade products like Momentous. Individual responses to supplements vary, and what works for one person may not work for another.`

    const response: SupplementRecommendationResponse = {
      recommendation_id: crypto.randomUUID(),
      recommendations: finalRecommendations,
      stack_summary: aiResponse.stack_summary || 'Personalized supplement recommendations based on your goals and data.',
      total_daily_cost_estimate: `$${totalDailyCost.toFixed(2)}/day`,
      goal_coverage: aiResponse.goal_coverage || {},
      interaction_warnings: aiResponse.interaction_warnings || [],
      timing_schedule: timingSchedule,
      disclaimer,
      cached: false
    }

    // ========================================================================
    // SAVE RECOMMENDATION TO DATABASE
    // ========================================================================
    const { data: savedRecommendation, error: saveError } = await supabaseClient
      .from('supplement_recommendations')
      .insert({
        patient_id,
        recommendations: response.recommendations,
        stack_summary: response.stack_summary,
        total_daily_cost_estimate: response.total_daily_cost_estimate,
        goal_coverage: response.goal_coverage,
        interaction_warnings: response.interaction_warnings,
        timing_schedule: response.timing_schedule,
        disclaimer: response.disclaimer
      })
      .select()
      .single()

    if (saveError) {
      console.error('[ai-supplement-recommendation] Error saving recommendation:', saveError)
      // Continue without saving
    } else if (savedRecommendation) {
      response.recommendation_id = savedRecommendation.id
      console.log(`[ai-supplement-recommendation] Recommendation saved: ${savedRecommendation.id}`)
    }

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[ai-supplement-recommendation] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        disclaimer: 'Supplement recommendations could not be generated. Please consult a healthcare provider.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
