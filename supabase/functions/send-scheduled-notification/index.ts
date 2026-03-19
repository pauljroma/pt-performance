// send-scheduled-notification Edge Function
// X2Index Phase 2: Scheduled Push Notification Delivery
// Queries users with scheduled notifications due and sends via APNs

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2.39.0"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

// Notification types matching iOS enum
type NotificationType =
  | 'check_in_reminder'
  | 'task_due'
  | 'brief_available'
  | 'safety_alert'
  | 'streak_milestone';

type NotificationPriority = 'high' | 'normal' | 'low';

interface ScheduledNotification {
  id: string;
  user_id: string;
  notification_type: NotificationType;
  title: string;
  body: string;
  data: Record<string, string>;
  scheduled_for: string;
  priority: NotificationPriority;
  status: 'pending' | 'sent' | 'failed' | 'cancelled';
  retry_count: number;
  created_at: string;
}

interface DeviceToken {
  id: string;
  user_id: string;
  device_token: string;
  platform: string;
  is_active: boolean;
}

interface APNsResponse {
  success: boolean;
  apnsId?: string;
  statusCode?: number;
  error?: string;
  deviceToken?: string;
}

interface SendResult {
  notificationId: string;
  userId: string;
  sent: number;
  failed: number;
  results: APNsResponse[];
}

// Max retries for failed notifications
const MAX_RETRIES = 3;

