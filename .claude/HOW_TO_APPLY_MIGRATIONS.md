# ⚠️ STOP - READ MIGRATION_RUNBOOK.md FIRST

**If you're here because of a migration task:**

→ **Read: `.claude/MIGRATION_RUNBOOK.md`** (Executable checklist - READ FIRST)

This file (HOW_TO_APPLY_MIGRATIONS.md) is **REFERENCE ONLY** for detailed manual instructions. The **RUNBOOK** has the executable steps.

---

# Quick Reference Checklist

Use this checklist for every migration:

- [ ] Migration file: `supabase/migrations/YYYYMMDDHHMMSS_*.sql`
- [ ] Pre-flight: `python3 apply_migration_direct.py`
- [ ] Application: Open `complete_migration.html` OR use Dashboard SQL Editor
- [ ] Verification: `python3 refresh_schema_cache.py`
- [ ] Mark complete: Add `.applied` suffix to filename
- [ ] Update Linear: "✅ Migration applied, Build X ready"

**Time:** 2-3 minutes per migration

---

# How to Apply Supabase Migrations

## Problem

Network restrictions block direct database connections from this environment:
- IPv6 routing blocked
- Connection pooler authentication fails
- Direct PostgreSQL connections refused

## Solution: Use Supabase Dashboard SQL Editor

This is the **standard workflow** for applying migrations. It's fast (1 minute) and reliable.

---

## Standard Workflow for Every Migration

### Step 1: Create Migration File

When code changes require database schema updates, Claude creates a migration file:

**Location:** `supabase/migrations/YYYYMMDDHHMMSS_description.sql`

**Example:** `20251212000001_create_exercise_logs_table.sql`

### Step 2: Apply via Supabase Dashboard

1. **Open SQL Editor:**
   - Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new
   - Or navigate: Dashboard → SQL Editor → New Query

2. **Copy Migration SQL:**
   ```bash
   # From terminal
   cat supabase/migrations/20251212000001_create_exercise_logs_table.sql | pbcopy
   ```
   - Or open file in editor and copy contents

3. **Paste and Run:**
   - Paste SQL into editor
   - Click "Run" button
   - Confirm success message

4. **Verify:**
   - Check Table Editor for new table
   - Or run: `SELECT * FROM information_schema.tables WHERE table_name = 'exercise_logs';`

### Step 3: Document in Linear

Update the Linear issue with:
- ✅ Migration applied
- Table name and purpose
- Build number ready to test

---

## Why This Workflow?

### ❌ Blocked Methods:
- `supabase db push` - Requires login token / network blocked
- `psql` direct connection - IPv6 routing issues
- Python `psycopg2` - Connection pooler auth fails
- Supabase REST API - Doesn't support DDL operations

### ✅ Working Method:
- **Supabase Dashboard SQL Editor** - Always works, web-based, no network restrictions

---

## Migration File Naming Convention

Format: `YYYYMMDDHHMMSS_description.sql`

Examples:
- `20251212000001_create_exercise_logs_table.sql`
- `20251212120000_add_readiness_score_column.sql`
- `20251213000001_create_patient_flags_table.sql`

---

## Migration Template

```sql
-- Migration: [Brief description]
-- Date: YYYY-MM-DD
-- Purpose: [Detailed explanation of why this change is needed]

-- Create table / alter table / add column / etc.
CREATE TABLE IF NOT EXISTS table_name (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    -- columns...
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_table_column ON table_name(column);

-- RLS Policies
ALTER TABLE table_name ENABLE ROW LEVEL SECURITY;

CREATE POLICY "policy_name" ON table_name
    FOR SELECT
    USING (patient_id = auth.uid());

-- Grants
GRANT SELECT, INSERT ON table_name TO authenticated;

-- Comment
COMMENT ON TABLE table_name IS 'Description of table purpose';
```

---

## Common Migration Patterns

### Adding a New Table

```sql
CREATE TABLE IF NOT EXISTS new_table (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    foreign_key_id UUID NOT NULL REFERENCES other_table(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_new_table_fk ON new_table(foreign_key_id);

ALTER TABLE new_table ENABLE ROW LEVEL SECURITY;

CREATE POLICY "new_table_select" ON new_table
    FOR SELECT
    USING (true);  -- Adjust as needed
```

### Adding a Column

```sql
ALTER TABLE existing_table
ADD COLUMN IF NOT EXISTS new_column TEXT;

-- Add index if needed
CREATE INDEX IF NOT EXISTS idx_existing_new_column ON existing_table(new_column);
```

### Adding RLS Policy

```sql
CREATE POLICY "new_policy_name" ON table_name
    FOR INSERT
    WITH CHECK (patient_id = auth.uid());
```

---

## Current Migration (Build 32)

**File:** `supabase/migrations/20251212000001_create_exercise_logs_table.sql`

**Purpose:** Create `exercise_logs` table for patient exercise logging

**Status:** ⏳ Pending application via dashboard

**After applying:** Build 32 will be fully functional for exercise logging

---

## Future Automation

When network restrictions are lifted, we can automate with:

```bash
# Method 1: Supabase CLI (requires login)
supabase db push --linked --include-all

# Method 2: psql (requires direct connection)
PGPASSWORD="password" psql -h db.project.supabase.co -U postgres -d postgres -f migration.sql

# Method 3: Python script (requires psycopg2 access)
python3 apply_migration.py
```

Until then: **Use Supabase Dashboard SQL Editor** (1 minute, always works)

---

## Troubleshooting

### "Table already exists"
- Migration has `IF NOT EXISTS` - safe to re-run
- Or comment out CREATE TABLE and run remaining statements

### "Policy already exists"
- Use `DROP POLICY IF EXISTS policy_name ON table_name;` before CREATE POLICY
- Or skip policy creation if already exists

### "Permission denied"
- Ensure you're logged in as project owner/admin
- Check RLS policies aren't blocking the operation

### "Relation does not exist"
- Check foreign key references point to existing tables
- Verify table names match exactly (case-sensitive)

---

## Best Practices

1. **Always use `IF NOT EXISTS`** - Makes migrations idempotent
2. **Test locally first** - Use Supabase local development if available
3. **Document why** - Add comments explaining the purpose
4. **Atomic operations** - Keep related changes in one migration
5. **Rollback plan** - Include DROP statements (commented out) for easy rollback

---

## Rollback

If migration causes issues, create a rollback migration:

```sql
-- Rollback: Remove exercise_logs table
-- Date: 2025-12-12
-- Reverts: 20251212000001_create_exercise_logs_table.sql

DROP TABLE IF EXISTS exercise_logs CASCADE;
```

---

**Remember:** Dashboard SQL Editor is the standard, reliable method for all migrations in this environment.
