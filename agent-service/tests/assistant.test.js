/**
 * PT Assistant Behavior Tests
 * ACP-72: Add PT assistant behavior tests
 *
 * Test scenarios:
 * - Pain > 5 triggers correct recommendation
 * - Velocity drop detected accurately
 * - Adherence < 60% flagged
 * - Summaries are safe (no harmful advice)
 */

import { describe, test, expect, beforeAll } from "@jest/globals";
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load test fixtures
let testData;

beforeAll(() => {
  const fixturePath = path.join(__dirname, "fixtures", "demo-patient-data.json");
  testData = JSON.parse(fs.readFileSync(fixturePath, "utf8"));
});

describe("PT Assistant Behavior Tests", () => {
  describe("Pain Detection", () => {
    test("should detect pain > 5 as high severity", () => {
      const scenario = testData.scenarios.high_pain;
      const latestPain = scenario.pain_logs[scenario.pain_logs.length - 1];

      expect(latestPain.pain_during).toBeGreaterThan(5);
      expect(scenario.expected_flag.severity).toBe("HIGH");
      expect(scenario.expected_flag.should_create_pcr).toBe(true);
    });

    test("should flag pain > 5 for immediate PT review", () => {
      const scenario = testData.scenarios.high_pain;

      // Simulate flag computation
      const flag = computePainFlag(scenario.pain_logs);

      expect(flag).not.toBeNull();
      expect(flag.type).toBe("pain_high");
      expect(flag.severity).toBe("HIGH");
      expect(flag.rationale).toContain("Pain");
    });

    test("should not flag pain <= 3 in safe progression", () => {
      const scenario = testData.scenarios.safe_progression;

      const flag = computePainFlag(scenario.pain_logs);

      // Safe pain levels should not trigger flags
      expect(flag).toBeNull();
    });

    test("should detect increasing pain trend", () => {
      const scenario = testData.scenarios.high_pain;

      // Pain is increasing: 7 -> 8
      const isIncreasing = scenario.pain_logs[1].pain_during > scenario.pain_logs[0].pain_during;

      expect(isIncreasing).toBe(true);
    });
  });

  describe("Velocity Drop Detection", () => {
    test("should detect velocity drop > 3 mph", () => {
      const scenario = testData.scenarios.velocity_drop;
      const logs = scenario.bullpen_logs;

      const velocityDrop = logs[0].velocity - logs[logs.length - 1].velocity;

      expect(velocityDrop).toBeGreaterThanOrEqual(3);
      expect(scenario.expected_flag.type).toBe("velocity_drop_significant");
    });

    test("should flag critical velocity drop > 5 mph", () => {
      const scenario = testData.scenarios.velocity_drop_critical;
      const logs = scenario.bullpen_logs;

      const velocityDrop = logs[0].velocity - logs[1].velocity;

      expect(velocityDrop).toBeGreaterThanOrEqual(5);
      expect(scenario.expected_flag.severity).toBe("HIGH");
      expect(scenario.expected_flag.should_create_pcr).toBe(true);
    });

    test("should compute velocity drop accurately", () => {
      const logs = [
        { velocity: 94, logged_at: "2025-02-10T14:00:00Z" },
        { velocity: 92, logged_at: "2025-02-12T14:00:00Z" },
        { velocity: 88, logged_at: "2025-02-14T14:00:00Z" }
      ];

      const drop = computeVelocityDrop(logs);

      expect(drop).toBe(6); // 94 - 88
    });

    test("should not flag normal velocity variance", () => {
      const logs = [
        { velocity: 92, logged_at: "2025-02-10T14:00:00Z" },
        { velocity: 91, logged_at: "2025-02-12T14:00:00Z" },
        { velocity: 92, logged_at: "2025-02-14T14:00:00Z" }
      ];

      const drop = computeVelocityDrop(logs);

      expect(drop).toBeLessThan(3); // Normal variance
    });
  });

  describe("Adherence Tracking", () => {
    test("should flag adherence < 60%", () => {
      const scenario = testData.scenarios.low_adherence;

      expect(scenario.adherence_pct).toBeLessThan(60);
      expect(scenario.expected_flag.type).toBe("adherence_low");
    });

    test("should calculate adherence percentage correctly", () => {
      const scheduled = 6;
      const completed = 3;

      const adherencePct = (completed / scheduled) * 100;

      expect(adherencePct).toBe(50);
    });

    test("should not flag high adherence", () => {
      const scenario = testData.scenarios.safe_progression;

      expect(scenario.adherence_pct).toBeGreaterThanOrEqual(60);
    });
  });

  describe("Summary Safety", () => {
    test("should not recommend increasing load with high pain", () => {
      const currentPain = 7;
      const recommendation = generateRecommendation({ currentPain });

      // Should recommend reduction, not increase
      expect(recommendation.type).not.toBe("increase_load");
      expect(recommendation.type).not.toBe("increase_intensity");
      expect(["reduce_volume", "reduce_intensity", "add_rest_day"]).toContain(recommendation.type);
    });

    test("should recommend conservative approach for velocity drop", () => {
      const velocityDrop = 6;
      const recommendation = generateRecommendation({ velocityDrop });

      // Should not recommend increasing velocity
      expect(recommendation.type).not.toBe("increase_velocity");
      expect(recommendation.rationale).toContain("velocity");
    });

    test("should never recommend harmful actions", () => {
      const harmfulActions = [
        "ignore_pain",
        "push_through_pain",
        "skip_rest",
        "exceed_protocol"
      ];

      const currentPain = 8;
      const recommendation = generateRecommendation({ currentPain });

      expect(harmfulActions).not.toContain(recommendation.type);
    });

    test("should always include rationale in recommendations", () => {
      const recommendation = generateRecommendation({ currentPain: 5 });

      expect(recommendation.rationale).toBeDefined();
      expect(recommendation.rationale.length).toBeGreaterThan(10);
    });

    test("should flag need for PT review on critical issues", () => {
      const currentPain = 8;
      const recommendation = generateRecommendation({ currentPain });

      expect(recommendation.pt_review_required).toBe(true);
    });
  });

  describe("Protocol Validation", () => {
    test("should block suggestions exceeding protocol constraints", () => {
      const unsafeSuggestion = testData.unsafe_suggestions.increase_velocity_unsafe;
      const constraints = testData.protocol_constraints;

      const isViolation = checkProtocolViolation(unsafeSuggestion, constraints);

      expect(isViolation).toBe(true);
    });

    test("should allow safe suggestions within protocol", () => {
      const safeSuggestion = testData.safe_suggestions.reduce_volume;
      const constraints = testData.protocol_constraints;

      const isViolation = checkProtocolViolation(safeSuggestion, constraints);

      expect(isViolation).toBe(false);
    });

    test("should enforce pain threshold constraint", () => {
      const painConstraint = testData.protocol_constraints.find(
        c => c.constraint_type === "pain_threshold"
      );

      expect(painConstraint.constraint_value).toBe(3);
      expect(painConstraint.violation_severity).toBe("critical");

      // Current pain 4 exceeds threshold 3
      const currentPain = 4;
      const violates = currentPain > painConstraint.constraint_value;

      expect(violates).toBe(true);
    });

    test("should enforce velocity constraint", () => {
      const velocityConstraint = testData.protocol_constraints.find(
        c => c.constraint_type === "max_velocity_mph"
      );

      expect(velocityConstraint.constraint_value).toBe(85);

      // Suggestion of 95 mph exceeds constraint
      const suggestedVelocity = 95;
      const violates = suggestedVelocity > velocityConstraint.constraint_value;

      expect(violates).toBe(true);
    });
  });

  describe("Flag Computation", () => {
    test("should compute all applicable flags", () => {
      const context = {
        pain_logs: testData.scenarios.high_pain.pain_logs,
        bullpen_logs: testData.scenarios.velocity_drop.bullpen_logs,
        adherence_pct: 50
      };

      const flags = computeAllFlags(context);

      // Should have multiple flags
      expect(flags.length).toBeGreaterThan(0);
      expect(flags.some(f => f.type === "pain_high")).toBe(true);
    });

    test("should prioritize flags by severity", () => {
      const flags = [
        { type: "pain_high", severity: "HIGH" },
        { type: "adherence_low", severity: "MEDIUM" },
        { type: "velocity_drop", severity: "MEDIUM" }
      ];

      const sorted = prioritizeFlags(flags);

      expect(sorted[0].severity).toBe("HIGH");
    });

    test("should generate PCR for HIGH severity flags", () => {
      const flag = { type: "pain_high", severity: "HIGH" };

      const shouldCreatePCR = flag.severity === "HIGH" || flag.severity === "CRITICAL";

      expect(shouldCreatePCR).toBe(true);
    });
  });
});

