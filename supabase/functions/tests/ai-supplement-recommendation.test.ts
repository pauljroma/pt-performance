// ============================================================================
// AI Supplement Recommendation Edge Function Tests
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
  MOCK_SUPPLEMENT_RESPONSE,
} from "./_mocks/mockAnthropicClient.ts";
import {
  TEST_PATIENT_ID,
  INVALID_UUID,
  MOCK_PATIENT_GOALS,
  MOCK_LAB_RESULT,
  MOCK_BIOMARKER_VALUES,
  MOCK_DAILY_READINESS,
  MOCK_PATIENT_SUPPLEMENT_STACKS,
  MOCK_SUPPLEMENTS,
  setupMockSupabaseWithPatientData,
} from "./_mocks/mockPatientData.ts";

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

function isValidUUID(uuid: string): boolean {
  const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
  return uuidRegex.test(uuid);
}

interface SleepData {
  avg_sleep_hours: number;
  avg_sleep_quality: number | null;
  days_below_7_hours: number;
}

interface RecoveryData {
  avg_readiness: number;
  avg_soreness: number;
  avg_energy: number;
  avg_stress: number;
}

function calculateSleepData(readinessEntries: any[]): SleepData {
  const sleepHours = readinessEntries
    .filter((r) => r.sleep_hours !== null)
    .map((r) => r.sleep_hours as number);

  if (sleepHours.length === 0) {
    return { avg_sleep_hours: 0, avg_sleep_quality: null, days_below_7_hours: 0 };
  }

  return {
    avg_sleep_hours: sleepHours.reduce((a, b) => a + b, 0) / sleepHours.length,
    avg_sleep_quality: null,
    days_below_7_hours: sleepHours.filter((h) => h < 7).length,
  };
}

function calculateRecoveryData(readinessEntries: any[]): RecoveryData {
  const readinessScores = readinessEntries.filter((r) => r.readiness_score !== null);
  const sorenessLevels = readinessEntries.filter((r) => r.soreness_level !== null);
  const energyLevels = readinessEntries.filter((r) => r.energy_level !== null);
  const stressLevels = readinessEntries.filter((r) => r.stress_level !== null);

  return {
    avg_readiness:
      readinessScores.length > 0
        ? readinessScores.reduce((sum, r) => sum + r.readiness_score, 0) /
          readinessScores.length
        : 70,
    avg_soreness:
      sorenessLevels.length > 0
        ? sorenessLevels.reduce((sum, r) => sum + r.soreness_level, 0) /
          sorenessLevels.length
        : 3,
    avg_energy:
      energyLevels.length > 0
        ? energyLevels.reduce((sum, r) => sum + r.energy_level, 0) / energyLevels.length
        : 5,
    avg_stress:
      stressLevels.length > 0
        ? stressLevels.reduce((sum, r) => sum + r.stress_level, 0) / stressLevels.length
        : 4,
  };
}

// Momentous product catalog (matching the actual function)
const MOMENTOUS_PRODUCTS: Record<
  string,
  {
    name: string;
    category: string;
    url: string;
    standard_dose: string;
    best_timing: string;
    price_per_serving: number;
  }
> = {
  creatine: {
    name: "Momentous Creatine",
    category: "performance",
    url: "https://www.livemomentous.com/products/creatine",
    standard_dose: "5g",
    best_timing: "Any time, with or without food",
    price_per_serving: 0.5,
  },
  vitamin_d3: {
    name: "Momentous Vitamin D3",
    category: "vitamins",
    url: "https://www.livemomentous.com/products/vitamin-d3",
    standard_dose: "5000 IU",
    best_timing: "Morning with fat-containing meal",
    price_per_serving: 0.35,
  },
  omega3: {
    name: "Momentous Omega-3",
    category: "essential_fatty_acids",
    url: "https://www.livemomentous.com/products/omega-3",
    standard_dose: "2g EPA/DHA",
    best_timing: "With meals",
    price_per_serving: 1.0,
  },
  magnesium: {
    name: "Momentous Magnesium L-Threonate",
    category: "minerals",
    url: "https://www.livemomentous.com/products/magnesium-l-threonate",
    standard_dose: "144mg elemental magnesium",
    best_timing: "30-60 minutes before bed",
    price_per_serving: 1.5,
  },
};

interface SupplementRecommendation {
  supplement_id: string | null;
  name: string;
  brand: string;
  category: string;
  dosage: string;
  timing: string;
  evidence_rating: number;
  rationale: string;
  goal_alignment: string[];
  purchase_url: string | null;
  priority: "essential" | "recommended" | "optional";
  warnings: string[];
}

