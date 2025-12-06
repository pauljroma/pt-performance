import express from 'express';
import * as therapistService from '../services/therapist.js';

const router = express.Router();

/**
 * GET /therapist/:therapistId/patients
 * Search and filter patients for a therapist
 *
 * Query params:
 * - search: string (search by name or email)
 * - sport: string (filter by sport)
 * - position: string (filter by position)
 * - flagSeverity: 'HIGH' | 'MEDIUM' | 'LOW' (filter by flag severity)
 * - hasFlags: boolean (filter patients with/without flags)
 * - minAdherence: number (minimum adherence percentage)
 * - maxAdherence: number (maximum adherence percentage)
 */
router.get('/:therapistId/patients', async (req, res) => {
    try {
        const { therapistId } = req.params;
        const {
            search,
            sport,
            position,
            flagSeverity,
            hasFlags,
            minAdherence,
            maxAdherence
        } = req.query;

        const filters = {
            therapistId,
            search: search || null,
            sport: sport || null,
            position: position || null,
            flagSeverity: flagSeverity || null,
            hasFlags: hasFlags === 'true' ? true : hasFlags === 'false' ? false : null,
            minAdherence: minAdherence ? parseFloat(minAdherence) : null,
            maxAdherence: maxAdherence ? parseFloat(maxAdherence) : null
        };

        const patients = await therapistService.searchPatients(filters);

        res.json({
            success: true,
            count: patients.length,
            patients
        });
    } catch (error) {
        console.error('Error searching patients:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * GET /therapist/:therapistId/dashboard
 * Get therapist dashboard summary
 */
router.get('/:therapistId/dashboard', async (req, res) => {
    try {
        const { therapistId } = req.params;

        const dashboard = await therapistService.getDashboardSummary(therapistId);

        res.json({
            success: true,
            dashboard
        });
    } catch (error) {
        console.error('Error fetching dashboard:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

/**
 * GET /therapist/:therapistId/alerts
 * Get high priority patient alerts
 */
router.get('/:therapistId/alerts', async (req, res) => {
    try {
        const { therapistId } = req.params;

        const alerts = await therapistService.getHighPriorityAlerts(therapistId);

        res.json({
            success: true,
            count: alerts.length,
            alerts
        });
    } catch (error) {
        console.error('Error fetching alerts:', error);
        res.status(500).json({
            success: false,
            error: error.message
        });
    }
});

export default router;
