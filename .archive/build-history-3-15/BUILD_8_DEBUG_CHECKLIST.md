# Build 8 Debug Checklist - "Data Could Not Be Read"

## Verification Complete ✅

**Date**: 2025-12-09
**Status**: Seed data is COMPLETE and CORRECT

```
✅ Patient exists: John Brebbia (demo-athlete@ptperformance.app)
✅ Active program: 4-Week Return to Throw
✅ Phases: 2 (Foundation, Light Throwing)
✅ Sessions: 6 sessions created
✅ Today's session exercises: 10 exercises
✅ iOS query simulation: WORKS
```

## Root Cause: NOT Missing Seed Data

The database has all required data. The error must be in:
1. Authentication/Session Management
2. Row Level Security (RLS) Policies
3. Network/API Configuration

## Debug Steps (In Order)

### 1. Check Xcode Console Logs

**What to look for**:
```
📱 [TodaySession] Starting fetch for patient: <UUID>
📱 [TodaySession] Backend URL: <URL>
📱 [TodaySession] Calling: <full URL>
```

**Good signs**:
- Patient ID is present and correct
- Backend URL is valid
- No error messages

**Bad signs**:
- "No patient ID available"
- URLError or network timeout
- Backend returns 404 or 500

**How to check**:
1. Open Xcode
2. Run Build 8 on simulator or device
3. Login as demo-athlete@ptperformance.app
4. Navigate to Today's Session
5. View console output

### 2. Verify Authentication State

**File**: `ios-app/PTPerformance/Services/SupabaseClient.swift`

**Check**:
```swift
var userId: String? {
    supabase.auth.currentUser?.id.uuidString
}
```

**Debug**:
Add this to `TodaySessionViewModel.fetchTodaySession()`:
```swift
print("🔐 Current user ID: \(supabase.userId ?? "nil")")
print("🔐 Auth session exists: \(supabase.client.auth.currentSession != nil)")
```

**Expected**:
- User ID should be `00000000-0000-0000-0000-000000000001`
- Auth session should exist

### 3. Test Backend API Directly

**Endpoint**: `POST https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session`

**Test with curl**:
```bash
curl -X POST \
  'https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3' \
  -d '{"patientId": "00000000-0000-0000-0000-000000000001"}'
```

**Expected Response**:
```json
{
  "session": {
    "id": "00000000-0000-0000-0000-000000000401",
    "name": "Session 1: Foundation Training",
    ...
  },
  "exercises": [
    {
      "id": "...",
      "exercise_name": "Band Pull-Apart",
      "target_sets": 3,
      "target_reps": 15,
      ...
    },
    ...
  ]
}
```

**If fails**: Backend is not deployed or not working

### 4. Test Supabase Direct Query

**Using Supabase Dashboard**:

1. Go to https://supabase.com/dashboard
2. Select project `rpbxeaxlaoyoqkohytlw`
3. Go to SQL Editor
4. Run this query:

```sql
-- Test the exact iOS query
SELECT
    s.id AS session_id,
    s.name AS session_name,
    ph.id AS phase_id,
    ph.name AS phase_name,
    p.id AS program_id,
    p.name AS program_name,
    p.status AS program_status
FROM sessions s
JOIN phases ph ON ph.id = s.phase_id
JOIN programs p ON p.id = ph.program_id
WHERE p.patient_id = '00000000-0000-0000-0000-000000000001'
  AND p.status = 'active'
ORDER BY s.sequence
LIMIT 1;
```

**Expected**: 1 row returned with session data

**If fails**: Database relationship issue (but verification showed this works)

### 5. Check Row Level Security (RLS) Policies

**In Supabase Dashboard**:

1. Go to Authentication > Policies
2. Check policies for these tables:
   - `patients`
   - `programs`
   - `phases`
   - `sessions`
   - `session_exercises`
   - `exercise_templates`

**Required Policies**:

```sql
-- Patients can read their own data
CREATE POLICY "Patients can view own record"
ON patients FOR SELECT
TO authenticated
USING (id = auth.uid());

-- OR allow anonymous read for demo
CREATE POLICY "Anyone can read patients"
ON patients FOR SELECT
TO anon, authenticated
USING (true);
```

**Common Issue**: RLS is enabled but policies are too restrictive

