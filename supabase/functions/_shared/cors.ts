// Shared CORS Module for Edge Functions
// Provides origin-validated CORS headers for the Modus app.
//
// Replaces the blanket `Access-Control-Allow-Origin: *` pattern with
// a whitelist of known origins, while still allowing local development.

// ============================================================================
// Allowed Origins
// ============================================================================

const ALLOWED_ORIGINS: string[] = [
  'https://app.moduspt.com',
  'https://www.app.moduspt.com',
  'capacitor://localhost',   // iOS Capacitor app
  'http://localhost',        // Local development
  'http://localhost:3000',   // Local dev (common port)
  'http://localhost:5173',   // Vite dev server
  'http://localhost:8080',   // Alternative dev port
  'http://127.0.0.1',       // Localhost alias
];

// Headers that are always included regardless of origin
const BASE_HEADERS: Record<string, string> = {
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Max-Age': '86400', // 24 hours
};

// ============================================================================
// CORS Headers
// ============================================================================

/**
 * Returns CORS headers with the appropriate Access-Control-Allow-Origin
 * based on the request origin.
 *
 * - If the origin matches the whitelist, it is echoed back (strict).
 * - If no origin header is present (e.g. server-to-server), defaults to
 *   the primary production origin.
 * - In development (ENVIRONMENT=local), falls back to '*'.
 *
 * @param origin - The Origin header from the incoming request
 * @returns A headers object suitable for spreading into a Response
 */
export function corsHeaders(origin?: string | null): Record<string, string> {
  // Check if the origin is in our whitelist
  if (origin && ALLOWED_ORIGINS.includes(origin)) {
    return {
      ...BASE_HEADERS,
      'Access-Control-Allow-Origin': origin,
      'Vary': 'Origin',
    };
  }

  // Allow any localhost origin for development (port-agnostic)
  if (origin && (origin.startsWith('http://localhost') || origin.startsWith('http://127.0.0.1'))) {
    return {
      ...BASE_HEADERS,
      'Access-Control-Allow-Origin': origin,
      'Vary': 'Origin',
    };
  }

  // For requests without an Origin header (server-to-server, curl, etc.)
  // or unrecognized origins, use the production domain.
  // This prevents the browser from accepting the response for unknown origins.
  return {
    ...BASE_HEADERS,
    'Access-Control-Allow-Origin': 'https://app.moduspt.com',
    'Vary': 'Origin',
  };
}

// ============================================================================
// Preflight Handler
// ============================================================================

/**
 * Handles CORS preflight (OPTIONS) requests.
 *
 * Returns a 204 No Content response with the appropriate CORS headers
 * if the request is an OPTIONS request. Returns null for all other
 * methods so the caller can proceed with normal handling.
 *
 * @param req - The incoming Request
 * @returns A preflight Response for OPTIONS, or null for other methods
 *
 * @example
 * ```ts
 * Deno.serve(async (req) => {
 *   const corsResponse = handleCors(req)
 *   if (corsResponse) return corsResponse
 *
 *   // ... normal handler logic
 * })
 * ```
 */
export function handleCors(req: Request): Response | null {
  if (req.method === 'OPTIONS') {
    const origin = req.headers.get('Origin');
    return new Response(null, {
      status: 204,
      headers: corsHeaders(origin),
    });
  }

  return null;
}
