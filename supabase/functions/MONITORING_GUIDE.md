# Edge Functions Monitoring & Observability Guide

**BUILD 138 - Production Monitoring**
**Date:** 2026-01-04
**Version:** 1.0

---

## Table of Contents

1. [Overview](#overview)
2. [Monitoring Dashboard](#monitoring-dashboard)
3. [Log Viewing](#log-viewing)
4. [Key Metrics](#key-metrics)
5. [Alert Configuration](#alert-configuration)
6. [Debugging Failed Requests](#debugging-failed-requests)
7. [Performance Monitoring](#performance-monitoring)
8. [Cost Monitoring](#cost-monitoring)
9. [SQL Monitoring Queries](#sql-monitoring-queries)
10. [Troubleshooting Playbook](#troubleshooting-playbook)

---

## Overview

This guide covers monitoring and observability for the 5 Edge Functions deployed in BUILD 138:

1. **generate-equipment-substitution** - AI-powered exercise substitution
2. **apply-substitution** - Apply substitutions to create workout instances
3. **sync-whoop-recovery** - Sync WHOOP recovery data
4. **ai-nutrition-recommendation** - AI-powered nutrition recommendations
5. **ai-meal-parser** - Parse meal descriptions into macro data

### Monitoring Objectives

- **Availability:** Ensure functions are responding (99.9% uptime target)
- **Performance:** Track response times and identify bottlenecks
- **Errors:** Detect and diagnose failures quickly
- **Costs:** Monitor OpenAI API usage and prevent bill surprises
- **Usage:** Understand feature adoption and user patterns

---

## Monitoring Dashboard

### Supabase Dashboard Access

**URL:** `https://app.supabase.com/project/<project-ref>`

**Navigate to Edge Functions:**
1. Log in to Supabase Dashboard
2. Select your project
3. Click **Edge Functions** in left sidebar
4. Select specific function to view metrics

### Available Metrics (Per Function)

| Metric | Description | Timeframe |
|--------|-------------|-----------|
| **Invocations** | Total number of requests | Last 24h, 7d, 30d |
| **Errors** | Count of 4xx and 5xx responses | Last 24h, 7d, 30d |
| **Response Time** | P50, P95, P99 latencies | Last 24h, 7d, 30d |
| **CPU Time** | Compute usage in GB-seconds | Last 24h, 7d, 30d |
| **Active Instances** | Number of warm instances | Real-time |

### Real-Time Monitoring

**View live requests:**
```
Dashboard → Edge Functions → [Function Name] → Logs (Real-time mode)
```

**Refresh rate:** Every 5 seconds

---

## Log Viewing

### Supabase Dashboard Logs

**Access:**
```
Dashboard → Edge Functions → [Function Name] → Logs
```

**Features:**
- **Real-time streaming** - See logs as they happen
- **Historical search** - Query last 7 days of logs
- **Filtering** - Filter by log level (info, error, warn)
- **Full-text search** - Search log messages

**Common Log Patterns to Watch:**

1. **OpenAI API Errors:**
   ```
   [generate-equipment-substitution] OpenAI API error: ...
   ```

2. **Database Errors:**
   ```
   Error fetching session exercises: ...
   Failed to save recommendation: ...
   ```

3. **WHOOP API Errors:**
   ```
   WHOOP recovery API error: 429 Rate limit reached
   ```

4. **Validation Errors:**
   ```
   AI selected exercise not in pre-vetted candidates: ...
   ```

### Local Log Viewing (Development)

**Serve function locally with debug logs:**
```bash
supabase functions serve generate-equipment-substitution --debug
```

**Output includes:**
- All `console.log()` statements
- HTTP request/response details
- Function execution time
- Environment variable values (redacted)

### Log Aggregation (Advanced)

**Export logs to external service:**

Supabase supports log forwarding to:
- **Datadog** - Full observability platform
- **Logflare** - Log management (Supabase partner)
- **Splunk** - Enterprise log analytics
- **Elasticsearch** - Self-hosted log search

**Setup:**
```
Dashboard → Settings → Integrations → Log Drains
```

---

## Key Metrics

### 1. Request Rate

**What:** Number of requests per minute/hour/day
**Why:** Understand usage patterns, detect traffic spikes
**Target:** Stable growth, no sudden drops

**How to View:**
```
Dashboard → Edge Functions → [Function] → Invocations Graph
```

**Red Flags:**
- Sudden drop to zero (function down or deployment issue)
- Spike 10x above normal (potential abuse or bot traffic)

### 2. Error Rate

**What:** Percentage of requests resulting in 4xx or 5xx errors
**Why:** Detect bugs, API failures, or user issues
**Target:** < 1% error rate

**Formula:**
```
Error Rate = (Error Count / Total Requests) × 100
```

**How to View:**
```
Dashboard → Edge Functions → [Function] → Errors Graph
```

**Red Flags:**
- Error rate > 5% (critical issue)
- Sudden spike in errors (deployment bug or API outage)
- Persistent errors on specific function (code bug)

### 3. Response Time (Latency)

**What:** Time from request to response
**Why:** Ensure good user experience
**Targets:**
- **P50:** < 2 seconds (median user experience)
- **P95:** < 5 seconds (95% of users)
- **P99:** < 10 seconds (outliers acceptable)

**How to View:**
```
Dashboard → Edge Functions → [Function] → Response Time Graph
```

**Red Flags:**
- P50 > 5 seconds (function too slow)
- P99 > 30 seconds (timeouts occurring)
- Increasing trend over time (performance degradation)

### 4. OpenAI API Usage

**What:** Tokens consumed, costs incurred
**Why:** Control AI costs, avoid budget overruns
**Target:** < $500/month for 1,000 users

**How to View:**
- **OpenAI Dashboard:** `https://platform.openai.com/usage`
- **Edge Function Logs:** Search for "tokens_used"

**Red Flags:**
- Daily cost > $20 (monthly would exceed budget)
- Token usage 10x higher than expected (prompt issue or abuse)

### 5. Cache Hit Rate

**What:** Percentage of requests served from cache
**Why:** Reduce costs and improve performance
**Targets:**
- **WHOOP sync:** > 90% (1-hour cache)
- **Nutrition recommendations:** > 70% (30-min cache)

**How to Calculate:**
```sql
-- Count cached WHOOP syncs today
SELECT
  COUNT(*) FILTER (WHERE whoop_synced_at > NOW() - INTERVAL '1 hour') AS cached_requests,
  COUNT(*) AS total_requests,
  (COUNT(*) FILTER (WHERE whoop_synced_at > NOW() - INTERVAL '1 hour')::float / COUNT(*)) * 100 AS cache_hit_rate
FROM daily_readiness
WHERE date = CURRENT_DATE;
```

**Red Flags:**
- Cache hit rate < 50% (caching not working or invalidated too often)
- Zero cache hits (caching broken)

---

## Alert Configuration

### Recommended Alerts

**Configure in Supabase Dashboard:**
```
Dashboard → Settings → Alerts → Create Alert
```

#### Alert 1: High Error Rate

**Condition:** Error rate > 5% over 15 minutes
**Notification:** Email, Slack
**Action:** Investigate logs immediately

**Configuration:**
```yaml
name: Edge Functions - High Error Rate
metric: error_rate
threshold: 5
duration: 15m
channels: [email, slack]
```

#### Alert 2: OpenAI API Failure

**Condition:** 3+ consecutive OpenAI API errors
**Notification:** Email, Slack, PagerDuty
**Action:** Check OpenAI status, verify API key

**How to Implement:**
```javascript
// Add to Edge Function code (generate-equipment-substitution, ai-nutrition-recommendation, ai-meal-parser)
let consecutiveErrors = 0;

try {
  const response = await fetch('https://api.openai.com/...');
  consecutiveErrors = 0; // Reset on success
} catch (error) {
  consecutiveErrors++;
  if (consecutiveErrors >= 3) {
    // Send alert via Slack webhook
    await fetch('https://hooks.slack.com/services/...', {
      method: 'POST',
      body: JSON.stringify({
        text: `🚨 ALERT: OpenAI API failing (${consecutiveErrors} consecutive errors)`
      })
    });
  }
}
```

#### Alert 3: Response Time Degradation

**Condition:** P95 latency > 10 seconds over 30 minutes
**Notification:** Email
**Action:** Investigate performance bottleneck

**Configuration:**
```yaml
name: Edge Functions - Slow Response Time
metric: p95_latency
threshold: 10000ms
duration: 30m
channels: [email]
```

#### Alert 4: Daily Cost Threshold

**Condition:** OpenAI API cost > $20 in 24 hours
**Notification:** Email, Slack
**Action:** Review usage, check for abuse

**How to Implement:**
```javascript
// Daily cron job (scheduled Edge Function)
export async function checkDailyCosts() {
  const openaiUsage = await fetch('https://api.openai.com/v1/usage', {
    headers: { 'Authorization': `Bearer ${OPENAI_API_KEY}` }
  });

  const data = await openaiUsage.json();
  const todayCost = data.total_usage * 0.00001; // Example calculation

  if (todayCost > 20) {
    await sendSlackAlert(`⚠️ OpenAI costs today: $${todayCost.toFixed(2)} (threshold: $20)`);
  }
}
```

#### Alert 5: WHOOP API Rate Limit

**Condition:** WHOOP API returns 429 response
**Notification:** Email
**Action:** Reduce sync frequency or request rate limit increase

**Implementation:**
```javascript
// In sync-whoop-recovery function
if (response.status === 429) {
  const retryAfter = response.headers.get('Retry-After');
  await sendAlert(`WHOOP rate limit hit. Retry after ${retryAfter}s`);
}
```

---

## Debugging Failed Requests

### Step-by-Step Debugging Process

#### 1. Identify the Failed Request

**From Logs:**
```
Dashboard → Edge Functions → [Function] → Logs
Filter by: "error" or "failed"
```

**From User Report:**
- Note: timestamp, user ID, function name
- Reproduce: attempt same request with same parameters

#### 2. Examine the Error Message

**Common Error Patterns:**

| Error Message | Cause | Solution |
|---------------|-------|----------|
| "patient_id required" | Missing request parameter | Client-side validation issue |
| "Recommendation not found" | Invalid UUID | Check database for missing data |
| "OpenAI API failed" | API key issue or OpenAI outage | Verify key, check status.openai.com |
| "Failed to fetch session exercises" | Database connectivity | Check Supabase status |
| "AI selected exercise not in pre-vetted candidates" | Prompt issue | Review AI response, update prompt |
| "WHOOP API rate limit reached" | Too many requests | Implement backoff, request limit increase |

#### 3. Check Function Logs

**Search for related log entries:**
```
Search: request_id:abc123
Time range: ± 5 minutes of error
```

**Look for:**
- Function entry point log
- Database query results
- OpenAI API request/response
- Error stack trace

#### 4. Reproduce Locally

**Serve function locally:**
```bash
supabase functions serve generate-equipment-substitution --debug
```

**Send test request:**
```bash
curl -X POST "http://localhost:54321/functions/v1/generate-equipment-substitution" \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "123e4567-e89b-12d3-a456-426614174000",
    "session_id": "987fcdeb-51a2-43d7-b890-123456789abc",
    "scheduled_date": "2026-01-15",
    "equipment_available": ["dumbbells"],
    "intensity_preference": "standard"
  }'
```

**Observe console output for detailed error**

#### 5. Fix and Re-Deploy

**Fix the issue:**
```bash
vim supabase/functions/generate-equipment-substitution/index.ts
# Make fix
```

**Test locally:**
```bash
# Re-test with same request
curl ...
```

**Deploy fix:**
```bash
supabase functions deploy generate-equipment-substitution
```

**Verify in production:**
```bash
# Re-test production endpoint
curl https://<project-ref>.supabase.co/functions/v1/...
```

---

## Performance Monitoring

### Latency Breakdown

**Where time is spent:**

| Function | Database Query | OpenAI API | Processing | Total |
|----------|----------------|------------|------------|-------|
| generate-equipment-substitution | ~200ms | ~3000ms | ~200ms | ~3400ms |
| apply-substitution | ~300ms | 0ms | ~100ms | ~400ms |
| sync-whoop-recovery | ~150ms | 0ms (or ~1500ms WHOOP) | ~50ms | ~200ms (or ~1700ms) |
| ai-nutrition-recommendation | ~250ms | ~1500ms | ~100ms | ~1850ms |
| ai-meal-parser (text) | 0ms | ~1200ms | ~50ms | ~1250ms |
| ai-meal-parser (image) | 0ms | ~2500ms | ~50ms | ~2550ms |

**Optimization Opportunities:**

1. **Database Queries**
   - Add indexes on frequently queried columns
   - Use `select` to limit returned columns
   - Batch queries where possible

2. **OpenAI API**
   - Use `gpt-4o-mini` instead of `gpt-4` where quality acceptable
   - Reduce `max_tokens` to minimum needed
   - Implement aggressive caching

3. **Processing**
   - Minimize JSON parsing overhead
   - Use efficient data structures
   - Avoid unnecessary loops

### Database Query Performance

**Monitor slow queries:**

```sql
-- Enable pg_stat_statements extension
CREATE EXTENSION IF NOT EXISTS pg_stat_statements;

-- View slowest queries
SELECT
  query,
  calls,
  mean_exec_time,
  max_exec_time,
  total_exec_time
FROM pg_stat_statements
WHERE query LIKE '%recommendations%'
ORDER BY mean_exec_time DESC
LIMIT 10;
```

**Create indexes for common queries:**

```sql
-- Index for fetching recommendations
CREATE INDEX IF NOT EXISTS idx_recommendations_patient_created
  ON recommendations(patient_id, created_at DESC);

-- Index for session exercises lookup
CREATE INDEX IF NOT EXISTS idx_session_exercises_session
  ON session_exercises(session_id);

-- Index for daily readiness lookup
CREATE INDEX IF NOT EXISTS idx_daily_readiness_patient_date
  ON daily_readiness(patient_id, date DESC);
```

### OpenAI API Performance

**Monitor token usage:**

```sql
-- Average tokens per function
SELECT
  'generate-equipment-substitution' AS function_name,
  AVG((metadata->>'tokens_used')::int) AS avg_tokens,
  MAX((metadata->>'tokens_used')::int) AS max_tokens,
  COUNT(*) AS request_count
FROM recommendations
WHERE metadata->>'tokens_used' IS NOT NULL
  AND created_at > NOW() - INTERVAL '7 days';
```

**Optimize prompts:**
- Remove unnecessary instructions
- Use concise language
- Limit example demonstrations
- Set appropriate `max_tokens`

---

## Cost Monitoring

### OpenAI API Costs

**Track daily costs:**

```sql
-- Estimated OpenAI costs (last 7 days)
WITH token_usage AS (
  SELECT
    DATE(created_at) AS date,
    'equipment-substitution' AS source,
    SUM((metadata->>'tokens_used')::int) AS total_tokens
  FROM recommendations
  WHERE metadata->>'tokens_used' IS NOT NULL
    AND created_at > NOW() - INTERVAL '7 days'
  GROUP BY DATE(created_at)

  UNION ALL

  SELECT
    DATE(created_at) AS date,
    'nutrition-recommendation' AS source,
    SUM((metadata->>'tokens_used')::int) AS total_tokens
  FROM nutrition_recommendations
  WHERE metadata->>'tokens_used' IS NOT NULL
    AND created_at > NOW() - INTERVAL '7 days'
  GROUP BY DATE(created_at)
)
SELECT
  date,
  source,
  total_tokens,
  CASE source
    WHEN 'equipment-substitution' THEN total_tokens * 0.00002  -- GPT-4 Turbo avg rate
    WHEN 'nutrition-recommendation' THEN total_tokens * 0.0000004  -- GPT-4o-mini avg rate
  END AS estimated_cost_usd
FROM token_usage
ORDER BY date DESC, source;
```

### Supabase Costs

**Edge Functions billing:**
- **Invocations:** Free up to 500K/month, then $2 per 1M
- **Compute:** Free up to 400K GB-s/month, then $0.00001838 per GB-s

**Track usage:**
```
Dashboard → Settings → Billing → Usage
```

**Estimate monthly cost:**
```sql
-- Current month invocations
SELECT
  function_slug,
  COUNT(*) AS invocations,
  CASE
    WHEN COUNT(*) > 500000 THEN (COUNT(*) - 500000) / 1000000 * 2
    ELSE 0
  END AS overage_cost_usd
FROM edge_function_logs
WHERE created_at >= DATE_TRUNC('month', NOW())
GROUP BY function_slug;
```

### Cost Alerts

**Set budget alerts:**
```
Dashboard → Settings → Billing → Budgets
```

**Recommended budgets:**
- OpenAI: $500/month (for 1,000 users)
- Supabase: $25/month (Pro plan)
- Total: $525/month

**Alert thresholds:**
- 50% of budget: Email notification
- 80% of budget: Email + Slack notification
- 100% of budget: Email + Slack + disable non-essential functions

---

## SQL Monitoring Queries

### 1. Recent Recommendations Created

```sql
-- Last 100 equipment substitution recommendations
SELECT
  id,
  patient_id,
  session_id,
  status,
  created_at,
  applied_at,
  patch->'exercise_substitutions' AS substitutions,
  metadata->>'tokens_used' AS tokens_used
FROM recommendations
ORDER BY created_at DESC
LIMIT 100;
```

### 2. Success/Failure Rates

```sql
-- Daily recommendation success rate (last 30 days)
SELECT
  DATE(created_at) AS date,
  COUNT(*) AS total_created,
  COUNT(*) FILTER (WHERE status = 'applied') AS applied_count,
  COUNT(*) FILTER (WHERE status = 'rejected') AS rejected_count,
  COUNT(*) FILTER (WHERE status = 'pending') AS pending_count,
  (COUNT(*) FILTER (WHERE status = 'applied')::float / COUNT(*)) * 100 AS application_rate
FROM recommendations
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### 3. Most Common Errors

```sql
-- Top error messages (from logs)
SELECT
  error_message,
  COUNT(*) AS occurrence_count,
  MAX(created_at) AS last_occurred
FROM edge_function_error_logs
WHERE created_at > NOW() - INTERVAL '7 days'
GROUP BY error_message
ORDER BY occurrence_count DESC
LIMIT 20;
```

### 4. WHOOP Sync Activity

```sql
-- WHOOP sync frequency (last 7 days)
SELECT
  patient_id,
  COUNT(*) AS sync_count,
  AVG(whoop_recovery_score) AS avg_recovery,
  MAX(whoop_synced_at) AS last_synced
FROM daily_readiness
WHERE whoop_synced_at > NOW() - INTERVAL '7 days'
GROUP BY patient_id
ORDER BY sync_count DESC
LIMIT 50;
```

### 5. Nutrition Recommendation Usage

```sql
-- Daily nutrition recommendation volume
SELECT
  DATE(created_at) AS date,
  COUNT(*) AS recommendation_count,
  COUNT(DISTINCT patient_id) AS unique_patients,
  AVG((target_macros->>'calories')::int) AS avg_calories,
  AVG((target_macros->>'protein')::int) AS avg_protein
FROM nutrition_recommendations
WHERE created_at > NOW() - INTERVAL '30 days'
GROUP BY DATE(created_at)
ORDER BY date DESC;
```

### 6. Meal Parsing Confidence

```sql
-- Meal parser confidence distribution
SELECT
  (parsed_meal->>'ai_confidence') AS confidence_level,
  COUNT(*) AS meal_count,
  AVG((parsed_meal->>'calories')::int) AS avg_calories
FROM daily_meals
WHERE created_at > NOW() - INTERVAL '7 days'
  AND parsed_meal IS NOT NULL
GROUP BY (parsed_meal->>'ai_confidence')
ORDER BY meal_count DESC;
```

---

## Troubleshooting Playbook

### Scenario 1: Function Returning 500 Errors

**Symptoms:**
- All requests to function return 500
- Logs show "Internal server error"

**Diagnosis:**
1. Check recent deployments (did code change?)
2. Check OpenAI API status (status.openai.com)
3. Check Supabase status (status.supabase.com)
4. Review function logs for stack traces

**Resolution:**
```bash
# If recent deployment caused it:
supabase functions deploy <function> --version <previous-good-version>

# If OpenAI is down:
# Wait for OpenAI to recover, or implement fallback

# If database issue:
# Check RLS policies, verify tables exist
```

### Scenario 2: OpenAI API Costs Spike

**Symptoms:**
- Daily OpenAI cost > $50 (normally $10)
- Token usage 5x higher than expected

**Diagnosis:**
1. Check for abuse (same user making 1000s of requests)
2. Review prompt changes (did prompt get longer?)
3. Check `max_tokens` setting (accidentally increased?)

**Resolution:**
```bash
# Identify abusive user
SELECT patient_id, COUNT(*)
FROM recommendations
WHERE created_at > NOW() - INTERVAL '1 day'
GROUP BY patient_id
ORDER BY COUNT(*) DESC;

# Temporarily disable function if abuse confirmed
supabase functions delete generate-equipment-substitution

# Implement rate limiting (code change + re-deploy)
# Add: Check request count, reject if > 10/hour per user
```

### Scenario 3: WHOOP Sync Fails for All Users

**Symptoms:**
- All WHOOP syncs return errors
- Logs show "Failed to refresh access token"

**Diagnosis:**
1. Check WHOOP API status
2. Verify WHOOP_CLIENT_SECRET is set correctly
3. Check if WHOOP OAuth app was deleted/disabled

**Resolution:**
```bash
# Verify secrets
supabase secrets list

# Re-set if needed
supabase secrets set WHOOP_CLIENT_SECRET=...

# Fallback to mock data temporarily
# (Function already does this automatically)
```

### Scenario 4: Database Queries Timing Out

**Symptoms:**
- Functions return 504 Gateway Timeout
- Logs show "Database query exceeded 10s timeout"

**Diagnosis:**
1. Check database CPU usage (Dashboard → Database → Metrics)
2. Identify slow queries (see Performance Monitoring section)
3. Check for missing indexes

**Resolution:**
```sql
-- Add missing indexes
CREATE INDEX CONCURRENTLY idx_name ON table_name(column);

-- Or scale up database instance
-- Dashboard → Settings → Database → Upgrade Plan
```

---

## Summary Checklist

**Daily Monitoring (5 minutes):**
- [ ] Check error rate (target < 1%)
- [ ] Review OpenAI costs (target < $20/day)
- [ ] Scan logs for critical errors
- [ ] Verify all functions show "ACTIVE" status

**Weekly Monitoring (30 minutes):**
- [ ] Review performance trends (response times increasing?)
- [ ] Check cache hit rates (WHOOP > 90%, nutrition > 70%)
- [ ] Analyze usage patterns (which functions most popular?)
- [ ] Review and close monitoring alerts

**Monthly Monitoring (2 hours):**
- [ ] Compare costs to budget (on track?)
- [ ] Identify optimization opportunities
- [ ] Update alert thresholds based on new baselines
- [ ] Document any incidents and resolutions

---

**Guide Version:** 1.0
**Last Updated:** 2026-01-04
**Maintained By:** BUILD 138 Team
**Next Review:** Monthly

---

**For Support:**
- Supabase: support@supabase.com
- OpenAI: help.openai.com
- Internal: #build-138-support (Slack)
