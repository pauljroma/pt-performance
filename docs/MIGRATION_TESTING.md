# Migration Testing Guide

**Purpose:** Comprehensive guide for testing database migrations before applying them to production.

**Context:** Build 44 had schema mismatches that reached production. This guide ensures all migrations are thoroughly tested before deployment.

---

## Quick Start

### Test a Migration

```bash
# Test migration (dry run)
python3 scripts/test_migration.py supabase/migrations/20251213120000_fix_workload_flags.sql

# Test migration with rollback validation
python3 scripts/test_migration.py supabase/migrations/20251213120000_fix_workload_flags.sql --rollback-test
```

### Expected Output (Success)

```
================================================================================
Migration Test: 20251213120000_fix_workload_flags.sql
================================================================================

Testing migration syntax...
✅ Migration syntax OK

Creating schema backup...
✅ Schema backed up to: /tmp/schema_backup_20251215_143022.sql

Pre-migration table counts:
  public.patients: 5 rows
  public.programs: 3 rows
  public.workload_flags: 0 rows

Applying migration: 20251213120000_fix_workload_flags.sql
✅ Migration applied successfully

Validating schema integrity...
  ✅ Check foreign key constraints
  ✅ Check primary key constraints
  ✅ Check for broken foreign keys

Running schema validation...
✅ Schema validation passed

Post-migration table counts:
  public.patients: 5 rows
  public.programs: 3 rows
  public.workload_flags: 0 rows

================================================================================
Migration Test Report
================================================================================

Migration: 20251213120000_fix_workload_flags.sql
Tested at: 2025-12-15 14:30:22

Results:
  ✅ Syntax validation passed
  ✅ Schema backup created
  ✅ Migration applied successfully
  ✅ Schema integrity validated
  ✅ iOS schema validation passed

================================================================================

✅ All migration tests passed!
```

---

## How It Works

### Test Flow

```
1. Syntax Validation
   ↓
2. Create Schema Backup
   ↓
3. Record Pre-Migration State
   ↓
4. Apply Migration
   ↓
5. Validate Schema Integrity
   ↓
6. Run iOS Schema Validation
   ↓
7. Compare Pre/Post State
   ↓
8. [Optional] Test Rollback
   ↓
9. Generate Report
```

---

## Migration Testing Checklist

### Before Writing Migration

- [ ] Understand what needs to change
- [ ] Check current schema state
- [ ] Review iOS models for compatibility
- [ ] Plan rollback strategy

### While Writing Migration

- [ ] Use descriptive migration file names
- [ ] Add comments explaining changes
- [ ] Include data migrations if needed
- [ ] Consider backwards compatibility
- [ ] Plan for zero-downtime deployment

### Before Applying Migration

- [ ] Test migration locally
- [ ] Run schema validation
- [ ] Test against staging database
- [ ] Review with team
- [ ] Create backup plan

### After Applying Migration

- [ ] Verify schema matches iOS models
- [ ] Run integration tests
- [ ] Monitor Sentry for errors
- [ ] Keep backup for 7 days

---

## Writing Safe Migrations

### Migration File Naming

```
Format: YYYYMMDDHHMMSS_description.sql

Examples:
✅ 20251213120000_add_workload_flags_table.sql
✅ 20251213130000_fix_session_exercises_nullable.sql
❌ fix_bug.sql (no timestamp)
❌ 20251213_migration.sql (incomplete timestamp)
```

### Migration Structure

