// ============================================================================
// Fasting Workout Optimizer Edge Function
// Health Intelligence Platform - Fasted Training Intelligence
// ============================================================================
// Analyzes patient's current fasting state and provides workout modifications
// based on fasting duration, training goals, and physiological considerations.
//
// Rules:
// - >16h fasted + hypertrophy goal = reduce volume 20-30%
// - Fat loss goal = allow fasted cardio up to 45 min
// - >20h fasted = recommend breaking fast or very light activity only
// - Fasted HIIT: limit to 20 min
// - Always consider electrolytes and hydration
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

interface FastingWorkoutOptimizerRequest {
  patient_id: string
  workout_id: string
}

interface FastingState {
  is_fasting: boolean
  started_at: string | null
  fasting_hours: number
  protocol_type: string | null
  planned_hours: number | null
}

interface WorkoutModification {
  type: 'volume' | 'intensity' | 'duration' | 'exercise_swap' | 'timing'
  original_value: string
  modified_value: string
  rationale: string
}

interface NutritionTiming {
  recommendation: string
  pre_workout: string | null
  intra_workout: string | null
  post_workout: string
  timing_notes: string
}

interface FastingWorkoutOptimizerResponse {
  optimization_id: string
  fasting_state: FastingState
  workout_allowed: boolean
  workout_recommended: boolean
  modifications: WorkoutModification[]
  nutrition_timing: NutritionTiming
  safety_warnings: string[]
  performance_notes: string[]
  electrolyte_recommendations: string[]
  alternative_workout_suggestion: string | null
  disclaimer: string
}

interface PatientGoal {
  category: string
  title: string
}

interface WorkoutTemplate {
  id: string
  name: string
  category: string | null
  difficulty: string | null
  duration_minutes: number | null
  exercises: any
}

interface FastingLog {
  id: string
  started_at: string
  ended_at: string | null
  planned_hours: number
  actual_hours: number | null
  protocol_type: string | null
  completed: boolean
}

// ============================================================================
// FASTING RULES ENGINE
// ============================================================================

interface FastingRule {
  min_hours: number
  max_hours: number
  goal_type: string | null
  workout_type: string | null
  modifications: Partial<WorkoutModification>[]
  allowed: boolean
  warnings: string[]
}

