import express from 'express';
import * as therapistService from '../services/therapist.js';
import { requireAuthenticatedUser, requireTherapistOwnership } from '../middleware/auth.js';

const router = express.Router();

router.use(requireAuthenticatedUser);
router.use('/:therapistId', requireTherapistOwnership);

/**
 * GET /therapist/:therapistId/patients
 * Search and filter patients for a therapist
 */
router.get('/:therapistId/patients', async (req, res, next) => {
    try {
        const { therapistId } = req.params;
        const {
            search,
            sport,
            position,
            flagSeverity,
            hasFlags,
            minAdherence,
            maxAdherence,
        } = req.query;

        const filters = {
            therapistId,
            search: search || null,
            sport: sport || null,
            position: position || null,
            flagSeverity: flagSeverity || null,
            hasFlags: hasFlags === 'true' ? true : hasFlags === 'false' ? false : null,
            minAdherence: minAdherence ? parseFloat(minAdherence) : null,
            maxAdherence: maxAdherence ? parseFloat(maxAdherence) : null,
        };

        const patients = await therapistService.searchPatients(filters);

        res.json({
            success: true,
            count: patients.length,
            patients,
        });
    } catch (error) {
        next(error);
    }
});

/**
 * GET /therapist/:therapistId/dashboard
 * Get therapist dashboard summary
 */
router.get('/:therapistId/dashboard', async (req, res, next) => {
    try {
        const { therapistId } = req.params;

        const dashboard = await therapistService.getDashboardSummary(therapistId);

        res.json({
            success: true,
            dashboard,
        });
    } catch (error) {
        next(error);
    }
});

/**
 * GET /therapist/:therapistId/alerts
 * Get high priority patient alerts
 */
router.get('/:therapistId/alerts', async (req, res, next) => {
    try {
        const { therapistId } = req.params;

        const alerts = await therapistService.getHighPriorityAlerts(therapistId);

        res.json({
            success: true,
            count: alerts.length,
            alerts,
        });
    } catch (error) {
        next(error);
    }
});

export default router;
