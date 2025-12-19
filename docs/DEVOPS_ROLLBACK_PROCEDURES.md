# Deployment Rollback Procedures

## Overview
Quick reference guide for rolling back deployments when issues are detected in production.

## When to Rollback

Rollback immediately if:
- Critical bugs affecting all users
- Data corruption or loss
- Authentication failures
- Crashes affecting >5% of users
- Security vulnerabilities exposed
- Performance degradation >50%

## Rollback Types

### 1. iOS App Rollback (TestFlight)
### 2. Database Migration Rollback
### 3. API/Backend Rollback
### 4. Full Stack Rollback

---

## iOS App Rollback

### Option A: TestFlight Build Rollback (Recommended)

**Time to Rollback**: 5-15 minutes

```bash
#!/bin/bash
# scripts/rollback_ios_app.sh

set -e

PREVIOUS_BUILD=$1

if [ -z "$PREVIOUS_BUILD" ]; then
    echo "Usage: ./rollback_ios_app.sh <previous_build_number>"
    echo "Example: ./rollback_ios_app.sh 60"
    exit 1
fi

echo "Rolling back to build $PREVIOUS_BUILD..."

# 1. Disable current build in TestFlight
# (Must be done manually in App Store Connect)
echo "1. Go to App Store Connect → TestFlight"
echo "2. Find current build and click 'Stop Testing'"
echo "3. Find build $PREVIOUS_BUILD and click 'Start Testing'"

# 2. Notify team
echo "
✅ iOS App Rollback Initiated

Previous Build: $PREVIOUS_BUILD
Reason: [INSERT REASON]
ETA: Build will be available in TestFlight in 5-10 minutes

Action Required:
- Monitor Sentry for new errors
- Verify critical paths working
- Notify users of the rollback
"

# 3. Send Slack notification (if configured)
# curl -X POST -H 'Content-type: application/json' \
#   --data '{"text":"iOS App rolled back to build '$PREVIOUS_BUILD'"}' \
#   $SLACK_WEBHOOK_URL
```

### Option B: Revert Git Commit and Redeploy

**Time to Rollback**: 30-45 minutes

```bash
#!/bin/bash
# scripts/revert_and_redeploy.sh

set -e

COMMIT_HASH=$1

if [ -z "$COMMIT_HASH" ]; then
    echo "Usage: ./revert_and_redeploy.sh <commit_hash_to_revert_to>"
    exit 1
fi

echo "Reverting to commit $COMMIT_HASH and redeploying..."

# 1. Create revert branch
git checkout main
git pull origin main
git checkout -b rollback/$(date +%Y%m%d_%H%M%S)

# 2. Revert to previous commit
git revert --no-commit $COMMIT_HASH..HEAD
git commit -m "Rollback to $COMMIT_HASH"

# 3. Push and trigger CI/CD
git push origin HEAD

# 4. Trigger TestFlight deployment
gh workflow run ios-testflight-deploy.yml

echo "✅ Revert commit pushed. CI/CD will build and deploy."
echo "Monitor: https://github.com/your-org/repo/actions"
```

---

## Database Migration Rollback

### Critical: Always Have Backup Before Migration

**Time to Rollback**: 5-20 minutes (depending on data size)

