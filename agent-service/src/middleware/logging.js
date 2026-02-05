/**
 * Logging Middleware
 * ACP-74: Add logging to endpoints
 *
 * Logs all endpoint requests to agent_logs table in Supabase
 * Tracks: timestamp, endpoint, patient_id, response_time, errors
 */

import fetch from "node-fetch";
import { PAYLOAD_REDACTION_POLICY } from "../config/redaction-policy.js";

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_SERVICE_KEY = process.env.SUPABASE_SERVICE_KEY;

/**
 * Write log entry to agent_logs table
 */
async function writeLog(logEntry) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    console.warn("Supabase not configured - log entry not written");
    return;
  }

  try {
    const url = `${SUPABASE_URL}/rest/v1/agent_logs`;

    const response = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "apikey": SUPABASE_SERVICE_KEY,
        "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`,
        "Prefer": "return=minimal"
      },
      body: JSON.stringify(logEntry)
    });

    if (!response.ok) {
      const errorText = await response.text();
      console.error("Failed to write log entry:", errorText);
    }
  } catch (error) {
    console.error("Error writing log entry:", error.message);
  }
}

/**
 * Extract patient ID from request
 */
function extractPatientId(req) {
  // Check URL params
  if (req.params?.patientId) {
    return req.params.patientId;
  }

  // Check query params
  if (req.query?.patientId || req.query?.patient_id) {
    return req.query.patientId || req.query.patient_id;
  }

  // Check request body
  if (req.body?.patientId || req.body?.patient_id) {
    return req.body.patientId || req.body.patient_id;
  }

  return null;
}

/**
 * Sanitize request/response bodies for logging
 * Remove sensitive data
 */
function sanitizeBody(body) {
  if (!body) return null;

  const sanitized = { ...body };

  // Remove sensitive fields using shared policy
  const { sensitiveFields, maxFieldLength, replacement } = PAYLOAD_REDACTION_POLICY;

  for (const field of sensitiveFields) {
    if (sanitized[field]) {
      sanitized[field] = replacement;
    }
  }

  // Truncate large fields
  for (const [key, value] of Object.entries(sanitized)) {
    if (typeof value === "string" && value.length > maxFieldLength) {
      sanitized[key] = value.substring(0, maxFieldLength) + "... [TRUNCATED]";
    }
  }

  return sanitized;
}

/**
 * Logging middleware
 *
 * Logs all requests to agent_logs table
 * Captures response time, status code, errors, and context
 */
export function loggingMiddleware(req, res, next) {
  const startTime = Date.now();
  req._startTime = startTime;

  // Store original res.json and res.status
  const originalJson = res.json.bind(res);
  const originalStatus = res.status.bind(res);

  let statusCode = 200;
  let responseBody = null;

  // Override res.status to capture status code
  res.status = function(code) {
    statusCode = code;
    return originalStatus(code);
  };

  // Override res.json to capture response body
  res.json = function(body) {
    responseBody = body;
    return originalJson(body);
  };

  // Log after response is sent
  res.on("finish", async () => {
    const responseTime = Date.now() - startTime;
    const patientId = extractPatientId(req);

    // Build log entry
    const logEntry = {
      endpoint: req.path,
      method: req.method,
      patient_id: patientId,
      response_time_ms: responseTime,
      status_code: statusCode,
      request_body: sanitizeBody(req.body),
      response_body: sanitizeBody(responseBody),
      created_at: new Date().toISOString()
    };

    // Add error details if response indicates error
    if (statusCode >= 400) {
      logEntry.error_message = responseBody?.error || responseBody?.message || `HTTP ${statusCode}`;

      if (responseBody?.stack) {
        logEntry.error_stack = responseBody.stack;
      }
    }

    // Write log entry asynchronously (don't block response)
    writeLog(logEntry).catch(error => {
      console.error("Failed to write log:", error);
    });
  });

  next();
}

/**
 * Error logging middleware
 *
 * Catches unhandled errors and logs them with stack traces
 */
export function errorLoggingMiddleware(err, req, res, next) {
  const responseTime = Date.now() - (req._startTime || Date.now());
  const patientId = extractPatientId(req);

  // Build log entry
  const logEntry = {
    endpoint: req.path,
    method: req.method,
    patient_id: patientId,
    response_time_ms: responseTime,
    status_code: err.statusCode || 500,
    error_message: err.message,
    error_stack: err.stack,
    request_body: sanitizeBody(req.body),
    created_at: new Date().toISOString()
  };

  // Write log entry
  writeLog(logEntry).catch(error => {
    console.error("Failed to write error log:", error);
  });

  // Pass error to next error handler
  next(err);
}

/**
 * Manual log function for custom logging
 */
export async function logEndpoint({ endpoint, method, patientId, responseTimeMs, statusCode, error, context }) {
  const logEntry = {
    endpoint,
    method: method || "GET",
    patient_id: patientId,
    response_time_ms: responseTimeMs,
    status_code: statusCode || 200,
    created_at: new Date().toISOString()
  };

  if (error) {
    logEntry.error_message = error.message || error;
    logEntry.error_stack = error.stack;
  }

  if (context) {
    logEntry.request_body = sanitizeBody(context);
  }

  await writeLog(logEntry);
}

/**
 * Get recent logs for a patient
 */
export async function getPatientLogs(patientId, limit = 50) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    throw new Error("Supabase configuration missing");
  }

  const url = `${SUPABASE_URL}/rest/v1/agent_logs?patient_id=eq.${patientId}&order=created_at.desc&limit=${limit}`;

  const response = await fetch(url, {
    headers: {
      "apikey": SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`
    }
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch logs: ${response.statusText}`);
  }

  return await response.json();
}

/**
 * Get error summary for monitoring
 */
export async function getErrorSummary(hours = 24) {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_KEY) {
    throw new Error("Supabase configuration missing");
  }

  const sinceTime = new Date(Date.now() - hours * 60 * 60 * 1000).toISOString();
  const url = `${SUPABASE_URL}/rest/v1/agent_logs?error_message=not.is.null&created_at=gte.${sinceTime}&order=created_at.desc&limit=100`;

  const response = await fetch(url, {
    headers: {
      "apikey": SUPABASE_SERVICE_KEY,
      "Authorization": `Bearer ${SUPABASE_SERVICE_KEY}`
    }
  });

  if (!response.ok) {
    throw new Error(`Failed to fetch error summary: ${response.statusText}`);
  }

  const errors = await response.json();

  // Group by endpoint
  const errorsByEndpoint = {};
  for (const error of errors) {
    if (!errorsByEndpoint[error.endpoint]) {
      errorsByEndpoint[error.endpoint] = [];
    }
    errorsByEndpoint[error.endpoint].push(error);
  }

  return {
    totalErrors: errors.length,
    errorsByEndpoint,
    recentErrors: errors.slice(0, 10)
  };
}
