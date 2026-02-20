// Structured Output Zod Schemas for AI Edge Functions
// Defines validated response shapes for all AI-powered features.
// These schemas are used with the validate-with-retry utility to ensure
// Claude API responses conform to expected structures before consumption.
//
// Usage:
//   import { WorkoutRecommendationSchema } from '../_shared/schemas.ts'
//   import { generateValidatedOutput } from '../_shared/validate-with-retry.ts'
//
//   const result = await generateValidatedOutput(prompt, WorkoutRecommendationSchema)

import { z } from "https://esm.sh/zod@3.23.8"

// ============================================================================
// WorkoutRecommendation -- used by AI Quick Pick
// ============================================================================

export const WorkoutRecommendationExerciseSchema = z.object({
  exercise_name: z.string().describe("Name of the exercise"),
  sets: z.number().int().min(1).max(10).describe("Number of sets (1-10)"),
  reps: z.number().int().min(1).max(50).describe("Number of reps per set (1-50)"),
  load_suggestion: z.string().optional().describe("Suggested load, e.g. '135 lbs' or 'bodyweight'"),
  modification_notes: z.string().optional().describe("Notes on modifications for the patient"),
  intensity: z.enum(["low", "moderate", "high"]).describe("Target intensity level"),
});

export const WorkoutRecommendationSchema = z.object({
  exercises: z
    .array(WorkoutRecommendationExerciseSchema)
    .min(1)
    .describe("List of recommended exercises for this session"),
  warmup_notes: z.string().optional().describe("Warm-up instructions or notes"),
  cooldown_notes: z.string().optional().describe("Cool-down instructions or notes"),
  session_duration_minutes: z
    .number()
    .min(10)
    .max(120)
    .describe("Estimated total session duration in minutes (10-120)"),
  rationale: z
    .string()
    .describe("Explanation of why this workout was recommended given the patient's context"),
});

// ============================================================================
// ExerciseSubstitution -- used when patient can't do an exercise
// ============================================================================

export const ExerciseSubstitutionItemSchema = z.object({
  exercise_name: z.string().describe("Name of the substitute exercise"),
  reason: z.string().describe("Why this substitution is appropriate"),
  difficulty_comparison: z
    .enum(["easier", "similar", "harder"])
    .describe("How the substitute compares in difficulty to the original"),
  muscles_targeted: z
    .array(z.string())
    .describe("Primary muscle groups targeted by the substitute"),
  equipment_needed: z
    .array(z.string())
    .describe("Equipment required for the substitute exercise"),
});

export const ExerciseSubstitutionSchema = z.object({
  original_exercise: z.string().describe("Name of the exercise being substituted"),
  substitutions: z
    .array(ExerciseSubstitutionItemSchema)
    .min(1)
    .max(5)
    .describe("List of 1-5 substitute exercise options"),
});

// ============================================================================
// HealthCoachResponse -- used by AI health coach
// ============================================================================

export const HealthCoachResponseSchema = z.object({
  message: z
    .string()
    .describe("The coach's conversational response to the patient"),
  action_items: z
    .array(z.string())
    .max(5)
    .describe("Actionable steps for the patient (up to 5)"),
  references: z
    .array(z.string())
    .optional()
    .describe("Supporting references or citations"),
  follow_up_question: z
    .string()
    .optional()
    .describe("A follow-up question to continue the conversation"),
  severity: z
    .enum(["info", "suggestion", "warning"])
    .default("info")
    .describe("Severity level of the coaching response"),
});

// ============================================================================
// ProgressiveOverloadSuggestion -- used by progressive overload engine
// ============================================================================

export const ProgressiveOverloadSchema = z.object({
  exercise_name: z.string().describe("Name of the exercise"),
  current_load: z.number().describe("Current working load in lbs"),
  suggested_load: z.number().describe("Recommended next load in lbs"),
  current_reps: z.number().describe("Current rep count per set"),
  suggested_reps: z.number().describe("Recommended next rep count per set"),
  progression_type: z
    .enum(["load", "volume", "intensity", "tempo"])
    .describe("The type of progression being recommended"),
  confidence: z
    .number()
    .min(0)
    .max(1)
    .describe("Confidence score for this recommendation (0.0-1.0)"),
  rationale: z
    .string()
    .describe("Explanation of why this progression is recommended"),
});
