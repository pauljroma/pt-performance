// Build 69 Agent 12: Generate Scheduled Sessions Edge Function
// Auto-generates scheduled sessions when a program is created
// Triggered via webhook or API call after program creation

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.3'
import { requireAuth, createAuthenticatedClient, verifyPatientOwnership, isTherapistForPatient, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface GenerateSessionsRequest {
  program_id: string
  start_date?: string // ISO date string, defaults to tomorrow
  default_time?: string // HH:MM format, defaults to 09:00
  frequency?: 'daily' | 'weekly' | 'custom' // defaults to weekly
  custom_days?: number[] // For custom frequency: [0=Sun, 1=Mon, 2=Tue, etc]
}

interface Phase {
  id: string
  name: string
  order_index: number
  duration_weeks: number
}

interface Session {
  id: string
  phase_id: string
  name: string
  order_index: number
}

interface Program {
  id: string
  patient_id: string
  name: string
  status: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Validate JWT authentication
    const authResult = await requireAuth(req)
    if (authResult instanceof Response) return authResult
    const authUser = authResult as AuthUser

    // Initialize Supabase client with user's JWT (respects RLS)
    const supabase = createAuthenticatedClient(req)

    // Parse request
    const requestData: GenerateSessionsRequest = await req.json()

    console.log('Generate scheduled sessions request:', {
      program_id: requestData.program_id,
      start_date: requestData.start_date,
      frequency: requestData.frequency || 'weekly'
    })

    // Validate request
    if (!requestData.program_id) {
      return new Response(
        JSON.stringify({ error: 'program_id is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Fetch program details
    const { data: program, error: programError } = await supabase
      .from('programs')
      .select('id, patient_id, name, status')
      .eq('id', requestData.program_id)
      .single()

    if (programError || !program) {
      return new Response(
        JSON.stringify({ error: 'Program not found', details: programError?.message }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    // Verify ownership: user owns the patient OR is a therapist for the patient
    const isOwner = await verifyPatientOwnership(supabase, program.patient_id, authUser.user_id)
    const isTherapist = await isTherapistForPatient(supabase, program.patient_id, authUser.user_id)

    if (!isOwner && !isTherapist) {
      return new Response(
        JSON.stringify({ error: 'Forbidden', message: 'You do not have access to this program' }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Fetch all phases and sessions for the program
    const { data: phases, error: phasesError } = await supabase
      .from('phases')
      .select('id, name, order_index, duration_weeks')
      .eq('program_id', requestData.program_id)
      .order('order_index', { ascending: true })

    if (phasesError || !phases || phases.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No phases found for program', details: phasesError?.message }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log(`Found ${phases.length} phases for program`)

    // Fetch sessions for all phases
    const allSessions: Session[] = []
    for (const phase of phases) {
      const { data: sessions, error: sessionsError } = await supabase
        .from('sessions')
        .select('id, phase_id, name, order_index')
        .eq('phase_id', phase.id)
        .order('order_index', { ascending: true })

      if (!sessionsError && sessions && sessions.length > 0) {
        allSessions.push(...sessions)
        console.log(`Found ${sessions.length} sessions for phase ${phase.name}`)
      }
    }

    if (allSessions.length === 0) {
      return new Response(
        JSON.stringify({ error: 'No sessions found for program phases' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log(`Total sessions to schedule: ${allSessions.length}`)

    // Generate scheduled sessions
    const scheduledSessions = generateSchedule(
      program,
      phases,
      allSessions,
      requestData
    )

    // Insert scheduled sessions into database
    const { data: insertedSessions, error: insertError } = await supabase
      .from('scheduled_sessions')
      .insert(scheduledSessions)
      .select()

    if (insertError) {
      console.error('Failed to insert scheduled sessions:', insertError)
      return new Response(
        JSON.stringify({
          error: 'Failed to create scheduled sessions',
          details: insertError.message
        }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' }
        }
      )
    }

    console.log(`Successfully created ${insertedSessions?.length || 0} scheduled sessions`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Generated ${insertedSessions?.length || 0} scheduled sessions`,
        program_id: requestData.program_id,
        scheduled_sessions: insertedSessions
      }),
      {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )

  } catch (error) {
    console.error('Unexpected error:', error)
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
 * Generate schedule based on program structure and parameters
 */
function generateSchedule(
  program: Program,
  phases: Phase[],
  sessions: Session[],
  params: GenerateSessionsRequest
): any[] {
  const scheduledSessions: any[] = []

  // Parse start date (default to tomorrow)
  const startDate = params.start_date
    ? new Date(params.start_date)
    : new Date(Date.now() + 86400000) // tomorrow

  // Parse default time (default to 9:00 AM)
  const defaultTime = params.default_time || '09:00'

  // Determine frequency
  const frequency = params.frequency || 'weekly'
  const customDays = params.custom_days || [1, 3, 5] // Mon, Wed, Fri default

  let currentDate = new Date(startDate)
  let sessionIndex = 0

  // Group sessions by phase
  const sessionsByPhase = new Map<string, Session[]>()
  sessions.forEach(session => {
    const phaseSessions = sessionsByPhase.get(session.phase_id) || []
    phaseSessions.push(session)
    sessionsByPhase.set(session.phase_id, phaseSessions)
  })

  // Schedule sessions for each phase
  phases.forEach(phase => {
    const phaseSessions = sessionsByPhase.get(phase.id) || []
    const phaseWeeks = phase.duration_weeks || 4
    const sessionsPerWeek = calculateSessionsPerWeek(frequency, customDays)
    const totalSlots = phaseWeeks * sessionsPerWeek

    console.log(`Phase ${phase.name}: ${phaseSessions.length} sessions over ${phaseWeeks} weeks (${sessionsPerWeek} sessions/week)`)

    // Distribute sessions across available slots
    let sessionIdx = 0
    for (let week = 0; week < phaseWeeks; week++) {
      for (let slot = 0; slot < sessionsPerWeek; slot++) {
        // Get next date based on frequency
        const scheduleDate = getNextScheduleDate(currentDate, frequency, customDays, slot)

        // Assign session (round-robin if more slots than sessions)
        const session = phaseSessions[sessionIdx % phaseSessions.length]

        scheduledSessions.push({
          patient_id: program.patient_id,
          session_id: session.id,
          scheduled_date: formatDateOnly(scheduleDate),
          scheduled_time: defaultTime,
          status: 'scheduled',
          reminder_sent: false,
          notes: `${phase.name} - Week ${week + 1}`
        })

        sessionIdx++
        sessionIndex++
      }

      // Move to next week
      currentDate = new Date(currentDate.getTime() + 7 * 86400000)
    }
  })

  return scheduledSessions
}

/**
 * Calculate sessions per week based on frequency
 */
function calculateSessionsPerWeek(
  frequency: string,
  customDays: number[]
): number {
  switch (frequency) {
    case 'daily':
      return 7
    case 'weekly':
      return 3 // Default: 3 sessions per week
    case 'custom':
      return customDays.length
    default:
      return 3
  }
}

/**
 * Get next schedule date based on frequency
 */
function getNextScheduleDate(
  baseDate: Date,
  frequency: string,
  customDays: number[],
  slotIndex: number
): Date {
  const date = new Date(baseDate)

  switch (frequency) {
    case 'daily':
      // Every day
      date.setDate(date.getDate() + slotIndex)
      break

    case 'weekly':
      // Default: Mon, Wed, Fri (1, 3, 5)
      const weeklyDays = [1, 3, 5]
      const dayOfWeek = weeklyDays[slotIndex % weeklyDays.length]
      const daysUntilTarget = (dayOfWeek - date.getDay() + 7) % 7
      date.setDate(date.getDate() + daysUntilTarget)
      break

    case 'custom':
      // Use custom days array
      const customDayOfWeek = customDays[slotIndex % customDays.length]
      const customDaysUntil = (customDayOfWeek - date.getDay() + 7) % 7
      date.setDate(date.getDate() + customDaysUntil)
      break

    default:
      date.setDate(date.getDate() + slotIndex * 2) // Every other day
  }

  return date
}

/**
 * Format date as YYYY-MM-DD for Postgres DATE type
 */
function formatDateOnly(date: Date): string {
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  return `${year}-${month}-${day}`
}

/* ============================================================================
   USAGE INSTRUCTIONS
   ============================================================================

   Deploy this Edge Function:
   ```bash
   cd /Users/expo/Code/expo/supabase
   supabase functions deploy generate-scheduled-sessions
   ```

   Call from client code after creating a program:
   ```typescript
   const { data, error } = await supabase.functions.invoke('generate-scheduled-sessions', {
     body: {
       program_id: 'uuid-of-program',
       start_date: '2025-12-20', // Optional, defaults to tomorrow
       default_time: '09:00',    // Optional, defaults to 09:00
       frequency: 'weekly',      // Optional: 'daily', 'weekly', 'custom'
       custom_days: [1, 3, 5]   // Optional: for custom frequency
     }
   })
   ```

   Or trigger automatically with a database trigger:
   ```sql
   CREATE OR REPLACE FUNCTION trigger_generate_scheduled_sessions()
   RETURNS TRIGGER AS $$
   DECLARE
     function_url TEXT := 'https://your-project.supabase.co/functions/v1/generate-scheduled-sessions';
     service_key TEXT := 'your-service-role-key';
   BEGIN
     -- Only trigger for active programs
     IF NEW.status = 'active' THEN
       PERFORM net.http_post(
         url := function_url,
         headers := jsonb_build_object(
           'Content-Type', 'application/json',
           'Authorization', 'Bearer ' || service_key
         ),
         body := jsonb_build_object(
           'program_id', NEW.id,
           'frequency', 'weekly'
         )
       );
     END IF;
     RETURN NEW;
   END;
   $$ LANGUAGE plpgsql;

   CREATE TRIGGER on_program_created
   AFTER INSERT ON programs
   FOR EACH ROW
   EXECUTE FUNCTION trigger_generate_scheduled_sessions();
   ```

   ============================================================================
   TESTING
   ============================================================================

   Test locally:
   ```bash
   supabase functions serve generate-scheduled-sessions
   ```

   Send test request:
   ```bash
   curl -X POST http://localhost:54321/functions/v1/generate-scheduled-sessions \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_SERVICE_KEY" \
     -d '{
       "program_id": "your-program-uuid",
       "start_date": "2025-12-20",
       "default_time": "09:00",
       "frequency": "weekly"
     }'
   ```

   ============================================================================
*/