const FASTING_RULES: FastingRule[] = [
  // 0-12 hours: Normal fed state, no modifications needed
  {
    min_hours: 0,
    max_hours: 12,
    goal_type: null,
    workout_type: null,
    modifications: [],
    allowed: true,
    warnings: []
  },

  // 12-16 hours: Light fasted state
  {
    min_hours: 12,
    max_hours: 16,
    goal_type: null,
    workout_type: null,
    modifications: [
      {
        type: 'intensity',
        rationale: 'Light fasting state - consider slightly lower peak intensity'
      }
    ],
    allowed: true,
    warnings: ['Stay hydrated with electrolytes']
  },

  // 16-20 hours + Hypertrophy: Reduce volume
  {
    min_hours: 16,
    max_hours: 20,
    goal_type: 'hypertrophy',
    workout_type: 'strength',
    modifications: [
      {
        type: 'volume',
        rationale: 'Extended fast reduces muscle protein synthesis response. Reduce sets by 20-30% to maintain quality while minimizing muscle protein breakdown.'
      },
      {
        type: 'intensity',
        rationale: 'Keep intensity (weight) high but reduce total volume. Quality > quantity when fasted.'
      }
    ],
    allowed: true,
    warnings: [
      'Glycogen stores are depleted - expect reduced performance on later sets',
      'Consider BCAAs or EAAs intra-workout if strict fast is not required',
      'Break fast within 1-2 hours post-workout for optimal muscle protein synthesis'
    ]
  },

  // 16-20 hours + Fat Loss: Allow cardio
  {
    min_hours: 16,
    max_hours: 20,
    goal_type: 'fat_loss',
    workout_type: 'cardio',
    modifications: [
      {
        type: 'duration',
        original_value: '60 min',
        modified_value: '45 min max',
        rationale: 'Fasted cardio is effective for fat oxidation, but limit duration to prevent excessive cortisol and muscle breakdown.'
      },
      {
        type: 'intensity',
        rationale: 'Keep heart rate in Zone 2 (60-70% max HR) for optimal fat oxidation without excessive stress.'
      }
    ],
    allowed: true,
    warnings: [
      'Fasted cardio increases fat oxidation but also cortisol - limit to 45 minutes',
      'Avoid high intensity intervals when fasted this long',
      'Have a protein-rich meal ready for post-workout'
    ]
  },

  // 16-20 hours + HIIT: Limit duration
  {
    min_hours: 16,
    max_hours: 20,
    goal_type: null,
    workout_type: 'hiit',
    modifications: [
      {
        type: 'duration',
        original_value: '30+ min',
        modified_value: '20 min max',
        rationale: 'HIIT is highly glycolytic - depleted glycogen makes this very stressful. Short HIIT is acceptable, extended is not recommended.'
      },
      {
        type: 'intensity',
        rationale: 'Reduce work intervals or increase rest periods by 25%.'
      }
    ],
    allowed: true,
    warnings: [
      'Glycogen-dependent exercise suffers significantly when fasted',
      'Watch for dizziness or lightheadedness',
      'Consider breaking fast or doing Zone 2 cardio instead'
    ]
  },

  // 20-24 hours: Extended fast - very light activity only
  {
    min_hours: 20,
    max_hours: 24,
    goal_type: null,
    workout_type: null,
    modifications: [
      {
        type: 'exercise_swap',
        rationale: 'Extended fasting significantly impairs high-intensity performance. Recommend mobility, yoga, or walking only.'
      },
      {
        type: 'duration',
        original_value: 'As planned',
        modified_value: '30 min max light activity',
        rationale: 'Minimize metabolic stress during extended fast to preserve lean mass.'
      }
    ],
    allowed: true,
    warnings: [
      'Extended fasting impairs strength and power output by 15-25%',
      'High cortisol during extended fast + intense exercise = muscle breakdown',
      'Consider breaking fast before any intense exercise',
      'Walking, stretching, and mobility work are ideal'
    ]
  },

  // 24+ hours: Very extended fast - breaking fast recommended
  {
    min_hours: 24,
    max_hours: 168,
    goal_type: null,
    workout_type: null,
    modifications: [
      {
        type: 'timing',
        rationale: 'Very extended fasting is not compatible with intense training. Break fast before workout or limit to very light walking.'
      }
    ],
    allowed: false,
    warnings: [
      'Extended fasting (24+ hours) + intense exercise is not recommended',
      'Risk of hypoglycemia, excessive muscle breakdown, and injury',
      'If continuing fast for health reasons, limit to gentle walking only',
      'Break fast with protein and carbs 2-3 hours before any planned intense workout'
    ]
  }
]

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function calculateFastingHours(startedAt: string): number {
  const start = new Date(startedAt)
  const now = new Date()
  const diffMs = now.getTime() - start.getTime()
  return diffMs / (1000 * 60 * 60)
}

function determineWorkoutType(workout: WorkoutTemplate): string {
  const name = workout.name?.toLowerCase() || ''
  const category = workout.category?.toLowerCase() || ''

  if (name.includes('hiit') || name.includes('interval') || name.includes('tabata')) {
    return 'hiit'
  }
  if (name.includes('cardio') || name.includes('run') || name.includes('cycling') || name.includes('swim')) {
    return 'cardio'
  }
  if (name.includes('yoga') || name.includes('mobility') || name.includes('stretch')) {
    return 'mobility'
  }
  if (category.includes('strength') || category.includes('lift') || name.includes('strength')) {
    return 'strength'
  }

  return 'general'
}

function determineGoalType(goals: PatientGoal[]): string | null {
  for (const goal of goals) {
    const category = goal.category.toLowerCase()
    const title = goal.title.toLowerCase()

    if (category.includes('muscle') || title.includes('muscle') || title.includes('hypertrophy') || title.includes('mass')) {
      return 'hypertrophy'
    }
    if (category.includes('fat') || title.includes('fat loss') || title.includes('weight loss') || title.includes('lean')) {
      return 'fat_loss'
    }
    if (category.includes('strength') || title.includes('strength') || title.includes('power')) {
      return 'strength'
    }
    if (category.includes('endurance') || title.includes('endurance') || title.includes('cardio')) {
      return 'endurance'
    }
  }

  return null
}

function getApplicableRules(
  fastingHours: number,
  goalType: string | null,
  workoutType: string
): FastingRule[] {
  return FASTING_RULES.filter(rule => {
    // Check fasting duration range
    if (fastingHours < rule.min_hours || fastingHours >= rule.max_hours) {
      return false
    }

    // Check goal type match (null means applies to all)
    if (rule.goal_type !== null && rule.goal_type !== goalType) {
      return false
    }

    // Check workout type match (null means applies to all)
    if (rule.workout_type !== null && rule.workout_type !== workoutType) {
      return false
    }

    return true
  })
}

