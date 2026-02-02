# Analyze Logs

Summarize recent Supabase and Sentry errors with actionable insights.

## Trigger

```
/analyze-logs [source]
```

**Examples:**
- `/analyze-logs` - Analyze all sources
- `/analyze-logs supabase` - Supabase logs only
- `/analyze-logs sentry` - Sentry errors only
- `/analyze-logs --hours 24` - Last 24 hours

## Prerequisites

1. Supabase Dashboard access
2. Sentry project configured (optional)
3. Relevant API keys

## Execution Steps

### Phase 1: Fetch Supabase Logs

Via Dashboard:
- URL: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/logs/explorer

```sql
-- Edge Function errors
SELECT
  timestamp,
  event_message,
  metadata->>'function_id' as function_name,
  metadata->>'level' as level
FROM edge_logs
WHERE metadata->>'level' = 'error'
  AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC
LIMIT 50;
```

```sql
-- Database errors
SELECT
  timestamp,
  error_severity,
  message,
  detail
FROM postgres_logs
WHERE error_severity IN ('ERROR', 'FATAL')
  AND timestamp > NOW() - INTERVAL '24 hours'
ORDER BY timestamp DESC
LIMIT 50;
```

### Phase 2: Fetch Sentry Errors (if configured)

```bash
# Using Sentry API
curl "https://sentry.io/api/0/projects/[org]/[project]/issues/" \
  -H "Authorization: Bearer $SENTRY_API_KEY" \
  -H "Content-Type: application/json" | \
  jq '.[] | {id, title, count, lastSeen}'
```

### Phase 3: Categorize Errors

Group by type:
- **Auth Errors**: Login failures, token expiration
- **Database Errors**: Query failures, constraint violations
- **Edge Function Errors**: Runtime exceptions, timeouts
- **iOS App Errors**: Crashes, API call failures

### Phase 4: Identify Patterns

```javascript
// Group errors by message
const errorGroups = errors.reduce((acc, err) => {
  const key = err.message.substring(0, 50);
  acc[key] = (acc[key] || 0) + 1;
  return acc;
}, {});

// Sort by frequency
const sorted = Object.entries(errorGroups)
  .sort((a, b) => b[1] - a[1]);
```

### Phase 5: Generate Report

```markdown
# Error Analysis Report

**Period:** Last 24 hours
**Total Errors:** 47

---

## Summary

| Category | Count | Trend |
|----------|-------|-------|
| Auth | 12 | +5 from yesterday |
| Database | 8 | Stable |
| Edge Functions | 22 | -3 from yesterday |
| iOS App | 5 | New |

---

## Top Errors

### 1. "JWT expired" (12 occurrences)
**Source:** Edge Functions
**Impact:** Users forced to re-login
**Fix:** Increase token refresh frequency in iOS app

### 2. "null value in column patient_id" (8 occurrences)
**Source:** Database (sessions table)
**Impact:** Session creation failing
**Fix:** Add null check before insert in SessionService.swift

### 3. "Function timeout" (6 occurrences)
**Source:** ai-workout-recommendation
**Impact:** Slow workout generation
**Fix:** Optimize OpenAI prompt, add caching

---

## Recommendations

1. **Critical**: Fix patient_id null check in iOS app
2. **High**: Add token refresh 5 min before expiry
3. **Medium**: Increase edge function timeout to 30s

---

## Error Timeline

```
00:00 ████░░░░ 8 errors
06:00 ██░░░░░░ 4 errors
12:00 ██████░░ 12 errors
18:00 ████████ 23 errors (peak)
```

Peak at 18:00 correlates with US evening usage.
```

## Output

```
Log Analysis Complete

Period: Last 24 hours
Sources: Supabase, Edge Functions

Total Errors: 47
- Critical: 2
- High: 8
- Medium: 15
- Low: 22

Top Issues:
1. JWT expired (12x) - Auth
2. null patient_id (8x) - Database
3. Function timeout (6x) - Edge

Action Required:
- Fix patient_id null check in SessionService.swift
- Review ai-workout-recommendation performance

Full report: ./reports/errors-2025-01-30.md
```

## Reference

- Supabase Logs: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/logs
- Edge Function Logs: Logs > Edge Functions
- Sentry Dashboard: https://sentry.io/
