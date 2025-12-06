/**
 * Flags Routes
 * Endpoints for risk engine and flag computation
 * ACP-100: Flag computation logic
 * ACP-101: Flag endpoint integration
 */

import { computeFlags, getTopFlags, getFlagSummary } from '../services/flags.js';

/**
 * Setup Flags routes
 */
export function setupFlagsRoutes(app) {
  /**
   * GET /flags/:patientId
   *
   * Compute all flags for a patient
   * Returns comprehensive flag analysis including:
   * - Pain flags
   * - Velocity flags (for pitchers)
   * - Command flags (for pitchers)
   * - Adherence flags
   * - Throwing pain flags (for pitchers)
   *
   * Response:
   * {
   *   "patient_id": "uuid",
   *   "flags": [...],
   *   "count": 3,
   *   "generated_at": "ISO datetime"
   * }
   */
  app.get("/flags/:patientId", async (req, res) => {
    const { patientId } = req.params;

    try {
      const flags = await computeFlags(patientId);

      res.json({
        patient_id: patientId,
        flags,
        count: flags.length,
        generated_at: new Date().toISOString(),
      });
    } catch (err) {
      console.error('Error in /flags:', err);
      res.status(500).json({
        error: "failed_to_compute_flags",
        message: err.message,
      });
    }
  });

  /**
   * GET /flags/:patientId/summary
   *
   * Get flag summary with counts by severity
   *
   * Response:
   * {
   *   "patient_id": "uuid",
   *   "total": 5,
   *   "high": 1,
   *   "medium": 3,
   *   "low": 1,
   *   "flags": [...]
   * }
   */
  app.get("/flags/:patientId/summary", async (req, res) => {
    const { patientId } = req.params;

    try {
      const summary = await getFlagSummary(patientId);

      res.json({
        patient_id: patientId,
        ...summary,
        generated_at: new Date().toISOString(),
      });
    } catch (err) {
      console.error('Error in /flags/summary:', err);
      res.status(500).json({
        error: "failed_to_compute_flag_summary",
        message: err.message,
      });
    }
  });

  /**
   * GET /flags/:patientId/top
   *
   * Get top N highest severity flags
   *
   * Query params:
   * - limit (default: 3): Number of flags to return
   *
   * Response:
   * {
   *   "patient_id": "uuid",
   *   "top_flags": [...],
   *   "count": 3
   * }
   */
  app.get("/flags/:patientId/top", async (req, res) => {
    const { patientId } = req.params;
    const limit = parseInt(req.query.limit) || 3;

    try {
      const topFlags = await getTopFlags(patientId, limit);

      res.json({
        patient_id: patientId,
        top_flags: topFlags,
        count: topFlags.length,
        generated_at: new Date().toISOString(),
      });
    } catch (err) {
      console.error('Error in /flags/top:', err);
      res.status(500).json({
        error: "failed_to_get_top_flags",
        message: err.message,
      });
    }
  });
}
