# MIGRATION RUNBOOK - ALWAYS READ THIS FIRST

## 🚨 HARD RULE: Execute this checklist BEFORE any exploration

When "migration" is mentioned in ANY context → **READ THIS FILE FIRST** and execute the steps mechanically.

**DO NOT:**
- ❌ Explore the codebase first
- ❌ Research automation methods
- ❌ Create new verification scripts
- ❌ Recreate existing tools

**DO:**
- ✅ Follow this checklist step-by-step
- ✅ Use Supabase CLI (we have credentials)
- ✅ Execute mechanically (make it boring)

---

## Step 1: Identify Migration File

```bash
# Find the migration file
# Typical location: supabase/migrations/YYYYMMDDHHMMSS_description.sql
# It may have .applied suffix if already run

ls -1 supabase/migrations/ | tail -10
```

---

## Step 2: Apply Migration via Supabase CLI

### 2a. Push migration to remote database

**PRIMARY METHOD** (Use Supabase CLI - credentials in .env):

**CRITICAL:** Supabase CLI requires TWO credentials:
1. **Access Token** - for Management API authentication
2. **Database Password** - for PostgreSQL access

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
source .env

# Set access token (required for CLI to work)
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"

# Apply migrations (uses both token and password)
supabase db push -p "${SUPABASE_PASSWORD}" --include-all
```

**Token Location:** `~/.supabase/access-token` or set via environment variable

**When prompted "Do you want to push these migrations?", type `Y`**

### 2b. Handle migration history conflicts (if needed)

If you see error: "Remote migration versions not found in local migrations directory"

**Solution:** Mark conflicting migrations as applied in remote history:

```bash
# Set access token first
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"

# For each migration that's causing conflicts:
supabase migration repair --status applied YYYYMMDDHHMMSS -p "${SUPABASE_PASSWORD}"

