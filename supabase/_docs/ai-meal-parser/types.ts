// Type definitions for AI Meal Parser Edge Function
// BUILD 138 - Nutrition Tracking

/**
 * Request payload for the ai-meal-parser function
 */
export interface MealParserRequest {
  /** Natural language description of the meal (required) */
  description: string;
  /** Optional URL to meal photo in Supabase Storage */
  image_url?: string;
}

/**
 * Meal type classification
 */
export type MealType = 'breakfast' | 'lunch' | 'dinner' | 'snack';

/**
 * AI confidence level for macro estimates
 */
export type ConfidenceLevel = 'high' | 'medium' | 'low';

/**
 * Parsed meal data with macro estimates
 */
export interface ParsedMeal {
  /** Classified meal type */
  meal_type: MealType;
  /** Individual food items identified in the meal */
  foods: string[];
  /** Total estimated calories */
  calories: number;
  /** Estimated protein in grams (rounded to 1 decimal) */
  protein: number;
  /** Estimated carbohydrates in grams (rounded to 1 decimal) */
  carbs: number;
  /** Estimated fats in grams (rounded to 1 decimal) */
  fats: number;
  /** AI confidence in the estimates */
  ai_confidence: ConfidenceLevel;
}

/**
 * Success response from ai-meal-parser function
 */
export interface MealParserSuccessResponse {
  success: true;
  /** Parsed meal data */
  parsed_meal: ParsedMeal;
  /** OpenAI model used for parsing */
  model_used: 'gpt-4-vision-preview' | 'gpt-4o-mini';
  /** Total tokens consumed by the API call */
  tokens_used: number;
}

/**
 * Error response from ai-meal-parser function
 */
export interface MealParserErrorResponse {
  success: false;
  /** Error message */
  error: string;
}

/**
 * Union type for all possible responses
 */
export type MealParserResponse = MealParserSuccessResponse | MealParserErrorResponse;

/**
 * Database row structure for nutrition_logs table
 * (For reference when saving parsed meals)
 */
export interface NutritionLog {
  id?: string;
  patient_id: string;
  log_date?: string;  // ISO date string, defaults to today
  meal_type: MealType;
  description: string;
  calories?: number;
  protein_grams?: number;
  carbs_grams?: number;
  fats_grams?: number;
  photo_url?: string;
  notes?: string;
  ai_generated?: boolean;  // Set to true for AI-parsed meals
  created_at?: string;
  updated_at?: string;
}

/**
 * Helper type guard to check if response is successful
 */
export function isMealParserSuccess(
  response: MealParserResponse
): response is MealParserSuccessResponse {
  return response.success === true;
}

/**
 * Helper type guard to check if response is an error
 */
export function isMealParserError(
  response: MealParserResponse
): response is MealParserErrorResponse {
  return response.success === false;
}
