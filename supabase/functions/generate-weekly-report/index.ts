// ============================================================================
// M7 - PT Weekly Report System
// Edge Function: generate-weekly-report
//
// Generates weekly progress reports for patients
// Called by:
// 1. On-demand from iOS app
// 2. Scheduled cron job (Monday 8am)
// 3. Therapist dashboard
// ============================================================================

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

// ============================================================================
// INTERFACES
// ============================================================================

interface WeeklyReportRequest {
  patient_id: string;
  week_start_date?: string; // YYYY-MM-DD format
  week_end_date?: string;
  therapist_id?: string;
  send_email?: boolean;
}

interface GoalProgress {
  id: string;
  goal_name: string;
  target_value: number;
  current_value: number;
  percent_complete: number;
  trend: 'improving' | 'stable' | 'declining';
}

interface WeeklyReport {
  id: string;
  patient_id: string;
  therapist_id: string;
  week_start_date: string;
  week_end_date: string;
  generated_at: string;
  session_completion_rate: number;
  total_sessions_scheduled: number;
  total_sessions_completed: number;
  average_pain_level: number | null;
  pain_trend: 'improving' | 'stable' | 'declining';
  average_recovery_score: number | null;
  recovery_trend: 'improving' | 'stable' | 'declining';
  adherence_score: number;
  goals_progress: GoalProgress[];
  ai_recommendations_adopted: number;
  ai_recommendations_total: number;
  achievements: string[];
  concerns: string[];
  recommendations: string[];
}

// ============================================================================
// MAIN HANDLER
// ============================================================================

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');

    if (!supabaseUrl || !supabaseServiceKey) {
      throw new Error('Missing required environment variables');
    }

    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Parse request
    const requestData: WeeklyReportRequest = await req.json();
    const { patient_id, week_start_date, week_end_date, send_email } = requestData;

    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log('Generating weekly report:', {
      patient_id,
      week_start_date,
      week_end_date,
      timestamp: new Date().toISOString()
    });

    // Calculate week boundaries if not provided
    const { weekStart, weekEnd } = getWeekBoundaries(week_start_date, week_end_date);

    // Fetch patient data
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .select('id, therapist_id, first_name, last_name')
      .eq('id', patient_id)
      .single();

    if (patientError || !patient) {
      throw new Error(`Patient not found: ${patient_id}`);
    }

    // Generate report metrics
    const metrics = await calculateMetrics(supabase, patient_id, weekStart, weekEnd);

    // Fetch goals progress
    const goalsProgress = await calculateGoalsProgress(supabase, patient_id, weekStart, weekEnd);

    // Fetch AI recommendations stats
    const aiStats = await calculateAIStats(supabase, patient_id, weekStart, weekEnd);

    // Generate achievements, concerns, and recommendations
    const highlights = generateHighlights(metrics, goalsProgress);

    // Create the report
    const reportData = {
      patient_id,
      therapist_id: patient.therapist_id,
      week_start_date: weekStart,
      week_end_date: weekEnd,
      generated_at: new Date().toISOString(),
      session_completion_rate: metrics.sessionCompletionRate,
      total_sessions_scheduled: metrics.sessionsScheduled,
      total_sessions_completed: metrics.sessionsCompleted,
      average_pain_level: metrics.averagePain,
      pain_trend: metrics.painTrend,
      average_recovery_score: metrics.averageRecovery,
      recovery_trend: metrics.recoveryTrend,
      adherence_score: metrics.adherenceScore,
      goals_progress: goalsProgress,
      ai_recommendations_adopted: aiStats.adopted,
      ai_recommendations_total: aiStats.total,
      achievements: highlights.achievements,
      concerns: highlights.concerns,
      recommendations: highlights.recommendations
    };

    // Insert or update the report
    const { data: report, error: insertError } = await supabase
      .from('weekly_reports')
      .upsert(reportData, {
        onConflict: 'patient_id,week_start_date',
        ignoreDuplicates: false
      })
      .select()
      .single();

    if (insertError) {
      throw new Error(`Failed to save report: ${insertError.message}`);
    }

    console.log('Report generated successfully:', report.id);

    // Optionally send email notification
    if (send_email) {
      await sendEmailNotification(supabase, patient, report);
    }

    return new Response(
      JSON.stringify(report),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    );

  } catch (error) {
    console.error('Error generating weekly report:', error);

    return new Response(
      JSON.stringify({
        error: error.message,
        timestamp: new Date().toISOString()
      }),
      {
        headers: { 'Content-Type': 'application/json' },
        status: 500
      }
    );
  }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function getWeekBoundaries(startDate?: string, endDate?: string): { weekStart: string; weekEnd: string } {
  if (startDate && endDate) {
    return { weekStart: startDate, weekEnd: endDate };
  }

  const now = new Date();
  const dayOfWeek = now.getDay(); // 0 = Sunday

  // Default to previous week
  const weekEnd = new Date(now);
  weekEnd.setDate(now.getDate() - dayOfWeek - 1); // Last Saturday

  const weekStart = new Date(weekEnd);
  weekStart.setDate(weekEnd.getDate() - 6); // Previous Sunday

  const formatDate = (d: Date) => d.toISOString().split('T')[0];

  return {
    weekStart: startDate || formatDate(weekStart),
    weekEnd: endDate || formatDate(weekEnd)
  };
}

