// ============================================================================
// Supplement Timing Optimizer Edge Function
// Health Intelligence Platform - Supplement Schedule Optimization
// ============================================================================
// Analyzes supplements, training schedule, and lifestyle factors to generate
// optimal timing recommendations for each supplement.
//
// Date: 2026-02-03
// Ticket: ACP-437
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// TYPE DEFINITIONS
// ============================================================================

interface Supplement {
  name: string
  dosage?: string
  form?: string // capsule, powder, liquid, etc.
}

interface Meal {
  name: string // breakfast, lunch, dinner, snack
  time: string // HH:MM format
  contains_fat?: boolean
  contains_protein?: boolean
}

interface TimingOptimizerRequest {
  patient_id?: string
  supplements: Supplement[]
  training_time?: string // HH:MM format
  wake_time: string // HH:MM format
  sleep_time: string // HH:MM format
  fasting_window?: {
    start: string // HH:MM format
    end: string // HH:MM format
  }
  meals?: Meal[]
}

interface SupplementSchedule {
  supplement: string
  dosage?: string
  recommended_time: string // HH:MM format
  timing_window: string // e.g., "6:00 AM - 8:00 AM"
  with_food: boolean
  food_notes?: string
  reasoning: string
  priority: 'critical' | 'important' | 'flexible'
  warnings?: string[]
}

interface TimingOptimizerResponse {
  success: boolean
  patient_id?: string
  schedule: SupplementSchedule[]
  daily_summary: {
    morning: string[]
    midday: string[]
    evening: string[]
    bedtime: string[]
  }
  general_notes: string[]
  error?: string
}

// ============================================================================
// SUPPLEMENT TIMING RULES DATABASE
// ============================================================================

interface TimingRule {
  category: 'fat_soluble' | 'water_soluble' | 'mineral' | 'amino_acid' | 'herbal' | 'probiotic' | 'stimulant' | 'other'
  with_food: boolean
  food_type?: 'fat' | 'protein' | 'any' | 'empty_stomach'
  best_time: 'morning' | 'midday' | 'evening' | 'bedtime' | 'pre_workout' | 'post_workout' | 'any'
  avoid_times?: string[]
  conflicts_with?: string[]
  reasoning: string
  priority: 'critical' | 'important' | 'flexible'
}

