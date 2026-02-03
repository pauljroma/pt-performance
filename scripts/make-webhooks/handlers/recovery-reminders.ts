/**
 * Recovery Reminders Webhook Handler
 *
 * Supabase Edge Function to handle recovery reminder logic.
 * Called hourly by Make.com to check and send recovery reminders.
 *
 * Make.com Scenario: Recovery Reminder System
 */

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

interface RecoveryReminderConfig {
  supabaseUrl: string;
  supabaseServiceKey: string;
  supabaseAnonKey: string;
  sendgridApiKey: string;
}

interface PatientRecoveryPreferences {
  id: string;
  full_name: string;
  email: string;
  preferred_recovery_activities: string[];
  recovery_reminder_hour: number;
  recovery_reminder_days: number[]; // 0-6, Sunday-Saturday
  timezone: string;
  last_workout_type?: string;
  today_readiness?: number;
}

interface RecoveryStreak {
  current_streak: number;
  longest_streak: number;
  last_recovery_date: string;
}

interface RecoveryRecommendation {
  recommended_activity: string;
  recommended_duration: string;
  benefits: string[];
  intensity: 'light' | 'moderate' | 'active';
}

interface MilestoneInfo {
  milestone_reached: boolean;
  milestone_days?: number;
  milestone_title?: string;
  milestone_message?: string;
  achievement_name?: string;
  achievement_description?: string;
}

/**
 * Main handler for recovery reminders batch
 */
export async function handleRecoveryRemindersBatch(
  config: RecoveryReminderConfig
): Promise<{
  success: boolean;
  reminders_sent: number;
  emails_sent: number;
  streaks_updated: number;
  milestones_reached: number;
}> {
  const supabase = createClient(config.supabaseUrl, config.supabaseServiceKey);

  const now = new Date();
  const currentHour = now.getHours();
  const currentDate = now.toISOString().split('T')[0];
  const dayOfWeek = now.getDay();

  let remindersSent = 0;
  let emailsSent = 0;
  let streaksUpdated = 0;
  let milestonesReached = 0;

  try {
    // Step 1: Get patients due for recovery reminder at this hour
    const { data: patients, error: patientsError } = await supabase.rpc(
      'get_patients_due_for_recovery_reminder',
      {
        p_current_hour: currentHour,
        p_current_date: currentDate,
        p_day_of_week: dayOfWeek,
      }
    );

    if (patientsError) {
      throw new Error(`Failed to fetch patients: ${patientsError.message}`);
    }

    if (!patients || patients.length === 0) {
      console.log(`No patients due for recovery reminder at hour ${currentHour}`);
      return {
        success: true,
        reminders_sent: 0,
        emails_sent: 0,
        streaks_updated: 0,
        milestones_reached: 0,
      };
    }

    // Step 2: Process each patient
    for (const patient of patients as PatientRecoveryPreferences[]) {
      try {
        // Check if recovery already logged today
        const { data: existingRecovery } = await supabase
          .from('recovery_sessions')
          .select('id')
          .eq('patient_id', patient.id)
          .eq('logged_date', currentDate);

        if (existingRecovery && existingRecovery.length > 0) {
          // Recovery logged - update streak
          await updateRecoveryStreak(supabase, patient.id);
          streaksUpdated++;

          // Check for milestones
          const milestone = await checkRecoveryMilestone(supabase, patient.id);
          if (milestone.milestone_reached) {
            await sendMilestoneCelebration(patient, milestone, config);
            await awardAchievement(supabase, patient.id, milestone);
            milestonesReached++;
          }
          continue;
        }

        // Get patient's recovery streak
        const streak = await getRecoveryStreak(supabase, patient.id);

        // Get AI recommendation
        const recommendation = await getRecoveryRecommendation(
          patient,
          streak,
          config
        );

        // Generate reminder message
        const message = generateReminderMessage(streak, recommendation);

        // Send push notification
        await sendRecoveryPush(
          patient.id,
          message.title,
          message.body,
          recommendation,
          streak.current_streak,
          config
        );
        remindersSent++;

        // Check if we should also send email (second reminder)
        const { data: previousReminders } = await supabase
          .from('recovery_reminders')
          .select('id')
          .eq('patient_id', patient.id)
          .eq('reminder_date', currentDate);

        if (previousReminders && previousReminders.length >= 1) {
          // This is the second reminder - send email too
          await sendRecoveryEmail(patient, streak, recommendation, config);
          emailsSent++;
        }

        // Log the reminder
        await supabase.from('recovery_reminders').insert({
          patient_id: patient.id,
          reminder_date: currentDate,
          reminder_hour: currentHour,
          channel: previousReminders && previousReminders.length >= 1 ? 'push_and_email' : 'push',
          current_streak: streak.current_streak,
          recommended_activity: recommendation.recommended_activity,
          sent_at: new Date().toISOString(),
        });

        // Update patient's last reminder timestamp
        await supabase
          .from('patients')
          .update({
            last_recovery_reminder_at: new Date().toISOString(),
            recovery_reminders_today: (previousReminders?.length || 0) + 1,
          })
          .eq('id', patient.id);
      } catch (patientError) {
        console.error(`Error processing patient ${patient.id}:`, patientError);
        // Continue with other patients
      }
    }

    // Log batch results
    await supabase.from('audit_logs').insert({
      action: 'recovery_reminder_batch',
      entity_type: 'system',
      entity_id: null,
      metadata: {
        hour: currentHour,
        date: currentDate,
        patients_checked: patients.length,
        reminders_sent: remindersSent,
        emails_sent: emailsSent,
        streaks_updated: streaksUpdated,
        milestones_reached: milestonesReached,
      },
    });

    return {
      success: true,
      reminders_sent: remindersSent,
      emails_sent: emailsSent,
      streaks_updated: streaksUpdated,
      milestones_reached: milestonesReached,
    };
  } catch (error) {
    console.error('Recovery reminders batch failed:', error);
    return {
      success: false,
      reminders_sent: remindersSent,
      emails_sent: emailsSent,
      streaks_updated: streaksUpdated,
      milestones_reached: milestonesReached,
    };
  }
}

