// Type Definitions for sync-whoop-recovery Edge Function
// Build 138 - WHOOP Integration MVP

// ============================================================================
// Request/Response Interfaces
// ============================================================================

/**
 * Request body for sync-whoop-recovery Edge Function
 */
export interface SyncWhoopRequest {
  /** UUID of patient to sync WHOOP data for */
  patient_id: string;
}

/**
 * Response from sync-whoop-recovery Edge Function
 */
export interface WHOOPRecoveryResponse {
  /** WHOOP recovery score (0-100, higher is better) */
  recovery_score: number;

  /** Sleep performance percentage (0-100) */
  sleep_performance_percentage: number;

  /** Heart rate variability in milliseconds (RMSSD) */
  hrv_rmssd: number;

  /** Estimated strain (0-21, higher is more demanding) */
  strain: number;

  /** ISO timestamp when data was synced */
  synced_at: string;
}

/**
 * Success response structure
 */
export interface SyncWhoopSuccessResponse {
  success: true;
  data: WHOOPRecoveryResponse;
  updated_readiness: DailyReadinessRecord;
  mock?: boolean;
  message?: string;
}

/**
 * Cached response structure
 */
export interface SyncWhoopCachedResponse {
  success: true;
  cached: true;
  message: string;
  next_sync_available_in_minutes: number;
}

/**
 * Error response structure
 */
export interface SyncWhoopErrorResponse {
  error: string;
  details?: string;
}

// ============================================================================
// WHOOP API Interfaces
// ============================================================================

/**
 * WHOOP OAuth credentials stored in patients.whoop_oauth_credentials
 */
export interface WHOOPCredentials {
  /** OAuth access token (expires in 1 hour) */
  access_token: string;

  /** OAuth refresh token (used to get new access token) */
  refresh_token: string;

  /** ISO timestamp when access_token expires */
  expires_at: string;

  /** WHOOP athlete ID (optional) */
  athlete_id?: string;
}

/**
 * WHOOP OAuth token refresh response
 * Docs: https://developer.whoop.com/docs/developing/oauth/
 */
export interface WHOOPOAuthTokenResponse {
  /** New access token */
  access_token: string;

  /** New refresh token (may be same as old one) */
  refresh_token: string;

  /** Seconds until access_token expires (typically 3600) */
  expires_in: number;

  /** Token type (always "Bearer") */
  token_type: string;

  /** OAuth scopes granted */
  scope?: string;
}

/**
 * WHOOP Recovery API response
 * Docs: https://developer.whoop.com/docs/developing/user-data/recovery
 */
export interface WHOOPRecoveryAPIResponse {
  /** Array of recovery records (most recent first) */
  records: WHOOPAPIRecovery[];

  /** Pagination token for next page */
  next_token?: string;
}

/**
 * Individual WHOOP recovery record
 */
export interface WHOOPAPIRecovery {
  /** Cycle ID this recovery belongs to */
  cycle_id: number;

  /** Sleep ID this recovery is based on */
  sleep_id: number;

  /** Whether user is still calibrating (first 30 days) */
  user_calibrating: boolean;

  /** Recovery score (0-100) */
  recovery_score: number;

  /** Resting heart rate in BPM */
  resting_heart_rate: number;

  /** Heart rate variability in milliseconds (RMSSD) */
  hrv_rmssd_milli: number;

  /** Blood oxygen saturation percentage */
  spo2_percentage: number;

  /** Skin temperature in Celsius */
  skin_temp_celsius: number;
}

// ============================================================================
// Database Interfaces
// ============================================================================

/**
 * daily_readiness table record with WHOOP columns
 */
export interface DailyReadinessRecord {
  id: string;
  patient_id: string;
  date: string;

  // Core metrics (1-10 scale)
  sleep_hours?: number;
  soreness_level?: number;
  energy_level?: number;
  stress_level?: number;

  // Calculated score
  readiness_score?: number;

  // WHOOP metrics (added in BUILD 138)
  whoop_recovery_score?: number;
  whoop_sleep_performance_percentage?: number;
  whoop_hrv_rmssd?: number;
  whoop_strain?: number;
  whoop_synced_at?: string;

  // Optional fields
  notes?: string;

  // Metadata
  created_at: string;
  updated_at: string;
}

/**
 * Patient record with WHOOP credentials
 */
export interface PatientWithWHOOP {
  id: string;
  whoop_oauth_credentials?: WHOOPCredentials;
  // ... other patient fields
}

// ============================================================================
// Configuration Constants
// ============================================================================

/**
 * WHOOP API endpoints
 */
