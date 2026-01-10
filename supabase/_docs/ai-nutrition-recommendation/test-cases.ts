// Test Cases for AI Nutrition Recommendation Edge Function
// BUILD 138 - Nutrition Tracking Enhancement

/**
 * Test Case 1: Pre-Workout Meal (1-2 hours before)
 *
 * Scenario: User has workout scheduled in 90 minutes
 * Expected: Light, easily digestible carbs + moderate protein
 */
export const testCase1_PreWorkout = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440000",
    time_of_day: "2:30 PM",
    context: {
      next_workout_time: "4:00 PM",
      workout_type: "Upper Body Strength"
    }
  },
  expectedBehavior: {
    carbs: { min: 30, max: 45 },
    protein: { min: 15, max: 25 },
    fats: { min: 5, max: 15 },
    reasoningIncludes: ["before workout", "easily digestible", "energy"],
    suggestedTiming: "Eat now"
  }
}

/**
 * Test Case 2: Post-Workout Recovery
 *
 * Scenario: User just finished workout 30 minutes ago
 * Expected: High protein + fast carbs for recovery
 */
export const testCase2_PostWorkout = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440001",
    time_of_day: "5:30 PM"
  },
  // Assumes: scheduled_sessions shows completed workout at 4:30 PM
  expectedBehavior: {
    protein: { min: 30, max: 45 },
    carbs: { min: 40, max: 60 },
    reasoningIncludes: ["recovery", "protein", "replenish"],
    suggestedTiming: "Eat now" // Within recovery window
  }
}

/**
 * Test Case 3: Low Recovery Day
 *
 * Scenario: User has low readiness score (55/100) and high soreness (8/10)
 * Expected: Lighter meal with anti-inflammatory foods
 */
export const testCase3_LowRecovery = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440002",
    time_of_day: "12:00 PM"
  },
  // Assumes: daily_readiness shows readiness_score=55, soreness_level=8
  expectedBehavior: {
    calories: { max: 400 }, // Lighter portion
    reasoningIncludes: ["recovery", "anti-inflammatory", "light", "soreness"],
    foodSuggestions: ["berries", "leafy greens", "omega-3", "yogurt"]
  }
}

/**
 * Test Case 4: High Energy Needs
 *
 * Scenario: User has consumed very few calories, lots remaining
 * Expected: Larger meal to catch up to daily goals
 */
export const testCase4_HighRemainingMacros = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440003",
    time_of_day: "6:00 PM"
  },
  // Assumes: consumed 800 calories, goal 2500, remaining 1700
  expectedBehavior: {
    calories: { min: 600, max: 900 }, // Substantial meal
    protein: { min: 40, max: 60 },
    reasoningIncludes: ["remaining", "catch up", "goals"]
  }
}

/**
 * Test Case 5: Nearly Met Daily Goals
 *
 * Scenario: User has consumed 95% of daily goals
 * Expected: Small snack to finish the day
 */
export const testCase5_NearlyComplete = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440004",
    time_of_day: "8:00 PM"
  },
  // Assumes: consumed 1900/2000 calories, 145/150g protein
  expectedBehavior: {
    calories: { max: 200 },
    protein: { max: 10 },
    reasoningIncludes: ["nearly met", "small", "snack"]
  }
}

/**
 * Test Case 6: Available Foods Constraint
 *
 * Scenario: User specifies available foods (pantry/fridge items)
 * Expected: Recommendation uses available foods
 */
export const testCase6_AvailableFoods = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440005",
    time_of_day: "1:00 PM",
    available_foods: ["chicken breast", "brown rice", "broccoli", "olive oil"]
  },
  expectedBehavior: {
    recommendationIncludes: ["chicken", "rice", "broccoli"],
    reasoningIncludes: ["available"]
  }
}

/**
 * Test Case 7: Morning Meal (No Workout)
 *
 * Scenario: Breakfast recommendation, no workout scheduled
 * Expected: Balanced breakfast to start the day
 */
export const testCase7_Breakfast = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440006",
    time_of_day: "7:00 AM"
  },
  expectedBehavior: {
    protein: { min: 20, max: 35 },
    carbs: { min: 30, max: 60 },
    reasoningIncludes: ["start the day", "energy", "balanced"]
  }
}

/**
 * Test Case 8: Late Night Snack
 *
 * Scenario: User requests recommendation late at night
 * Expected: Light, protein-focused snack (slow-digesting)
 */