async function calculateMetrics(
  supabase: any,
  patientId: string,
  weekStart: string,
  weekEnd: string
): Promise<{
  sessionsScheduled: number;
  sessionsCompleted: number;
  sessionCompletionRate: number;
  averagePain: number | null;
  painTrend: 'improving' | 'stable' | 'declining';
  averageRecovery: number | null;
  recoveryTrend: 'improving' | 'stable' | 'declining';
  adherenceScore: number;
}> {

  // Count scheduled sessions
  const { data: scheduledSessions } = await supabase
    .from('scheduled_sessions')
    .select('id')
    .eq('patient_id', patientId)
    .gte('scheduled_date', weekStart)
    .lte('scheduled_date', weekEnd);

  const sessionsScheduled = scheduledSessions?.length || 0;

  // Count completed sessions
  const { data: completedSessions } = await supabase
    .from('sessions')
    .select('id, phase_id')
    .eq('completed', true)
    .gte('session_date', weekStart)
    .lte('session_date', weekEnd);

  // Filter to patient's sessions via programs
  let sessionsCompleted = 0;
  if (completedSessions && completedSessions.length > 0) {
    const { data: patientPrograms } = await supabase
      .from('programs')
      .select('id')
      .eq('patient_id', patientId);

    if (patientPrograms) {
      const programIds = patientPrograms.map((p: any) => p.id);

      const { data: phases } = await supabase
        .from('phases')
        .select('id')
        .in('program_id', programIds);

      if (phases) {
        const phaseIds = phases.map((p: any) => p.id);
        sessionsCompleted = completedSessions.filter((s: any) =>
          phaseIds.includes(s.phase_id)
        ).length;
      }
    }
  }

  const sessionCompletionRate = sessionsScheduled > 0
    ? sessionsCompleted / sessionsScheduled
    : (sessionsCompleted > 0 ? Math.min(sessionsCompleted / 5, 1) : 0);

  // Calculate average pain
  const { data: painLogs } = await supabase
    .from('exercise_logs')
    .select('pain_score')
    .eq('patient_id', patientId)
    .gte('logged_at', weekStart)
    .lte('logged_at', weekEnd + 'T23:59:59')
    .not('pain_score', 'is', null);

  const averagePain = painLogs && painLogs.length > 0
    ? painLogs.reduce((sum: number, log: any) => sum + log.pain_score, 0) / painLogs.length
    : null;

  // Calculate previous week's pain for trend
  const prevWeekStart = new Date(weekStart);
  prevWeekStart.setDate(prevWeekStart.getDate() - 7);
  const prevWeekStartStr = prevWeekStart.toISOString().split('T')[0];
  const prevWeekEndStr = weekStart;

  const { data: prevPainLogs } = await supabase
    .from('exercise_logs')
    .select('pain_score')
    .eq('patient_id', patientId)
    .gte('logged_at', prevWeekStartStr)
    .lt('logged_at', prevWeekEndStr)
    .not('pain_score', 'is', null);

  const prevAveragePain = prevPainLogs && prevPainLogs.length > 0
    ? prevPainLogs.reduce((sum: number, log: any) => sum + log.pain_score, 0) / prevPainLogs.length
    : null;

  let painTrend: 'improving' | 'stable' | 'declining' = 'stable';
  if (averagePain !== null && prevAveragePain !== null) {
    if (averagePain < prevAveragePain - 0.5) painTrend = 'improving';
    else if (averagePain > prevAveragePain + 0.5) painTrend = 'declining';
  }

  // Calculate recovery scores
  const { data: readinessLogs } = await supabase
    .from('daily_readiness')
    .select('recovery_score')
    .eq('patient_id', patientId)
    .gte('date', weekStart)
    .lte('date', weekEnd)
    .not('recovery_score', 'is', null);

  const averageRecovery = readinessLogs && readinessLogs.length > 0
    ? readinessLogs.reduce((sum: number, log: any) => sum + log.recovery_score, 0) / readinessLogs.length
    : null;

  // Recovery trend (simplified)
  const recoveryTrend: 'improving' | 'stable' | 'declining' = 'stable';

  // Calculate adherence
  const adherenceScore = sessionCompletionRate;

  return {
    sessionsScheduled,
    sessionsCompleted,
    sessionCompletionRate,
    averagePain,
    painTrend,
    averageRecovery,
    recoveryTrend,
    adherenceScore
  };
}