// Batch size for processing
const BATCH_SIZE = 100;

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Get environment variables
    const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!
    const SUPABASE_SERVICE_ROLE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const APNS_KEY_ID = Deno.env.get('APNS_KEY_ID')
    const APNS_TEAM_ID = Deno.env.get('APNS_TEAM_ID')
    const APNS_AUTH_KEY = Deno.env.get('APNS_AUTH_KEY')
    const APNS_BUNDLE_ID = Deno.env.get('APNS_BUNDLE_ID') || 'com.ptperformance.app'
    const APNS_ENVIRONMENT = Deno.env.get('APNS_ENVIRONMENT') || 'development'

    if (!APNS_KEY_ID || !APNS_TEAM_ID || !APNS_AUTH_KEY) {
      throw new Error('APNs credentials not configured')
    }

    // Initialize Supabase client with service role for full access
    const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)

    // Query for due notifications
    const now = new Date().toISOString()

    const { data: dueNotifications, error: queryError } = await supabase
      .from('scheduled_notifications')
      .select('*')
      .eq('status', 'pending')
      .lte('scheduled_for', now)
      .lt('retry_count', MAX_RETRIES)
      .order('scheduled_for', { ascending: true })
      .limit(BATCH_SIZE)

    if (queryError) {
      throw new Error(`Failed to query notifications: ${queryError.message}`)
    }

    if (!dueNotifications || dueNotifications.length === 0) {
      return new Response(
        JSON.stringify({
          success: true,
          message: 'No notifications due',
          processed: 0
        }),
        {
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
          status: 200
        }
      )
    }

    console.log(`Processing ${dueNotifications.length} scheduled notifications`)

    // Generate APNs JWT token
    const jwtToken = await generateAPNsJWT(APNS_KEY_ID, APNS_TEAM_ID, APNS_AUTH_KEY)
    const apnsEndpoint = APNS_ENVIRONMENT === 'production'
      ? 'https://api.push.apple.com'
      : 'https://api.sandbox.push.apple.com'

    // Process each notification
    const results: SendResult[] = []
    let totalSent = 0
    let totalFailed = 0

    for (const notification of dueNotifications as ScheduledNotification[]) {
      // Get active device tokens for user
      const { data: tokens, error: tokenError } = await supabase
        .from('push_notification_tokens')
        .select('*')
        .eq('user_id', notification.user_id)
        .eq('is_active', true)
        .eq('platform', 'ios')

      if (tokenError) {
        console.error(`Failed to get tokens for user ${notification.user_id}:`, tokenError)
        await markNotificationFailed(supabase, notification.id, 'Failed to fetch device tokens')
        totalFailed++
        continue
      }

      if (!tokens || tokens.length === 0) {
        console.log(`No active device tokens for user ${notification.user_id}`)
        await markNotificationFailed(supabase, notification.id, 'No active device tokens')
        totalFailed++
        continue
      }

      // Build APNs payload
      const apnsPayload = buildAPNsPayload(notification)

      // Send to all user's devices
      const sendResults: APNsResponse[] = []
      let successCount = 0

      for (const token of tokens as DeviceToken[]) {
        try {
          const response = await fetch(
            `${apnsEndpoint}/3/device/${token.device_token}`,
            {
              method: 'POST',
              headers: {
                'authorization': `bearer ${jwtToken}`,
                'apns-topic': APNS_BUNDLE_ID,
                'apns-push-type': 'alert',
                'apns-priority': notification.priority === 'high' ? '10' : '5',
                'apns-expiration': String(Math.floor(Date.now() / 1000) + 86400), // 24 hours
                'content-type': 'application/json'
              },
              body: JSON.stringify(apnsPayload)
            }
          )

          const apnsId = response.headers.get('apns-id')

          if (response.ok) {
            sendResults.push({
              success: true,
              apnsId: apnsId || undefined,
              statusCode: response.status,
              deviceToken: token.device_token.substring(0, 8) + '...'
            })
            successCount++
          } else {
            const errorBody = await response.json()
            sendResults.push({
              success: false,
              statusCode: response.status,
              error: errorBody.reason || 'Unknown error',
              deviceToken: token.device_token.substring(0, 8) + '...'
            })

            // Handle invalid device tokens
            if (errorBody.reason === 'BadDeviceToken' || errorBody.reason === 'Unregistered') {
              await supabase
                .from('push_notification_tokens')
                .update({ is_active: false })
                .eq('device_token', token.device_token)
            }
          }
        } catch (error) {
          sendResults.push({
            success: false,
            error: error.message,
            deviceToken: token.device_token.substring(0, 8) + '...'
          })
        }
      }

      // Update notification status
      if (successCount > 0) {
        await markNotificationSent(supabase, notification.id, sendResults)
        totalSent++
      } else {
        await incrementRetryCount(supabase, notification.id, sendResults)
        if (notification.retry_count + 1 >= MAX_RETRIES) {
          totalFailed++
        }
      }

      results.push({
        notificationId: notification.id,
        userId: notification.user_id,
        sent: successCount,
        failed: tokens.length - successCount,
        results: sendResults
      })

      // Log delivery attempt
      await logDeliveryAttempt(supabase, notification, sendResults, successCount > 0)
    }

    return new Response(
      JSON.stringify({
        success: true,
        processed: dueNotifications.length,
        sent: totalSent,
        failed: totalFailed,
        results
      }),
      {
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        status: 200
      }
    )

  } catch (error) {
    console.error('Send scheduled notification error:', error)

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

// Build APNs payload from notification
function buildAPNsPayload(notification: ScheduledNotification): object {
  const interruptionLevel = notification.priority === 'high'
    ? 'time-sensitive'
    : notification.priority === 'low'
      ? 'passive'
      : 'active'

  return {
    aps: {
      alert: {
        title: notification.title,
        body: notification.body
      },
      sound: notification.priority === 'low' ? null : 'default',
      badge: 1,
      category: getCategoryIdentifier(notification.notification_type),
      'interruption-level': interruptionLevel,
      'thread-id': notification.data.thread_id || notification.notification_type
    },
    notification_type: notification.notification_type,
    ...notification.data
  }
}

// Get category identifier for notification type
function getCategoryIdentifier(type: NotificationType): string {
  const categories: Record<NotificationType, string> = {
    'check_in_reminder': 'CHECK_IN_REMINDER',
    'task_due': 'TASK_DUE',
    'brief_available': 'BRIEF_AVAILABLE',
    'safety_alert': 'SAFETY_ALERT',
    'streak_milestone': 'STREAK_MILESTONE'
  }
  return categories[type] || 'DEFAULT'
}

// Mark notification as sent
async function markNotificationSent(
  supabase: any,
  notificationId: string,
  results: APNsResponse[]
): Promise<void> {
  await supabase
    .from('scheduled_notifications')
    .update({
      status: 'sent',
      sent_at: new Date().toISOString(),
      delivery_results: results
    })
    .eq('id', notificationId)
}

// Mark notification as failed
async function markNotificationFailed(
  supabase: any,
  notificationId: string,
  errorMessage: string
): Promise<void> {
  await supabase
    .from('scheduled_notifications')
    .update({
      status: 'failed',
      error_message: errorMessage,
      retry_count: MAX_RETRIES // Set to max to prevent further retries
    })
    .eq('id', notificationId)
}

// Increment retry count for failed delivery
async function incrementRetryCount(
  supabase: any,
  notificationId: string,
  results: APNsResponse[]
): Promise<void> {
  await supabase
    .from('scheduled_notifications')
    .update({
      retry_count: supabase.raw('retry_count + 1'),
      last_retry_at: new Date().toISOString(),
      delivery_results: results
    })
    .eq('id', notificationId)
}

// Log delivery attempt for analytics
async function logDeliveryAttempt(
  supabase: any,
  notification: ScheduledNotification,
  results: APNsResponse[],
  success: boolean
): Promise<void> {
  try {
    await supabase
      .from('notification_delivery_logs')
      .insert({
        notification_id: notification.id,
        user_id: notification.user_id,
        notification_type: notification.notification_type,
        title: notification.title,
        status: success ? 'sent' : 'failed',
        device_count: results.length,
        success_count: results.filter(r => r.success).length,
        failure_count: results.filter(r => !r.success).length,
        results: results,
        created_at: new Date().toISOString()
      })
  } catch (error) {
    console.error('Failed to log delivery attempt:', error)
  }
}

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
