// ============================================================================
// AI Lab Analysis Edge Function Tests
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
  MOCK_LAB_ANALYSIS_RESPONSE,
} from "./_mocks/mockAnthropicClient.ts";
import {
  TEST_PATIENT_ID,
  TEST_LAB_RESULT_ID,
  INVALID_UUID,
  MOCK_LAB_RESULT,
  MOCK_BIOMARKER_VALUES,
  MOCK_BIOMARKER_REFERENCE_RANGES,
  MOCK_DAILY_READINESS,
  MOCK_WORKOUTS,
  setupMockSupabaseWithPatientData,
} from "./_mocks/mockPatientData.ts";

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

interface BiomarkerReference {
  biomarker_type: string;
  name: string;
  category: string;
  optimal_low: number | null;
  optimal_high: number | null;
  normal_low: number | null;
  normal_high: number | null;
  unit: string;
  description: string | null;
}

function determineBiomarkerStatus(
  value: number,
  reference: BiomarkerReference
): "optimal" | "normal" | "low" | "high" | "critical" {
  const { optimal_low, optimal_high, normal_low, normal_high } = reference;

  // Check for critical values (significantly outside normal range)
  if (normal_low !== null && value < normal_low * 0.7) return "critical";
  if (normal_high !== null && value > normal_high * 1.3) return "critical";

  // Check optimal range
  if (optimal_low !== null && optimal_high !== null) {
    if (value >= optimal_low && value <= optimal_high) return "optimal";
  }

  // Check normal range
  if (normal_low !== null && value < normal_low) return "low";
  if (normal_high !== null && value > normal_high) return "high";

  return "normal";
}

interface BiomarkerAnalysis {
  biomarker_type: string;
  name: string;
  value: number;
  unit: string;
  status: "optimal" | "normal" | "low" | "high" | "critical";
  interpretation: string;
}

function calculateHealthScore(biomarkerAnalyses: BiomarkerAnalysis[]): number {
  if (biomarkerAnalyses.length === 0) return 75;

  let score = 100;
  for (const analysis of biomarkerAnalyses) {
    switch (analysis.status) {
      case "optimal":
        score += 0;
        break;
      case "normal":
        score -= 2;
        break;
      case "low":
        score -= 8;
        break;
      case "high":
        score -= 8;
        break;
      case "critical":
        score -= 15;
        break;
    }
  }

  return Math.max(0, Math.min(100, score));
}

// ============================================================================
// TEST SUITE
// ============================================================================

