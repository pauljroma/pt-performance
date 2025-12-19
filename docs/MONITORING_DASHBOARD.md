# Monitoring Dashboard Guide

**Purpose:** Guide for using Sentry to monitor PT Performance app health, errors, and performance in production.

**Context:** Build 45 integrated Sentry SDK for comprehensive error tracking and performance monitoring to detect issues before they impact users.

---

## Quick Access

### Sentry Dashboard

**Production:** https://sentry.io/organizations/[your-org]/projects/pt-performance/

**Key Sections:**
- **Issues** - Error tracking and crash reports
- **Performance** - Transaction monitoring and slow operations
- **Releases** - Version tracking and error attribution

---

## Dashboard Overview

### 1. Issues (Error Tracking)

**What it shows:** All errors, crashes, and exceptions in production

**Key Metrics:**
- **Error Rate** - Errors per hour/day
- **Affected Users** - Number of users experiencing errors
- **Crash-Free Sessions** - % of sessions without crashes
- **First Seen / Last Seen** - When error first/last occurred

**Priority Indicators:**
- 🔴 **Fatal** - App crashes (schema mismatches, nil unwrapping)
- 🟠 **Error** - Handled errors (network failures, database errors)
- 🟡 **Warning** - Non-critical issues (slow queries, high memory)

**How to Use:**
1. Check dashboard daily for new issues
2. Sort by "Events" to see most frequent errors
3. Click issue to see stack trace, breadcrumbs, user context
4. Mark as "Resolved" after deploying fix
5. Set alerts for critical errors (schema mismatches)

---

### 2. Performance Monitoring

**What it shows:** App performance metrics and slow operations

**Key Metrics:**
- **App Launch Time** - Time from app start to first screen
- **View Load Time** - Time to render each screen
- **Database Query Duration** - Time spent in database operations
- **Network Request Duration** - API call response times
- **Memory Usage** - RAM consumption trends

**Thresholds:**
- ✅ **Good** - App launch < 1s, views < 2s, queries < 1s
- ⚠️ **Warning** - App launch 1-2s, views 2-4s, queries 1-2s
- 🔴 **Poor** - App launch > 2s, views > 4s, queries > 2s

**Slow Operation Alerts:**
Automatically logged when operations exceed thresholds:
- View load > 2s
- Database query > 1s
- Network request > 3s
- Memory usage > 500 MB

---

### 3. Releases

**What it shows:** Errors attributed to specific app versions

**Key Information:**
- **Version** - e.g., "1.0.0 (44)"
- **Deploy Date** - When version was released
- **New Issues** - Errors introduced in this version
- **Regressed Issues** - Errors that came back
- **Crash-Free Rate** - % of sessions without crashes

**How to Use:**
1. After each TestFlight deployment, create release in Sentry
2. Monitor new issues in first 24 hours
3. Compare crash-free rate vs previous version
4. Roll back if crash-free rate drops significantly

**Creating a Release:**
```bash
# Via Sentry CLI
sentry-cli releases new "1.0.0 (44)"
sentry-cli releases set-commits "1.0.0 (44)" --auto
sentry-cli releases finalize "1.0.0 (44)"

# Or via GitHub Actions (automated)
```

---

## Common Scenarios

### Scenario 1: Schema Mismatch Detected

**Alert:** ⚠️ SCHEMA MISMATCH DETECTED

**Details:**
- **Type:** DecodingError.keyNotFound or typeMismatch
- **Severity:** Fatal (marked in ErrorLogger)
- **Impact:** Users can't load data, app may crash

**Investigation Steps:**
1. Check error details for missing/mismatched field
2. Compare iOS model CodingKeys vs database schema
3. Run schema validation: `python3 scripts/validate_ios_schema.py`
4. Check recent migrations for schema changes

**Resolution:**
1. Fix schema mismatch (update model or database)
2. Deploy hotfix via TestFlight
3. Monitor release for 24 hours
4. Mark issue as "Resolved in next release"

---

### Scenario 2: High Error Rate

**Alert:** Error rate spiked to 50 errors/hour

**Investigation Steps:**
1. **Check timeline** - When did spike start?
2. **Check affected users** - Is it everyone or specific users?
3. **Check device/OS** - Is it iOS version specific?
4. **Check breadcrumbs** - What actions led to error?
5. **Check stack trace** - Where in code did error occur?

**Common Causes:**
- Backend API down or returning errors
- Database migration in progress
- iOS version incompatibility
- Network connectivity issues

**Resolution:**
- If backend issue: Coordinate with backend team
- If client issue: Deploy hotfix
- If transient: Monitor and ensure it resolves

---

### Scenario 3: Slow Performance

**Alert:** 25% of database queries taking > 1s

**Investigation Steps:**
1. Go to Performance → Database Operations
2. Sort by P95 duration (95th percentile)
3. Identify slowest queries
4. Check query patterns (N+1 queries, missing indexes)
5. Check affected users (slow devices, poor network)

**Common Causes:**
- Missing database indexes
- N+1 query patterns
- Fetching too much data at once
- Slow network connection

**Resolution:**
- Add database indexes for slow queries
- Implement pagination for large datasets
- Add caching for frequently accessed data
- Use query batching to reduce round trips

---

### Scenario 4: Memory Warning

**Alert:** Memory usage exceeded 500 MB

**Investigation Steps:**
1. Check memory usage timeline
2. Identify which views/operations consume most memory
3. Look for memory leaks (usage never decreases)
4. Check image loading and caching

**Common Causes:**
- Images not being released after use
- Large datasets kept in memory
- Retain cycles in closures
- Caching too much data

**Resolution:**
- Implement proper image caching with limits
- Release unused data from memory
- Fix retain cycles
- Use lazy loading for large datasets

---

## Alerts and Notifications

