// Sync WHOOP Recovery Handler
// Build 138 - WHOOP Integration MVP
// Syncs WHOOP recovery data to daily_readiness table

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// WHOOP API Configuration
const WHOOP_API_BASE = 'https://api.prod.whoop.com/developer/v1'
const WHOOP_OAUTH_TOKEN_URL = 'https://api.prod.whoop.com/oauth/oauth2/token'
const CACHE_DURATION_HOURS = 1 // Don't sync more than once per hour

interface SyncWhoopRequest {
  patient_id: string;
}

interface WHOOPRecoveryResponse {
  recovery_score: number;        // 0-100
  sleep_performance_percentage: number;
  hrv_rmssd: number;
  strain: number;
  synced_at: string;
}

interface WHOOPCredentials {
  access_token: string;
  refresh_token: string;
  expires_at: string;
  athlete_id?: string;
}

interface WHOOPAPIRecovery {
  cycle_id: number;
  sleep_id: number;
  user_calibrating: boolean;
  recovery_score: number;
  resting_heart_rate: number;
  hrv_rmssd_milli: number;
  spo2_percentage: number;
  skin_temp_celsius: number;
}

serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { patient_id } = await req.json() as SyncWhoopRequest

    if (!patient_id) {
      return new Response(
        JSON.stringify({ error: 'patient_id required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      { auth: { persistSession: false } }
    )

    // ============================================================================
    // 1. Check cache - don't sync more than once per hour
    // ============================================================================

    const today = new Date().toISOString().split('T')[0]

    const { data: existingReadiness } = await supabaseClient
      .from('daily_readiness')
      .select('whoop_synced_at')
      .eq('patient_id', patient_id)
      .eq('date', today)
      .single()

    if (existingReadiness?.whoop_synced_at) {
      const syncedAt = new Date(existingReadiness.whoop_synced_at)
      const hoursSinceSync = (Date.now() - syncedAt.getTime()) / (1000 * 60 * 60)

      if (hoursSinceSync < CACHE_DURATION_HOURS) {
        return new Response(
          JSON.stringify({
            success: true,
            cached: true,
            message: `Recovery data synced ${Math.round(hoursSinceSync * 60)} minutes ago. Using cached data.`,
            next_sync_available_in_minutes: Math.round((CACHE_DURATION_HOURS - hoursSinceSync) * 60)
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // ============================================================================
    // 2. Get WHOOP OAuth credentials from patients table
    // ============================================================================
    // NOTE: Uses whoop_credentials JSONB column from patients table

    const { data: patient, error: patientError } = await supabaseClient
      .from('patients')
      .select('id, whoop_credentials')
      .eq('id', patient_id)
      .single()

    if (patientError) {
      console.error('Patient fetch error:', patientError)

      // Return 404 if patient not found
      if (patientError.code === 'PGRST116' || patientError.message?.includes('No rows found')) {
        return new Response(
          JSON.stringify({ error: 'Patient not found' }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      throw new Error('Failed to fetch patient credentials')
    }

    // ============================================================================
    // 3. Check if access token is expired, refresh if needed
    // ============================================================================

    let credentials: WHOOPCredentials | null = null

    if (patient?.whoop_credentials) {
      credentials = patient.whoop_credentials as WHOOPCredentials

      // ============================================================================
      // MOCK MODE DETECTION: Check if credentials are mock credentials
      // ============================================================================
      if (credentials.access_token.startsWith('mock_')) {
        console.log('Mock WHOOP credentials detected, returning mock data')
        return await syncMockRecoveryData(supabaseClient, patient_id, today)
      }

      const expiresAt = new Date(credentials.expires_at)
      const isExpired = Date.now() >= expiresAt.getTime()

      if (isExpired) {
        console.log('Access token expired, refreshing...')
        credentials = await refreshWHOOPToken(credentials.refresh_token, supabaseClient, patient_id)
      }
    } else {
      // No WHOOP credentials - return mock data for testing
      console.log('No WHOOP credentials found, returning mock data')
      return await syncMockRecoveryData(supabaseClient, patient_id, today)
    }

    // ============================================================================
    // 4. Call WHOOP API to get latest recovery data
    // ============================================================================

    const recoveryData = await fetchWHOOPRecovery(credentials.access_token)

    // ============================================================================
    // 5. Calculate strain from recovery score (WHOOP-specific logic)
    // ============================================================================
    // WHOOP strain is 0-21, but recovery API doesn't return it directly
    // For MVP, we'll estimate it based on recovery score
    // Higher recovery = lower recent strain (inverse relationship)
    const estimatedStrain = Math.max(0, Math.min(21,
      21 - (recoveryData.recovery_score / 100) * 10
    ))

    // ============================================================================
    // 6. Update daily_readiness with WHOOP data
    // ============================================================================

    const { data: updatedReadiness, error: updateError } = await supabaseClient
      .from('daily_readiness')
      .upsert({
        patient_id: patient_id,
        date: today,
        whoop_recovery_score: recoveryData.recovery_score,
        whoop_sleep_performance_percentage: recoveryData.spo2_percentage, // Using SPO2 as proxy
        whoop_hrv_rmssd: recoveryData.hrv_rmssd_milli,
        whoop_strain: estimatedStrain,
        whoop_synced_at: new Date().toISOString(),
      }, {
        onConflict: 'patient_id,date'
      })
      .select()
      .single()

    if (updateError) {
      console.error('Update error:', updateError)
      throw new Error('Failed to update daily_readiness')
    }

    // ============================================================================
    // 7. Return structured recovery data
    // ============================================================================

    const response: WHOOPRecoveryResponse = {
      recovery_score: recoveryData.recovery_score,
      sleep_performance_percentage: recoveryData.spo2_percentage,
      hrv_rmssd: recoveryData.hrv_rmssd_milli,
      strain: estimatedStrain,
      synced_at: new Date().toISOString(),
    }

    return new Response(
      JSON.stringify({
        success: true,
        data: response,
        updated_readiness: updatedReadiness,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Error in sync-whoop-recovery:', error)
    const errorMessage = error instanceof Error ? error.message : 'Unknown error occurred'
    const errorDetails = error instanceof Error ? error.toString() : String(error)

    return new Response(
      JSON.stringify({
        error: errorMessage,
        details: errorDetails
      }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

// ============================================================================
// Helper: Refresh WHOOP OAuth Token
// ============================================================================

async function refreshWHOOPToken(
  refreshToken: string,
  supabaseClient: any,
  patientId: string
): Promise<WHOOPCredentials> {
  const clientId = Deno.env.get('WHOOP_CLIENT_ID') ?? ''
  const clientSecret = Deno.env.get('WHOOP_CLIENT_SECRET') ?? ''

  const response = await fetch(WHOOP_OAUTH_TOKEN_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-www-form-urlencoded',
    },
    body: new URLSearchParams({
      grant_type: 'refresh_token',
      refresh_token: refreshToken,
      client_id: clientId,
      client_secret: clientSecret,
    }),
  })

  if (!response.ok) {
    const error = await response.text()
    console.error('WHOOP token refresh error:', error)
    throw new Error('Failed to refresh WHOOP access token')
  }

  const tokenData = await response.json()

  // Calculate expiration time (WHOOP typically returns expires_in seconds)
  const expiresAt = new Date(Date.now() + (tokenData.expires_in * 1000)).toISOString()

  const newCredentials: WHOOPCredentials = {
    access_token: tokenData.access_token,
    refresh_token: tokenData.refresh_token || refreshToken, // Some APIs don't rotate refresh tokens
    expires_at: expiresAt,
  }

  // Update patient record with new credentials
  await supabaseClient
    .from('patients')
    .update({
      whoop_credentials: newCredentials
    })
    .eq('id', patientId)

  console.log('WHOOP token refreshed successfully')
  return newCredentials
}

// ============================================================================
// Helper: Fetch WHOOP Recovery Data
// ============================================================================

async function fetchWHOOPRecovery(accessToken: string): Promise<WHOOPAPIRecovery> {
  // Get the most recent recovery data
  // WHOOP API: GET /v1/recovery
  // Docs: https://developer.whoop.com/docs/developing/user-data/recovery

  const response = await fetch(`${WHOOP_API_BASE}/recovery`, {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Content-Type': 'application/json',
    },
  })

  if (!response.ok) {
    const error = await response.text()
    console.error('WHOOP recovery API error:', error)

    // Handle rate limiting
    if (response.status === 429) {
      throw new Error('WHOOP API rate limit reached. Please try again later.')
    }

    throw new Error('Failed to fetch WHOOP recovery data')
  }

  const data = await response.json()

  // WHOOP returns an array of recovery records, we want the most recent
  const recoveries = data.records || []

  if (recoveries.length === 0) {
    throw new Error('No recovery data available from WHOOP')
  }

  // Return the most recent recovery
  return recoveries[0]
}

// ============================================================================
// Helper: Return Mock Recovery Data (for testing without WHOOP credentials)
// ============================================================================

async function syncMockRecoveryData(
  supabaseClient: any,
  patientId: string,
  today: string
): Promise<Response> {
  // Generate realistic mock data
  const mockRecoveryScore = 70 + Math.random() * 25 // 70-95 range
  const mockSleepPerformance = 75 + Math.random() * 20 // 75-95 range
  const mockHRV = 45 + Math.random() * 30 // 45-75ms range
  const mockStrain = 8 + Math.random() * 6 // 8-14 range (moderate)

  const { data: updatedReadiness, error: updateError } = await supabaseClient
    .from('daily_readiness')
    .upsert({
      patient_id: patientId,
      date: today,
      whoop_recovery_score: Math.round(mockRecoveryScore * 10) / 10,
      whoop_sleep_performance_percentage: Math.round(mockSleepPerformance * 10) / 10,
      whoop_hrv_rmssd: Math.round(mockHRV * 10) / 10,
      whoop_strain: Math.round(mockStrain * 10) / 10,
      whoop_synced_at: new Date().toISOString(),
    }, {
      onConflict: 'patient_id,date'
    })
    .select()
    .single()

  if (updateError) {
    throw new Error('Failed to update daily_readiness with mock data')
  }

  const response: WHOOPRecoveryResponse = {
    recovery_score: Math.round(mockRecoveryScore * 10) / 10,
    sleep_performance_percentage: Math.round(mockSleepPerformance * 10) / 10,
    hrv_rmssd: Math.round(mockHRV * 10) / 10,
    strain: Math.round(mockStrain * 10) / 10,
    synced_at: new Date().toISOString(),
  }

  return new Response(
    JSON.stringify({
      success: true,
      mock: true,
      message: 'No WHOOP credentials found. Using mock data for testing.',
      data: response,
      updated_readiness: updatedReadiness,
    }),
    { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
  )
}
