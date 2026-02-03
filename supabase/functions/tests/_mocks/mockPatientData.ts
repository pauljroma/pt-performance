// ============================================================================
// Mock Patient Data for Testing
// Health Intelligence Platform - Edge Function Tests
// ============================================================================

// Standard test patient ID
export const TEST_PATIENT_ID = '123e4567-e89b-12d3-a456-426614174000';
export const TEST_PATIENT_ID_2 = '223e4567-e89b-12d3-a456-426614174001';
export const TEST_THERAPIST_ID = '323e4567-e89b-12d3-a456-426614174002';
export const TEST_LAB_RESULT_ID = '423e4567-e89b-12d3-a456-426614174003';
export const TEST_SESSION_ID = '523e4567-e89b-12d3-a456-426614174004';

// Invalid UUIDs for testing validation
export const INVALID_UUID = 'not-a-valid-uuid';
export const MALFORMED_UUID = '123e4567-e89b-12d3-a456';

// ============================================================================
// WORKOUT DATA
// ============================================================================

export const MOCK_WORKOUTS = [
  {
    id: 'w1-' + crypto.randomUUID().substring(3),
    patient_id: TEST_PATIENT_ID,
    name: 'Upper Body Strength',
    completed_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString(),
    duration_minutes: 65,
    completed: true
  },
  {
    id: 'w2-' + crypto.randomUUID().substring(3),
    patient_id: TEST_PATIENT_ID,
    name: 'Lower Body Power',
    completed_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    duration_minutes: 55,
    completed: true
  },
  {
    id: 'w3-' + crypto.randomUUID().substring(3),
    patient_id: TEST_PATIENT_ID,
    name: 'Cardio & Core',
    completed_at: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString(),
    duration_minutes: 45,
    completed: true
  },
  {
    id: 'w4-' + crypto.randomUUID().substring(3),
    patient_id: TEST_PATIENT_ID,
    name: 'Full Body Circuit',
    completed_at: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString(),
    duration_minutes: 50,
    completed: true
  }
];

// ============================================================================
// DAILY READINESS / SLEEP / HRV DATA
// ============================================================================

export const MOCK_DAILY_READINESS = [
  {
    id: 'dr1-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 0 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 78,
    sleep_hours: 7.5,
    soreness_level: 3,
    energy_level: 7,
    stress_level: 4,
    whoop_hrv_rmssd: 52,
    whoop_resting_hr: 58
  },
  {
    id: 'dr2-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 72,
    sleep_hours: 6.5,
    soreness_level: 4,
    energy_level: 6,
    stress_level: 5,
    whoop_hrv_rmssd: 48,
    whoop_resting_hr: 60
  },
  {
    id: 'dr3-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 85,
    sleep_hours: 8.0,
    soreness_level: 2,
    energy_level: 8,
    stress_level: 3,
    whoop_hrv_rmssd: 58,
    whoop_resting_hr: 55
  },
  {
    id: 'dr4-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 68,
    sleep_hours: 6.0,
    soreness_level: 5,
    energy_level: 5,
    stress_level: 6,
    whoop_hrv_rmssd: 45,
    whoop_resting_hr: 62
  },
  {
    id: 'dr5-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 4 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 75,
    sleep_hours: 7.2,
    soreness_level: 3,
    energy_level: 7,
    stress_level: 4,
    whoop_hrv_rmssd: 50,
    whoop_resting_hr: 59
  },
  {
    id: 'dr6-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 82,
    sleep_hours: 7.8,
    soreness_level: 2,
    energy_level: 8,
    stress_level: 3,
    whoop_hrv_rmssd: 55,
    whoop_resting_hr: 56
  },
  {
    id: 'dr7-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    date: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    readiness_score: 70,
    sleep_hours: 6.8,
    soreness_level: 4,
    energy_level: 6,
    stress_level: 5,
    whoop_hrv_rmssd: 47,
    whoop_resting_hr: 61
  }
];

// ============================================================================
// LAB RESULTS DATA
// ============================================================================

export const MOCK_LAB_RESULT = {
  id: TEST_LAB_RESULT_ID,
  patient_id: TEST_PATIENT_ID,
  test_date: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
  provider: 'quest',
  notes: 'Routine bloodwork'
};

