# Audit Database Schema

Compare local migrations against remote database schema to detect drift.

## Trigger

```
/audit-schema
```

**Examples:**
- `/audit-schema` - Full schema comparison
- `/audit-schema --table patients` - Specific table
- `/audit-schema --fix` - Generate fix migrations

## Prerequisites

1. Supabase CLI installed
2. Database access configured
3. Local migrations in `supabase/migrations/`

## Execution Steps

### Phase 1: Get Remote Schema

```bash
# Pull remote schema
supabase db pull --schema public > remote-schema.sql

# Or query directly
psql "$DATABASE_URL" -c "
  SELECT
    table_name,
    column_name,
    data_type,
    is_nullable,
    column_default
  FROM information_schema.columns
  WHERE table_schema = 'public'
  ORDER BY table_name, ordinal_position;
" > remote-columns.txt
```

### Phase 2: Get Local Schema

```bash
# Apply all local migrations to diff database
supabase db reset --linked

# Or parse migration files
cat supabase/migrations/*.sql | \
  grep -E "CREATE TABLE|ALTER TABLE|ADD COLUMN" > local-changes.txt
```

### Phase 3: Compare Schemas

```sql
-- Find columns in remote but not expected
SELECT
  r.table_name,
  r.column_name,
  'Missing locally' as status
FROM remote_schema r
LEFT JOIN expected_schema e
  ON r.table_name = e.table_name
  AND r.column_name = e.column_name
WHERE e.column_name IS NULL;

-- Find columns expected but not in remote
SELECT
  e.table_name,
  e.column_name,
  'Missing remotely' as status
FROM expected_schema e
LEFT JOIN remote_schema r
  ON e.table_name = r.table_name
  AND e.column_name = r.column_name
WHERE r.column_name IS NULL;
```

### Phase 4: Check RLS Policies

```sql
-- Compare expected vs actual policies
SELECT
  tablename,
  policyname,
  CASE
    WHEN expected THEN 'OK'
    ELSE 'MISSING'
  END as status
FROM policy_check;
```

### Phase 5: Check Indexes

```sql
-- Find missing indexes
SELECT
  schemaname,
  tablename,
  indexname
FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
```

### Phase 6: Generate Report

```markdown
# Schema Audit Report

**Date:** 2025-01-30
**Remote:** rpbxeaxlaoyoqkohytlw.supabase.co
**Local Migrations:** 45 files

---

## Summary

| Check | Status |
|-------|--------|
| Tables | 32/32 match |
| Columns | 245/248 match |
| Indexes | 18/20 match |
| RLS Policies | 45/45 match |
| Functions | 12/12 match |

---

## Discrepancies

### Missing Columns (Remote has, Local missing)

| Table | Column | Type |
|-------|--------|------|
| sessions | legacy_id | uuid |
| patients | imported_at | timestamp |

*Action: These may be from direct DB edits. Create migration to add.*

### Missing Indexes

| Table | Columns | Status |
|-------|---------|--------|
| sessions | patient_id, scheduled_date | MISSING |
| pain_logs | patient_id, date | MISSING |

*Action: Add indexes for query performance.*

---

## Recommendations

1. Create migration for missing columns
2. Add performance indexes
3. Document any intentional differences
```

### Phase 7: Generate Fix Migration (Optional)

```sql
-- supabase/migrations/[timestamp]_schema_sync.sql

-- Add missing columns
ALTER TABLE sessions
ADD COLUMN IF NOT EXISTS legacy_id UUID;

ALTER TABLE patients
ADD COLUMN IF NOT EXISTS imported_at TIMESTAMP;

-- Add missing indexes
CREATE INDEX IF NOT EXISTS idx_sessions_patient_date
ON sessions(patient_id, scheduled_date);

CREATE INDEX IF NOT EXISTS idx_pain_logs_patient_date
ON pain_logs(patient_id, date);
```

## Output

```
Schema Audit Complete

Tables: 32/32 match
Columns: 245/248 (3 differences)
Indexes: 18/20 (2 missing)
RLS: 45/45 match

Discrepancies Found:

Columns:
- sessions.legacy_id (remote only)
- patients.imported_at (remote only)
- exercises.video_duration (local only)

Indexes:
- idx_sessions_patient_date (missing)
- idx_pain_logs_patient_date (missing)

Fix migration generated:
supabase/migrations/20250130_schema_sync.sql

Run /deploy to apply fixes.
```

## Reference

- `supabase/migrations/` - Local migration files
- `.claude/MIGRATION_RUNBOOK.md` - Migration procedures
- Supabase Dashboard: Database > Schema