```bash
#!/bin/bash
# scripts/rollback_database.sh

set -e

BACKUP_FILE=$1

if [ -z "$BACKUP_FILE" ]; then
    echo "Usage: ./rollback_database.sh <backup_file>"
    echo "Example: ./rollback_database.sh prod_backup_20251219_120000.sql"
    exit 1
fi

if [ ! -f "$BACKUP_FILE" ]; then
    echo "❌ Backup file not found: $BACKUP_FILE"
    exit 1
fi

echo "⚠️  WARNING: This will restore database from backup!"
echo "Backup file: $BACKUP_FILE"
echo "Target: $PRODUCTION_DATABASE_URL"
read -p "Continue? (type 'ROLLBACK' to confirm): " confirmation

if [ "$confirmation" != "ROLLBACK" ]; then
    echo "Rollback cancelled."
    exit 0
fi

echo "Starting database rollback..."

# 1. Create safety backup of current state
echo "Creating safety backup of current state..."
pg_dump $PRODUCTION_DATABASE_URL > safety_backup_$(date +%Y%m%d_%H%M%S).sql

# 2. Kill all active connections
echo "Terminating active connections..."
psql $PRODUCTION_DATABASE_URL -c "
SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid();
"

# 3. Restore from backup
echo "Restoring from backup..."
psql $PRODUCTION_DATABASE_URL < $BACKUP_FILE

# 4. Verify restoration
echo "Verifying restoration..."
psql $PRODUCTION_DATABASE_URL -c "
SELECT
    (SELECT COUNT(*) FROM patients) as patients,
    (SELECT COUNT(*) FROM programs) as programs,
    (SELECT COUNT(*) FROM sessions) as sessions,
    (SELECT COUNT(*) FROM exercise_logs) as exercise_logs;
"

echo "✅ Database rollback complete!"
echo "Safety backup saved: safety_backup_$(date +%Y%m%d_%H%M%S).sql"
```

### Migration-Specific Rollback

If migration includes down migration:

```bash
#!/bin/bash
# scripts/rollback_migration.sh

set -e

MIGRATION_FILE=$1

if [ -z "$MIGRATION_FILE" ]; then
    echo "Usage: ./rollback_migration.sh <migration_file>"
    echo "Example: ./rollback_migration.sh 20251219000001_add_new_feature.sql"
    exit 1
fi

# Look for corresponding down migration
DOWN_MIGRATION="${MIGRATION_FILE%.sql}_down.sql"

if [ ! -f "supabase/migrations/$DOWN_MIGRATION" ]; then
    echo "❌ Down migration not found: $DOWN_MIGRATION"
    echo "Use full database restore instead."
    exit 1
fi

echo "Running down migration: $DOWN_MIGRATION"

# Create backup first
pg_dump $PRODUCTION_DATABASE_URL > backup_before_down_$(date +%Y%m%d_%H%M%S).sql

# Run down migration
psql $PRODUCTION_DATABASE_URL < supabase/migrations/$DOWN_MIGRATION

echo "✅ Migration rolled back successfully!"
```

---

## Automated Rollback Scripts

### Health Check and Auto-Rollback

```bash
#!/bin/bash
# scripts/auto_rollback_monitor.sh

set -e

HEALTH_CHECK_URL="https://api.ptperformance.com/health"
ERROR_THRESHOLD=10
PREVIOUS_BUILD="60"

echo "Monitoring deployment health..."

error_count=0
for i in {1..30}; do
    response=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_CHECK_URL)

    if [ "$response" != "200" ]; then
        error_count=$((error_count + 1))
        echo "Health check failed: $response (attempt $i/30, errors: $error_count)"

        if [ $error_count -ge $ERROR_THRESHOLD ]; then
            echo "❌ Error threshold exceeded! Initiating automatic rollback..."

            # Rollback iOS app
            ./scripts/rollback_ios_app.sh $PREVIOUS_BUILD

            # Notify team
            echo "
            🚨 AUTOMATIC ROLLBACK TRIGGERED

            Reason: Health check failures exceeded threshold
            Previous Build: $PREVIOUS_BUILD
            Failed Checks: $error_count/$ERROR_THRESHOLD
            Time: $(date)

            Action Required:
            1. Investigate failed deployment
            2. Fix issues
            3. Re-test in staging
            4. Re-deploy when ready
            "

            exit 1
        fi
    else
        echo "✅ Health check passed (attempt $i/30)"
    fi

    sleep 10
done

echo "✅ Deployment healthy! Monitoring complete."
```

---

## Rollback Decision Matrix

