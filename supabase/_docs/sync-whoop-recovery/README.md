# sync-whoop-recovery Edge Function

**Build 138 - WHOOP Integration MVP**

Syncs WHOOP recovery data to the `daily_readiness` table with OAuth refresh logic and intelligent caching.

---

## Purpose

Fetch latest WHOOP recovery metrics (recovery score, HRV, sleep performance, strain) and update today's `daily_readiness` entry. Handles OAuth token expiration/refresh automatically.

---

## Request Interface

```typescript
interface SyncWhoopRequest {
  patient_id: string;  // UUID of patient to sync WHOOP data for
}
```

### Example Request

```bash
curl -X POST https://your-project.supabase.co/functions/v1/sync-whoop-recovery \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "550e8400-e29b-41d4-a716-446655440000"}'
```

---

## Response Interface

```typescript
interface WHOOPRecoveryResponse {
  recovery_score: number;                  // 0-100
  sleep_performance_percentage: number;    // 0-100
  hrv_rmssd: number;                       // HRV in milliseconds
  strain: number;                          // 0-21 (estimated from recovery)
  synced_at: string;                       // ISO timestamp
}
```

### Example Success Response

```json
{
  "success": true,
  "data": {
    "recovery_score": 87.3,
    "sleep_performance_percentage": 91.5,
    "hrv_rmssd": 62.4,
    "strain": 9.7,
    "synced_at": "2026-01-04T12:34:56.789Z"
  },
  "updated_readiness": {
    "id": "uuid",
    "patient_id": "uuid",
    "date": "2026-01-04",
    "whoop_recovery_score": 87.3,
    "whoop_sleep_performance_percentage": 91.5,
    "whoop_hrv_rmssd": 62.4,
    "whoop_strain": 9.7,
    "whoop_synced_at": "2026-01-04T12:34:56.789Z"
  }
}
```

### Example Mock Data Response

```json
{
  "success": true,
  "mock": true,
  "message": "No WHOOP credentials found. Using mock data for testing.",
  "data": {
    "recovery_score": 82.7,
    "sleep_performance_percentage": 88.3,
    "hrv_rmssd": 58.9,
    "strain": 11.2,
    "synced_at": "2026-01-04T12:34:56.789Z"
  }
}
```

### Example Cached Response

```json
{
  "success": true,
  "cached": true,
  "message": "Recovery data synced 23 minutes ago. Using cached data.",
  "next_sync_available_in_minutes": 37
}
```

---

## Algorithm

### 1. Cache Check
- Query `daily_readiness` for today's entry
- If `whoop_synced_at` exists and < 1 hour old, return cached response
- Otherwise, proceed to sync

### 2. Fetch Patient Credentials
```sql
SELECT whoop_oauth_credentials FROM patients WHERE id = patient_id
```

Expected structure:
```json
{
  "access_token": "string",
  "refresh_token": "string",
  "expires_at": "2026-01-04T12:00:00Z",
  "athlete_id": "12345"
}
```

### 3. OAuth Token Refresh (if expired)
```
POST https://api.prod.whoop.com/oauth/oauth2/token
Content-Type: application/x-www-form-urlencoded

grant_type=refresh_token
&refresh_token={refresh_token}
&client_id={WHOOP_CLIENT_ID}
&client_secret={WHOOP_CLIENT_SECRET}
```

Response:
```json
{
  "access_token": "new_token",
  "refresh_token": "new_refresh_token",
  "expires_in": 3600,
  "token_type": "Bearer"
}
```

Update `patients.whoop_oauth_credentials` with new tokens.

### 4. Fetch WHOOP Recovery Data
```
GET https://api.prod.whoop.com/developer/v1/recovery
Authorization: Bearer {access_token}
```

Response:
```json
{
  "records": [
    {
      "cycle_id": 123456,
      "sleep_id": 789012,
      "user_calibrating": false,
      "recovery_score": 87,
      "resting_heart_rate": 52,
      "hrv_rmssd_milli": 62,
      "spo2_percentage": 97,
      "skin_temp_celsius": 33.4
    }
  ]
}
```

### 5. Calculate Strain (Estimated)
WHOOP's strain is 0-21 scale. Since recovery API doesn't return it directly:
```typescript
estimatedStrain = 21 - (recovery_score / 100) * 10
// Higher recovery → lower recent strain
```

### 6. Update daily_readiness
```sql
INSERT INTO daily_readiness (
  patient_id,
  date,
  whoop_recovery_score,
  whoop_sleep_performance_percentage,
  whoop_hrv_rmssd,
  whoop_strain,
  whoop_synced_at
) VALUES (
  patient_id,
  CURRENT_DATE,
  recovery_score,
  spo2_percentage,
  hrv_rmssd_milli,
  estimated_strain,
  NOW()
)
ON CONFLICT (patient_id, date) DO UPDATE SET
  whoop_recovery_score = EXCLUDED.whoop_recovery_score,
  whoop_sleep_performance_percentage = EXCLUDED.whoop_sleep_performance_percentage,
  whoop_hrv_rmssd = EXCLUDED.whoop_hrv_rmssd,
  whoop_strain = EXCLUDED.whoop_strain,
  whoop_synced_at = EXCLUDED.whoop_synced_at;
```

