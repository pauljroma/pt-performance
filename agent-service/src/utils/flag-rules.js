/**
 * Flag Rules Engine - PT Performance Platform
 * Defines all flag types and their evaluation logic
 *
 * Flag Types:
 * 1. Pain Flags (EPIC G)
 * 2. Velocity Flags (EPIC C - pitchers)
 * 3. Command Flags (EPIC C - pitchers)
 * 4. Adherence Flags
 *
 * Severity Levels:
 * - HIGH: Requires immediate attention, auto-creates PCR
 * - MEDIUM: Needs monitoring, flag for PT review
 * - LOW: Informational
 */

/**
 * Evaluate pain-based flags
 * @param {Array} painLogs - Recent pain logs (sorted by date desc)
 * @returns {Array} - Array of flag objects
 */
export function evaluatePainFlags(painLogs) {
  const flags = [];

  if (!painLogs || painLogs.length === 0) {
    return flags;
  }

  // Most recent pain log
  const latest = painLogs[0];

  // Flag 1: Pain > 5 (immediate, HIGH severity)
  if (latest.pain_during > 5 || latest.pain_after > 5 || latest.pain_rest > 5) {
    const maxPain = Math.max(
      latest.pain_during || 0,
      latest.pain_after || 0,
      latest.pain_rest || 0
    );

    flags.push({
      flag_type: 'pain_high',
      severity: 'HIGH',
      rationale: `Pain score ${maxPain}/10 reported on ${formatDate(latest.logged_at)}. Immediate review required.`,
      triggered_at: latest.logged_at,
      metric_value: maxPain,
      metric_name: 'pain_score',
      patient_id: latest.patient_id
    });
  }

  // Flag 2: Pain 3-5 for 2+ consecutive sessions (MEDIUM severity)
  if (painLogs.length >= 2) {
    const consecutiveModerate = painLogs.slice(0, 2).every(log => {
      const maxPain = Math.max(
        log.pain_during || 0,
        log.pain_after || 0,
        log.pain_rest || 0
      );
      return maxPain >= 3 && maxPain <= 5;
    });

    if (consecutiveModerate) {
      flags.push({
        flag_type: 'pain_moderate_persistent',
        severity: 'MEDIUM',
        rationale: `Moderate pain (3-5/10) reported for 2+ consecutive sessions. Monitor for progression.`,
        triggered_at: latest.logged_at,
        metric_value: 3.5,
        metric_name: 'pain_score',
        patient_id: latest.patient_id
      });
    }
  }

  // Flag 3: Pain increasing > 2 points session-over-session (MEDIUM severity)
  if (painLogs.length >= 2) {
    const latestMax = Math.max(
      latest.pain_during || 0,
      latest.pain_after || 0,
      latest.pain_rest || 0
    );
    const previousMax = Math.max(
      painLogs[1].pain_during || 0,
      painLogs[1].pain_after || 0,
      painLogs[1].pain_rest || 0
    );

    const painIncrease = latestMax - previousMax;

    if (painIncrease > 2) {
      flags.push({
        flag_type: 'pain_sharp_increase',
        severity: 'MEDIUM',
        rationale: `Pain increased by ${painIncrease} points from ${previousMax} to ${latestMax}. Workload may need adjustment.`,
        triggered_at: latest.logged_at,
        metric_value: painIncrease,
        metric_name: 'pain_delta',
        patient_id: latest.patient_id
      });
    }
  }

  return flags;
}

/**
 * Evaluate velocity-based flags for pitchers
 * @param {Array} bullpenLogs - Recent bullpen logs (sorted by date desc)
 * @param {string} patientPosition - Patient's position (to check if pitcher)
 * @returns {Array} - Array of flag objects
 */