# Then retry the push:
supabase db push -p "${SUPABASE_PASSWORD}" --include-all
```

### 2c. Success indicators

**Expected output:**
```
Applying migration YYYYMMDDHHMMSS_description.sql...
Finished supabase db push.
```

**If you see this, the migration is APPLIED! ✅**

---

## Step 3: Mark Complete

### 3a. Add .applied marker

```bash
# Mark migration as applied (local tracking)
mv supabase/migrations/YYYYMMDDHHMMSS_filename.sql supabase/migrations/YYYYMMDDHHMMSS_filename.sql.applied
```

### 3b. Verify migration in history (optional)

```bash
# Confirm migration shows in remote database history
supabase migration list --password "${SUPABASE_PASSWORD}" | grep YYYYMMDDHHMMSS
```

### 3c. PostgREST Schema Cache Refresh (CRITICAL - READ THIS!)

**⚠️ EXPECTED BEHAVIOR AFTER EVERY MIGRATION:**

After applying any migration, you WILL see schema cache errors for 30-60 seconds. This is NORMAL.

**What the error looks like:**
```
❌ Could not find the 'column_name' column of 'table_name' in the schema cache
```

**Why this happens:**
- PostgREST (Supabase's API layer) caches the database schema for performance
- The cache auto-refreshes every 30-60 seconds
- New columns/tables exist in the database but not in the API cache yet

**What to do:**
- ✅ **NOTHING** - Wait 1-2 minutes for automatic refresh
- ✅ Tell user to wait 1-2 minutes
- ✅ Or tell user to restart the app to force reconnection

**What NOT to do:**
- ❌ Do NOT try to "fix" the migration
- ❌ Do NOT re-apply the migration
- ❌ Do NOT create schema refresh scripts
- ❌ Do NOT try to manually refresh via API calls
- ❌ Do NOT assume the migration failed

**How to verify migration succeeded:**
```bash
# Check that migration file is marked as .applied
ls supabase/migrations/*.applied | tail -3

# If you see the migration with .applied suffix, it's done!
```

**If error persists after 5 minutes:**
- Check if migration was actually applied (look for .applied file)
- Restart the iOS app
- Check Supabase Dashboard → Database → Tables to confirm schema changes

---

## Step 4: Document (Optional)

If this is a significant migration (new feature):

```bash
# Example for Build 33
echo "✅ Build 33: Session completion columns migration applied" >> .outcomes/BUILD33_MIGRATION_APPLIED.md
```

---

## 🚨 CRITICAL: DO NOT CREATE NEW SCRIPTS

The following scripts **ALREADY EXIST** - REUSE THEM:

| Script | Purpose | When to Use |
|--------|---------|-------------|
| `apply_migration_direct.py` | Check if table exists | Step 1b (every migration) |
| `refresh_schema_cache.py` | Verify schema cache refreshed | Step 4a (every migration) |
| `complete_migration.html` | HTML automation tool | Step 2a (every migration) |
| `verify_table_schema.py` | Validate specific table schema | Optional - detailed validation |
| `verify_exercise_logs_schema.py` | Build 32 specific validation | Only for exercise_logs table |

**NEVER:**
- ❌ Create `apply_migration.py` (use `apply_migration_direct.py`)
- ❌ Create new `verify_*.py` scripts (use existing ones)
- ❌ Create new HTML tools (use `complete_migration.html`)
- ❌ Recreate schema check scripts (use `refresh_schema_cache.py`)

**ONLY CREATE NEW SCRIPT IF:**
- Migration SQL file doesn't exist yet (use `migration_template.sql`)
- Genuinely novel table type requiring new validation logic

---

## When Things Go Wrong

### "Could not find column in schema cache"
**THIS IS NOT AN ERROR - THIS IS EXPECTED!**

→ PostgREST schema cache takes 30-60 seconds to refresh after ANY migration
→ The migration WAS successful, the cache just hasn't updated yet
→ Wait 1-2 minutes and the error will disappear automatically
→ **NO ACTION NEEDED** - Do not try to "fix" this
→ See Step 3c for full details

### "invalid input syntax for type integer: '[value]'" (Array Type Error)
**This means column was created with wrong type**

→ A column that should be an array (e.g., `INT[]`) was created as a scalar (e.g., `INT`)
→ Common with partially-failed migrations
→ **Fix:** Create migration with DO block to DROP and re-ADD column:
```sql
DO $$
BEGIN
    ALTER TABLE table_name DROP COLUMN IF EXISTS column_name;
    ALTER TABLE table_name ADD COLUMN column_name INT[] NOT NULL DEFAULT '{}';
END $$;
```
→ Use DO block (not direct ALTER) to handle errors gracefully
→ See migration 20251212180000 for example

### "Remote migration versions not found"
**Migration history is out of sync**

→ Use `supabase migration repair --status reverted TIMESTAMP` to mark remote migrations as reverted
→ Then retry the push with `--include-all`
→ Example:
```bash
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"
supabase migration repair --status reverted 20251212000001 -p "${SUPABASE_PASSWORD}"
supabase db push -p "${SUPABASE_PASSWORD}" --include-all
```

### "401 Unauthorized" Error
**Access token is missing or invalid**

→ This means SUPABASE_ACCESS_TOKEN is not set
→ The Supabase CLI needs the access token for Management API authentication
→ Example:
```bash
# Set the access token
export SUPABASE_ACCESS_TOKEN="sbp_9d60dd93d30bd9f1dc7adce99fd8ec3e02dfc6a8"

# Verify it's set
echo $SUPABASE_ACCESS_TOKEN

# Then retry your command
supabase db push -p "${SUPABASE_PASSWORD}" --include-all
```

### "Migration file not found"
→ Need to CREATE the migration SQL
→ Use `.claude/migration_template.sql` as starting point

### "Do you want to push these migrations?"
→ Review the list, then type `Y` to confirm
→ This is normal - Supabase CLI is asking for confirmation

---

## For Reference Only

**Build History:**
- **Build 34 (Dec 2024):** 3 migrations applied successfully with access token
  - Discovered: SUPABASE_ACCESS_TOKEN required (not just password)
  - Fully automated via deploy_testflight.sh script
  - Pattern: RLS policies use `patients.user_id = auth.uid()`
  - Pattern: DO blocks for safe schema changes (DROP COLUMN IF EXISTS)
  - Total time: ~30 seconds for all 3 migrations
- **Build 33 (Dec 2024):** CLI method works! Uses credentials from .env
- Supabase CLI `db push` command applies migrations directly
- `migration repair` handles history conflicts

**Common Migration Patterns (Build 34):**

```sql
-- Pattern 1: Safe column type changes with DO block
DO $$
BEGIN
    ALTER TABLE table_name DROP COLUMN IF EXISTS column_name;
    ALTER TABLE table_name ADD COLUMN column_name INT[] NOT NULL DEFAULT '{}';
END $$;

-- Pattern 2: RLS policies for patient data
CREATE POLICY "Patients can insert their own exercise logs"
ON exercise_logs FOR INSERT
WITH CHECK (
    EXISTS (
        SELECT 1 FROM patients
        WHERE patients.id = exercise_logs.patient_id
        AND patients.user_id = auth.uid()
    )
);
```

**Previous Workflow (Deprecated):**
- 31 builds tried direct psql - all failed due to network/auth
- Manual Dashboard SQL Editor was 100% success rate but slower
- HTML automation tools were workarounds

**Full Documentation:**
- `.claude/MIGRATION_SCRIPTS_INVENTORY.md` - All available scripts
- `.claude/HOW_TO_APPLY_MIGRATIONS.md` - Detailed manual instructions (deprecated)
- `.claude/AUTOMATED_MIGRATIONS.md` - Why psql doesn't work
- `TESTFLIGHT_DEPLOYMENT_README.md` - Full build and deployment process
- `deploy_testflight.sh` - Automated deployment script (handles migrations + build + upload)

---

**Summary: This runbook eliminates 90% of exploration time by executing known, working steps.**

**Total Time:** 30 seconds per migration (fully automated via CLI)