/**
 * Get patient's current recovery streak
 */
async function getRecoveryStreak(
  supabase: ReturnType<typeof createClient>,
  patientId: string
): Promise<RecoveryStreak> {
  const { data } = await supabase.rpc('get_patient_recovery_streak', {
    p_patient_id: patientId,
  });

  return data || {
    current_streak: 0,
    longest_streak: 0,
    last_recovery_date: null,
  };
}

/**
 * Update recovery streak after logging
 */
async function updateRecoveryStreak(
  supabase: ReturnType<typeof createClient>,
  patientId: string
): Promise<void> {
  await supabase.rpc('update_recovery_streak', {
    p_patient_id: patientId,
  });
}

/**
 * Check for recovery streak milestones
 */
async function checkRecoveryMilestone(
  supabase: ReturnType<typeof createClient>,
  patientId: string
): Promise<MilestoneInfo> {
  const { data } = await supabase.rpc('check_recovery_streak_milestone', {
    p_patient_id: patientId,
  });

  return data || { milestone_reached: false };
}

/**
 * Get AI-powered recovery recommendation
 */
async function getRecoveryRecommendation(
  patient: PatientRecoveryPreferences,
  streak: RecoveryStreak,
  config: RecoveryReminderConfig
): Promise<RecoveryRecommendation> {
  try {
    const response = await fetch(
      `${config.supabaseUrl}/functions/v1/ai-recovery-recommendation`,
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${config.supabaseAnonKey}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          patient_id: patient.id,
          context: {
            current_streak: streak.current_streak,
            preferred_activities: patient.preferred_recovery_activities,
            last_workout_type: patient.last_workout_type,
            readiness_score: patient.today_readiness,
          },
        }),
      }
    );

    if (response.ok) {
      return response.json();
    }
  } catch (error) {
    console.error('AI recommendation failed, using fallback:', error);
  }

  // Fallback recommendation
  const activities = patient.preferred_recovery_activities || ['stretching', 'foam rolling'];
  return {
    recommended_activity: activities[Math.floor(Math.random() * activities.length)],
    recommended_duration: '15-20 minutes',
    benefits: ['Improved flexibility', 'Reduced muscle tension', 'Better recovery'],
    intensity: 'light',
  };
}

/**
 * Generate reminder message based on streak
 */
