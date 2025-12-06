# Quick Deploy - Get Access Token & Deploy

## Option 1: Get Access Token (2 minutes)

1. **Go to:** https://supabase.com/dashboard/account/tokens
2. **Click:** "Generate New Token"
3. **Name it:** "CLI Deployment"
4. **Copy the token**
5. **Run this:**

```bash
export SUPABASE_ACCESS_TOKEN="your-token-here"
```

Then continue below...

## Option 2: Use Supabase Dashboard (1 minute)

**Fastest way - just copy/paste SQL:**

1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
2. Click "New Query"
3. Copy contents of `infra/005_add_rm_estimate.sql` → Paste → Run
4. Copy contents of `infra/007_agent_logs_table.sql` → Paste → Run
5. Done!

---

## After You Choose Either Option

Run verification:
```bash
python3 verify_migrations.py
```

Then we'll mark everything Done in Linear!
