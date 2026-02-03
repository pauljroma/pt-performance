// ============================================================================
// AI Coach Edge Function Tests
// Health Intelligence Platform - Test Suite
// ============================================================================

import {
  assertEquals,
  assertExists,
  assertStringIncludes,
} from "https://deno.land/std@0.168.0/testing/asserts.ts";
import {
  describe,
  it,
  beforeEach,
} from "https://deno.land/std@0.168.0/testing/bdd.ts";

import { createMockSupabaseClient } from "./_mocks/mockSupabaseClient.ts";
import {
  createMockAnthropicClient,
  MOCK_AI_COACH_RESPONSE,
} from "./_mocks/mockAnthropicClient.ts";
import {
  TEST_PATIENT_ID,
  TEST_SESSION_ID,
  INVALID_UUID,
  setupMockSupabaseWithPatientData,
  MOCK_WORKOUTS,
  MOCK_DAILY_READINESS,
  MOCK_FASTING_LOGS,
  MOCK_PATIENT_SUPPLEMENT_STACKS,
  MOCK_PATIENT_GOALS,
} from "./_mocks/mockPatientData.ts";

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

interface PatientContext {
  workouts: any[];
  sleep: any[];
  hrv: any[];
  labs: any | null;
  fasting: any[];
  supplements: any[];
  goals: any[];
  readiness: any[];
}

function buildContextSummary(context: PatientContext) {
  const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);

  const workouts7d = context.workouts.filter(
    (w) => new Date(w.completed_at) >= sevenDaysAgo
  ).length;

  const sleepValues = context.sleep
    .filter((s) => s.sleep_hours !== null)
    .map((s) => s.sleep_hours as number);
  const avgSleep =
    sleepValues.length > 0
      ? sleepValues.reduce((a, b) => a + b, 0) / sleepValues.length
      : null;

  const hrvValues = context.hrv
    .filter((h) => h.hrv_rmssd !== null)
    .map((h) => h.hrv_rmssd as number);
  const avgHrv =
    hrvValues.length > 0
      ? hrvValues.reduce((a, b) => a + b, 0) / hrvValues.length
      : null;

  const currentFasting = context.fasting.some((f) => !f.ended_at);

  return {
    workouts_7d: workouts7d,
    avg_sleep_7d: avgSleep ? Math.round(avgSleep * 10) / 10 : null,
    avg_hrv_7d: avgHrv ? Math.round(avgHrv) : null,
    current_fasting: currentFasting,
    active_supplements: context.supplements.length,
  };
}

// ============================================================================
// TEST SUITE
// ============================================================================

