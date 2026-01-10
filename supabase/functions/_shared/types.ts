// Shared TypeScript Type Definitions for Edge Functions
// BUILD 138 - Type Safety Enhancement
// Used across all Edge Functions for consistent typing

// ============================================================================
// Database Row Types
// ============================================================================

export interface Patient {
  id: string;
  user_id: string;
  therapist_id?: string;
  whoop_oauth_credentials?: WHOOPCredentials;
  created_at: string;
  updated_at: string;
}

export interface Therapist {
  id: string;
  user_id: string;
  created_at: string;
}

export interface ExerciseTemplate {
  id: string;
  name: string;
  equipment_required: string[];
  muscle_groups: string[];
  difficulty_level?: string;
  created_at: string;
}

export interface Session {
  id: string;
  name: string;
  description?: string;
  sequence: number;
  session_number?: number;
  exercises?: any; // JSONB
  notes?: string;
  created_at: string;
}

export interface SessionExercise {
  id: string;
  session_id: string;
  exercise_id: string;
  exercise_templates?: ExerciseTemplate;
  prescribed_sets: number;
  prescribed_reps: number;
  prescribed_rpe?: number;
  created_at: string;
}

export interface Recommendation {
  id: string;
  patient_id: string;
  session_id: string;
  scheduled_date: string;
  recommendation_type: 'equipment_substitution' | 'intensity_adjustment' | 'recovery_modification';
  patch: SubstitutionPatch | any; // JSONB
  rationale: string;
  status: 'pending' | 'applied' | 'rejected' | 'undone';
  created_at: string;
  applied_at?: string;
  rejected_at?: string;
}

export interface SessionInstance {
  id: string;
  patient_id: string;
  template_session_id: string;
  scheduled_date: string;
  instance_data: any; // JSONB containing session with exercises
  created_from_recommendation_id?: string;
  created_at: string;
}

export interface DailyReadiness {
  id: string;
  patient_id: string;
  date: string;
  sleep_hours?: number;
  soreness_level?: number;
  energy_level?: number;
  stress_level?: number;
  readiness_score?: number;
  equipment_available?: string[];
  intensity_preference?: 'recovery' | 'standard' | 'go_hard';
  whoop_recovery_score?: number;
  whoop_sleep_performance_percentage?: number;
  whoop_hrv_rmssd?: number;
  whoop_strain?: number;
  whoop_synced_at?: string;
  notes?: string;
  created_at: string;
  updated_at: string;
}

export interface NutritionRecommendation {
  id: string;
  patient_id: string;
  recommendation_text: string;
  target_macros: MacroTargets;
  reasoning: string;
  context?: any; // JSONB
  created_at: string;
}

export interface NutritionLog {
  id: string;
  patient_id: string;
  meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  description: string;
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
  photo_url?: string;
  ai_generated: boolean;
  logged_at: string;
}

export interface ScheduledSession {
  id: string;
  patient_id: string;
  session_id: string;
  scheduled_date: string;
  scheduled_time: string;
  status: 'scheduled' | 'completed' | 'cancelled';
  sessions?: Session;
}

export interface NutritionGoal {
  id: string;
  patient_id: string;
  target_calories: number;
  target_protein: number;
  target_carbs: number;
  target_fats: number;
}

// ============================================================================
// JSONB Structured Types
// ============================================================================

export interface SubstitutionPatch {
  exercise_substitutions: ExerciseSubstitution[];
  intensity_adjustments: IntensityAdjustment[];
}

export interface ExerciseSubstitution {
  original_exercise_id: string;
  original_exercise_name: string;
  substitute_exercise_id: string;
  substitute_exercise_name: string;
  reason: string;
}

export interface IntensityAdjustment {
  exercise_id: string;
  exercise_name: string;
  original_sets: number;
  adjusted_sets: number;
  original_reps: number;
  adjusted_reps: number;
  original_rpe?: number;
  adjusted_rpe?: number;
  reason: string;
}

export interface MacroTargets {
  protein: number;
  carbs: number;
  fats: number;
  calories: number;
}

export interface WHOOPCredentials {
  access_token: string;
  refresh_token: string;
  expires_at: string;
  athlete_id?: string;
}

// ============================================================================
// Request/Response Types
// ============================================================================

export interface GenerateSubstitutionRequest {
  patient_id: string;
  session_id: string;
  scheduled_date: string;
  equipment_available: string[];
  intensity_preference: 'recovery' | 'standard' | 'go_hard';
  readiness_score?: number;
  whoop_recovery_score?: number;
}

export interface GenerateSubstitutionResponse {
  success: boolean;
  recommendation_id: string;
  patch: SubstitutionPatch;
  rationale: string;
  status: 'pending';
  tokens_used: number;
  exercises_substituted: number;
}

export interface ApplySubstitutionRequest {
  recommendation_id: string;
}

export interface ApplySubstitutionResponse {
  success: boolean;
  data: {
    session_instance_id: string;
    recommendation_id: string;
    applied_at: string;
  };
  message: string;
}

