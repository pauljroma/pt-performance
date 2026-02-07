import express from "express";
import fetch from "node-fetch";
import rateLimit from 'express-rate-limit';
import { config } from './config.js';
import {
  getPatient,
  getActiveProgram,
  getPainLogs,
  getRecentExerciseLogs,
  getBullpenLogs,
  getTodaySession,
} from './services/supabase.js';
import { getStrengthTargets } from './services/strength.js';
import { generatePatientSummary } from './services/assistant.js';
import therapistRoutes from './routes/therapist.js';
import { setupPCRRoutes } from './routes/pcr.js';
import { loggingMiddleware, errorLoggingMiddleware } from './middleware/logging.js';
import { validateRecommendation, getProtocolSummary } from './services/protocol-validator.js';
import { createAppError, sendApiError, globalErrorMiddleware } from './errors/api-error.js';

// Try to import flags service if Agent 2 has created it
let computeFlags, getTopFlags, getFlagSummary, createPlanChangeRequest;
try {
  const flagsModule = await import('./services/flags.js');
  computeFlags = flagsModule.computeFlags;
  getTopFlags = flagsModule.getTopFlags;
  getFlagSummary = flagsModule.getFlagSummary;
} catch (e) {
  console.log('⚠️  Flag service not available yet (will be added by Agent 2)');
}

try {
  const pcrModule = await import('./services/linear-pcr.js');
  createPlanChangeRequest = pcrModule.createPlanChangeRequest;
} catch (e) {
  console.log('⚠️  Linear PCR service not available yet (will be added by Agent 2)');
}

// Default rate limiter: 100 requests per 15 minutes per IP
const defaultLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { error: 'Too many requests, please try again later' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Strict limiter for expensive LLM operations: 10 per minute
const llmLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 10,
  message: { error: 'Rate limit exceeded for AI operations' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Very strict for issue creation: 5 per minute
const pcrLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 5,
  message: { error: 'Rate limit exceeded for plan change requests' },
  standardHeaders: true,
  legacyHeaders: false,
});

const app = express();
app.use(express.json());
app.use(loggingMiddleware);

// Apply rate limiters to specific endpoints
app.use('/pt-assistant', llmLimiter);
app.use('/plan-change-request', pcrLimiter);
app.use('/flags', defaultLimiter);
app.use('/patient-summary', defaultLimiter);
app.use('/protocol', defaultLimiter);

// Register therapist routes (ACP-68, ACP-96-99)
app.use('/therapist', therapistRoutes);

const SUPABASE_URL = config.supabase.url;
const SUPABASE_SERVICE_KEY = config.supabase.serviceKey;
const LINEAR_API_KEY = config.linear.apiKey;

// ============================================================================
// HEALTH ENDPOINT (ACP-87)
// ============================================================================
app.get("/health", (req, res) => {
  res.json({
    status: "ok",
    service: "pt-agent-service",
    version: "0.1.0",
    timestamp: new Date().toISOString(),
  });
});

// ============================================================================
// PATIENT SUMMARY ENDPOINT (ACP-88)
// Returns patient profile, recent logs, pain trend, bullpen metrics
// ============================================================================
app.get("/patient-summary/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const [patient, program, painLogs, exerciseLogs, bullpenLogs] = await Promise.all([
      getPatient(patientId),
      getActiveProgram(patientId),
      getPainLogs(patientId, 7),
      getRecentExerciseLogs(patientId, 7),
      getBullpenLogs(patientId, 14),
    ]);

    // Calculate pain trend
    const painTrend = painLogs.map(log => ({
      date: log.logged_at,
      pain_rest: log.pain_rest,
      pain_during: log.pain_during,
      pain_after: log.pain_after,
    }));

    // Group exercise logs by session
    const sessionMap = new Map();
    exerciseLogs.forEach(log => {
      const sessionId = log.session_id;
      if (!sessionMap.has(sessionId)) {
        sessionMap.set(sessionId, []);
      }
      sessionMap.get(sessionId).push(log);
    });

    const recentSessions = Array.from(sessionMap.entries()).map(([sessionId, logs]) => ({
      session_id: sessionId,
      performed_at: logs[0]?.performed_at,
      exercise_count: logs.length,
      exercises: logs.map(log => ({
        exercise: log.session_exercise?.exercise_template?.name,
        sets: 1,
        reps: log.actual_reps,
        load: log.actual_load,
        rpe: log.rpe,
        pain_score: log.pain_score,
      })),
    }));

    // Get flags if available (Agent 2 feature)
    let flagData = null;
    if (getFlagSummary) {
      try {
        const flagSummary = await getFlagSummary(patientId);
        const topFlags = flagSummary.flags.slice(0, 3);

        // Auto-create PCRs for HIGH severity flags
        if (createPlanChangeRequest) {
          const highFlags = flagSummary.flags.filter(f => f.severity === 'HIGH');
          for (const flag of highFlags) {
            try {
              await createPlanChangeRequest(flag, patient);
            } catch (error) {
              console.error('Error auto-creating PCR:', error);
            }
          }
        }

        flagData = {
          total: flagSummary.total,
          high: flagSummary.high,
          medium: flagSummary.medium,
          low: flagSummary.low,
          top_flags: topFlags
        };
      } catch (e) {
        console.error('Error fetching flags:', e);
      }
    }

    const response = {
      patient: {
        id: patient.id,
        name: `${patient.first_name} ${patient.last_name}`,
        sport: patient.sport,
        position: patient.position,
        email: patient.email,
      },
      program: program ? {
        id: program.id,
        name: program.name,
        status: program.status,
        start_date: program.start_date,
      } : null,
      recentSessions,
      painTrend,
      bullpenMetrics: bullpenLogs.slice(0, 5).map(log => ({
        date: log.logged_at,
        velocity: log.velocity,
        pitch_type: log.pitch_type,
        command_rating: log.command_rating,
        pain_score: log.pain_score,
      })),
    };

    if (flagData) {
      response.flags = flagData;
    }

    res.json(response);
  } catch (err) {
    console.error('Error in /patient-summary:', err);
    return sendApiError(res, createAppError('failed_to_fetch_patient_summary', 500, err.message));
  }
});

