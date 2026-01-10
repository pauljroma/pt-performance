# Deployment Guide - AI Nutrition Recommendation

## Pre-Deployment Checklist

### 1. Database Migrations
Ensure these migrations are applied:

```bash
cd /Users/expo/Code/expo/supabase

# Check migration status
supabase db status

# Required migrations:
# ✓ 20251215150000_create_nutrition_tracking.sql
# ✓ 20260108000003_create_nutrition_storage.sql
# ✓ 20251215120000_create_scheduled_sessions.sql
# ✓ 20260105000010_create_daily_readiness.sql

# Apply if needed
supabase db push
```

### 2. Verify Database Functions
Check that helper function exists:

```sql
-- Run in Supabase SQL Editor
SELECT routine_name
FROM information_schema.routines
WHERE routine_name = 'get_daily_nutrition_summary';
-- Should return 1 row
```

### 3. OpenAI API Key
Ensure OpenAI API key is set in Supabase secrets:

```bash
# Check if secret exists
supabase secrets list | grep OPENAI_API_KEY

# Set if missing
supabase secrets set OPENAI_API_KEY=sk-proj-...
```

### 4. Test Data (Optional for Testing)
Create test patient and data:

```sql
-- See test-cases.ts for full SQL setup
-- Creates test patient with nutrition goals, logs, readiness, and scheduled sessions
```

## Deployment Steps

### Step 1: Verify Function Code
```bash
cd /Users/expo/Code/expo/supabase/functions/ai-nutrition-recommendation

# Check files exist
ls -la
# Should see: index.ts, README.md, test-cases.ts, DEPLOYMENT.md
```

### Step 2: Deploy to Supabase
```bash
# From project root
cd /Users/expo/Code/expo

# Deploy function
supabase functions deploy ai-nutrition-recommendation --project-ref <your-project-ref>

# Expected output:
# Deploying ai-nutrition-recommendation...
# Function deployed successfully
```

### Step 3: Verify Deployment
```bash
# List functions
supabase functions list

# Should show:
# ai-nutrition-recommendation | 2026-01-04 | deployed
```

### Step 4: Test Basic Functionality
```bash
# Get your Supabase URL and anon key
SUPABASE_URL="https://your-project.supabase.co"
ANON_KEY="your-anon-key"

# Test basic request
curl -X POST "$SUPABASE_URL/functions/v1/ai-nutrition-recommendation" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{
    "patient_id": "test-patient-id",
    "time_of_day": "2:00 PM"
  }'

# Expected: 200 response with recommendation JSON
```

## Post-Deployment Verification

### Test Case 1: Error Handling
```bash
# Missing required field (should return 400)
curl -X POST "$SUPABASE_URL/functions/v1/ai-nutrition-recommendation" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{
    "time_of_day": "2:00 PM"
  }'

# Expected: {"error":"patient_id and time_of_day required"}
```

### Test Case 2: Cache Behavior
```bash
# First request
curl -X POST "$SUPABASE_URL/functions/v1/ai-nutrition-recommendation" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{
    "patient_id": "test-patient-id",
    "time_of_day": "2:00 PM"
  }'
# Note the recommendation_id

# Second request (within 30 minutes)
sleep 5
curl -X POST "$SUPABASE_URL/functions/v1/ai-nutrition-recommendation" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{
    "patient_id": "test-patient-id",
    "time_of_day": "2:05 PM"
  }'

# Expected: Same recommendation_id + "cached": true
```

### Test Case 3: With Context
```bash
curl -X POST "$SUPABASE_URL/functions/v1/ai-nutrition-recommendation" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ANON_KEY" \
  -d '{
    "patient_id": "test-patient-id",
    "time_of_day": "2:30 PM",
    "available_foods": ["chicken", "rice", "vegetables"],
    "context": {
      "next_workout_time": "4:00 PM",
      "workout_type": "Strength Training"
    }
  }'

# Expected: Recommendation considers workout timing and available foods
```

## Monitoring Setup

