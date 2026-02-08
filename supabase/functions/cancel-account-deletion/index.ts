// cancel-account-deletion Edge Function
// Cancels a pending account deletion request
// Called from AccountDeletionViewModel.swift

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from '../_shared/errors.ts'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

interface CancelDeletionRequest {
  user_id: string
}

interface CancelDeletionResponse {
  success: boolean
  message: string
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
    const body: CancelDeletionRequest = await req.json()
    const { user_id } = body

    // Validate user_id is provided
    if (!user_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'user_id is required'
        } as CancelDeletionResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Critical: user_id must match authenticated user
    // Users can only cancel their own deletion request
    if (user_id !== authUser.user_id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Forbidden: Cannot cancel another user\'s deletion request'
        } as CancelDeletionResponse),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role for admin operations
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    // Get the patient record for this user
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .select('id')
      .eq('user_id', user_id)
      .maybeSingle()

    if (patientError) {
      console.error('Error fetching patient:', patientError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch patient record'
        } as CancelDeletionResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!patient) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Patient record not found'
        } as CancelDeletionResponse),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Try to cancel via account_deletion_requests table first
    const { data: deletionRequest, error: requestError } = await supabase
      .from('account_deletion_requests')
      .update({
        status: 'cancelled',
        cancelled_at: new Date().toISOString()
      })
      .eq('user_id', user_id)
      .eq('status', 'pending')
      .select()
      .maybeSingle()

    if (requestError) {
      // If table doesn't exist, try to clear deletion status on patient directly
      console.warn('account_deletion_requests table may not exist, clearing patient status directly:', requestError)

      const { error: updateError } = await supabase
        .from('patients')
        .update({
          deletion_requested_at: null,
          scheduled_deletion_at: null,
          deletion_status: null
        })
        .eq('id', patient.id)
        .eq('deletion_status', 'pending')

      if (updateError) {
        console.error('Error cancelling patient deletion:', updateError)
        return new Response(
          JSON.stringify({
            success: false,
            error: 'Failed to cancel account deletion'
          } as CancelDeletionResponse),
          { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Also clear deletion status on patient record if it was set
    await supabase
      .from('patients')
      .update({
        deletion_requested_at: null,
        scheduled_deletion_at: null,
        deletion_status: null
      })
      .eq('id', patient.id)

    // Reactivate push notification tokens for this user
    await supabase
      .from('push_notification_tokens')
      .update({ is_active: true })
      .eq('user_id', user_id)

    // Log the cancellation for audit
    console.log(`[cancel-account-deletion] Account deletion cancelled for user ${user_id}, patient ${patient.id}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Account deletion request has been cancelled. Your account is now active again.'
      } as CancelDeletionResponse),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[cancel-account-deletion] Error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error'
      } as CancelDeletionResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
