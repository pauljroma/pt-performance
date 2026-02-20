// Therapist Approval Gate - Request Approval Handler
// Human-in-the-loop pattern for AI-generated workout modifications
//
// Receives a modification request, classifies risk level, creates an
// approval_request record. Low severity = auto-approved, medium+ = pending
// therapist review.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// ============================================================================
// Types
// ============================================================================

interface ApprovalRequestInput {
  patient_id: string
  request_type: 'workout_modification' | 'intensity_increase' | 'exercise_substitution' | 'program_change' | 'return_to_activity'
  title: string
  description: string
  suggested_change: Record<string, unknown>
  ai_rationale?: string
  ai_confidence?: number
  severity_override?: 'low' | 'medium' | 'high' | 'critical'
}

interface ApprovalRequestResponse {
  success: boolean
  approval_request_id: string
  status: 'pending' | 'auto_approved'
  severity: string
  requires_therapist_review: boolean
  message: string
}

// ============================================================================
// Risk Classification
// ============================================================================

/**
 * Classify the risk level of a modification request based on its type and content.
 *
 * Risk levels:
 * - low: Minor adjustments unlikely to cause harm (small load reductions, minor swaps)
 * - medium: Moderate changes that benefit from therapist review (volume changes, new exercises)
 * - high: Significant changes that require therapist approval (intensity increases, program changes)
 * - critical: Safety-sensitive changes that must be reviewed (return-to-activity, major increases)
 */
function classifyRiskLevel(
  requestType: string,
  suggestedChange: Record<string, unknown>,
  aiConfidence?: number
): 'low' | 'medium' | 'high' | 'critical' {

  // Return-to-activity is always critical -- requires clinical judgment
  if (requestType === 'return_to_activity') {
    return 'critical'
  }

  // Program changes are high severity by default
  if (requestType === 'program_change') {
    return 'high'
  }

  // Intensity increases need careful evaluation
  if (requestType === 'intensity_increase') {
    const increasePercentage = suggestedChange.increase_percentage as number | undefined
    if (increasePercentage !== undefined) {
      if (increasePercentage > 20) return 'critical'
      if (increasePercentage > 10) return 'high'
      if (increasePercentage > 5) return 'medium'
      return 'low'
    }
    return 'high' // Default for intensity increases without explicit percentage
  }

  // Exercise substitutions depend on muscle group changes
  if (requestType === 'exercise_substitution') {
    const sameMusceGroup = suggestedChange.same_muscle_group as boolean | undefined
    const painRelated = suggestedChange.pain_related as boolean | undefined

    if (painRelated) return 'high' // Pain-driven substitutions need review
    if (sameMusceGroup === true) return 'low' // Same muscle group swaps are safe
    return 'medium'
  }

  // Workout modifications depend on the specifics
  if (requestType === 'workout_modification') {
    const modificationType = suggestedChange.modification_type as string | undefined

    // Load reductions are generally safe
    if (modificationType === 'load_reduction' || modificationType === 'volume_reduction') {
      const reductionPercentage = suggestedChange.reduction_percentage as number | undefined
      if (reductionPercentage !== undefined && reductionPercentage <= 20) return 'low'
      return 'medium'
    }

    // Recovery day insertions are low risk
    if (modificationType === 'insert_recovery_day' || modificationType === 'skip_workout') {
      return 'low'
    }

    // Deload triggers are medium
    if (modificationType === 'trigger_deload') {
      return 'medium'
    }

    return 'medium'
  }

  // If AI confidence is very low, escalate
  if (aiConfidence !== undefined && aiConfidence < 0.5) {
    return 'high'
  }

  return 'medium'
}

// ============================================================================
// Handler
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const requestBody: ApprovalRequestInput = await req.json()
    const {
      patient_id,
      request_type,
      title,
      description,
      suggested_change,
      ai_rationale,
      ai_confidence,
      severity_override,
    } = requestBody

    // Validate required fields
    if (!patient_id || !request_type || !title || !description || !suggested_change) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Missing required fields: patient_id, request_type, title, description, suggested_change',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate request_type
    const validTypes = ['workout_modification', 'intensity_increase', 'exercise_substitution', 'program_change', 'return_to_activity']
    if (!validTypes.includes(request_type)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Invalid request_type. Must be one of: ${validTypes.join(', ')}`,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate ai_confidence range if provided
    if (ai_confidence !== undefined && (ai_confidence < 0 || ai_confidence > 1)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'ai_confidence must be between 0 and 1',
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client with service role for full access
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // Look up the patient to find their assigned therapist
    const { data: patient, error: patientError } = await supabaseClient
      .from('patients')
      .select('id, therapist_id, first_name, last_name')
      .eq('id', patient_id)
      .single()

    if (patientError || !patient) {
      return new Response(
        JSON.stringify({
          success: false,
          error: `Patient not found: ${patient_id}`,
        }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Classify risk level (allow override for testing or manual escalation)
    const severity = severity_override || classifyRiskLevel(request_type, suggested_change, ai_confidence)

    // Build the approval request record
    const approvalRecord = {
      patient_id,
      therapist_id: patient.therapist_id || null,
      request_type,
      severity,
      title,
      description,
      suggested_change,
      ai_rationale: ai_rationale || null,
      ai_confidence: ai_confidence ?? null,
      auto_approve_if_low_severity: true,
      expires_at: new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString(), // 72 hours
    }

    // Insert the approval request
    // The auto_approve_low_severity trigger will auto-approve if severity is 'low'
    const { data: approvalRequest, error: insertError } = await supabaseClient
      .from('approval_requests')
      .insert(approvalRecord)
      .select()
      .single()

    if (insertError) {
      console.error('Error creating approval request:', insertError)
      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to create approval request',
          details: insertError.message,
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Determine if therapist review is required
    const isAutoApproved = approvalRequest.status === 'auto_approved'
    const requiresReview = !isAutoApproved

    // Build response
    const response: ApprovalRequestResponse = {
      success: true,
      approval_request_id: approvalRequest.id,
      status: approvalRequest.status,
      severity: approvalRequest.severity,
      requires_therapist_review: requiresReview,
      message: isAutoApproved
        ? 'Change auto-approved (low severity within safe parameters).'
        : `Change requires therapist approval (${severity} severity). Your therapist has been notified.`,
    }

    console.log(
      `Approval request created: ${approvalRequest.id} | ` +
      `patient=${patient_id} | type=${request_type} | severity=${severity} | ` +
      `status=${approvalRequest.status} | therapist=${patient.therapist_id || 'none'}`
    )

    return new Response(
      JSON.stringify(response),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in request-approval:', error)
    return new Response(
      JSON.stringify({
        success: false,
        error: error.message || 'Internal server error',
        details: error.toString(),
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