// ============================================================================
// TODAY'S SESSION ENDPOINT (ACP-88)
// Returns exercises prescribed for today's session
// ============================================================================
app.get("/today-session/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const sessionData = await getTodaySession(patientId);

    res.json({
      patient_id: patientId,
      program: sessionData.program ? {
        id: sessionData.program.id,
        name: sessionData.program.name,
      } : null,
      phase: sessionData.phase ? {
        id: sessionData.phase.id,
        name: sessionData.phase.name,
        sequence: sessionData.phase.sequence,
      } : null,
      session: sessionData.session ? {
        id: sessionData.session.id,
        name: sessionData.session.name,
        sequence: sessionData.session.sequence,
        weekday: sessionData.session.weekday,
      } : null,
      exercises: sessionData.exercises.map(se => ({
        id: se.id,
        exercise: {
          id: se.exercise_template.id,
          name: se.exercise_template.name,
          category: se.exercise_template.category,
          body_region: se.exercise_template.body_region,
        },
        prescription: {
          sets: se.target_sets,
          reps: se.target_reps,
          load: se.target_load,
          rpe: se.target_rpe,
          tempo: se.tempo,
        },
        notes: se.notes,
        sequence: se.sequence,
      })),
    });
  } catch (err) {
    console.error('Error in /today-session:', err);
    return sendApiError(res, createAppError('failed_to_fetch_today_session', 500, err.message));
  }
});

// ============================================================================
// PT ASSISTANT SUMMARY ENDPOINT (ACP-89)
// Generates intelligent summary with pain, adherence, strength, velocity
// ============================================================================
app.get("/pt-assistant/summary/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const summary = await generatePatientSummary(patientId);

    // Add flags if available (Agent 2 feature)
    if (getFlagSummary) {
      try {
        const flagSummary = await getFlagSummary(patientId);

        summary.flags = {
          total: flagSummary.total,
          high: flagSummary.high,
          medium: flagSummary.medium,
          low: flagSummary.low,
          details: flagSummary.flags.slice(0, 5), // Top 5 flags
        };

        // Add flag-based recommendations
        summary.recommendations = generateFlagRecommendations(flagSummary.flags);

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
      }
    }

    res.json(summary);
  } catch (err) {
    console.error('Error in /pt-assistant/summary:', err);
    return sendApiError(res, createAppError('failed_to_generate_summary', 500, err.message));
  }
});

// ============================================================================
// FLAGS ENDPOINTS (ACP-100, ACP-101)
// Risk engine and flag computation
// ============================================================================
app.get("/flags/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    if (!computeFlags) {
      return sendApiError(res, createAppError('flag_service_unavailable', 501, 'Flag service not available yet', { note: 'Agent 2 flag computation service not yet deployed' }));
    }

    const flags = await computeFlags(patientId);

    res.json({
      patient_id: patientId,
      flags,
      count: flags.length,
      generated_at: new Date().toISOString(),
    });
  } catch (err) {
    console.error('Error in /flags:', err);
    return sendApiError(res, createAppError('failed_to_compute_flags', 500, err.message));
  }
});

