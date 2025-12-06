/**
 * Strength Calculation Service
 * Implements 1RM estimation formulas and progressive target calculation
 * Reference: EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md
 * Zone-7 (Data Analytics)
 */

import { getStrengthLogs, getExerciseTemplates } from './supabase.js';

/**
 * Calculate 1RM using Epley formula
 * Formula: 1RM = W * (1 + R / 30)
 */
export function calculateEpley(weight, reps) {
  if (!weight || !reps || reps < 1) return null;
  return weight * (1 + reps / 30);
}

/**
 * Calculate 1RM using Brzycki formula
 * Formula: 1RM = W * 36 / (37 - R)
 */
export function calculateBrzycki(weight, reps) {
  if (!weight || !reps || reps < 1 || reps >= 37) return null;
  return weight * 36 / (37 - reps);
}

/**
 * Calculate 1RM using Lombardi formula
 * Formula: 1RM = W * R^0.10
 */
export function calculateLombardi(weight, reps) {
  if (!weight || !reps || reps < 1) return null;
  return weight * Math.pow(reps, 0.10);
}

/**
 * Calculate 1RM using specified method
 */
export function calculate1RM(weight, reps, method = 'epley') {
  switch (method.toLowerCase()) {
    case 'epley':
      return calculateEpley(weight, reps);
    case 'brzycki':
      return calculateBrzycki(weight, reps);
    case 'lombardi':
      return calculateLombardi(weight, reps);
    default:
      return calculateEpley(weight, reps); // Default to Epley
  }
}

/**
 * Calculate training zone targets from 1RM
 * Based on S&C model:
 * - Strength: 90% of 1RM
 * - Hypertrophy: 77.5% of 1RM
 * - Endurance: 65% of 1RM
 */
export function calculateTrainingZones(oneRM) {
  if (!oneRM) return null;

  return {
    strength: Math.round(oneRM * 0.90 * 100) / 100,
    hypertrophy: Math.round(oneRM * 0.775 * 100) / 100,
    endurance: Math.round(oneRM * 0.65 * 100) / 100,
  };
}

/**
 * Get best 1RM estimate from recent exercise logs
 */
export function getBest1RMFromLogs(logs, method = 'epley') {
  if (!logs || logs.length === 0) return null;

  const estimates = logs
    .filter(log => log.actual_load && log.actual_reps)
    .map(log => ({
      estimate: calculate1RM(log.actual_load, log.actual_reps, method),
      performed_at: log.performed_at,
      weight: log.actual_load,
      reps: log.actual_reps,
    }))
    .filter(est => est.estimate !== null)
    .sort((a, b) => b.estimate - a.estimate);

  return estimates.length > 0 ? estimates[0] : null;
}

/**
 * Get strength targets for a patient
 * Returns 1RM estimates and progressive targets for all strength exercises
 */
export async function getStrengthTargets(patientId) {
  // Get all strength exercise templates
  const templates = await getExerciseTemplates('strength');

  // Get patient's strength logs
  const allLogs = await getStrengthLogs(patientId);

  const targets = [];

  for (const template of templates) {
    // Filter logs for this specific exercise
    const exerciseLogs = allLogs.filter(
      log => log.session_exercise?.exercise_template_id === template.id
    );

    if (exerciseLogs.length === 0) {
      // No logs for this exercise yet
      targets.push({
        exercise_id: template.id,
        exercise_name: template.name,
        rm_method: template.rm_method || 'epley',
        one_rm_estimate: null,
        strength_target: null,
        hypertrophy_target: null,
        endurance_target: null,
        last_performed: null,
        total_sessions: 0,
        notes: 'No logged sessions yet',
      });
      continue;
    }

    // Get best 1RM estimate
    const method = template.rm_method || 'epley';
    const best = getBest1RMFromLogs(exerciseLogs, method);

    if (!best) {
      targets.push({
        exercise_id: template.id,
        exercise_name: template.name,
        rm_method: method,
        one_rm_estimate: null,
        strength_target: null,
        hypertrophy_target: null,
        endurance_target: null,
        last_performed: exerciseLogs[0]?.performed_at,
        total_sessions: exerciseLogs.length,
        notes: 'Unable to calculate 1RM from available data',
      });
      continue;
    }

    // Calculate training zones
    const zones = calculateTrainingZones(best.estimate);

    targets.push({
      exercise_id: template.id,
      exercise_name: template.name,
      rm_method: method,
      one_rm_estimate: Math.round(best.estimate * 100) / 100,
      one_rm_based_on: {
        weight: best.weight,
        reps: best.reps,
        performed_at: best.performed_at,
      },
      strength_target: zones.strength,
      hypertrophy_target: zones.hypertrophy,
      endurance_target: zones.endurance,
      last_performed: exerciseLogs[0]?.performed_at,
      total_sessions: exerciseLogs.length,
      notes: `Based on best lift: ${best.weight} lbs x ${best.reps} reps`,
    });
  }

  return {
    patient_id: patientId,
    generated_at: new Date().toISOString(),
    targets: targets.sort((a, b) =>
      (b.one_rm_estimate || 0) - (a.one_rm_estimate || 0)
    ),
  };
}

console.log('✅ Strength calculation service initialized');
