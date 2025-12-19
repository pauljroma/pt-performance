# Migration Rollback Procedures

**Purpose:** Step-by-step procedures for safely rolling back database migrations when issues occur in production.

**Context:** Build 44 had schema issues that required emergency fixes. This guide ensures we can safely revert problematic migrations without data loss.

---

## Quick Rollback (Emergency)

If a migration causes immediate production issues:

```bash
# 1. Get the backup file (created before migration)
ls /tmp/schema_backup_*.sql

# 2. Rollback to previous state
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_YYYYMMDD_HHMMSS.sql

# 3. Verify rollback succeeded
python3 scripts/validate_ios_schema.py

# 4. Alert team
# Post in #pt-performance-alerts that migration was rolled back
```

**⚠️ IMPORTANT:** Only use this in emergencies. Follow full procedure below for planned rollbacks.

---

## When to Rollback

### Immediate Rollback Required

Roll back immediately if migration causes:
- ✅ App crashes on launch
- ✅ Users cannot log in
- ✅ Critical features broken (can't log workouts, can't view programs)
- ✅ Data corruption detected
- ✅ Schema mismatch errors in Sentry

### Rollback Recommended

Consider rollback if migration causes:
- ⚠️ Slow queries (> 5s)
- ⚠️ Increased error rate (> 10%)
- ⚠️ RLS policies blocking legitimate access
- ⚠️ Non-critical features broken

### No Rollback Needed

Don't rollback for:
- ℹ️ Minor UI issues
- ℹ️ Warning logs (not errors)
- ℹ️ Non-blocking performance degradation

---

## Pre-Rollback Checklist

Before rolling back ANY migration:

- [ ] Identify which migration caused the issue
- [ ] Verify backup file exists
- [ ] Check no critical writes are in progress
- [ ] Alert team in #pt-performance-alerts
- [ ] Document the issue (Linear ticket)
- [ ] Take snapshot of current error logs from Sentry

---

## Rollback Procedure

### Step 1: Assess the Situation

```bash
# Check current migration version
supabase migration list

# Check Sentry for errors
# Go to https://sentry.io and look for spike in errors

# Check schema validation
python3 scripts/validate_ios_schema.py
```

**Document findings:**
- Which migration is causing issues?
- What errors are occurring?
- How many users affected?

---

### Step 2: Create Emergency Backup

Even if rolling back, create a backup of current state:

```bash
# Create backup of current state
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump "$SUPABASE_DB_URL" --schema-only > /tmp/emergency_backup_$TIMESTAMP.sql

echo "Emergency backup saved to: /tmp/emergency_backup_$TIMESTAMP.sql"
```

---

### Step 3: Find Rollback Point

```bash
# List recent migrations
ls -lt supabase/migrations/ | head -10

# Identify the last working migration
# This is usually the migration BEFORE the problematic one
```

**Example:**
```
20251213120000_create_workload_flags.sql    ← Problematic
20251213110000_fix_session_exercises.sql    ← Roll back to this
20251213100000_create_analytics_views.sql
```

---

### Step 4: Execute Rollback

**Option A: Restore from Pre-Migration Backup** (Recommended)

```bash
# Find the backup created before migration
ls -lt /tmp/schema_backup_*.sql | head -5

# Restore from backup
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_YYYYMMDD_HHMMSS.sql

# Verify restoration
psql "$SUPABASE_DB_URL" -c "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='public';"
```

**Option B: Revert Using DOWN Migration** (If available)

Some migrations include a DOWN section for rollback:

```sql
-- UP migration
ALTER TABLE patients ADD COLUMN new_field TEXT;

-- DOWN migration (for rollback)
ALTER TABLE patients DROP COLUMN new_field;
```

If your migration has a DOWN section:

```bash
# Extract DOWN migration
grep -A 999 "-- DOWN" supabase/migrations/20251213120000_*.sql > /tmp/down_migration.sql

# Apply DOWN migration
psql "$SUPABASE_DB_URL" -f /tmp/down_migration.sql
```

**Option C: Manual Rollback** (Last resort)

If no backup and no DOWN migration, manually reverse the changes:

```sql
-- Example: If migration added a column
ALTER TABLE patients DROP COLUMN new_field;

-- Example: If migration created a table
DROP TABLE IF EXISTS new_table;

-- Example: If migration modified a column
ALTER TABLE patients ALTER COLUMN status TYPE TEXT;
```

