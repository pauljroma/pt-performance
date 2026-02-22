// Supabase Edge Function: feature-flags
// Returns all feature flags as a key-value map for the authenticated user.
// Cached for 5 minutes via Cache-Control header.

import { serve } from "https://deno.land/std@0.177.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireAuth, AuthUser } from '../_shared/auth.ts'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
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
    const _authUser = authResult as AuthUser

    // Create a service-role client to read feature flags
    // (RLS allows authenticated reads, but service role avoids any future policy changes)
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    )

    // Fetch all feature flags
    const { data: flagRows, error } = await supabase
      .from('feature_flags')
      .select('flag_key, enabled')

    if (error) {
      console.error('Error fetching feature flags:', error.message)
      return new Response(
        JSON.stringify({ error: 'Failed to fetch feature flags' }),
        {
          status: 500,
          headers: { ...corsHeaders, 'Content-Type': 'application/json' },
        }
      )
    }

    // Transform rows into { [key]: boolean } map
    const flags: Record<string, boolean> = {}
    for (const row of flagRows || []) {
      flags[row.flag_key] = row.enabled
    }

    return new Response(
      JSON.stringify({ flags }),
      {
        status: 200,
        headers: {
          ...corsHeaders,
          'Content-Type': 'application/json',
          'Cache-Control': 'public, max-age=300',
        },
      }
    )
  } catch (error) {
    console.error('Feature flags error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error' }),
      {
        status: 500,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      }
    )
  }
})
