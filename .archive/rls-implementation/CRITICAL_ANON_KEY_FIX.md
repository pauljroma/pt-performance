# CRITICAL: Config.swift Has Wrong Supabase Key

## The Problem

**Config.swift line 9** has the **SERVICE KEY** instead of the **ANON KEY**:

```swift
// WRONG - This is the service key (bypasses RLS, security risk!)
static let supabaseAnonKey = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"
```

**Why this breaks connectivity:**
- Service keys are meant for server-side use only
- Using service key in iOS app bypasses Row Level Security (RLS)
- This is why "no connectivity to database" occurs - RLS policies block access

## The Fix

### Step 1: Get the Correct Anon Key

I've opened Supabase dashboard at: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/settings/api

**Copy the "anon" key** (NOT the service_role key). It should:
- Start with `eyJ...` (it's a JWT token)
- Be much longer than the service key
- Be labeled as "anon" or "anon public" in the dashboard

### Step 2: Update Config.swift

Replace line 9 in Config.swift:

```swift
// BEFORE (WRONG):
static let supabaseAnonKey = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"

// AFTER (CORRECT):
static let supabaseAnonKey = "eyJ... [paste the anon key here]"
```

### Step 3: Rebuild

```bash
# Increment build number
# Push to GitHub
# TestFlight will build Build 10
```

## Why This Matters

**Service Key (what's there now):**
- ❌ Bypasses all security
- ❌ Never use in client apps
- ❌ Exposed in compiled app binary
- ✅ Only for server-side backend

**Anon Key (what should be there):**
- ✅ Enforces Row Level Security
- ✅ Safe for client apps
- ✅ Users only see their own data
- ✅ Proper authentication flow

## Security Impact

Using the service key in a client app means:
- Anyone who decompiles the iOS app gets admin access
- All RLS policies are bypassed
- Any user can see/modify all data
- This is a **CRITICAL security vulnerability**

## Next Steps

1. Copy anon key from Supabase dashboard (I opened it for you)
2. Update Config.swift line 9
3. Commit and push to trigger Build 10
4. Test Build 10 - should connect properly now

---

**Note**: The anon key is safe to expose in client apps because RLS policies control access. The service key must NEVER be in client code.