---

### Step 5: Verify Rollback

```bash
# 1. Run schema validation
python3 scripts/validate_ios_schema.py

# 2. Check table counts
psql "$SUPABASE_DB_URL" -c "
  SELECT schemaname || '.' || tablename as table_name,
         n_tup_ins - n_tup_del as row_count
  FROM pg_stat_user_tables
  WHERE schemaname = 'public'
  ORDER BY tablename;
"

# 3. Test critical queries
psql "$SUPABASE_DB_URL" -c "
  SELECT COUNT(*) FROM patients;
  SELECT COUNT(*) FROM programs;
  SELECT COUNT(*) FROM sessions;
"

# 4. Check foreign key constraints
psql "$SUPABASE_DB_URL" -c "
  SELECT COUNT(*) FROM information_schema.table_constraints
  WHERE constraint_type = 'FOREIGN KEY'
  AND table_schema = 'public';
"
```

**Expected Results:**
- ✅ Schema validation passes
- ✅ All expected tables exist
- ✅ Row counts match pre-migration numbers
- ✅ Foreign keys intact

---

### Step 6: Test Application

After rollback, test the app:

```bash
# Run integration tests
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -only-testing:PTPerformanceTests/CriticalPathTests/testPatientCompleteFlow

# Or test manually:
# 1. Launch app in simulator
# 2. Login as demo patient
# 3. Verify today's session loads
# 4. Log an exercise
# 5. Logout
# 6. Login as therapist
# 7. Verify patient list loads
```

**Pass Criteria:**
- ✅ App launches without crashes
- ✅ Users can log in
- ✅ Critical features work
- ✅ No schema mismatch errors

---

### Step 7: Update Migration Records

```bash
# Mark migration as rolled back
echo "# ROLLED BACK: $(date)" >> supabase/migrations/20251213120000_problematic.sql
mv supabase/migrations/20251213120000_problematic.sql supabase/migrations/ROLLED_BACK_20251213120000_problematic.sql

# Update migration log
echo "$(date): Rolled back migration 20251213120000 due to [reason]" >> .migration_log.txt
```

---

### Step 8: Post-Rollback Communication

**Team Notification:**
```
📢 ROLLBACK COMPLETED

Migration: 20251213120000_create_workload_flags.sql
Reason: Schema mismatch causing app crashes
Rollback Time: 2025-12-15 14:30 PST
Status: ✅ Successful
Impact: App now stable, all features working

Next Steps:
1. Fix migration in separate branch
2. Test migration thoroughly
3. Re-deploy with fix

Linear Issue: ACP-XXX
```

**User Notification (if needed):**
```
We've resolved a technical issue that was affecting the app.
Everything is now working normally. Thank you for your patience!
```

---

## Common Rollback Scenarios

### Scenario 1: Schema Mismatch (Build 44 Issue)

**Problem:** iOS model expects field `flag_type` but database has `severity`

**Symptoms:**
- DecodingError in Sentry
- App crashes when loading workload flags
- "data could not be read" errors

**Rollback Steps:**
```bash
# 1. Restore from backup
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_*.sql

# 2. Verify schema matches iOS models
python3 scripts/validate_ios_schema.py

# 3. Update migration to fix field name
# Edit supabase/migrations/...sql:
ALTER TABLE workload_flags RENAME COLUMN severity TO flag_type;

# 4. Retest migration
python3 scripts/test_migration.py supabase/migrations/...sql

# 5. Reapply fixed migration
supabase migration up
```

---

### Scenario 2: Missing NOT NULL Constraint

**Problem:** Migration made column required but existing data has NULLs

**Symptoms:**
- Migration fails with constraint violation
- Partial migration applied
- Inconsistent schema state

**Rollback Steps:**
```bash
# 1. Rollback to pre-migration state
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_*.sql

# 2. Fix migration to set defaults BEFORE adding constraint
# Edit migration:
UPDATE programs SET target_level = 'Intermediate' WHERE target_level IS NULL;
ALTER TABLE programs ALTER COLUMN target_level SET DEFAULT 'Intermediate';
ALTER TABLE programs ALTER COLUMN target_level SET NOT NULL;

# 3. Test migration
python3 scripts/test_migration.py supabase/migrations/...sql

# 4. Reapply
supabase migration up
```