const SUPPLEMENT_TIMING_RULES: Record<string, TimingRule> = {
  // Fat-Soluble Vitamins
  'vitamin d': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'Fat-soluble vitamin requiring dietary fat for absorption. Morning timing supports natural circadian rhythm and may improve sleep quality.',
    priority: 'critical'
  },
  'vitamin d3': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'Fat-soluble vitamin requiring dietary fat for absorption. Morning timing supports natural circadian rhythm.',
    priority: 'critical'
  },
  'vitamin k2': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'morning',
    reasoning: 'Fat-soluble vitamin that works synergistically with Vitamin D. Take together with breakfast containing fat.',
    priority: 'important'
  },
  'vitamin a': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    reasoning: 'Fat-soluble vitamin requiring dietary fat for absorption.',
    priority: 'important'
  },
  'vitamin e': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    conflicts_with: ['iron'],
    reasoning: 'Fat-soluble antioxidant. Separate from iron supplements by 2+ hours as it may reduce iron absorption.',
    priority: 'important'
  },

  // Water-Soluble Vitamins
  'vitamin c': {
    category: 'water_soluble',
    with_food: false,
    best_time: 'morning',
    conflicts_with: ['vitamin b12'],
    reasoning: 'Water-soluble vitamin that can be taken any time. Morning may provide antioxidant benefits throughout the day. High doses may interfere with B12 absorption.',
    priority: 'flexible'
  },
  'vitamin b12': {
    category: 'water_soluble',
    with_food: false,
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'Supports energy production. Morning timing prevents potential sleep interference.',
    priority: 'important'
  },
  'b complex': {
    category: 'water_soluble',
    with_food: true,
    food_type: 'any',
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'B vitamins support energy metabolism. Take with food to prevent nausea. Avoid evening as they may disrupt sleep.',
    priority: 'important'
  },
  'folate': {
    category: 'water_soluble',
    with_food: false,
    best_time: 'morning',
    reasoning: 'Water-soluble B vitamin. Morning timing aligns with natural metabolic needs.',
    priority: 'flexible'
  },

  // Minerals
  'magnesium': {
    category: 'mineral',
    with_food: true,
    food_type: 'any',
    best_time: 'bedtime',
    conflicts_with: ['calcium', 'zinc'],
    reasoning: 'Promotes relaxation and sleep quality. Take 30-60 minutes before bed. Separate from calcium and zinc by 2+ hours.',
    priority: 'critical'
  },
  'magnesium glycinate': {
    category: 'mineral',
    with_food: true,
    food_type: 'any',
    best_time: 'bedtime',
    conflicts_with: ['calcium', 'zinc'],
    reasoning: 'Glycinate form is calming and well-absorbed. Ideal for evening/bedtime use to support sleep.',
    priority: 'critical'
  },
  'magnesium threonate': {
    category: 'mineral',
    with_food: false,
    best_time: 'bedtime',
    reasoning: 'Crosses blood-brain barrier effectively. Best taken before bed for cognitive and sleep benefits.',
    priority: 'critical'
  },
  'calcium': {
    category: 'mineral',
    with_food: true,
    food_type: 'any',
    best_time: 'evening',
    conflicts_with: ['iron', 'magnesium', 'zinc'],
    reasoning: 'Separate from iron, magnesium, and zinc by 2+ hours due to absorption competition. Evening timing supports bone health.',
    priority: 'important'
  },
  'iron': {
    category: 'mineral',
    with_food: false,
    food_type: 'empty_stomach',
    best_time: 'morning',
    conflicts_with: ['calcium', 'zinc', 'vitamin e'],
    reasoning: 'Best absorbed on empty stomach with vitamin C. Separate from calcium, zinc, and vitamin E by 2+ hours.',
    priority: 'critical'
  },
  'zinc': {
    category: 'mineral',
    with_food: true,
    food_type: 'protein',
    best_time: 'evening',
    conflicts_with: ['calcium', 'iron', 'copper'],
    reasoning: 'Take with protein-containing food to prevent nausea. Separate from copper by 2+ hours. Evening supports immune function and recovery.',
    priority: 'important'
  },
  'copper': {
    category: 'mineral',
    with_food: true,
    food_type: 'any',
    best_time: 'morning',
    conflicts_with: ['zinc'],
    reasoning: 'Separate from zinc by 2+ hours as they compete for absorption.',
    priority: 'important'
  },
  'selenium': {
    category: 'mineral',
    with_food: true,
    food_type: 'any',
    best_time: 'any',
    reasoning: 'Can be taken any time with food. Works synergistically with vitamin E.',
    priority: 'flexible'
  },
  'iodine': {
    category: 'mineral',
    with_food: true,
    food_type: 'any',
    best_time: 'morning',
    reasoning: 'Supports thyroid function. Morning timing aligns with natural hormone production.',
    priority: 'important'
  },

  // Amino Acids & Proteins
  'creatine': {
    category: 'amino_acid',
    with_food: true,
    food_type: 'any',
    best_time: 'post_workout',
    reasoning: 'Timing is flexible for creatine. Post-workout with carbs may slightly enhance uptake. Consistency matters more than timing.',
    priority: 'flexible'
  },
  'collagen': {
    category: 'amino_acid',
    with_food: false,
    food_type: 'empty_stomach',
    best_time: 'morning',
    reasoning: 'Best absorbed on empty stomach or between meals for optimal amino acid uptake.',
    priority: 'important'
  },
  'glutamine': {
    category: 'amino_acid',
    with_food: false,
    best_time: 'post_workout',
    reasoning: 'Supports gut health and recovery. Post-workout or before bed on empty stomach is ideal.',
    priority: 'flexible'
  },
  'bcaa': {
    category: 'amino_acid',
    with_food: false,
    best_time: 'pre_workout',
    reasoning: 'Best taken before or during training for muscle protein synthesis support.',
    priority: 'important'
  },
  'l-theanine': {
    category: 'amino_acid',
    with_food: false,
    best_time: 'any',
    reasoning: 'Can be taken any time. Often paired with caffeine for focus or taken before bed for relaxation.',
    priority: 'flexible'
  },
  'glycine': {
    category: 'amino_acid',
    with_food: false,
    best_time: 'bedtime',
    reasoning: 'Supports sleep quality and collagen synthesis. Best taken 30-60 minutes before bed.',
    priority: 'important'
  },

  // Stimulants
  'caffeine': {
    category: 'stimulant',
    with_food: false,
    best_time: 'morning',
    avoid_times: ['evening', 'bedtime'],
    reasoning: 'Half-life of 5-6 hours. Avoid within 8-10 hours of bedtime to prevent sleep disruption.',
    priority: 'critical'
  },

  // Herbals & Adaptogens
  'ashwagandha': {
    category: 'herbal',
    with_food: true,
    food_type: 'any',
    best_time: 'bedtime',
    reasoning: 'Adaptogen that supports stress response. Evening timing may enhance relaxation and sleep quality.',
    priority: 'important'
  },
  'rhodiola': {
    category: 'herbal',
    with_food: false,
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'Energizing adaptogen. Take in morning on empty stomach for best absorption. Avoid evening use.',
    priority: 'important'
  },
  'ginseng': {
    category: 'herbal',
    with_food: false,
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'Stimulating herb. Morning use provides energy support without sleep interference.',
    priority: 'important'
  },
  'turmeric': {
    category: 'herbal',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    reasoning: 'Curcumin absorption enhanced by fat and black pepper. Take with fatty meal.',
    priority: 'important'
  },
  'curcumin': {
    category: 'herbal',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    reasoning: 'Requires fat and piperine for absorption. Take with meals containing healthy fats.',
    priority: 'important'
  },

  // Probiotics
  'probiotic': {
    category: 'probiotic',
    with_food: false,
    food_type: 'empty_stomach',
    best_time: 'morning',
    reasoning: 'Best taken on empty stomach 30 minutes before breakfast when stomach acid is lowest.',
    priority: 'critical'
  },
  'probiotics': {
    category: 'probiotic',
    with_food: false,
    food_type: 'empty_stomach',
    best_time: 'morning',
    reasoning: 'Best taken on empty stomach 30 minutes before breakfast when stomach acid is lowest.',
    priority: 'critical'
  },

  // Omega Fatty Acids
  'fish oil': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    reasoning: 'Take with fatty meal to enhance absorption and reduce fishy burps.',
    priority: 'important'
  },
  'omega 3': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    reasoning: 'Take with meals containing fat for optimal absorption.',
    priority: 'important'
  },
  'omega-3': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'any',
    reasoning: 'Take with meals containing fat for optimal absorption.',
    priority: 'important'
  },

  // Other Common Supplements
  'coq10': {
    category: 'fat_soluble',
    with_food: true,
    food_type: 'fat',
    best_time: 'morning',
    avoid_times: ['bedtime'],
    reasoning: 'Fat-soluble antioxidant that may increase energy. Morning with fatty food is ideal.',
    priority: 'important'
  },
  'melatonin': {
    category: 'other',
    with_food: false,
    best_time: 'bedtime',
    reasoning: 'Take 30-60 minutes before desired sleep time. Start with lowest effective dose.',
    priority: 'critical'
  },
  'apple cider vinegar': {
    category: 'other',
    with_food: false,
    best_time: 'morning',
    reasoning: 'Best taken before meals to support digestion. Dilute in water.',
    priority: 'flexible'
  },
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function parseTime(timeStr: string): { hours: number; minutes: number } {
  const [hours, minutes] = timeStr.split(':').map(Number)
  return { hours, minutes }
}

