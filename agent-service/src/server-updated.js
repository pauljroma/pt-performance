/**
 * PT Agent Backend Service
 * Phase 2: Backend Intelligence
 *
 * Integrates:
 * - PCR endpoint (ACP-90)
 * - Protocol validation (ACP-81)
 * - Logging middleware (ACP-74)
 */

import express from "express";
import fetch from "node-fetch";
import { setupPCRRoutes } from "./routes/pcr.js";
import { loggingMiddleware, errorLoggingMiddleware } from "./middleware/logging.js";
import { validateRecommendation, getProtocolSummary } from "./services/protocol-validator.js";

const app = express();
app.use(express.json());

// Apply logging middleware to all routes
app.use(loggingMiddleware);

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;
const LINEAR_API_KEY = process.env.LINEAR_API_KEY;

// ============================================================================
// HEALTH CHECK
// ============================================================================

app.get("/health", (req, res) => {
  res.json({ status: "ok", timestamp: new Date().toISOString() });
});

// ============================================================================
// PATIENT SUMMARY ENDPOINT
// ============================================================================

app.get("/patient-summary/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const { patient, recentSessions, painTrend } = await getPatientSummary(patientId);
    res.json({ patient, recentSessions, painTrend });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "failed_to_fetch_patient_summary", message: err.message });
  }
});

async function getPatientSummary(patientId) {
  // Skeleton implementation
  return {
    patient: { id: patientId },
    recentSessions: [],
    painTrend: []
  };
}

// ============================================================================
// TODAY'S SESSION ENDPOINT
// ============================================================================

app.get("/today-session/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const session = await getTodaySession(patientId);
    res.json({ session });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: "failed_to_fetch_session", message: err.message });
  }
});

async function getTodaySession(patientId) {
  // Skeleton implementation
  return {
    id: "session-today",
    patientId,
    exercises: []
  };
}

// ============================================================================
// PROTOCOL VALIDATION ENDPOINT
// ============================================================================

app.post("/protocol/validate", async (req, res) => {
  const { patientId, recommendation } = req.body;

  try {
    if (!patientId || !recommendation) {
      return res.status(400).json({
        error: "patient_id_and_recommendation_required"
      });
    }

    const validation = await validateRecommendation(patientId, recommendation);

    res.json({
      success: true,
      validation
    });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: "validation_failed",
      message: err.message
    });
  }
});

app.get("/protocol/summary/:patientId", async (req, res) => {
  const { patientId } = req.params;

  try {
    const summary = await getProtocolSummary(patientId);
    res.json({ success: true, summary });
  } catch (err) {
    console.error(err);
    res.status(500).json({
      error: "failed_to_fetch_protocol_summary",
      message: err.message
    });
  }
});

// ============================================================================
// PCR ROUTES (ACP-90)
// ============================================================================

setupPCRRoutes(app);

// ============================================================================
// ERROR HANDLING MIDDLEWARE
// ============================================================================

app.use(errorLoggingMiddleware);

app.use((err, req, res, next) => {
  console.error("Unhandled error:", err);
  res.status(err.statusCode || 500).json({
    error: "internal_server_error",
    message: err.message
  });
});

// ============================================================================
// START SERVER
// ============================================================================

const port = process.env.PORT || 4000;
app.listen(port, () => {
  console.log(`PT agent service listening on port ${port}`);
  console.log(`Environment: ${process.env.NODE_ENV || "development"}`);
  console.log(`Supabase configured: ${!!SUPABASE_URL}`);
  console.log(`Linear configured: ${!!LINEAR_API_KEY}`);
});
