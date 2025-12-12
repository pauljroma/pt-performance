# Get Supabase Personal Access Token

## Quick Steps (30 seconds)

1. **Go to:** https://supabase.com/dashboard/account/tokens

2. **Click:** "Generate new token"

3. **Name:** "CLI Migrations" (or any name)

4. **Click:** "Generate token"

5. **Copy the token** (starts with `sbp_...`)

6. **Run this command:**
```bash
echo "SUPABASE_ACCESS_TOKEN=sbp_your_token_here" >> /Users/expo/Code/expo/clients/linear-bootstrap/agent-service/.env
```

7. **Then run:**
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
export SUPABASE_ACCESS_TOKEN=sbp_your_token_here
supabase link --project-ref rpbxeaxlaoyoqkohytlw
supabase db push
```

## After This One-Time Setup

All future migrations will work with just:
```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap
supabase db push
```

---

## Note: Credentials You Provided

The credentials you provided are:
- **Client ID:** `89c89853-da91-4d49-b669-0e9e88182451`
- **Client Secret:** `sba_4e03ab0730df9d1af10d2978fe6af2907952260b`

These are **OAuth credentials for the Swift app** (used in the iOS app), NOT CLI credentials.

For CLI authentication, you need a **Personal Access Token** (`sbp_...`) from the link above.