function formatTime(hours: number, minutes: number): string {
  const period = hours >= 12 ? 'PM' : 'AM'
  const displayHours = hours > 12 ? hours - 12 : hours === 0 ? 12 : hours
  return `${displayHours}:${minutes.toString().padStart(2, '0')} ${period}`
}

function addMinutes(timeStr: string, minutesToAdd: number): string {
  const { hours, minutes } = parseTime(timeStr)
  const totalMinutes = hours * 60 + minutes + minutesToAdd
  const newHours = Math.floor(totalMinutes / 60) % 24
  const newMinutes = totalMinutes % 60
  return `${newHours.toString().padStart(2, '0')}:${newMinutes.toString().padStart(2, '0')}`
}

function getTimeCategory(timeStr: string, wakeTime: string, sleepTime: string): 'morning' | 'midday' | 'evening' | 'bedtime' {
  const { hours } = parseTime(timeStr)
  const wake = parseTime(wakeTime)
  const sleep = parseTime(sleepTime)

  // Bedtime is 1-2 hours before sleep
  const bedtimeStart = sleep.hours - 2

  if (hours >= wake.hours && hours < wake.hours + 4) return 'morning'
  if (hours >= wake.hours + 4 && hours < 17) return 'midday'
  if (hours >= 17 && hours < bedtimeStart) return 'evening'
  return 'bedtime'
}

