# Apply Security Definer Fixes

## Issue

Supabase Splinter detected SECURITY DEFINER security vulnerabilities:
- Views and functions with SECURITY DEFINER bypass RLS policies
- They run with creator's permissions instead of user's permissions
- Security risk: unauthorized data access

## Fix Created

**Migration:** `supabase/migrations/20251211000015_fix_security_definer_issues.sql`

### Changes:

1. **Function:** `get_current_therapist_id()`
   - Changed from `SECURITY DEFINER` → `SECURITY INVOKER`
   - Now respects RLS policies of the calling user

2. **Views Fixed:**
   - `vw_agent_error_summary` → `SECURITY INVOKER`
   - `vw_agent_endpoint_performance` → `SECURITY INVOKER`
   - `vw_patient_sessions` → `SECURITY INVOKER`
   - `vw_pain_trend` → `SECURITY INVOKER`
   - `vw_patient_adherence` → `SECURITY INVOKER`

3. **Permissions Added:**
   - Granted SELECT on all views to `authenticated` role
   - Granted EXECUTE on function to `authenticated` role

## How to Apply

### Option 1: Supabase Dashboard SQL Editor (RECOMMENDED)

1. Go to https://supabase.com/dashboard
2. Open your project: PTPerformance
3. Click "SQL Editor" in left sidebar
4. Click "New query"
5. Copy contents of `supabase/migrations/20251211000015_fix_security_definer_issues.sql`
6. Paste into SQL editor
7. Click "Run" (bottom right)
8. Verify success message

### Option 2: Supabase CLI

```bash
cd supabase
supabase db push --include-all
```

## Verification

After applying, check Supabase dashboard for warnings:
- ✅ No more SECURITY DEFINER warnings
- ✅ Splinter should show green/passing
- ✅ RLS policies properly enforced

## Impact

**No breaking changes** - all existing queries continue to work.

The difference is that views/functions now:
- ✅ Respect RLS policies of the querying user
- ✅ More secure (can't bypass RLS)
- ✅ Follow Supabase best practices
