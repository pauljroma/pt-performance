// register-device-token Edge Function
// Registers APNs device token for push notifications
// Called from PushNotificationService.swift

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { corsHeaders } from '../_shared/errors.ts'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

interface RegisterDeviceTokenRequest {
  device_token: string
  platform?: 'ios' | 'android'
  device_id?: string
  device_name?: string
  device_model?: string
  os_version?: string
  app_version?: string
  // Alternative field names from iOS
  deviceToken?: string
  userId?: string
}

interface RegisterDeviceTokenResponse {
  success: boolean
  message: string
  token_id?: string
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
    const body: RegisterDeviceTokenRequest = await req.json()

    // Support both naming conventions
    const deviceToken = body.device_token || body.deviceToken
    const platform = body.platform || 'ios'

    // Validate device_token is provided
    if (!deviceToken) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'device_token is required'
        } as RegisterDeviceTokenResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate device token format (should be hex string for APNs)
    if (!/^[a-fA-F0-9]{64}$/.test(deviceToken)) {
      console.warn(`[register-device-token] Unusual device token format: ${deviceToken.substring(0, 16)}...`)
      // Don't reject - APNs tokens may vary
    }

    // Validate platform
    if (!['ios', 'android'].includes(platform)) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'platform must be "ios" or "android"'
        } as RegisterDeviceTokenResponse),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Initialize Supabase client with service role
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, serviceRoleKey)

    // Check if this exact token already exists
    const { data: existingToken } = await supabase
      .from('push_notification_tokens')
      .select('id, user_id, is_active')
      .eq('device_token', deviceToken)
      .maybeSingle()

    if (existingToken) {
      // Token exists - update it
      if (existingToken.user_id === authUser.user_id) {
        // Same user, just ensure it's active and update metadata
        const { data: updated, error: updateError } = await supabase
          .from('push_notification_tokens')
          .update({
            is_active: true,
            platform: platform,
            device_name: body.device_name,
            device_model: body.device_model,
            os_version: body.os_version,
            app_version: body.app_version,
            last_used_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', existingToken.id)
          .select('id')
          .single()

        if (updateError) {
          console.error('Error updating device token:', updateError)
          return new Response(
            JSON.stringify({
              success: false,
              error: 'Failed to update device token'
            } as RegisterDeviceTokenResponse),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        console.log(`[register-device-token] Updated existing token for user ${authUser.user_id}`)

        return new Response(
          JSON.stringify({
            success: true,
            message: 'Device token updated successfully',
            token_id: updated?.id
          } as RegisterDeviceTokenResponse),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      } else {
        // Token belongs to different user - reassign it
        // This handles device transfers between users
        const { data: reassigned, error: reassignError } = await supabase
          .from('push_notification_tokens')
          .update({
            user_id: authUser.user_id,
            is_active: true,
            platform: platform,
            device_name: body.device_name,
            device_model: body.device_model,
            os_version: body.os_version,
            app_version: body.app_version,
            last_used_at: new Date().toISOString(),
            updated_at: new Date().toISOString()
          })
          .eq('id', existingToken.id)
          .select('id')
          .single()

        if (reassignError) {
          console.error('Error reassigning device token:', reassignError)
          return new Response(
            JSON.stringify({
              success: false,
              error: 'Failed to register device token'
            } as RegisterDeviceTokenResponse),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          )
        }

        console.log(`[register-device-token] Reassigned token to user ${authUser.user_id} (was ${existingToken.user_id})`)

        return new Response(
          JSON.stringify({
            success: true,
            message: 'Device token registered successfully',
            token_id: reassigned?.id
          } as RegisterDeviceTokenResponse),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // Token doesn't exist - create it
    const { data: newToken, error: insertError } = await supabase
      .from('push_notification_tokens')
      .insert({
        user_id: authUser.user_id,
        device_token: deviceToken,
        platform: platform,
        device_name: body.device_name,
        device_model: body.device_model,
        os_version: body.os_version,
        app_version: body.app_version,
        is_active: true,
        last_used_at: new Date().toISOString()
      })
      .select('id')
      .single()

    if (insertError) {
      console.error('Error inserting device token:', insertError)

      // Handle unique constraint violation (race condition)
      if (insertError.code === '23505') {
        return new Response(
          JSON.stringify({
            success: true,
            message: 'Device token already registered'
          } as RegisterDeviceTokenResponse),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      return new Response(
        JSON.stringify({
          success: false,
          error: 'Failed to register device token'
        } as RegisterDeviceTokenResponse),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    console.log(`[register-device-token] Created new token ${newToken.id} for user ${authUser.user_id}`)

    return new Response(
      JSON.stringify({
        success: true,
        message: 'Device token registered successfully',
        token_id: newToken.id
      } as RegisterDeviceTokenResponse),
      { status: 201, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('[register-device-token] Error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error instanceof Error ? error.message : 'Internal server error'
      } as RegisterDeviceTokenResponse),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