---

### Scenario 3: Broken Foreign Keys

**Problem:** Migration modified table structure breaking foreign keys

**Symptoms:**
- Cannot insert records
- "foreign key constraint violation" errors
- Relationships broken

**Rollback Steps:**
```bash
# 1. Restore from backup
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_*.sql

# 2. Check foreign key constraints
psql "$SUPABASE_DB_URL" -c "
  SELECT
    tc.table_name,
    tc.constraint_name,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
  FROM information_schema.table_constraints AS tc
  JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
  JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
  WHERE tc.constraint_type = 'FOREIGN KEY';
"

# 3. Fix migration to preserve foreign keys
# Add to migration:
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_phase_id_fkey;
-- Make your changes here
ALTER TABLE sessions ADD CONSTRAINT sessions_phase_id_fkey
  FOREIGN KEY (phase_id) REFERENCES phases(id);
```

---

### Scenario 4: RLS Policies Too Restrictive

**Problem:** Migration updated RLS policies blocking legitimate access

**Symptoms:**
- "permission denied" errors
- Users cannot access their own data
- Therapists cannot view patients

**Rollback Steps:**
```bash
# 1. Quick fix: Temporarily disable RLS (emergency only!)
psql "$SUPABASE_DB_URL" -c "
  ALTER TABLE patients DISABLE ROW LEVEL SECURITY;
  ALTER TABLE programs DISABLE ROW LEVEL SECURITY;
"

# 2. Restore from backup (proper fix)
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_*.sql

# 3. Fix RLS policies in migration
# Test policies carefully before reapplying
```

---

## Preventing Rollback Situations

### Before Every Migration

- [ ] Run `python3 scripts/test_migration.py migration_file.sql`
- [ ] Run `python3 scripts/validate_ios_schema.py`
- [ ] Test migration against staging database first
- [ ] Review migration changes with team
- [ ] Create rollback plan before applying
- [ ] Ensure backup exists and is valid

### During Migration

- [ ] Monitor Sentry for errors
- [ ] Watch application logs
- [ ] Test critical paths immediately
- [ ] Have rollback backup ready
- [ ] Keep team online during deployment

### After Migration

- [ ] Run integration tests
- [ ] Monitor for 1 hour
- [ ] Check Sentry error rate
- [ ] Validate schema
- [ ] Keep backup for 7 days

---

## Backup Management

### Creating Backups

```bash
# Full backup (schema + data)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
pg_dump "$SUPABASE_DB_URL" > /tmp/full_backup_$TIMESTAMP.sql

# Schema only (faster, smaller)
pg_dump "$SUPABASE_DB_URL" --schema-only > /tmp/schema_backup_$TIMESTAMP.sql

# Data only
pg_dump "$SUPABASE_DB_URL" --data-only > /tmp/data_backup_$TIMESTAMP.sql
```

### Restoring Backups

```bash
# Restore full backup
psql "$SUPABASE_DB_URL" < /tmp/full_backup_YYYYMMDD_HHMMSS.sql

# Restore schema only
psql "$SUPABASE_DB_URL" < /tmp/schema_backup_YYYYMMDD_HHMMSS.sql

# Restore specific table
pg_restore --table=patients "$SUPABASE_DB_URL" < /tmp/patients_backup.sql
```

### Backup Retention

- **Keep all backups for 7 days after migration**
- **Keep weekly backups for 30 days**
- **Keep monthly backups for 1 year**
- **Delete backups older than retention policy**

```bash
# Cleanup old backups (older than 7 days)
find /tmp -name "schema_backup_*.sql" -mtime +7 -delete
```

---

## Emergency Contacts

**During rollback emergency:**

1. **Primary:** Tech Lead (check team roster)
2. **Secondary:** DevOps (if database access issues)
3. **Escalation:** CTO (if data loss risk)

**Channels:**
- #pt-performance-alerts (Slack)
- #incidents (for major issues)
- Linear: Create issue with label `critical`

---

## Related Documentation

- [Migration Testing Guide](./MIGRATION_TESTING.md)
- [Schema Validation Guide](./SCHEMA_VALIDATION.md)
- [Integration Testing Guide](./INTEGRATION_TESTING.md)

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 3 (Migration Testing Engineer)
