# ⚠️ STOP - READ MIGRATION_RUNBOOK.md FIRST

**If you're here because of a migration task:**

→ **Read: `.claude/MIGRATION_RUNBOOK.md`** (Executable checklist - READ FIRST)

This file (AUTOMATED_MIGRATIONS.md) is **REFERENCE ONLY** for understanding why automation doesn't work. The **RUNBOOK** has the executable steps.

---

# Automated Migration Application Workflow

## Current Status (Build 32) - ✅ RESOLVED

**Previous Challenge:** Direct database connections blocked by network/auth restrictions:
- `supabase db push` - Requires login token
- `psql` with pooler - Authentication format issues
- Python `psycopg2` - Same connection issues

**Working Solution:** Migrations already applied! Table verification via REST API works.

**Key Learning:** For Build 32, the `exercise_logs` table already existed (likely from previous manual application). Always verify table existence via REST API before attempting migration.

## Standard Workflow for All Migrations

### Step 1: Verify Table Doesn't Exist
```bash
python3 apply_migration.py
```

This script:
1. Attempts to query the table via REST API
2. If table exists → Reports success, no action needed
3. If table doesn't exist → Displays SQL for manual application

### Step 2: If Needed - Apply via Dashboard (1 minute)

**URL:** https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql/new

**Steps:**
1. Open SQL Editor in browser
2. Copy migration SQL:
   ```bash
   cat supabase/migrations/20251212000001_create_exercise_logs_table.sql | pbcopy
   ```
3. Paste into SQL Editor
4. Click "Run" button
5. Verify success message

### Step 3: Verify Table Created
```sql
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'exercise_logs'
ORDER BY ordinal_position;
```

Expected: 14 rows (id, session_exercise_id, patient_id, actual_sets, actual_reps, etc.)

### Step 4: Update Linear
Post comment to Linear issue:
```
✅ Migration applied: exercise_logs table created
Build 32 ready to test on TestFlight
```

## Build 32 Migration Details

**File:** `supabase/migrations/20251212000001_create_exercise_logs_table.sql`

**Creates:**
- Table: `exercise_logs` (14 columns)
- Indexes: 4 indexes for query performance
- RLS Policies: Patient/therapist access control
- Grants: `authenticated` role permissions

**Purpose:** Enable patient exercise logging in iOS app

## Future Automation Attempts

When network/auth restrictions are resolved, we can automate with:

### Option 1: Supabase CLI
```bash
# One-time setup
supabase login  # Requires browser authentication
supabase link --project-ref rpbxeaxlaoyoqkohytlw

# Apply migrations
cd supabase && supabase db push --linked --include-all
```

**Blocker:** No access token available in this environment

### Option 2: psql Direct Connection
```bash
PGPASSWORD="SERVICE_KEY" psql \\
  "postgresql://postgres.PROJECT_REF@aws-0-us-west-1.pooler.supabase.com:6543/postgres" \\
  -f migration.sql
```

**Blocker:** "Tenant or user not found" error (auth format issue)

### Option 3: Supabase Management API
```python
import requests

response = requests.post(
    "https://api.supabase.com/v1/projects/rpbxeaxlaoyoqkohytlw/database/migrations",
    headers={"Authorization": f"Bearer {MANAGEMENT_API_TOKEN}"},
    json={"name": "migration_name", "statements": [sql]}
)
```

**Blocker:** Requires Management API token (user must generate)

## Lessons Learned (Builds 1-32)

**Why This Workflow?**
- ✅ **Always works** - No network/auth dependencies
- ✅ **Fast** - 1 minute from file creation to applied
- ✅ **Visible** - See SQL execution in real-time
- ✅ **Debuggable** - Error messages clear and actionable

**Attempted Automations:**
- 31 builds tried various automation approaches
- All failed due to network/auth restrictions
- Manual dashboard workflow has 100% success rate

## When to Apply Migrations

**Trigger:** When you see this in Linear/docs:
```
⚠️ Migration Required
File: supabase/migrations/YYYYMMDDHHMMSS_*.sql
Status: Pending application
```

**Frequency:** Typically 1-2 migrations per build for new features

**Time Investment:** 1 minute per migration (worth it vs. debugging automation)

---

**For Build 32:** Apply `20251212000001_create_exercise_logs_table.sql` now to unblock exercise logging feature.

**Next Build:** Same workflow - copy SQL, paste in dashboard, run, verify.