**Fix**: Either:
- Add proper RLS policies for authenticated users
- Temporarily disable RLS for testing (NOT for production!)

### 6. Check Supabase Anon Key Permissions

**File**: `ios-app/PTPerformance/Config.swift`

**Current**:
```swift
static let supabaseAnonKey = "sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3"
```

**Verify**:
- This is the anon key (NOT service_role key)
- Anon key has permission to read tables
- Tables have correct RLS policies for anon access

### 7. Network Connectivity

**Test from iOS app**:

Add to `fetchFromSupabase()`:
```swift
print("🌐 Testing Supabase connectivity...")
let testResponse = try await supabase.client
    .from("patients")
    .select("id")
    .limit(1)
    .execute()
print("✅ Supabase reachable, returned \(testResponse.count) rows")
```

**Expected**: Should successfully connect and return data

**If fails**: Network issue or Supabase down

### 8. Check AppState.userId

**File**: `ios-app/PTPerformance/PTPerformanceApp.swift`

**Verify**:
```swift
@StateObject private var appState = AppState()
```

**In AuthView or after login**:
```swift
print("🔐 AppState userId after login: \(appState.userId ?? "nil")")
```

**Expected**:
- After successful login, `appState.userId` should be set
- Should persist across view changes

**Common Issue**: userId is set but not persisted in AppState

## Quick Test Script

Run this to verify everything:

```bash
cd /Users/expo/Code/expo/clients/linear-bootstrap

# 1. Verify seed data exists
python3 /tmp/verify_seed_data_fixed.py

# 2. Test backend endpoint (if running locally)
curl -X POST \
  'https://rpbxeaxlaoyoqkohytlw.supabase.co/functions/v1/today-session' \
  -H 'Content-Type: application/json' \
  -H 'Authorization: Bearer sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3' \
  -d '{"patientId": "00000000-0000-0000-0000-000000000001"}'
```

## Most Likely Issues (Ranked)

### 1. Authentication Not Persisting (70% probability)
**Symptom**: User logs in but `userId` is nil when fetching session
**Fix**: Check `PTSupabaseClient.userId` implementation

### 2. RLS Policies Blocking Read (20% probability)
**Symptom**: Query works in dashboard but fails from app
**Fix**: Add proper RLS policies or disable for testing

### 3. Backend Not Deployed (5% probability)
**Symptom**: Backend API call fails, fallback to Supabase also fails
**Fix**: Deploy Edge Function or run agent-service locally

### 4. Network/Connectivity (5% probability)
**Symptom**: All API calls timeout
**Fix**: Check internet, firewall, or VPN

## Data Verification Commands

```bash
# Re-seed if needed (safe to run multiple times)
python3 seed_demo_minimal.py
python3 seed_minimal_program.py

# Verify migrations
python3 verify_migrations.py

# Full verification
python3 /tmp/verify_seed_data_fixed.py
```

## Expected User Flow

1. User opens app
2. User taps "Login as Patient"
3. App calls `signIn(email: "demo-athlete@ptperformance.app", password: "demo-patient-2025")`
4. Supabase returns auth session with userId
5. App sets `appState.userId = session.user.id`
6. User navigates to "Today's Session"
7. App calls `fetchTodaySession()` with userId
8. Backend returns session + exercises
9. UI displays exercises

**Where it's breaking**: Likely between steps 5-7

## Key Files to Review

| File | Purpose | Check |
|------|---------|-------|
| `PTSupabaseClient.swift` | Auth & DB client | userId extraction |
| `AppState.swift` | Global state | userId persistence |
| `AuthView.swift` | Login flow | Sets userId after login |
| `TodaySessionViewModel.swift` | Data fetching | Logs query results |
| `Config.swift` | Supabase credentials | Correct URL & key |

## Success Criteria

✅ User can login
✅ userId is present in AppState
✅ Backend or Supabase query succeeds
✅ Session data is returned
✅ Exercises are displayed

## Current Status

- ❌ Build 8 shows "data could not be read"
- ✅ Seed data verified and complete
- ❓ Auth state unknown
- ❓ RLS policies unknown
- ❓ Backend deployment unknown

## Next Action

**Recommended**: Check Xcode console logs during Build 8 run to see exact error message from `TodaySessionViewModel`.
