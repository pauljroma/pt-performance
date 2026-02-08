// activate-deload Edge Function
// Activates a deload period for a patient based on a recommendation
// Called from DeloadRecommendationService.swift

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from '../_shared/errors.ts'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

interface ActivateDeloadRequest {
  recommendation_id?: string
  recommendationId?: string  // Alternative camelCase naming
  start_date?: string
  startDate?: string  // Alternative camelCase naming
  patient_id?: string
  patientId?: string  // Alternative camelCase naming
  // Optional overrides
  duration_days?: number
  durationDays?: number
  load_reduction_pct?: number
  loadReductionPct?: number
  volume_reduction_pct?: number
  volumeReductionPct?: number
  focus?: 'technique' | 'mobility' | 'active_recovery' | 'complete_rest'
}

interface ActivateDeloadResponse {
  success: boolean
  message?: string
  deload_period_id?: string
  start_date?: string
  end_date?: string
  load_reduction_pct?: number
  volume_reduction_pct?: number
  focus?: string
  days_remaining?: number
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
    const body: ActivateDeloadRequest = await req.json()

    // Support both naming conventions
    const recommendationId = body.recommendation_id || body.recommendationId
    const startDateStr = body.start_date || body.startDate
    const patientIdFromBody = body.patient_id || body.patientId
    const durationDays = body.duration_days || body.durationDays
    const loadReductionPct = body.load_reduction_pct || body.loadReductionPct
    const volumeReductionPct = body.volume_reduction_pct || body.volumeReductionPct
    const focus = body.focus

    // Validate recommendation_id is provided
    if (!recommendationId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'recommendation_id is required'
        } as ActivateDeloadResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    // Get the patient record for this user
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .select('id')
      .eq('user_id', authUser.user_id)
      .maybeSingle()

    if (patientError) {
      console.error('Error fetching patient:', patientError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch patient record'
        } as ActivateDeloadResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!patient) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Patient record not found'
        } as ActivateDeloadResponse),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get the recommendation
    const { data: recommendation, error: recError } = await supabase
      .from('deload_recommendations')
      .select('*')
      .eq('id', recommendationId)
      .maybeSingle()

    if (recError) {
      console.error('Error fetching recommendation:', recError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to fetch recommendation'
        } as ActivateDeloadResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    if (!recommendation) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Recommendation not found'
        } as ActivateDeloadResponse),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify the recommendation belongs to this patient
    if (recommendation.patient_id !== patient.id) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Forbidden: This recommendation does not belong to your account'
        } as ActivateDeloadResponse),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if recommendation is still pending
    if (recommendation.status !== 'pending') {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Recommendation has already been ${recommendation.status}`
        } as ActivateDeloadResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if patient already has an active deload
    const { data: existingDeload } = await supabase
      .from('active_deloads')
      .select('id, start_date, end_date')
      .eq('patient_id', patient.id)
      .eq('is_active', true)
      .maybeSingle()

    if (existingDeload) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'You already have an active deload period',
          deload_period_id: existingDeload.id,
          start_date: existingDeload.start_date,
          end_date: existingDeload.end_date
        } as ActivateDeloadResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Calculate deload period dates
    const startDate = startDateStr
      ? new Date(startDateStr)
      : (recommendation.suggested_start_date
        ? new Date(recommendation.suggested_start_date)
        : new Date())

    const duration = durationDays || recommendation.duration_days || 7
    const endDate = new Date(startDate)
    endDate.setDate(endDate.getDate() + duration)

    // Use values from recommendation or overrides
    const finalLoadReduction = loadReductionPct ?? recommendation.load_reduction_pct ?? 50
    const finalVolumeReduction = volumeReductionPct ?? recommendation.volume_reduction_pct ?? 40
    const finalFocus = focus || recommendation.focus || 'active_recovery'

    // Create the active deload record
    const { data: deloadPeriod, error: createError } = await supabase
      .from('active_deloads')
      .insert({
        patient_id: patient.id,
        recommendation_id: recommendationId,
        start_date: startDate.toISOString().split('T')[0],
        end_date: endDate.toISOString().split('T')[0],
        load_reduction_pct: finalLoadReduction,
        volume_reduction_pct: finalVolumeReduction,
        focus: finalFocus,
        is_active: true
      })
      .select()
      .single()

    if (createError) {
      console.error('Error creating deload period:', createError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to create deload period'
        } as ActivateDeloadResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Update recommendation status to accepted
    const { error: updateError } = await supabase
      .from('deload_recommendations')
      .update({
        status: 'accepted',
        accepted_at: new Date().toISOString()
      })
      .eq('id', recommendationId)

    if (updateError) {
      console.error('Error updating recommendation status:', updateError)
      // Don't fail the request, the deload period was created
    }

    // Calculate days remaining
    const today = new Date()
    const daysRemaining = Math.ceil((endDate.getTime() - today.getTime()) / (1000 * 60 * 60 * 24))

    console.log(`[activate-deload] Created deload period ${deloadPeriod.id} for patient ${patient.id}. Start: ${startDate.toISOString().split('T')[0]}, End: ${endDate.toISOString().split('T')[0]}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Deload period activated successfully',
        deload_period_id: deloadPeriod.id,
        start_date: deloadPeriod.start_date,
        end_date: deloadPeriod.end_date,
        load_reduction_pct: deloadPeriod.load_reduction_pct,
        volume_reduction_pct: deloadPeriod.volume_reduction_pct,
        focus: deloadPeriod.focus,
        days_remaining: daysRemaining
      } as ActivateDeloadResponse),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[activate-deload] Error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error'
      } as ActivateDeloadResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
