# Manual SQL Migration Deployment Guide

Since `psql` is not installed on this system, you'll need to deploy the SQL migrations manually through the Supabase dashboard.

## Quick Steps

### 1. Access Supabase SQL Editor

1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw
2. Navigate to: **SQL Editor** (left sidebar)
3. Click: **New Query**

### 2. Deploy Migration 005 - RM Estimate

**File:** `infra/005_add_rm_estimate.sql`

1. Open the file: `infra/005_add_rm_estimate.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run** (or press ⌘+Enter)
5. Verify success: Check for "Success. No rows returned" or similar

**What this does:**
- Adds `rm_estimate` column to `exercise_logs` table
- Creates `calculate_rm_estimate()` function (Epley formula)
- Adds trigger to auto-calculate RM on insert/update
- Backfills existing logs
- Creates `vw_rm_progression` view
- Creates `get_current_1rm()` function

### 3. Deploy Migration 007 - Agent Logs

**File:** `infra/007_agent_logs_table.sql`

1. Open the file: `infra/007_agent_logs_table.sql`
2. Copy the entire contents
3. Paste into Supabase SQL Editor
4. Click **Run**
5. Verify success

**What this does:**
- Creates `agent_logs` table for request logging
- Creates indexes for performance
- Creates monitoring views:
  - `vw_agent_errors` - Error tracking
  - `vw_endpoint_performance` - Performance metrics
- Creates helper functions:
  - `cleanup_old_agent_logs()` - Cleanup old logs
  - `get_error_summary()` - Error summaries
  - `get_slow_requests()` - Performance analysis

### 4. Verify Deployment

Run these queries in SQL Editor to verify:

```sql
-- Check rm_estimate column exists
SELECT column_name, data_type
FROM information_schema.columns
WHERE table_name = 'exercise_logs'
AND column_name = 'rm_estimate';

-- Check agent_logs table exists
SELECT table_name
FROM information_schema.tables
WHERE table_name = 'agent_logs';

-- Check views exist
SELECT table_name
FROM information_schema.views
WHERE table_name IN ('vw_rm_progression', 'vw_agent_errors', 'vw_endpoint_performance');
```

Expected results:
- `rm_estimate` column should exist
- `agent_logs` table should exist
- All 3 views should exist

## Alternative: Use Supabase CLI

If you have Supabase CLI installed:

```bash
# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref rpbxeaxlaoyoqkohytlw

# Apply migrations
supabase db push
```

## Files to Deploy

1. `infra/005_add_rm_estimate.sql` (6,559 bytes)
2. `infra/007_agent_logs_table.sql` (4,306 bytes)

## Connection Info

- **Project URL:** https://rpbxeaxlaoyoqkohytlw.supabase.co
- **Database:** PostgreSQL (Supabase)
- **Service Role Key:** (in .env file)

## Troubleshooting

**Error: "relation already exists"**
- This means the table/column already exists from a previous deployment
- Safe to ignore if the migration was already applied

**Error: "permission denied"**
- Make sure you're using the service role key, not the anon key
- Check that you're logged in with admin privileges

**Error: "syntax error"**
- Make sure you copied the entire SQL file
- Check that no characters were lost during copy/paste

## After Deployment

Once migrations are deployed:

1. ✅ Update Linear (mark deployment complete)
2. ✅ Test backend endpoints
3. ✅ Build iOS app
4. ✅ Integration testing

---

**Need Help?**
- Supabase Docs: https://supabase.com/docs/guides/database/migrations
- SQL Editor: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