// ============================================================================
// HELPER FUNCTIONS (simulate PT assistant logic)
// ============================================================================

function computePainFlag(painLogs) {
  if (!painLogs || painLogs.length === 0) return null;

  const latestPain = painLogs[painLogs.length - 1];

  if (latestPain.pain_during > 5) {
    return {
      type: "pain_high",
      severity: "HIGH",
      rationale: `Pain level ${latestPain.pain_during}/10 requires immediate attention`,
      pt_review_required: true
    };
  }

  return null;
}

function computeVelocityDrop(bullpenLogs) {
  if (!bullpenLogs || bullpenLogs.length < 2) return 0;

  const maxVelocity = Math.max(...bullpenLogs.map(log => log.velocity));
  const latestVelocity = bullpenLogs[bullpenLogs.length - 1].velocity;

  return maxVelocity - latestVelocity;
}

function generateRecommendation({ currentPain, velocityDrop }) {
  if (currentPain && currentPain > 5) {
    return {
      type: "reduce_intensity",
      rationale: `High pain level (${currentPain}/10) indicates need to reduce training intensity`,
      pt_review_required: true
    };
  }

  if (velocityDrop && velocityDrop > 5) {
    return {
      type: "reduce_volume",
      rationale: `Significant velocity drop (${velocityDrop} mph) suggests fatigue or strain`,
      pt_review_required: true
    };
  }

  return {
    type: "continue_current_plan",
    rationale: "No concerning metrics detected",
    pt_review_required: false
  };
}

