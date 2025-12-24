// WHOOP Recovery Sync Handler
// Build 76 - WHOOP Integration
// Fetches latest recovery data from WHOOP API and stores in database

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WHOOPCredentials {
  access_token: string
  refresh_token: string
  expires_at: string
}

interface WHOOPRecoveryResponse {
  score: {
    recovery_score: number
    hrv_rmssd_milli: number
    resting_heart_rate: number
    sleep_performance_percentage: number
  }
  created_at: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { athlete_id } = await req.json()

    if (!athlete_id) {
      return new Response(
        JSON.stringify({ error: 'athlete_id required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Supabase client
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          persistSession: false,
        },
      }
    )

    // Fetch WHOOP credentials
    const { data: credentials, error: credError } = await supabaseClient
      .from('whoop_credentials')
      .select('access_token, refresh_token, expires_at')
      .eq('athlete_id', athlete_id)
      .single()

    if (credError || !credentials) {
      return new Response(
        JSON.stringify({ error: 'WHOOP not connected for this athlete' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Check if token is expired
    let accessToken = credentials.access_token
    const expiresAt = new Date(credentials.expires_at)
    const now = new Date()

    if (now >= expiresAt) {
      // Token expired - refresh it
      const refreshResponse = await fetch('https://api.whoop.com/oauth/token', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: new URLSearchParams({
          grant_type: 'refresh_token',
          refresh_token: credentials.refresh_token,
          client_id: Deno.env.get('WHOOP_CLIENT_ID') || '',
          client_secret: Deno.env.get('WHOOP_CLIENT_SECRET') || '',
        }),
      })

      if (!refreshResponse.ok) {
        console.error('Token refresh failed')
        return new Response(
          JSON.stringify({ error: 'Failed to refresh WHOOP token' }),
          { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      const tokens = await refreshResponse.json()
      accessToken = tokens.access_token

      // Update credentials
      await supabaseClient
        .from('whoop_credentials')
        .update({
          access_token: tokens.access_token,
          refresh_token: tokens.refresh_token,
          expires_at: new Date(Date.now() + tokens.expires_in * 1000).toISOString(),
        })
        .eq('athlete_id', athlete_id)
    }

    // Fetch recovery data from WHOOP
    const recoveryResponse = await fetch('https://api.whoop.com/v1/recovery', {
      headers: {
        'Authorization': `Bearer ${accessToken}`,
      },
    })

    if (!recoveryResponse.ok) {
      const error = await recoveryResponse.text()
      console.error('WHOOP recovery fetch failed:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch recovery from WHOOP' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const recoveryData: WHOOPRecoveryResponse = await recoveryResponse.json()

    // Calculate readiness band
    const recoveryScore = recoveryData.score.recovery_score
    let readinessBand: string
    if (recoveryScore >= 67) {
      readinessBand = 'green'
    } else if (recoveryScore >= 34) {
      readinessBand = 'yellow'
    } else {
      readinessBand = 'red'
    }

    // Store in database
    const { error: dbError } = await supabaseClient
      .from('whoop_recovery')
      .upsert({
        athlete_id: athlete_id,
        date: new Date().toISOString().split('T')[0], // Today's date
        recovery_score: recoveryScore,
        hrv_rmssd: recoveryData.score.hrv_rmssd_milli,
        resting_hr: recoveryData.score.resting_heart_rate,
        sleep_performance: recoveryData.score.sleep_performance_percentage,
        readiness_band: readinessBand,
        synced_at: new Date().toISOString(),
      })

    if (dbError) {
      console.error('Database error:', dbError)
      return new Response(
        JSON.stringify({ error: 'Failed to store recovery data' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    return new Response(
      JSON.stringify({
        success: true,
        recovery_score: recoveryScore,
        readiness_band: readinessBand,
        hrv_rmssd: recoveryData.score.hrv_rmssd_milli,
        resting_hr: recoveryData.score.resting_heart_rate,
        sleep_performance: recoveryData.score.sleep_performance_percentage,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in whoop-sync-recovery:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
