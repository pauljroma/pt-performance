// Inferred TypeScript Types from Zod Schemas
// These types are derived from the Zod schemas in schemas.ts and represent
// the validated shapes of AI-generated responses.
//
// Use these types when you need to annotate variables, function parameters,
// or return types for AI response data that has been validated through
// the generateValidatedOutput utility.
//
// Usage:
//   import type { WorkoutRecommendation, ExerciseSubstitution } from '../_shared/ai-types.ts'

import { z } from "https://esm.sh/zod@3.23.8"
import {
  WorkoutRecommendationSchema,
  WorkoutRecommendationExerciseSchema,
  ExerciseSubstitutionSchema,
  ExerciseSubstitutionItemSchema,
  HealthCoachResponseSchema,
  ProgressiveOverloadSchema,
} from './schemas.ts'

// ============================================================================
// Inferred Types from Zod Schemas
// ============================================================================

/** A single exercise within a workout recommendation */
export type WorkoutRecommendationExercise = z.infer<typeof WorkoutRecommendationExerciseSchema>;

/** Full workout recommendation from AI Quick Pick */
export type WorkoutRecommendation = z.infer<typeof WorkoutRecommendationSchema>;

/** A single substitution option for an exercise */
export type ExerciseSubstitutionItem = z.infer<typeof ExerciseSubstitutionItemSchema>;

/** Exercise substitution response with original exercise and alternatives */
export type ExerciseSubstitution = z.infer<typeof ExerciseSubstitutionSchema>;

/** Health coach conversational response */
export type HealthCoachResponse = z.infer<typeof HealthCoachResponseSchema>;

/** Progressive overload suggestion for a specific exercise */
export type ProgressiveOverloadSuggestion = z.infer<typeof ProgressiveOverloadSchema>;

// ============================================================================
// Re-export schemas for convenience
// ============================================================================

export {
  WorkoutRecommendationSchema,
  WorkoutRecommendationExerciseSchema,
  ExerciseSubstitutionSchema,
  ExerciseSubstitutionItemSchema,
  HealthCoachResponseSchema,
  ProgressiveOverloadSchema,
} from './schemas.ts';

// ============================================================================
// Re-export utility
// ============================================================================

export {
  generateValidatedOutput,
  StructuredOutputError,
} from './validate-with-retry.ts';

export type { GenerateValidatedOutputOptions } from './validate-with-retry.ts';
