// Test Cases for AI Safety Check Edge Function
// Build 79 - Agent 3: Claude Safety Integration

/**
 * Test Suite: AI Safety Check Scenarios
 *
 * Purpose: Validate contraindication detection and warning level escalation
 * across various injury + exercise combinations
 */

// ============================================================
// Test Case 1: Shoulder Injury + Overhead Press (DANGER)
// ============================================================

export const testCase1_ShoulderInjury_OverheadPress = {
  name: "Shoulder Injury + Overhead Press → Should flag as DANGER",
  description: "Severe shoulder injury with overhead pressing movement",

  request: {
    athlete_id: "test-athlete-1",
    exercise_id: "overhead-press-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-1",
      medical_history: {
        injuries: [
          {
            year: 2025,
            body_region: "shoulder",
            diagnosis: "rotator cuff strain",
            severity: "severe",
            notes: "Grade 2 strain, currently in acute phase",
          },
        ],
      },
    },
    exercise: {
      id: "overhead-press-exercise",
      name: "Overhead Press",
      primary_muscle_group: "shoulders",
      muscle_groups: ["deltoids", "triceps"],
      movement_pattern: "vertical push",
      load_type: "barbell",
      clinical_tags: ["overhead", "shoulder_intensive"],
    },
    recovery: {
      recovery_score: 45,
      readiness_band: "yellow",
      hrv_rmssd: 32,
      resting_hr: 68,
      sleep_performance: 72,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "danger",
    should_alert: true,
    fast_path: true, // Should be caught by rule-based system
  },
};

// ============================================================
// Test Case 2: Knee Injury + Squat (WARNING)
// ============================================================

export const testCase2_KneeInjury_Squat = {
  name: "Knee Injury + Squat → Should flag as WARNING",
  description: "Moderate knee injury with squat movement",

  request: {
    athlete_id: "test-athlete-2",
    exercise_id: "back-squat-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-2",
      medical_history: {
        injuries: [
          {
            year: 2025,
            body_region: "knee",
            diagnosis: "patellar tendinopathy",
            severity: "moderate",
            notes: "Improving, currently in rehab phase",
          },
        ],
      },
    },
    exercise: {
      id: "back-squat-exercise",
      name: "Back Squat",
      primary_muscle_group: "quadriceps",
      muscle_groups: ["quadriceps", "glutes", "hamstrings"],
      movement_pattern: "squat",
      load_type: "barbell",
      clinical_tags: ["knee_dominant", "high_load"],
    },
    recovery: {
      recovery_score: 68,
      readiness_band: "green",
      hrv_rmssd: 58,
      resting_hr: 55,
      sleep_performance: 88,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "warning",
    should_alert: true,
    fast_path: false, // May need Claude analysis for nuanced assessment
  },
};

// ============================================================
// Test Case 3: No Injuries + Any Exercise (INFO)
// ============================================================

export const testCase3_NoInjuries_SafeExercise = {
  name: "No Injuries + Any Exercise → Should return INFO (safe)",
  description: "Healthy athlete with appropriate exercise",

  request: {
    athlete_id: "test-athlete-3",
    exercise_id: "bench-press-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-3",
      medical_history: {
        injuries: [],
        surgeries: [],
        chronic_conditions: [],
      },
    },
    exercise: {
      id: "bench-press-exercise",
      name: "Bench Press",
      primary_muscle_group: "chest",
      muscle_groups: ["pectorals", "triceps", "deltoids"],
      movement_pattern: "horizontal push",
      load_type: "barbell",
      clinical_tags: [],
    },
    recovery: {
      recovery_score: 82,
      readiness_band: "green",
      hrv_rmssd: 65,
      resting_hr: 52,
      sleep_performance: 91,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "info",
    should_alert: false,
    fast_path: false,
  },
};

// ============================================================
// Test Case 4: Low Recovery + High Intensity (CAUTION)
// ============================================================

export const testCase4_LowRecovery_HighIntensity = {
  name: "Low Recovery Score + High Intensity → Should flag as CAUTION",
  description: "Poor recovery state with demanding exercise",

  request: {
    athlete_id: "test-athlete-4",
    exercise_id: "deadlift-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-4",
      medical_history: {
        injuries: [],
      },
    },
    exercise: {
      id: "deadlift-exercise",
      name: "Deadlift",
      primary_muscle_group: "posterior_chain",
      muscle_groups: ["hamstrings", "glutes", "lower_back", "traps"],
      movement_pattern: "hip_hinge",
      load_type: "barbell",
      clinical_tags: ["high_cns_demand", "high_load"],
    },
    recovery: {
      recovery_score: 28,
      readiness_band: "red",
      hrv_rmssd: 24,
      resting_hr: 72,
      sleep_performance: 54,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "caution",
    should_alert: false,
    fast_path: false,
  },
};

// ============================================================
// Test Case 5: Elbow Injury + Bench Press (WARNING)
// ============================================================