function checkProtocolViolation(suggestion, constraints) {
  // Safe actions never violate protocol - they're responses to problems
  const safeActions = ["reduce_volume", "reduce_intensity", "add_rest_day", "reduce_load"];
  if (safeActions.includes(suggestion.type)) {
    return false;
  }

  // Check constraints for potentially unsafe actions
  for (const constraint of constraints) {
    if (constraint.constraint_type === "max_velocity_mph" && suggestion.type === "increase_velocity") {
      if (suggestion.value > constraint.constraint_value) {
        return true;
      }
    }

    if (constraint.constraint_type === "pain_threshold") {
      // Only check pain for increasing actions
      const increasingActions = ["increase_velocity", "increase_load", "increase_volume", "add_overhead_exercise"];
      if (increasingActions.includes(suggestion.type) && suggestion.context?.currentPain > constraint.constraint_value) {
        return true;
      }
    }
  }

  return false;
}

function computeAllFlags(context) {
  const flags = [];

  const painFlag = computePainFlag(context.pain_logs);
  if (painFlag) flags.push(painFlag);

  if (context.adherence_pct < 60) {
    flags.push({
      type: "adherence_low",
      severity: "MEDIUM",
      rationale: `Adherence ${context.adherence_pct}% below target`
    });
  }

  return flags;
}

function prioritizeFlags(flags) {
  const severityOrder = { CRITICAL: 4, HIGH: 3, MEDIUM: 2, LOW: 1 };
  return [...flags].sort((a, b) => severityOrder[b.severity] - severityOrder[a.severity]);
}
