// Validation Retry Utility for AI Edge Functions
// Calls Claude API, parses the response as JSON, validates against a Zod schema,
// and retries with error context if validation fails.
//
// This eliminates the fragile manual JSON parsing and ad-hoc validation
// scattered across edge functions, replacing it with a single robust utility
// that guarantees type-safe, schema-validated outputs.
//
// Usage:
//   import { generateValidatedOutput } from '../_shared/validate-with-retry.ts'
//   import { WorkoutRecommendationSchema } from '../_shared/schemas.ts'
//
//   const result = await generateValidatedOutput(
//     "Recommend a workout for a patient recovering from knee surgery...",
//     WorkoutRecommendationSchema,
//     { systemPrompt: "You are a physical therapy AI assistant." }
//   )
//   // result is fully typed as WorkoutRecommendation

import { z } from "https://esm.sh/zod@3.23.8"

// ============================================================================
// Types
// ============================================================================

export interface GenerateValidatedOutputOptions {
  /** Maximum number of retry attempts (default: 3) */
  maxRetries?: number;
  /** Anthropic model to use (default: 'claude-sonnet-4-20250514') */
  model?: string;
  /** System prompt to set context for the AI */
  systemPrompt?: string;
  /** Temperature for generation (default: 0.3) */
  temperature?: number;
  /** Max tokens for the response (default: 2048) */
  maxTokens?: number;
  /** Anthropic API key override (default: reads ANTHROPIC_API_KEY env var) */
  apiKey?: string;
}

export class StructuredOutputError extends Error {
  constructor(
    message: string,
    public readonly attempts: number,
    public readonly lastRawResponse: string,
    public readonly zodErrors: z.ZodError | null,
  ) {
    super(message);
    this.name = 'StructuredOutputError';
  }
}

// ============================================================================
// Internal Helpers
// ============================================================================

/**
 * Extracts JSON from a string that might contain markdown code fences
 * or other wrapper text around the JSON object.
 */
function extractJSON(text: string): string {
  // First, try to strip markdown code fences: ```json ... ``` or ``` ... ```
  const fenceMatch = text.match(/```(?:json)?\s*([\s\S]*?)```/);
  if (fenceMatch) {
    return fenceMatch[1]!.trim();
  }

  // Then try to extract the outermost JSON object or array
  const jsonMatch = text.match(/(\{[\s\S]*\}|\[[\s\S]*\])/);
  if (jsonMatch) {
    return jsonMatch[1]!;
  }

  // Fall back to the raw text
  return text.trim();
}

/**
 * Formats Zod validation errors into a human-readable string
 * suitable for sending back to Claude as correction context.
 */
function formatZodErrors(error: z.ZodError): string {
  return error.issues
    .map((issue) => {
      const path = issue.path.length > 0 ? issue.path.join('.') : '(root)';
      return `  - ${path}: ${issue.message} (${issue.code})`;
    })
    .join('\n');
}

/**
 * Builds the schema description string from a Zod schema to include
 * in the prompt, helping Claude understand the expected shape.
 */
function buildSchemaHint(schema: z.ZodTypeAny): string {
  try {
    // Generate a JSON-friendly description of the schema shape
    // by introspecting the Zod schema definition
    return describeZodShape(schema, 0);
  } catch {
    return '(schema description unavailable)';
  }
}

/**
 * Recursively describes a Zod schema shape as a TypeScript-like string.
 */