export function evaluateVelocityFlags(bullpenLogs, patientPosition) {
  const flags = [];

  // Only apply to pitchers
  if (!patientPosition || !patientPosition.toLowerCase().includes('pitcher')) {
    return flags;
  }

  if (!bullpenLogs || bullpenLogs.length < 2) {
    return flags;
  }

  // Calculate average velocity for recent sessions (fastball only)
  const recentSessions = bullpenLogs.slice(0, 3);
  const olderSessions = bullpenLogs.slice(3, 6);

  // Get average fastball velocity for recent vs older sessions
  const recentAvgVelo = getAverageFastballVelocity(recentSessions);
  const olderAvgVelo = getAverageFastballVelocity(olderSessions);

  if (recentAvgVelo && olderAvgVelo) {
    const velocityDrop = olderAvgVelo - recentAvgVelo;

    // Flag 1: Velocity drop > 5 mph (HIGH severity - critical)
    if (velocityDrop > 5) {
      flags.push({
        flag_type: 'velocity_critical_drop',
        severity: 'HIGH',
        rationale: `Fastball velocity dropped ${velocityDrop.toFixed(1)} mph (from ${olderAvgVelo.toFixed(1)} to ${recentAvgVelo.toFixed(1)} mph). Critical issue - plan change needed.`,
        triggered_at: bullpenLogs[0].logged_at,
        metric_value: velocityDrop,
        metric_name: 'velocity_drop_mph',
        patient_id: bullpenLogs[0].patient_id
      });
    }
    // Flag 2: Velocity drop > 3 mph in 1-2 sessions (MEDIUM severity)
    else if (velocityDrop > 3) {
      flags.push({
        flag_type: 'velocity_moderate_drop',
        severity: 'MEDIUM',
        rationale: `Fastball velocity dropped ${velocityDrop.toFixed(1)} mph (from ${olderAvgVelo.toFixed(1)} to ${recentAvgVelo.toFixed(1)} mph). Monitor workload and fatigue.`,
        triggered_at: bullpenLogs[0].logged_at,
        metric_value: velocityDrop,
        metric_name: 'velocity_drop_mph',
        patient_id: bullpenLogs[0].patient_id
      });
    }
  }

  return flags;
}

/**
 * Evaluate command (hit-spot %) flags for pitchers
 * @param {Array} bullpenLogs - Recent bullpen logs (sorted by date desc)
 * @param {string} patientPosition - Patient's position (to check if pitcher)
 * @returns {Array} - Array of flag objects
 */
export function evaluateCommandFlags(bullpenLogs, patientPosition) {
  const flags = [];

  // Only apply to pitchers
  if (!patientPosition || !patientPosition.toLowerCase().includes('pitcher')) {
    return flags;
  }

  if (!bullpenLogs || bullpenLogs.length < 3) {
    return flags;
  }

  // Get last 3 sessions with command data
  const sessionsWithCommand = bullpenLogs
    .filter(log => log.hit_spot_pct !== null && log.hit_spot_pct !== undefined)
    .slice(0, 6);

  if (sessionsWithCommand.length < 6) {
    return flags;
  }

  const recentCommand = sessionsWithCommand.slice(0, 3);
  const olderCommand = sessionsWithCommand.slice(3, 6);

  const recentAvg = average(recentCommand.map(log => log.hit_spot_pct));
  const olderAvg = average(olderCommand.map(log => log.hit_spot_pct));

  const commandDecline = olderAvg - recentAvg;

  // Flag: Hit-spot% decline > 20% over 3 sessions (MEDIUM severity)
  if (commandDecline > 20) {
    flags.push({
      flag_type: 'command_decline',
      severity: 'MEDIUM',
      rationale: `Hit-spot percentage declined by ${commandDecline.toFixed(1)}% (from ${olderAvg.toFixed(1)}% to ${recentAvg.toFixed(1)}%). Command issues detected.`,
      triggered_at: bullpenLogs[0].logged_at,
      metric_value: commandDecline,
      metric_name: 'command_pct_decline',
      patient_id: bullpenLogs[0].patient_id
    });
  }

  return flags;
}

/**
 * Evaluate adherence flags
 * @param {number} adherencePct - 7-day adherence percentage
 * @param {string} patientId - Patient ID
 * @returns {Array} - Array of flag objects
 */