export const WHOOP_ENDPOINTS = {
  /** Base URL for WHOOP API v1 */
  API_BASE: 'https://api.prod.whoop.com/developer/v1',

  /** OAuth token endpoint */
  OAUTH_TOKEN: 'https://api.prod.whoop.com/oauth/oauth2/token',

  /** Recovery data endpoint */
  RECOVERY: 'https://api.prod.whoop.com/developer/v1/recovery',

  /** Strain data endpoint */
  STRAIN: 'https://api.prod.whoop.com/developer/v1/cycle',

  /** Sleep data endpoint */
  SLEEP: 'https://api.prod.whoop.com/developer/v1/activity/sleep',
} as const;

/**
 * Cache configuration
 */
export const CACHE_CONFIG = {
  /** Don't sync more than once per hour */
  DURATION_HOURS: 1,

  /** Convert hours to milliseconds */
  DURATION_MS: 1 * 60 * 60 * 1000,
} as const;

/**
 * WHOOP data ranges and constraints
 */
export const WHOOP_RANGES = {
  /** Recovery score range (0-100) */
  RECOVERY_SCORE: { min: 0, max: 100 },

  /** Strain range (0-21) */
  STRAIN: { min: 0, max: 21 },

  /** HRV range (varies by individual, typically 20-100ms) */
  HRV_RMSSD: { min: 0, max: 200 },

  /** Sleep performance range (0-100%) */
  SLEEP_PERFORMANCE: { min: 0, max: 100 },
} as const;

// ============================================================================
// Helper Type Guards
// ============================================================================

/**
 * Check if patient has WHOOP credentials
 */
export function hasWHOOPCredentials(
  patient: PatientWithWHOOP
): patient is PatientWithWHOOP & { whoop_oauth_credentials: WHOOPCredentials } {
  return patient.whoop_oauth_credentials !== undefined &&
         patient.whoop_oauth_credentials !== null &&
         'access_token' in patient.whoop_oauth_credentials &&
         'refresh_token' in patient.whoop_oauth_credentials &&
         'expires_at' in patient.whoop_oauth_credentials;
}

/**
 * Check if WHOOP credentials are expired
 */
export function areCredentialsExpired(credentials: WHOOPCredentials): boolean {
  const expiresAt = new Date(credentials.expires_at);
  return Date.now() >= expiresAt.getTime();
}

/**
 * Check if recovery data should be refreshed (cache expired)
 */
export function shouldRefreshRecovery(syncedAt: string | null | undefined): boolean {
  if (!syncedAt) return true;

  const syncTime = new Date(syncedAt).getTime();
  const hoursSinceSync = (Date.now() - syncTime) / (1000 * 60 * 60);

  return hoursSinceSync >= CACHE_CONFIG.DURATION_HOURS;
}

/**
 * Validate recovery score is in valid range
 */
export function isValidRecoveryScore(score: number): boolean {
  return score >= WHOOP_RANGES.RECOVERY_SCORE.min &&
         score <= WHOOP_RANGES.RECOVERY_SCORE.max;
}

/**
 * Validate strain is in valid range
 */
export function isValidStrain(strain: number): boolean {
  return strain >= WHOOP_RANGES.STRAIN.min &&
         strain <= WHOOP_RANGES.STRAIN.max;
}

/**
 * Validate HRV is in valid range
 */
export function isValidHRV(hrv: number): boolean {
  return hrv >= WHOOP_RANGES.HRV_RMSSD.min &&
         hrv <= WHOOP_RANGES.HRV_RMSSD.max;
}

// ============================================================================
// Utility Functions
// ============================================================================

/**
 * Estimate strain from recovery score
 * Higher recovery → lower recent strain (inverse relationship)
 */
export function estimateStrainFromRecovery(recoveryScore: number): number {
  const estimatedStrain = 21 - (recoveryScore / 100) * 10;
  return Math.max(
    WHOOP_RANGES.STRAIN.min,
    Math.min(WHOOP_RANGES.STRAIN.max, estimatedStrain)
  );
}

/**
 * Calculate minutes until next sync is allowed
 */
export function minutesUntilNextSync(syncedAt: string): number {
  const syncTime = new Date(syncedAt).getTime();
  const hoursSinceSync = (Date.now() - syncTime) / (1000 * 60 * 60);
  const hoursRemaining = CACHE_CONFIG.DURATION_HOURS - hoursSinceSync;
  return Math.max(0, Math.round(hoursRemaining * 60));
}

/**
 * Calculate access token expiration from expires_in seconds
 */
export function calculateExpiresAt(expiresInSeconds: number): string {
  return new Date(Date.now() + (expiresInSeconds * 1000)).toISOString();
}