async function calculateGoalsProgress(
  supabase: any,
  patientId: string,
  weekStart: string,
  weekEnd: string
): Promise<GoalProgress[]> {
  const { data: goals } = await supabase
    .from('patient_goals')
    .select('*')
    .eq('patient_id', patientId)
    .eq('status', 'active');

  if (!goals || goals.length === 0) {
    return [];
  }

  return goals.map((goal: any) => {
    const targetValue = goal.target_value || 100;
    const currentValue = goal.current_value || 0;
    const percentComplete = targetValue > 0
      ? Math.min((currentValue / targetValue) * 100, 100)
      : 0;

    // Determine trend based on progress history (simplified)
    let trend: 'improving' | 'stable' | 'declining' = 'stable';
    if (goal.previous_value !== undefined && goal.previous_value !== null) {
      if (currentValue > goal.previous_value) trend = 'improving';
      else if (currentValue < goal.previous_value) trend = 'declining';
    }

    return {
      id: goal.id,
      goal_name: goal.name || goal.goal_name || 'Unnamed Goal',
      target_value: targetValue,
      current_value: currentValue,
      percent_complete: Math.round(percentComplete),
      trend
    };
  });
}

async function calculateAIStats(
  supabase: any,
  patientId: string,
  weekStart: string,
  weekEnd: string
): Promise<{ adopted: number; total: number }> {
  // Query AI conversations/recommendations for the week
  const { data: recommendations } = await supabase
    .from('ai_conversations')
    .select('id, user_accepted')
    .eq('patient_id', patientId)
    .gte('created_at', weekStart)
    .lte('created_at', weekEnd + 'T23:59:59');

  if (!recommendations || recommendations.length === 0) {
    return { adopted: 0, total: 0 };
  }

  const total = recommendations.length;
  const adopted = recommendations.filter((r: any) => r.user_accepted === true).length;

  return { adopted, total };
}

