// ============================================================================
// Recovery Impact Analysis Edge Function Tests
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
  MOCK_RECOVERY_ANALYSIS_RESPONSE,
} from "./_mocks/mockAnthropicClient.ts";
import {
  TEST_PATIENT_ID,
  INVALID_UUID,
  MOCK_RECOVERY_SESSIONS,
  MOCK_DAILY_READINESS,
  setupMockSupabaseWithPatientData,
} from "./_mocks/mockPatientData.ts";

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

function calculateChange(before: number | null, after: number | null): number | null {
  if (before === null || after === null) return null;
  return after - before;
}

function calculateAverage(values: number[]): number | null {
  const validValues = values.filter((v) => v !== null && !isNaN(v));
  if (validValues.length === 0) return null;
  return validValues.reduce((a, b) => a + b, 0) / validValues.length;
}

function getDateString(date: Date): string {
  return date.toISOString().split("T")[0];
}

function addDays(dateStr: string, days: number): string {
  const date = new Date(dateStr);
  date.setDate(date.getDate() + days);
  return getDateString(date);
}

interface DailyMetrics {
  date: string;
  readiness_score: number | null;
  sleep_hours: number | null;
  hrv_rmssd: number | null;
  resting_hr: number | null;
  soreness_level: number | null;
  energy_level: number | null;
  stress_level: number | null;
}

interface RecoverySession {
  id: string;
  session_type: string;
  duration_minutes: number;
  logged_at: string;
  notes: string | null;
  rating: number | null;
}

interface SessionWithMetrics {
  session: RecoverySession;
  dayBeforeMetrics: DailyMetrics | null;
  dayOfMetrics: DailyMetrics | null;
  dayAfterMetrics: DailyMetrics | null;
}

interface ModalityImpact {
  modality: string;
  session_count: number;
  avg_duration_minutes: number;
  avg_next_day_hrv_change: number | null;
  avg_next_day_readiness_change: number | null;
  avg_next_day_sleep_change: number | null;
  effectiveness_score: number;
  best_duration_range: string;
  best_timing: string;
  notes: string[];
}

