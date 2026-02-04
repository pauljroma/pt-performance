// ============================================================================
// Fasting Analytics Edge Function
// Health Intelligence Platform - Fasting Data Analysis & Insights
// ============================================================================
// Analyzes patient fasting history and provides comprehensive statistics,
// patterns, correlations with other health metrics, and actionable insights.
//
// Outputs:
// - Compliance rate and adherence trends
// - Average duration statistics
// - Streak tracking (current and best)
// - Correlation analysis with sleep, energy, HRV
// - Day-of-week and time patterns
// - Personalized insights and recommendations
//
// Date: 2026-02-03
// Ticket: ACP-433
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

interface FastingAnalyticsRequest {
  patient_id: string
  start_date: string  // YYYY-MM-DD
  end_date: string    // YYYY-MM-DD
}

interface FastingLog {
  id: string
  started_at: string
  ended_at: string | null
  planned_hours: number
  actual_hours: number | null
  protocol_type: string | null
  completed: boolean
  notes: string | null
  break_reason: string | null
}

interface DailyReadinessData {
  date: string
  sleep_hours: number | null
  energy_level: number | null
  stress_level: number | null
  readiness_score: number | null
  whoop_hrv_rmssd: number | null
}

interface WeeklyBreakdown {
  week_start: string
  week_end: string
  fasts_completed: number
  fasts_planned: number
  compliance_rate: number
  total_fasting_hours: number
  average_duration: number
  longest_fast: number
  protocols_used: string[]
}

interface DayOfWeekPattern {
  day: string
  fasts_started: number
  average_duration: number
  completion_rate: number
}

interface CorrelationData {
  metric: string
  correlation: 'positive' | 'negative' | 'neutral' | 'insufficient_data'
  strength: 'strong' | 'moderate' | 'weak' | 'none'
  description: string
  data_points: number
}

interface Insight {
  category: 'achievement' | 'pattern' | 'suggestion' | 'warning'
  title: string
  description: string
  priority: 'high' | 'medium' | 'low'
  actionable: boolean
  action?: string
}

interface StreakData {
  current_streak: number
  current_streak_start: string | null
  best_streak: number
  best_streak_period: { start: string; end: string } | null
  total_fasts: number
}

interface SummaryStats {
  total_fasts: number
  completed_fasts: number
  incomplete_fasts: number
  compliance_rate: number
  total_fasting_hours: number
  average_duration_hours: number
  median_duration_hours: number
  longest_fast_hours: number
  shortest_fast_hours: number
  most_used_protocol: string | null
  protocols_breakdown: { protocol: string; count: number; percentage: number }[]
}

interface FastingAnalyticsResponse {
  analytics_id: string
  patient_id: string
  date_range: { start: string; end: string }
  summary: SummaryStats
  streaks: StreakData
  weekly_breakdown: WeeklyBreakdown[]
  day_of_week_patterns: DayOfWeekPattern[]
  time_of_day_patterns: {
    morning_starts: number   // Before 10am
    midday_starts: number    // 10am-2pm
    afternoon_starts: number // 2pm-6pm
    evening_starts: number   // After 6pm
  }
  correlations: CorrelationData[]
  insights: Insight[]
  trend: {
    direction: 'improving' | 'declining' | 'stable'
    compliance_trend: number[] // Last 4 weeks
    duration_trend: number[]   // Last 4 weeks
  }
  disclaimer: string
}

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i
  return uuidRegex.test(uuid)
}

function isValidDateFormat(date: string): boolean {
  return /^\d{4}-\d{2}-\d{2}$/.test(date) && !isNaN(Date.parse(date))
}

function getWeekStart(dateStr: string): string {
  const date = new Date(dateStr + 'T12:00:00')
  const day = date.getDay()
  const diff = date.getDate() - day + (day === 0 ? -6 : 1) // Monday start
  date.setDate(diff)
  return date.toISOString().split('T')[0]
}

function getWeekEnd(weekStart: string): string {
  const date = new Date(weekStart + 'T12:00:00')
  date.setDate(date.getDate() + 6)
  return date.toISOString().split('T')[0]
}

function getDayOfWeek(dateStr: string): string {
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  const date = new Date(dateStr + 'T12:00:00')
  return days[date.getDay()]
}

