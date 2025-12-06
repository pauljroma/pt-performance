/**
 * Supabase Service
 * Provides database query functions for PT Performance Platform
 * Zone-7 (Data Access), Zone-8 (Data Ingestion)
 */

import { createClient } from '@supabase/supabase-js';
import { config } from '../config.js';
import {
  DEMO_PATIENT_ID,
  mockPatient,
  mockProgram,
  mockPainLogs,
  mockExerciseLogs,
  mockBullpenLogs,
  mockPhase,
  mockSession,
  mockSessionExercises,
  mockExerciseTemplates
} from './mock-data.js';

// Check if Supabase URL is a placeholder
const isPlaceholder = config.supabase.url.includes('your-project');
const useMockData = isPlaceholder;

if (useMockData) {
  console.log('⚠️  Using MOCK DATA (Supabase URL is placeholder)');
}

// Initialize Supabase client (may not work if placeholder URL)
let supabase;
try {
  supabase = createClient(
    config.supabase.url,
    config.supabase.serviceKey,
    {
      auth: {
        autoRefreshToken: false,
        persistSession: false
      }
    }
  );
} catch (e) {
  console.log('⚠️  Supabase client initialization failed, using mock data');
}

/**
 * Get patient profile by ID
 */
export async function getPatient(patientId) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return mockPatient;
    }
    throw new Error(`Patient ${patientId} not found in mock data`);
  }

  const { data, error } = await supabase
    .from('patients')
    .select('*')
    .eq('id', patientId)
    .single();

  if (error) throw error;
  return data;
}

/**
 * Get active program for a patient
 */
export async function getActiveProgram(patientId) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return mockProgram;
    }
    return null;
  }

  const { data, error } = await supabase
    .from('programs')
    .select('*')
    .eq('patient_id', patientId)
    .eq('status', 'active')
    .order('created_at', { ascending: false })
    .limit(1)
    .single();

  if (error && error.code !== 'PGRST116') throw error; // PGRST116 = no rows
  return data;
}

/**
 * Get recent exercise logs for a patient (last N days)
 */
export async function getRecentExerciseLogs(patientId, days = 7) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return mockExerciseLogs;
    }
    return [];
  }

  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const { data, error } = await supabase
    .from('exercise_logs')
    .select(`
      *,
      session_exercise:session_exercises(
        *,
        exercise_template:exercise_templates(name, category)
      )
    `)
    .eq('patient_id', patientId)
    .gte('performed_at', cutoffDate.toISOString())
    .order('performed_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

/**
 * Get pain logs for a patient (last N days)
 */
export async function getPainLogs(patientId, days = 7) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return mockPainLogs;
    }
    return [];
  }

  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const { data, error } = await supabase
    .from('pain_logs')
    .select('*')
    .eq('patient_id', patientId)
    .gte('logged_at', cutoffDate.toISOString())
    .order('logged_at', { ascending: false });

  if (error) throw error;
  return data || [];
}

/**
 * Get bullpen logs for a patient (last N days)
 */
export async function getBullpenLogs(patientId, days = 14) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return mockBullpenLogs;
    }
    return [];
  }

  const cutoffDate = new Date();
  cutoffDate.setDate(cutoffDate.getDate() - days);

  const { data, error } = await supabase
    .from('bullpen_logs')
    .select('*')
    .eq('patient_id', patientId)
    .gte('logged_at', cutoffDate.toISOString())
    .order('logged_at', { ascending: false });

  if (error && error.code !== 'PGRST116') throw error;
  return data || [];
}

/**
 * Get today's session exercises for a patient
 */
export async function getTodaySession(patientId) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return {
        program: mockProgram,
        phase: mockPhase,
        session: mockSession,
        exercises: mockSessionExercises
      };
    }
    return {
      program: null,
      phase: null,
      session: null,
      exercises: []
    };
  }

  // Get active program
  const program = await getActiveProgram(patientId);
  if (!program) {
    return {
      program: null,
      phase: null,
      session: null,
      exercises: []
    };
  }

  // Get current phase
  const { data: phases, error: phaseError } = await supabase
    .from('phases')
    .select('*')
    .eq('program_id', program.id)
    .order('sequence', { ascending: true });

  if (phaseError) throw phaseError;

  // For demo purposes, get the first phase
  const currentPhase = phases?.[0];
  if (!currentPhase) {
    return {
      program,
      phase: null,
      session: null,
      exercises: []
    };
  }

  // Get today's session (using weekday or sequence)
  const today = new Date().getDay(); // 0-6
  const { data: sessions, error: sessionError } = await supabase
    .from('sessions')
    .select('*')
    .eq('phase_id', currentPhase.id)
    .order('sequence', { ascending: true});

  if (sessionError) throw sessionError;

  // For demo, pick first session or match by weekday
  const todaySession = sessions?.find(s => s.weekday === today) || sessions?.[0];

  if (!todaySession) {
    return {
      program,
      phase: currentPhase,
      session: null,
      exercises: []
    };
  }

  // Get session exercises
  const { data: exercises, error: exerciseError } = await supabase
    .from('session_exercises')
    .select(`
      *,
      exercise_template:exercise_templates(*)
    `)
    .eq('session_id', todaySession.id)
    .order('sequence', { ascending: true });

  if (exerciseError) throw exerciseError;

  return {
    program,
    phase: currentPhase,
    session: todaySession,
    exercises: exercises || []
  };
}

/**
 * Get strength exercise logs for calculating 1RM estimates
 */
export async function getStrengthLogs(patientId, exerciseTemplateId = null) {
  if (useMockData) {
    if (patientId === DEMO_PATIENT_ID) {
      return mockExerciseLogs.filter(log =>
        log.session_exercise?.exercise_template?.category === 'strength'
      );
    }
    return [];
  }

  let query = supabase
    .from('exercise_logs')
    .select(`
      *,
      session_exercise:session_exercises(
        exercise_template_id,
        exercise_template:exercise_templates(name, category, rm_method)
      )
    `)
    .eq('patient_id', patientId)
    .order('performed_at', { ascending: false })
    .limit(100);

  if (exerciseTemplateId) {
    // Filter by specific exercise via join
    query = query.eq('session_exercise.exercise_template_id', exerciseTemplateId);
  }

  const { data, error } = await query;
  if (error) throw error;

  // Filter for strength exercises only
  return (data || []).filter(log =>
    log.session_exercise?.exercise_template?.category === 'strength'
  );
}

/**
 * Get all exercise templates (for strength targets)
 */
export async function getExerciseTemplates(category = null) {
  if (useMockData) {
    let templates = mockExerciseTemplates;
    if (category) {
      templates = templates.filter(t => t.category === category);
    }
    return templates;
  }

  let query = supabase
    .from('exercise_templates')
    .select('*')
    .order('name');

  if (category) {
    query = query.eq('category', category);
  }

  const { data, error } = await query;
  if (error) throw error;
  return data || [];
}

console.log('✅ Supabase service initialized');