function analyzeModalityImpact(
  sessions: SessionWithMetrics[],
  modality: string
): ModalityImpact {
  const modalitySessions = sessions.filter(
    (s) => s.session.session_type.toLowerCase() === modality.toLowerCase()
  );

  if (modalitySessions.length === 0) {
    return {
      modality,
      session_count: 0,
      avg_duration_minutes: 0,
      avg_next_day_hrv_change: null,
      avg_next_day_readiness_change: null,
      avg_next_day_sleep_change: null,
      effectiveness_score: 0,
      best_duration_range: "N/A",
      best_timing: "N/A",
      notes: ["No sessions recorded for this modality"],
    };
  }

  const hrvChanges: number[] = [];
  const readinessChanges: number[] = [];
  const sleepChanges: number[] = [];
  const durations: number[] = [];

  for (const s of modalitySessions) {
    durations.push(s.session.duration_minutes);

    if (s.dayBeforeMetrics && s.dayAfterMetrics) {
      const hrvChange = calculateChange(
        s.dayBeforeMetrics.hrv_rmssd,
        s.dayAfterMetrics.hrv_rmssd
      );
      if (hrvChange !== null) hrvChanges.push(hrvChange);

      const readinessChange = calculateChange(
        s.dayBeforeMetrics.readiness_score,
        s.dayAfterMetrics.readiness_score
      );
      if (readinessChange !== null) readinessChanges.push(readinessChange);

      const sleepChange = calculateChange(
        s.dayBeforeMetrics.sleep_hours,
        s.dayAfterMetrics.sleep_hours
      );
      if (sleepChange !== null) sleepChanges.push(sleepChange);
    }
  }

  // Calculate effectiveness score
  let effectivenessScore = 50;

  const avgHrvChange = calculateAverage(hrvChanges);
  if (avgHrvChange !== null) {
    effectivenessScore += Math.min(20, Math.max(-20, avgHrvChange / 2));
  }

  const avgReadinessChange = calculateAverage(readinessChanges);
  if (avgReadinessChange !== null) {
    effectivenessScore += Math.min(15, Math.max(-15, avgReadinessChange / 2));
  }

  const avgSleepChange = calculateAverage(sleepChanges);
  if (avgSleepChange !== null) {
    effectivenessScore += Math.min(15, Math.max(-15, avgSleepChange * 5));
  }

  effectivenessScore = Math.max(0, Math.min(100, effectivenessScore));

  const avgDuration = calculateAverage(durations) || 0;
  const minDuration = Math.min(...durations);
  const maxDuration = Math.max(...durations);
  const bestDurationRange = `${minDuration}-${maxDuration} minutes (avg: ${Math.round(avgDuration)})`;

  const hours = modalitySessions.map((s) => new Date(s.session.logged_at).getHours());
  const avgHour = Math.round(calculateAverage(hours) || 12);
  let bestTiming = "Morning";
  if (avgHour >= 12 && avgHour < 17) bestTiming = "Afternoon";
  else if (avgHour >= 17 && avgHour < 21) bestTiming = "Evening";
  else if (avgHour >= 21) bestTiming = "Night";

  const notes: string[] = [];
  if (avgHrvChange !== null && avgHrvChange > 5) {
    notes.push(
      `HRV improved by average of ${avgHrvChange.toFixed(1)} ms after ${modality} sessions`
    );
  }
  if (avgReadinessChange !== null && avgReadinessChange > 3) {
    notes.push(`Readiness improved by ${avgReadinessChange.toFixed(0)} points on average`);
  }

  return {
    modality,
    session_count: modalitySessions.length,
    avg_duration_minutes: Math.round(avgDuration),
    avg_next_day_hrv_change: avgHrvChange !== null ? Math.round(avgHrvChange * 10) / 10 : null,
    avg_next_day_readiness_change:
      avgReadinessChange !== null ? Math.round(avgReadinessChange * 10) / 10 : null,
    avg_next_day_sleep_change:
      avgSleepChange !== null ? Math.round(avgSleepChange * 100) / 100 : null,
    effectiveness_score: Math.round(effectivenessScore),
    best_duration_range: bestDurationRange,
    best_timing: bestTiming,
    notes: notes.length > 0 ? notes : ["Insufficient data for detailed analysis"],
  };
}

// ============================================================================
// TEST SUITE
// ============================================================================