```sql
-- Migration: Add workload_flags table
-- Date: 2025-12-13
-- Author: Build 45 Swarm
-- Description: Creates workload_flags table for tracking patient overtraining

-- ============================================================================
-- UP Migration
-- ============================================================================

BEGIN;

-- Create table
CREATE TABLE IF NOT EXISTS workload_flags (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    patient_id UUID NOT NULL REFERENCES patients(id) ON DELETE CASCADE,
    flag_type TEXT NOT NULL CHECK (flag_type IN ('yellow', 'red')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    resolved_at TIMESTAMPTZ,
    notes TEXT
);

-- Create index
CREATE INDEX idx_workload_flags_patient_id ON workload_flags(patient_id);
CREATE INDEX idx_workload_flags_unresolved ON workload_flags(patient_id) WHERE resolved_at IS NULL;

-- Add RLS policies
ALTER TABLE workload_flags ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Therapists can view all flags"
    ON workload_flags FOR SELECT
    USING (auth.role() = 'therapist');

CREATE POLICY "Patients can view their own flags"
    ON workload_flags FOR SELECT
    USING (patient_id = auth.uid());

COMMIT;

-- ============================================================================
-- DOWN Migration (for rollback)
-- ============================================================================

-- Uncomment to enable rollback:
-- BEGIN;
-- DROP TABLE IF EXISTS workload_flags CASCADE;
-- COMMIT;
```

### Best Practices

**1. Always Use Transactions**

```sql
-- ✅ GOOD - Wrapped in transaction
BEGIN;
ALTER TABLE patients ADD COLUMN sport TEXT;
ALTER TABLE patients ADD COLUMN position TEXT;
COMMIT;

-- ❌ BAD - No transaction (partial failure possible)
ALTER TABLE patients ADD COLUMN sport TEXT;
ALTER TABLE patients ADD COLUMN position TEXT;
```

**2. Handle Existing Data**

```sql
-- ✅ GOOD - Set defaults before adding constraint
UPDATE programs SET target_level = 'Intermediate' WHERE target_level IS NULL;
ALTER TABLE programs ALTER COLUMN target_level SET DEFAULT 'Intermediate';
ALTER TABLE programs ALTER COLUMN target_level SET NOT NULL;

-- ❌ BAD - Will fail if any NULL values exist
ALTER TABLE programs ALTER COLUMN target_level SET NOT NULL;
```

**3. Use IF EXISTS / IF NOT EXISTS**

```sql
-- ✅ GOOD - Idempotent (can run multiple times)
CREATE TABLE IF NOT EXISTS workload_flags (...);
DROP TABLE IF EXISTS old_table CASCADE;

-- ❌ BAD - Will fail if table exists/doesn't exist
CREATE TABLE workload_flags (...);
DROP TABLE old_table;
```

**4. Preserve Foreign Keys**

```sql
-- ✅ GOOD - Preserve relationships
ALTER TABLE sessions DROP CONSTRAINT IF EXISTS sessions_phase_id_fkey;
-- Make your changes
ALTER TABLE sessions ADD CONSTRAINT sessions_phase_id_fkey
    FOREIGN KEY (phase_id) REFERENCES phases(id) ON DELETE CASCADE;

-- ❌ BAD - Breaks relationships
ALTER TABLE sessions ALTER COLUMN phase_id TYPE TEXT;
```

**5. Test Constraints**

```sql
-- ✅ GOOD - Test constraint is valid
ALTER TABLE workload_flags ADD CONSTRAINT flag_type_check
    CHECK (flag_type IN ('yellow', 'red'));

-- Verify constraint works:
-- INSERT INTO workload_flags (flag_type) VALUES ('invalid'); -- Should fail

-- ❌ BAD - No validation of constraint
ALTER TABLE workload_flags ADD CONSTRAINT flag_type_check
    CHECK (flag_type IN ('yello', 'red')); -- Typo!
```

---

## Testing Strategies

### 1. Local Testing

Test against local Supabase instance:

```bash
# Start local Supabase
supabase start

# Set local database URL
export SUPABASE_DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

# Test migration
python3 scripts/test_migration.py supabase/migrations/20251213120000_*.sql

# Run schema validation
python3 scripts/validate_ios_schema.py
```

**Advantages:**
- Fast iteration
- No risk to shared databases
- Can test rollback destructively

---

### 2. Staging Database Testing

Test against staging (shared test environment):