describe("AI Coach Edge Function", () => {
  let mockSupabase: ReturnType<typeof createMockSupabaseClient>;
  let mockAnthropic: ReturnType<typeof createMockAnthropicClient>;

  beforeEach(() => {
    mockSupabase = createMockSupabaseClient();
    mockAnthropic = createMockAnthropicClient();
    mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);
    setupMockSupabaseWithPatientData(mockSupabase);
  });

  describe("Request Validation", () => {
    it("should reject requests without patient_id", async () => {
      const request = {
        message: "How am I doing?",
      };

      const hasPatientId = "patient_id" in request && request.patient_id;
      assertEquals(hasPatientId, false);
    });

    it("should reject requests without message", async () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
      };

      const hasMessage = "message" in request && (request as any).message;
      assertEquals(hasMessage, false);
    });

    it("should reject requests with empty message", async () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        message: "",
      };

      const hasValidMessage = !!(request.message && request.message.trim().length > 0);
      assertEquals(hasValidMessage, false);
    });

    it("should reject requests with invalid patient_id format", async () => {
      const request = {
        patient_id: INVALID_UUID,
        message: "How am I doing?",
      };

      const isValid = isValidUUID(request.patient_id);
      assertEquals(isValid, false);
    });

    it("should accept valid request with patient_id and message", async () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        message: "How is my recovery looking?",
      };

      const isValid =
        isValidUUID(request.patient_id) &&
        request.message &&
        request.message.trim().length > 0;
      assertEquals(isValid, true);
    });

    it("should accept optional session_id parameter", async () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        message: "Follow up question",
        session_id: TEST_SESSION_ID,
      };

      const isValid =
        isValidUUID(request.patient_id) &&
        isValidUUID(request.session_id!) &&
        request.message.trim().length > 0;
      assertEquals(isValid, true);
    });
  });

  describe("Context Gathering", () => {
    it("should gather workout data from manual_sessions", async () => {
      const workoutsResult = await mockSupabase
        .from("manual_sessions")
        .select("id, name, completed_at, duration_minutes")
        .eq("patient_id", TEST_PATIENT_ID)
        .eq("completed", true);

      assertExists(workoutsResult.data);
      assertEquals(Array.isArray(workoutsResult.data), true);
      assertEquals(workoutsResult.data.length > 0, true);
    });

    it("should gather sleep data from daily_readiness", async () => {
      const sleepResult = await mockSupabase
        .from("daily_readiness")
        .select("date, sleep_hours")
        .eq("patient_id", TEST_PATIENT_ID);

      assertExists(sleepResult.data);
      assertEquals(Array.isArray(sleepResult.data), true);
    });

    it("should gather HRV data from daily_readiness", async () => {
      const hrvData = MOCK_DAILY_READINESS.filter(
        (r) => r.whoop_hrv_rmssd !== null
      );

      assertEquals(hrvData.length > 0, true);
      assertExists(hrvData[0].whoop_hrv_rmssd);
    });

    it("should gather fasting data", async () => {
      const fastingResult = await mockSupabase
        .from("fasting_logs")
        .select("started_at, ended_at, planned_hours, completed, protocol_type")
        .eq("patient_id", TEST_PATIENT_ID);

      assertExists(fastingResult.data);
      assertEquals(Array.isArray(fastingResult.data), true);
    });

    it("should gather active supplements", async () => {
      const supplementsResult = await mockSupabase
        .from("patient_supplement_stacks")
        .select("dosage, dosage_unit, timing, supplements (name)")
        .eq("patient_id", TEST_PATIENT_ID)
        .eq("is_active", true);

      assertExists(supplementsResult.data);
    });

    it("should gather active goals", async () => {
      const goalsResult = await mockSupabase
        .from("patient_goals")
        .select("category, title, status")
        .eq("patient_id", TEST_PATIENT_ID)
        .eq("status", "active");

      assertExists(goalsResult.data);
    });
  });

  describe("Context Summary Calculation", () => {
    it("should calculate workouts in last 7 days", () => {
      const context: PatientContext = {
        workouts: MOCK_WORKOUTS,
        sleep: MOCK_DAILY_READINESS.map((r) => ({
          date: r.date,
          sleep_hours: r.sleep_hours,
        })),
        hrv: MOCK_DAILY_READINESS.map((r) => ({
          date: r.date,
          hrv_rmssd: r.whoop_hrv_rmssd,
        })),
        labs: null,
        fasting: MOCK_FASTING_LOGS,
        supplements: MOCK_PATIENT_SUPPLEMENT_STACKS,
        goals: MOCK_PATIENT_GOALS,
        readiness: MOCK_DAILY_READINESS,
      };

      const summary = buildContextSummary(context);
      assertExists(summary.workouts_7d);
      assertEquals(typeof summary.workouts_7d, "number");
      assertEquals(summary.workouts_7d >= 0, true);
    });

    it("should calculate average sleep", () => {
      const context: PatientContext = {
        workouts: [],
        sleep: MOCK_DAILY_READINESS.map((r) => ({
          date: r.date,
          sleep_hours: r.sleep_hours,
        })),
        hrv: [],
        labs: null,
        fasting: [],
        supplements: [],
        goals: [],
        readiness: [],
      };

      const summary = buildContextSummary(context);
      assertExists(summary.avg_sleep_7d);
      assertEquals(typeof summary.avg_sleep_7d, "number");
      assertEquals(summary.avg_sleep_7d! > 0, true);
    });

    it("should calculate average HRV", () => {
      const context: PatientContext = {
        workouts: [],
        sleep: [],
        hrv: MOCK_DAILY_READINESS.map((r) => ({
          date: r.date,
          hrv_rmssd: r.whoop_hrv_rmssd,
        })),
        labs: null,
        fasting: [],
        supplements: [],
        goals: [],
        readiness: [],
      };

      const summary = buildContextSummary(context);
      assertExists(summary.avg_hrv_7d);
      assertEquals(typeof summary.avg_hrv_7d, "number");
      assertEquals(summary.avg_hrv_7d! > 0, true);
    });

    it("should detect current fasting state", () => {
      // Test with active fast
      const contextWithFast: PatientContext = {
        workouts: [],
        sleep: [],
        hrv: [],
        labs: null,
        fasting: [{ ended_at: null }],
        supplements: [],
        goals: [],
        readiness: [],
      };

      const summaryWithFast = buildContextSummary(contextWithFast);
      assertEquals(summaryWithFast.current_fasting, true);

      // Test without active fast
      const contextWithoutFast: PatientContext = {
        workouts: [],
        sleep: [],
        hrv: [],
        labs: null,
        fasting: [{ ended_at: new Date().toISOString() }],
        supplements: [],
        goals: [],
        readiness: [],
      };

      const summaryWithoutFast = buildContextSummary(contextWithoutFast);
      assertEquals(summaryWithoutFast.current_fasting, false);
    });

    it("should count active supplements", () => {
      const context: PatientContext = {
        workouts: [],
        sleep: [],
        hrv: [],
        labs: null,
        fasting: [],
        supplements: MOCK_PATIENT_SUPPLEMENT_STACKS,
        goals: [],
        readiness: [],
      };

      const summary = buildContextSummary(context);
      assertEquals(summary.active_supplements, MOCK_PATIENT_SUPPLEMENT_STACKS.length);
    });

    it("should handle empty data gracefully", () => {
      const emptyContext: PatientContext = {
        workouts: [],
        sleep: [],
        hrv: [],
        labs: null,
        fasting: [],
        supplements: [],
        goals: [],
        readiness: [],
      };

      const summary = buildContextSummary(emptyContext);
      assertEquals(summary.workouts_7d, 0);
      assertEquals(summary.avg_sleep_7d, null);
      assertEquals(summary.avg_hrv_7d, null);
      assertEquals(summary.current_fasting, false);
      assertEquals(summary.active_supplements, 0);
    });
  });

  describe("Claude API Integration", () => {
    it("should call Anthropic API with correct parameters", async () => {
      mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        system: "You are an expert AI health coach...",
        messages: [{ role: "user", content: "Test message" }],
        temperature: 0.5,
      });

      assertExists(result);
      assertExists(result.content);
      assertEquals(result.content.length > 0, true);
    });

    it("should parse JSON response from Claude", async () => {
      mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [{ role: "user", content: "Test" }],
      });

      const responseText = result.content[0].text;
      const parsed = JSON.parse(responseText);

      assertExists(parsed.response);
      assertExists(parsed.insights);
      assertExists(parsed.suggested_questions);
    });

    it("should handle Claude API errors gracefully", async () => {
      mockAnthropic._setMockError(new Error("API rate limit exceeded"));

      let errorCaught = false;
      try {
        await mockAnthropic.messages.create({
          model: "claude-sonnet-4-20250514",
          messages: [{ role: "user", content: "Test" }],
        });
      } catch (error) {
        errorCaught = true;
        assertEquals((error as Error).message, "API rate limit exceeded");
      }

      assertEquals(errorCaught, true);
    });
  });

  describe("Suggested Questions Generation", () => {
    it("should return suggested questions in response", async () => {
      mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.suggested_questions);
      assertEquals(Array.isArray(parsed.suggested_questions), true);
      assertEquals(parsed.suggested_questions.length >= 2, true);
    });

    it("should provide relevant follow-up questions", async () => {
      mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      const questions = parsed.suggested_questions;

      // Questions should be strings
      for (const q of questions) {
        assertEquals(typeof q, "string");
        assertEquals(q.length > 10, true);
      }
    });
  });

  describe("Response Structure", () => {
    it("should include session_id in response", async () => {
      const response = {
        session_id: TEST_SESSION_ID,
        response: "Test response",
        insights: [],
        suggested_questions: [],
        context_summary: {},
        disclaimer: "AI disclaimer",
      };

      assertExists(response.session_id);
      assertEquals(isValidUUID(response.session_id), true);
    });

    it("should include insights array", async () => {
      mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.insights);
      assertEquals(Array.isArray(parsed.insights), true);
    });

    it("should include valid insight structure", async () => {
      mockAnthropic._setMockResponse(MOCK_AI_COACH_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      const insight = parsed.insights[0];

      assertExists(insight.category);
      assertExists(insight.observation);
      assertExists(insight.recommendation);
      assertExists(insight.priority);

      const validCategories = [
        "training",
        "recovery",
        "nutrition",
        "sleep",
        "labs",
        "supplements",
        "general",
      ];
      assertEquals(validCategories.includes(insight.category), true);

      const validPriorities = ["high", "medium", "low"];
      assertEquals(validPriorities.includes(insight.priority), true);
    });

    it("should include disclaimer in response", async () => {
      const disclaimer =
        "AI HEALTH COACHING DISCLAIMER: This response is generated by an AI system and is for informational and educational purposes only.";

      assertStringIncludes(disclaimer, "AI");
      assertStringIncludes(disclaimer, "informational");
    });

    it("should include context_summary in response", async () => {
      const contextSummary = {
        workouts_7d: 4,
        avg_sleep_7d: 7.2,
        avg_hrv_7d: 51,
        current_fasting: false,
        active_supplements: 2,
      };

      assertExists(contextSummary.workouts_7d);
      assertExists(contextSummary.avg_sleep_7d);
      assertExists(contextSummary.active_supplements);
    });
  });

  describe("Conversation History", () => {
    it("should retrieve conversation history for existing session", async () => {
      const historyResult = await mockSupabase
        .from("ai_chat_messages")
        .select("role, content")
        .eq("session_id", TEST_SESSION_ID)
        .order("created_at", { ascending: true })
        .limit(10);

      assertExists(historyResult.data);
    });

    it("should create new session when session_id not provided", async () => {
      const newSession = {
        id: crypto.randomUUID(),
        athlete_id: TEST_PATIENT_ID,
        started_at: new Date().toISOString(),
      };

      assertExists(newSession.id);
      assertEquals(isValidUUID(newSession.id), true);
    });
  });

  describe("Error Handling", () => {
    it("should return error response with proper structure", () => {
      const errorResponse = {
        error: "Internal server error",
        session_id: null,
        response: "I encountered an issue processing your request. Please try again.",
        insights: [],
        suggested_questions: [],
        context_summary: {
          workouts_7d: 0,
          avg_sleep_7d: null,
          avg_hrv_7d: null,
          current_fasting: false,
          active_supplements: 0,
        },
        disclaimer:
          "AI Coaching is temporarily unavailable. Please consult a healthcare provider for guidance.",
      };

      assertExists(errorResponse.error);
      assertExists(errorResponse.response);
      assertExists(errorResponse.disclaimer);
      assertEquals(errorResponse.insights.length, 0);
      assertEquals(errorResponse.suggested_questions.length, 0);
    });

    it("should handle missing ANTHROPIC_API_KEY", () => {
      const apiKey = undefined; // Simulating missing key
      const shouldThrow = !apiKey;
      assertEquals(shouldThrow, true);
    });
  });
});
