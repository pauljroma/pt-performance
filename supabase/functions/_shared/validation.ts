// Input Validation Utilities for Edge Functions
// BUILD 138 - Type Safety and Validation Enhancement

import type {
  ValidationError,
  ValidationResult,
} from './types.ts';

// ============================================================================
// Error Codes
// ============================================================================

export const ERROR_CODES = {
  REQUIRED_FIELD: 'ERR_REQUIRED_FIELD',
  INVALID_FORMAT: 'ERR_INVALID_FORMAT',
  INVALID_UUID: 'ERR_INVALID_UUID',
  INVALID_DATE: 'ERR_INVALID_DATE',
  INVALID_ENUM: 'ERR_INVALID_ENUM',
  INVALID_ARRAY: 'ERR_INVALID_ARRAY',
  INVALID_NUMBER: 'ERR_INVALID_NUMBER',
  OUT_OF_RANGE: 'ERR_OUT_OF_RANGE',
} as const;

// ============================================================================
// Validation Functions
// ============================================================================

export function validateRequired(
  value: unknown,
  fieldName: string
): ValidationError | null {
  if (value === undefined || value === null || value === '') {
    return {
      field: fieldName,
      message: `${fieldName} is required`,
      code: ERROR_CODES.REQUIRED_FIELD,
    };
  }
  return null;
}

export function validateUUID(
  value: string,
  fieldName: string
): ValidationError | null {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  if (!uuidRegex.test(value)) {
    return {
      field: fieldName,
      message: `${fieldName} must be a valid UUID`,
      code: ERROR_CODES.INVALID_UUID,
    };
  }
  return null;
}

export function validateDate(
  value: string,
  fieldName: string
): ValidationError | null {
  const date = new Date(value);
  if (isNaN(date.getTime())) {
    return {
      field: fieldName,
      message: `${fieldName} must be a valid ISO date string`,
      code: ERROR_CODES.INVALID_DATE,
    };
  }
  return null;
}

export function validateEnum<T extends string>(
  value: string,
  allowedValues: readonly T[],
  fieldName: string
): ValidationError | null {
  if (!allowedValues.includes(value as T)) {
    return {
      field: fieldName,
      message: `${fieldName} must be one of: ${allowedValues.join(', ')}`,
      code: ERROR_CODES.INVALID_ENUM,
    };
  }
  return null;
}

export function validateArray(
  value: unknown,
  fieldName: string,
  options?: { minLength?: number; maxLength?: number; allowEmpty?: boolean }
): ValidationError | null {
  if (!Array.isArray(value)) {
    return {
      field: fieldName,
      message: `${fieldName} must be an array`,
      code: ERROR_CODES.INVALID_ARRAY,
    };
  }

  if (!options?.allowEmpty && value.length === 0) {
    return {
      field: fieldName,
      message: `${fieldName} cannot be empty`,
      code: ERROR_CODES.INVALID_ARRAY,
    };
  }

  if (options?.minLength !== undefined && value.length < options.minLength) {
    return {
      field: fieldName,
      message: `${fieldName} must have at least ${options.minLength} items`,
      code: ERROR_CODES.INVALID_ARRAY,
    };
  }

  if (options?.maxLength !== undefined && value.length > options.maxLength) {
    return {
      field: fieldName,
      message: `${fieldName} must have at most ${options.maxLength} items`,
      code: ERROR_CODES.INVALID_ARRAY,
    };
  }

  return null;
}

export function validateNumber(
  value: unknown,
  fieldName: string,
  options?: { min?: number; max?: number; integer?: boolean }
): ValidationError | null {
  if (typeof value !== 'number' || isNaN(value)) {
    return {
      field: fieldName,
      message: `${fieldName} must be a valid number`,
      code: ERROR_CODES.INVALID_NUMBER,
    };
  }

  if (options?.integer && !Number.isInteger(value)) {
    return {
      field: fieldName,
      message: `${fieldName} must be an integer`,
      code: ERROR_CODES.INVALID_NUMBER,
    };
  }

  if (options?.min !== undefined && value < options.min) {
    return {
      field: fieldName,
      message: `${fieldName} must be at least ${options.min}`,
      code: ERROR_CODES.OUT_OF_RANGE,
    };
  }

  if (options?.max !== undefined && value > options.max) {
    return {
      field: fieldName,
      message: `${fieldName} must be at most ${options.max}`,
      code: ERROR_CODES.OUT_OF_RANGE,
    };
  }

  return null;
}

export function validateString(
  value: unknown,
  fieldName: string,
  options?: { minLength?: number; maxLength?: number; pattern?: RegExp }
): ValidationError | null {
  if (typeof value !== 'string') {
    return {
      field: fieldName,
      message: `${fieldName} must be a string`,
      code: ERROR_CODES.INVALID_FORMAT,
    };
  }

  if (options?.minLength !== undefined && value.length < options.minLength) {
    return {
      field: fieldName,
      message: `${fieldName} must be at least ${options.minLength} characters`,
      code: ERROR_CODES.INVALID_FORMAT,
    };
  }

  if (options?.maxLength !== undefined && value.length > options.maxLength) {
    return {
      field: fieldName,
      message: `${fieldName} must be at most ${options.maxLength} characters`,
      code: ERROR_CODES.INVALID_FORMAT,
    };
  }

  if (options?.pattern && !options.pattern.test(value)) {
    return {
      field: fieldName,
      message: `${fieldName} has invalid format`,
      code: ERROR_CODES.INVALID_FORMAT,
    };
  }

  return null;
}

// ============================================================================
// Composite Validators
// ============================================================================

