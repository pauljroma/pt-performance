/**
 * PT Assistant Service
 * Generates intelligent summaries from patient data
 * Reference: EPIC_J_PT_ASSISTANT_AGENT_SPEC.md
 * Zone-3c (Backend Intelligence), Zone-12 (UI Integration)
 */

import {
  getPatient,
  getActiveProgram,
  getPainLogs,
  getRecentExerciseLogs,
  getBullpenLogs,
} from './supabase.js';
import { getStrengthTargets } from './strength.js';

/**
 * Generate pain trend summary
 * Reference: EPIC_G_PAIN_INTERPRETATION_MODEL
 */
export function generatePainSummary(painLogs) {
  if (!painLogs || painLogs.length === 0) {
    return {
      status: 'no_data',
      summary: 'No pain data recorded in the last 7 days.',
      severity: 'none',
    };
  }

  // Calculate average pain during activity
  const avgPainDuring = painLogs.reduce((sum, log) => sum + (log.pain_during || 0), 0) / painLogs.length;
  const maxPainDuring = Math.max(...painLogs.map(log => log.pain_during || 0));
  const recentPain = painLogs.slice(0, 3).map(log => log.pain_during || 0);

  // Check for concerning trends
  const highPain = maxPainDuring > 5;
  const moderatePersistent = avgPainDuring >= 3 && painLogs.length >= 2;
  const increasing = recentPain.length >= 2 && recentPain[0] > recentPain[recentPain.length - 1] + 2;

  let status, summary, severity;

  if (highPain) {
    status = 'high_pain';
    summary = `Pain levels concerning: max pain ${maxPainDuring}/10 during activity. Immediate PT review recommended.`;
    severity = 'high';
  } else if (increasing) {
    status = 'pain_increasing';
    summary = `Pain trend increasing over last ${recentPain.length} sessions. Consider reducing intensity.`;
    severity = 'medium';
  } else if (moderatePersistent) {
    status = 'moderate_persistent';
    summary = `Moderate pain (avg ${avgPainDuring.toFixed(1)}/10) persisting over ${painLogs.length} sessions. Monitor closely.`;
    severity = 'medium';
  } else {
    status = 'low_pain';
    summary = `Pain levels well-managed: avg ${avgPainDuring.toFixed(1)}/10, max ${maxPainDuring}/10. Continue current protocol.`;
    severity = 'low';
  }

  return {
    status,
    summary,
    severity,
    avg_pain: Math.round(avgPainDuring * 10) / 10,
    max_pain: maxPainDuring,
    sessions_logged: painLogs.length,
  };
}

/**
 * Generate adherence summary
 */
export function generateAdherenceSummary(exerciseLogs) {
  if (!exerciseLogs || exerciseLogs.length === 0) {
    return {
      status: 'no_data',
      summary: 'No exercise logs recorded in the last 7 days.',
      severity: 'medium',
    };
  }

  // Count unique session dates
  const uniqueDates = new Set(
    exerciseLogs.map(log => log.performed_at.split('T')[0])
  );
  const sessionCount = uniqueDates.size;
  const expectedSessions = 5; // Assume 5 sessions per week for demo

  const adherenceRate = (sessionCount / expectedSessions) * 100;

  let status, summary, severity;

  if (adherenceRate >= 80) {
    status = 'excellent';
    summary = `Excellent adherence: ${sessionCount}/${expectedSessions} sessions completed (${Math.round(adherenceRate)}%). Keep up the great work!`;
    severity = 'low';
  } else if (adherenceRate >= 60) {
    status = 'good';
    summary = `Good adherence: ${sessionCount}/${expectedSessions} sessions completed (${Math.round(adherenceRate)}%). On track.`;
    severity = 'low';
  } else {
    status = 'poor';
    summary = `Low adherence: ${sessionCount}/${expectedSessions} sessions completed (${Math.round(adherenceRate)}%). Check in with patient.`;
    severity = 'high';
  }

  return {
    status,
    summary,
    severity,
    sessions_completed: sessionCount,
    expected_sessions: expectedSessions,
    adherence_rate: Math.round(adherenceRate),
  };
}

/**
 * Generate strength signals summary
 */