function describeZodShape(schema: z.ZodTypeAny, depth: number): string {
  const indent = '  '.repeat(depth);
  const innerIndent = '  '.repeat(depth + 1);

  // Unwrap defaults, optionals, etc.
  if (schema instanceof z.ZodDefault) {
    return describeZodShape(schema._def.innerType, depth);
  }
  if (schema instanceof z.ZodOptional) {
    return describeZodShape(schema._def.innerType, depth) + ' (optional)';
  }

  if (schema instanceof z.ZodObject) {
    const shape = schema._def.shape();
    const entries = Object.entries(shape as Record<string, z.ZodTypeAny>);
    if (entries.length === 0) return '{}';

    const fields = entries.map(([key, value]) => {
      const isOptional = value instanceof z.ZodOptional || value instanceof z.ZodDefault;
      const desc = (value as z.ZodTypeAny)._def.description;
      const typeStr = describeZodShape(value as z.ZodTypeAny, depth + 1);
      const descSuffix = desc ? ` // ${desc}` : '';
      return `${innerIndent}${key}${isOptional ? '?' : ''}: ${typeStr}${descSuffix}`;
    });

    return `{\n${fields.join(',\n')}\n${indent}}`;
  }

  if (schema instanceof z.ZodArray) {
    const elementType = describeZodShape(schema._def.type, depth);
    return `${elementType}[]`;
  }

  if (schema instanceof z.ZodEnum) {
    const values = schema._def.values as string[];
    return values.map((v: string) => `"${v}"`).join(' | ');
  }

  if (schema instanceof z.ZodString) return 'string';
  if (schema instanceof z.ZodNumber) return 'number';
  if (schema instanceof z.ZodBoolean) return 'boolean';

  return 'unknown';
}

// ============================================================================
// Main Export
// ============================================================================

/**
 * Calls the Claude API with a prompt, parses the response as JSON, and
 * validates it against a Zod schema. If validation fails, retries with
 * error context included in the prompt so Claude can self-correct.
 *
 * @param prompt  - The user prompt describing what to generate
 * @param schema  - A Zod schema defining the expected response shape
 * @param options - Configuration options (retries, model, temperature, etc.)
 * @returns A validated, typed result matching the Zod schema
 * @throws StructuredOutputError if all retry attempts fail
 *
 * @example
 * ```ts
 * const recommendation = await generateValidatedOutput(
 *   "Generate a workout for a 35yo male recovering from ACL surgery...",
 *   WorkoutRecommendationSchema,
 *   { systemPrompt: "You are a PT AI assistant.", maxRetries: 2 }
 * );
 * // recommendation: WorkoutRecommendation (fully typed)
 * ```
 */