| Issue | Severity | Rollback Type | ETA |
|-------|----------|---------------|-----|
| App crashes on launch | Critical | iOS App | 5-15 min |
| Authentication failure | Critical | iOS App + DB | 15-30 min |
| Data corruption | Critical | Database | 5-20 min |
| UI bug (non-blocking) | Low | Next release | N/A |
| Performance degradation | High | iOS App | 5-15 min |
| RLS policy issue | Critical | Database | 5-10 min |
| New feature bug | Medium | Feature flag off | <1 min |

---

## Emergency Contacts

### Rollback Authority

**Tier 1**: Can initiate rollback immediately
- DevOps Lead
- CTO
- Engineering Manager

**Tier 2**: Can initiate rollback with approval
- Senior Engineers
- Product Manager

**Tier 3**: Must request rollback
- Engineers
- QA Team

### Contact List

```
DevOps Lead: +1-555-0101
CTO: +1-555-0102
Engineering Manager: +1-555-0103
Supabase Support: support@supabase.com
Apple Developer Support: 1-800-633-2152
```

---

## Post-Rollback Procedures

### 1. Incident Report

Create incident report within 24 hours:

```markdown
# Incident Report: [Date] Rollback

## Summary
- Date/Time: [UTC timestamp]
- Duration: [minutes]
- Affected Users: [count or percentage]
- Root Cause: [brief description]

## Timeline
- [Time] Issue detected
- [Time] Rollback initiated
- [Time] Rollback completed
- [Time] Service restored

## Root Cause Analysis
[Detailed analysis of what went wrong]

## Action Items
- [ ] Fix identified in code
- [ ] Additional tests added
- [ ] Deployment process improved
- [ ] Documentation updated

## Prevention
[Steps to prevent similar issues]
```

### 2. Database Verification

```sql
-- Verify data integrity after rollback
SELECT
    'patients' as table_name,
    COUNT(*) as count,
    MAX(created_at) as latest_record
FROM patients
UNION ALL
SELECT 'programs', COUNT(*), MAX(created_at) FROM programs
UNION ALL
SELECT 'sessions', COUNT(*), MAX(created_at) FROM sessions
UNION ALL
SELECT 'exercise_logs', COUNT(*), MAX(created_at) FROM exercise_logs;

-- Check for orphaned records
SELECT s.id, s.program_id
FROM sessions s
LEFT JOIN programs p ON s.program_id = p.id
WHERE p.id IS NULL;
```

### 3. Monitor After Rollback

- Sentry error rate (should decrease)
- User session count (should stabilize)
- API response times (should improve)
- Crash-free rate (should improve)

### 4. Communication

**Internal**:
```
Subject: Production Rollback Complete

Team,

We've completed a rollback to Build 60 due to [issue].

Status: ✅ Resolved
Users Affected: [count]
Downtime: [duration]
Root Cause: [brief description]

Next Steps:
- Fix is being developed
- ETA for re-deployment: [time]
- Post-mortem scheduled for [date/time]
```

**External** (if needed):
```
We experienced a technical issue and have rolled back to a previous version.
All data is safe and the app is now functioning normally.
We apologize for the inconvenience.
```

---

## Testing Rollback Procedures

### Quarterly Rollback Drill

1. Schedule maintenance window
2. Deploy to staging
3. Simulate failure
4. Execute rollback
5. Verify restoration
6. Document learnings

---

## Rollback Checklist

### Pre-Rollback
- [ ] Backup current state
- [ ] Notify team
- [ ] Identify previous stable version
- [ ] Document reason for rollback

### During Rollback
- [ ] Execute rollback script
- [ ] Monitor progress
- [ ] Verify each step completes

### Post-Rollback
- [ ] Verify application functionality
- [ ] Check database integrity
- [ ] Monitor error rates
- [ ] Notify users (if needed)
- [ ] Create incident report
- [ ] Schedule post-mortem

---

## Support

For rollback assistance:
- Slack: #devops-emergency
- Email: devops@example.com
- On-call: PagerDuty rotation