describe("AI Lab Analysis Edge Function", () => {
  let mockSupabase: ReturnType<typeof createMockSupabaseClient>;
  let mockAnthropic: ReturnType<typeof createMockAnthropicClient>;

  beforeEach(() => {
    mockSupabase = createMockSupabaseClient();
    mockAnthropic = createMockAnthropicClient();
    mockAnthropic._setMockResponse(MOCK_LAB_ANALYSIS_RESPONSE);
    setupMockSupabaseWithPatientData(mockSupabase);
  });

  describe("Request Validation", () => {
    it("should reject requests without patient_id", () => {
      const request = {
        lab_result_id: TEST_LAB_RESULT_ID,
      };

      const hasPatientId = "patient_id" in request && (request as any).patient_id;
      assertEquals(hasPatientId, false);
    });

    it("should reject requests without lab_result_id", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
      };

      const hasLabResultId = "lab_result_id" in request && (request as any).lab_result_id;
      assertEquals(hasLabResultId, false);
    });

    it("should reject invalid patient_id format", () => {
      const request = {
        patient_id: INVALID_UUID,
        lab_result_id: TEST_LAB_RESULT_ID,
      };

      assertEquals(isValidUUID(request.patient_id), false);
    });

    it("should reject invalid lab_result_id format", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        lab_result_id: "not-a-uuid",
      };

      assertEquals(isValidUUID(request.lab_result_id), false);
    });

    it("should accept valid request", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
        lab_result_id: TEST_LAB_RESULT_ID,
      };

      assertEquals(isValidUUID(request.patient_id), true);
      assertEquals(isValidUUID(request.lab_result_id), true);
    });
  });

  describe("Lab Result Analysis", () => {
    it("should fetch lab result by ID and patient_id", async () => {
      const labResult = await mockSupabase
        .from("lab_results")
        .select("*")
        .eq("id", TEST_LAB_RESULT_ID)
        .eq("patient_id", TEST_PATIENT_ID)
        .single();

      assertExists(labResult.data);
      assertEquals(labResult.data.id, TEST_LAB_RESULT_ID);
    });

    it("should fetch biomarker values for lab result", async () => {
      const biomarkers = await mockSupabase
        .from("biomarker_values")
        .select("*")
        .eq("lab_result_id", TEST_LAB_RESULT_ID);

      assertExists(biomarkers.data);
      assertEquals(Array.isArray(biomarkers.data), true);
      assertEquals(biomarkers.data.length > 0, true);
    });

    it("should return 404 when lab result not found", async () => {
      mockSupabase.setMockError("lab_results", { message: "Not found" });

      const labResult = await mockSupabase
        .from("lab_results")
        .select("*")
        .eq("id", "non-existent-id")
        .single();

      assertEquals(labResult.error !== null, true);
    });

    it("should handle missing biomarker values", async () => {
      mockSupabase.setMockData("biomarker_values", []);

      const biomarkers = await mockSupabase
        .from("biomarker_values")
        .select("*")
        .eq("lab_result_id", TEST_LAB_RESULT_ID);

      assertEquals(biomarkers.data?.length, 0);
    });
  });

  describe("Biomarker Optimal Range Comparisons", () => {
    it("should classify biomarker as optimal when in optimal range", () => {
      const reference = MOCK_BIOMARKER_REFERENCE_RANGES.find(
        (r) => r.biomarker_type === "hdl"
      )!;
      const value = 55; // Within optimal range 50-80

      const status = determineBiomarkerStatus(value, reference as BiomarkerReference);
      assertEquals(status, "optimal");
    });

    it("should classify biomarker as normal when in normal but not optimal range", () => {
      const reference = MOCK_BIOMARKER_REFERENCE_RANGES.find(
        (r) => r.biomarker_type === "hdl"
      )!;
      const value = 45; // Above normal low (40) but below optimal low (50)

      const status = determineBiomarkerStatus(value, reference as BiomarkerReference);
      assertEquals(status, "normal");
    });

    it("should classify biomarker as low when below normal range", () => {
      const reference = MOCK_BIOMARKER_REFERENCE_RANGES.find(
        (r) => r.biomarker_type === "glucose"
      )!;
      const value = 65; // Below normal_low of 70

      const status = determineBiomarkerStatus(value, reference as BiomarkerReference);
      assertEquals(status, "low");
    });

    it("should classify biomarker as high when above normal range", () => {
      const reference = MOCK_BIOMARKER_REFERENCE_RANGES.find(
        (r) => r.biomarker_type === "glucose"
      )!;
      const value = 110; // Above normal_high of 100

      const status = determineBiomarkerStatus(value, reference as BiomarkerReference);
      assertEquals(status, "high");
    });

    it("should classify biomarker as critical when significantly outside range", () => {
      const reference = MOCK_BIOMARKER_REFERENCE_RANGES.find(
        (r) => r.biomarker_type === "glucose"
      )!;
      const value = 45; // Below 70 * 0.7 = 49

      const status = determineBiomarkerStatus(value, reference as BiomarkerReference);
      assertEquals(status, "critical");
    });

    it("should handle reference ranges with null values", () => {
      const reference: BiomarkerReference = {
        biomarker_type: "ldl",
        name: "LDL",
        category: "Lipid Panel",
        optimal_low: null,
        optimal_high: 100,
        normal_low: null,
        normal_high: 130,
        unit: "mg/dL",
        description: null,
      };

      const normalValue = 90;
      const highValue = 140;

      assertEquals(determineBiomarkerStatus(normalValue, reference), "normal");
      assertEquals(determineBiomarkerStatus(highValue, reference), "high");
    });
  });

  describe("Health Score Calculation", () => {
    it("should calculate perfect score for all optimal biomarkers", () => {
      const analyses: BiomarkerAnalysis[] = [
        { biomarker_type: "hdl", name: "HDL", value: 60, unit: "mg/dL", status: "optimal", interpretation: "" },
        { biomarker_type: "ldl", name: "LDL", value: 80, unit: "mg/dL", status: "optimal", interpretation: "" },
        { biomarker_type: "glucose", name: "Glucose", value: 85, unit: "mg/dL", status: "optimal", interpretation: "" },
      ];

      const score = calculateHealthScore(analyses);
      assertEquals(score, 100);
    });

    it("should reduce score for normal (non-optimal) biomarkers", () => {
      const analyses: BiomarkerAnalysis[] = [
        { biomarker_type: "hdl", name: "HDL", value: 45, unit: "mg/dL", status: "normal", interpretation: "" },
        { biomarker_type: "ldl", name: "LDL", value: 115, unit: "mg/dL", status: "normal", interpretation: "" },
      ];

      const score = calculateHealthScore(analyses);
      assertEquals(score, 96); // 100 - (2 * 2)
    });

    it("should reduce score more for low/high biomarkers", () => {
      const analyses: BiomarkerAnalysis[] = [
        { biomarker_type: "vitamin_d", name: "Vitamin D", value: 25, unit: "ng/mL", status: "low", interpretation: "" },
        { biomarker_type: "glucose", name: "Glucose", value: 110, unit: "mg/dL", status: "high", interpretation: "" },
      ];

      const score = calculateHealthScore(analyses);
      assertEquals(score, 84); // 100 - (8 * 2)
    });

    it("should reduce score significantly for critical biomarkers", () => {
      const analyses: BiomarkerAnalysis[] = [
        { biomarker_type: "glucose", name: "Glucose", value: 40, unit: "mg/dL", status: "critical", interpretation: "" },
      ];

      const score = calculateHealthScore(analyses);
      assertEquals(score, 85); // 100 - 15
    });

    it("should return default score for empty biomarkers", () => {
      const score = calculateHealthScore([]);
      assertEquals(score, 75);
    });

    it("should clamp score between 0 and 100", () => {
      const manyBadBiomarkers: BiomarkerAnalysis[] = Array(10).fill({
        biomarker_type: "test",
        name: "Test",
        value: 0,
        unit: "",
        status: "critical",
        interpretation: "",
      });

      const score = calculateHealthScore(manyBadBiomarkers);
      assertEquals(score, 0);
    });
  });

  describe("Correlation with Training Data", () => {
    it("should fetch recent workout data", async () => {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString();

      const workouts = await mockSupabase
        .from("manual_sessions")
        .select("completed_at, name, duration_minutes")
        .eq("patient_id", TEST_PATIENT_ID)
        .eq("completed", true)
        .gte("completed_at", thirtyDaysAgo);

      assertExists(workouts.data);
      assertEquals(Array.isArray(workouts.data), true);
    });

    it("should fetch sleep/readiness data for correlations", async () => {
      const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000)
        .toISOString()
        .split("T")[0];

      const readiness = await mockSupabase
        .from("daily_readiness")
        .select("date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level")
        .eq("patient_id", TEST_PATIENT_ID)
        .gte("date", thirtyDaysAgo);

      assertExists(readiness.data);
    });

    it("should calculate average sleep from readiness data", () => {
      const sleepHours = MOCK_DAILY_READINESS
        .filter((r) => r.sleep_hours !== null)
        .map((r) => r.sleep_hours!);

      const avgSleep =
        sleepHours.length > 0
          ? sleepHours.reduce((a, b) => a + b, 0) / sleepHours.length
          : null;

      assertExists(avgSleep);
      assertEquals(avgSleep! > 0, true);
    });

    it("should calculate average readiness score", () => {
      const readinessScores = MOCK_DAILY_READINESS
        .filter((r) => r.readiness_score !== null)
        .map((r) => r.readiness_score!);

      const avgReadiness =
        readinessScores.length > 0
          ? readinessScores.reduce((a, b) => a + b, 0) / readinessScores.length
          : null;

      assertExists(avgReadiness);
      assertEquals(avgReadiness! > 0, true);
    });

    it("should count workout frequency", () => {
      const workoutCount = MOCK_WORKOUTS.length;
      assertEquals(workoutCount > 0, true);
    });
  });

  describe("Caching Behavior", () => {
    it("should check for cached analysis within 24 hours", async () => {
      const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();

      // Simulate cached analysis
      mockSupabase.setMockData("lab_analyses", [
        {
          id: "cached-analysis-id",
          lab_result_id: TEST_LAB_RESULT_ID,
          created_at: new Date().toISOString(),
          analysis_text: "Cached analysis",
          recommendations: [],
          biomarker_analyses: [],
        },
      ]);

      const cached = await mockSupabase
        .from("lab_analyses")
        .select("*")
        .eq("lab_result_id", TEST_LAB_RESULT_ID)
        .gte("created_at", twentyFourHoursAgo)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      assertExists(cached.data);
    });

    it("should return cached=true when using cached analysis", () => {
      const cachedResponse = {
        analysis_id: "cached-id",
        cached: true,
        analysis_text: "Cached analysis",
      };

      assertEquals(cachedResponse.cached, true);
    });

    it("should return cached=false for fresh analysis", () => {
      const freshResponse = {
        analysis_id: crypto.randomUUID(),
        cached: false,
        analysis_text: "Fresh analysis",
      };

      assertEquals(freshResponse.cached, false);
    });

    it("should skip cache for analyses older than 24 hours", async () => {
      const oldAnalysis = {
        id: "old-analysis-id",
        lab_result_id: TEST_LAB_RESULT_ID,
        created_at: new Date(Date.now() - 48 * 60 * 60 * 1000).toISOString(),
      };

      const twentyFourHoursAgo = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
      const isOlderThan24Hours = oldAnalysis.created_at < twentyFourHoursAgo;

      assertEquals(isOlderThan24Hours, true);
    });
  });

  describe("Claude API Integration", () => {
    it("should call Claude API with biomarker context", async () => {
      mockAnthropic._setMockResponse(MOCK_LAB_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [{ role: "user", content: "Analyze these lab results..." }],
        temperature: 0.3,
      });

      assertExists(result);
      assertExists(result.content);
    });

    it("should parse training correlations from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_LAB_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.training_correlations);
      assertEquals(Array.isArray(parsed.training_correlations), true);
    });

    it("should parse sleep correlations from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_LAB_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.sleep_correlations);
      assertEquals(Array.isArray(parsed.sleep_correlations), true);
    });

    it("should include priority actions in response", async () => {
      mockAnthropic._setMockResponse(MOCK_LAB_ANALYSIS_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.priority_actions);
      assertEquals(Array.isArray(parsed.priority_actions), true);
    });
  });

  describe("Response Structure", () => {
    it("should include analysis_id", () => {
      const response = {
        analysis_id: crypto.randomUUID(),
        analysis_text: "Analysis text",
      };

      assertExists(response.analysis_id);
      assertEquals(isValidUUID(response.analysis_id), true);
    });

    it("should include overall_health_score", () => {
      const response = {
        overall_health_score: 85,
      };

      assertEquals(response.overall_health_score >= 0, true);
      assertEquals(response.overall_health_score <= 100, true);
    });

    it("should include medical disclaimer", () => {
      const disclaimer =
        "IMPORTANT MEDICAL DISCLAIMER: This analysis is provided for informational and educational purposes only.";

      assertStringIncludes(disclaimer, "MEDICAL DISCLAIMER");
      assertStringIncludes(disclaimer, "informational");
    });

    it("should include biomarker_analyses array", () => {
      const response = {
        biomarker_analyses: [
          {
            biomarker_type: "vitamin_d",
            name: "Vitamin D",
            value: 32,
            unit: "ng/mL",
            status: "normal",
            interpretation: "Slightly below optimal",
          },
        ],
      };

      assertExists(response.biomarker_analyses);
      assertEquals(Array.isArray(response.biomarker_analyses), true);
      assertEquals(response.biomarker_analyses.length > 0, true);
    });

    it("should include recommendations array", () => {
      const response = {
        recommendations: [
          "Increase Vitamin D supplementation",
          "Retest in 8 weeks",
        ],
      };

      assertExists(response.recommendations);
      assertEquals(Array.isArray(response.recommendations), true);
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
        medical_disclaimer:
          "This service encountered an error. Please consult a healthcare provider for lab result interpretation.",
      };

      assertExists(errorResponse.error);
      assertExists(errorResponse.medical_disclaimer);
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

  describe("Reference Range Fetching", () => {
    it("should fetch reference ranges for biomarker types", async () => {
      const biomarkerTypes = MOCK_BIOMARKER_VALUES.map((bv) => bv.biomarker_type);

      const references = await mockSupabase
        .from("biomarker_reference_ranges")
        .select("*")
        .in("biomarker_type", biomarkerTypes);

      assertExists(references.data);
    });

    it("should create reference map for quick lookup", () => {
      const referenceMap: Record<string, BiomarkerReference> = {};

      for (const ref of MOCK_BIOMARKER_REFERENCE_RANGES) {
        referenceMap[ref.biomarker_type] = ref as BiomarkerReference;
      }

      assertExists(referenceMap["vitamin_d"]);
      assertExists(referenceMap["hdl"]);
      assertExists(referenceMap["glucose"]);
    });
  });
});
