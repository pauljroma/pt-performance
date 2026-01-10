// Error Handling Utilities for Edge Functions
// BUILD 138 - Type Safety and Error Handling Enhancement

import type { ErrorResponse, SupabaseError } from './types.ts';

// ============================================================================
// CORS Headers
// ============================================================================

export const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

// ============================================================================
// Error Types
// ============================================================================

export class AppError extends Error {
  constructor(
    message: string,
    public code: string,
    public statusCode: number = 500,
    public field?: string,
    public details?: string
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export class ValidationError extends AppError {
  constructor(message: string, field?: string) {
    super(message, 'ERR_VALIDATION', 400, field);
    this.name = 'ValidationError';
  }
}

export class NotFoundError extends AppError {
  constructor(resource: string, id?: string) {
    super(
      id ? `${resource} with id ${id} not found` : `${resource} not found`,
      'ERR_NOT_FOUND',
      404
    );
    this.name = 'NotFoundError';
  }
}

export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized') {
    super(message, 'ERR_UNAUTHORIZED', 401);
    this.name = 'UnauthorizedError';
  }
}

export class ForbiddenError extends AppError {
  constructor(message: string = 'Access denied') {
    super(message, 'ERR_FORBIDDEN', 403);
    this.name = 'ForbiddenError';
  }
}

export class ExternalAPIError extends AppError {
  constructor(service: string, message: string, details?: string) {
    super(`${service} API error: ${message}`, 'ERR_EXTERNAL_API', 502, undefined, details);
    this.name = 'ExternalAPIError';
  }
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

export function isAppError(error: unknown): error is AppError {
  return error instanceof AppError;
}

// ============================================================================
// Error Response Builders
// ============================================================================

export function buildErrorResponse(error: unknown): Response {
  console.error('Error occurred:', error);

  // Handle AppError (our custom errors)
  if (isAppError(error)) {
    const response: ErrorResponse = {
      success: false,
      error: error.message,
      code: error.code,
      field: error.field,
      details: error.details,
    };

    return new Response(JSON.stringify(response), {
      status: error.statusCode,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Handle Supabase errors
  if (isSupabaseError(error)) {
    const response: ErrorResponse = {
      success: false,
      error: error.message,
      code: error.code || 'ERR_DATABASE',
      details: error.details || error.hint,
    };

    return new Response(JSON.stringify(response), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Handle standard Error
  if (error instanceof Error) {
    const response: ErrorResponse = {
      success: false,
      error: error.message,
      code: 'ERR_INTERNAL',
      details: error.stack,
    };

    return new Response(JSON.stringify(response), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    });
  }

  // Handle unknown errors
  const response: ErrorResponse = {
    success: false,
    error: 'An unknown error occurred',
    code: 'ERR_UNKNOWN',
    details: String(error),
  };

  return new Response(JSON.stringify(response), {
    status: 500,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });
}

// ============================================================================
// Logging Utilities
// ============================================================================

export interface LogContext {
  functionName: string;
  requestId?: string;
  patientId?: string;
  userId?: string;
  [key: string]: unknown;
}

export class Logger {
  constructor(private context: LogContext) {}

  private formatMessage(level: string, message: string, data?: unknown): string {
    const timestamp = new Date().toISOString();
    const contextStr = JSON.stringify(this.context);
    const dataStr = data ? ` | Data: ${JSON.stringify(data)}` : '';
    return `[${timestamp}] [${level}] [${this.context.functionName}] ${message} | Context: ${contextStr}${dataStr}`;
  }

  info(message: string, data?: unknown): void {
    console.log(this.formatMessage('INFO', message, data));
  }

  warn(message: string, data?: unknown): void {
    console.warn(this.formatMessage('WARN', message, data));
  }

  error(message: string, error?: unknown): void {
    const errorData = error instanceof Error
      ? { message: error.message, stack: error.stack, name: error.name }
      : error;
    console.error(this.formatMessage('ERROR', message, errorData));
  }

  debug(message: string, data?: unknown): void {
    console.debug(this.formatMessage('DEBUG', message, data));
  }
}

export function createLogger(functionName: string, additionalContext?: Partial<LogContext>): Logger {
  return new Logger({
    functionName,
    ...additionalContext,
  });
}

// ============================================================================
// OpenAI Error Handling
// ============================================================================

export async function handleOpenAIError(response: Response): Promise<never> {
  const errorText = await response.text();
  let errorMessage = `OpenAI API failed with status ${response.status}`;

  try {
    const errorJson = JSON.parse(errorText);
    if (errorJson.error?.message) {
      errorMessage = errorJson.error.message;
    }
  } catch {
    // If not JSON, use the raw text
    errorMessage = errorText;
  }

  throw new ExternalAPIError('OpenAI', errorMessage, errorText);
}

// ============================================================================
// WHOOP Error Handling
// ============================================================================

export async function handleWHOOPError(response: Response): Promise<never> {
  const errorText = await response.text();
  let errorMessage = `WHOOP API failed with status ${response.status}`;

  if (response.status === 429) {
    throw new ExternalAPIError(
      'WHOOP',
      'Rate limit reached. Please try again later.',
      errorText
    );
  }

  if (response.status === 401 || response.status === 403) {
    throw new UnauthorizedError('WHOOP authentication failed. Please reconnect your account.');
  }

  try {
    const errorJson = JSON.parse(errorText);
    if (errorJson.error?.message) {
      errorMessage = errorJson.error.message;
    }
  } catch {
    errorMessage = errorText;
  }

  throw new ExternalAPIError('WHOOP', errorMessage, errorText);
}

// ============================================================================
// Safe JSON Parsing
// ============================================================================

export function safeJSONParse<T>(text: string, fallback: T): T {
  try {
    // Try direct parse first
    return JSON.parse(text) as T;
  } catch {
    try {
      // Try extracting JSON from markdown code blocks
      const jsonMatch = text.match(/\{[\s\S]*\}/);
      if (jsonMatch) {
        return JSON.parse(jsonMatch[0]) as T;
      }
    } catch {
      // Fall through
    }
  }

  console.warn('Failed to parse JSON, using fallback:', { text, fallback });
  return fallback;
}

// ============================================================================
// Retry Utility (for external APIs)
// ============================================================================

export async function retryWithBackoff<T>(
  fn: () => Promise<T>,
  options: {
    maxRetries?: number;
    initialDelay?: number;
    maxDelay?: number;
    backoffFactor?: number;
  } = {}
): Promise<T> {
  const {
    maxRetries = 3,
    initialDelay = 1000,
    maxDelay = 10000,
    backoffFactor = 2,
  } = options;

  let lastError: unknown;
  let delay = initialDelay;

  for (let attempt = 0; attempt <= maxRetries; attempt++) {
    try {
      return await fn();
    } catch (error) {
      lastError = error;

      if (attempt < maxRetries) {
        console.warn(`Attempt ${attempt + 1} failed, retrying in ${delay}ms...`, error);
        await new Promise(resolve => setTimeout(resolve, delay));
        delay = Math.min(delay * backoffFactor, maxDelay);
      }
    }
  }

  throw lastError;
}