```bash
# Set staging database URL
export SUPABASE_DB_URL="postgresql://user:pass@staging-host:5432/postgres"

# Test migration
python3 scripts/test_migration.py supabase/migrations/20251213120000_*.sql

# Run integration tests
xcodebuild test \
  -project ios-app/PTPerformance.xcodeproj \
  -scheme PTPerformance \
  -only-testing:PTPerformanceTests/CriticalPathTests
```

**Advantages:**
- More realistic data
- Tests with production-like volume
- Validates with real auth setup

**Caution:**
- Coordinate with team (shared environment)
- Don't test destructive operations
- Keep staging data clean

---

### 3. Production-Like Testing

Test with production data snapshot:

```bash
# 1. Create production data snapshot (read-only)
pg_dump "$PRODUCTION_DB_URL" > /tmp/prod_snapshot.sql

# 2. Restore to test database
psql "$TEST_DB_URL" < /tmp/prod_snapshot.sql

# 3. Test migration against production-like data
export SUPABASE_DB_URL="$TEST_DB_URL"
python3 scripts/test_migration.py supabase/migrations/20251213120000_*.sql

# 4. Run full test suite
xcodebuild test -project ios-app/PTPerformance.xcodeproj -scheme PTPerformance
```

**Advantages:**
- Most realistic testing
- Catches edge cases in real data
- Validates performance at scale

**Caution:**
- Sanitize sensitive data
- Don't use production URLs
- Large data takes time

---

## Migration Testing Script

### Usage

```bash
# Basic test
python3 scripts/test_migration.py supabase/migrations/MIGRATION_FILE.sql

# With verbose output
python3 scripts/test_migration.py supabase/migrations/MIGRATION_FILE.sql --verbose

# With rollback test (destructive!)
python3 scripts/test_migration.py supabase/migrations/MIGRATION_FILE.sql --rollback-test
```

### What It Tests

**1. Syntax Validation**
- Migration file exists and is readable
- SQL syntax is valid
- Detects dangerous operations (DROP DATABASE, TRUNCATE)

**2. Schema Backup**
- Creates backup before migration
- Verifies backup was created successfully
- Stores backup for rollback

**3. Migration Application**
- Applies migration to database
- Checks for errors
- Records pre/post state

**4. Schema Integrity**
- Validates foreign key constraints
- Checks primary key constraints
- Ensures referential integrity

**5. iOS Schema Validation**
- Runs `validate_ios_schema.py`
- Checks Swift models match database
- Detects schema mismatches

**6. Data Integrity**
- Compares pre/post row counts
- Flags unexpected data changes
- Validates relationships

**7. Rollback Testing** (Optional)
- Tests restoration from backup
- Validates rollback succeeded
- Reapplies migration after rollback

---

## Common Migration Issues

### Issue 1: NULL Values in NOT NULL Column

**Error:**
```
ERROR: column "target_level" contains null values
```

**Cause:** Adding NOT NULL constraint when data has NULLs

**Fix:**
```sql
-- Set default for existing NULL values
UPDATE programs SET target_level = 'Intermediate' WHERE target_level IS NULL;

-- Add default for future inserts
ALTER TABLE programs ALTER COLUMN target_level SET DEFAULT 'Intermediate';

-- Now safe to add NOT NULL
ALTER TABLE programs ALTER COLUMN target_level SET NOT NULL;
```

---

### Issue 2: Schema Mismatch After Migration

**Error:**
```
DecodingError.keyNotFound: flag_type
```

**Cause:** Database column name doesn't match Swift CodingKeys

**Fix:**
```swift
// In WorkloadFlag.swift
enum CodingKeys: String, CodingKey {
    case flagType = "flag_type"  // ✅ Match database column name
    // NOT: case flagType = "severity"
}
```

Or rename column in migration:
```sql
ALTER TABLE workload_flags RENAME COLUMN severity TO flag_type;
```

---