function getHourOfDay(dateTimeStr: string): number {
  const date = new Date(dateTimeStr)
  return date.getHours()
}

function median(values: number[]): number {
  if (values.length === 0) return 0
  const sorted = [...values].sort((a, b) => a - b)
  const mid = Math.floor(sorted.length / 2)
  return sorted.length % 2 !== 0 ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2
}

function calculateCorrelation(x: number[], y: number[]): number {
  if (x.length !== y.length || x.length < 3) return 0

  const n = x.length
  const sumX = x.reduce((a, b) => a + b, 0)
  const sumY = y.reduce((a, b) => a + b, 0)
  const sumXY = x.reduce((total, xi, i) => total + xi * y[i], 0)
  const sumX2 = x.reduce((a, b) => a + b * b, 0)
  const sumY2 = y.reduce((a, b) => a + b * b, 0)

  const numerator = n * sumXY - sumX * sumY
  const denominator = Math.sqrt((n * sumX2 - sumX * sumX) * (n * sumY2 - sumY * sumY))

  if (denominator === 0) return 0
  return numerator / denominator
}

function interpretCorrelation(r: number, n: number): { direction: 'positive' | 'negative' | 'neutral', strength: 'strong' | 'moderate' | 'weak' | 'none' } {
  if (n < 5) return { direction: 'neutral', strength: 'none' }

  const absR = Math.abs(r)
  const direction = r > 0.1 ? 'positive' : r < -0.1 ? 'negative' : 'neutral'

  let strength: 'strong' | 'moderate' | 'weak' | 'none'
  if (absR >= 0.7) strength = 'strong'
  else if (absR >= 0.4) strength = 'moderate'
  else if (absR >= 0.2) strength = 'weak'
  else strength = 'none'

  return { direction, strength }
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
    const { patient_id, start_date, end_date } = await req.json() as FastingAnalyticsRequest

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

    if (!start_date || !isValidDateFormat(start_date)) {
      return new Response(
        JSON.stringify({ error: 'start_date is required in YYYY-MM-DD format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!end_date || !isValidDateFormat(end_date)) {
      return new Response(
        JSON.stringify({ error: 'end_date is required in YYYY-MM-DD format' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (new Date(start_date) > new Date(end_date)) {
      return new Response(
        JSON.stringify({ error: 'start_date must be before end_date' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Limit date range to 1 year
    const daysDiff = (new Date(end_date).getTime() - new Date(start_date).getTime()) / (1000 * 60 * 60 * 24)
    if (daysDiff > 365) {
      return new Response(
        JSON.stringify({ error: 'Date range cannot exceed 365 days' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[fasting-analytics] Analyzing fasting data for patient ${patient_id}, ${start_date} to ${end_date}`)

    // ========================================================================
    // INITIALIZE SUPABASE CLIENT
    // ========================================================================
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ========================================================================
    // FETCH FASTING LOGS
    // ========================================================================
    const { data: fastingLogs, error: fastingError } = await supabaseClient
      .from('fasting_logs')
      .select('*')
      .eq('patient_id', patient_id)
      .gte('started_at', start_date)
      .lte('started_at', end_date + 'T23:59:59')
      .order('started_at', { ascending: true })

    if (fastingError) {
      console.error('[fasting-analytics] Error fetching fasting logs:', fastingError)
      throw new Error('Failed to fetch fasting data')
    }

    const fasts: FastingLog[] = fastingLogs || []
    console.log(`[fasting-analytics] Found ${fasts.length} fasting logs`)

    // ========================================================================
    // FETCH DAILY READINESS DATA FOR CORRELATIONS
    // ========================================================================
    const { data: readinessData, error: readinessError } = await supabaseClient
      .from('daily_readiness')
      .select('date, sleep_hours, energy_level, stress_level, readiness_score, whoop_hrv_rmssd')
      .eq('patient_id', patient_id)
      .gte('date', start_date)
      .lte('date', end_date)
      .order('date', { ascending: true })

    if (readinessError) {
      console.error('[fasting-analytics] Error fetching readiness data:', readinessError)
    }

    const readiness: DailyReadinessData[] = readinessData || []

    // ========================================================================
    // CALCULATE SUMMARY STATISTICS
    // ========================================================================
    const completedFasts = fasts.filter(f => f.completed)
    const incompleteFasts = fasts.filter(f => !f.completed)
    const durations = fasts.map(f => f.actual_hours || f.planned_hours).filter(d => d > 0)

    const protocolCounts = new Map<string, number>()
    for (const fast of fasts) {
      const protocol = fast.protocol_type || 'unspecified'
      protocolCounts.set(protocol, (protocolCounts.get(protocol) || 0) + 1)
    }

    const protocolsBreakdown = Array.from(protocolCounts.entries())
      .map(([protocol, count]) => ({
        protocol,
        count,
        percentage: Math.round((count / fasts.length) * 100)
      }))
      .sort((a, b) => b.count - a.count)

    const summary: SummaryStats = {
      total_fasts: fasts.length,
      completed_fasts: completedFasts.length,
      incomplete_fasts: incompleteFasts.length,
      compliance_rate: fasts.length > 0 ? Math.round((completedFasts.length / fasts.length) * 100) : 0,
      total_fasting_hours: Math.round(durations.reduce((a, b) => a + b, 0) * 10) / 10,
      average_duration_hours: durations.length > 0 ? Math.round((durations.reduce((a, b) => a + b, 0) / durations.length) * 10) / 10 : 0,
      median_duration_hours: Math.round(median(durations) * 10) / 10,
      longest_fast_hours: durations.length > 0 ? Math.max(...durations) : 0,
      shortest_fast_hours: durations.length > 0 ? Math.min(...durations) : 0,
      most_used_protocol: protocolsBreakdown.length > 0 ? protocolsBreakdown[0].protocol : null,
      protocols_breakdown: protocolsBreakdown
    }

    // ========================================================================
    // CALCULATE STREAKS
    // ========================================================================
    let currentStreak = 0
    let currentStreakStart: string | null = null
    let bestStreak = 0
    let bestStreakPeriod: { start: string; end: string } | null = null
    let tempStreak = 0
    let tempStreakStart: string | null = null

    // Sort by date for streak calculation
    const sortedFasts = [...completedFasts].sort((a, b) =>
      new Date(a.started_at).getTime() - new Date(b.started_at).getTime()
    )

    for (let i = 0; i < sortedFasts.length; i++) {
      const currentDate = sortedFasts[i].started_at.split('T')[0]

      if (i === 0) {
        tempStreak = 1
        tempStreakStart = currentDate
      } else {
        const prevDate = sortedFasts[i - 1].started_at.split('T')[0]
        const daysDiff = (new Date(currentDate).getTime() - new Date(prevDate).getTime()) / (1000 * 60 * 60 * 24)

        if (daysDiff <= 2) { // Allow 1 day gap for flexibility
          tempStreak++
        } else {
          // Check if this was the best streak
          if (tempStreak > bestStreak) {
            bestStreak = tempStreak
            bestStreakPeriod = {
              start: tempStreakStart!,
              end: prevDate
            }
          }
          tempStreak = 1
          tempStreakStart = currentDate
        }
      }
    }

    // Check final streak
    if (tempStreak > bestStreak) {
      bestStreak = tempStreak
      bestStreakPeriod = {
        start: tempStreakStart!,
        end: sortedFasts[sortedFasts.length - 1]?.started_at.split('T')[0] || tempStreakStart!
      }
    }

    // Check if current streak is ongoing
    if (sortedFasts.length > 0) {
      const lastFastDate = sortedFasts[sortedFasts.length - 1].started_at.split('T')[0]
      const today = new Date().toISOString().split('T')[0]
      const daysSinceLastFast = (new Date(today).getTime() - new Date(lastFastDate).getTime()) / (1000 * 60 * 60 * 24)

      if (daysSinceLastFast <= 2) {
        currentStreak = tempStreak
        currentStreakStart = tempStreakStart
      }
    }

    const streaks: StreakData = {
      current_streak: currentStreak,
      current_streak_start: currentStreakStart,
      best_streak: bestStreak,
      best_streak_period: bestStreakPeriod,
      total_fasts: fasts.length
    }

    // ========================================================================
    // WEEKLY BREAKDOWN
    // ========================================================================
    const weeklyMap = new Map<string, WeeklyBreakdown>()

    for (const fast of fasts) {
      const weekStart = getWeekStart(fast.started_at.split('T')[0])

      if (!weeklyMap.has(weekStart)) {
        weeklyMap.set(weekStart, {
          week_start: weekStart,
          week_end: getWeekEnd(weekStart),
          fasts_completed: 0,
          fasts_planned: 0,
          compliance_rate: 0,
          total_fasting_hours: 0,
          average_duration: 0,
          longest_fast: 0,
          protocols_used: []
        })
      }

      const week = weeklyMap.get(weekStart)!
      week.fasts_planned++
      if (fast.completed) week.fasts_completed++
      const duration = fast.actual_hours || fast.planned_hours
      week.total_fasting_hours += duration
      if (duration > week.longest_fast) week.longest_fast = duration
      if (fast.protocol_type && !week.protocols_used.includes(fast.protocol_type)) {
        week.protocols_used.push(fast.protocol_type)
      }
    }

    const weeklyBreakdown = Array.from(weeklyMap.values())
      .map(week => ({
        ...week,
        compliance_rate: week.fasts_planned > 0 ? Math.round((week.fasts_completed / week.fasts_planned) * 100) : 0,
        average_duration: week.fasts_planned > 0 ? Math.round((week.total_fasting_hours / week.fasts_planned) * 10) / 10 : 0,
        total_fasting_hours: Math.round(week.total_fasting_hours * 10) / 10,
        longest_fast: Math.round(week.longest_fast * 10) / 10
      }))
      .sort((a, b) => a.week_start.localeCompare(b.week_start))

    // ========================================================================
    // DAY OF WEEK PATTERNS
    // ========================================================================
    const dayPatterns = new Map<string, { started: number; durations: number[]; completed: number }>()
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

    for (const day of dayNames) {
      dayPatterns.set(day, { started: 0, durations: [], completed: 0 })
    }

    for (const fast of fasts) {
      const day = getDayOfWeek(fast.started_at.split('T')[0])
      const pattern = dayPatterns.get(day)!
      pattern.started++
      pattern.durations.push(fast.actual_hours || fast.planned_hours)
      if (fast.completed) pattern.completed++
    }

    const dayOfWeekPatterns: DayOfWeekPattern[] = dayNames.map(day => {
      const pattern = dayPatterns.get(day)!
      return {
        day,
        fasts_started: pattern.started,
        average_duration: pattern.durations.length > 0
          ? Math.round((pattern.durations.reduce((a, b) => a + b, 0) / pattern.durations.length) * 10) / 10
          : 0,
        completion_rate: pattern.started > 0
          ? Math.round((pattern.completed / pattern.started) * 100)
          : 0
      }
    })

    // ========================================================================
    // TIME OF DAY PATTERNS
    // ========================================================================
    let morningStarts = 0
    let middayStarts = 0
    let afternoonStarts = 0
    let eveningStarts = 0

    for (const fast of fasts) {
      const hour = getHourOfDay(fast.started_at)
      if (hour < 10) morningStarts++
      else if (hour < 14) middayStarts++
      else if (hour < 18) afternoonStarts++
      else eveningStarts++
    }

    const timeOfDayPatterns = {
      morning_starts: morningStarts,
      midday_starts: middayStarts,
      afternoon_starts: afternoonStarts,
      evening_starts: eveningStarts
    }

    // ========================================================================
    // CORRELATION ANALYSIS
    // ========================================================================
    const correlations: CorrelationData[] = []

    // Create date-based lookup for fasting data
    const fastingByDate = new Map<string, number>()
    for (const fast of completedFasts) {
      const date = fast.started_at.split('T')[0]
      fastingByDate.set(date, fast.actual_hours || fast.planned_hours)
    }

    // Correlate with sleep
    const sleepPairs: { x: number; y: number }[] = []
    for (const r of readiness) {
      const fastDuration = fastingByDate.get(r.date)
      if (fastDuration && r.sleep_hours) {
        sleepPairs.push({ x: fastDuration, y: r.sleep_hours })
      }
    }

    if (sleepPairs.length >= 3) {
      const r = calculateCorrelation(sleepPairs.map(p => p.x), sleepPairs.map(p => p.y))
      const { direction, strength } = interpretCorrelation(r, sleepPairs.length)
      correlations.push({
        metric: 'Sleep Duration',
        correlation: direction === 'neutral' ? 'neutral' : direction,
        strength,
        description: direction === 'positive'
          ? 'Longer fasts tend to correlate with better sleep duration'
          : direction === 'negative'
          ? 'Longer fasts may be associated with reduced sleep'
          : 'No clear relationship between fasting duration and sleep',
        data_points: sleepPairs.length
      })
    }

    // Correlate with energy
    const energyPairs: { x: number; y: number }[] = []
    for (const r of readiness) {
      const fastDuration = fastingByDate.get(r.date)
      if (fastDuration && r.energy_level) {
        energyPairs.push({ x: fastDuration, y: r.energy_level })
      }
    }

    if (energyPairs.length >= 3) {
      const r = calculateCorrelation(energyPairs.map(p => p.x), energyPairs.map(p => p.y))
      const { direction, strength } = interpretCorrelation(r, energyPairs.length)
      correlations.push({
        metric: 'Energy Level',
        correlation: direction === 'neutral' ? 'neutral' : direction,
        strength,
        description: direction === 'positive'
          ? 'Fasting days show improved energy levels'
          : direction === 'negative'
          ? 'Extended fasts may reduce energy levels'
          : 'Energy levels appear stable regardless of fasting',
        data_points: energyPairs.length
      })
    }

    // Correlate with HRV
    const hrvPairs: { x: number; y: number }[] = []
    for (const r of readiness) {
      const fastDuration = fastingByDate.get(r.date)
      if (fastDuration && r.whoop_hrv_rmssd) {
        hrvPairs.push({ x: fastDuration, y: r.whoop_hrv_rmssd })
      }
    }

    if (hrvPairs.length >= 3) {
      const r = calculateCorrelation(hrvPairs.map(p => p.x), hrvPairs.map(p => p.y))
      const { direction, strength } = interpretCorrelation(r, hrvPairs.length)
      correlations.push({
        metric: 'Heart Rate Variability (HRV)',
        correlation: direction === 'neutral' ? 'neutral' : direction,
        strength,
        description: direction === 'positive'
          ? 'Fasting correlates with improved HRV - indicating better recovery'
          : direction === 'negative'
          ? 'Extended fasting may be stressing your system (lower HRV)'
          : 'HRV appears stable regardless of fasting duration',
        data_points: hrvPairs.length
      })
    }

    // Add insufficient data correlations if needed
    if (sleepPairs.length < 3) {
      correlations.push({
        metric: 'Sleep Duration',
        correlation: 'insufficient_data',
        strength: 'none',
        description: 'Not enough overlapping data to analyze sleep correlation',
        data_points: sleepPairs.length
      })
    }

    // ========================================================================
    // TREND ANALYSIS
    // ========================================================================
    const last4Weeks = weeklyBreakdown.slice(-4)
    const complianceTrend = last4Weeks.map(w => w.compliance_rate)
    const durationTrend = last4Weeks.map(w => w.average_duration)

    let trendDirection: 'improving' | 'declining' | 'stable' = 'stable'
    if (complianceTrend.length >= 2) {
      const firstHalf = complianceTrend.slice(0, Math.floor(complianceTrend.length / 2))
      const secondHalf = complianceTrend.slice(Math.floor(complianceTrend.length / 2))
      const firstAvg = firstHalf.reduce((a, b) => a + b, 0) / firstHalf.length
      const secondAvg = secondHalf.reduce((a, b) => a + b, 0) / secondHalf.length

      if (secondAvg > firstAvg + 10) trendDirection = 'improving'
      else if (secondAvg < firstAvg - 10) trendDirection = 'declining'
    }

    // ========================================================================
    // GENERATE INSIGHTS
    // ========================================================================
    const insights: Insight[] = []

    // Achievement insights
    if (summary.compliance_rate >= 80) {
      insights.push({
        category: 'achievement',
        title: 'Excellent Compliance',
        description: `Your ${summary.compliance_rate}% completion rate shows strong commitment to your fasting protocol.`,
        priority: 'low',
        actionable: false
      })
    }

    if (bestStreak >= 7) {
      insights.push({
        category: 'achievement',
        title: `${bestStreak}-Day Streak`,
        description: `Your best streak of ${bestStreak} consecutive fasts shows excellent consistency.`,
        priority: 'low',
        actionable: false
      })
    }

    // Pattern insights
    const bestDay = dayOfWeekPatterns.reduce((a, b) => b.completion_rate > a.completion_rate ? b : a)
    const worstDay = dayOfWeekPatterns.filter(d => d.fasts_started > 0).reduce((a, b) => b.completion_rate < a.completion_rate ? b : a)

    if (bestDay.fasts_started >= 2 && bestDay.completion_rate > worstDay.completion_rate + 20) {
      insights.push({
        category: 'pattern',
        title: 'Best Fasting Day',
        description: `You have the highest success rate on ${bestDay.day}s (${bestDay.completion_rate}% completion).`,
        priority: 'medium',
        actionable: true,
        action: `Consider scheduling important fasts on ${bestDay.day}s for higher success.`
      })
    }

    if (worstDay.fasts_started >= 2 && worstDay.completion_rate < 70) {
      insights.push({
        category: 'pattern',
        title: 'Challenging Day Identified',
        description: `${worstDay.day}s show lower completion rates (${worstDay.completion_rate}%).`,
        priority: 'medium',
        actionable: true,
        action: `Consider lighter fasting protocols or meal prep on ${worstDay.day}s.`
      })
    }

    // Suggestion insights
    if (summary.average_duration_hours < 14) {
      insights.push({
        category: 'suggestion',
        title: 'Consider Longer Fasts',
        description: `Your average ${summary.average_duration_hours} hour fasts may not maximize autophagy benefits.`,
        priority: 'medium',
        actionable: true,
        action: 'Try extending your eating window end time by 1-2 hours to reach 14+ hour fasts.'
      })
    }

    if (summary.compliance_rate < 60) {
      insights.push({
        category: 'warning',
        title: 'Low Compliance Rate',
        description: `${summary.compliance_rate}% completion suggests your protocol may be too aggressive.`,
        priority: 'high',
        actionable: true,
        action: 'Consider switching to a more flexible protocol like 14:10 or 16:8 to build consistency.'
      })
    }

    // Correlation-based insights
    const negativeEnergyCorr = correlations.find(c => c.metric === 'Energy Level' && c.correlation === 'negative' && c.strength !== 'none')
    if (negativeEnergyCorr) {
      insights.push({
        category: 'warning',
        title: 'Energy Impact Detected',
        description: 'Your fasting may be negatively affecting energy levels.',
        priority: 'high',
        actionable: true,
        action: 'Consider shortening fasts or ensuring adequate electrolyte intake during fasted periods.'
      })
    }

    // Time of day insight
    if (eveningStarts > morningStarts + middayStarts) {
      insights.push({
        category: 'suggestion',
        title: 'Evening Fasting Pattern',
        description: 'Most of your fasts start in the evening, which may affect sleep quality.',
        priority: 'medium',
        actionable: true,
        action: 'Consider an earlier eating window end time to avoid eating close to bedtime.'
      })
    }

    // Sort insights by priority
    insights.sort((a, b) => {
      const priorityOrder = { high: 0, medium: 1, low: 2 }
      return priorityOrder[a.priority] - priorityOrder[b.priority]
    })

    // ========================================================================
    // BUILD RESPONSE
    // ========================================================================
    const disclaimer = `FASTING ANALYTICS DISCLAIMER: These analytics are generated from your logged fasting data and are for informational purposes only. Correlations shown do not imply causation. Individual responses to fasting vary significantly. This is not medical advice. Consult with a healthcare provider before making significant changes to your fasting or nutrition regimen, especially if you have medical conditions or take medications.`

    const response: FastingAnalyticsResponse = {
      analytics_id: crypto.randomUUID(),
      patient_id,
      date_range: { start: start_date, end: end_date },
      summary,
      streaks,
      weekly_breakdown: weeklyBreakdown,
      day_of_week_patterns: dayOfWeekPatterns,
      time_of_day_patterns: timeOfDayPatterns,
      correlations,
      insights,
      trend: {
        direction: trendDirection,
        compliance_trend: complianceTrend,
        duration_trend: durationTrend
      },
      disclaimer
    }

    console.log(`[fasting-analytics] Generated analytics: ${fasts.length} fasts, ${insights.length} insights`)

    return new Response(
      JSON.stringify(response),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[fasting-analytics] Error:', error)

    const errorMessage = error instanceof Error ? error.message : 'Internal server error'

    return new Response(
      JSON.stringify({
        error: errorMessage,
        disclaimer: 'Unable to generate fasting analytics. Please try again.'
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