function generateHighlights(
  metrics: any,
  goalsProgress: GoalProgress[]
): {
  achievements: string[];
  concerns: string[];
  recommendations: string[];
} {
  const achievements: string[] = [];
  const concerns: string[] = [];
  const recommendations: string[] = [];

  // Achievements
  if (metrics.sessionCompletionRate >= 1) {
    achievements.push('Completed all scheduled sessions this week');
  } else if (metrics.sessionCompletionRate >= 0.8) {
    achievements.push(`Completed ${Math.round(metrics.sessionCompletionRate * 100)}% of scheduled sessions`);
  }

  if (metrics.painTrend === 'improving') {
    achievements.push('Pain levels decreased from previous week');
  }

  if (metrics.adherenceScore >= 0.9) {
    achievements.push('Excellent adherence to prescribed exercises');
  }

  const completedGoals = goalsProgress.filter(g => g.percent_complete >= 100);
  if (completedGoals.length > 0) {
    achievements.push(`Completed ${completedGoals.length} goal(s) this week`);
  }

  const improvingGoals = goalsProgress.filter(g => g.trend === 'improving');
  if (improvingGoals.length > 0) {
    achievements.push(`${improvingGoals.length} goal(s) showing improvement`);
  }

  // Concerns
  if (metrics.sessionCompletionRate < 0.5) {
    concerns.push('Session completion rate below 50%');
  }

  if (metrics.painTrend === 'declining') {
    concerns.push('Pain levels increased compared to previous week');
  }

  if (metrics.averagePain !== null && metrics.averagePain >= 7) {
    concerns.push('High average pain level reported');
  }

  const decliningGoals = goalsProgress.filter(g => g.trend === 'declining');
  if (decliningGoals.length > 0) {
    concerns.push(`${decliningGoals.length} goal(s) showing regression`);
  }

  // Recommendations
  if (metrics.sessionCompletionRate < 0.8) {
    recommendations.push('Consider scheduling reminder notifications for sessions');
  }

  if (metrics.painTrend === 'declining' || (metrics.averagePain !== null && metrics.averagePain >= 6)) {
    recommendations.push('Review exercise intensity and consider modifications');
  }

  if (metrics.adherenceScore < 0.7) {
    recommendations.push('Follow up with patient about barriers to adherence');
  }

  if (goalsProgress.length > 0) {
    const avgProgress = goalsProgress.reduce((sum, g) => sum + g.percent_complete, 0) / goalsProgress.length;
    if (avgProgress >= 80) {
      recommendations.push('Consider setting new challenging goals');
    } else if (avgProgress < 50) {
      recommendations.push('Review goal difficulty and timeline expectations');
    }
  }

  // Default positive recommendation
  if (achievements.length >= 2 && concerns.length === 0) {
    recommendations.push('Maintain current protocol - patient is progressing well');
  }

  return { achievements, concerns, recommendations };
}

async function sendEmailNotification(
  supabase: any,
  patient: any,
  report: any
): Promise<void> {
  // This would integrate with an email service like SendGrid or Postmark
  // For now, just log the intent
  console.log(`Would send email notification for report ${report.id} to therapist ${report.therapist_id}`);

  // In production, you would:
  // 1. Fetch therapist email
  // 2. Generate email HTML with report summary
  // 3. Send via email service

  // Example:
  // const { data: therapist } = await supabase
  //   .from('therapist_profiles')
  //   .select('email, first_name')
  //   .eq('user_id', report.therapist_id)
  //   .single();
  //
  // await sendgrid.send({
  //   to: therapist.email,
  //   subject: `Weekly Report Ready: ${patient.first_name} ${patient.last_name}`,
  //   html: generateEmailHTML(report, patient)
  // });
}

/* ============================================================================
   DEPLOYMENT INSTRUCTIONS
   ============================================================================

   1. Deploy this Edge Function:
      ```bash
      supabase functions deploy generate-weekly-report
      ```

   2. Test locally:
      ```bash
      supabase functions serve generate-weekly-report
      ```

   3. Test with curl:
      ```bash
      curl -X POST http://localhost:54321/functions/v1/generate-weekly-report \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer YOUR_ANON_KEY" \
        -d '{
          "patient_id": "uuid-here",
          "week_start_date": "2026-02-01",
          "week_end_date": "2026-02-07"
        }'
      ```

   4. Set up cron job for automatic Monday 8am generation:
      ```sql
      SELECT cron.schedule(
        'generate-weekly-reports-monday',
        '0 8 * * 1', -- Every Monday at 8 AM
        $$
        SELECT net.http_post(
          url := 'https://your-project.supabase.co/functions/v1/generate-weekly-report',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'Authorization', 'Bearer ' || current_setting('app.service_role_key')
          ),
          body := jsonb_build_object(
            'generate_all', true,
            'trigger_type', 'cron'
          )
        );
        $$
      );
      ```

   ============================================================================
*/