export async function generateValidatedOutput<T>(
  prompt: string,
  schema: z.ZodSchema<T>,
  options?: GenerateValidatedOutputOptions,
): Promise<T> {
  const {
    maxRetries = 3,
    model = 'claude-sonnet-4-20250514',
    systemPrompt,
    temperature = 0.3,
    maxTokens = 2048,
    apiKey,
  } = options ?? {};

  const anthropicApiKey = apiKey ?? Deno.env.get('ANTHROPIC_API_KEY');
  if (!anthropicApiKey) {
    throw new Error('ANTHROPIC_API_KEY environment variable is not set');
  }

  // Build a schema description to guide Claude's output
  const schemaHint = buildSchemaHint(schema as z.ZodTypeAny);

  // Build the initial system prompt with schema guidance
  const baseSystemPrompt = [
    systemPrompt ?? 'You are a helpful AI assistant.',
    '',
    'RESPONSE FORMAT REQUIREMENTS:',
    'You MUST respond with valid JSON only. No markdown, no explanation outside JSON.',
    'Your JSON response must conform to the following TypeScript-like schema:',
    '',
    schemaHint,
    '',
    'Respond with ONLY the JSON object. Do not wrap it in code fences or add any other text.',
  ].join('\n');

  let lastRawResponse = '';
  let lastZodError: z.ZodError | null = null;

  for (let attempt = 1; attempt <= maxRetries; attempt++) {
    // Build messages for this attempt
    let userMessage = prompt;

    // On retry attempts, include the validation error context
    if (attempt > 1 && lastZodError) {
      userMessage = [
        prompt,
        '',
        '--- VALIDATION ERROR FROM PREVIOUS ATTEMPT ---',
        `Attempt ${attempt - 1} of ${maxRetries} failed validation.`,
        'Your previous response had the following validation errors:',
        '',
        formatZodErrors(lastZodError),
        '',
        'Your previous (invalid) response was:',
        lastRawResponse.substring(0, 1000),
        '',
        'Please fix these errors and respond with valid JSON that conforms to the schema.',
        '--- END VALIDATION ERROR ---',
      ].join('\n');
    }

    console.log(`[validate-with-retry] Attempt ${attempt}/${maxRetries} using ${model}`);

    // Call Claude API
    const response = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': anthropicApiKey,
        'anthropic-version': '2023-06-01',
      },
      body: JSON.stringify({
        model,
        max_tokens: maxTokens,
        temperature,
        system: baseSystemPrompt,
        messages: [
          { role: 'user', content: userMessage },
        ],
      }),
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error(
        `[validate-with-retry] Anthropic API error (attempt ${attempt}):`,
        response.status,
        errorText,
      );

      // If it's a rate limit or server error, retry; otherwise throw immediately
      if (response.status === 429 || response.status >= 500) {
        if (attempt < maxRetries) {
          const backoffMs = Math.min(1000 * Math.pow(2, attempt - 1), 10000);
          console.warn(`[validate-with-retry] Retrying in ${backoffMs}ms...`);
          await new Promise((resolve) => setTimeout(resolve, backoffMs));
          continue;
        }
      }

      throw new StructuredOutputError(
        `Anthropic API error (${response.status}): ${errorText.substring(0, 200)}`,
        attempt,
        errorText,
        null,
      );
    }

    const completion = await response.json();

    // Extract text content from Anthropic response
    const responseText: string | undefined = completion.content?.[0]?.text;
    if (!responseText) {
      console.error(`[validate-with-retry] No text content in response (attempt ${attempt})`);
      lastRawResponse = JSON.stringify(completion);
      lastZodError = null;
      if (attempt < maxRetries) continue;
      throw new StructuredOutputError(
        'No text content in Anthropic response',
        attempt,
        lastRawResponse,
        null,
      );
    }

    lastRawResponse = responseText;

    // Step 1: Extract and parse JSON
    let parsed: unknown;
    try {
      const jsonStr = extractJSON(responseText);
      parsed = JSON.parse(jsonStr);
    } catch (parseError) {
      console.warn(
        `[validate-with-retry] JSON parse failed (attempt ${attempt}):`,
        parseError instanceof Error ? parseError.message : parseError,
      );

      // Create a synthetic ZodError for the retry prompt
      lastZodError = new z.ZodError([
        {
          code: 'custom',
          message: `Response was not valid JSON: ${parseError instanceof Error ? parseError.message : 'parse error'}`,
          path: [],
        },
      ]);

      if (attempt < maxRetries) continue;

      throw new StructuredOutputError(
        `Failed to parse JSON after ${maxRetries} attempts`,
        attempt,
        lastRawResponse,
        lastZodError,
      );
    }

    // Step 2: Validate against Zod schema
    const result = schema.safeParse(parsed);

    if (result.success) {
      console.log(
        `[validate-with-retry] Validation succeeded on attempt ${attempt}/${maxRetries}`,
      );
      return result.data;
    }

    // Validation failed
    lastZodError = result.error;
    console.warn(
      `[validate-with-retry] Validation failed (attempt ${attempt}/${maxRetries}):`,
      formatZodErrors(result.error),
    );

    if (attempt < maxRetries) continue;

    // All retries exhausted
    throw new StructuredOutputError(
      `Schema validation failed after ${maxRetries} attempts. Errors:\n${formatZodErrors(result.error)}`,
      attempt,
      lastRawResponse,
      lastZodError,
    );
  }

  // This should be unreachable, but TypeScript needs it
  throw new StructuredOutputError(
    'Unexpected: exhausted retry loop without result',
    maxRetries,
    lastRawResponse,
    lastZodError,
  );
}