---

## Error Handling

### 1. Missing patient_id
```json
{
  "error": "patient_id required"
}
```
HTTP 400

### 2. Patient not found
```json
{
  "error": "Failed to fetch patient credentials"
}
```
HTTP 500

### 3. Token refresh failed
```json
{
  "error": "Failed to refresh WHOOP access token"
}
```
HTTP 500

### 4. WHOOP API rate limit
```json
{
  "error": "WHOOP API rate limit reached. Please try again later."
}
```
HTTP 500

### 5. No recovery data available
```json
{
  "error": "No recovery data available from WHOOP"
}
```
HTTP 500

---

## Environment Variables

Required in Supabase Edge Function secrets:

```bash
WHOOP_CLIENT_ID=your_client_id
WHOOP_CLIENT_SECRET=your_client_secret
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
```

Set with:
```bash
supabase secrets set WHOOP_CLIENT_ID=your_client_id
supabase secrets set WHOOP_CLIENT_SECRET=your_client_secret
```

---

## Testing

### 1. Test with Mock Data (no WHOOP credentials)
```bash
curl -X POST http://localhost:54321/functions/v1/sync-whoop-recovery \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "test-uuid"}'
```

Expected: Mock data response with realistic values.

### 2. Test with Real WHOOP Credentials
First, add WHOOP credentials to a patient:
```sql
UPDATE patients
SET whoop_oauth_credentials = '{
  "access_token": "test_token",
  "refresh_token": "test_refresh",
  "expires_at": "2026-01-04T12:00:00Z"
}'::jsonb
WHERE id = 'your-patient-uuid';
```

Then sync:
```bash
curl -X POST http://localhost:54321/functions/v1/sync-whoop-recovery \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "your-patient-uuid"}'
```

### 3. Test Cache Behavior
Run the same request twice within 1 hour:
- First request: Fetches from WHOOP API
- Second request: Returns cached response

---

## Database Schema Dependencies

### patients table
Requires `whoop_oauth_credentials` JSONB column (future migration):
```sql
ALTER TABLE patients
  ADD COLUMN IF NOT EXISTS whoop_oauth_credentials JSONB;

COMMENT ON COLUMN patients.whoop_oauth_credentials IS
  'WHOOP OAuth credentials: {access_token, refresh_token, expires_at, athlete_id}';
```

### daily_readiness table
Requires WHOOP columns (created in BUILD 138 migration):
```sql
-- Already exists:
whoop_recovery_score FLOAT CHECK (whoop_recovery_score >= 0 AND whoop_recovery_score <= 100)
whoop_sleep_performance_percentage FLOAT CHECK (whoop_sleep_performance_percentage >= 0 AND whoop_sleep_performance_percentage <= 100)
whoop_hrv_rmssd FLOAT CHECK (whoop_hrv_rmssd >= 0)
whoop_strain FLOAT CHECK (whoop_strain >= 0 AND whoop_strain <= 21)
whoop_synced_at TIMESTAMPTZ
```

---

## WHOOP API References

- **OAuth Documentation**: https://developer.whoop.com/docs/developing/oauth/
- **Recovery Endpoint**: https://developer.whoop.com/docs/developing/user-data/recovery
- **Rate Limits**: 100 requests per minute (per user)
- **Token Expiration**: 1 hour (refresh required)

---

## Deployment

```bash
# Deploy function
supabase functions deploy sync-whoop-recovery

# Set secrets
supabase secrets set WHOOP_CLIENT_ID=your_client_id
supabase secrets set WHOOP_CLIENT_SECRET=your_client_secret

# Test deployed function
curl -X POST https://your-project.supabase.co/functions/v1/sync-whoop-recovery \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"patient_id": "uuid"}'
```

---

## Future Enhancements

1. **Background Sync**: Schedule automatic daily syncs via cron
2. **Historical Data**: Sync past 7 days of recovery data
3. **Sleep Breakdown**: Add detailed sleep stage data
4. **Workout Detection**: Sync strain from WHOOP workouts
5. **Real-time Webhooks**: Listen to WHOOP webhooks for instant updates

---

## Build Context

- **Build**: 138
- **Agent**: 3
- **Linear**: BUILD-138
- **Migration**: `20260108000001_create_substitution_system.sql` (WHOOP columns)
- **Related Functions**: None (first WHOOP integration)

---

**Last Updated**: 2026-01-04
**Status**: ✅ Complete (mock data mode)
**Next**: Add real WHOOP OAuth credentials to patients table