function buildNutritionTiming(fastingHours: number, workoutType: string): NutritionTiming {
  if (fastingHours < 12) {
    return {
      recommendation: 'Normal fed state - follow standard pre/post workout nutrition.',
      pre_workout: 'Light carbs + protein 1-2 hours before if desired',
      intra_workout: 'Water or electrolytes as needed',
      post_workout: 'Protein + carbs within 2 hours',
      timing_notes: 'No special timing needed in fed state.'
    }
  }

  if (fastingHours < 16) {
    return {
      recommendation: 'Light fasted state - consider breaking fast post-workout.',
      pre_workout: null,
      intra_workout: 'Electrolytes (sodium, potassium, magnesium) strongly recommended',
      post_workout: 'Break fast with 30-40g protein + moderate carbs within 30 minutes',
      timing_notes: 'Post-workout is an excellent time to break your fast - enhanced nutrient partitioning.'
    }
  }

  if (fastingHours < 20) {
    return {
      recommendation: 'Extended fasted state - plan your fast-breaking meal carefully.',
      pre_workout: 'Consider BCAAs or EAAs (5-10g) if muscle preservation is priority',
      intra_workout: 'Essential: Electrolytes with sodium (1000mg+), potassium, magnesium',
      post_workout: 'Break fast immediately with protein shake (40g) + simple carbs, then full meal in 1-2 hours',
      timing_notes: 'The post-workout window becomes crucial after extended fasting. Prioritize fast-digesting protein.'
    }
  }

  return {
    recommendation: 'Very extended fast - strongly recommend breaking fast before intense exercise.',
    pre_workout: 'Recommended: Break fast 2-3 hours before with light protein + carbs',
    intra_workout: 'If fasting continues: electrolytes essential, watch for hypoglycemia symptoms',
    post_workout: 'If continuing fast: very light activity only. Otherwise: full balanced meal.',
    timing_notes: 'Extended fasting + intense exercise is not recommended. If you must train, eat first or limit to gentle movement.'
  }
}