export function validateGenerateSubstitutionRequest(body: unknown): ValidationResult {
  const errors: ValidationError[] = [];

  if (typeof body !== 'object' || body === null) {
    return {
      valid: false,
      errors: [{
        field: 'body',
        message: 'Request body must be an object',
        code: ERROR_CODES.INVALID_FORMAT,
      }],
    };
  }

  const req = body as Record<string, unknown>;

  // Required fields
  const requiredError = validateRequired(req.patient_id, 'patient_id');
  if (requiredError) errors.push(requiredError);

  const sessionError = validateRequired(req.session_id, 'session_id');
  if (sessionError) errors.push(sessionError);

  const dateError = validateRequired(req.scheduled_date, 'scheduled_date');
  if (dateError) errors.push(dateError);

  const equipmentError = validateRequired(req.equipment_available, 'equipment_available');
  if (equipmentError) errors.push(equipmentError);

  const prefError = validateRequired(req.intensity_preference, 'intensity_preference');
  if (prefError) errors.push(prefError);

  // UUID validation
  if (typeof req.patient_id === 'string') {
    const uuidError = validateUUID(req.patient_id, 'patient_id');
    if (uuidError) errors.push(uuidError);
  }

  if (typeof req.session_id === 'string') {
    const uuidError = validateUUID(req.session_id, 'session_id');
    if (uuidError) errors.push(uuidError);
  }

  // Date validation
  if (typeof req.scheduled_date === 'string') {
    const dateValidError = validateDate(req.scheduled_date, 'scheduled_date');
    if (dateValidError) errors.push(dateValidError);
  }

  // Array validation
  const arrayError = validateArray(req.equipment_available, 'equipment_available', { minLength: 1 });
  if (arrayError) errors.push(arrayError);

  // Enum validation
  if (typeof req.intensity_preference === 'string') {
    const enumError = validateEnum(
      req.intensity_preference,
      ['recovery', 'standard', 'go_hard'] as const,
      'intensity_preference'
    );
    if (enumError) errors.push(enumError);
  }

  // Optional number validation
  if (req.readiness_score !== undefined) {
    const numError = validateNumber(req.readiness_score, 'readiness_score', {
      min: 0,
      max: 100,
    });
    if (numError) errors.push(numError);
  }

  if (req.whoop_recovery_score !== undefined) {
    const numError = validateNumber(req.whoop_recovery_score, 'whoop_recovery_score', {
      min: 0,
      max: 100,
    });
    if (numError) errors.push(numError);
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export function validateApplySubstitutionRequest(body: unknown): ValidationResult {
  const errors: ValidationError[] = [];

  if (typeof body !== 'object' || body === null) {
    return {
      valid: false,
      errors: [{
        field: 'body',
        message: 'Request body must be an object',
        code: ERROR_CODES.INVALID_FORMAT,
      }],
    };
  }

  const req = body as Record<string, unknown>;

  const requiredError = validateRequired(req.recommendation_id, 'recommendation_id');
  if (requiredError) errors.push(requiredError);

  if (typeof req.recommendation_id === 'string') {
    const uuidError = validateUUID(req.recommendation_id, 'recommendation_id');
    if (uuidError) errors.push(uuidError);
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export function validateSyncWhoopRequest(body: unknown): ValidationResult {
  const errors: ValidationError[] = [];

  if (typeof body !== 'object' || body === null) {
    return {
      valid: false,
      errors: [{
        field: 'body',
        message: 'Request body must be an object',
        code: ERROR_CODES.INVALID_FORMAT,
      }],
    };
  }

  const req = body as Record<string, unknown>;

  const requiredError = validateRequired(req.patient_id, 'patient_id');
  if (requiredError) errors.push(requiredError);

  if (typeof req.patient_id === 'string') {
    const uuidError = validateUUID(req.patient_id, 'patient_id');
    if (uuidError) errors.push(uuidError);
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export function validateNutritionRecommendationRequest(body: unknown): ValidationResult {
  const errors: ValidationError[] = [];

  if (typeof body !== 'object' || body === null) {
    return {
      valid: false,
      errors: [{
        field: 'body',
        message: 'Request body must be an object',
        code: ERROR_CODES.INVALID_FORMAT,
      }],
    };
  }

  const req = body as Record<string, unknown>;

  const patientError = validateRequired(req.patient_id, 'patient_id');
  if (patientError) errors.push(patientError);

  const timeError = validateRequired(req.time_of_day, 'time_of_day');
  if (timeError) errors.push(timeError);

  if (typeof req.patient_id === 'string') {
    const uuidError = validateUUID(req.patient_id, 'patient_id');
    if (uuidError) errors.push(uuidError);
  }

  if (typeof req.time_of_day === 'string') {
    const strError = validateString(req.time_of_day, 'time_of_day', {
      minLength: 1,
      maxLength: 20,
    });
    if (strError) errors.push(strError);
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

export function validateMealParserRequest(body: unknown): ValidationResult {
  const errors: ValidationError[] = [];

  if (typeof body !== 'object' || body === null) {
    return {
      valid: false,
      errors: [{
        field: 'body',
        message: 'Request body must be an object',
        code: ERROR_CODES.INVALID_FORMAT,
      }],
    };
  }

  const req = body as Record<string, unknown>;

  const descError = validateRequired(req.description, 'description');
  if (descError) errors.push(descError);

  if (typeof req.description === 'string') {
    const strError = validateString(req.description, 'description', {
      minLength: 1,
      maxLength: 1000,
    });
    if (strError) errors.push(strError);
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

// ============================================================================
// Error Response Builder
// ============================================================================

export function buildValidationErrorResponse(result: ValidationResult): Response {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  };

  const firstError = result.errors[0];

  return new Response(
    JSON.stringify({
      success: false,
      error: firstError.message,
      code: firstError.code,
      field: firstError.field,
      validation_errors: result.errors,
    }),
    {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    }
  );
}
