# Edge Functions Type Safety Guide

**BUILD 138** - TypeScript Type Safety and RLS Security Enhancement

---

## Quick Start

### Using Shared Types

```typescript
import type {
  GenerateSubstitutionRequest,
  GenerateSubstitutionResponse,
  ErrorResponse,
} from '../_shared/types.ts'

import {
  validateGenerateSubstitutionRequest,
  buildValidationErrorResponse,
} from '../_shared/validation.ts'

import {
  buildErrorResponse,
  createLogger,
  corsHeaders,
  NotFoundError,
  UnauthorizedError,
} from '../_shared/errors.ts'

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const logger = createLogger('my-function')
    logger.info('Request received')

    // Parse and validate request
    const body = await req.json()
    const validation = validateGenerateSubstitutionRequest(body)

    if (!validation.valid) {
      logger.warn('Validation failed', { errors: validation.errors })
      return buildValidationErrorResponse(validation)
    }

    const request = body as GenerateSubstitutionRequest

    // ... your logic here

    // Return success response
    const response: GenerateSubstitutionResponse = {
      success: true,
      recommendation_id: 'uuid-here',
      // ... other fields
    }

    return new Response(JSON.stringify(response), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })

  } catch (error) {
    return buildErrorResponse(error) // Handles all error types
  }
})
```

---

## Available Utilities

### Type Definitions (`_shared/types.ts`)

**Database Types:**
- `Patient`, `Therapist`, `Session`, `SessionExercise`
- `Recommendation`, `SessionInstance`, `DailyReadiness`
- `NutritionRecommendation`, `NutritionLog`, `ExerciseTemplate`

**Request/Response Types:**
- `GenerateSubstitutionRequest/Response`
- `ApplySubstitutionRequest/Response`
- `SyncWhoopRequest/Response`
- `NutritionRecommendationRequest/Response`
- `MealParserRequest/Response`

**Type Guards:**
- `isValidUUID(uuid: string): boolean`
- `isValidDate(dateString: string): boolean`
- `isValidMealType(type: string): boolean`
- `isSupabaseError(error: unknown): boolean`

### Validation (`_shared/validation.ts`)

**Validators:**
```typescript
validateRequired(value, fieldName) // Check if field exists
validateUUID(value, fieldName)     // Validate UUID format
validateDate(value, fieldName)     // Validate ISO date
validateEnum(value, allowed, fieldName) // Validate enum
validateArray(value, fieldName, options) // Validate array
validateNumber(value, fieldName, options) // Validate number
validateString(value, fieldName, options) // Validate string
```

**Composite Validators:**
```typescript
validateGenerateSubstitutionRequest(body)
validateApplySubstitutionRequest(body)
validateSyncWhoopRequest(body)
validateNutritionRecommendationRequest(body)
validateMealParserRequest(body)
```

**Error Codes:**
```typescript
ERROR_CODES.REQUIRED_FIELD  // Field is missing
ERROR_CODES.INVALID_FORMAT  // Invalid format
ERROR_CODES.INVALID_UUID    // Not a valid UUID
ERROR_CODES.INVALID_DATE    // Not a valid date
ERROR_CODES.INVALID_ENUM    // Not in allowed values
ERROR_CODES.INVALID_ARRAY   // Array validation failed
ERROR_CODES.OUT_OF_RANGE    // Number out of range
```

### Error Handling (`_shared/errors.ts`)

**Custom Errors:**
```typescript
throw new ValidationError('Invalid input', 'field_name')
throw new NotFoundError('Recommendation', 'uuid-here')
throw new UnauthorizedError('Invalid token')
throw new ForbiddenError('Access denied')
throw new ExternalAPIError('OpenAI', 'Rate limit exceeded')
```

**Error Response Builder:**
```typescript
try {
  // ... operation
} catch (error) {
  return buildErrorResponse(error) // Auto-handles all error types
}
```

