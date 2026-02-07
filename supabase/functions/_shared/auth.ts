// Shared authentication utilities for Supabase Edge Functions
// Provides JWT validation, ownership checks, and authenticated client creation

import { createClient, SupabaseClient } from 'https://esm.sh/@supabase/supabase-js@2'

export interface AuthUser {
  user_id: string
  email: string
}

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

/**
 * Validates the JWT token from the Authorization header.
 * Returns the user info if valid, null if invalid or missing.
 */
export async function validateJWT(req: Request): Promise<AuthUser | null> {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return null
    }

    const token = authHeader.replace('Bearer ', '')

    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

    // Create a client with the user's JWT to validate it
    const supabase = createClient(supabaseUrl, supabaseAnonKey, {
      global: {
        headers: { Authorization: `Bearer ${token}` }
      }
    })

    // getUser validates the JWT and returns user info
    const { data: { user }, error } = await supabase.auth.getUser()

    if (error || !user) {
      console.error('JWT validation failed:', error?.message)
      return null
    }

    return {
      user_id: user.id,
      email: user.email || ''
    }
  } catch (error) {
    console.error('Error validating JWT:', error)
    return null
  }
}

/**
 * Requires authentication. Returns AuthUser if valid, or a 401 Response if not.
 * Usage:
 *   const authResult = await requireAuth(req)
 *   if (authResult instanceof Response) return authResult
 *   const authUser = authResult as AuthUser
 */
export async function requireAuth(req: Request): Promise<AuthUser | Response> {
  const user = await validateJWT(req)

  if (!user) {
    return new Response(
      JSON.stringify({ error: 'Unauthorized', message: 'Valid authentication required' }),
      {
        status: 401,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      }
    )
  }

  return user
}

/**
 * Creates a Supabase client authenticated with the user's JWT.
 * This client respects RLS policies based on the authenticated user.
 */
export function createAuthenticatedClient(req: Request): SupabaseClient {
  const authHeader = req.headers.get('Authorization') || ''
  const token = authHeader.replace('Bearer ', '')

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!
  const supabaseAnonKey = Deno.env.get('SUPABASE_ANON_KEY')!

  return createClient(supabaseUrl, supabaseAnonKey, {
    global: {
      headers: { Authorization: `Bearer ${token}` }
    }
  })
}

/**
 * Verifies that the given user owns the patient record.
 * Returns true if the patient's user_id matches the provided userId.
 */
export async function verifyPatientOwnership(
  supabase: SupabaseClient,
  patientId: string,
  userId: string
): Promise<boolean> {
  try {
    const { data: patient, error } = await supabase
      .from('patients')
      .select('user_id')
      .eq('id', patientId)
      .single()

    if (error || !patient) {
      console.error('Error fetching patient for ownership check:', error?.message)
      return false
    }

    return patient.user_id === userId
  } catch (error) {
    console.error('Error verifying patient ownership:', error)
    return false
  }
}

/**
 * Checks if the user is a therapist for the given patient.
 * Returns true if the user's therapist record is linked to the patient.
 */
export async function isTherapistForPatient(
  supabase: SupabaseClient,
  patientId: string,
  userId: string
): Promise<boolean> {
  try {
    // First, find the therapist record for this user
    const { data: therapist, error: therapistError } = await supabase
      .from('therapists')
      .select('id')
      .eq('user_id', userId)
      .single()

    if (therapistError || !therapist) {
      // User is not a therapist
      return false
    }

    // Check if this therapist is linked to the patient
    const { data: patient, error: patientError } = await supabase
      .from('patients')
      .select('therapist_id')
      .eq('id', patientId)
      .single()

    if (patientError || !patient) {
      return false
    }

    return patient.therapist_id === therapist.id
  } catch (error) {
    console.error('Error checking therapist relationship:', error)
    return false
  }
}
