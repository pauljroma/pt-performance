// delete-patient-account Edge Function
// Soft-deletes patient account with 30-day grace period (GDPR Right to Erasure)
// Called from AccountDeletionViewModel.swift

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from '../_shared/errors.ts'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

interface DeleteAccountRequest {
  user_id: string
  grace_period_days?: string | number
}

interface DeleteAccountResponse {
  success: boolean
  message: string
  scheduled_deletion_date?: string
  error?: string
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

    // Parse request body
    const body: DeleteAccountRequest = await req.json()
    const { user_id, grace_period_days } = body

    // Validate user_id is provided
    if (!user_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'user_id is required'
        } as DeleteAccountResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Critical: user_id must match authenticated user
    // Users can only delete their own account
    if (user_id !== authUser.user_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Forbidden: Cannot delete another user\'s account'
        } as DeleteAccountResponse),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role for admin operations
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    // Calculate deletion date (default 30 days)
    const gracePeriod = typeof grace_period_days === 'string'
      ? parseInt(grace_period_days, 10)
      : (grace_period_days || 30)
    const deletionDate = new Date()
    deletionDate.setDate(deletionDate.getDate() + gracePeriod)
    const scheduledDeletionDate = deletionDate.toISOString()

    // Get the patient record for this user
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .select('id, email, first_name, last_name')
      .eq('user_id', user_id)
      .maybeSingle()

    if (patientError) {
      console.error('Error fetching patient:', patientError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch patient record'
        } as DeleteAccountResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!patient) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Patient record not found'
        } as DeleteAccountResponse),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if there's already a pending deletion request
    const { data: existingRequest } = await supabase
      .from('account_deletion_requests')
      .select('id, status, scheduled_deletion_at')
      .eq('user_id', user_id)
      .eq('status', 'pending')
      .maybeSingle()

    if (existingRequest) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'Account deletion already scheduled',
          scheduled_deletion_date: existingRequest.scheduled_deletion_at
        } as DeleteAccountResponse),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Create account deletion request (soft-delete approach)
    const { error: insertError } = await supabase
      .from('account_deletion_requests')
      .insert({
        user_id: user_id,
        patient_id: patient.id,
        status: 'pending',
        requested_at: new Date().toISOString(),
        scheduled_deletion_at: scheduledDeletionDate,
        grace_period_days: gracePeriod
      })

    if (insertError) {
      // If table doesn't exist, mark patient as pending deletion directly
      console.warn('account_deletion_requests table may not exist, marking patient directly:', insertError)

      const { error: updateError } = await supabase
        .from('patients')
        .update({
          deletion_requested_at: new Date().toISOString(),
          scheduled_deletion_at: scheduledDeletionDate,
          deletion_status: 'pending'
        })
        .eq('id', patient.id)

      if (updateError) {
        console.error('Error marking patient for deletion:', updateError)
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Failed to schedule account deletion'
          } as DeleteAccountResponse),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Deactivate push notification tokens for this user
    await supabase
      .from('push_notification_tokens')
      .update({ is_active: false })
      .eq('user_id', user_id)

    // Log the deletion request for audit
    console.log(`[delete-patient-account] Account deletion scheduled for user ${user_id}, patient ${patient.id}. Scheduled deletion: ${scheduledDeletionDate}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: `Your account has been scheduled for deletion on ${deletionDate.toLocaleDateString()}. You can cancel this request by logging back in within the grace period.`,
        scheduled_deletion_date: scheduledDeletionDate
      } as DeleteAccountResponse),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[delete-patient-account] Error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error'
      } as DeleteAccountResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