export interface SyncWhoopRequest {
  patient_id: string;
}

export interface SyncWhoopResponse {
  success: boolean;
  cached?: boolean;
  mock?: boolean;
  data: WHOOPRecoveryData;
  updated_readiness?: DailyReadiness;
  message?: string;
  next_sync_available_in_minutes?: number;
}

export interface WHOOPRecoveryData {
  recovery_score: number;
  sleep_performance_percentage: number;
  hrv_rmssd: number;
  strain: number;
  synced_at: string;
}

export interface NutritionRecommendationRequest {
  patient_id: string;
  time_of_day: string;
  available_foods?: string[];
  context?: {
    next_workout_time?: string;
    workout_type?: string;
  };
}

export interface NutritionRecommendationResponse {
  recommendation_id: string;
  recommendation_text: string;
  target_macros: MacroTargets;
  reasoning: string;
  suggested_timing: string;
  cached?: boolean;
}

export interface MealParserRequest {
  description: string;
  image_url?: string;
}

export interface MealParserResponse {
  success: boolean;
  parsed_meal: ParsedMeal;
  model_used: string;
  tokens_used: number;
}

export interface ParsedMeal {
  meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack';
  foods: string[];
  calories: number;
  protein: number;
  carbs: number;
  fats: number;
  ai_confidence: 'high' | 'medium' | 'low';
}

// ============================================================================
// OpenAI API Types
// ============================================================================

export interface OpenAIMessage {
  role: 'system' | 'user' | 'assistant';
  content: string | OpenAIMessageContent[];
}

export interface OpenAIMessageContent {
  type: 'text' | 'image_url';
  text?: string;
  image_url?: {
    url: string;
    detail?: 'low' | 'high' | 'auto';
  };
}

export interface OpenAICompletionRequest {
  model: string;
  messages: OpenAIMessage[];
  max_tokens?: number;
  temperature?: number;
  response_format?: { type: 'json_object' };
}

export interface OpenAICompletionResponse {
  id: string;
  object: string;
  created: number;
  model: string;
  choices: OpenAIChoice[];
  usage: OpenAIUsage;
}

export interface OpenAIChoice {
  index: number;
  message: {
    role: string;
    content: string;
  };
  finish_reason: string;
}

export interface OpenAIUsage {
  prompt_tokens: number;
  completion_tokens: number;
  total_tokens: number;
}

// ============================================================================
// WHOOP API Types
// ============================================================================

export interface WHOOPAPIRecovery {
  cycle_id: number;
  sleep_id: number;
  user_calibrating: boolean;
  recovery_score: number;
  resting_heart_rate: number;
  hrv_rmssd_milli: number;
  spo2_percentage: number;
  skin_temp_celsius: number;
}

export interface WHOOPTokenResponse {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: string;
}

// ============================================================================
// Supabase Error Types
// ============================================================================

export interface SupabaseError {
  message: string;
  details?: string;
  hint?: string;
  code?: string;
}

export interface PostgrestResponse<T> {
  data: T | null;
  error: SupabaseError | null;
  count?: number | null;
  status: number;
  statusText: string;
}

// ============================================================================
// Validation Types
// ============================================================================

export interface ValidationError {
  field: string;
  message: string;
  code: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

// ============================================================================
// Error Response Types
// ============================================================================

export interface ErrorResponse {
  error: string;
  details?: string;
  code?: string;
  field?: string;
  success: false;
}

// ============================================================================
// Type Guards
// ============================================================================

export function isSupabaseError(error: unknown): error is SupabaseError {
  return (
    typeof error === 'object' &&
    error !== null &&
    'message' in error &&
    typeof (error as SupabaseError).message === 'string'
  );
}

export function isOpenAIError(error: unknown): error is { message: string; type: string } {
  return (
    typeof error === 'object' &&
    error !== null &&
    'message' in error &&
    'type' in error
  );
}

export function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

export function isValidDate(dateString: string): boolean {
  const date = new Date(dateString);
  return date instanceof Date && !isNaN(date.getTime());
}

export function isValidMealType(type: string): type is ParsedMeal['meal_type'] {
  return ['breakfast', 'lunch', 'dinner', 'snack'].includes(type);
}

export function isValidConfidenceLevel(level: string): level is ParsedMeal['ai_confidence'] {
  return ['high', 'medium', 'low'].includes(level);
}

export function isValidIntensityPreference(pref: string): pref is DailyReadiness['intensity_preference'] {
  return ['recovery', 'standard', 'go_hard'].includes(pref);
}

export function isValidRecommendationType(type: string): type is Recommendation['recommendation_type'] {
  return ['equipment_substitution', 'intensity_adjustment', 'recovery_modification'].includes(type);
}

export function isValidRecommendationStatus(status: string): status is Recommendation['status'] {
  return ['pending', 'applied', 'rejected', 'undone'].includes(status);
}
