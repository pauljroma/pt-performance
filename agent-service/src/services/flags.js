/**
 * Flags Service - Risk Engine
 * Computes patient flags based on pain, velocity, command, and adherence data
 *
 * Zone: 3c (Backend Service Logic), 7 (Data Access), 10b (Analytics)
 */

import fetch from 'node-fetch';
import {
  evaluatePainFlags,
  evaluateVelocityFlags,
  evaluateCommandFlags,
  evaluateAdherenceFlags,
  evaluateThrowingPainFlags
} from '../utils/flag-rules.js';

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

/**
 * Compute all flags for a patient
 * @param {string} patientId - UUID of patient
 * @returns {Promise<Array>} - Array of flag objects with severity, rationale, etc.
 */
export async function computeFlags(patientId) {
  try {
    // Fetch all necessary data in parallel
    const [
      patient,
      painLogs,
      bullpenLogs,
      adherence
    ] = await Promise.all([
      getPatient(patientId),
      getRecentPainLogs(patientId, 10),
      getRecentBullpenLogs(patientId, 10),
      getAdherence(patientId)
    ]);

    if (!patient) {
      throw new Error(`Patient ${patientId} not found`);
    }

    const allFlags = [];

    // 1. Evaluate Pain Flags
    const painFlags = evaluatePainFlags(painLogs);
    allFlags.push(...painFlags);

    // 2. Evaluate Velocity Flags (pitchers only)
    const velocityFlags = evaluateVelocityFlags(bullpenLogs, patient.position);
    allFlags.push(...velocityFlags);

    // 3. Evaluate Command Flags (pitchers only)
    const commandFlags = evaluateCommandFlags(bullpenLogs, patient.position);
    allFlags.push(...commandFlags);

    // 4. Evaluate Adherence Flags
    const adherenceFlags = evaluateAdherenceFlags(adherence?.adherence_pct, patientId);
    allFlags.push(...adherenceFlags);

    // 5. Evaluate Throwing Pain Flags (pitchers only)
    const throwingPainFlags = evaluateThrowingPainFlags(bullpenLogs, patient.position);
    allFlags.push(...throwingPainFlags);

    // Sort by severity (HIGH first, then MEDIUM, then LOW)
    const severityOrder = { HIGH: 0, MEDIUM: 1, LOW: 2 };
    allFlags.sort((a, b) => severityOrder[a.severity] - severityOrder[b.severity]);

    return allFlags;
  } catch (error) {
    console.error('Error computing flags:', error);
    throw error;
  }
}

/**
 * Get top N flags (highest severity)
 * @param {string} patientId
 * @param {number} limit - Max number of flags to return
 * @returns {Promise<Array>}
 */
export async function getTopFlags(patientId, limit = 3) {
  const allFlags = await computeFlags(patientId);
  return allFlags.slice(0, limit);
}

/**
 * Get flag count by severity
 * @param {string} patientId
 * @returns {Promise<Object>} - { total, high, medium, low }
 */
export async function getFlagSummary(patientId) {
  const allFlags = await computeFlags(patientId);

  return {
    total: allFlags.length,
    high: allFlags.filter(f => f.severity === 'HIGH').length,
    medium: allFlags.filter(f => f.severity === 'MEDIUM').length,
    low: allFlags.filter(f => f.severity === 'LOW').length,
    flags: allFlags
  };
}

// ==================== SUPABASE DATA FETCHERS ====================

/**
 * Get patient details
 */
async function getPatient(patientId) {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/patients?id=eq.${patientId}&select=*`,
    {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  if (!response.ok) {
    throw new Error(`Failed to fetch patient: ${response.statusText}`);
  }

  const data = await response.json();
  return data.length > 0 ? data[0] : null;
}

/**
 * Get recent pain logs for a patient
 * @param {string} patientId
 * @param {number} limit
 * @returns {Promise<Array>}
 */
async function getRecentPainLogs(patientId, limit = 10) {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/pain_logs?patient_id=eq.${patientId}&order=logged_at.desc&limit=${limit}`,
    {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  if (!response.ok) {
    console.error('Failed to fetch pain logs:', response.statusText);
    return [];
  }

  return await response.json();
}

/**
 * Get recent bullpen logs for a patient
 * @param {string} patientId
 * @param {number} limit
 * @returns {Promise<Array>}
 */
async function getRecentBullpenLogs(patientId, limit = 10) {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/bullpen_logs?patient_id=eq.${patientId}&order=logged_at.desc&limit=${limit}`,
    {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  if (!response.ok) {
    console.error('Failed to fetch bullpen logs:', response.statusText);
    return [];
  }

  return await response.json();
}

/**
 * Get 7-day adherence for a patient
 * @param {string} patientId
 * @returns {Promise<Object>}
 */
async function getAdherence(patientId) {
  // Query the vw_patient_adherence view
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/vw_patient_adherence?patient_id=eq.${patientId}`,
    {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json'
      }
    }
  );

  if (!response.ok) {
    console.error('Failed to fetch adherence:', response.statusText);
    return null;
  }

  const data = await response.json();
  return data.length > 0 ? data[0] : null;
}

/**
 * Get recent session data for context
 * Used for flag rationale and PCR creation
 * @param {string} patientId
 * @param {number} limit
 * @returns {Promise<Array>}
 */
export async function getRecentSessions(patientId, limit = 3) {
  const response = await fetch(
    `${SUPABASE_URL}/rest/v1/exercise_logs?patient_id=eq.${patientId}&order=performed_at.desc&limit=${limit * 10}`,
    {
      headers: {
        'apikey': SUPABASE_SERVICE_KEY,
        'Authorization': `Bearer ${SUPABASE_SERVICE_KEY}`,
        'Content-Type': 'application/json',
        'Prefer': 'return=representation'
      }
    }
  );

  if (!response.ok) {
    console.error('Failed to fetch recent sessions:', response.statusText);
    return [];
  }

  const logs = await response.json();

  // Group by session_id and get unique sessions
  const sessionMap = new Map();
  logs.forEach(log => {
    if (!sessionMap.has(log.session_id)) {
      sessionMap.set(log.session_id, {
        session_id: log.session_id,
        performed_at: log.performed_at,
        exercises: []
      });
    }
    sessionMap.get(log.session_id).exercises.push(log);
  });

  return Array.from(sessionMap.values()).slice(0, limit);
}