### Issue 3: Foreign Key Constraint Violation

**Error:**
```
ERROR: insert or update on table "sessions" violates foreign key constraint
```

**Cause:** Referenced record doesn't exist or was deleted

**Fix:**
```sql
-- Add ON DELETE CASCADE to handle deletions
ALTER TABLE sessions DROP CONSTRAINT sessions_phase_id_fkey;
ALTER TABLE sessions ADD CONSTRAINT sessions_phase_id_fkey
    FOREIGN KEY (phase_id) REFERENCES phases(id) ON DELETE CASCADE;
```

---

### Issue 4: Enum Value Mismatch

**Error:**
```
ERROR: invalid input value for enum flag_type: "high"
```

**Cause:** Enum constraint doesn't match Swift enum

**Fix:**
```sql
-- Option 1: Update data to match Swift enum
UPDATE workload_flags
SET flag_type = CASE
    WHEN flag_type = 'high' THEN 'red'
    WHEN flag_type IN ('medium', 'low') THEN 'yellow'
END;

-- Option 2: Update constraint
ALTER TABLE workload_flags DROP CONSTRAINT flag_type_check;
ALTER TABLE workload_flags ADD CONSTRAINT flag_type_check
    CHECK (flag_type IN ('yellow', 'red'));
```

---

### Issue 5: RLS Policy Too Restrictive

**Error:**
```
ERROR: permission denied for table patients
```

**Cause:** RLS policy blocks legitimate access

**Fix:**
```sql
-- Review policy
SELECT * FROM pg_policies WHERE tablename = 'patients';

-- Fix policy (example: allow patients to view their own data)
DROP POLICY IF EXISTS "Patients can view own data" ON patients;

CREATE POLICY "Patients can view own data"
    ON patients FOR SELECT
    USING (id = auth.uid() OR therapist_id = auth.uid());
```

---

## CI/CD Integration

### GitHub Actions

Migrations are tested automatically in CI:

```yaml
# .github/workflows/migration-test.yml
name: Migration Test

on:
  pull_request:
    paths:
      - 'supabase/migrations/**'

jobs:
  test-migration:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Setup Python
        uses: actions/setup-python@v5
        with:
          python-version: '3.11'

      - name: Install PostgreSQL client
        run: sudo apt-get install -y postgresql-client

      - name: Test migration
        env:
          SUPABASE_DB_URL: ${{ secrets.SUPABASE_STAGING_URL }}
        run: |
          python3 scripts/test_migration.py supabase/migrations/*.sql
```

---

## Migration Approval Process

### Before Merging PR

1. **Developer creates migration**
   - Writes migration SQL
   - Tests locally
   - Runs `test_migration.py`
   - Runs `validate_ios_schema.py`

2. **CI tests migration**
   - Syntax validation passes
   - Schema validation passes
   - Integration tests pass

3. **Team reviews PR**
   - Migration logic is sound
   - No destructive operations
   - Rollback plan exists
   - Schema matches iOS models

4. **Merge to main**
   - All checks passed
   - Approved by reviewer
   - Ready for staging deployment

### Before Production Deployment

1. **Deploy to staging**
   - Apply migration to staging
   - Run full integration test suite
   - Monitor for 1 hour

2. **Validate staging**
   - No errors in Sentry
   - All features working
   - Performance acceptable

3. **Create production plan**
   - Schedule deployment window
   - Prepare rollback procedure
   - Alert team

4. **Deploy to production**
   - Apply migration
   - Monitor actively for 1 hour
   - Keep rollback ready

---

## Related Documentation

- [Migration Rollback Guide](./MIGRATION_ROLLBACK.md)
- [Schema Validation Guide](./SCHEMA_VALIDATION.md)
- [Integration Testing Guide](./INTEGRATION_TESTING.md)

---

**Last Updated:** 2025-12-15 (Build 45)
**Owner:** Build 45 Swarm Agent 3 (Migration Testing Engineer)
