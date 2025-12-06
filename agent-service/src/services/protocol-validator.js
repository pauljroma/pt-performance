/**
 * Protocol Validator Service
 * ACP-81: Add protocol validation before suggestions
 *
 * Validates PT assistant suggestions against protocol constraints
 * Prevents unsafe recommendations that violate clinical safety rules
 */

import fetch from "node-fetch";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

/**
 * Query protocol constraints for a patient's current program
 */
async function getProtocolConstraints(patientId) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    throw new Error("Supabase configuration missing");
  }

  // Get patient's active program and current phase
  const programQuery = `
    SELECT
      pr.id as program_id,
      pr.name as program_name,
      ph.id as phase_id,
      ph.name as phase_name,
      ph.sequence as phase_sequence,
      ppl.protocol_template_id
    FROM programs pr
    JOIN phases ph ON ph.program_id = pr.id
    LEFT JOIN program_protocol_links ppl ON ppl.program_id = pr.id
    WHERE pr.patient_id = '${patientId}'
      AND pr.status = 'active'
    ORDER BY ph.sequence DESC
    LIMIT 1
  `;

  const programResponse = await fetch(
    `${SUPABASE_URL}/rest/v1/rpc/execute_sql`,
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`
      },
      body: JSON.stringify({ query: programQuery })
    }
  );

  if (!programResponse.ok) {
    // Fallback: query using REST API
    const programUrl = `${SUPABASE_URL}/rest/v1/programs?patient_id=eq.${patientId}&status=eq.active&select=id,name,phases(id,name,sequence)&order=phases.sequence.desc&limit=1`;

    const fallbackResponse = await fetch(programUrl, {
      headers: {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`
      }
    });

    const programs = await fallbackResponse.json();

    if (!programs || programs.length === 0) {
      return {
        hasProtocol: false,
        constraints: []
      };
    }

    const program = programs[0];
    const phase = program.phases && program.phases.length > 0 ? program.phases[0] : null;

    if (!phase) {
      return {
        hasProtocol: false,
        constraints: []
      };
    }

    // Get protocol constraints for this phase
    const constraintsUrl = `${SUPABASE_URL}/rest/v1/protocol_constraints?protocol_phase_id=eq.${phase.id}&is_active=eq.true&select=*`;

    const constraintsResponse = await fetch(constraintsUrl, {
      headers: {
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`
      }
    });

    const constraints = await constraintsResponse.json();

    return {
      hasProtocol: true,
      programId: program.id,
      programName: program.name,
      phaseId: phase.id,
      phaseName: phase.name,
      constraints: constraints || []
    };
  }

  const programData = await programResponse.json();

  if (!programData || programData.length === 0) {
    return {
      hasProtocol: false,
      constraints: []
    };
  }

  const program = programData[0];

  if (!program.protocol_template_id) {
    return {
      hasProtocol: false,
      programId: program.program_id,
      programName: program.program_name,
      constraints: []
    };
  }

  // Get protocol constraints
  const constraintsUrl = `${SUPABASE_URL}/rest/v1/protocol_constraints?protocol_phase_id=eq.${program.phase_id}&is_active=eq.true&select=*`;

  const constraintsResponse = await fetch(constraintsUrl, {
    headers: {
      "apikey": SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`
    }
  });

  const constraints = await constraintsResponse.json();

  return {
    hasProtocol: true,
    programId: program.program_id,
    programName: program.program_name,
    phaseId: program.phase_id,
    phaseName: program.phase_name,
    constraints: constraints || []
  };
}

/**
 * Validate a suggestion against protocol constraints
 *
 * @param {Object} suggestion - Suggestion to validate
 * @param {string} suggestion.type - Type of suggestion (e.g., "increase_load", "increase_velocity")
 * @param {number} suggestion.value - Suggested value
 * @param {Object} context - Current patient context
 * @param {Array} constraints - Protocol constraints
 * @returns {Object} Validation result
 */
function validateSuggestion(suggestion, context, constraints) {
  const violations = [];

  for (const constraint of constraints) {
    const violation = checkConstraint(constraint, suggestion, context);
    if (violation) {
      violations.push(violation);
    }
  }

  const criticalViolations = violations.filter(v => v.severity === "critical");
  const errorViolations = violations.filter(v => v.severity === "error");

  return {
    isValid: criticalViolations.length === 0 && errorViolations.length === 0,
    isSafe: criticalViolations.length === 0,
    violations,
    criticalViolations,
    errorViolations,
    warningViolations: violations.filter(v => v.severity === "warning")
  };
}

/**
 * Check a single constraint against a suggestion
 */
