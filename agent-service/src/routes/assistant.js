/**
 * PT Assistant Routes
 * Endpoints for PT Assistant summaries with flag integration
 * ACP-89: PT Assistant summary endpoint
 * ACP-101: Flags integration
 */

import { generatePatientSummary } from '../services/assistant.js';
import { getPatient } from '../services/supabase.js';

// Try to import flags service (Agent 2 feature)
let getFlagSummary, createPlanChangeRequest;
try {
  const flagsModule = await import('../services/flags.js');
  getFlagSummary = flagsModule.getFlagSummary;
} catch (e) {
  console.log('⚠️  Flag service not available in assistant routes');
}

try {
  const pcrModule = await import('../services/linear-pcr.js');
  createPlanChangeRequest = pcrModule.createPlanChangeRequest;
} catch (e) {
  console.log('⚠️  Linear PCR service not available in assistant routes');
}

/**
 * Generate flag-based recommendations
 */
function generateFlagRecommendations(flags) {
  const recommendations = [];

  const highFlags = flags.filter(f => f.severity === 'HIGH');
  const mediumFlags = flags.filter(f => f.severity === 'MEDIUM');

  if (highFlags.length > 0) {
    recommendations.push({
      priority: 'URGENT',
      message: `${highFlags.length} HIGH severity flag(s) detected. Immediate intervention required.`,
      actions: [
        'Review patient status immediately',
        'Consider reducing workload or intensity',
        'Schedule PT assessment or medical evaluation',
      ],
      affected_flags: highFlags.map(f => f.flag_type),
    });
  }

  if (mediumFlags.length > 0) {
    recommendations.push({
      priority: 'MEDIUM',
      message: `${mediumFlags.length} MEDIUM severity flag(s) detected. Monitor and adjust as needed.`,
      actions: [
        'Review trends over next 2-3 sessions',
        'Consider minor adjustments to program',
        'Communicate with patient about symptoms',
      ],
      affected_flags: mediumFlags.map(f => f.flag_type),
    });
  }

  if (flags.length === 0) {
    recommendations.push({
      priority: 'LOW',
      message: 'No flags detected. Patient progressing well.',
      actions: ['Continue current program', 'Monitor for any changes'],
    });
  }

  return recommendations;
}

/**
 * Setup PT Assistant routes
 */
export function setupAssistantRoutes(app) {
  /**
   * GET /pt-assistant/summary/:patientId
   *
   * Generate comprehensive PT assistant summary with flag analysis
   * Includes pain summary, adherence, strength, velocity (if pitcher), and flags
   *
   * Response includes auto-generated recommendations based on flags
   * HIGH severity flags trigger automatic PCR creation in Linear
   */
  app.get("/pt-assistant/summary/:patientId", async (req, res) => {
    const { patientId } = req.params;

    try {
      // Generate base assistant summary
      const assistantSummary = await generatePatientSummary(patientId);

      // Add flags if available (Agent 2 feature)
      if (getFlagSummary) {
        try {
          const flagSummary = await getFlagSummary(patientId);

          assistantSummary.flags = {
            total: flagSummary.total,
            high: flagSummary.high,
            medium: flagSummary.medium,
            low: flagSummary.low,
            details: flagSummary.flags.slice(0, 5), // Top 5 flags
          };

          // Add flag-based recommendations
          assistantSummary.recommendations = generateFlagRecommendations(flagSummary.flags);

          // Auto-create PCRs for HIGH severity flags
          if (createPlanChangeRequest) {
            const highFlags = flagSummary.flags.filter(f => f.severity === 'HIGH');

            if (highFlags.length > 0) {
              console.log(`🚨 ${highFlags.length} HIGH severity flag(s) detected for patient ${patientId}`);

              const patient = await getPatient(patientId);

              for (const flag of highFlags) {
                try {
                  const pcr = await createPlanChangeRequest(flag, patient);
                  console.log(`✅ Auto-created PCR: ${pcr.identifier} - ${pcr.url}`);
                } catch (error) {
                  console.error('Error auto-creating PCR:', error);
                }
              }
            }
          }
        } catch (e) {
          console.error('Error adding flags to assistant summary:', e);
          assistantSummary.flags = {
            total: 0,
            high: 0,
            medium: 0,
            low: 0,
            details: [],
          };
        }
      }

      res.json(assistantSummary);
    } catch (err) {
      console.error('Error in /pt-assistant/summary:', err);
      res.status(500).json({
        error: "failed_to_generate_summary",
        message: err.message,
      });
    }
  });
}
