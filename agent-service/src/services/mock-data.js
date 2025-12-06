/**
 * Mock Data Service
 * Provides demo data when Supabase is not available
 * Based on 003_seed_demo_data.sql
 */

export const DEMO_PATIENT_ID = '00000000-0000-0000-0000-000000000001';

export const mockPatient = {
  id: DEMO_PATIENT_ID,
  therapist_id: '00000000-0000-0000-0000-000000000100',
  first_name: 'John',
  last_name: 'Brebbia',
  email: 'demo-athlete@ptperformance.app',
  date_of_birth: '1990-05-27',
  sport: 'Baseball',
  position: 'Pitcher (Right-handed)',
  dominant_hand: 'Right',
  height_in: 73,
  weight_lb: 195,
  medical_history: {
    injuries: [{
      year: 2025,
      body_region: 'elbow',
      diagnosis: 'Grade 1 tricep strain',
      notes: 'Minor strain during spring training, conservative rehab protocol'
    }],
    surgeries: [],
    chronic_conditions: []
  },
  medications: {
    current: [],
    allergies: []
  },
  goals: 'Return to full throwing capacity by June 2025. Regain 94-96 mph fastball velocity. Improve shoulder stability and reduce injury risk.',
  created_at: '2025-01-01T08:30:00Z'
};

export const mockProgram = {
  id: '00000000-0000-0000-0000-000000000200',
  patient_id: DEMO_PATIENT_ID,
  name: '8-Week On-Ramp',
  description: 'Post-tricep strain rehab program with progressive throwing reintegration',
  start_date: '2025-01-06',
  end_date: '2025-03-03',
  status: 'active',
  created_at: '2025-01-01T09:00:00Z'
};

export const mockPainLogs = [
  {
    id: '1',
    patient_id: DEMO_PATIENT_ID,
    logged_at: '2025-12-05T10:00:00Z',
    pain_rest: 1,
    pain_during: 2,
    pain_after: 2,
    notes: 'Minor discomfort during overhead work'
  },
  {
    id: '2',
    patient_id: DEMO_PATIENT_ID,
    logged_at: '2025-12-04T10:00:00Z',
    pain_rest: 1,
    pain_during: 3,
    pain_after: 2,
    notes: 'Felt tightness during warmup'
  },
  {
    id: '3',
    patient_id: DEMO_PATIENT_ID,
    logged_at: '2025-12-03T10:00:00Z',
    pain_rest: 0,
    pain_during: 2,
    pain_after: 1,
    notes: 'Good day, minimal pain'
  }
];

export const mockExerciseLogs = [
  {
    id: '1',
    patient_id: DEMO_PATIENT_ID,
    session_id: 'session-1',
    session_exercise_id: 'se-1',
    performed_at: '2025-12-05T14:00:00Z',
    set_number: 1,
    actual_reps: 10,
    actual_load: 135,
    rpe: 7,
    pain_score: 2,
    session_exercise: {
      exercise_template: {
        name: 'Trap Bar Deadlift',
        category: 'strength'
      }
    }
  },
  {
    id: '2',
    patient_id: DEMO_PATIENT_ID,
    session_id: 'session-1',
    session_exercise_id: 'se-2',
    performed_at: '2025-12-05T14:15:00Z',
    set_number: 1,
    actual_reps: 8,
    actual_load: 95,
    rpe: 6,
    pain_score: 1,
    session_exercise: {
      exercise_template: {
        name: 'Bench Press',
        category: 'strength'
      }
    }
  }
];

export const mockBullpenLogs = [
  {
    id: '1',
    patient_id: DEMO_PATIENT_ID,
    logged_at: '2025-12-05T16:00:00Z',
    pitch_type: 'Fastball',
    velocity: 92,
    command_rating: 7,
    pitch_count: 25,
    pain_score: 2,
    notes: 'Felt strong, good extension'
  },
  {
    id: '2',
    patient_id: DEMO_PATIENT_ID,
    logged_at: '2025-12-03T16:00:00Z',
    pitch_type: 'Fastball',
    velocity: 91,
    command_rating: 8,
    pitch_count: 20,
    pain_score: 1,
    notes: 'Excellent session'
  },
  {
    id: '3',
    patient_id: DEMO_PATIENT_ID,
    logged_at: '2025-12-01T16:00:00Z',
    pitch_type: 'Fastball',
    velocity: 90,
    command_rating: 7,
    pitch_count: 15,
    pain_score: 2,
    notes: 'Building back up'
  }
];

export const mockPhase = {
  id: 'phase-1',
  program_id: mockProgram.id,
  name: 'Phase 1: Foundation',
  sequence: 1,
  start_date: '2025-01-06',
  end_date: '2025-01-19',
  notes: 'Build base strength and mobility'
};

export const mockSession = {
  id: 'session-1',
  phase_id: mockPhase.id,
  name: 'Week 1 - Day 1',
  sequence: 1,
  weekday: 1, // Monday
  notes: 'Focus on form and control'
};

export const mockSessionExercises = [
  {
    id: 'se-1',
    session_id: mockSession.id,
    exercise_template_id: 'ex-1',
    target_sets: 3,
    target_reps: 10,
    target_load: 135,
    target_rpe: 7,
    tempo: '3-0-1-0',
    notes: 'Focus on hip hinge',
    sequence: 1,
    exercise_template: {
      id: 'ex-1',
      name: 'Trap Bar Deadlift',
      category: 'strength',
      body_region: 'posterior chain',
      rm_method: 'epley'
    }
  },
  {
    id: 'se-2',
    session_id: mockSession.id,
    exercise_template_id: 'ex-2',
    target_sets: 3,
    target_reps: 8,
    target_load: 95,
    target_rpe: 6,
    tempo: '2-0-1-0',
    notes: 'Scapular control',
    sequence: 2,
    exercise_template: {
      id: 'ex-2',
      name: 'Bench Press',
      category: 'strength',
      body_region: 'chest',
      rm_method: 'epley'
    }
  }
];

export const mockExerciseTemplates = [
  {
    id: 'ex-1',
    name: 'Trap Bar Deadlift',
    category: 'strength',
    body_region: 'posterior chain',
    rm_method: 'epley'
  },
  {
    id: 'ex-2',
    name: 'Bench Press',
    category: 'strength',
    body_region: 'chest',
    rm_method: 'epley'
  },
  {
    id: 'ex-3',
    name: 'Front Squat',
    category: 'strength',
    body_region: 'legs',
    rm_method: 'brzycki'
  }
];