**Logger:**
```typescript
const logger = createLogger('function-name', {
  patient_id: 'uuid',
  request_id: 'trace-id',
})

logger.info('Message', { data: 'value' })
logger.warn('Warning', { reason: 'xyz' })
logger.error('Error occurred', error)
logger.debug('Debug info', { details: 'abc' })
```

**Retry with Backoff:**
```typescript
const data = await retryWithBackoff(
  async () => {
    // Your async operation
    const response = await fetch('...')
    if (!response.ok) throw new Error('Failed')
    return response.json()
  },
  {
    maxRetries: 3,
    initialDelay: 1000,
    maxDelay: 10000,
    backoffFactor: 2,
  }
)
```

---

## RLS Security Model

### Edge Functions Use Service Role

**All Edge Functions use `SUPABASE_SERVICE_ROLE_KEY`, not `SUPABASE_ANON_KEY`.**

```typescript
const supabaseClient = createClient(
  Deno.env.get('SUPABASE_URL') ?? '',
  Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '', // ← Service role key
  { auth: { persistSession: false } }
)
```

**Why?**
- Service role bypasses RLS for backend operations
- Allows Edge Functions to create recommendations, instances, etc.
- Security enforced via application logic and input validation

### Tables with Service Role Policies

| Table | Service Role Access |
|-------|---------------------|
| `recommendations` | Full (INSERT, UPDATE, DELETE) |
| `session_instances` | Full (INSERT, UPDATE, DELETE) |
| `nutrition_recommendations` | Full (INSERT, UPDATE, DELETE) |
| `nutrition_logs` | Full (INSERT, UPDATE, DELETE) |
| `daily_readiness` | Full (INSERT, UPDATE) |
| `patients` | Read + Update (WHOOP credentials) |
| `sessions` | Read-only |
| `session_exercises` | Read-only |
| `exercise_templates` | Read-only |
| `scheduled_sessions` | Read-only |
| `nutrition_goals` | Read-only |
| `therapists` | Read-only |
| `exercise_substitution_candidates` | Public read |

### Patient Data Protection

Even though Edge Functions use service role, security is maintained:

1. **Input Validation:** UUIDs validated, enums checked, arrays verified
2. **Application Logic:** Functions verify `patient_id` matches authenticated user
3. **RLS for Users:** When users query directly, RLS still enforces `patient_id = auth.uid()`
4. **Therapist Access:** Therapists can only access their assigned patients via EXISTS checks

---

## Testing RLS Policies

```bash
# Set environment variables
export SUPABASE_URL="https://your-project.supabase.co"
export SUPABASE_ANON_KEY="your-anon-key"
export SUPABASE_SERVICE_ROLE_KEY="your-service-key"

# Run tests
./scripts/tests/test_rls_policies.sh
```

**Expected Output:**
```
[PASS] Service role can INSERT recommendations
[PASS] Anon key correctly blocked from INSERT on recommendations
[PASS] Service role can INSERT session_instances
...
All tests passed!
```

---

## Common Patterns

### Pattern 1: Validate Request

```typescript
const body = await req.json()
const validation = validateMyRequest(body)

if (!validation.valid) {
  return buildValidationErrorResponse(validation)
}

const request = body as MyRequest
```

### Pattern 2: Handle Not Found

```typescript
const { data, error } = await supabase
  .from('recommendations')
  .select('*')
  .eq('id', id)
  .single()

if (error || !data) {
  throw new NotFoundError('Recommendation', id)
}
```

### Pattern 3: Check Authorization

```typescript
const { data: { user }, error: authError } = await supabase.auth.getUser(token)

if (authError || !user) {
  throw new UnauthorizedError('Invalid token')
}

// Check if user can access this resource
if (data.patient_id !== user.id) {
  throw new ForbiddenError('Access denied to this resource')
}
```

### Pattern 4: Call External API with Error Handling

```typescript
const openaiResponse = await fetch('https://api.openai.com/v1/chat/completions', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/json',
    'Authorization': `Bearer ${Deno.env.get('OPENAI_API_KEY')}`,
  },
  body: JSON.stringify(requestBody),
})

if (!openaiResponse.ok) {
  await handleOpenAIError(openaiResponse) // Throws ExternalAPIError
}

const completion = await openaiResponse.json()
```