export const MOCK_BIOMARKER_VALUES = [
  {
    id: 'bv1-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'vitamin_d',
    value: 32,
    unit: 'ng/mL',
    is_flagged: false
  },
  {
    id: 'bv2-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'cholesterol_total',
    value: 185,
    unit: 'mg/dL',
    is_flagged: false
  },
  {
    id: 'bv3-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'hdl',
    value: 62,
    unit: 'mg/dL',
    is_flagged: false
  },
  {
    id: 'bv4-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'ldl',
    value: 95,
    unit: 'mg/dL',
    is_flagged: false
  },
  {
    id: 'bv5-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'triglycerides',
    value: 140,
    unit: 'mg/dL',
    is_flagged: false
  },
  {
    id: 'bv6-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'glucose',
    value: 92,
    unit: 'mg/dL',
    is_flagged: false
  },
  {
    id: 'bv7-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'testosterone_total',
    value: 650,
    unit: 'ng/dL',
    is_flagged: false
  },
  {
    id: 'bv8-' + crypto.randomUUID().substring(4),
    lab_result_id: TEST_LAB_RESULT_ID,
    biomarker_type: 'tsh',
    value: 2.1,
    unit: 'mIU/L',
    is_flagged: false
  }
];

export const MOCK_BIOMARKER_REFERENCE_RANGES = [
  {
    biomarker_type: 'vitamin_d',
    name: 'Vitamin D, 25-Hydroxy',
    category: 'Vitamins',
    optimal_low: 40,
    optimal_high: 60,
    normal_low: 30,
    normal_high: 100,
    unit: 'ng/mL',
    description: 'Essential for bone health, immune function, and hormone regulation'
  },
  {
    biomarker_type: 'cholesterol_total',
    name: 'Total Cholesterol',
    category: 'Lipid Panel',
    optimal_low: 125,
    optimal_high: 180,
    normal_low: null,
    normal_high: 200,
    unit: 'mg/dL',
    description: 'Total blood cholesterol level'
  },
  {
    biomarker_type: 'hdl',
    name: 'HDL Cholesterol',
    category: 'Lipid Panel',
    optimal_low: 50,
    optimal_high: 80,
    normal_low: 40,
    normal_high: null,
    unit: 'mg/dL',
    description: 'High-density lipoprotein - "good" cholesterol'
  },
  {
    biomarker_type: 'ldl',
    name: 'LDL Cholesterol',
    category: 'Lipid Panel',
    optimal_low: null,
    optimal_high: 100,
    normal_low: null,
    normal_high: 130,
    unit: 'mg/dL',
    description: 'Low-density lipoprotein - target varies by cardiovascular risk'
  },
  {
    biomarker_type: 'triglycerides',
    name: 'Triglycerides',
    category: 'Lipid Panel',
    optimal_low: null,
    optimal_high: 100,
    normal_low: null,
    normal_high: 150,
    unit: 'mg/dL',
    description: 'Blood fat level, affected by diet and exercise'
  },
  {
    biomarker_type: 'glucose',
    name: 'Glucose, Fasting',
    category: 'Metabolic',
    optimal_low: 72,
    optimal_high: 90,
    normal_low: 70,
    normal_high: 100,
    unit: 'mg/dL',
    description: 'Fasting blood sugar level'
  },
  {
    biomarker_type: 'testosterone_total',
    name: 'Testosterone, Total',
    category: 'Hormones',
    optimal_low: 500,
    optimal_high: 900,
    normal_low: 300,
    normal_high: 1000,
    unit: 'ng/dL',
    description: 'Primary male sex hormone'
  },
  {
    biomarker_type: 'tsh',
    name: 'TSH',
    category: 'Thyroid',
    optimal_low: 1.0,
    optimal_high: 2.5,
    normal_low: 0.4,
    normal_high: 4.0,
    unit: 'mIU/L',
    description: 'Thyroid Stimulating Hormone'
  }
];

// ============================================================================
// FASTING DATA
// ============================================================================