### Critical Alerts (Immediate Action)

Configure Sentry to send alerts for:
- **Schema Mismatch** - DecodingError with "SCHEMA MISMATCH" tag
- **Crash Rate > 1%** - More than 1% of sessions crashing
- **Error Rate > 100/hour** - Spike in errors
- **New Fatal Error** - First occurrence of crash

**Notification Channels:**
- Slack: #pt-performance-alerts
- Email: dev-team@example.com
- PagerDuty: Critical issues only

### Warning Alerts (Review Within 24h)

- **Slow View Load** - Views taking > 4s to render
- **Slow Database Query** - Queries taking > 2s
- **High Memory Usage** - Usage > 750 MB
- **Network Request Timeout** - Requests taking > 10s

---

## Best Practices

### 1. Daily Monitoring Routine

**Morning Check (5 minutes):**
1. Check Issues → Unresolved
2. Review any new errors from last 24 hours
3. Check crash-free rate (should be > 99%)
4. Triage: ignore noise, assign critical issues

**Weekly Review (15 minutes):**
1. Review Performance trends
2. Identify slow operations to optimize
3. Check memory usage patterns
4. Review release comparison

### 2. Release Monitoring

**After TestFlight Deployment:**
- ✅ Create release in Sentry
- ✅ Monitor first 1 hour for crashes
- ✅ Check after 24 hours for new issues
- ✅ Compare crash-free rate vs previous version
- ✅ Address any regressions immediately

### 3. Error Triage

**Ignore:**
- Old errors already fixed
- Test/debug builds (filter by release)
- Network errors during maintenance
- User-initiated cancellations

**Investigate Immediately:**
- Schema mismatches
- Crashes affecting > 10 users
- New errors in latest release
- Database connection failures

**Monitor:**
- Slow operations
- High memory usage
- Network timeouts
- Validation errors

### 4. Context is Key

When investigating errors, always check:
1. **Stack Trace** - Where error occurred
2. **Breadcrumbs** - User actions leading to error
3. **User Context** - User role, device, OS version
4. **Tags** - Environment, release, custom tags
5. **Additional Data** - Request/response, query details

---

## Integrations

### GitHub Integration

**Setup:**
1. Install Sentry GitHub app
2. Connect to repository
3. Enable commit tracking

**Features:**
- Link errors to commits that introduced them
- Suggest commits to resolve issue
- Auto-resolve issues when fix is deployed

### Slack Integration

**Setup:**
1. Install Sentry Slack app
2. Configure alert rules
3. Set notification channel

**Features:**
- Real-time error notifications
- Daily/weekly digests
- Resolve issues from Slack

---

## Custom Queries

### Find Schema Mismatches

```
error.type:DecodingError
AND (message:"keyNotFound" OR message:"typeMismatch")
AND release:[latest]
```

### Find Slow Database Queries

```
transaction:db.*
AND measurements.query_duration:>1000ms
```

### Find Memory Issues

```
level:warning
AND message:"High memory usage"
AND event.timestamp:>now-7d
```

### Find User-Affecting Errors

```
level:error
AND user.count:>10
AND is:unresolved
```

---

## Maintenance

### Weekly Tasks

- [ ] Review and close resolved issues
- [ ] Update alert thresholds if needed
- [ ] Archive old releases (> 30 days)
- [ ] Check quota usage (events, storage)

### Monthly Tasks

- [ ] Review performance trends
- [ ] Optimize slow operations identified
- [ ] Update monitoring documentation
- [ ] Review and adjust alert rules

---

## Troubleshooting

### No Data Appearing in Sentry

**Possible Causes:**
- Sentry DSN not configured
- Network blocking Sentry requests
- Debug build (DSN intentionally empty)
- Sentry SDK not initialized

**Fixes:**
- Check `SENTRY_DSN` environment variable
- Test with `SentrySDK.capture(message: "Test")`
- Verify network allows sentry.io connections
- Check app logs for Sentry init errors

### Too Many Events / Over Quota

**Causes:**
- Noisy errors being logged repeatedly
- High sample rate in production
- Test builds sending events

**Fixes:**
- Use `beforeSend` filter to exclude noisy errors
- Lower `tracesSampleRate` to 0.1 (10%)
- Filter out debug builds by environment
- Add rate limiting for specific errors

### Missing Context Data

**Causes:**
- Context not set before error occurs
- Scope not configured properly
- Data filtered by `beforeSend`

**Fixes:**
- Set user context immediately after auth
- Use tags and custom context consistently
- Review `beforeSend` filter logic
- Check ErrorLogger utility usage

---

## Advanced Features

### Custom Dashboards

Create custom dashboards for:
- **Therapist View** - Errors affecting therapist workflows
- **Patient View** - Errors affecting patient experience
- **Database Health** - All database-related metrics
- **Network Health** - All API/network metrics

### Saved Searches

Save common queries:
- "Schema Mismatches This Week"
- "Unresolved Crashes"
- "Slow Operations by View"
- "High Priority Issues"

### Metric Alerts

Set up metric-based alerts:
- Crash-free rate drops below 99%
- Error rate exceeds 50/hour
- P95 database query time > 2s
- Memory usage trend increasing

---

## Related Documentation

- [Error Handling Best Practices](./ERROR_HANDLING.md)
- [Schema Validation Guide](./SCHEMA_VALIDATION.md)
- [Performance Optimization](./PERFORMANCE_OPTIMIZATION.md)

---

## Support

**Sentry Documentation:** https://docs.sentry.io/platforms/apple/guides/ios/

**Internal Support:**
- Check Linear issues with label `monitoring`
- Team chat: #pt-performance-dev

**Sentry Support:**
- Email: support@sentry.io
- Community: https://forum.sentry.io/

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 5 (Error Monitoring Engineer)
