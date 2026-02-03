# Supabase Edge Function Tests

Comprehensive test suite for all Health Intelligence Platform edge functions.

## Running Tests

```bash
cd /Users/expo/pt-performance/supabase/functions
deno test --allow-env --allow-net tests/
```

### Running Individual Test Files

```bash
# AI Coach tests
deno test --allow-env --allow-net tests/ai-coach.test.ts

# AI Lab Analysis tests
deno test --allow-env --allow-net tests/ai-lab-analysis.test.ts

# AI Supplement Recommendation tests
deno test --allow-env --allow-net tests/ai-supplement-recommendation.test.ts

# Recovery Impact Analysis tests
deno test --allow-env --allow-net tests/recovery-impact-analysis.test.ts

# Parse Lab PDF tests
deno test --allow-env --allow-net tests/parse-lab-pdf.test.ts
```

### Running with Coverage

```bash
deno test --allow-env --allow-net --coverage=coverage tests/
deno coverage coverage
```

## Test Structure

```
tests/
├── _mocks/
│   ├── index.ts                    # Mock exports
│   ├── mockSupabaseClient.ts       # Mock Supabase client
│   ├── mockAnthropicClient.ts      # Mock Anthropic/Claude client
│   └── mockPatientData.ts          # Mock patient data fixtures
├── ai-coach.test.ts                # AI Coach function tests
├── ai-lab-analysis.test.ts         # Lab Analysis function tests
├── ai-supplement-recommendation.test.ts  # Supplement Recommendation tests
├── recovery-impact-analysis.test.ts      # Recovery Analysis tests
├── parse-lab-pdf.test.ts           # PDF Parsing tests
└── README.md                       # This file
```

## Test Categories

### 1. ai-coach.test.ts
- Request validation (patient_id, message, session_id)
- Context gathering (workouts, sleep, HRV, labs, fasting, supplements)
- Context summary calculations
- Claude API integration
- Suggested questions generation
- Response structure validation
- Conversation history handling
- Error handling

### 2. ai-lab-analysis.test.ts
- Request validation (patient_id, lab_result_id)
- Lab result analysis
- Biomarker optimal range comparisons
- Health score calculation
- Correlation with training data
- Caching behavior (24-hour cache)
- Response structure validation
- Error handling

### 3. ai-supplement-recommendation.test.ts
- Request validation
- Recommendation generation
- Goal-based filtering
- Momentous product matching
- Dosage calculations
- Timing schedule building
- Caching behavior (7-day cache)
- Response structure validation
- Evidence rating validation
- Error handling

### 4. recovery-impact-analysis.test.ts
- Request validation (patient_id, lookback_days)
- HRV/sleep correlation calculations
- Impact percentage calculations
- Personalized recommendations
- Insufficient data handling
- Modality-specific analysis
- Caching behavior
- Response structure validation
- Error handling

### 5. parse-lab-pdf.test.ts
- Request validation (pdf_base64)
- PDF parsing with mock Claude Vision
- Biomarker extraction
- Lab provider detection
- Error handling for invalid PDFs
- Response structure validation
- Confidence level determination
- Biomarker validation
- Test date validation

## Mock Helpers

### mockSupabaseClient.ts
Provides a mock Supabase client that:
- Simulates database queries (select, insert, update, delete)
- Supports query filters (eq, neq, gt, gte, lt, lte, in, not)
- Supports ordering and limiting
- Allows setting mock data and errors

### mockAnthropicClient.ts
Provides a mock Anthropic client that:
- Simulates Claude API calls
- Returns configurable mock responses
- Tracks call history for assertions
- Includes pre-built mock responses for each function

### mockPatientData.ts
Provides mock patient data including:
- Test UUIDs (patient, therapist, lab result, session)
- Workout data
- Daily readiness/sleep/HRV data
- Lab results and biomarker values
- Fasting logs
- Supplements and stacks
- Patient goals
- Recovery sessions
- AI chat sessions and messages

## Writing New Tests

```typescript
import {
  assertEquals,
  assertExists,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  describe,
  it,
  beforeEach,
} from "https://deno.land/std@0.168.0/testing/bdd.ts";

import { createMockSupabaseClient } from "./_mocks/mockSupabaseClient.ts";
import { createMockAnthropicClient, MOCK_AI_COACH_RESPONSE } from "./_mocks/mockAnthropicClient.ts";
import { TEST_PATIENT_ID, setupMockSupabaseWithPatientData } from "./_mocks/mockPatientData.ts";

describe("My New Test Suite", () => {
  let mockSupabase: ReturnType<typeof createMockSupabaseClient>;
  let mockAnthropic: ReturnType<typeof createMockAnthropicClient>;

  beforeEach(() => {
    mockSupabase = createMockSupabaseClient();
    mockAnthropic = createMockAnthropicClient();
    mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);
    setupMockSupabaseWithPatientData(mockSupabase);
  });

  it("should do something", () => {
    // Test implementation
    assertEquals(true, true);
  });
});
```

## CI/CD Integration

Add to your GitHub Actions workflow:

```yaml
- name: Run Edge Function Tests
  run: |
    cd supabase/functions
    deno test --allow-env --allow-net tests/
```