export const MOCK_FASTING_LOGS = [
  {
    id: 'fl1-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    started_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000).toISOString(),
    ended_at: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000 + 16 * 60 * 60 * 1000).toISOString(),
    planned_hours: 16,
    completed: true,
    protocol_type: '16:8'
  },
  {
    id: 'fl2-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    started_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000).toISOString(),
    ended_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000 + 18 * 60 * 60 * 1000).toISOString(),
    planned_hours: 18,
    completed: true,
    protocol_type: '18:6'
  },
  {
    id: 'fl3-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    started_at: new Date(Date.now() - 8 * 24 * 60 * 60 * 1000).toISOString(),
    ended_at: null,
    planned_hours: 16,
    completed: false,
    protocol_type: '16:8'
  }
];

// ============================================================================
// SUPPLEMENTS DATA
// ============================================================================

export const MOCK_SUPPLEMENTS = [
  {
    id: 's1-' + crypto.randomUUID().substring(3),
    name: 'Creatine Monohydrate',
    category: 'performance',
    evidence_rating: 5,
    dosage_info: '5g daily',
    timing_recommendation: 'Any time'
  },
  {
    id: 's2-' + crypto.randomUUID().substring(3),
    name: 'Vitamin D3',
    category: 'vitamins',
    evidence_rating: 5,
    dosage_info: '5000 IU daily',
    timing_recommendation: 'Morning with fat'
  },
  {
    id: 's3-' + crypto.randomUUID().substring(3),
    name: 'Omega-3 Fish Oil',
    category: 'essential_fatty_acids',
    evidence_rating: 5,
    dosage_info: '2g EPA/DHA daily',
    timing_recommendation: 'With meals'
  },
  {
    id: 's4-' + crypto.randomUUID().substring(3),
    name: 'Magnesium L-Threonate',
    category: 'minerals',
    evidence_rating: 4,
    dosage_info: '144mg elemental magnesium',
    timing_recommendation: 'Before bed'
  }
];

export const MOCK_PATIENT_SUPPLEMENT_STACKS = [
  {
    id: 'pss1-' + crypto.randomUUID().substring(5),
    patient_id: TEST_PATIENT_ID,
    supplement_id: MOCK_SUPPLEMENTS[0].id,
    dosage: 5,
    dosage_unit: 'g',
    frequency: 'daily',
    timing: 'post-workout',
    is_active: true,
    supplements: MOCK_SUPPLEMENTS[0]
  },
  {
    id: 'pss2-' + crypto.randomUUID().substring(5),
    patient_id: TEST_PATIENT_ID,
    supplement_id: MOCK_SUPPLEMENTS[1].id,
    dosage: 5000,
    dosage_unit: 'IU',
    frequency: 'daily',
    timing: 'morning',
    is_active: true,
    supplements: MOCK_SUPPLEMENTS[1]
  }
];

// ============================================================================
// GOALS DATA
// ============================================================================

export const MOCK_PATIENT_GOALS = [
  {
    id: 'pg1-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    category: 'strength',
    title: 'Increase bench press to 225 lbs',
    target_date: new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    status: 'active'
  },
  {
    id: 'pg2-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    category: 'body_composition',
    title: 'Reduce body fat to 12%',
    target_date: new Date(Date.now() + 120 * 24 * 60 * 60 * 1000).toISOString().split('T')[0],
    status: 'active'
  },
  {
    id: 'pg3-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    category: 'sleep',
    title: 'Maintain 7.5+ hours average sleep',
    target_date: null,
    status: 'active'
  }
];

// ============================================================================
// RECOVERY SESSIONS DATA
// ============================================================================

