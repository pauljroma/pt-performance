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

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
source .env
supabase db push --password "${SUPABASE_PASSWORD}" --include-all
```

**When prompted "Do you want to push these migrations?", type `Y`**

### 2b. Handle migration history conflicts (if needed)

If you see error: "Remote migration versions not found in local migrations directory"

**Solution:** Mark conflicting migrations as applied in remote history:

```bash
# For each migration that's causing conflicts:
supabase migration repair --status applied YYYYMMDDHHMMSS --password "${SUPABASE_PASSWORD}"

# Then retry the push:
supabase db push --password "${SUPABASE_PASSWORD}" --include-all
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

### 3c. Schema cache note

**Important:** PostgREST schema cache takes 30-60 seconds to refresh automatically.

If you see "Could not find column in schema cache" errors in the app:
- Wait 1-2 minutes
- The cache updates automatically
- No action needed

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
→ Expected! Schema cache takes 30-60 seconds to refresh
→ Wait 1-2 minutes and test again
→ No action needed

### "Remote migration versions not found"
→ Use `supabase migration repair --status applied TIMESTAMP`
→ Then retry the push

### "Migration file not found"
→ Need to CREATE the migration SQL
→ Use `.claude/migration_template.sql` as starting point

### "Do you want to push these migrations?"
→ Review the list, then type `Y` to confirm
→ This is normal - Supabase CLI is asking for confirmation

---

## For Reference Only

**Why This Workflow?**
- **Build 33 (Dec 2024):** CLI method works! Uses credentials from .env
- Supabase CLI `db push` command applies migrations directly
- `migration repair` handles history conflicts
- Takes 30 seconds total (automated)

**Previous Workflow (Deprecated):**
- 31 builds tried direct psql - all failed due to network/auth
- Manual Dashboard SQL Editor was 100% success rate but slower
- HTML automation tools were workarounds

**Full Documentation:**
- `.claude/MIGRATION_SCRIPTS_INVENTORY.md` - All available scripts
- `.claude/HOW_TO_APPLY_MIGRATIONS.md` - Detailed manual instructions (deprecated)
- `.claude/AUTOMATED_MIGRATIONS.md` - Why psql doesn't work

---

**Summary: This runbook eliminates 90% of exploration time by executing known, working steps.**

**Total Time:** 30 seconds per migration (fully automated via CLI)