### Pattern 5: Safe JSON Parsing

```typescript
import { safeJSONParse } from '../_shared/errors.ts'

const aiResponseText = completion.choices[0].message.content
const aiResponse = safeJSONParse(aiResponseText, {
  // Fallback value if parse fails
  exercise_substitutions: [],
  intensity_adjustments: [],
})
```

---

## TypeScript Strict Mode

All Edge Functions compile with strict TypeScript settings:

```json
{
  "compilerOptions": {
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "noUnusedLocals": true,
    "noImplicitReturns": true
  }
}
```

**Check for type errors:**
```bash
cd /Users/expo/Code/expo/supabase/functions
deno check my-function/index.ts
```

---

## Best Practices

### 1. Always Validate Input

```typescript
// ❌ BAD - No validation
const { patient_id } = await req.json()

// ✅ GOOD - Validate first
const body = await req.json()
const validation = validateRequest(body)
if (!validation.valid) {
  return buildValidationErrorResponse(validation)
}
const { patient_id } = body as MyRequest
```

### 2. Use Type Guards

```typescript
// ❌ BAD - Implicit any
catch (error) {
  console.error(error.message) // error is 'any'
}

// ✅ GOOD - Type guard
catch (error) {
  if (error instanceof Error) {
    console.error(error.message)
  }
  return buildErrorResponse(error)
}
```

### 3. Log Structured Data

```typescript
// ❌ BAD - Unstructured logs
console.log('Request received for patient ' + patient_id)

// ✅ GOOD - Structured logging
const logger = createLogger('my-function', { patient_id })
logger.info('Request received')
```

### 4. Return Consistent Responses

```typescript
// ❌ BAD - Inconsistent format
return new Response(JSON.stringify({ data: result }))

// ✅ GOOD - Consistent format
return new Response(
  JSON.stringify({
    success: true,
    data: result,
  }),
  {
    status: 200,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  }
)
```

### 5. Handle Edge Cases

```typescript
// ❌ BAD - Assumes array has items
const firstItem = items[0].name

// ✅ GOOD - Check first
if (items.length === 0) {
  throw new ValidationError('No items found', 'items')
}
const firstItem = items[0].name
```

---

## Migration Guide

To adopt shared utilities in existing Edge Functions:

1. **Add imports:**
   ```typescript
   import type { MyRequest, MyResponse } from '../_shared/types.ts'
   import { validateMyRequest, buildValidationErrorResponse } from '../_shared/validation.ts'
   import { buildErrorResponse, createLogger, corsHeaders } from '../_shared/errors.ts'
   ```

2. **Replace CORS headers:**
   ```typescript
   // Remove local definition
   // const corsHeaders = { ... }

   // Use imported
   import { corsHeaders } from '../_shared/errors.ts'
   ```

3. **Add validation:**
   ```typescript
   const body = await req.json()
   const validation = validateMyRequest(body)
   if (!validation.valid) {
     return buildValidationErrorResponse(validation)
   }
   const request = body as MyRequest
   ```

4. **Replace error handling:**
   ```typescript
   try {
     // ... logic
   } catch (error) {
     return buildErrorResponse(error) // One line!
   }
   ```

5. **Add logging:**
   ```typescript
   const logger = createLogger('my-function', { patient_id })
   logger.info('Processing request')
   ```

---

## Support

**Documentation:**
- Type Definitions: `supabase/functions/_shared/types.ts`
- Validation: `supabase/functions/_shared/validation.ts`
- Error Handling: `supabase/functions/_shared/errors.ts`
- Summary Report: `.outcomes/RLS_TYPE_FIXES_COMPLETE.md`

**Testing:**
- RLS Tests: `scripts/tests/test_rls_policies.sh`
- TypeScript Check: `deno check <function>/index.ts`

**Migration:**
- RLS Policies: `supabase/migrations/20260108000005_add_edge_function_rls_policies.sql`

---

**BUILD 138 - Type Safety and Security Complete** ✅
