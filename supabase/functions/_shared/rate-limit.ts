// Shared Rate Limiting Module for Edge Functions
// In-memory sliding window rate limiter (per edge function instance)
// Edge function instances are short-lived so in-memory is appropriate.

// ============================================================================
// Types
// ============================================================================

export interface RateLimitConfig {
  /** Time window in milliseconds (default: 60000 = 1 minute) */
  windowMs: number;
  /** Maximum requests allowed per window (default: 30) */
  maxRequests: number;
}

export interface RateLimitResult {
  /** Whether the request is allowed */
  allowed: boolean;
  /** Number of requests remaining in the current window */
  remaining: number;
  /** Milliseconds until the window resets */
  resetMs: number;
}

// ============================================================================
// Internal State
// ============================================================================

// Map of key -> array of request timestamps (sliding window)
const requestLog = new Map<string, number[]>();

// Default configuration
const DEFAULT_CONFIG: RateLimitConfig = {
  windowMs: 60_000,  // 1 minute
  maxRequests: 30,
};

// ============================================================================
// Rate Limiting
// ============================================================================

/**
 * Check if a request is allowed under the rate limit.
 *
 * Uses a sliding window approach: maintains an array of timestamps for each key,
 * and counts how many fall within the current window.
 *
 * @param key    - Identifier for rate limiting (user ID, IP address, etc.)
 * @param config - Optional rate limit configuration overrides
 * @returns Whether the request is allowed, remaining quota, and reset time
 */
export function checkRateLimit(
  key: string,
  config?: Partial<RateLimitConfig>,
): RateLimitResult {
  const { windowMs, maxRequests } = { ...DEFAULT_CONFIG, ...config };
  const now = Date.now();
  const windowStart = now - windowMs;

  // Get or initialize the request log for this key
  let timestamps = requestLog.get(key);
  if (!timestamps) {
    timestamps = [];
    requestLog.set(key, timestamps);
  }

  // Prune timestamps outside the current window
  const activeTimestamps = timestamps.filter((ts) => ts > windowStart);
  requestLog.set(key, activeTimestamps);

  // Check if the request is within limits
  if (activeTimestamps.length >= maxRequests) {
    // Find when the oldest request in the window will expire
    const oldestInWindow = activeTimestamps[0];
    const resetMs = oldestInWindow + windowMs - now;

    return {
      allowed: false,
      remaining: 0,
      resetMs: Math.max(resetMs, 0),
    };
  }

  // Allow the request and record the timestamp
  activeTimestamps.push(now);

  const remaining = maxRequests - activeTimestamps.length;

  // Reset time is when the oldest active timestamp expires
  const oldestActive = activeTimestamps[0];
  const resetMs = oldestActive + windowMs - now;

  return {
    allowed: true,
    remaining,
    resetMs: Math.max(resetMs, 0),
  };
}

// ============================================================================
// Response Builder
// ============================================================================

/**
 * Build a 429 Too Many Requests response with standard headers.
 *
 * @param resetMs - Milliseconds until the rate limit window resets
 * @returns A Response object with 429 status and Retry-After header
 */
export function rateLimitResponse(resetMs: number): Response {
  const retryAfterSeconds = Math.ceil(resetMs / 1000);

  return new Response(
    JSON.stringify({
      error: 'Too many requests',
      message: `Rate limit exceeded. Please retry after ${retryAfterSeconds} seconds.`,
      code: 'ERR_RATE_LIMIT',
      retry_after_seconds: retryAfterSeconds,
    }),
    {
      status: 429,
      headers: {
        'Content-Type': 'application/json',
        'Retry-After': String(retryAfterSeconds),
        'X-RateLimit-Reset': String(retryAfterSeconds),
        // CORS headers so the client can read the error
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
      },
    },
  );
}
