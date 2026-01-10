// Export Patient Data - HIPAA-compliant data export API
// Allows patients to export their complete health data in various formats

import { serve } from 'https://deno.land/std@0.177.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.39.0'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface ExportRequest {
  patient_id: string
  export_format?: 'json' | 'csv' | 'pdf'
  include_sessions?: boolean
  include_exercises?: boolean
  include_notes?: boolean
  include_readiness?: boolean
  include_analytics?: boolean
  date_range_start?: string
  date_range_end?: string
}

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Initialize Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_ANON_KEY') ?? '',
      {
        global: {
          headers: { Authorization: req.headers.get('Authorization')! },
        },
      }
    )

    // Get authenticated user
    const {
      data: { user },
      error: userError,
    } = await supabaseClient.auth.getUser()

    if (userError || !user) {
      return new Response(
        JSON.stringify({ error: 'Unauthorized' }),
        {
          status: 401,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Parse request body
    const requestData: ExportRequest = await req.json()

    if (!requestData.patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id is required' }),
        {
          status: 400,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Verify user has access to this patient's data
    const { data: patient, error: patientError } = await supabaseClient
      .from('patients')
      .select('id, user_id, therapist_id')
      .eq('id', requestData.patient_id)
      .single()

    if (patientError || !patient) {
      return new Response(
        JSON.stringify({ error: 'Patient not found' }),
        {
          status: 404,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Check if user is the patient or their therapist
    const isPatient = patient.user_id === user.id

    let isTherapist = false
    if (!isPatient) {
      const { data: therapist } = await supabaseClient
        .from('therapists')
        .select('id')
        .eq('id', patient.therapist_id)
        .eq('user_id', user.id)
        .single()

      isTherapist = !!therapist
    }

    if (!isPatient && !isTherapist) {
      return new Response(
        JSON.stringify({ error: 'Insufficient permissions' }),
        {
          status: 403,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Call the database function to export data
    const { data: exportData, error: exportError } = await supabaseClient
      .rpc('export_patient_data', {
        p_patient_id: requestData.patient_id,
        p_include_sessions: requestData.include_sessions ?? true,
        p_include_exercises: requestData.include_exercises ?? true,
        p_include_notes: requestData.include_notes ?? true,
        p_include_readiness: requestData.include_readiness ?? true,
        p_include_analytics: requestData.include_analytics ?? true,
        p_date_range_start: requestData.date_range_start || null,
        p_date_range_end: requestData.date_range_end || null,
      })

    if (exportError) {
      console.error('Export error:', exportError)
      return new Response(
        JSON.stringify({ error: 'Failed to export data', details: exportError.message }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Format response based on requested format
    const exportFormat = requestData.export_format || 'json'

    if (exportFormat === 'json') {
      // Return JSON directly
      return new Response(
        JSON.stringify(exportData, null, 2),
        {
          status: 200,
          headers: {
            ...corsHeaders,
            'Content-Type': 'application/json',
            'Content-Disposition': `attachment; filename="patient-data-${requestData.patient_id}-${new Date().toISOString().split('T')[0]}.json"`,
          },
        }
      )
    } else if (exportFormat === 'csv') {
      // Convert to CSV format
      const csv = convertToCSV(exportData)
      return new Response(csv, {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'text/csv',
          'Content-Disposition': `attachment; filename="patient-data-${requestData.patient_id}-${new Date().toISOString().split('T')[0]}.csv"`,
        },
      })
    } else if (exportFormat === 'pdf') {
      // PDF generation would require additional libraries
      return new Response(
        JSON.stringify({ error: 'PDF format not yet implemented' }),
        {
          status: 501,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    return new Response(
      JSON.stringify({ error: 'Invalid export format' }),
      {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})

/**
 * Convert patient data to CSV format
 * Flattens nested data structures into CSV rows
 */
function convertToCSV(data: any): string {
  const lines: string[] = []

  // Patient Info
  lines.push('PATIENT INFORMATION')
  lines.push('Field,Value')
  if (data.patient) {
    Object.entries(data.patient).forEach(([key, value]) => {
      lines.push(`"${key}","${value}"`)
    })
  }
  lines.push('')

  // Programs
  if (data.programs && data.programs.length > 0) {
    lines.push('PROGRAMS')
    const programHeaders = Object.keys(data.programs[0])
    lines.push(programHeaders.map(h => `"${h}"`).join(','))
    data.programs.forEach((program: any) => {
      const row = programHeaders.map(h => `"${program[h] ?? ''}"`).join(',')
      lines.push(row)
    })
    lines.push('')
  }

  // Sessions
  if (data.sessions && data.sessions.length > 0) {
    lines.push('SESSIONS')
    const sessionHeaders = Object.keys(data.sessions[0])
    lines.push(sessionHeaders.map(h => `"${h}"`).join(','))
    data.sessions.forEach((session: any) => {
      const row = sessionHeaders.map(h => `"${session[h] ?? ''}"`).join(',')
      lines.push(row)
    })
    lines.push('')
  }

  // Exercise Logs
  if (data.exercise_logs && data.exercise_logs.length > 0) {
    lines.push('EXERCISE LOGS')
    const exerciseHeaders = Object.keys(data.exercise_logs[0])
    lines.push(exerciseHeaders.map(h => `"${h}"`).join(','))
    data.exercise_logs.forEach((exercise: any) => {
      const row = exerciseHeaders.map(h => `"${exercise[h] ?? ''}"`).join(',')
      lines.push(row)
    })
    lines.push('')
  }

  // Notes
  if (data.notes && data.notes.length > 0) {
    lines.push('NOTES')
    const noteHeaders = Object.keys(data.notes[0])
    lines.push(noteHeaders.map(h => `"${h}"`).join(','))
    data.notes.forEach((note: any) => {
      const row = noteHeaders.map(h => `"${note[h] ?? ''}"`).join(',')
      lines.push(row)
    })
    lines.push('')
  }

  // Daily Readiness
  if (data.daily_readiness && data.daily_readiness.length > 0) {
    lines.push('DAILY READINESS')
    const readinessHeaders = Object.keys(data.daily_readiness[0])
    lines.push(readinessHeaders.map(h => `"${h}"`).join(','))
    data.daily_readiness.forEach((readiness: any) => {
      const row = readinessHeaders.map(h => `"${readiness[h] ?? ''}"`).join(',')
      lines.push(row)
    })
    lines.push('')
  }

  return lines.join('\n')
}