export const testCase8_LateNightSnack = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440007",
    time_of_day: "10:00 PM"
  },
  expectedBehavior: {
    calories: { max: 250 },
    protein: { min: 15, max: 25 },
    carbs: { max: 20 },
    reasoningIncludes: ["casein", "slow-digesting", "recovery overnight"],
    foodSuggestions: ["cottage cheese", "greek yogurt", "casein protein"]
  }
}

/**
 * Test Case 9: Cached Recommendation
 *
 * Scenario: User requests recommendation twice within 30 minutes
 * Expected: Second request returns cached result
 */
export const testCase9_CachedResponse = {
  requests: [
    {
      patient_id: "550e8400-e29b-41d4-a716-446655440008",
      time_of_day: "3:00 PM"
    },
    {
      patient_id: "550e8400-e29b-41d4-a716-446655440008",
      time_of_day: "3:15 PM"
    }
  ],
  expectedBehavior: {
    secondResponseHas: { cached: true },
    sameRecommendationId: true,
    noAdditionalOpenAICall: true
  }
}

/**
 * Test Case 10: No Data Scenario
 *
 * Scenario: New user with no nutrition_goals, no daily_readiness, no scheduled_sessions
 * Expected: Function uses sensible defaults and still provides recommendation
 */
export const testCase10_NoData = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440009",
    time_of_day: "12:00 PM"
  },
  expectedBehavior: {
    usesDefaultGoals: true, // 2000 cal, 150g protein, etc.
    stillReturnsRecommendation: true,
    reasoningIncludes: ["balanced", "general"]
  }
}

/**
 * Test Case 11: High Stress Day
 *
 * Scenario: User reports high stress (9/10) in daily_readiness
 * Expected: Comfort foods, stress-reducing nutrients (magnesium, B vitamins)
 */
export const testCase11_HighStress = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440010",
    time_of_day: "6:30 PM"
  },
  // Assumes: daily_readiness shows stress_level=9
  expectedBehavior: {
    reasoningIncludes: ["stress", "magnesium", "calming"],
    foodSuggestions: ["dark chocolate", "nuts", "leafy greens", "avocado"]
  }
}

/**
 * Test Case 12: Low Energy Morning
 *
 * Scenario: User woke up with low energy (3/10) and poor sleep (4 hours)
 * Expected: Quick energy foods, caffeine sources, B vitamins
 */
export const testCase12_LowEnergy = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440011",
    time_of_day: "8:00 AM"
  },
  // Assumes: daily_readiness shows energy_level=3, sleep_hours=4
  expectedBehavior: {
    reasoningIncludes: ["energy", "quick", "B vitamins"],
    foodSuggestions: ["oatmeal", "banana", "coffee", "berries", "eggs"]
  }
}

/**
 * Test Case 13: Error - Missing patient_id
 *
 * Expected: 400 Bad Request
 */
export const testCase13_MissingPatientId = {
  request: {
    time_of_day: "2:00 PM"
  },
  expectedResponse: {
    status: 400,
    error: "patient_id and time_of_day required"
  }
}

/**
 * Test Case 14: Error - Missing time_of_day
 *
 * Expected: 400 Bad Request
 */
export const testCase14_MissingTimeOfDay = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440012"
  },
  expectedResponse: {
    status: 400,
    error: "patient_id and time_of_day required"
  }
}

/**
 * Test Case 15: Long Workout (2-4 hours before)
 *
 * Scenario: User has workout scheduled in 3 hours
 * Expected: Balanced meal with complex carbs, adequate protein
 */
export const testCase15_LongPreWorkout = {
  request: {
    patient_id: "550e8400-e29b-41d4-a716-446655440013",
    time_of_day: "12:00 PM",
    context: {
      next_workout_time: "3:00 PM",
      workout_type: "Lower Body Strength"
    }
  },
  expectedBehavior: {
    protein: { min: 25, max: 40 },
    carbs: { min: 40, max: 70 },
    fats: { min: 10, max: 20 },
    reasoningIncludes: ["3 hours", "complex carbs", "sustained energy"],
    foodSuggestions: ["whole grain", "lean protein", "vegetables"]
  }
}

/**
 * Integration Test: Full Day Scenario
 *
 * Simulates multiple requests throughout the day
 */
export const integrationTest_FullDay = {
  scenario: "User requests recommendations at different times",
  requests: [
    { time_of_day: "7:00 AM", description: "Breakfast" },
    { time_of_day: "10:00 AM", description: "Mid-morning snack" },
    { time_of_day: "12:30 PM", description: "Lunch" },
    { time_of_day: "2:30 PM", description: "Pre-workout (workout at 4 PM)" },
    { time_of_day: "5:00 PM", description: "Post-workout" },
    { time_of_day: "7:30 PM", description: "Dinner" },
    { time_of_day: "9:30 PM", description: "Evening snack" }
  ],
  expectedBehavior: {
    totalCaloriesRecommended: { min: 1800, max: 2200 },
    proteinDistribution: "Spread throughout day",
    preworkoutCarbs: "Higher than other meals",
    postworkoutProtein: "Highest protein meal",
    eveningSnack: "Light, slow-digesting"
  }
}

