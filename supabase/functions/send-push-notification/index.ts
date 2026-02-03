// send-push-notification Edge Function
// Build 69 - Agent 9: Safety - Notifications & QA
// Sends push notifications via APNs (Apple Push Notification service)

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface PushNotificationPayload {
  user_id?: string
  device_token?: string
  title: string
  body: string
  data?: Record<string, any>
  category?: string
  badge?: number
  sound?: string
  priority?: 'normal' | 'high'
}

interface APNsResponse {
  success: boolean
  apnsId?: string
  statusCode?: number
  error?: string
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get environment variables
    const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID')
    const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID')
    const APNS_AUTH_KEY = Deno.env.get('APNS_AUTH_KEY')
    const APNS_BUNDLE_ID = Deno.env.get('APNS_BUNDLE_ID') || 'com.getmodus.app'
    const APNS_ENVIRONMENT = Deno.env.get('APNS_ENVIRONMENT') || 'development'

    if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_AUTH_KEY) {
      throw new Error('APNs credentials not configured')
    }

    // Parse request body
    const payload: PushNotificationPayload = await req.json()

    // Initialize Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    // Get device tokens
    let deviceTokens: string[] = []

    if (payload.device_token) {
      // Send to specific device
      deviceTokens = [payload.device_token]
    } else if (payload.user_id) {
      // Get all active device tokens for user
      const { data: tokens, error } = await supabase
        .from('push_notification_tokens')
        .select('device_token, id')
        .eq('user_id', payload.user_id)
        .eq('is_active', true)
        .eq('platform', 'ios')

      if (error) {
        throw new Error(`Failed to fetch device tokens: ${error.message}`)
      }

      deviceTokens = tokens?.map(t => t.device_token) || []
    } else {
      throw new Error('Either user_id or device_token must be provided')
    }

    if (deviceTokens.length === 0) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'No active device tokens found',
          sent: 0
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    // Build APNs payload
    const apnsPayload = {
      aps: {
        alert: {
          title: payload.title,
          body: payload.body
        },
        sound: payload.sound || 'default',
        badge: payload.badge,
        category: payload.category,
        'interruption-level': payload.priority === 'high' ? 'time-sensitive' : 'active'
      },
      ...payload.data
    }

    // Generate JWT token for APNs authentication
    const jwtToken = await generateAPNsJWT(APNS_KEY_ID, APNS_TEAM_ID, APNS_AUTH_KEY)

    // Send notifications to all devices
    const results: APNsResponse[] = []
    const apnsEndpoint = APNS_ENVIRONMENT === 'production'
      ? 'https://api.push.apple.com'
      : 'https://api.sandbox.push.apple.com'

    for (const deviceToken of deviceTokens) {
      try {
        const response = await fetch(
          `${apnsEndpoint}/3/device/${deviceToken}`,
          {
            method: 'POST',
            headers: {
              'authorization': `bearer ${jwtToken}`,
              'apns-topic': APNS_BUNDLE_ID,
              'apns-push-type': 'alert',
              'apns-priority': payload.priority === 'high' ? '10' : '5',
              'content-type': 'application/json'
            },
            body: JSON.stringify(apnsPayload)
          }
        )

        const apnsId = response.headers.get('apns-id')

        if (response.ok) {
          results.push({
            success: true,
            apnsId: apnsId || undefined,
            statusCode: response.status
          })

          // Log successful delivery
          await supabase.from('notification_logs').insert({
            user_id: payload.user_id,
            notification_type: payload.category || 'unknown',
            title: payload.title,
            body: payload.body,
            payload: payload.data,
            status: 'sent',
            apns_response: { apnsId, statusCode: response.status }
          })

        } else {
          const errorBody = await response.json()
          results.push({
            success: false,
            statusCode: response.status,
            error: errorBody.reason || 'Unknown error'
          })

          // Log failed delivery
          await supabase.from('notification_logs').insert({
            user_id: payload.user_id,
            notification_type: payload.category || 'unknown',
            title: payload.title,
            body: payload.body,
            payload: payload.data,
            status: 'failed',
            error_message: errorBody.reason || 'Unknown error',
            apns_response: { ...errorBody, statusCode: response.status }
          })

          // Handle BadDeviceToken - deactivate the token
          if (errorBody.reason === 'BadDeviceToken' || errorBody.reason === 'Unregistered') {
            await supabase
              .from('push_notification_tokens')
              .update({ is_active: false })
              .eq('device_token', deviceToken)
          }
        }
      } catch (error) {
        results.push({
          success: false,
          error: error.message
        })

        // Log error
        await supabase.from('notification_logs').insert({
          user_id: payload.user_id,
          notification_type: payload.category || 'unknown',
          title: payload.title,
          body: payload.body,
          payload: payload.data,
          status: 'failed',
          error_message: error.message
        })
      }
    }

    // Return results
    const successCount = results.filter(r => r.success).length
    const failureCount = results.filter(r => !r.success).length

    return new Response(
      JSON.stringify({
        success: successCount > 0,
        sent: successCount,
        failed: failureCount,
        total: deviceTokens.length,
        results
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Push notification error:', error)

    return new Response(
      JSON.stringify({
        success: false,
        error: error.message
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 500
      }
    )
  }
})

// Generate JWT token for APNs authentication
async function generateAPNsJWT(
  keyId: string,
  teamId: string,
  authKey: string
): Promise<string> {
  // JWT header
  const header = {
    alg: 'ES256',
    kid: keyId
  }

  // JWT claims
  const claims = {
    iss: teamId,
    iat: Math.floor(Date.now() / 1000)
  }

  // Encode header and claims
  const encodedHeader = base64UrlEncode(JSON.stringify(header))
  const encodedClaims = base64UrlEncode(JSON.stringify(claims))
  const signingInput = `${encodedHeader}.${encodedClaims}`

  // Import the private key
  const privateKey = await importPrivateKey(authKey)

  // Sign the JWT
  const signature = await signJWT(signingInput, privateKey)
  const encodedSignature = base64UrlEncode(signature)

  return `${signingInput}.${encodedSignature}`
}

// Import ES256 private key from PEM format
async function importPrivateKey(pemKey: string): Promise<CryptoKey> {
  // Decode base64 (if it was base64 encoded in env)
  let keyContent = pemKey
  try {
    keyContent = atob(pemKey)
  } catch {
    // Already decoded
  }

  // Remove PEM headers and whitespace
  const pemContents = keyContent
    .replace(/-----BEGIN PRIVATE KEY-----/, '')
    .replace(/-----END PRIVATE KEY-----/, '')
    .replace(/\s/g, '')

  // Convert to ArrayBuffer
  const binaryDer = Uint8Array.from(atob(pemContents), c => c.charCodeAt(0))

  // Import the key
  return await crypto.subtle.importKey(
    'pkcs8',
    binaryDer,
    {
      name: 'ECDSA',
      namedCurve: 'P-256'
    },
    false,
    ['sign']
  )
}

// Sign JWT with ES256
async function signJWT(data: string, key: CryptoKey): Promise<string> {
  const encoder = new TextEncoder()
  const dataBuffer = encoder.encode(data)

  const signature = await crypto.subtle.sign(
    {
      name: 'ECDSA',
      hash: 'SHA-256'
    },
    key,
    dataBuffer
  )

  return arrayBufferToString(signature)
}

// Base64 URL encode
function base64UrlEncode(str: string): string {
  const base64 = btoa(str)
  return base64
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=/g, '')
}

// Convert ArrayBuffer to string
function arrayBufferToString(buffer: ArrayBuffer): string {
  const bytes = new Uint8Array(buffer)
  let binary = ''
  for (let i = 0; i < bytes.byteLength; i++) {
    binary += String.fromCharCode(bytes[i])
  }
  return binary
}
