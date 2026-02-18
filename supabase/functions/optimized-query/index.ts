// ACP-940: Optimized Query Edge Function
// Demonstrates payload optimization utilities: field selection, pagination, compression.
//
// GET ?table=patients&fields=id,first_name,last_name,sport&page=1&pageSize=20&sort=created_at&order=desc
//
// Validates table name against an allowlist and proxies to Supabase with
// optimized response handling. Intended as a reference implementation and
// general-purpose read endpoint for lightweight list views.

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { requireAuth, createAuthenticatedClient } from '../_shared/auth.ts'
import type { AuthUser } from '../_shared/auth.ts'
import { corsHeaders } from '../_shared/errors.ts'
import { buildErrorResponse, ValidationError as AppValidationError } from '../_shared/errors.ts'
import {
  parseQueryParams,
  buildOptimizedResponse,
  standardHeaders,
} from '../_shared/payload-utils.ts'

// ============================================================================
// Configuration
// ============================================================================

/**
 * Allowlisted tables that can be queried through this endpoint.
 * Each entry maps a public table name to the Supabase table and its
 * default select columns (used when no ?fields= param is provided).
 */
const ALLOWED_TABLES: Record<string, { table: string; defaultSelect: string }> = {
  patients: {
    table: 'patients',
    defaultSelect: 'id, first_name, last_name, sport, position, created_at',
  },
  sessions: {
    table: 'sessions',
    defaultSelect: 'id, name, description, sequence, session_number, created_at',
  },
  exercise_logs: {
    table: 'exercise_logs',
    defaultSelect: 'id, session_exercise_id, set_number, reps_completed, weight_used, rpe, created_at',
  },
  programs: {
    table: 'programs',
    defaultSelect: 'id, name, description, status, start_date, end_date, created_at',
  },
}

const ALLOWED_TABLE_NAMES = Object.keys(ALLOWED_TABLES);

// ============================================================================
// Main Handler
// ============================================================================

serve(async (req) => {
  // Handle CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  // Only accept GET requests
  if (req.method !== 'GET') {
    return new Response(
      JSON.stringify({
        success: false,
        error: 'Method not allowed. Use GET.',
        code: 'ERR_METHOD_NOT_ALLOWED',
      }),
      {
        status: 405,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' },
      },
    )
  }

  try {
    // ── Auth ──────────────────────────────────────────────────────────
    const authResult = await requireAuth(req)
    if (authResult instanceof Response) return authResult
    const _authUser = authResult as AuthUser

    // Use the user's JWT so RLS policies are enforced
    const supabase = createAuthenticatedClient(req)

    // ── Parse & validate query params ────────────────────────────────
    const url = new URL(req.url)
    const tableName = url.searchParams.get('table')

    if (!tableName) {
      throw new AppValidationError('Query parameter "table" is required', 'table')
    }

    if (!ALLOWED_TABLE_NAMES.includes(tableName)) {
      throw new AppValidationError(
        `Table "${tableName}" is not allowed. Allowed tables: ${ALLOWED_TABLE_NAMES.join(', ')}`,
        'table',
      )
    }

    const tableConfig = ALLOWED_TABLES[tableName]!
    const params = parseQueryParams(url)

    // ── Build Supabase query ─────────────────────────────────────────
    // Determine the select clause: use requested fields if provided,
    // otherwise fall back to the table's default select list.
    const selectClause = params.fields.length > 0
      ? params.fields.join(', ')
      : tableConfig.defaultSelect

    // Count query (for pagination metadata) — runs in parallel with data query
    const countQuery = supabase
      .from(tableConfig.table)
      .select('*', { count: 'exact', head: true })

    // Data query with pagination and sorting
    const offset = (params.page - 1) * params.pageSize
    const dataQuery = supabase
      .from(tableConfig.table)
      .select(selectClause)
      .order(params.sort, { ascending: params.order === 'asc' })
      .range(offset, offset + params.pageSize - 1)

    // Execute both queries in parallel
    const [countResult, dataResult] = await Promise.all([countQuery, dataQuery])

    if (countResult.error) {
      console.error('Count query error:', countResult.error)
      return buildErrorResponse(countResult.error)
    }

    if (dataResult.error) {
      console.error('Data query error:', dataResult.error)
      return buildErrorResponse(dataResult.error)
    }

    const total = countResult.count ?? 0
    const rows = (dataResult.data ?? []) as Record<string, unknown>[]

    // ── Build optimized response ─────────────────────────────────────
    // Field selection is already handled by the Supabase select clause,
    // so we pass an empty fields array to buildOptimizedResponse to
    // avoid double-filtering. Compression + pagination still apply.
    const acceptEncoding = req.headers.get('accept-encoding') ?? ''

    const response = await buildOptimizedResponse(
      rows,
      total,
      { ...params, fields: [] }, // fields already projected in SQL
      acceptEncoding,
      60, // Cache for 60 seconds — adjust per use case
    )

    return response

  } catch (error) {
    return buildErrorResponse(error)
  }
})

/* ============================================================================
   USAGE EXAMPLES
   ============================================================================

   # List patients with specific fields, page 1
   curl -s "https://<project>.supabase.co/functions/v1/optimized-query?table=patients&fields=id,first_name,last_name,sport&page=1&pageSize=10&sort=created_at&order=desc" \
     -H "Authorization: Bearer <jwt>" \
     -H "Accept-Encoding: gzip"

   # List programs, default fields, page 2
   curl -s "https://<project>.supabase.co/functions/v1/optimized-query?table=programs&page=2&pageSize=5" \
     -H "Authorization: Bearer <jwt>"

   # Exercise logs sorted by set number ascending
   curl -s "https://<project>.supabase.co/functions/v1/optimized-query?table=exercise_logs&sort=set_number&order=asc&pageSize=50" \
     -H "Authorization: Bearer <jwt>"

   RESPONSE FORMAT:
   {
     "data": [
       { "id": "uuid", "first_name": "John", "last_name": "Doe", "sport": "Baseball" },
       ...
     ],
     "pagination": {
       "page": 1,
       "pageSize": 10,
       "total": 57,
       "totalPages": 6,
       "hasMore": true
     }
   }

   ============================================================================
*/