/**
 * Performance Test
 *
 * Measure response times and cache effectiveness
 */
export const performanceTest = {
  description: "Test response times and caching",
  metrics: {
    uncachedResponseTime: { target: "<2 seconds" },
    cachedResponseTime: { target: "<100ms" },
    cacheHitRate: { target: ">60%" },
    databaseQueriesPerRequest: { target: "<6" }
  }
}

/**
 * SQL Setup for Testing
 *
 * Use this to create test data in database
 */
export const testDataSQL = `
-- Create test patient
INSERT INTO patients (id, email, name) VALUES
('550e8400-e29b-41d4-a716-446655440000', 'test@example.com', 'Test Patient');

-- Create nutrition goals
INSERT INTO nutrition_goals (patient_id, daily_calories, daily_protein_grams, daily_carbs_grams, daily_fats_grams, active) VALUES
('550e8400-e29b-41d4-a716-446655440000', 2500, 180, 250, 75, true);

-- Create some nutrition logs for today
INSERT INTO nutrition_logs (patient_id, log_date, meal_type, description, calories, protein_grams, carbs_grams, fats_grams) VALUES
('550e8400-e29b-41d4-a716-446655440000', CURRENT_DATE, 'breakfast', 'Oatmeal with protein', 450, 30, 60, 12),
('550e8400-e29b-41d4-a716-446655440000', CURRENT_DATE, 'lunch', 'Chicken and rice', 600, 50, 70, 15);

-- Create daily readiness entry
INSERT INTO daily_readiness (patient_id, date, sleep_hours, soreness_level, energy_level, stress_level, readiness_score) VALUES
('550e8400-e29b-41d4-a716-446655440000', CURRENT_DATE, 7.5, 4, 7, 3, 72.0);

-- Create a session and schedule it
INSERT INTO sessions (id, name, description, phase_id) VALUES
('660e8400-e29b-41d4-a716-446655440000', 'Upper Body Strength', 'Push/Pull workout', '770e8400-e29b-41d4-a716-446655440000');

INSERT INTO scheduled_sessions (patient_id, session_id, scheduled_date, scheduled_time, status) VALUES
('550e8400-e29b-41d4-a716-446655440000', '660e8400-e29b-41d4-a716-446655440000', CURRENT_DATE, '16:00:00', 'scheduled');
`;

/**
 * cURL Test Commands
 */
export const curlTests = `
# Test Case 1: Basic request
curl -X POST https://your-project.supabase.co/functions/v1/ai-nutrition-recommendation \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <anon-key>" \\
  -d '{
    "patient_id": "550e8400-e29b-41d4-a716-446655440000",
    "time_of_day": "2:30 PM"
  }'

# Test Case 2: With context and available foods
curl -X POST https://your-project.supabase.co/functions/v1/ai-nutrition-recommendation \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <anon-key>" \\
  -d '{
    "patient_id": "550e8400-e29b-41d4-a716-446655440000",
    "time_of_day": "2:30 PM",
    "available_foods": ["chicken", "rice", "broccoli"],
    "context": {
      "next_workout_time": "4:00 PM",
      "workout_type": "Strength Training"
    }
  }'

# Test Case 3: Missing patient_id (should return 400)
curl -X POST https://your-project.supabase.co/functions/v1/ai-nutrition-recommendation \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <anon-key>" \\
  -d '{
    "time_of_day": "2:30 PM"
  }'

# Test Case 4: Cache test (run twice within 30 minutes)
# First request
curl -X POST https://your-project.supabase.co/functions/v1/ai-nutrition-recommendation \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <anon-key>" \\
  -d '{
    "patient_id": "550e8400-e29b-41d4-a716-446655440000",
    "time_of_day": "2:30 PM"
  }'

# Second request (should return cached: true)
sleep 5
curl -X POST https://your-project.supabase.co/functions/v1/ai-nutrition-recommendation \\
  -H "Content-Type: application/json" \\
  -H "Authorization: Bearer <anon-key>" \\
  -d '{
    "patient_id": "550e8400-e29b-41d4-a716-446655440000",
    "time_of_day": "2:35 PM"
  }'
`;