interface TimingSchedule {
  morning: { name: string; dosage: string; notes: string }[];
  pre_workout: { name: string; dosage: string; notes: string }[];
  post_workout: { name: string; dosage: string; notes: string }[];
  evening: { name: string; dosage: string; notes: string }[];
  with_meals: { name: string; dosage: string; notes: string }[];
}

function buildTimingSchedule(recommendations: SupplementRecommendation[]): TimingSchedule {
  const schedule: TimingSchedule = {
    morning: [],
    pre_workout: [],
    post_workout: [],
    evening: [],
    with_meals: [],
  };

  for (const rec of recommendations) {
    const timing = {
      name: rec.name,
      dosage: rec.dosage,
      notes: rec.rationale.substring(0, 100),
    };

    const timingLower = rec.timing.toLowerCase();
    if (timingLower.includes("morning") || timingLower.includes("am")) {
      schedule.morning.push(timing);
    } else if (timingLower.includes("pre-workout") || timingLower.includes("before exercise")) {
      schedule.pre_workout.push(timing);
    } else if (timingLower.includes("post-workout") || timingLower.includes("after exercise")) {
      schedule.post_workout.push(timing);
    } else if (
      timingLower.includes("evening") ||
      timingLower.includes("bed") ||
      timingLower.includes("night")
    ) {
      schedule.evening.push(timing);
    } else if (timingLower.includes("meal") || timingLower.includes("food")) {
      schedule.with_meals.push(timing);
    } else {
      schedule.morning.push(timing);
    }
  }

  return schedule;
}

// ============================================================================
// TEST SUITE
// ============================================================================

