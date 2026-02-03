// ============================================================================
// Unified AI Coach Edge Function
// Health Intelligence Platform - Holistic Coaching (ACP-1201)
// ============================================================================
// This is the KEY DIFFERENTIATOR vs Ladder/Volt - a truly integrated AI coach
// that understands ALL aspects of the patient's health and fitness journey.
//
// Aggregates ALL data streams:
// - Training history, current program, recent workouts
// - Sleep quality, HRV, recovery metrics
// - Lab results and biomarkers
// - Fasting state and nutrition
// - Supplement stack
// - Goals and progress
//
// Returns holistic, contextual coaching that considers the WHOLE person.
//
// Date: 2026-02-02
// Ticket: ACP-1201 (Critical)
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

interface UnifiedCoachRequest {
  patient_id: string
  question?: string  // Optional - if provided, answer specifically; if not, provide proactive insights
}

interface PatientContext {
  // Basic info
  patient_id: string
  training_age_days: number

  // Goals
  active_goals: PatientGoal[]

  // Training
  recent_workouts: WorkoutSummary[]
  current_program: ProgramInfo | null
  weekly_workout_count: number
  training_frequency_trend: 'increasing' | 'stable' | 'decreasing'

  // Recovery & Readiness
  current_readiness: ReadinessData | null
  readiness_trend_7d: number[]
  avg_readiness_7d: number | null
  fatigue_score: number | null
  fatigue_band: string | null

  // Sleep
  avg_sleep_hours_7d: number | null
  sleep_trend: 'improving' | 'stable' | 'declining' | null
  nights_below_7h: number

  // HRV (if available from WHOOP/HealthKit)
  latest_hrv: number | null
  hrv_trend_7d: number[]
  avg_hrv_7d: number | null

  // Lab Results
  recent_lab_date: string | null
  flagged_biomarkers: BiomarkerFlag[]
  lab_concerns: string[]

  // Fasting
  current_fasting_state: FastingState | null
  fasting_history_30d: FastingSummary

  // Supplements
  current_supplements: SupplementInfo[]

  // Recovery Modalities
  recovery_sessions_7d: RecoverySessionInfo[]
}

interface PatientGoal {
  category: string
  title: string
  progress: number
  target_date: string | null
}

interface WorkoutSummary {
  date: string
  name: string
  category: string | null
  duration_minutes: number | null
  completed: boolean
}

interface ProgramInfo {
  name: string
  current_week: number
  total_weeks: number
}

interface ReadinessData {
  date: string
  readiness_score: number
  sleep_hours: number | null
  soreness_level: number | null
  energy_level: number | null
  stress_level: number | null
}

interface BiomarkerFlag {
  name: string
  value: number
  unit: string
  status: 'low' | 'high' | 'critical'
}

interface FastingState {
  is_fasting: boolean
  hours_fasted: number
  protocol_type: string | null
}

interface FastingSummary {
  total_fasts: number
  avg_duration: number
  completion_rate: number
}

interface SupplementInfo {
  name: string
  dosage: string
  timing: string
}

interface RecoverySessionInfo {
  type: string
  duration_minutes: number
  date: string
}

interface CoachingInsight {
  category: 'training' | 'recovery' | 'nutrition' | 'sleep' | 'labs' | 'general'
  priority: 'high' | 'medium' | 'low'
  insight: string
  action: string
  rationale: string
}

