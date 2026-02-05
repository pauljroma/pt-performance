import express from 'express';
import * as therapistService from '../services/therapist.js';
import { requireAuthenticatedUser, requireTherapistOwnership } from '../middleware/auth.js';
import { createAppError } from '../errors/api-error.js';

const router = express.Router();

router.use(requireAuthenticatedUser);
router.use('/:therapistId', requireTherapistOwnership);

function parseOptionalNumber(value, fieldName) {
    if (value === undefined || value === null || value === '') {
        return null;
    }

    const parsed = Number(value);

    if (Number.isNaN(parsed)) {
        throw createAppError('invalid_query_parameter', 400, `${fieldName} must be a valid number`);
    }

    return parsed;
}

function parseFilters(query, therapistId) {
    const allowedSeverities = new Set(['HIGH', 'MEDIUM', 'LOW']);

    if (query.flagSeverity && !allowedSeverities.has(query.flagSeverity)) {
        throw createAppError('invalid_query_parameter', 400, 'flagSeverity must be one of HIGH, MEDIUM, LOW');
    }

    if (query.hasFlags && query.hasFlags !== 'true' && query.hasFlags !== 'false') {
        throw createAppError('invalid_query_parameter', 400, 'hasFlags must be true or false');
    }

    const minAdherence = parseOptionalNumber(query.minAdherence, 'minAdherence');
    const maxAdherence = parseOptionalNumber(query.maxAdherence, 'maxAdherence');

    if (minAdherence !== null && (minAdherence < 0 || minAdherence > 100)) {
        throw createAppError('invalid_query_parameter', 400, 'minAdherence must be between 0 and 100');
    }

    if (maxAdherence !== null && (maxAdherence < 0 || maxAdherence > 100)) {
        throw createAppError('invalid_query_parameter', 400, 'maxAdherence must be between 0 and 100');
    }

    if (minAdherence !== null && maxAdherence !== null && minAdherence > maxAdherence) {
        throw createAppError('invalid_query_parameter', 400, 'minAdherence cannot be greater than maxAdherence');
    }

    return {
        therapistId,
        search: query.search || null,
        sport: query.sport || null,
        position: query.position || null,
        flagSeverity: query.flagSeverity || null,
        hasFlags: query.hasFlags === 'true' ? true : query.hasFlags === 'false' ? false : null,
        minAdherence,
        maxAdherence,
    };
}

/**
 * GET /therapist/:therapistId/patients
 * Search and filter patients for a therapist
 */
router.get('/:therapistId/patients', async (req, res, next) => {
    try {
        const { therapistId } = req.params;
        const filters = parseFilters(req.query, therapistId);
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
export { parseFilters, parseOptionalNumber };