function getElectrolyteRecommendations(fastingHours: number): string[] {
  if (fastingHours < 12) {
    return ['Standard hydration with water is sufficient']
  }

  if (fastingHours < 16) {
    return [
      'Add electrolytes to water: sodium (500-1000mg), potassium, magnesium',
      'Consider LMNT, Nuun, or DIY electrolyte mix',
      'Avoid sugary sports drinks if maintaining fast'
    ]
  }

  return [
    'Electrolytes are essential: sodium (1000-2000mg), potassium (500-1000mg), magnesium (200-400mg)',
    'Use sugar-free electrolyte supplements',
    'Consider salt tablets or LMNT packets',
    'Watch for signs of electrolyte imbalance: cramping, dizziness, heart palpitations',
    'If symptoms occur, break fast immediately with salted food'
  ]
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
    const { patient_id, workout_id } = await req.json() as FastingWorkoutOptimizerRequest

    // Validate required fields
    if (!patient_id || !workout_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id and workout_id are required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate UUID formats
    if (!isValidUUID(patient_id) || !isValidUUID(workout_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid UUID format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[fasting-workout-optimizer] Processing for patient ${patient_id}, workout ${workout_id}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // FETCH CURRENT FASTING STATE
    // ========================================================================
    const { data: currentFast, error: fastError } = await supabaseClient
      .from('fasting_logs')
      .select('*')
      .eq('patient_id', patient_id)
      .is('ended_at', null)
      .order('started_at', { ascending: false })
      .limit(1)
      .maybeSingle()

    if (fastError) {
      console.error('[fasting-workout-optimizer] Error fetching fasting state:', fastError)
    }

    const fastingLog = currentFast as FastingLog | null
    const fastingHours = fastingLog ? calculateFastingHours(fastingLog.started_at) : 0

    const fastingState: FastingState = {
      is_fasting: !!fastingLog && !fastingLog.ended_at,
      started_at: fastingLog?.started_at || null,
      fasting_hours: Math.round(fastingHours * 10) / 10,
      protocol_type: fastingLog?.protocol_type || null,
      planned_hours: fastingLog?.planned_hours || null
    }

    console.log(`[fasting-workout-optimizer] Fasting state: ${fastingState.is_fasting ? `${fastingState.fasting_hours}h` : 'Not fasting'}`)

    // ========================================================================
    // FETCH WORKOUT DETAILS
    // ========================================================================
    // Try system_workout_templates first, then patient_workout_templates
    let workout: WorkoutTemplate | null = null

    const { data: systemWorkout } = await supabaseClient
      .from('system_workout_templates')
      .select('id, name, category, difficulty, duration_minutes, exercises')
      .eq('id', workout_id)
      .maybeSingle()

    if (systemWorkout) {
      workout = systemWorkout as WorkoutTemplate
    } else {
      const { data: patientWorkout } = await supabaseClient
        .from('patient_workout_templates')
        .select('id, name, category, difficulty, duration_minutes, exercises')
        .eq('id', workout_id)
        .eq('patient_id', patient_id)
        .maybeSingle()

      if (patientWorkout) {
        workout = patientWorkout as WorkoutTemplate
      }
    }

    if (!workout) {
      return new Response(
        JSON.stringify({ error: 'Workout not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // FETCH PATIENT GOALS
    // ========================================================================
    const { data: goalsData } = await supabaseClient
      .from('patient_goals')
      .select('category, title')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(5)

    const patientGoals: PatientGoal[] = goalsData || []
    const goalType = determineGoalType(patientGoals)
    const workoutType = determineWorkoutType(workout)

    console.log(`[fasting-workout-optimizer] Goal type: ${goalType}, Workout type: ${workoutType}`)

    // ========================================================================
    // APPLY FASTING RULES
    // ========================================================================
    const applicableRules = getApplicableRules(fastingHours, goalType, workoutType)

    // Aggregate modifications and warnings from all applicable rules
    const allModifications: WorkoutModification[] = []
    const allWarnings: string[] = []
    let workoutAllowed = true
    let workoutRecommended = true

    for (const rule of applicableRules) {
      // Collect modifications
      for (const mod of rule.modifications) {
        allModifications.push({
          type: mod.type!,
          original_value: mod.original_value || 'As planned',
          modified_value: mod.modified_value || 'See rationale',
          rationale: mod.rationale!
        })
      }

      // Collect warnings
      allWarnings.push(...rule.warnings)

      // Check if workout is allowed
      if (!rule.allowed) {
        workoutAllowed = false
        workoutRecommended = false
      }
    }

    // Additional logic for workout recommendation
    if (fastingHours > 20) {
      workoutRecommended = false
    }

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const nutritionTiming = buildNutritionTiming(fastingHours, workoutType)
    const electrolyteRecs = getElectrolyteRecommendations(fastingHours)

    const performanceNotes: string[] = []
    if (fastingHours >= 12 && fastingHours < 16) {
      performanceNotes.push('Expect 5-10% reduction in peak power output')
      performanceNotes.push('Glycogen stores moderately depleted')
    } else if (fastingHours >= 16 && fastingHours < 20) {
      performanceNotes.push('Expect 10-20% reduction in strength and power')
      performanceNotes.push('Fat oxidation significantly elevated - good for fat loss goals')
      performanceNotes.push('Glycogen substantially depleted - high-rep sets will suffer')
    } else if (fastingHours >= 20) {
      performanceNotes.push('Expect 20-30%+ reduction in all performance metrics')
      performanceNotes.push('Cognitive function may be impaired - focus on safety')
      performanceNotes.push('Muscle protein breakdown elevated - not ideal for muscle building')
    }

    // Alternative workout suggestion for extended fasts
    let alternativeWorkout: string | null = null
    if (fastingHours >= 20 || !workoutRecommended) {
      if (workoutType === 'strength' || workoutType === 'hiit') {
        alternativeWorkout = 'Consider: 20-30 minute walk, gentle yoga/mobility, or break your fast 2-3 hours before training.'
      } else if (workoutType === 'cardio') {
        alternativeWorkout = 'Consider: Zone 2 walking (30 min max), gentle stretching, or break your fast before longer cardio.'
      }
    }

    const disclaimer = `FASTING & EXERCISE DISCLAIMER: Individual responses to fasted exercise vary significantly. These recommendations are general guidelines based on research and should be adapted to your personal experience. If you experience dizziness, extreme fatigue, nausea, or other concerning symptoms, stop exercise immediately and consume food. Always prioritize safety over fasting goals. Consult a healthcare provider before combining extended fasting with intense exercise, especially if you have any medical conditions.`

    const response: FastingWorkoutOptimizerResponse = {
      optimization_id: crypto.randomUUID(),
      fasting_state: fastingState,
      workout_allowed: workoutAllowed,
      workout_recommended: workoutRecommended,
      modifications: allModifications,
      nutrition_timing: nutritionTiming,
      safety_warnings: [...new Set(allWarnings)], // Deduplicate
      performance_notes: performanceNotes,
      electrolyte_recommendations: electrolyteRecs,
      alternative_workout_suggestion: alternativeWorkout,
      disclaimer
    }

    console.log(`[fasting-workout-optimizer] Generated ${allModifications.length} modifications, workout ${workoutAllowed ? 'allowed' : 'not allowed'}`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[fasting-workout-optimizer] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        disclaimer: 'Unable to analyze fasting state. If fasting, please exercise caution and prioritize safety.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