export const testCase5_ElbowInjury_BenchPress = {
  name: "Elbow Injury + Bench Press → Should flag as WARNING",
  description: "Elbow tendinitis with pressing movement",

  request: {
    athlete_id: "test-athlete-5",
    exercise_id: "bench-press-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-5",
      medical_history: {
        injuries: [
          {
            year: 2025,
            body_region: "elbow",
            diagnosis: "lateral epicondylitis (tennis elbow)",
            severity: "moderate",
            notes: "Pain with gripping and pressing movements",
          },
        ],
      },
    },
    exercise: {
      id: "bench-press-exercise",
      name: "Bench Press",
      primary_muscle_group: "chest",
      muscle_groups: ["pectorals", "triceps", "deltoids"],
      movement_pattern: "horizontal push",
      load_type: "barbell",
      clinical_tags: ["elbow_stress", "grip_intensive"],
    },
    recovery: {
      recovery_score: 71,
      readiness_band: "green",
      hrv_rmssd: 62,
      resting_hr: 56,
      sleep_performance: 85,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "warning",
    should_alert: true,
    fast_path: true,
  },
};

// ============================================================
// Test Case 6: Multiple Injuries + Complex Exercise (DANGER)
// ============================================================

export const testCase6_MultipleInjuries_ComplexExercise = {
  name: "Multiple Injuries + Olympic Lift → Should flag as DANGER",
  description: "Multiple active injuries with complex, high-risk exercise",

  request: {
    athlete_id: "test-athlete-6",
    exercise_id: "clean-and-jerk-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-6",
      medical_history: {
        injuries: [
          {
            year: 2025,
            body_region: "shoulder",
            diagnosis: "AC joint sprain",
            severity: "moderate",
            notes: "Pain with overhead movements",
          },
          {
            year: 2025,
            body_region: "lower back",
            diagnosis: "lumbar strain",
            severity: "mild",
            notes: "Resolving, but sensitive to loaded flexion",
          },
        ],
      },
    },
    exercise: {
      id: "clean-and-jerk-exercise",
      name: "Clean and Jerk",
      primary_muscle_group: "full_body",
      muscle_groups: ["legs", "back", "shoulders", "core"],
      movement_pattern: "olympic_lift",
      load_type: "barbell",
      clinical_tags: [
        "overhead",
        "high_complexity",
        "high_load",
        "explosive",
        "spine_loading",
      ],
    },
    recovery: {
      recovery_score: 52,
      readiness_band: "yellow",
      hrv_rmssd: 41,
      resting_hr: 64,
      sleep_performance: 68,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "danger",
    should_alert: true,
    fast_path: true,
  },
};

// ============================================================
// Test Case 7: Resolved Injury + Same Movement (CAUTION)
// ============================================================

export const testCase7_ResolvedInjury_CautiousReturn = {
  name: "Resolved Injury + Previously Problematic Exercise → CAUTION",
  description: "Injury marked as resolved but returning to challenging movement",

  request: {
    athlete_id: "test-athlete-7",
    exercise_id: "overhead-press-exercise",
  },

  mockData: {
    athlete: {
      id: "test-athlete-7",
      medical_history: {
        injuries: [
          {
            year: 2024,
            body_region: "shoulder",
            diagnosis: "rotator cuff impingement",
            severity: "mild",
            notes: "Resolved after 8 weeks PT, cleared for full activity",
          },
        ],
      },
    },
    exercise: {
      id: "overhead-press-exercise",
      name: "Overhead Press",
      primary_muscle_group: "shoulders",
      muscle_groups: ["deltoids", "triceps"],
      movement_pattern: "vertical push",
      load_type: "barbell",
      clinical_tags: ["overhead", "shoulder_intensive"],
    },
    recovery: {
      recovery_score: 78,
      readiness_band: "green",
      hrv_rmssd: 64,
      resting_hr: 54,
      sleep_performance: 89,
      date: "2025-12-24",
    },
  },

  expectedResult: {
    warning_level: "caution",
    should_alert: false,
    fast_path: false,
  },
};

// ============================================================
// Test Execution Helper
// ============================================================

export const allTestCases = [
  testCase1_ShoulderInjury_OverheadPress,
  testCase2_KneeInjury_Squat,
  testCase3_NoInjuries_SafeExercise,
  testCase4_LowRecovery_HighIntensity,
  testCase5_ElbowInjury_BenchPress,
  testCase6_MultipleInjuries_ComplexExercise,
  testCase7_ResolvedInjury_CautiousReturn,
];

/**
 * Test runner function (for local development)
 */
export async function runTestCase(
  testCase: any,
  edgeFunctionUrl: string,
  authToken: string
) {
  console.log(`\n========================================`);
  console.log(`Running: ${testCase.name}`);
  console.log(`========================================`);

  try {
    const response = await fetch(edgeFunctionUrl, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${authToken}`,
        "Content-Type": "application/json",
      },
      body: JSON.stringify(testCase.request),
    });

    const result = await response.json();

    console.log("Response:", JSON.stringify(result, null, 2));

    // Validate expected results
    const passed =
      result.safety_check?.warning_level === testCase.expectedResult.warning_level &&
      result.should_alert === testCase.expectedResult.should_alert;

    console.log(`\nTest ${passed ? "PASSED ✓" : "FAILED ✗"}`);

    return { testCase: testCase.name, passed, result };
  } catch (error) {
    console.error("Test failed with error:", error);
    return { testCase: testCase.name, passed: false, error };
  }
}