function checkConstraint(constraint, suggestion, context) {
  const { constraint_type, constraint_value, constraint_value_text, violation_severity, rationale } = constraint;

  // Pain threshold constraint
  if (constraint_type === "pain_threshold") {
    if (context.currentPain > constraint_value) {
      return {
        constraintType: constraint_type,
        severity: violation_severity,
        message: `Current pain (${context.currentPain}/10) exceeds threshold (${constraint_value}/10)`,
        rationale,
        constraint
      };
    }
  }

  // Max velocity constraint
  if (constraint_type === "max_velocity_mph" && suggestion.type === "increase_velocity") {
    if (suggestion.value > constraint_value) {
      return {
        constraintType: constraint_type,
        severity: violation_severity,
        message: `Suggested velocity (${suggestion.value} mph) exceeds protocol max (${constraint_value} mph)`,
        rationale,
        constraint
      };
    }
  }

  // Max load constraint
  if (constraint_type === "max_load_pct" && suggestion.type === "increase_load") {
    if (suggestion.value > constraint_value) {
      return {
        constraintType: constraint_type,
        severity: violation_severity,
        message: `Suggested load (${suggestion.value}% 1RM) exceeds protocol max (${constraint_value}% 1RM)`,
        rationale,
        constraint
      };
    }
  }

  // No overhead exercises constraint
  if (constraint_type === "no_overhead_exercises" && suggestion.type === "add_overhead_exercise") {
    if (constraint_value_text === "true") {
      return {
        constraintType: constraint_type,
        severity: violation_severity,
        message: "Overhead exercises not allowed in current phase",
        rationale,
        constraint
      };
    }
  }

  // Bilateral only constraint
  if (constraint_type === "bilateral_only" && suggestion.type === "add_unilateral_exercise") {
    if (constraint_value_text === "true") {
      return {
        constraintType: constraint_type,
        severity: violation_severity,
        message: "Only bilateral exercises allowed in current phase",
        rationale,
        constraint
      };
    }
  }

  // Max pitch count constraint
  if (constraint_type === "max_pitch_count" && suggestion.type === "increase_pitch_count") {
    if (suggestion.value > constraint_value) {
      return {
        constraintType: constraint_type,
        severity: violation_severity,
        message: `Suggested pitch count (${suggestion.value}) exceeds protocol max (${constraint_value})`,
        rationale,
        constraint
      };
    }
  }

  return null;
}

/**
 * Validate PT assistant recommendation against protocol
 */
export async function validateRecommendation(patientId, recommendation) {
  try {
    // Get protocol constraints
    const protocolData = await getProtocolConstraints(patientId);

    if (!protocolData.hasProtocol) {
      // No protocol constraints - allow recommendation but flag as unvalidated
      return {
        isValid: true,
        isSafe: true,
        hasProtocol: false,
        violations: [],
        message: "No protocol constraints found - recommendation unvalidated"
      };
    }

    // Extract suggestion from recommendation
    const suggestion = {
      type: recommendation.type,
      value: recommendation.value
    };

    // Get current patient context (pain, etc.)
    const context = {
      currentPain: recommendation.context?.currentPain || 0,
      currentVelocity: recommendation.context?.currentVelocity || 0,
      currentLoad: recommendation.context?.currentLoad || 0
    };

    // Validate suggestion
    const validation = validateSuggestion(suggestion, context, protocolData.constraints);

    return {
      ...validation,
      hasProtocol: true,
      programName: protocolData.programName,
      phaseName: protocolData.phaseName,
      constraintCount: protocolData.constraints.length
    };

  } catch (error) {
    console.error("Protocol validation error:", error);

    // On error, fail safe - reject recommendation
    return {
      isValid: false,
      isSafe: false,
      error: true,
      errorMessage: error.message,
      violations: [{
        severity: "critical",
        message: "Protocol validation failed - cannot verify safety",
        rationale: "System error during validation"
      }]
    };
  }
}

/**
 * Check if recommendation is safe (no critical violations)
 */
export async function isRecommendationSafe(patientId, recommendation) {
  const validation = await validateRecommendation(patientId, recommendation);
  return validation.isSafe;
}

/**
 * Get protocol summary for patient
 */
export async function getProtocolSummary(patientId) {
  try {
    const protocolData = await getProtocolConstraints(patientId);

    if (!protocolData.hasProtocol) {
      return {
        hasProtocol: false,
        message: "No protocol template assigned to patient program"
      };
    }

    return {
      hasProtocol: true,
      programName: protocolData.programName,
      phaseName: protocolData.phaseName,
      constraintCount: protocolData.constraints.length,
      constraints: protocolData.constraints.map(c => ({
        type: c.constraint_type,
        value: c.constraint_value,
        severity: c.violation_severity,
        rationale: c.rationale
      }))
    };

  } catch (error) {
    console.error("Protocol summary error:", error);
    return {
      hasProtocol: false,
      error: true,
      errorMessage: error.message
    };
  }
}