export const MOCK_RECOVERY_SESSIONS = [
  {
    id: 'rs1-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    session_type: 'sauna',
    duration_minutes: 20,
    logged_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000 + 18 * 60 * 60 * 1000).toISOString(),
    notes: 'Post-workout sauna',
    rating: 4
  },
  {
    id: 'rs2-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    session_type: 'cold_plunge',
    duration_minutes: 3,
    logged_at: new Date(Date.now() - 1 * 24 * 60 * 60 * 1000 + 18.5 * 60 * 60 * 1000).toISOString(),
    notes: 'After sauna',
    rating: 5
  },
  {
    id: 'rs3-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    session_type: 'sauna',
    duration_minutes: 15,
    logged_at: new Date(Date.now() - 3 * 24 * 60 * 60 * 1000 + 19 * 60 * 60 * 1000).toISOString(),
    notes: 'Evening sauna',
    rating: 4
  },
  {
    id: 'rs4-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    session_type: 'massage',
    duration_minutes: 60,
    logged_at: new Date(Date.now() - 5 * 24 * 60 * 60 * 1000 + 14 * 60 * 60 * 1000).toISOString(),
    notes: 'Deep tissue massage',
    rating: 5
  },
  {
    id: 'rs5-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    session_type: 'cold_plunge',
    duration_minutes: 4,
    logged_at: new Date(Date.now() - 6 * 24 * 60 * 60 * 1000 + 15 * 60 * 60 * 1000).toISOString(),
    notes: 'Afternoon cold exposure',
    rating: 4
  },
  {
    id: 'rs6-' + crypto.randomUUID().substring(4),
    patient_id: TEST_PATIENT_ID,
    session_type: 'stretching',
    duration_minutes: 30,
    logged_at: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000 + 20 * 60 * 60 * 1000).toISOString(),
    notes: 'Evening mobility work',
    rating: 3
  }
];

// ============================================================================
// AI CHAT SESSION DATA
// ============================================================================

export const MOCK_AI_CHAT_SESSIONS = [
  {
    id: TEST_SESSION_ID,
    athlete_id: TEST_PATIENT_ID,
    started_at: new Date(Date.now() - 1 * 60 * 60 * 1000).toISOString(),
    ended_at: null
  }
];

export const MOCK_AI_CHAT_MESSAGES = [
  {
    id: 'acm1-' + crypto.randomUUID().substring(5),
    session_id: TEST_SESSION_ID,
    role: 'user',
    content: 'How am I doing with my recovery this week?',
    tokens_used: 0,
    model: 'user-input',
    created_at: new Date(Date.now() - 30 * 60 * 1000).toISOString()
  },
  {
    id: 'acm2-' + crypto.randomUUID().substring(5),
    session_id: TEST_SESSION_ID,
    role: 'assistant',
    content: 'Based on your data, your recovery has been solid this week. Your HRV has averaged 51ms which is in a good range...',
    tokens_used: 150,
    model: 'claude-sonnet-4-20250514',
    created_at: new Date(Date.now() - 29 * 60 * 1000).toISOString()
  }
];

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

export function getPatientDataForSupabase() {
  return {
    manual_sessions: MOCK_WORKOUTS,
    daily_readiness: MOCK_DAILY_READINESS,
    lab_results: [MOCK_LAB_RESULT],
    biomarker_values: MOCK_BIOMARKER_VALUES,
    biomarker_reference_ranges: MOCK_BIOMARKER_REFERENCE_RANGES,
    fasting_logs: MOCK_FASTING_LOGS,
    supplements: MOCK_SUPPLEMENTS,
    patient_supplement_stacks: MOCK_PATIENT_SUPPLEMENT_STACKS,
    patient_goals: MOCK_PATIENT_GOALS,
    recovery_sessions: MOCK_RECOVERY_SESSIONS,
    ai_chat_sessions: MOCK_AI_CHAT_SESSIONS,
    ai_chat_messages: MOCK_AI_CHAT_MESSAGES
  };
}

export function setupMockSupabaseWithPatientData(mockClient: any) {
  const data = getPatientDataForSupabase();

  mockClient.setMockData('manual_sessions', data.manual_sessions);
  mockClient.setMockData('daily_readiness', data.daily_readiness);
  mockClient.setMockData('lab_results', data.lab_results);
  mockClient.setMockData('biomarker_values', data.biomarker_values);
  mockClient.setMockData('biomarker_reference_ranges', data.biomarker_reference_ranges);
  mockClient.setMockData('fasting_logs', data.fasting_logs);
  mockClient.setMockData('supplements', data.supplements);
  mockClient.setMockData('patient_supplement_stacks', data.patient_supplement_stacks);
  mockClient.setMockData('patient_goals', data.patient_goals);
  mockClient.setMockData('recovery_sessions', data.recovery_sessions);
  mockClient.setMockData('ai_chat_sessions', data.ai_chat_sessions);
  mockClient.setMockData('ai_chat_messages', data.ai_chat_messages);
}
