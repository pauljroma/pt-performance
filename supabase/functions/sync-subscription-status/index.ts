// Supabase Edge Function: sync-subscription-status
// Syncs subscription status from iOS app to the database for server-side feature gating

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
}

// Valid product IDs - must match Config.Subscription in iOS app
const VALID_PRODUCT_IDS = new Set([
  'com.getmodus.app.monthly',
  'com.getmodus.app.annual',
  'com.getmodus.app.baseballpack',
])

interface SyncSubscriptionRequest {
  is_premium: boolean
  subscription_status: 'none' | 'active' | 'expired' | 'grace_period'
  purchased_products: string[]
  owns_baseball_pack: boolean
  expires_at?: string
  synced_at: string
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
    const body: SyncSubscriptionRequest = await req.json()

    // Validate purchased products - only accept known product IDs
    const validatedProducts = body.purchased_products.filter(
      productId => VALID_PRODUCT_IDS.has(productId)
    )

    // Log if any invalid product IDs were submitted (potential tampering)
    const invalidProducts = body.purchased_products.filter(
      productId => !VALID_PRODUCT_IDS.has(productId)
    )
    if (invalidProducts.length > 0) {
      console.warn(`Invalid product IDs submitted by user ${authUser.user_id}: ${invalidProducts.join(', ')}`)
    }

    // Create Supabase client with service role for database writes
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Upsert subscription status to database
    const { error: upsertError } = await supabase
      .from('user_subscription_status')
      .upsert({
        user_id: authUser.user_id,
        is_premium: body.is_premium,
        subscription_status: body.subscription_status,
        purchased_products: validatedProducts,
        owns_baseball_pack: body.owns_baseball_pack,
        expires_at: body.expires_at || null,
        client_synced_at: body.synced_at,
        server_synced_at: new Date().toISOString(),
      }, {
        onConflict: 'user_id',
      })

    if (upsertError) {
      console.error('Failed to upsert subscription status:', upsertError)

      // If table doesn't exist, log a helpful message
      if (upsertError.code === '42P01') {
        console.error('Table user_subscription_status does not exist. Please run migration.')
        // Return success anyway - the subscription still works client-side
        return new Response(
          JSON.stringify({
            success: false,
            warning: 'Subscription status not synced - database table not configured',
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }

      throw upsertError
    }

    console.log(`Subscription status synced for user ${authUser.user_id}: premium=${body.is_premium}`)

    return new Response(
      JSON.stringify({
        success: true,
        synced_at: new Date().toISOString(),
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    console.error('Subscription sync error:', error)
    return new Response(
      JSON.stringify({ success: false, error: 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