export function evaluateAdherenceFlags(adherencePct, patientId) {
  const flags = [];

  if (adherencePct === null || adherencePct === undefined) {
    return flags;
  }

  // Flag: Adherence < 60% over 7 days (MEDIUM severity)
  if (adherencePct < 60) {
    flags.push({
      flag_type: 'adherence_low',
      severity: 'MEDIUM',
      rationale: `Adherence at ${adherencePct.toFixed(1)}% over past 7 days. Below 60% threshold. Patient may need check-in.`,
      triggered_at: new Date().toISOString(),
      metric_value: adherencePct,
      metric_name: 'adherence_pct',
      patient_id: patientId
    });
  }

  return flags;
}

/**
 * Evaluate throwing-specific pain flags
 * @param {Array} bullpenLogs - Recent bullpen logs with pain scores
 * @param {string} patientPosition - Patient's position
 * @returns {Array} - Array of flag objects
 */
export function evaluateThrowingPainFlags(bullpenLogs, patientPosition) {
  const flags = [];

  // Only apply to pitchers
  if (!patientPosition || !patientPosition.toLowerCase().includes('pitcher')) {
    return flags;
  }

  if (!bullpenLogs || bullpenLogs.length === 0) {
    return flags;
  }

  const latest = bullpenLogs[0];

  // Flag 1: Bullpen pain > 6 (HIGH severity)
  if (latest.pain_score && latest.pain_score > 6) {
    flags.push({
      flag_type: 'throwing_pain_high',
      severity: 'HIGH',
      rationale: `Throwing pain ${latest.pain_score}/10 during bullpen session. Immediate assessment needed. Pitch type: ${latest.pitch_type || 'N/A'}, Velocity: ${latest.velocity || 'N/A'} mph.`,
      triggered_at: latest.logged_at,
      metric_value: latest.pain_score,
      metric_name: 'throwing_pain',
      patient_id: latest.patient_id,
      context: {
        pitch_type: latest.pitch_type,
        velocity: latest.velocity,
        pitch_count: latest.pitch_count
      }
    });
  }
  // Flag 2: Bullpen pain > 4 for 2+ sessions (MEDIUM severity)
  else if (latest.pain_score && latest.pain_score > 4) {
    if (bullpenLogs.length >= 2) {
      const consecutive = bullpenLogs.slice(0, 2).every(log => log.pain_score > 4);

      if (consecutive) {
        flags.push({
          flag_type: 'throwing_pain_persistent',
          severity: 'MEDIUM',
          rationale: `Throwing pain > 4/10 for 2+ consecutive sessions. Consider intensity reduction.`,
          triggered_at: latest.logged_at,
          metric_value: latest.pain_score,
          metric_name: 'throwing_pain',
          patient_id: latest.patient_id
        });
      }
    }
  }

  return flags;
}

// ==================== HELPER FUNCTIONS ====================

/**
 * Get average fastball velocity from bullpen logs
 */
function getAverageFastballVelocity(logs) {
  const fastballLogs = logs.filter(log => {
    const pitchType = (log.pitch_type || '').toLowerCase();
    return pitchType.includes('fb') ||
           pitchType.includes('fastball') ||
           pitchType.includes('4-seam') ||
           pitchType.includes('2-seam');
  });

  if (fastballLogs.length === 0) {
    // If no specific fastball logs, use avg_velocity or velocity field
    const velocities = logs
      .map(log => log.avg_velocity || log.velocity)
      .filter(v => v !== null && v !== undefined);

    return velocities.length > 0 ? average(velocities) : null;
  }

  const velocities = fastballLogs
    .map(log => log.avg_velocity || log.velocity)
    .filter(v => v !== null && v !== undefined);

  return velocities.length > 0 ? average(velocities) : null;
}

/**
 * Calculate average of an array of numbers
 */
function average(numbers) {
  if (!numbers || numbers.length === 0) return null;
  const sum = numbers.reduce((acc, val) => acc + val, 0);
  return sum / numbers.length;
}

/**
 * Format date for display
 */
function formatDate(dateString) {
  if (!dateString) return 'Unknown date';
  const date = new Date(dateString);
  return date.toISOString().split('T')[0];
}
