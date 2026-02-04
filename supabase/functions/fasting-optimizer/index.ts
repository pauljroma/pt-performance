// ============================================================================
// Fasting Optimizer Edge Function
// Health Intelligence Platform - Training-Aligned Fasting Recommendations
// ============================================================================
// Generates day-by-day fasting recommendations aligned with the patient's
// training schedule. Optimizes eating windows around workouts for performance
// and recovery while supporting fasting goals.
//
// Rules:
// - Break fast 2-3 hours before high-intensity workouts
// - Extend fasting windows on rest days
// - Align eating windows with circadian rhythm
// - Adjust for wake/sleep times
// - Consider training type when timing meals
//
// Date: 2026-02-03
// Ticket: ACP-429
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

interface FastingOptimizerRequest {
  patient_id: string
  training_schedule: TrainingDay[]
  preferred_protocol: FastingProtocol
  wake_time: string  // HH:MM format
  sleep_time: string // HH:MM format
  start_date?: string // YYYY-MM-DD format, defaults to today
  days?: number // Number of days to generate, defaults to 7
}

interface TrainingDay {
  date: string // YYYY-MM-DD
  workout_type: 'strength' | 'hiit' | 'cardio' | 'mobility' | 'rest'
  intensity: 'low' | 'moderate' | 'high'
  scheduled_time?: string // HH:MM format
  duration_minutes?: number
}

type FastingProtocol = '16:8' | '18:6' | '20:4' | 'OMAD' | '5:2' | 'custom'

interface DayRecommendation {
  date: string
  day_of_week: string
  is_training_day: boolean
  workout_info: {
    type: string
    intensity: string
    time: string | null
  } | null
  fasting_window: {
    start_time: string
    end_time: string
    duration_hours: number
  }
  eating_window: {
    start_time: string
    end_time: string
    duration_hours: number
    first_meal_recommendation: string
    last_meal_recommendation: string
  }
  meal_timing: {
    pre_workout: string | null
    post_workout: string | null
    optimal_protein_windows: string[]
  }
  rationale: string
  tips: string[]
}

interface FastingOptimizerResponse {
  optimization_id: string
  patient_id: string
  protocol: FastingProtocol
  schedule: DayRecommendation[]
  weekly_summary: {
    total_fasting_hours: number
    average_daily_fast: number
    training_days: number
    rest_days: number
    longest_fast: number
    shortest_fast: number
  }
  general_guidelines: string[]
  warnings: string[]
  disclaimer: string
}

// ============================================================================
// FASTING PROTOCOL CONFIGURATIONS
// ============================================================================

interface ProtocolConfig {
  base_fasting_hours: number
  eating_window_hours: number
  min_fast_hours: number
  max_fast_hours: number
  flexibility: 'strict' | 'moderate' | 'flexible'
}