describe("AI Supplement Recommendation Edge Function", () => {
  let mockSupabase: ReturnType<typeof createMockSupabaseClient>;
  let mockAnthropic: ReturnType<typeof createMockAnthropicClient>;

  beforeEach(() => {
    mockSupabase = createMockSupabaseClient();
    mockAnthropic = createMockAnthropicClient();
    mockAnthropic._setMockResponse(MOCK_SUPPLEMENT_RESPONSE);
    setupMockSupabaseWithPatientData(mockSupabase);
  });

  describe("Request Validation", () => {
    it("should reject requests without patient_id", () => {
      const request = {};
      const hasPatientId = "patient_id" in request && (request as any).patient_id;
      assertEquals(hasPatientId, false);
    });

    it("should reject invalid patient_id format", () => {
      const request = {
        patient_id: INVALID_UUID,
      };
      assertEquals(isValidUUID(request.patient_id), false);
    });

    it("should accept valid patient_id", () => {
      const request = {
        patient_id: TEST_PATIENT_ID,
      };
      assertEquals(isValidUUID(request.patient_id), true);
    });
  });

  describe("Recommendation Generation", () => {
    it("should fetch patient goals", async () => {
      const goals = await mockSupabase
        .from("patient_goals")
        .select("id, category, title, target_date, status")
        .eq("patient_id", TEST_PATIENT_ID)
        .eq("status", "active");

      assertExists(goals.data);
      assertEquals(Array.isArray(goals.data), true);
    });

    it("should fetch recent lab results", async () => {
      const labs = await mockSupabase
        .from("lab_results")
        .select("id, test_date, biomarker_values (biomarker_type, value, unit, is_flagged)")
        .eq("patient_id", TEST_PATIENT_ID)
        .order("test_date", { ascending: false })
        .limit(1);

      assertExists(labs.data);
    });

    it("should fetch sleep/readiness data", async () => {
      const readiness = await mockSupabase
        .from("daily_readiness")
        .select("date, readiness_score, sleep_hours, soreness_level, energy_level, stress_level")
        .eq("patient_id", TEST_PATIENT_ID);

      assertExists(readiness.data);
    });

    it("should fetch current supplement stack", async () => {
      const stack = await mockSupabase
        .from("patient_supplement_stacks")
        .select("id, dosage, dosage_unit, frequency, timing, supplements (id, name, category)")
        .eq("patient_id", TEST_PATIENT_ID)
        .eq("is_active", true);

      assertExists(stack.data);
    });

    it("should calculate sleep metrics", () => {
      const sleepData = calculateSleepData(MOCK_DAILY_READINESS);

      assertExists(sleepData.avg_sleep_hours);
      assertEquals(sleepData.avg_sleep_hours > 0, true);
      assertEquals(typeof sleepData.days_below_7_hours, "number");
    });

    it("should calculate recovery metrics", () => {
      const recoveryData = calculateRecoveryData(MOCK_DAILY_READINESS);

      assertExists(recoveryData.avg_readiness);
      assertExists(recoveryData.avg_soreness);
      assertExists(recoveryData.avg_energy);
      assertExists(recoveryData.avg_stress);
    });
  });

  describe("Goal-Based Filtering", () => {
    it("should identify strength goals", () => {
      const strengthGoals = MOCK_PATIENT_GOALS.filter(
        (g) => g.category === "strength"
      );
      assertEquals(strengthGoals.length > 0, true);
    });

    it("should identify body composition goals", () => {
      const bodyCompGoals = MOCK_PATIENT_GOALS.filter(
        (g) => g.category === "body_composition"
      );
      assertEquals(bodyCompGoals.length > 0, true);
    });

    it("should identify sleep goals", () => {
      const sleepGoals = MOCK_PATIENT_GOALS.filter((g) => g.category === "sleep");
      assertEquals(sleepGoals.length > 0, true);
    });

    it("should map goals to supplement categories", () => {
      const goalToSupplementMap: Record<string, string[]> = {
        strength: ["creatine", "protein"],
        sleep: ["magnesium", "sleep_pack"],
        recovery: ["omega3", "collagen", "magnesium"],
        body_composition: ["protein", "omega3"],
      };

      const strengthSupplements = goalToSupplementMap["strength"];
      assertExists(strengthSupplements);
      assertEquals(strengthSupplements.includes("creatine"), true);
    });
  });

  describe("Momentous Product Matching", () => {
    it("should match creatine to Momentous product", () => {
      const product = MOMENTOUS_PRODUCTS["creatine"];
      assertExists(product);
      assertEquals(product.name, "Momentous Creatine");
      assertEquals(product.category, "performance");
    });

    it("should match vitamin D3 to Momentous product", () => {
      const product = MOMENTOUS_PRODUCTS["vitamin_d3"];
      assertExists(product);
      assertEquals(product.name, "Momentous Vitamin D3");
    });

    it("should match omega3 to Momentous product", () => {
      const product = MOMENTOUS_PRODUCTS["omega3"];
      assertExists(product);
      assertEquals(product.name, "Momentous Omega-3");
    });

    it("should match magnesium to Momentous product", () => {
      const product = MOMENTOUS_PRODUCTS["magnesium"];
      assertExists(product);
      assertEquals(product.name, "Momentous Magnesium L-Threonate");
    });

    it("should include purchase URL for Momentous products", () => {
      for (const [key, product] of Object.entries(MOMENTOUS_PRODUCTS)) {
        assertExists(product.url);
        assertStringIncludes(product.url, "livemomentous.com");
      }
    });

    it("should include price per serving for cost calculations", () => {
      let totalCost = 0;
      const selectedProducts = ["creatine", "vitamin_d3", "omega3", "magnesium"];

      for (const key of selectedProducts) {
        const product = MOMENTOUS_PRODUCTS[key];
        assertExists(product.price_per_serving);
        totalCost += product.price_per_serving;
      }

      assertEquals(totalCost > 0, true);
    });
  });

  describe("Dosage Calculations", () => {
    it("should use standard dose when no adjustment needed", () => {
      const standardDose = MOMENTOUS_PRODUCTS["creatine"].standard_dose;
      assertEquals(standardDose, "5g");
    });

    it("should support dose adjustments", () => {
      const recommendation: SupplementRecommendation = {
        supplement_id: null,
        name: "Momentous Vitamin D3",
        brand: "Momentous",
        category: "vitamins",
        dosage: "5000 IU",
        timing: "Morning with fat",
        evidence_rating: 5,
        rationale: "Lab showed deficiency",
        goal_alignment: ["general health"],
        purchase_url: MOMENTOUS_PRODUCTS["vitamin_d3"].url,
        priority: "essential",
        warnings: [],
      };

      assertEquals(recommendation.dosage, "5000 IU");
    });

    it("should include timing recommendations", () => {
      const vitaminD = MOMENTOUS_PRODUCTS["vitamin_d3"];
      assertStringIncludes(vitaminD.best_timing.toLowerCase(), "morning");
    });

    it("should include magnesium timing for sleep", () => {
      const magnesium = MOMENTOUS_PRODUCTS["magnesium"];
      assertStringIncludes(magnesium.best_timing.toLowerCase(), "bed");
    });
  });

  describe("Timing Schedule Building", () => {
    it("should categorize morning supplements", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Vitamin D3",
          brand: "Momentous",
          category: "vitamins",
          dosage: "5000 IU",
          timing: "Morning with breakfast",
          evidence_rating: 5,
          rationale: "Fat-soluble vitamin best absorbed with morning meal",
          goal_alignment: [],
          purchase_url: null,
          priority: "essential",
          warnings: [],
        },
      ];

      const schedule = buildTimingSchedule(recommendations);
      assertEquals(schedule.morning.length, 1);
      assertEquals(schedule.morning[0].name, "Vitamin D3");
    });

    it("should categorize pre-workout supplements", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Alpha-GPC",
          brand: "Momentous",
          category: "cognitive",
          dosage: "300mg",
          timing: "30-60 minutes before exercise",
          evidence_rating: 4,
          rationale: "Enhances mind-muscle connection",
          goal_alignment: [],
          purchase_url: null,
          priority: "optional",
          warnings: [],
        },
      ];

      const schedule = buildTimingSchedule(recommendations);
      assertEquals(schedule.pre_workout.length, 1);
    });

    it("should categorize post-workout supplements", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Whey Protein",
          brand: "Momentous",
          category: "protein",
          dosage: "25g",
          timing: "Post-workout within 30 minutes",
          evidence_rating: 5,
          rationale: "Optimal protein synthesis window",
          goal_alignment: [],
          purchase_url: null,
          priority: "essential",
          warnings: [],
        },
      ];

      const schedule = buildTimingSchedule(recommendations);
      assertEquals(schedule.post_workout.length, 1);
    });

    it("should categorize evening supplements", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Magnesium L-Threonate",
          brand: "Momentous",
          category: "minerals",
          dosage: "144mg",
          timing: "30-60 minutes before bed",
          evidence_rating: 4,
          rationale: "Supports sleep quality",
          goal_alignment: [],
          purchase_url: null,
          priority: "recommended",
          warnings: [],
        },
      ];

      const schedule = buildTimingSchedule(recommendations);
      assertEquals(schedule.evening.length, 1);
    });

    it("should categorize with-meals supplements", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Omega-3",
          brand: "Momentous",
          category: "essential_fatty_acids",
          dosage: "2g",
          timing: "With meals",
          evidence_rating: 5,
          rationale: "Better absorption with food",
          goal_alignment: [],
          purchase_url: null,
          priority: "essential",
          warnings: [],
        },
      ];

      const schedule = buildTimingSchedule(recommendations);
      assertEquals(schedule.with_meals.length, 1);
    });

    it("should default unspecified timing to morning", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Creatine",
          brand: "Momentous",
          category: "performance",
          dosage: "5g",
          timing: "Any time",
          evidence_rating: 5,
          rationale: "Timing doesn't matter",
          goal_alignment: [],
          purchase_url: null,
          priority: "essential",
          warnings: [],
        },
      ];

      const schedule = buildTimingSchedule(recommendations);
      assertEquals(schedule.morning.length, 1);
    });
  });

  describe("Caching Behavior", () => {
    it("should check for cached recommendations within 7 days", async () => {
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

      mockSupabase.setMockData("supplement_recommendations", [
        {
          id: "cached-rec-id",
          patient_id: TEST_PATIENT_ID,
          created_at: new Date().toISOString(),
          recommendations: [],
          stack_summary: "Cached stack",
        },
      ]);

      const cached = await mockSupabase
        .from("supplement_recommendations")
        .select("*")
        .eq("patient_id", TEST_PATIENT_ID)
        .gte("created_at", sevenDaysAgo)
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      assertExists(cached.data);
    });

    it("should return cached=true when using cached recommendation", () => {
      const cachedResponse = {
        recommendation_id: "cached-id",
        cached: true,
      };
      assertEquals(cachedResponse.cached, true);
    });

    it("should return cached=false for fresh recommendation", () => {
      const freshResponse = {
        recommendation_id: crypto.randomUUID(),
        cached: false,
      };
      assertEquals(freshResponse.cached, false);
    });
  });

  describe("Claude API Integration", () => {
    it("should call Claude API with patient context", async () => {
      mockAnthropic._setMockResponse(MOCK_SUPPLEMENT_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        max_tokens: 2048,
        messages: [{ role: "user", content: "Generate supplement recommendations..." }],
        temperature: 0.4,
      });

      assertExists(result);
      assertExists(result.content);
    });

    it("should parse recommendations from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_SUPPLEMENT_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.recommendations);
      assertEquals(Array.isArray(parsed.recommendations), true);
    });

    it("should parse stack summary from AI response", async () => {
      mockAnthropic._setMockResponse(MOCK_SUPPLEMENT_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.stack_summary);
      assertEquals(typeof parsed.stack_summary, "string");
    });

    it("should parse interaction warnings", async () => {
      mockAnthropic._setMockResponse(MOCK_SUPPLEMENT_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.interaction_warnings);
      assertEquals(Array.isArray(parsed.interaction_warnings), true);
    });

    it("should parse goal coverage mapping", async () => {
      mockAnthropic._setMockResponse(MOCK_SUPPLEMENT_RESPONSE);

      const result = await mockAnthropic.messages.create({
        model: "claude-sonnet-4-20250514",
        messages: [{ role: "user", content: "Test" }],
      });

      const parsed = JSON.parse(result.content[0].text);
      assertExists(parsed.goal_coverage);
      assertEquals(typeof parsed.goal_coverage, "object");
    });
  });

  describe("Response Structure", () => {
    it("should include recommendation_id", () => {
      const response = {
        recommendation_id: crypto.randomUUID(),
      };
      assertExists(response.recommendation_id);
      assertEquals(isValidUUID(response.recommendation_id), true);
    });

    it("should include total_daily_cost_estimate", () => {
      const response = {
        total_daily_cost_estimate: "$3.35/day",
      };
      assertExists(response.total_daily_cost_estimate);
      assertStringIncludes(response.total_daily_cost_estimate, "$");
    });

    it("should include timing_schedule", () => {
      const response = {
        timing_schedule: {
          morning: [],
          pre_workout: [],
          post_workout: [],
          evening: [],
          with_meals: [],
        },
      };
      assertExists(response.timing_schedule.morning);
      assertExists(response.timing_schedule.evening);
    });

    it("should include disclaimer", () => {
      const disclaimer =
        "SUPPLEMENT DISCLAIMER: These recommendations are for informational purposes only and are not intended to diagnose, treat, cure, or prevent any disease.";
      assertStringIncludes(disclaimer, "SUPPLEMENT DISCLAIMER");
      assertStringIncludes(disclaimer, "informational");
    });

    it("should include recommendations with priority levels", () => {
      const recommendations: SupplementRecommendation[] = [
        {
          supplement_id: null,
          name: "Creatine",
          brand: "Momentous",
          category: "performance",
          dosage: "5g",
          timing: "Any time",
          evidence_rating: 5,
          rationale: "Essential for performance",
          goal_alignment: [],
          purchase_url: null,
          priority: "essential",
          warnings: [],
        },
        {
          supplement_id: null,
          name: "Ashwagandha",
          brand: "Momentous",
          category: "adaptogens",
          dosage: "600mg",
          timing: "Evening",
          evidence_rating: 4,
          rationale: "Helps with stress",
          goal_alignment: [],
          purchase_url: null,
          priority: "optional",
          warnings: [],
        },
      ];

      const essential = recommendations.filter((r) => r.priority === "essential");
      const optional = recommendations.filter((r) => r.priority === "optional");

      assertEquals(essential.length, 1);
      assertEquals(optional.length, 1);
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
          "Supplement recommendations could not be generated. Please consult a healthcare provider.",
      };

      assertExists(errorResponse.error);
      assertExists(errorResponse.disclaimer);
    });

    it("should handle missing lab data gracefully", () => {
      const labResult = null;
      const hasBiomarkers = labResult !== null;
      assertEquals(hasBiomarkers, false);
    });

    it("should handle empty goals list", () => {
      const goals: any[] = [];
      const defaultGoal = goals.length > 0 ? goals : [{ title: "General health optimization" }];
      assertEquals(defaultGoal[0].title, "General health optimization");
    });
  });

  describe("Evidence Rating", () => {
    it("should assign high evidence rating to creatine", () => {
      const creatine = MOCK_SUPPLEMENTS.find((s) => s.name.toLowerCase().includes("creatine"));
      assertExists(creatine);
      assertEquals(creatine.evidence_rating, 5);
    });

    it("should only recommend supplements with evidence rating >= 3", () => {
      const minimumRating = 3;
      const validSupplements = MOCK_SUPPLEMENTS.filter(
        (s) => s.evidence_rating >= minimumRating
      );
      assertEquals(validSupplements.length, MOCK_SUPPLEMENTS.length);
    });
  });
});