// ============================================================================
// STRENGTH TARGETS ENDPOINT (ACP-60)
// Returns 1RM estimates and progressive targets
// ============================================================================
app.get("/strength-targets/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const targets = await getStrengthTargets(patientId);
    res.json(targets);
  } catch (err) {
    console.error('Error in /strength-targets:', err);
    return sendApiError(res, createAppError('failed_to_calculate_strength_targets', 500, err.message));
  }
});

// ============================================================================
// PROTOCOL VALIDATION ENDPOINTS (ACP-81)
// Validate recommendation safety and summarize risk profile
// ============================================================================
app.post('/protocol/validate', async (req, res) => {
  const { patientId, recommendation } = req.body;

  try {
    if (!patientId || !recommendation) {
      return sendApiError(res, createAppError('patient_id_and_recommendation_required', 400, 'patientId and recommendation are required'));
    }

    const validation = await validateRecommendation(patientId, recommendation);
    res.json({ success: true, validation });
  } catch (err) {
    console.error('Error in /protocol/validate:', err);
    return sendApiError(res, createAppError('validation_failed', 500, err.message));
  }
});

app.get('/protocol/summary/:patientId', async (req, res) => {
  const { patientId } = req.params;

  try {
    const summary = await getProtocolSummary(patientId);
    res.json({ success: true, summary });
  } catch (err) {
    console.error('Error in /protocol/summary:', err);
    return sendApiError(res, createAppError('failed_to_fetch_protocol_summary', 500, err.message));
  }
});

// Additional PCR route(s) for PT assistant workflow (ACP-90)
setupPCRRoutes(app);

// ============================================================================
// PLAN CHANGE REQUEST ENDPOINT (kept for compatibility)
// Will be enhanced by Agent 2
// ============================================================================
app.post("/plan-change-request", async (req, res) => {
  const { patientId, summary, reason, impact } = req.body;

  try {
    const issue = await createLinearPlanChangeIssue({ patientId, summary, reason, impact });
    res.json({ issue });
  } catch (err) {
    console.error(err);
    return sendApiError(res, createAppError('failed_to_create_issue', 500, err.message));
  }
});

// ============================================================================
// HELPER FUNCTIONS
// ============================================================================

/**
 * Generate flag-based recommendations
 * Used by PT assistant summary endpoint
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

async function createLinearPlanChangeIssue({ patientId, summary, reason, impact }) {
  const query = `
    mutation CreateIssue($input: IssueCreateInput!) {
      issueCreate(input: $input) {
        success
        issue {
          id
          identifier
          url
        }
      }
    }
  `;

  const input = {
    title: `Plan Change for Patient ${patientId}: ${summary}`,
    teamId: config.linear.teamId,
    description: `Reason/context:\n${reason}\n\nImpact: ${impact}`,
    labelIds: [],
  };

  const resp = await fetch("https://api.linear.app/graphql", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "Authorization": LINEAR_API_KEY
    },
    body: JSON.stringify({ query, variables: { input } })
  });

  const json = await resp.json();
  if (!json.data?.issueCreate?.success) {
    throw new Error("Linear issueCreate failed: " + JSON.stringify(json));
  }

  return json.data.issueCreate.issue;
}

app.use(errorLoggingMiddleware);

app.use(globalErrorMiddleware);

// ============================================================================
// START SERVER
// ============================================================================
const port = config.port;
app.listen(port, () => {
  console.log('='.repeat(60));
  console.log('PT AGENT SERVICE - STARTED');
  console.log('='.repeat(60));
  console.log(`Port: ${port}`);
  console.log(`Environment: ${config.nodeEnv}`);
  console.log('');
  console.log('Endpoints:');
  console.log(`  GET  /health`);
  console.log(`  GET  /patient-summary/:patientId`);
  console.log(`  GET  /today-session/:patientId`);
  console.log(`  GET  /pt-assistant/summary/:patientId`);
  console.log(`  GET  /flags/:patientId`);
  console.log(`  GET  /strength-targets/:patientId`);
  console.log(`  POST /protocol/validate`);
  console.log(`  GET  /protocol/summary/:patientId`);
  console.log(`  POST /plan-change-request`);
  console.log(`  POST /pt-assistant/plan-change-proposal/:patientId`);
  console.log('');
  console.log('Therapist Endpoints:');
  console.log(`  GET  /therapist/:therapistId/patients`);
  console.log(`  GET  /therapist/:therapistId/dashboard`);
  console.log(`  GET  /therapist/:therapistId/alerts`);
  console.log('='.repeat(60));
});