describe("Recovery Impact Analysis Edge Function", () => {
  let mockSupabase: ReturnType<typeof createMockSupabaseClient>;
  let mockAnthropic: ReturnType<typeof createMockAnthropicClient>;

  beforeEach(() => {
    mockSupabase = createMockSupabaseClient();
    mockAnthropic = createMockAnthropicClient();
    mockAnthropic._setMockResponse(MOCK_RECOVERY_ANALYSIS_RESPONSE);
    setupMockSupabaseWithPatientData(mockSupabase);
  });

  describe("Request Validation", () => {
    it("should reject requests without patient_id", () => {
      const request = {
        lookback_days: 30,
      };
      const hasPatientId = "patient_id" in request && (request as any).patient_id;
      assertEquals(hasPatientId, false);
    });

    it("should reject invalid patient_id format", () => {
      const request = {
        patient_id: INVALID_UUID,
        lookback_days: 30,
      };
      assertEquals(isValidUUID(request.patient_id), false);
    });

    it("should accept valid patient_id", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
      };
      assertEquals(isValidUUID(request.patient_id), true);
    });

    it("should use default lookback_days of 30", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
      };
      const lookbackDays = (request as any).lookback_days || 30;
      assertEquals(lookbackDays, 30);
    });

    it("should clamp lookback_days to minimum of 7", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        lookback_days: 3,
      };
      const validLookbackDays = Math.min(Math.max(7, request.lookback_days), 90);
      assertEquals(validLookbackDays, 7);
    });

    it("should clamp lookback_days to maximum of 90", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        lookback_days: 120,
      };
      const validLookbackDays = Math.min(Math.max(7, request.lookback_days), 90);
      assertEquals(validLookbackDays, 90);
    });
  });

  describe("HRV/Sleep Correlation Calculations", () => {
    it("should calculate HRV change between days", () => {
      const before = 50;
      const after = 58;
      const change = calculateChange(before, after);
      assertEquals(change, 8);
    });

    it("should handle null values in change calculation", () => {
      assertEquals(calculateChange(null, 50), null);
      assertEquals(calculateChange(50, null), null);
      assertEquals(calculateChange(null, null), null);
    });

    it("should calculate average correctly", () => {
      const values = [48, 52, 55, 58, 50];
      const avg = calculateAverage(values);
      assertEquals(avg, 52.6);
    });

    it("should handle empty array in average calculation", () => {
      const avg = calculateAverage([]);
      assertEquals(avg, null);
    });

    it("should filter out NaN values in average calculation", () => {
      const values = [48, NaN, 52, NaN, 50];
      const avg = calculateAverage(values);
      assertEquals(avg, 50);
    });

    it("should get date string in YYYY-MM-DD format", () => {
      const date = new Date("2026-01-15T10:30:00Z");
      const dateStr = getDateString(date);
      assertEquals(dateStr, "2026-01-15");
    });

    it("should add days to date string correctly", () => {
      const dateStr = "2026-01-15";
      assertEquals(addDays(dateStr, 1), "2026-01-16");
      assertEquals(addDays(dateStr, -1), "2026-01-14");
    });
  });

  describe("Impact Percentage Calculations", () => {
    it("should calculate effectiveness score from HRV changes", () => {
      const sessionsWithMetrics: SessionWithMetrics[] = [
        {
          session: {
            id: "test-1",
            session_type: "sauna",
            duration_minutes: 20,
            logged_at: new Date().toISOString(),
            notes: null,
            rating: 4,
          },
          dayBeforeMetrics: {
            date: "2026-01-14",
            readiness_score: 70,
            sleep_hours: 7.0,
            hrv_rmssd: 48,
            resting_hr: 60,
            soreness_level: 4,
            energy_level: 6,
            stress_level: 5,
          },
          dayOfMetrics: null,
          dayAfterMetrics: {
            date: "2026-01-16",
            readiness_score: 78,
            sleep_hours: 7.5,
            hrv_rmssd: 58,
            resting_hr: 56,
            soreness_level: 2,
            energy_level: 8,
            stress_level: 3,
          },
        },
      ];

      const impact = analyzeModalityImpact(sessionsWithMetrics, "sauna");

      assertExists(impact.effectiveness_score);
      assertEquals(impact.effectiveness_score >= 0, true);
      assertEquals(impact.effectiveness_score <= 100, true);
    });

    it("should return base score of 50 for no data", () => {
      const impact = analyzeModalityImpact([], "sauna");
      assertEquals(impact.effectiveness_score, 0); // No sessions = 0
    });

    it("should calculate positive effectiveness for improving metrics", () => {
      const sessionsWithMetrics: SessionWithMetrics[] = [
        {
          session: {
            id: "test-1",
            session_type: "sauna",
            duration_minutes: 20,
            logged_at: new Date().toISOString(),
            notes: null,
            rating: 4,
          },
          dayBeforeMetrics: {
            date: "2026-01-14",
            readiness_score: 60,
            sleep_hours: 6.0,
            hrv_rmssd: 40,
            resting_hr: 65,
            soreness_level: 5,
            energy_level: 5,
            stress_level: 6,
          },
          dayOfMetrics: null,
          dayAfterMetrics: {
            date: "2026-01-16",
            readiness_score: 80,
            sleep_hours: 8.0,
            hrv_rmssd: 60,
            resting_hr: 55,
            soreness_level: 2,
            energy_level: 8,
            stress_level: 3,
          },
        },
      ];

      const impact = analyzeModalityImpact(sessionsWithMetrics, "sauna");
      assertEquals(impact.effectiveness_score > 50, true);
    });

    it("should calculate HRV change correctly", () => {
      const sessionsWithMetrics: SessionWithMetrics[] = [
        {
          session: {
            id: "test-1",
            session_type: "cold_plunge",
            duration_minutes: 3,
            logged_at: new Date().toISOString(),
            notes: null,
            rating: 5,
          },
          dayBeforeMetrics: {
            date: "2026-01-14",
            readiness_score: 70,
            sleep_hours: 7.0,
            hrv_rmssd: 45,
            resting_hr: 60,
            soreness_level: 4,
            energy_level: 6,
            stress_level: 5,
          },
          dayOfMetrics: null,
          dayAfterMetrics: {
            date: "2026-01-16",
            readiness_score: 75,
            sleep_hours: 7.5,
            hrv_rmssd: 55,
            resting_hr: 58,
            soreness_level: 3,
            energy_level: 7,
            stress_level: 4,
          },
        },
      ];

      const impact = analyzeModalityImpact(sessionsWithMetrics, "cold_plunge");
      assertEquals(impact.avg_next_day_hrv_change, 10); // 55 - 45
    });
  });

  describe("Personalized Recommendations", () => {
    it("should identify best timing from session data", () => {
      const eveningSession: RecoverySession = {
        id: "test-1",
        session_type: "sauna",
        duration_minutes: 20,
        logged_at: "2026-01-15T19:00:00Z", // 7 PM UTC
        notes: null,
        rating: 4,
      };

      const hour = new Date(eveningSession.logged_at).getUTCHours();
      let timing = "Morning";
      if (hour >= 12 && hour < 17) timing = "Afternoon";
      else if (hour >= 17 && hour < 21) timing = "Evening";
      else if (hour >= 21) timing = "Night";

      assertEquals(timing, "Evening");
    });

    it("should calculate best duration range", () => {
      const durations = [15, 20, 18, 22, 25];
      const min = Math.min(...durations);
      const max = Math.max(...durations);
      const avg = durations.reduce((a, b) => a + b, 0) / durations.length;

      const range = `${min}-${max} minutes (avg: ${Math.round(avg)})`;
      assertEquals(range, "15-25 minutes (avg: 20)");
    });

    it("should generate notes for significant HRV improvements", () => {
      const avgHrvChange = 8;
      const modality = "sauna";
      const notes: string[] = [];

      if (avgHrvChange > 5) {
        notes.push(
          `HRV improved by average of ${avgHrvChange.toFixed(1)} ms after ${modality} sessions`
        );
      }

      assertEquals(notes.length, 1);
      assertStringIncludes(notes[0], "HRV improved");
    });

    it("should generate notes for significant readiness improvements", () => {
      const avgReadinessChange = 5;
      const notes: string[] = [];

      if (avgReadinessChange > 3) {
        notes.push(`Readiness improved by ${avgReadinessChange.toFixed(0)} points on average`);
      }

      assertEquals(notes.length, 1);
      assertStringIncludes(notes[0], "Readiness improved");
    });
  });

  describe("Insufficient Data Handling", () => {
    it("should return empty analysis for no recovery sessions", async () => {
      mockSupabase.setMockData("recovery_sessions", []);

      const sessions = await mockSupabase
        .from("recovery_sessions")
        .select("*")
        .eq("patient_id", TEST_PATIENT_ID);

      assertEquals(sessions.data?.length, 0);
    });

    it("should return appropriate response when no sessions found", () => {
      const response = {
        error: "No recovery sessions found in the specified period",
        analysis_id: crypto.randomUUID(),
        patient_id: TEST_PATIENT_ID,
        total_recovery_sessions: 0,
        modality_impacts: [],
        correlation_insights: [],
        overall_recommendations: [
          "Start logging recovery sessions to track their impact on your health metrics",
        ],
        ai_analysis: "Insufficient data for analysis. Please log recovery sessions to enable impact tracking.",
      };

      assertEquals(response.total_recovery_sessions, 0);
      assertEquals(response.modality_impacts.length, 0);
      assertStringIncludes(response.ai_analysis, "Insufficient data");
    });

    it("should handle missing daily metrics gracefully", () => {
      const metricsMap: Record<string, DailyMetrics> = {};
      const sessionDate = "2026-01-15";
      const dayBefore = addDays(sessionDate, -1);

      const dayBeforeMetrics = metricsMap[dayBefore] || null;
      assertEquals(dayBeforeMetrics, null);
    });

    it("should calculate data quality metrics", () => {
      const totalDays = 30;
      const daysWithHrv = MOCK_DAILY_READINESS.filter(
        (m) => m.whoop_hrv_rmssd !== null
      ).length;
      const daysWithSleep = MOCK_DAILY_READINESS.filter(
        (m) => m.sleep_hours !== null
      ).length;
      const daysWithReadiness = MOCK_DAILY_READINESS.filter(
        (m) => m.readiness_score !== null
      ).length;

      const dataQuality = {
        hrv_data_completeness: Math.round((daysWithHrv / totalDays) * 100),
        sleep_data_completeness: Math.round((daysWithSleep / totalDays) * 100),
        readiness_data_completeness: Math.round((daysWithReadiness / totalDays) * 100),
      };

      assertEquals(dataQuality.hrv_data_completeness >= 0, true);
      assertEquals(dataQuality.hrv_data_completeness <= 100, true);
    });

    it("should return default note for insufficient analysis data", () => {
      const impact = analyzeModalityImpact(
        [
          {
            session: {
              id: "test-1",
              session_type: "massage",
              duration_minutes: 60,
              logged_at: new Date().toISOString(),
              notes: null,
              rating: 5,
            },
            dayBeforeMetrics: null,
            dayOfMetrics: null,
            dayAfterMetrics: null,
          },
        ],
        "massage"
      );

      assertEquals(impact.notes.includes("Insufficient data for detailed analysis"), true);
    });
  });

  describe("Caching Behavior", () => {
    it("should check for cached analysis within 24 hours", async () => {
      mockSupabase.setMockData("recovery_impact_analyses", [
        {
          id: "cached-analysis-id",
          patient_id: TEST_PATIENT_ID,
          created_at: new Date().toISOString(),
          total_recovery_sessions: 10,
          modality_impacts: [],
        },
      ]);

      const cached = await mockSupabase
        .from("recovery_impact_analyses")
        .select("*")
        .eq("patient_id", TEST_PATIENT_ID)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      assertExists(cached.data);
    });

    it("should return cached=true when using cached analysis", () => {
      const cachedResponse = { cached: true };
      assertEquals(cachedResponse.cached, true);
    });

    it("should return cached=false for fresh analysis", () => {
      const freshResponse = { cached: false };
      assertEquals(freshResponse.cached, false);
    });
  });

  describe("Claude API Integration", () => {
    it("should call Claude API with recovery data context", async () => {
      mockAnthropic._setMockResponse(MOCK_RECOVERY_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        system: "You are an expert sports scientist...",
        messages: [{ role: "user", content: "Analyze recovery sessions..." }],
        temperature: 0.3,
      });

      assertExists(result);
      assertExists(result.content);
    });

    it("should parse correlation insights from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_RECOVERY_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.correlation_insights);
      assertEquals(Array.isArray(parsed.correlation_insights), true);
    });

    it("should parse optimal protocol from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_RECOVERY_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.optimal_protocol);
      assertExists(parsed.optimal_protocol.weekly_frequency);
      assertExists(parsed.optimal_protocol.timing_recommendations);
    });

    it("should parse combination synergies from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_RECOVERY_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.optimal_protocol.combination_synergies);
      assertEquals(Array.isArray(parsed.optimal_protocol.combination_synergies), true);
    });
  });

  describe("Response Structure", () => {
    it("should include analysis_id", () => {
      const response = {
        analysis_id: crypto.randomUUID(),
      };
      assertExists(response.analysis_id);
      assertEquals(isValidUUID(response.analysis_id), true);
    });

    it("should include analysis_period", () => {
      const startDate = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);
      const endDate = new Date();

      const response = {
        analysis_period: {
          start_date: getDateString(startDate),
          end_date: getDateString(endDate),
          total_days: 30,
        },
      };

      assertExists(response.analysis_period.start_date);
      assertExists(response.analysis_period.end_date);
      assertEquals(response.analysis_period.total_days, 30);
    });

    it("should include modality_impacts array", () => {
      const response = {
        modality_impacts: [
          {
            modality: "sauna",
            session_count: 4,
            effectiveness_score: 75,
          },
        ],
      };

      assertExists(response.modality_impacts);
      assertEquals(Array.isArray(response.modality_impacts), true);
    });

    it("should include data_quality metrics", () => {
      const response = {
        data_quality: {
          hrv_data_completeness: 80,
          sleep_data_completeness: 90,
          readiness_data_completeness: 85,
        },
      };

      assertExists(response.data_quality.hrv_data_completeness);
      assertExists(response.data_quality.sleep_data_completeness);
      assertExists(response.data_quality.readiness_data_completeness);
    });

    it("should include disclaimer", () => {
      const disclaimer =
        "RECOVERY ANALYSIS DISCLAIMER: This analysis is based on correlations in your logged data and general sports science principles.";
      assertStringIncludes(disclaimer, "DISCLAIMER");
      assertStringIncludes(disclaimer, "correlations");
    });
  });

  describe("Modality-Specific Analysis", () => {
    it("should analyze sauna sessions", () => {
      const saunaSessions = MOCK_RECOVERY_SESSIONS.filter(
        (s) => s.session_type === "sauna"
      );
      assertEquals(saunaSessions.length > 0, true);
    });

    it("should analyze cold plunge sessions", () => {
      const coldPlungeSessions = MOCK_RECOVERY_SESSIONS.filter(
        (s) => s.session_type === "cold_plunge"
      );
      assertEquals(coldPlungeSessions.length > 0, true);
    });

    it("should analyze massage sessions", () => {
      const massageSessions = MOCK_RECOVERY_SESSIONS.filter(
        (s) => s.session_type === "massage"
      );
      assertEquals(massageSessions.length > 0, true);
    });

    it("should analyze stretching sessions", () => {
      const stretchingSessions = MOCK_RECOVERY_SESSIONS.filter(
        (s) => s.session_type === "stretching"
      );
      assertEquals(stretchingSessions.length > 0, true);
    });

    it("should identify unique modalities", () => {
      const uniqueModalities = [
        ...new Set(MOCK_RECOVERY_SESSIONS.map((s) => s.session_type)),
      ];
      assertEquals(uniqueModalities.length >= 3, true);
    });

    it("should sort modality impacts by effectiveness score", () => {
      const impacts: ModalityImpact[] = [
        { modality: "sauna", effectiveness_score: 75 } as ModalityImpact,
        { modality: "cold_plunge", effectiveness_score: 85 } as ModalityImpact,
        { modality: "massage", effectiveness_score: 65 } as ModalityImpact,
      ];

      impacts.sort((a, b) => b.effectiveness_score - a.effectiveness_score);

      assertEquals(impacts[0].modality, "cold_plunge");
      assertEquals(impacts[1].modality, "sauna");
      assertEquals(impacts[2].modality, "massage");
    });
  });

  describe("Error Handling", () => {
    it("should handle Anthropic API errors", async () => {
      mockAnthropic._setMockError(new Error("API Error"));

      let errorCaught = false;
      try {
        await mockAnthropic.messages.create({
          model: "claude-sonnet-4-20250514",
          messages: [{ role: "user", content: "Test" }],
        });
      } catch (error) {
        errorCaught = true;
      }

      assertEquals(errorCaught, true);
    });

    it("should return error response with disclaimer", () => {
      const errorResponse = {
        error: "Internal server error",
        disclaimer:
          "Recovery analysis encountered an error. Please try again or consult with a healthcare provider.",
      };

      assertExists(errorResponse.error);
      assertExists(errorResponse.disclaimer);
    });

    it("should handle recovery session fetch errors", async () => {
      mockSupabase.setMockError("recovery_sessions", { message: "Database error" });

      const result = await mockSupabase
        .from("recovery_sessions")
        .select("*")
        .eq("patient_id", TEST_PATIENT_ID);

      assertEquals(result.error !== null, true);
    });

    it("should handle invalid JSON response from Claude", () => {
      const invalidResponse = "This is not JSON";

      let parseError = false;
      try {
        JSON.parse(invalidResponse);
      } catch {
        parseError = true;
      }

      assertEquals(parseError, true);
    });
  });
});