function generateReminderMessage(
  streak: RecoveryStreak,
  recommendation: RecoveryRecommendation
): { title: string; body: string; atRisk: boolean } {
  const { current_streak } = streak;
  const { recommended_activity, recommended_duration } = recommendation;

  let title: string;
  let body: string;

  if (current_streak === 0) {
    title = 'Time for Recovery';
    body = `Start building your recovery streak! Try ${recommended_duration} of ${recommended_activity} today.`;
  } else if (current_streak < 7) {
    title = `${current_streak} Day Streak!`;
    body = `Keep your recovery streak alive with ${recommended_duration} of ${recommended_activity}.`;
  } else if (current_streak < 30) {
    title = `${current_streak} Day Streak!`;
    body = `Amazing commitment! ${recommended_activity} will help maintain your ${current_streak}-day streak.`;
  } else {
    title = `${current_streak} Day Streak Champion!`;
    body = `Incredible! Don't break your ${current_streak}-day streak. ${recommended_duration} of ${recommended_activity} awaits.`;
  }

  return {
    title,
    body,
    atRisk: current_streak > 0,
  };
}

/**
 * Send recovery reminder push notification
 */
async function sendRecoveryPush(
  patientId: string,
  title: string,
  body: string,
  recommendation: RecoveryRecommendation,
  currentStreak: number,
  config: RecoveryReminderConfig
): Promise<void> {
  await fetch(
    `${config.supabaseUrl}/functions/v1/send-push-notification`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.supabaseAnonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        patient_id: patientId,
        title,
        body,
        data: {
          screen: 'recovery',
          action: 'log_recovery',
          recommended_activity: recommendation.recommended_activity,
          recommended_duration: recommendation.recommended_duration,
          current_streak: currentStreak,
        },
        priority: currentStreak > 0 ? 'high' : 'normal',
      }),
    }
  );
}

/**
 * Send recovery reminder email
 */
async function sendRecoveryEmail(
  patient: PatientRecoveryPreferences,
  streak: RecoveryStreak,
  recommendation: RecoveryRecommendation,
  config: RecoveryReminderConfig
): Promise<void> {
  const firstName = patient.full_name.split(' ')[0];

  await fetch('https://api.sendgrid.com/v3/mail/send', {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${config.sendgridApiKey}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      personalizations: [
        {
          to: [{ email: patient.email }],
          dynamic_template_data: {
            first_name: firstName,
            current_streak: streak.current_streak,
            recommended_activity: recommendation.recommended_activity,
            recommended_duration: recommendation.recommended_duration,
            benefits: recommendation.benefits,
            streak_at_risk: streak.current_streak > 0,
            quick_log_url: 'https://app.ptperformance.app/recovery/quick-log',
            unsubscribe_url: 'https://app.ptperformance.app/settings/notifications',
          },
        },
      ],
      from: {
        email: 'recovery@ptperformance.app',
        name: 'PT Performance',
      },
      template_id: 'd-recovery-reminder-template-id',
      tracking_settings: {
        click_tracking: { enable: true },
        open_tracking: { enable: true },
      },
    }),
  });
}

/**
 * Send milestone celebration notification
 */
async function sendMilestoneCelebration(
  patient: PatientRecoveryPreferences,
  milestone: MilestoneInfo,
  config: RecoveryReminderConfig
): Promise<void> {
  await fetch(
    `${config.supabaseUrl}/functions/v1/send-push-notification`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${config.supabaseAnonKey}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        patient_id: patient.id,
        title: milestone.milestone_title,
        body: milestone.milestone_message,
        data: {
          screen: 'achievements',
          achievement_type: 'recovery_streak',
          milestone: milestone.milestone_days,
        },
      }),
    }
  );
}

/**
 * Award achievement badge for milestone
 */
async function awardAchievement(
  supabase: ReturnType<typeof createClient>,
  patientId: string,
  milestone: MilestoneInfo
): Promise<void> {
  await supabase.from('patient_achievements').insert({
    patient_id: patientId,
    achievement_type: 'recovery_streak',
    achievement_name: milestone.achievement_name,
    achievement_description: milestone.achievement_description,
    milestone_value: milestone.milestone_days,
    earned_at: new Date().toISOString(),
  });
}

// Edge function handler
serve(async (req) => {
  try {
    const config: RecoveryReminderConfig = {
      supabaseUrl: Deno.env.get('SUPABASE_URL') || '',
      supabaseServiceKey: Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') || '',
      supabaseAnonKey: Deno.env.get('SUPABASE_ANON_KEY') || '',
      sendgridApiKey: Deno.env.get('SENDGRID_API_KEY') || '',
    };

    const result = await handleRecoveryRemindersBatch(config);

    return new Response(JSON.stringify(result), {
      headers: { 'Content-Type': 'application/json' },
      status: result.success ? 200 : 500,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 500,
    });
  }
});