### 1. Enable Function Logs
```bash
# View real-time logs
supabase functions logs ai-nutrition-recommendation --tail

# View recent logs
supabase functions logs ai-nutrition-recommendation --limit 50
```

### 2. Create Monitoring Dashboard (Optional)
```sql
-- Create view for monitoring
CREATE OR REPLACE VIEW nutrition_recommendation_stats AS
SELECT
    DATE(created_at) as date,
    COUNT(*) as total_recommendations,
    COUNT(DISTINCT patient_id) as unique_patients,
    AVG((target_macros->>'calories')::int) as avg_calories_recommended,
    AVG((target_macros->>'protein')::int) as avg_protein_recommended
FROM nutrition_recommendations
GROUP BY DATE(created_at)
ORDER BY date DESC;

-- Query stats
SELECT * FROM nutrition_recommendation_stats LIMIT 7;
```

### 3. Set Up Alerts (Optional)
```sql
-- Alert for high error rate
-- (Implement using Supabase webhooks or external monitoring)

-- Query error frequency
SELECT
    DATE_TRUNC('hour', created_at) as hour,
    COUNT(*) as recommendation_count
FROM nutrition_recommendations
GROUP BY hour
ORDER BY hour DESC
LIMIT 24;

-- If count drops significantly, investigate
```

## Cost Monitoring

### OpenAI API Usage
```bash
# Track OpenAI API calls
# Method 1: Count recommendations (max 1 API call per recommendation, often cached)
SELECT COUNT(*) as api_calls_estimate
FROM nutrition_recommendations
WHERE created_at >= NOW() - INTERVAL '1 month';

# Method 2: Check OpenAI dashboard
# https://platform.openai.com/usage
```

### Cost Calculation
```
GPT-4 mini costs:
- ~$0.00027 per recommendation (uncached)
- With 60% cache hit rate: ~$0.00011 per request

Monthly cost per active user (3 requests/day):
- 90 requests/month
- ~60 API calls (with caching)
- Cost: $0.016 per user

1000 active users: ~$16/month
```

## Rollback Procedure

If issues arise, rollback:

```bash
# Option 1: Redeploy previous version
git checkout <previous-commit>
supabase functions deploy ai-nutrition-recommendation

# Option 2: Delete function (temporary)
supabase functions delete ai-nutrition-recommendation

# Option 3: Update iOS app to stop calling function
# (If function has critical bugs)
```

## Integration with iOS App

### Swift Implementation Example
```swift
// In iOS app: Services/NutritionService.swift

func getAIRecommendation(
    timeOfDay: String,
    availableFoods: [String]? = nil
) async throws -> NutritionRecommendation {
    let url = URL(string: "\(supabaseURL)/functions/v1/ai-nutrition-recommendation")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

    let body: [String: Any] = [
        "patient_id": currentUserId,
        "time_of_day": timeOfDay,
        "available_foods": availableFoods ?? []
    ]

    request.httpBody = try JSONSerialization.data(withJSONObject: body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NutritionError.apiError
    }

    return try JSONDecoder().decode(NutritionRecommendation.self, from: data)
}
```

## Troubleshooting

### Issue: "Failed to generate nutrition recommendation"

**Causes:**
1. OpenAI API key not set or invalid
2. OpenAI account out of credits
3. Network connectivity issue

**Solution:**
```bash
# Verify secret
supabase secrets list | grep OPENAI_API_KEY

# Re-set secret
supabase secrets set OPENAI_API_KEY=sk-...

# Check OpenAI account: https://platform.openai.com/account/billing
```

### Issue: "Error fetching nutrition summary"

**Causes:**
1. `get_daily_nutrition_summary` function not deployed
2. Patient has no nutrition_goals record
3. Database connection issue

**Solution:**
```sql
-- Check function exists
SELECT routine_name FROM information_schema.routines
WHERE routine_name = 'get_daily_nutrition_summary';

-- Create nutrition_goals for patient
INSERT INTO nutrition_goals (patient_id, daily_calories, daily_protein_grams, daily_carbs_grams, daily_fats_grams, active)
VALUES ('<patient-id>', 2000, 150, 200, 65, true)
ON CONFLICT (patient_id, active) WHERE active = TRUE DO NOTHING;
```

