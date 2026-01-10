// Build 69 Agent 12: Send Session Reminders Cron Job
// Automatically sends reminder notifications 24 hours before scheduled sessions
// Designed to run as a cron job (daily at midnight or every 6 hours)

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ScheduledSession {
  id: string
  patient_id: string
  session_id: string
  scheduled_date: string
  scheduled_time: string
  status: string
  reminder_sent: boolean
  patient: {
    id: string
    user_id: string
    first_name: string
    last_name: string
  }
  session: {
    id: string
    name: string
  }
}

interface NotificationPayload {
  user_id: string
  title: string
  message: string
  type: string
  data: any
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify cron secret for security (prevents unauthorized calls)
    const cronSecret = req.headers.get('x-cron-secret')
    const expectedSecret = Deno.env.get('CRON_SECRET') || 'your-cron-secret'

    if (cronSecret !== expectedSecret) {
      console.error('Invalid cron secret')
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Initialize Supabase client with service role (bypasses RLS)
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    console.log('Starting session reminder cron job...')

    // Calculate reminder window (24 hours from now, with 1 hour buffer)
    const now = new Date()
    const reminderStart = new Date(now.getTime() + 23 * 60 * 60 * 1000) // 23 hours
    const reminderEnd = new Date(now.getTime() + 25 * 60 * 60 * 1000) // 25 hours

    const reminderDateStart = formatDateOnly(reminderStart)
    const reminderDateEnd = formatDateOnly(reminderEnd)

    console.log(`Checking sessions between ${reminderDateStart} and ${reminderDateEnd}`)

    // Fetch sessions that need reminders (24 hours before)
    const { data: sessions, error: fetchError } = await supabase
      .from('scheduled_sessions')
      .select(`
        id,
        patient_id,
        session_id,
        scheduled_date,
        scheduled_time,
        status,
        reminder_sent,
        patients!inner (
          id,
          user_id,
          first_name,
          last_name
        ),
        sessions!inner (
          id,
          name
        )
      `)
      .eq('status', 'scheduled')
      .eq('reminder_sent', false)
      .gte('scheduled_date', reminderDateStart)
      .lte('scheduled_date', reminderDateEnd)

    if (fetchError) {
      console.error('Failed to fetch sessions:', fetchError)
      return new Response(
        JSON.stringify({
          error: 'Failed to fetch sessions',
          details: fetchError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log(`Found ${sessions?.length || 0} sessions needing reminders`)

    if (!sessions || sessions.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No sessions need reminders at this time',
          reminders_sent: 0
        }),
        {
          status: 200,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Send reminders for each session
    const results = []
    for (const session of sessions as any[]) {
      try {
        // Format reminder message
        const reminderMessage = formatReminderMessage(session)

        // Create notification
        const notification: NotificationPayload = {
          user_id: session.patients.user_id,
          title: 'Workout Reminder',
          message: reminderMessage,
          type: 'session_reminder',
          data: {
            scheduled_session_id: session.id,
            session_id: session.session_id,
            scheduled_date: session.scheduled_date,
            scheduled_time: session.scheduled_time
          }
        }

        // Insert notification into database
        const { error: notifError } = await supabase
          .from('notifications')
          .insert(notification)

        if (notifError) {
          console.error(`Failed to create notification for session ${session.id}:`, notifError)
          results.push({
            scheduled_session_id: session.id,
            success: false,
            error: notifError.message
          })
          continue
        }

        // Mark reminder as sent
        const { error: updateError } = await supabase
          .from('scheduled_sessions')
          .update({ reminder_sent: true, updated_at: new Date().toISOString() })
          .eq('id', session.id)

        if (updateError) {
          console.error(`Failed to mark reminder as sent for session ${session.id}:`, updateError)
        }

        console.log(`Reminder sent for session ${session.id} to patient ${session.patients.first_name} ${session.patients.last_name}`)

        results.push({
          scheduled_session_id: session.id,
          patient_name: `${session.patients.first_name} ${session.patients.last_name}`,
          session_name: session.sessions.name,
          scheduled_date: session.scheduled_date,
          scheduled_time: session.scheduled_time,
          success: true
        })

      } catch (error) {
        console.error(`Error processing session ${session.id}:`, error)
        results.push({
          scheduled_session_id: session.id,
          success: false,
          error: error.message
        })
      }
    }

    const successCount = results.filter(r => r.success).length
    const failureCount = results.filter(r => !r.success).length

    console.log(`Reminder job complete: ${successCount} sent, ${failureCount} failed`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Sent ${successCount} reminders`,
        reminders_sent: successCount,
        reminders_failed: failureCount,
        details: results
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Unexpected error in reminder cron job:', error)
    return new Response(
      JSON.stringify({
        error: 'Internal server error',
        details: error.message,
        stack: error.stack
      }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }
})

/**
 * Format reminder message for notification
 */
function formatReminderMessage(session: any): string {
  const patientName = session.patients.first_name
  const sessionName = session.sessions.name
  const scheduledDate = new Date(session.scheduled_date)
  const scheduledTime = session.scheduled_time

  // Format date as "Tomorrow" or day of week
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)

  let dateString = 'tomorrow'
  if (scheduledDate.toDateString() !== tomorrow.toDateString()) {
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    dateString = dayNames[scheduledDate.getDay()]
  }

  // Format time (HH:MM:SS -> H:MM AM/PM)
  const timeFormatted = formatTime(scheduledTime)

  return `Hi ${patientName}! Reminder: Your "${sessionName}" workout is scheduled for ${dateString} at ${timeFormatted}.`
}

/**
 * Format time from HH:MM:SS to H:MM AM/PM
 */
function formatTime(timeString: string): string {
  const [hours, minutes] = timeString.split(':').map(Number)
  const period = hours >= 12 ? 'PM' : 'AM'
  const displayHours = hours === 0 ? 12 : hours > 12 ? hours - 12 : hours
  return `${displayHours}:${String(minutes).padStart(2, '0')} ${period}`
}

/**
 * Format date as YYYY-MM-DD
 */
function formatDateOnly(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

/* ============================================================================
   DEPLOYMENT INSTRUCTIONS
   ============================================================================

   1. Deploy this Edge Function:
      ```bash
      cd /Users/expo/Code/expo/supabase
      supabase functions deploy send-session-reminders
      ```

   2. Set the CRON_SECRET environment variable:
      ```bash
      supabase secrets set CRON_SECRET=your-secure-random-secret
      ```

   3. Set up cron job using pg_cron extension:
      ```sql
      -- Enable pg_cron extension
      CREATE EXTENSION IF NOT EXISTS pg_cron;

      -- Schedule daily at 8:00 AM (runs every day to check for next-day sessions)
      SELECT cron.schedule(
        'send-session-reminders',
        '0 8 * * *', -- Cron expression: 8:00 AM daily
        $$
        SELECT net.http_post(
          url := 'https://your-project.supabase.co/functions/v1/send-session-reminders',
          headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-cron-secret', 'your-secure-random-secret'
          ),
          body := '{}'::jsonb
        ) as request_id;
        $$
      );

      -- Alternative: Run every 6 hours for more frequent checks
      -- SELECT cron.schedule('send-session-reminders', '0 */6 * * *', ...);
      ```

   4. Create notifications table (if not exists):
      ```sql
      CREATE TABLE IF NOT EXISTS notifications (
        id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
        user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        type TEXT NOT NULL,
        data JSONB,
        read BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW(),

        -- Index for efficient queries
        CONSTRAINT fk_user FOREIGN KEY (user_id) REFERENCES auth.users(id)
      );

      CREATE INDEX idx_notifications_user ON notifications(user_id);
      CREATE INDEX idx_notifications_unread ON notifications(user_id, read) WHERE read = FALSE;

      -- Enable RLS
      ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

      -- Users can view their own notifications
      CREATE POLICY "Users view own notifications"
        ON notifications FOR SELECT
        USING (user_id = auth.uid());

      -- Users can mark their own notifications as read
      CREATE POLICY "Users update own notifications"
        ON notifications FOR UPDATE
        USING (user_id = auth.uid())
        WITH CHECK (user_id = auth.uid());
      ```

   ============================================================================
   TESTING
   ============================================================================

   Test the function locally:
   ```bash
   supabase functions serve send-session-reminders
   ```

   Send test request:
   ```bash
   curl -X POST http://localhost:54321/functions/v1/send-session-reminders \
     -H "Content-Type: application/json" \
     -H "x-cron-secret: your-secure-random-secret" \
     -d '{}'
   ```

   Test with production:
   ```bash
   curl -X POST https://your-project.supabase.co/functions/v1/send-session-reminders \
     -H "Content-Type: application/json" \
     -H "x-cron-secret: your-secure-random-secret" \
     -d '{}'
   ```

   ============================================================================
   MONITORING
   ============================================================================

   View cron job status:
   ```sql
   SELECT * FROM cron.job WHERE jobname = 'send-session-reminders';
   ```

   View cron job run history:
   ```sql
   SELECT * FROM cron.job_run_details
   WHERE jobid = (SELECT jobid FROM cron.job WHERE jobname = 'send-session-reminders')
   ORDER BY start_time DESC
   LIMIT 10;
   ```

   Delete cron job (if needed):
   ```sql
   SELECT cron.unschedule('send-session-reminders');
   ```

   ============================================================================
*/
