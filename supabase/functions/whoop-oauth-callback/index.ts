// WHOOP OAuth Callback Handler
// Build 76 - WHOOP Integration
// Handles OAuth code exchange and stores credentials

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface WHOOPTokenResponse {
  access_token: string
  refresh_token: string
  expires_in: number
  token_type: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get code from request
    const { code, athlete_id } = await req.json()

    if (!code) {
      return new Response(
        JSON.stringify({ error: 'Authorization code required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Exchange code for access token
    const tokenResponse = await fetch('https://api.whoop.com/oauth/token', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: new URLSearchParams({
        grant_type: 'authorization_code',
        code: code,
        client_id: Deno.env.get('WHOOP_CLIENT_ID') || '',
        client_secret: Deno.env.get('WHOOP_CLIENT_SECRET') || '',
        redirect_uri: Deno.env.get('WHOOP_REDIRECT_URI') || '',
      }),
    })

    if (!tokenResponse.ok) {
      const error = await tokenResponse.text()
      console.error('WHOOP token exchange failed:', error)
      return new Response(
        JSON.stringify({ error: 'Failed to exchange authorization code' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    const tokens: WHOOPTokenResponse = await tokenResponse.json()

    // Calculate expiration timestamp
    const expiresAt = new Date(Date.now() + tokens.expires_in * 1000)

    // Store credentials in database
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          persistSession: false,
        },
      }
    )

    const { error: dbError } = await supabaseClient
      .from('whoop_credentials')
      .upsert({
        athlete_id: athlete_id,
        access_token: tokens.access_token,
        refresh_token: tokens.refresh_token,
        expires_at: expiresAt.toISOString(),
      })

    if (dbError) {
      console.error('Database error:', dbError)
      return new Response(
        JSON.stringify({ error: 'Failed to store credentials' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Trigger immediate sync
    try {
      await fetch(`${Deno.env.get('SUPABASE_URL')}/functions/v1/whoop-sync-recovery`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': req.headers.get('Authorization') || '',
        },
        body: JSON.stringify({ athlete_id }),
      })
    } catch (syncError) {
      console.warn('Initial sync failed (non-fatal):', syncError)
    }

    return new Response(
      JSON.stringify({
        success: true,
        message: 'WHOOP connected successfully',
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Error in whoop-oauth-callback:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