### Issue: Recommendations don't consider workouts

**Causes:**
1. No scheduled_sessions records
2. Sessions marked as 'completed' or 'cancelled'
3. Query looking at wrong date

**Solution:**
```sql
-- Verify scheduled sessions
SELECT * FROM scheduled_sessions
WHERE patient_id = '<patient-id>'
AND scheduled_date = CURRENT_DATE
AND status = 'scheduled';

-- Create test session
INSERT INTO scheduled_sessions (patient_id, session_id, scheduled_date, scheduled_time, status)
VALUES ('<patient-id>', '<session-id>', CURRENT_DATE, '16:00:00', 'scheduled');
```

### Issue: Cache always returns old data

**Causes:**
1. Time zone issue (recommendations older than 30 minutes still cached)

**Solution:**
```sql
-- Check recommendation timestamps
SELECT id, created_at, NOW() - created_at as age
FROM nutrition_recommendations
WHERE patient_id = '<patient-id>'
ORDER BY created_at DESC
LIMIT 5;

-- Manually clear old cache (if needed)
DELETE FROM nutrition_recommendations
WHERE created_at < NOW() - INTERVAL '30 minutes';
```

## Performance Optimization

### Database Indexes
Verify indexes exist:

```sql
-- Check nutrition_recommendations index
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'nutrition_recommendations';

-- Should see: idx_nutrition_recommendations_patient

-- If missing, create:
CREATE INDEX IF NOT EXISTS idx_nutrition_recommendations_patient_recent
ON nutrition_recommendations(patient_id, created_at DESC);
```

### Edge Function Performance
- **Target:** <2s for uncached requests
- **Target:** <100ms for cached requests

Monitor in Supabase dashboard under Functions > ai-nutrition-recommendation > Metrics

## Security Checklist

- [ ] RLS enabled on `nutrition_recommendations` table
- [ ] Patients can only view/insert their own recommendations
- [ ] Therapists can view patient recommendations (via RLS)
- [ ] OpenAI API key stored in Supabase secrets (not in code)
- [ ] CORS headers configured correctly
- [ ] Input validation on all parameters
- [ ] No sensitive data logged

## Success Criteria

Function is successfully deployed when:

1. ✅ Function appears in `supabase functions list`
2. ✅ Basic test request returns 200 with valid JSON
3. ✅ Error handling works (400 for missing params)
4. ✅ Cache works (second request within 30 min returns cached)
5. ✅ Recommendations saved to database
6. ✅ Context correctly gathered (nutrition, workouts, readiness)
7. ✅ OpenAI API calls successful
8. ✅ Logs show no errors

## Next Steps After Deployment

1. **Integrate with iOS app**
   - Add `NutritionService.getAIRecommendation()` method
   - Create UI for displaying recommendations
   - Add "Get Recommendation" button to nutrition screen

2. **User Testing**
   - Test with real users
   - Gather feedback on recommendation quality
   - Iterate on prompt engineering

3. **Monitor Usage**
   - Track API call frequency
   - Monitor OpenAI costs
   - Analyze cache hit rate

4. **Optimize Prompts**
   - Review generated recommendations
   - Refine prompt based on user feedback
   - Test different temperature settings

5. **Add Features**
   - Photo analysis (OpenAI Vision)
   - Meal planning (full day recommendations)
   - Shopping lists
   - Allergy/preference filtering

## Support

For issues or questions:
- Check Supabase logs: `supabase functions logs ai-nutrition-recommendation`
- Review test cases: `test-cases.ts`
- Check README: `README.md`
- Contact: BUILD 138 development team

## Changelog

### 2026-01-04 - Initial Deployment
- Deployed ai-nutrition-recommendation Edge Function
- Integrated with BUILD 138 nutrition tracking system
- OpenAI GPT-4 mini for cost-effective recommendations
- 30-minute caching implemented
- Full context awareness (nutrition, workouts, recovery)
