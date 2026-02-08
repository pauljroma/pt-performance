// Supabase Edge Function: validate-receipt
// Validates App Store receipts for in-app purchases

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

interface ValidateReceiptRequest {
  receipt_data: string  // Base64-encoded receipt
  exclude_old_transactions?: boolean
}

interface AppleReceiptResponse {
  status: number
  environment?: 'Sandbox' | 'Production'
  receipt?: {
    bundle_id: string
    application_version: string
    in_app?: AppleInAppPurchase[]
    original_purchase_date_ms?: string
  }
  latest_receipt_info?: AppleInAppPurchase[]
  pending_renewal_info?: ApplePendingRenewal[]
}

interface AppleInAppPurchase {
  product_id: string
  transaction_id: string
  original_transaction_id: string
  purchase_date_ms: string
  expires_date_ms?: string
  is_trial_period?: string
  cancellation_date_ms?: string
}

interface ApplePendingRenewal {
  product_id: string
  auto_renew_status: string
  auto_renew_product_id: string
}

// Apple receipt status codes
const APPLE_STATUS = {
  VALID: 0,
  INVALID_JSON: 21000,
  MALFORMED_RECEIPT: 21002,
  RECEIPT_AUTH_FAILED: 21003,
  SHARED_SECRET_MISMATCH: 21004,
  RECEIPT_SERVER_UNAVAILABLE: 21005,
  SUBSCRIPTION_EXPIRED: 21006,
  SANDBOX_RECEIPT_ON_PROD: 21007,
  PROD_RECEIPT_ON_SANDBOX: 21008,
} as const

// Expected bundle ID for the app
// Note: This should match the bundle ID in the iOS app's Info.plist
const EXPECTED_BUNDLE_ID = 'com.getmodus.app'

// Valid product IDs - must match Config.Subscription in iOS app
// These are the only product IDs that will be accepted for validation
const VALID_PRODUCT_IDS = [
  'com.getmodus.app.monthly',      // Monthly subscription
  'com.getmodus.app.annual',        // Annual subscription
  'com.getmodus.app.baseballpack',  // Baseball Pack one-time purchase
]

async function validateWithApple(
  receiptData: string,
  useSandbox: boolean = false
): Promise<AppleReceiptResponse> {
  const url = useSandbox
    ? 'https://sandbox.itunes.apple.com/verifyReceipt'
    : 'https://buy.itunes.apple.com/verifyReceipt'

  const sharedSecret = Deno.env.get('APPLE_SHARED_SECRET')
  if (!sharedSecret) {
    throw new Error('APPLE_SHARED_SECRET not configured')
  }

  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      'receipt-data': receiptData,
      'password': sharedSecret,
      'exclude-old-transactions': true,
    }),
  })

  if (!response.ok) {
    throw new Error(`Apple API error: ${response.status}`)
  }

  return await response.json()
}

function findActiveSubscription(
  receiptInfo: AppleInAppPurchase[]
): AppleInAppPurchase | null {
  const now = Date.now()

  // Sort by expiration date descending
  const sorted = [...receiptInfo].sort((a, b) => {
    const aExpires = parseInt(a.expires_date_ms || '0')
    const bExpires = parseInt(b.expires_date_ms || '0')
    return bExpires - aExpires
  })

  // Find active subscription
  for (const purchase of sorted) {
    if (purchase.cancellation_date_ms) continue
    if (!VALID_PRODUCT_IDS.includes(purchase.product_id)) continue

    const expiresMs = parseInt(purchase.expires_date_ms || '0')
    if (expiresMs > now) {
      return purchase
    }
  }

  return null
}

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Require authentication
    const authResult = await requireAuth(req)
    if (authResult instanceof Response) {
      return authResult
    }
    const authUser = authResult as AuthUser

    // Parse request
    const { receipt_data, exclude_old_transactions = true }: ValidateReceiptRequest = await req.json()

    if (!receipt_data) {
      return new Response(
        JSON.stringify({ valid: false, error: 'Missing receipt_data' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Validate with Apple (try production first)
    let appleResponse = await validateWithApple(receipt_data, false)

    // If sandbox receipt sent to production, retry with sandbox
    if (appleResponse.status === APPLE_STATUS.SANDBOX_RECEIPT_ON_PROD) {
      appleResponse = await validateWithApple(receipt_data, true)
    }

    // Check for valid response
    if (appleResponse.status !== APPLE_STATUS.VALID) {
      console.error(`Receipt validation failed: status ${appleResponse.status}`)
      return new Response(
        JSON.stringify({
          valid: false,
          error: 'Receipt validation failed',
          apple_status: appleResponse.status,
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Verify bundle ID
    if (appleResponse.receipt?.bundle_id !== EXPECTED_BUNDLE_ID) {
      console.error(`Bundle ID mismatch: ${appleResponse.receipt?.bundle_id}`)
      return new Response(
        JSON.stringify({ valid: false, error: 'Invalid bundle ID' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get latest receipt info
    const receiptInfo = appleResponse.latest_receipt_info || appleResponse.receipt?.in_app || []

    // Find active subscription
    const activeSubscription = findActiveSubscription(receiptInfo)

    // Store validation result in database
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!  // Need service role to write
    )

    if (activeSubscription) {
      // Update user's subscription status
      const { error: updateError } = await supabase
        .from('user_subscriptions')
        .upsert({
          user_id: authUser.user_id,
          product_id: activeSubscription.product_id,
          transaction_id: activeSubscription.transaction_id,
          original_transaction_id: activeSubscription.original_transaction_id,
          purchase_date: new Date(parseInt(activeSubscription.purchase_date_ms)).toISOString(),
          expires_date: activeSubscription.expires_date_ms
            ? new Date(parseInt(activeSubscription.expires_date_ms)).toISOString()
            : null,
          is_trial: activeSubscription.is_trial_period === 'true',
          environment: appleResponse.environment,
          validated_at: new Date().toISOString(),
          status: 'active',
        }, {
          onConflict: 'user_id',
        })

      if (updateError) {
        console.error('Failed to update subscription:', updateError)
      }
    }

    return new Response(
      JSON.stringify({
        valid: true,
        has_active_subscription: !!activeSubscription,
        subscription: activeSubscription ? {
          product_id: activeSubscription.product_id,
          expires_date: activeSubscription.expires_date_ms
            ? new Date(parseInt(activeSubscription.expires_date_ms)).toISOString()
            : null,
          is_trial: activeSubscription.is_trial_period === 'true',
        } : null,
        environment: appleResponse.environment,
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Receipt validation error:', error)
    return new Response(
      JSON.stringify({ valid: false, error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
