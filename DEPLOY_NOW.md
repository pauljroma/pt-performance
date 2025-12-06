# Deploy SQL Migrations - Step by Step

## 🚀 2-Minute Deployment via Supabase Dashboard

### Step 1: Open SQL Editor
Click this link: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql

### Step 2: Deploy Migration 005 (RM Estimate)

1. Click "New Query" button (top right)
2. Open file: `infra/005_add_rm_estimate.sql` in your editor
3. Copy ALL contents (231 lines)
4. Paste into Supabase SQL Editor
5. Click "Run" (or press ⌘+Enter)
6. Wait for "Success" message

**What this does:**
- Adds `rm_estimate` column to exercise_logs
- Creates auto-calculation trigger (Epley formula)
- Backfills existing data
- Creates views and helper functions

### Step 3: Deploy Migration 007 (Agent Logs)

1. Click "New Query" again
2. Open file: `infra/007_agent_logs_table.sql`
3. Copy ALL contents (160 lines)
4. Paste into Supabase SQL Editor
5. Click "Run"
6. Wait for "Success" message

**What this does:**
- Creates `agent_logs` table
- Adds performance indexes
- Creates monitoring views
- Sets up RLS policies

### Step 4: Verify Deployment

Run this command in your terminal:

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
python3 verify_migrations.py
```

Expected output:
```
✅ rm_estimate column exists
✅ agent_logs table exists
```

## ✅ After Deployment

Once verified, we'll:
1. Mark ACP-57 as Done in Linear
2. Update project status to 100% Phase 3 complete
3. Create improvement plan for next phase

---

## 🆘 Troubleshooting

**"relation already exists" error:**
- Safe to ignore - means migration was already run

**"syntax error" or "unexpected" error:**
- Make sure you copied the ENTIRE file
- Check no characters were lost during copy/paste
- Try copying directly from the file in VSCode or your editor

**Still having issues?**
- Let me know the exact error message
- We can try individual statements or alternative approach
