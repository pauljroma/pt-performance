# Supabase CLI Setup & Migration Deployment

## Step 1: Login to Supabase

Run this command (it will open your browser):

```bash
supabase login
```

**What happens:**
- Opens browser to Supabase dashboard
- You authenticate with your Supabase account
- CLI receives access token automatically

## Step 2: Link to Your Project

After login, run:

```bash
supabase link --project-ref rpbxeaxlaoyoqkohytlw --password "rcq!vyd6qtb_HCP5mzt"
```

**Expected output:**
```
Finished supabase link.
```

## Step 3: Deploy Migrations

Now deploy the SQL migrations:

```bash
# Deploy all pending migrations
supabase db push
```

**Alternative: Deploy specific files**

If `db push` doesn't work, use direct execution:

```bash
# Deploy migration 005
supabase db execute --file infra/005_add_rm_estimate.sql --linked

# Deploy migration 007
supabase db execute --file infra/007_agent_logs_table.sql --linked
```

## Step 4: Verify Deployment

```bash
# Run verification script
python3 verify_migrations.py
```

## Troubleshooting

**Error: "Access token not provided"**
- Solution: Run `supabase login` first

**Error: "Project not linked"**
- Solution: Run `supabase link` command from Step 2

**Error: "Permission denied"**
- Solution: Make sure you're logged in with the correct Supabase account
- Verify you have admin access to project `rpbxeaxlaoyoqkohytlw`

## Alternative: Get Access Token Manually

If the browser login doesn't work:

1. Go to: https://supabase.com/dashboard/account/tokens
2. Click "Generate New Token"
3. Copy the token
4. Set environment variable:

```bash
export SUPABASE_ACCESS_TOKEN="your-token-here"
```

Then proceed with Step 2 (link) and Step 3 (deploy).

## Quick Reference

**Project Details:**
- Project Ref: `rpbxeaxlaoyoqkohytlw`
- URL: `https://rpbxeaxlaoyoqkohytlw.supabase.co`
- Dashboard: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw

**Files to Deploy:**
- `infra/005_add_rm_estimate.sql` (RM calculation)
- `infra/007_agent_logs_table.sql` (Logging infrastructure)

**After Deployment:**
1. Run `python3 verify_migrations.py` to verify
2. Start backend: `cd agent-service && npm start`
3. Test: `curl http://localhost:4000/health`
4. Update Linear ACP-57 to Done

---

**Need help?** Check the Supabase CLI docs:
https://supabase.com/docs/guides/cli