function findMealWithFat(meals: Meal[]): Meal | undefined {
  return meals.find(m => m.contains_fat === true) || meals.find(m => m.name.toLowerCase() === 'breakfast')
}

function findMealWithProtein(meals: Meal[]): Meal | undefined {
  return meals.find(m => m.contains_protein === true) || meals.find(m => m.name.toLowerCase() === 'dinner')
}

function normalizeSupplementName(name: string): string {
  return name.toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
}

function findMatchingRule(supplementName: string): TimingRule | undefined {
  const normalized = normalizeSupplementName(supplementName)

  // Direct match
  if (SUPPLEMENT_TIMING_RULES[normalized]) {
    return SUPPLEMENT_TIMING_RULES[normalized]
  }

  // Partial match
  for (const [key, rule] of Object.entries(SUPPLEMENT_TIMING_RULES)) {
    if (normalized.includes(key) || key.includes(normalized)) {
      return rule
    }
  }

  return undefined
}

// ============================================================================
// MAIN OPTIMIZATION LOGIC
// ============================================================================

function optimizeSupplementTiming(request: TimingOptimizerRequest): TimingOptimizerResponse {
  const {
    patient_id,
    supplements,
    training_time,
    wake_time,
    sleep_time,
    fasting_window,
    meals = []
  } = request

  const schedule: SupplementSchedule[] = []
  const warnings: string[] = []
  const dailySummary: TimingOptimizerResponse['daily_summary'] = {
    morning: [],
    midday: [],
    evening: [],
    bedtime: []
  }

  // Calculate key times
  const wakeHours = parseTime(wake_time).hours
  const sleepHours = parseTime(sleep_time).hours
  const caffeineCutoff = sleepHours - 10 // 10 hours before sleep

  // Default meal times if not provided
  const defaultMeals: Meal[] = meals.length > 0 ? meals : [
    { name: 'breakfast', time: addMinutes(wake_time, 60), contains_fat: true, contains_protein: true },
    { name: 'lunch', time: '12:00', contains_fat: true, contains_protein: true },
    { name: 'dinner', time: '18:30', contains_fat: true, contains_protein: true }
  ]

  // Track conflicts
  const scheduledSupplements: { name: string; time: string; conflicts_with?: string[] }[] = []

  for (const supplement of supplements) {
    const rule = findMatchingRule(supplement.name)
    const supplementSchedule: SupplementSchedule = {
      supplement: supplement.name,
      dosage: supplement.dosage,
      recommended_time: '',
      timing_window: '',
      with_food: false,
      reasoning: '',
      priority: 'flexible'
    }

    if (rule) {
      supplementSchedule.with_food = rule.with_food
      supplementSchedule.priority = rule.priority
      supplementSchedule.reasoning = rule.reasoning

      // Determine recommended time based on rule
      let recommendedTime: string
      let timingWindow: string

      switch (rule.best_time) {
        case 'morning':
          if (rule.food_type === 'empty_stomach') {
            recommendedTime = wake_time
            timingWindow = `${formatTime(wakeHours, 0)} - ${formatTime(wakeHours + 1, 0)}`
            supplementSchedule.food_notes = 'Take on empty stomach, 30 minutes before breakfast'
          } else if (rule.with_food) {
            const breakfast = defaultMeals.find(m => m.name.toLowerCase() === 'breakfast')
            recommendedTime = breakfast?.time || addMinutes(wake_time, 60)
            timingWindow = `${formatTime(wakeHours + 1, 0)} - ${formatTime(wakeHours + 2, 0)}`
            if (rule.food_type === 'fat') {
              supplementSchedule.food_notes = 'Take with breakfast containing healthy fats (eggs, avocado, nuts)'
            }
          } else {
            recommendedTime = addMinutes(wake_time, 30)
            timingWindow = `${formatTime(wakeHours, 0)} - ${formatTime(wakeHours + 2, 0)}`
          }
          dailySummary.morning.push(supplement.name)
          break

        case 'midday':
          const lunch = defaultMeals.find(m => m.name.toLowerCase() === 'lunch')
          recommendedTime = lunch?.time || '12:00'
          timingWindow = '11:00 AM - 2:00 PM'
          if (rule.with_food) {
            supplementSchedule.food_notes = 'Take with lunch'
          }
          dailySummary.midday.push(supplement.name)
          break

        case 'evening':
          const dinner = defaultMeals.find(m => m.name.toLowerCase() === 'dinner')
          recommendedTime = dinner?.time || '18:30'
          timingWindow = '5:00 PM - 7:30 PM'
          if (rule.with_food) {
            supplementSchedule.food_notes = 'Take with dinner'
          }
          dailySummary.evening.push(supplement.name)
          break

        case 'bedtime':
          recommendedTime = addMinutes(sleep_time, -60)
          const bedtimeHour = sleepHours - 1
          timingWindow = `${formatTime(bedtimeHour, 0)} - ${formatTime(sleepHours, 0)}`
          supplementSchedule.food_notes = 'Take 30-60 minutes before bed'
          dailySummary.bedtime.push(supplement.name)
          break

        case 'pre_workout':
          if (training_time) {
            recommendedTime = addMinutes(training_time, -30)
            const preHours = parseTime(training_time).hours
            timingWindow = `${formatTime(preHours - 1, 0)} - ${formatTime(preHours, 0)}`
            supplementSchedule.food_notes = 'Take 30-60 minutes before training'
          } else {
            recommendedTime = '09:00'
            timingWindow = '8:00 AM - 10:00 AM'
            supplementSchedule.food_notes = 'Take before physical activity'
          }
          dailySummary.morning.push(supplement.name)
          break

        case 'post_workout':
          if (training_time) {
            recommendedTime = addMinutes(training_time, 60)
            const postHours = parseTime(training_time).hours
            timingWindow = `${formatTime(postHours, 30)} - ${formatTime(postHours + 2, 0)}`
            supplementSchedule.food_notes = 'Take within 30-60 minutes after training'
          } else {
            recommendedTime = '12:00'
            timingWindow = '11:00 AM - 1:00 PM'
            supplementSchedule.food_notes = 'Take after physical activity or with lunch'
          }
          dailySummary.midday.push(supplement.name)
          break

        default:
          // 'any' - default to morning with food
          const anyMeal = findMealWithFat(defaultMeals) || defaultMeals[0]
          recommendedTime = anyMeal?.time || '08:00'
          timingWindow = '7:00 AM - 9:00 AM'
          if (rule.with_food && rule.food_type === 'fat') {
            supplementSchedule.food_notes = 'Take with meal containing healthy fats'
          }
          dailySummary.morning.push(supplement.name)
      }

      supplementSchedule.recommended_time = formatTime(parseTime(recommendedTime).hours, parseTime(recommendedTime).minutes)
      supplementSchedule.timing_window = timingWindow

      // Check for caffeine timing
      if (normalizeSupplementName(supplement.name).includes('caffeine')) {
        const recTime = parseTime(recommendedTime)
        if (recTime.hours >= caffeineCutoff) {
          supplementSchedule.warnings = supplementSchedule.warnings || []
          supplementSchedule.warnings.push(`Caffeine should be avoided after ${formatTime(caffeineCutoff, 0)} to prevent sleep disruption`)
          supplementSchedule.recommended_time = formatTime(Math.min(recTime.hours, caffeineCutoff - 1), 0)
        }
      }

      // Check for fasting window conflicts
      if (fasting_window && rule.with_food) {
        const fastStart = parseTime(fasting_window.start)
        const fastEnd = parseTime(fasting_window.end)
        const recTime = parseTime(recommendedTime)

        // Check if recommended time falls within fasting window
        if (recTime.hours >= fastStart.hours || recTime.hours < fastEnd.hours) {
          supplementSchedule.warnings = supplementSchedule.warnings || []
          supplementSchedule.warnings.push(`Recommended time conflicts with fasting window. Consider taking immediately after breaking fast.`)
        }
      }

      // Check for conflicts with other supplements
      if (rule.conflicts_with) {
        for (const scheduled of scheduledSupplements) {
          const scheduledNormalized = normalizeSupplementName(scheduled.name)
          for (const conflict of rule.conflicts_with) {
            if (scheduledNormalized.includes(conflict)) {
              supplementSchedule.warnings = supplementSchedule.warnings || []
              supplementSchedule.warnings.push(`Separate from ${scheduled.name} by at least 2 hours for optimal absorption`)
            }
          }
        }
      }

      scheduledSupplements.push({
        name: supplement.name,
        time: recommendedTime,
        conflicts_with: rule.conflicts_with
      })

    } else {
      // No specific rule found - use general guidelines
      supplementSchedule.recommended_time = formatTime(wakeHours + 1, 0)
      supplementSchedule.timing_window = `${formatTime(wakeHours + 1, 0)} - ${formatTime(wakeHours + 2, 0)}`
      supplementSchedule.with_food = true
      supplementSchedule.food_notes = 'Take with breakfast (general recommendation)'
      supplementSchedule.reasoning = 'No specific timing data available. General recommendation is to take with morning meal for consistency.'
      supplementSchedule.priority = 'flexible'
      dailySummary.morning.push(supplement.name)
    }

    schedule.push(supplementSchedule)
  }

  // Generate general notes
  const generalNotes: string[] = []

  if (schedule.some(s => s.with_food && s.food_notes?.includes('fat'))) {
    generalNotes.push('Ensure breakfast includes healthy fats (eggs, avocado, olive oil, nuts) for fat-soluble vitamin absorption.')
  }

  if (schedule.some(s => normalizeSupplementName(s.supplement).includes('iron'))) {
    generalNotes.push('Iron is best absorbed with vitamin C. Consider taking with citrus juice or vitamin C supplement.')
  }

  if (schedule.some(s => normalizeSupplementName(s.supplement).includes('magnesium'))) {
    generalNotes.push('Magnesium supports sleep quality. Maintain consistent bedtime dosing for best results.')
  }

  if (training_time) {
    generalNotes.push(`Training schedule considered. Pre/post workout supplements timed around your ${formatTime(parseTime(training_time).hours, parseTime(training_time).minutes)} training.`)
  }

  if (fasting_window) {
    generalNotes.push(`Intermittent fasting window (${fasting_window.start} - ${fasting_window.end}) considered. Supplements requiring food are scheduled during eating window.`)
  }

  generalNotes.push('Consistency in timing is often more important than perfect optimization. Choose times you can maintain daily.')

  return {
    success: true,
    patient_id,
    schedule,
    daily_summary: dailySummary,
    general_notes: generalNotes
  }
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
    console.log(`[supplement-timing-optimizer] Request method: ${req.method}`)

    // Parse request body
    let requestBody: TimingOptimizerRequest
    try {
      requestBody = await req.json() as TimingOptimizerRequest
    } catch (parseError) {
      console.error(`[supplement-timing-optimizer] JSON parse error:`, parseError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to parse request body',
          schedule: [],
          daily_summary: { morning: [], midday: [], evening: [], bedtime: [] },
          general_notes: []
        } as TimingOptimizerResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate required fields
    if (!requestBody.supplements || !Array.isArray(requestBody.supplements) || requestBody.supplements.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'supplements array is required and must not be empty',
          schedule: [],
          daily_summary: { morning: [], midday: [], evening: [], bedtime: [] },
          general_notes: []
        } as TimingOptimizerResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!requestBody.wake_time || !requestBody.sleep_time) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'wake_time and sleep_time are required (HH:MM format)',
          schedule: [],
          daily_summary: { morning: [], midday: [], evening: [], bedtime: [] },
          general_notes: []
        } as TimingOptimizerResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[supplement-timing-optimizer] Processing ${requestBody.supplements.length} supplements`)
    console.log(`[supplement-timing-optimizer] Wake: ${requestBody.wake_time}, Sleep: ${requestBody.sleep_time}`)

    // Optimize timing
    const response = optimizeSupplementTiming(requestBody)

    console.log(`[supplement-timing-optimizer] Generated schedule for ${response.schedule.length} supplements`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[supplement-timing-optimizer] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        success: false,
        error: errorMessage,
        schedule: [],
        daily_summary: { morning: [], midday: [], evening: [], bedtime: [] },
        general_notes: []
      } as TimingOptimizerResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