export function generateStrengthSummary(strengthTargets) {
  if (!strengthTargets || !strengthTargets.targets || strengthTargets.targets.length === 0) {
    return {
      status: 'no_data',
      summary: 'No strength training data available.',
      severity: 'low',
    };
  }

  const exercisesWithData = strengthTargets.targets.filter(t => t.one_rm_estimate !== null);

  if (exercisesWithData.length === 0) {
    return {
      status: 'no_estimates',
      summary: 'Strength exercises prescribed but no 1RM estimates available yet.',
      severity: 'low',
    };
  }

  const avgSessions = exercisesWithData.reduce((sum, t) => sum + t.total_sessions, 0) / exercisesWithData.length;

  return {
    status: 'tracking',
    summary: `Tracking ${exercisesWithData.length} strength exercises. Average ${Math.round(avgSessions)} sessions per exercise. Progressive targets calculated.`,
    severity: 'low',
    exercises_tracked: exercisesWithData.length,
    avg_sessions: Math.round(avgSessions),
    top_lifts: exercisesWithData.slice(0, 3).map(t => ({
      exercise: t.exercise_name,
      one_rm: t.one_rm_estimate,
    })),
  };
}

/**
 * Generate velocity signals summary (for pitchers)
 * Reference: EPIC_C_THROWING_ONRAMP_PLYO_MODEL
 */
export function generateVelocitySummary(bullpenLogs) {
  if (!bullpenLogs || bullpenLogs.length === 0) {
    return {
      status: 'no_data',
      summary: 'No throwing velocity data recorded.',
      severity: 'low',
    };
  }

  const avgVelocity = bullpenLogs.reduce((sum, log) => sum + (log.velocity || 0), 0) / bullpenLogs.length;
  const maxVelocity = Math.max(...bullpenLogs.map(log => log.velocity || 0));
  const recentVelocities = bullpenLogs.slice(0, 3).map(log => log.velocity || 0);

  // Check for velocity drops
  const baselineVelocity = maxVelocity;
  const currentVelocity = recentVelocities[0] || 0;
  const velocityDrop = baselineVelocity - currentVelocity;

  let status, summary, severity;

  if (velocityDrop > 5) {
    status = 'critical_drop';
    summary = `CRITICAL: Velocity drop of ${velocityDrop.toFixed(1)} mph from baseline ${baselineVelocity} mph. Immediate review required.`;
    severity = 'high';
  } else if (velocityDrop > 3) {
    status = 'moderate_drop';
    summary = `Velocity drop of ${velocityDrop.toFixed(1)} mph from baseline ${baselineVelocity} mph. Monitor workload and recovery.`;
    severity = 'medium';
  } else {
    status = 'normal';
    summary = `Velocity stable: current ${currentVelocity} mph, max ${maxVelocity} mph. Good throwing progression.`;
    severity = 'low';
  }

  return {
    status,
    summary,
    severity,
    current_velocity: currentVelocity,
    max_velocity: maxVelocity,
    avg_velocity: Math.round(avgVelocity * 10) / 10,
    velocity_drop: Math.round(velocityDrop * 10) / 10,
    sessions_logged: bullpenLogs.length,
  };
}

/**
 * Generate comprehensive PT assistant summary for a patient
 */
export async function generatePatientSummary(patientId) {
  // Fetch all required data
  const [patient, program, painLogs, exerciseLogs, bullpenLogs, strengthTargets] = await Promise.all([
    getPatient(patientId),
    getActiveProgram(patientId),
    getPainLogs(patientId, 7),
    getRecentExerciseLogs(patientId, 7),
    getBullpenLogs(patientId, 14),
    getStrengthTargets(patientId),
  ]);

  // Generate individual summaries
  const painSummary = generatePainSummary(painLogs);
  const adherenceSummary = generateAdherenceSummary(exerciseLogs);
  const strengthSummary = generateStrengthSummary(strengthTargets);
  const velocitySummary = generateVelocitySummary(bullpenLogs);

  // Determine overall status
  const severities = [
    painSummary.severity,
    adherenceSummary.severity,
    strengthSummary.severity,
    velocitySummary.severity,
  ];
  const hasHigh = severities.includes('high');
  const hasMedium = severities.includes('medium');
  const overallStatus = hasHigh ? 'needs_attention' : hasMedium ? 'monitoring' : 'on_track';

  // Generate overall summary text
  const summaryParts = [];
  if (painSummary.summary) summaryParts.push(painSummary.summary);
  if (adherenceSummary.summary) summaryParts.push(adherenceSummary.summary);
  if (velocitySummary.status !== 'no_data') summaryParts.push(velocitySummary.summary);
  if (strengthSummary.status === 'tracking') summaryParts.push(strengthSummary.summary);

  return {
    patient_id: patientId,
    patient_name: `${patient.first_name} ${patient.last_name}`,
    sport: patient.sport,
    position: patient.position,
    program_name: program?.name || 'No active program',
    generated_at: new Date().toISOString(),
    overall_status: overallStatus,
    summary: summaryParts.join(' '),
    pain: painSummary,
    adherence: adherenceSummary,
    strength: strengthSummary,
    velocity: velocitySummary,
  };
}

console.log('✅ PT Assistant service initialized');
