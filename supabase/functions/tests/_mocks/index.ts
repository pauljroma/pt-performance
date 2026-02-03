// ============================================================================
// Mock Exports Index
// Health Intelligence Platform - Edge Function Tests
// ============================================================================

export {
  createMockSupabaseClient,
  mockSupabaseClient,
  type MockSupabaseClient,
  type MockQueryBuilder,
} from "./mockSupabaseClient.ts";

export {
  createMockAnthropicClient,
  createMockAnthropicFetch,
  mockAnthropicClient,
  MOCK_AI_COACH_RESPONSE,
  MOCK_LAB_ANALYSIS_RESPONSE,
  MOCK_SUPPLEMENT_RESPONSE,
  MOCK_RECOVERY_ANALYSIS_RESPONSE,
  MOCK_PDF_PARSE_RESPONSE,
  type MockAnthropicClient,
  type MockMessage,
} from "./mockAnthropicClient.ts";

export {
  TEST_PATIENT_ID,
  TEST_PATIENT_ID_2,
  TEST_THERAPIST_ID,
  TEST_LAB_RESULT_ID,
  TEST_SESSION_ID,
  INVALID_UUID,
  MALFORMED_UUID,
  MOCK_WORKOUTS,
  MOCK_DAILY_READINESS,
  MOCK_LAB_RESULT,
  MOCK_BIOMARKER_VALUES,
  MOCK_BIOMARKER_REFERENCE_RANGES,
  MOCK_FASTING_LOGS,
  MOCK_SUPPLEMENTS,
  MOCK_PATIENT_SUPPLEMENT_STACKS,
  MOCK_PATIENT_GOALS,
  MOCK_RECOVERY_SESSIONS,
  MOCK_AI_CHAT_SESSIONS,
  MOCK_AI_CHAT_MESSAGES,
  getPatientDataForSupabase,
  setupMockSupabaseWithPatientData,
} from "./mockPatientData.ts";