const PROTOCOL_CONFIGS: Record<FastingProtocol, ProtocolConfig> = {
  '16:8': {
    base_fasting_hours: 16,
    eating_window_hours: 8,
    min_fast_hours: 14,
    max_fast_hours: 18,
    flexibility: 'flexible'
  },
  '18:6': {
    base_fasting_hours: 18,
    eating_window_hours: 6,
    min_fast_hours: 16,
    max_fast_hours: 20,
    flexibility: 'moderate'
  },
  '20:4': {
    base_fasting_hours: 20,
    eating_window_hours: 4,
    min_fast_hours: 18,
    max_fast_hours: 22,
    flexibility: 'moderate'
  },
  'OMAD': {
    base_fasting_hours: 23,
    eating_window_hours: 1,
    min_fast_hours: 22,
    max_fast_hours: 24,
    flexibility: 'strict'
  },
  '5:2': {
    base_fasting_hours: 16, // Normal days
    eating_window_hours: 8,
    min_fast_hours: 14,
    max_fast_hours: 24,
    flexibility: 'flexible'
  },
  'custom': {
    base_fasting_hours: 16,
    eating_window_hours: 8,
    min_fast_hours: 12,
    max_fast_hours: 24,
    flexibility: 'flexible'
  }
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function isValidTimeFormat(time: string): boolean {
  return /^([01]\d|2[0-3]):([0-5]\d)$/.test(time)
}

function isValidDateFormat(date: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(date) && !isNaN(Date.parse(date))
}

function parseTime(timeStr: string): { hours: number; minutes: number } {
  const [hours, minutes] = timeStr.split(':').map(Number)
  return { hours, minutes }
}

function formatTime(hours: number, minutes: number = 0): string {
  const h = ((hours % 24) + 24) % 24
  return `${h.toString().padStart(2, '0')}:${minutes.toString().padStart(2, '0')}`
}

function addHoursToTime(timeStr: string, hoursToAdd: number): string {
  const { hours, minutes } = parseTime(timeStr)
  const newHours = hours + hoursToAdd
  return formatTime(Math.floor(newHours), minutes)
}

function subtractHoursFromTime(timeStr: string, hoursToSubtract: number): string {
  return addHoursToTime(timeStr, -hoursToSubtract)
}

function getHoursBetween(startTime: string, endTime: string): number {
  const start = parseTime(startTime)
  const end = parseTime(endTime)
  let hours = end.hours - start.hours + (end.minutes - start.minutes) / 60
  if (hours < 0) hours += 24
  return hours
}

function getDayOfWeek(dateStr: string): string {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  const date = new Date(dateStr + 'T12:00:00')
  return days[date.getDay()]
}

function addDays(dateStr: string, days: number): string {
  const date = new Date(dateStr + 'T12:00:00')
  date.setDate(date.getDate() + days)
  return date.toISOString().split('T')[0]
}

// ============================================================================
// OPTIMIZATION LOGIC
// ============================================================================

function calculateOptimalEatingWindow(
  trainingDay: TrainingDay | null,
  wakeTime: string,
  sleepTime: string,
  protocolConfig: ProtocolConfig
): { start: string; end: string; duration: number; rationale: string } {
  const awakeHours = getHoursBetween(wakeTime, sleepTime)

  // Default eating window based on protocol
  let eatingWindowHours = protocolConfig.eating_window_hours
  let rationale = ''

  if (!trainingDay || trainingDay.workout_type === 'rest') {
    // REST DAY: Can extend fast, eating window later in day
    const fastExtension = Math.min(2, protocolConfig.max_fast_hours - protocolConfig.base_fasting_hours)
    eatingWindowHours = Math.max(protocolConfig.eating_window_hours - fastExtension, 2)

    // Start eating window later on rest days (more fasting time)
    const startOffset = protocolConfig.base_fasting_hours - (awakeHours - eatingWindowHours - 2)
    const eatingStart = addHoursToTime(wakeTime, Math.max(4, Math.min(startOffset, awakeHours - eatingWindowHours - 1)))
    const eatingEnd = addHoursToTime(eatingStart, eatingWindowHours)

    rationale = `Rest day allows extended fasting. Eating window shortened to ${eatingWindowHours} hours to maximize autophagy benefits.`

    return { start: eatingStart, end: eatingEnd, duration: eatingWindowHours, rationale }
  }

  // TRAINING DAY: Optimize around workout
  const workoutTime = trainingDay.scheduled_time || addHoursToTime(wakeTime, 8) // Default to 8 hours after wake
  const workoutIntensity = trainingDay.intensity
  const workoutType = trainingDay.workout_type

  // High-intensity or strength training: Break fast 2-3 hours before
  if (workoutIntensity === 'high' || workoutType === 'strength' || workoutType === 'hiit') {
    const preWorkoutMealTime = subtractHoursFromTime(workoutTime, 2.5)
    let eatingStart = preWorkoutMealTime
    let eatingEnd = addHoursToTime(eatingStart, eatingWindowHours)

    // Ensure eating window doesn't extend past 2 hours before sleep
    const maxEndTime = subtractHoursFromTime(sleepTime, 2)
    if (getHoursBetween(eatingEnd, maxEndTime) < 0) {
      eatingEnd = maxEndTime
      eatingStart = subtractHoursFromTime(eatingEnd, eatingWindowHours)
    }

    rationale = `High-intensity ${workoutType} at ${workoutTime}. Eating window starts ${preWorkoutMealTime} to ensure pre-workout nutrition. Post-workout meal critical for recovery.`

    return { start: eatingStart, end: eatingEnd, duration: eatingWindowHours, rationale }
  }

  // Moderate intensity: More flexibility, prefer fasted if morning
  if (workoutIntensity === 'moderate') {
    const workoutHour = parseTime(workoutTime).hours
    const wakeHour = parseTime(wakeTime).hours

    if (workoutHour - wakeHour <= 4) {
      // Morning workout: Can do fasted cardio, break fast after
      const eatingStart = addHoursToTime(workoutTime, 0.5) // 30 min after workout
      const eatingEnd = addHoursToTime(eatingStart, eatingWindowHours)

      rationale = `Morning moderate ${workoutType}. Fasted training enhances fat oxidation. Break fast immediately post-workout for recovery.`

      return { start: eatingStart, end: eatingEnd, duration: eatingWindowHours, rationale }
    } else {
      // Later workout: Similar to high intensity
      const preWorkoutMealTime = subtractHoursFromTime(workoutTime, 2)
      const eatingEnd = addHoursToTime(preWorkoutMealTime, eatingWindowHours)

      rationale = `Afternoon ${workoutType}. Pre-workout meal 2 hours before for sustained energy.`

      return { start: preWorkoutMealTime, end: eatingEnd, duration: eatingWindowHours, rationale }
    }
  }

  // Low intensity / mobility: Maximum flexibility
  const eatingStart = addHoursToTime(wakeTime, protocolConfig.base_fasting_hours - (24 - awakeHours))
  const eatingEnd = addHoursToTime(eatingStart, eatingWindowHours)

  rationale = `Low-intensity ${workoutType} - can be done fasted or fed. Standard eating window optimized for circadian rhythm.`

  return { start: eatingStart, end: eatingEnd, duration: eatingWindowHours, rationale }
}

function generateMealTiming(
  trainingDay: TrainingDay | null,
  eatingWindowStart: string,
  eatingWindowEnd: string
): DayRecommendation['meal_timing'] {
  const proteinWindows: string[] = []

  // First protein window: Start of eating window
  proteinWindows.push(eatingWindowStart)

  // If eating window is 6+ hours, add middle protein window
  const windowDuration = getHoursBetween(eatingWindowStart, eatingWindowEnd)
  if (windowDuration >= 6) {
    proteinWindows.push(addHoursToTime(eatingWindowStart, windowDuration / 2))
  }

  // Last protein window before bed
  proteinWindows.push(subtractHoursFromTime(eatingWindowEnd, 0.5))

  if (!trainingDay || trainingDay.workout_type === 'rest') {
    return {
      pre_workout: null,
      post_workout: null,
      optimal_protein_windows: proteinWindows
    }
  }

  const workoutTime = trainingDay.scheduled_time || addHoursToTime(eatingWindowStart, 2)
  const preWorkout = subtractHoursFromTime(workoutTime, 2)
  const postWorkout = addHoursToTime(workoutTime, 0.5)

  // Check if pre-workout falls within eating window
  const preWorkoutInWindow = getHoursBetween(eatingWindowStart, preWorkout) >= 0 &&
                              getHoursBetween(preWorkout, eatingWindowEnd) >= 0

  return {
    pre_workout: preWorkoutInWindow ? `${preWorkout} - Eat 2 hours before workout` : `${eatingWindowStart} - First meal as close to workout as possible`,
    post_workout: `${postWorkout} - High protein meal within 30-60 minutes post-workout`,
    optimal_protein_windows: proteinWindows
  }
}

function generateTips(
  trainingDay: TrainingDay | null,
  fastingHours: number,
  protocol: FastingProtocol
): string[] {
  const tips: string[] = []

  // General fasting tips
  if (fastingHours >= 16) {
    tips.push('Stay hydrated with water, black coffee, or plain tea during the fast')
    tips.push('Electrolytes (sodium, potassium, magnesium) help maintain energy while fasting')
  }

  if (fastingHours >= 18) {
    tips.push('Listen to your body - it\'s okay to adjust if you feel lightheaded')
  }

  if (!trainingDay || trainingDay.workout_type === 'rest') {
    tips.push('Rest days are ideal for longer fasts - autophagy benefits peak around 18-24 hours')
    tips.push('Consider light walking or mobility work during extended fasts')
    return tips
  }

  // Training day tips
  if (trainingDay.workout_type === 'strength' || trainingDay.workout_type === 'hiit') {
    tips.push('Pre-workout meal: Focus on protein (30-40g) and moderate carbs for performance')
    tips.push('Post-workout: Prioritize protein within 1 hour for muscle protein synthesis')
    if (trainingDay.intensity === 'high') {
      tips.push('High-intensity training is not recommended beyond 16-18 hour fasts')
    }
  }

  if (trainingDay.workout_type === 'cardio') {
    tips.push('Fasted cardio can enhance fat oxidation - effective for fat loss goals')
    tips.push('Keep fasted cardio moderate intensity (Zone 2) for best results')
  }

  if (trainingDay.scheduled_time) {
    const hour = parseTime(trainingDay.scheduled_time).hours
    if (hour < 10) {
      tips.push('Morning workouts: Coffee before training can enhance performance while fasted')
    } else if (hour >= 17) {
      tips.push('Evening workouts: Ensure adequate time for post-workout meal before sleep')
    }
  }

  return tips
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
    const requestBody = await req.json() as FastingOptimizerRequest
    const {
      patient_id,
      training_schedule,
      preferred_protocol,
      wake_time,
      sleep_time,
      start_date,
      days = 7
    } = requestBody

    // ========================================================================
    // VALIDATION
    // ========================================================================

    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!isValidUUID(patient_id)) {
      return new Response(
        JSON.stringify({ error: 'Invalid patient_id format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!training_schedule || !Array.isArray(training_schedule)) {
      return new Response(
        JSON.stringify({ error: 'training_schedule array is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!preferred_protocol || !PROTOCOL_CONFIGS[preferred_protocol]) {
      return new Response(
        JSON.stringify({
          error: 'Invalid preferred_protocol',
          valid_protocols: Object.keys(PROTOCOL_CONFIGS)
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!wake_time || !isValidTimeFormat(wake_time)) {
      return new Response(
        JSON.stringify({ error: 'wake_time is required in HH:MM format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!sleep_time || !isValidTimeFormat(sleep_time)) {
      return new Response(
        JSON.stringify({ error: 'sleep_time is required in HH:MM format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (days < 1 || days > 30) {
      return new Response(
        JSON.stringify({ error: 'days must be between 1 and 30' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const effectiveStartDate = start_date || new Date().toISOString().split('T')[0]
    if (!isValidDateFormat(effectiveStartDate)) {
      return new Response(
        JSON.stringify({ error: 'Invalid start_date format (use YYYY-MM-DD)' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[fasting-optimizer] Generating ${days}-day schedule for patient ${patient_id}, protocol: ${preferred_protocol}`)

    // ========================================================================
    // INITIALIZE SUPABASE CLIENT (for potential future data lookup)
    // ========================================================================
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Validate patient exists
    const { data: patient, error: patientError } = await supabaseClient
      .from('patients')
      .select('id')
      .eq('id', patient_id)
      .maybeSingle()

    if (patientError || !patient) {
      return new Response(
        JSON.stringify({ error: 'Patient not found' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // ========================================================================
    // BUILD TRAINING SCHEDULE MAP
    // ========================================================================
    const trainingMap = new Map<string, TrainingDay>()
    for (const day of training_schedule) {
      if (day.date && isValidDateFormat(day.date)) {
        trainingMap.set(day.date, day)
      }
    }

    // ========================================================================
    // GENERATE DAILY RECOMMENDATIONS
    // ========================================================================
    const protocolConfig = PROTOCOL_CONFIGS[preferred_protocol]
    const schedule: DayRecommendation[] = []
    let totalFastingHours = 0
    let trainingDays = 0
    let restDays = 0

    for (let i = 0; i < days; i++) {
      const currentDate = addDays(effectiveStartDate, i)
      const dayOfWeek = getDayOfWeek(currentDate)
      const trainingDay = trainingMap.get(currentDate) || null
      const isTrainingDay = trainingDay !== null && trainingDay.workout_type !== 'rest'

      if (isTrainingDay) {
        trainingDays++
      } else {
        restDays++
      }

      // Calculate optimal eating window
      const eatingWindow = calculateOptimalEatingWindow(
        trainingDay,
        wake_time,
        sleep_time,
        protocolConfig
      )

      // Calculate fasting window (inverse of eating window)
      const fastingStart = eatingWindow.end
      const fastingEnd = eatingWindow.start
      const fastingDuration = 24 - eatingWindow.duration
      totalFastingHours += fastingDuration

      // Generate meal timing
      const mealTiming = generateMealTiming(trainingDay, eatingWindow.start, eatingWindow.end)

      // Generate tips
      const tips = generateTips(trainingDay, fastingDuration, preferred_protocol)

      // Build first/last meal recommendations
      const firstMealRec = isTrainingDay
        ? 'Protein-rich meal (30-40g protein). Add carbs if training soon after.'
        : 'Balanced meal with protein and healthy fats. Lower carb on rest days optional.'

      const lastMealRec = isTrainingDay
        ? 'Include casein or slow-digesting protein. Carbs help with sleep and recovery.'
        : 'Light protein with vegetables. Avoid heavy meals close to bedtime.'

      const dayRecommendation: DayRecommendation = {
        date: currentDate,
        day_of_week: dayOfWeek,
        is_training_day: isTrainingDay,
        workout_info: trainingDay && trainingDay.workout_type !== 'rest' ? {
          type: trainingDay.workout_type,
          intensity: trainingDay.intensity,
          time: trainingDay.scheduled_time || null
        } : null,
        fasting_window: {
          start_time: fastingStart,
          end_time: fastingEnd,
          duration_hours: Math.round(fastingDuration * 10) / 10
        },
        eating_window: {
          start_time: eatingWindow.start,
          end_time: eatingWindow.end,
          duration_hours: Math.round(eatingWindow.duration * 10) / 10,
          first_meal_recommendation: firstMealRec,
          last_meal_recommendation: lastMealRec
        },
        meal_timing: mealTiming,
        rationale: eatingWindow.rationale,
        tips
      }

      schedule.push(dayRecommendation)
    }

    // ========================================================================
    // BUILD WEEKLY SUMMARY
    // ========================================================================
    const fastingDurations = schedule.map(d => d.fasting_window.duration_hours)
    const weeklySummary = {
      total_fasting_hours: Math.round(totalFastingHours * 10) / 10,
      average_daily_fast: Math.round((totalFastingHours / days) * 10) / 10,
      training_days: trainingDays,
      rest_days: restDays,
      longest_fast: Math.max(...fastingDurations),
      shortest_fast: Math.min(...fastingDurations)
    }

    // ========================================================================
    // GENERATE WARNINGS
    // ========================================================================
    const warnings: string[] = []

    if (weeklySummary.average_daily_fast < 14) {
      warnings.push('Average fasting duration is below 14 hours - consider extending fasts for metabolic benefits')
    }

    if (weeklySummary.longest_fast > 20 && trainingDays > 0) {
      warnings.push('Extended fasts (20+ hours) may impair high-intensity training performance')
    }

    const highIntensityFasted = schedule.filter(d =>
      d.is_training_day &&
      d.workout_info?.intensity === 'high' &&
      d.fasting_window.duration_hours >= 18
    )
    if (highIntensityFasted.length > 0) {
      warnings.push(`${highIntensityFasted.length} high-intensity workout(s) scheduled during extended fasts - monitor performance and adjust if needed`)
    }

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const generalGuidelines = [
      `Your ${preferred_protocol} protocol targets ${protocolConfig.base_fasting_hours} hours of fasting daily`,
      'Eating windows are shifted earlier on training days to support workout performance',
      'Rest days have extended fasting windows to maximize autophagy and metabolic benefits',
      'Protein distribution across the eating window optimizes muscle protein synthesis',
      'Stay flexible - adjust by 1-2 hours based on hunger, energy, and performance',
      'Break the fast immediately if experiencing dizziness, extreme fatigue, or weakness'
    ]

    const disclaimer = `FASTING OPTIMIZATION DISCLAIMER: These recommendations are generated algorithmically based on general principles of intermittent fasting and exercise timing. Individual responses vary significantly. This is not medical advice. Consult with a healthcare provider or registered dietitian before starting any fasting protocol, especially if you have diabetes, are pregnant, have a history of eating disorders, or take medications that require food. Listen to your body and adjust as needed.`

    const response: FastingOptimizerResponse = {
      optimization_id: crypto.randomUUID(),
      patient_id,
      protocol: preferred_protocol,
      schedule,
      weekly_summary: weeklySummary,
      general_guidelines: generalGuidelines,
      warnings,
      disclaimer
    }

    console.log(`[fasting-optimizer] Generated ${schedule.length}-day schedule, avg fast: ${weeklySummary.average_daily_fast}h`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[fasting-optimizer] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        disclaimer: 'Unable to generate fasting recommendations. Please try again or consult a healthcare provider.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