interface UnifiedCoachResponse {
  coaching_id: string
  greeting: string
  primary_message: string
  insights: CoachingInsight[]
  today_focus: string
  weekly_priorities: string[]
  data_summary: {
    readiness: string
    training: string
    recovery: string
    labs: string
  }
  proactive_alerts: string[]
  follow_up_questions: string[]
  disclaimer: string
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function calculateTrend(values: number[]): 'improving' | 'stable' | 'declining' | null {
  if (values.length < 3) return null

  const firstHalf = values.slice(0, Math.floor(values.length / 2))
  const secondHalf = values.slice(Math.floor(values.length / 2))

  const avgFirst = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length
  const avgSecond = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length

  const diff = avgSecond - avgFirst
  const percentChange = (diff / avgFirst) * 100

  if (percentChange > 5) return 'improving'
  if (percentChange < -5) return 'declining'
  return 'stable'
}

function getTimeBasedGreeting(): string {
  const hour = new Date().getHours()
  if (hour < 12) return 'Good morning'
  if (hour < 17) return 'Good afternoon'
  return 'Good evening'
}

async function gatherPatientContext(
  supabaseClient: any,
  patient_id: string
): Promise<PatientContext> {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString()
  const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString()
  const today = new Date().toISOString().split('T')[0]

  // Gather all data in parallel for efficiency
  const [
    patientData,
    goalsData,
    readinessData,
    workoutsData,
    fatigueData,
    labsData,
    fastingData,
    supplementsData,
    recoveryData,
    hrvData,
    programData
  ] = await Promise.all([
    // 1. Patient basic info
    supabaseClient
      .from('patients')
      .select('id, created_at')
      .eq('id', patient_id)
      .single(),

    // 2. Active goals
    supabaseClient
      .from('patient_goals')
      .select('category, title, current_value, target_value, target_date, status')
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(10),

    // 3. Readiness data (last 7 days)
    supabaseClient
      .from('daily_readiness')
      .select('date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo.split('T')[0])
      .order('date', { ascending: false })
      .limit(7),

    // 4. Recent workouts (last 14 days)
    supabaseClient
      .from('manual_sessions')
      .select('completed_at, name, duration_minutes, completed, source_template_id')
      .eq('patient_id', patient_id)
      .gte('completed_at', new Date(Date.now() - 14 * 24 * 60 * 60 * 1000).toISOString())
      .order('completed_at', { ascending: false })
      .limit(20),

    // 5. Fatigue data
    supabaseClient
      .from('fatigue_accumulation')
      .select('fatigue_score, fatigue_band, calculation_date')
      .eq('patient_id', patient_id)
      .order('calculation_date', { ascending: false })
      .limit(1)
      .maybeSingle(),

    // 6. Recent lab results
    supabaseClient
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
      .maybeSingle(),

    // 7. Current fasting state
    supabaseClient
      .from('fasting_logs')
      .select('started_at, ended_at, planned_hours, protocol_type, completed')
      .eq('patient_id', patient_id)
      .gte('started_at', thirtyDaysAgo)
      .order('started_at', { ascending: false })
      .limit(30),

    // 8. Current supplements
    supabaseClient
      .from('patient_supplement_stacks')
      .select(`
        dosage,
        dosage_unit,
        timing,
        supplements (name)
      `)
      .eq('patient_id', patient_id)
      .eq('is_active', true)
      .limit(20),

    // 9. Recovery sessions (last 7 days)
    supabaseClient
      .from('recovery_sessions')
      .select('session_type, duration_minutes, logged_at')
      .eq('patient_id', patient_id)
      .gte('logged_at', sevenDaysAgo)
      .order('logged_at', { ascending: false })
      .limit(20),

    // 10. HRV data (if available)
    supabaseClient
      .from('daily_readiness')
      .select('date, whoop_hrv_rmssd')
      .eq('patient_id', patient_id)
      .gte('date', sevenDaysAgo.split('T')[0])
      .not('whoop_hrv_rmssd', 'is', null)
      .order('date', { ascending: false })
      .limit(7),

    // 11. Current program enrollment
    supabaseClient
      .from('program_enrollments')
      .select(`
        start_date,
        current_week,
        programs (name, duration_weeks)
      `)
      .eq('patient_id', patient_id)
      .eq('status', 'active')
      .limit(1)
      .maybeSingle()
  ])

  // Process patient data
  const trainingAgeDays = patientData.data?.created_at
    ? Math.floor((Date.now() - new Date(patientData.data.created_at).getTime()) / (1000 * 60 * 60 * 24))
    : 0

  // Process goals
  const activeGoals: PatientGoal[] = (goalsData.data || []).map((g: any) => ({
    category: g.category || 'general',
    title: g.title,
    progress: g.target_value > 0 ? (g.current_value || 0) / g.target_value : 0,
    target_date: g.target_date
  }))

  // Process readiness
  const readinessEntries = readinessData.data || []
  const currentReadiness = readinessEntries.length > 0 ? readinessEntries[0] as ReadinessData : null
  const readinessTrend = readinessEntries
    .filter((r: any) => r.readiness_score !== null)
    .map((r: any) => r.readiness_score)
    .reverse()

  const avgReadiness = readinessTrend.length > 0
    ? readinessTrend.reduce((a: number, b: number) => a + b, 0) / readinessTrend.length
    : null

  // Process sleep
  const sleepHours = readinessEntries
    .filter((r: any) => r.sleep_hours !== null)
    .map((r: any) => r.sleep_hours as number)

  const avgSleep = sleepHours.length > 0
    ? sleepHours.reduce((a, b) => a + b, 0) / sleepHours.length
    : null

  const nightsBelow7h = sleepHours.filter(h => h < 7).length

  // Process workouts
  const recentWorkouts: WorkoutSummary[] = (workoutsData.data || []).map((w: any) => ({
    date: w.completed_at,
    name: w.name || 'Workout',
    category: null,
    duration_minutes: w.duration_minutes,
    completed: w.completed
  }))

  const weeklyWorkoutCount = recentWorkouts.filter(w => {
    const workoutDate = new Date(w.date)
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    return workoutDate >= oneWeekAgo && w.completed
  }).length

  // Process lab results
  const labResult = labsData.data
  let flaggedBiomarkers: BiomarkerFlag[] = []
  let labConcerns: string[] = []

  if (labResult && labResult.biomarker_values) {
    flaggedBiomarkers = labResult.biomarker_values
      .filter((b: any) => b.is_flagged)
      .map((b: any) => ({
        name: b.biomarker_type,
        value: b.value,
        unit: b.unit,
        status: 'high' as const // Would need reference range lookup for accurate status
      }))

    if (flaggedBiomarkers.length > 0) {
      labConcerns.push(`${flaggedBiomarkers.length} biomarker(s) flagged outside normal range`)
    }
  }

  // Process fasting
  const fastingLogs = fastingData.data || []
  const currentFast = fastingLogs.find((f: any) => !f.ended_at)

  let fastingState: FastingState | null = null
  if (currentFast) {
    const hoursFasted = (Date.now() - new Date(currentFast.started_at).getTime()) / (1000 * 60 * 60)
    fastingState = {
      is_fasting: true,
      hours_fasted: Math.round(hoursFasted * 10) / 10,
      protocol_type: currentFast.protocol_type
    }
  }

  const completedFasts = fastingLogs.filter((f: any) => f.completed)
  const fastingSummary: FastingSummary = {
    total_fasts: completedFasts.length,
    avg_duration: completedFasts.length > 0
      ? completedFasts.reduce((sum: number, f: any) => sum + (f.planned_hours || 0), 0) / completedFasts.length
      : 0,
    completion_rate: fastingLogs.length > 0
      ? completedFasts.length / fastingLogs.length
      : 0
  }

  // Process supplements
  const currentSupplements: SupplementInfo[] = (supplementsData.data || []).map((s: any) => ({
    name: s.supplements?.name || 'Unknown',
    dosage: `${s.dosage} ${s.dosage_unit}`,
    timing: s.timing
  }))

  // Process recovery sessions
  const recoverySessions: RecoverySessionInfo[] = (recoveryData.data || []).map((r: any) => ({
    type: r.session_type,
    duration_minutes: r.duration_minutes,
    date: r.logged_at
  }))

  // Process HRV
  const hrvValues = (hrvData.data || [])
    .filter((h: any) => h.whoop_hrv_rmssd !== null)
    .map((h: any) => h.whoop_hrv_rmssd)

  const latestHrv = hrvValues.length > 0 ? hrvValues[0] : null
  const avgHrv = hrvValues.length > 0
    ? hrvValues.reduce((a: number, b: number) => a + b, 0) / hrvValues.length
    : null

  // Process program
  let currentProgram: ProgramInfo | null = null
  if (programData.data) {
    currentProgram = {
      name: programData.data.programs?.name || 'Program',
      current_week: programData.data.current_week || 1,
      total_weeks: programData.data.programs?.duration_weeks || 12
    }
  }

  // Calculate training frequency trend
  const previousWeekWorkouts = recentWorkouts.filter(w => {
    const workoutDate = new Date(w.date)
    const twoWeeksAgo = new Date(Date.now() - 14 * 24 * 60 * 60 * 1000)
    const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
    return workoutDate >= twoWeeksAgo && workoutDate < oneWeekAgo && w.completed
  }).length

  let trainingTrend: 'increasing' | 'stable' | 'decreasing' = 'stable'
  if (weeklyWorkoutCount > previousWeekWorkouts + 1) trainingTrend = 'increasing'
  else if (weeklyWorkoutCount < previousWeekWorkouts - 1) trainingTrend = 'decreasing'

  return {
    patient_id,
    training_age_days: trainingAgeDays,
    active_goals: activeGoals,
    recent_workouts: recentWorkouts,
    current_program: currentProgram,
    weekly_workout_count: weeklyWorkoutCount,
    training_frequency_trend: trainingTrend,
    current_readiness: currentReadiness,
    readiness_trend_7d: readinessTrend,
    avg_readiness_7d: avgReadiness,
    fatigue_score: fatigueData.data?.fatigue_score || null,
    fatigue_band: fatigueData.data?.fatigue_band || null,
    avg_sleep_hours_7d: avgSleep,
    sleep_trend: calculateTrend(sleepHours),
    nights_below_7h: nightsBelow7h,
    latest_hrv: latestHrv,
    hrv_trend_7d: hrvValues.reverse(),
    avg_hrv_7d: avgHrv,
    recent_lab_date: labResult?.test_date || null,
    flagged_biomarkers: flaggedBiomarkers,
    lab_concerns: labConcerns,
    current_fasting_state: fastingState,
    fasting_history_30d: fastingSummary,
    current_supplements: currentSupplements,
    recovery_sessions_7d: recoverySessions
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
    const { patient_id, question } = await req.json() as UnifiedCoachRequest

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

    console.log(`[unified-ai-coach] Processing request for patient ${patient_id}${question ? ` with question: "${question.substring(0, 50)}..."` : ''}`)

    // Initialize Supabase client with service role
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // GATHER ALL PATIENT CONTEXT
    // ========================================================================
    console.log('[unified-ai-coach] Gathering patient context...')
    const context = await gatherPatientContext(supabaseClient, patient_id)
    console.log('[unified-ai-coach] Context gathered successfully')

    // ========================================================================
    // BUILD AI PROMPT
    // ========================================================================
    const systemPrompt = `You are an elite AI health and performance coach - think of yourself as a combination of Dr. Andrew Huberman (science-based optimization), Andy Galpin (exercise physiology), and Peter Attia (longevity medicine).

YOUR UNIQUE VALUE: Unlike basic fitness apps, you have access to the COMPLETE picture of this person's health - their training, sleep, HRV, lab work, fasting, supplements, and goals. Use this holistic view to provide insights that no single-domain app could offer.

COACHING PHILOSOPHY:
1. Evidence-based: Ground recommendations in science, cite mechanisms when helpful
2. Personalized: Use their actual data, not generic advice
3. Prioritized: Focus on the 1-2 highest-impact actions, not overwhelming lists
4. Empathetic: Acknowledge challenges, celebrate wins
5. Actionable: Every insight should have a clear next step

RESPONSE STYLE:
- Conversational but knowledgeable
- Use "you" language, make it personal
- Be specific with numbers and data
- Avoid cliches and generic fitness advice
- If they asked a question, answer it directly first

KEY INTEGRATIONS TO CONSIDER:
- Low HRV + high training load = overtraining risk
- Poor sleep + high stress = cortisol concern
- Flagged biomarkers + symptoms = investigate
- Fasting + intense training = performance tradeoff
- Supplement stack + lab results = efficacy check

PROACTIVE INSIGHTS:
- Identify concerning patterns before they become problems
- Suggest optimizations based on data trends
- Connect dots between different data streams
- Celebrate consistency and progress`

    const userPrompt = `${question ? `USER QUESTION: "${question}"\n\n` : ''}COMPLETE PATIENT CONTEXT:

=== BASIC INFO ===
Training Age: ${context.training_age_days} days

=== ACTIVE GOALS ===
${context.active_goals.length > 0
  ? context.active_goals.map(g => `- ${g.category}: ${g.title} (${Math.round(g.progress * 100)}% complete${g.target_date ? `, target: ${g.target_date}` : ''})`).join('\n')
  : 'No active goals set'}

=== CURRENT READINESS (Today) ===
${context.current_readiness
  ? `Readiness Score: ${context.current_readiness.readiness_score}/100
Sleep: ${context.current_readiness.sleep_hours ?? 'N/A'} hours
Soreness: ${context.current_readiness.soreness_level ?? 'N/A'}/10
Energy: ${context.current_readiness.energy_level ?? 'N/A'}/10
Stress: ${context.current_readiness.stress_level ?? 'N/A'}/10`
  : 'No readiness data logged today'}

7-Day Readiness Trend: ${context.readiness_trend_7d.length > 0 ? context.readiness_trend_7d.join(' -> ') : 'No data'}
Average Readiness (7d): ${context.avg_readiness_7d?.toFixed(0) ?? 'N/A'}/100

=== FATIGUE STATUS ===
Fatigue Score: ${context.fatigue_score ?? 'N/A'}/100
Fatigue Band: ${context.fatigue_band ?? 'Unknown'}

=== SLEEP (7-Day) ===
Average: ${context.avg_sleep_hours_7d?.toFixed(1) ?? 'N/A'} hours
Trend: ${context.sleep_trend ?? 'Unknown'}
Nights Below 7h: ${context.nights_below_7h}

=== HRV ===
Latest: ${context.latest_hrv ?? 'No data'} ms
7-Day Average: ${context.avg_hrv_7d?.toFixed(0) ?? 'N/A'} ms
Trend: ${context.hrv_trend_7d.length > 0 ? context.hrv_trend_7d.join(' -> ') : 'No data'}

=== TRAINING ===
Current Program: ${context.current_program ? `${context.current_program.name} (Week ${context.current_program.current_week}/${context.current_program.total_weeks})` : 'No active program'}
Workouts This Week: ${context.weekly_workout_count}
Training Trend: ${context.training_frequency_trend}
Recent Workouts:
${context.recent_workouts.slice(0, 5).map(w =>
  `- ${new Date(w.date).toLocaleDateString()}: ${w.name}${w.duration_minutes ? ` (${w.duration_minutes} min)` : ''}`
).join('\n') || 'No recent workouts'}

=== LAB RESULTS ===
${context.recent_lab_date
  ? `Most Recent: ${context.recent_lab_date}
Flagged Biomarkers: ${context.flagged_biomarkers.length > 0
      ? context.flagged_biomarkers.map(b => `${b.name}: ${b.value} ${b.unit} [${b.status.toUpperCase()}]`).join(', ')
      : 'None'}
Concerns: ${context.lab_concerns.length > 0 ? context.lab_concerns.join(', ') : 'None'}`
  : 'No lab data available'}

=== FASTING ===
Current State: ${context.current_fasting_state
  ? `FASTING - ${context.current_fasting_state.hours_fasted.toFixed(1)} hours${context.current_fasting_state.protocol_type ? ` (${context.current_fasting_state.protocol_type})` : ''}`
  : 'Not currently fasting'}
30-Day Summary: ${context.fasting_history_30d.total_fasts} fasts, avg ${context.fasting_history_30d.avg_duration.toFixed(0)}h, ${Math.round(context.fasting_history_30d.completion_rate * 100)}% completion

=== SUPPLEMENTS ===
${context.current_supplements.length > 0
  ? context.current_supplements.map(s => `- ${s.name}: ${s.dosage} (${s.timing})`).join('\n')
  : 'No supplements tracked'}

=== RECOVERY MODALITIES (7-Day) ===
${context.recovery_sessions_7d.length > 0
  ? context.recovery_sessions_7d.map(r => `- ${r.type}: ${r.duration_minutes} min (${new Date(r.date).toLocaleDateString()})`).join('\n')
  : 'No recovery sessions logged'}

TASK: ${question
  ? `Answer the user's question directly and comprehensively, then provide additional relevant insights based on their full context.`
  : `Provide proactive coaching insights based on the complete data picture. Identify the most important things this person should know right now.`}

Respond with valid JSON ONLY:
{
  "greeting": "Personalized greeting using time of day and their current state",
  "primary_message": "${question ? 'Direct answer to their question (2-3 paragraphs)' : 'Most important insight right now (2-3 paragraphs)'}",
  "insights": [
    {
      "category": "training|recovery|nutrition|sleep|labs|general",
      "priority": "high|medium|low",
      "insight": "What you noticed in their data",
      "action": "Specific action to take",
      "rationale": "Why this matters (science-backed)"
    }
  ],
  "today_focus": "The ONE thing they should focus on today",
  "weekly_priorities": ["Priority 1", "Priority 2", "Priority 3"],
  "data_summary": {
    "readiness": "One-line readiness summary",
    "training": "One-line training summary",
    "recovery": "One-line recovery summary",
    "labs": "One-line labs summary (or 'No recent data')"
  },
  "proactive_alerts": ["Any concerning patterns or warnings"],
  "follow_up_questions": ["Question to learn more about the user", "Another helpful question"]
}`

    const anthropicApiKey = Deno.env.get('ANTHROPIC_API_KEY')
    if (!anthropicApiKey) {
      throw new Error('ANTHROPIC_API_KEY environment variable not set')
    }

    console.log('[unified-ai-coach] Calling Anthropic Claude API...')

    const anthropicResponse = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model: 'claude-sonnet-4-20250514',
        max_tokens: 3000,
        messages: [
          {
            role: 'user',
            content: `${systemPrompt}\n\n${userPrompt}`
          }
        ],
        temperature: 0.5,
      }),
    })

    if (!anthropicResponse.ok) {
      const error = await anthropicResponse.text()
      console.error('[unified-ai-coach] Anthropic API error:', anthropicResponse.status, error)
      throw new Error(`Anthropic API error (${anthropicResponse.status}): ${error.substring(0, 200)}`)
    }

    const completion = await anthropicResponse.json()
    const responseText = completion.content?.[0]?.text

    if (!responseText) {
      throw new Error('No text content in Anthropic response')
    }

    console.log('[unified-ai-coach] Received response from Claude')

    // Parse AI response
    let aiResponse: any
    try {
      const jsonMatch = responseText.match(/\{[\s\S]*\}/)
      aiResponse = jsonMatch ? JSON.parse(jsonMatch[0]) : JSON.parse(responseText)
    } catch (parseError) {
      console.error('[unified-ai-coach] Failed to parse AI response:', responseText)
      throw new Error('Failed to parse AI response as JSON')
    }

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const disclaimer = `AI COACHING DISCLAIMER: This coaching is provided by an AI system and is for informational and motivational purposes only. It is not medical advice. The AI analyzes patterns in your data but cannot replace the judgment of qualified healthcare professionals. Always consult with your doctor before making significant changes to your exercise, nutrition, or health regimen, especially if you have medical conditions. If you experience concerning symptoms, seek medical attention.`

    const response: UnifiedCoachResponse = {
      coaching_id: crypto.randomUUID(),
      greeting: aiResponse.greeting || `${getTimeBasedGreeting()}! Let's look at your data.`,
      primary_message: aiResponse.primary_message || 'I analyzed your recent data and have some insights for you.',
      insights: aiResponse.insights || [],
      today_focus: aiResponse.today_focus || 'Focus on consistency today.',
      weekly_priorities: aiResponse.weekly_priorities || [],
      data_summary: aiResponse.data_summary || {
        readiness: 'Data unavailable',
        training: 'Data unavailable',
        recovery: 'Data unavailable',
        labs: 'No recent data'
      },
      proactive_alerts: aiResponse.proactive_alerts || [],
      follow_up_questions: aiResponse.follow_up_questions || [],
      disclaimer
    }

    // ========================================================================
    // LOG COACHING INTERACTION (for learning/improvement)
    // ========================================================================
    try {
      await supabaseClient
        .from('ai_coaching_logs')
        .insert({
          patient_id,
          question: question || null,
          response_summary: response.primary_message.substring(0, 500),
          insights_count: response.insights.length,
          context_snapshot: {
            readiness: context.avg_readiness_7d,
            sleep: context.avg_sleep_hours_7d,
            workouts_7d: context.weekly_workout_count,
            fasting: context.current_fasting_state?.is_fasting || false,
            fatigue_band: context.fatigue_band
          }
        })
    } catch (logError) {
      console.error('[unified-ai-coach] Failed to log interaction:', logError)
      // Don't fail the request if logging fails
    }

    console.log(`[unified-ai-coach] Generated ${response.insights.length} insights`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[unified-ai-coach] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        greeting: `${getTimeBasedGreeting()}! I encountered an issue.`,
        primary_message: 'I was unable to analyze your data at this time. Please try again in a few moments.',
        insights: [],
        today_focus: 'Keep doing what you are doing and check back later.',
        weekly_priorities: [],
        data_summary: {
          readiness: 'Unable to load',
          training: 'Unable to load',
          recovery: 'Unable to load',
          labs: 'Unable to load'
        },
        proactive_alerts: [],
        follow_up_questions: [],
        disclaimer: 'AI Coaching is temporarily unavailable. Please consult with a healthcare professional for guidance.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
