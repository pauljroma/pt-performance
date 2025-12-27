# AI Safety Check - Deployment Guide

**Build 79 - Agent 3: Claude Safety Integration**

## Pre-Deployment Checklist

- [ ] Anthropic API key obtained (https://console.anthropic.com/)
- [ ] Supabase CLI installed (`npm install -g supabase`)
- [ ] Supabase project linked (`supabase link --project-ref your-project-ref`)
- [ ] Database migrations applied (Build 77 AI Helper tables)

## Step 1: Verify Environment

```bash
# Check Supabase CLI
supabase --version
# Expected: >=1.120.0

# Check project link
supabase status
# Should show your project URL

# Verify migrations
supabase db remote ls
# Should include: 20251224000002_create_ai_helper_tables.sql
```

## Step 2: Deploy Edge Function

```bash
# From project root
cd /Users/expo/Code/expo

# Deploy function
supabase functions deploy ai-safety-check

# Expected output:
# Deploying function ai-safety-check...
# Function URL: https://your-project.supabase.co/functions/v1/ai-safety-check
# ✓ Deployed successfully
```

## Step 3: Configure Environment Variables

```bash
# Set Anthropic API key
supabase secrets set ANTHROPIC_API_KEY=sk-ant-api03-your-key-here

# Verify secret was set
supabase secrets list
# Should show: ANTHROPIC_API_KEY (masked)

# Note: SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are auto-injected
```

## Step 4: Test Deployment

### Basic Health Check

```bash
# Test with curl (replace with your project URL)
curl -X POST \
  https://your-project.supabase.co/functions/v1/ai-safety-check \
  -H "Authorization: Bearer YOUR_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": "00000000-0000-0000-0000-000000000000",
    "exercise_id": "00000000-0000-0000-0000-000000000000"
  }'

# Expected: 404 error (athlete not found) - confirms function is running
```

### Test with Real Data

```bash
# Get a real athlete_id from database
ATHLETE_ID=$(supabase db query "SELECT id FROM patients LIMIT 1;" --csv | tail -1)

# Get a real exercise_id
EXERCISE_ID=$(supabase db query "SELECT id FROM exercise_templates LIMIT 1;" --csv | tail -1)

# Test function
supabase functions invoke ai-safety-check \
  --body "{\"athlete_id\":\"$ATHLETE_ID\",\"exercise_id\":\"$EXERCISE_ID\"}"

# Expected: JSON response with safety_check object
```

## Step 5: Monitor Logs

```bash
# Tail function logs
supabase functions logs ai-safety-check --tail

# Look for:
# - "[AI Safety Check] Starting analysis..."
# - "[AI Safety Check] Claude analysis complete: info|caution|warning|danger"
# - No errors or stack traces
```

## Step 6: Verify Database Persistence

```bash
# Check that safety checks are being saved
supabase db query "
  SELECT
    id,
    warning_level,
    reason,
    created_at
  FROM ai_safety_checks
  ORDER BY created_at DESC
  LIMIT 5;
"

# Should show recent safety check records
```

## Step 7: Performance Testing

### Fast Path Test (Rule-Based)

Create test athlete with severe shoulder injury:

```sql
-- Insert test athlete with shoulder injury
INSERT INTO patients (id, email, medical_history)
VALUES (
  '11111111-1111-1111-1111-111111111111',
  'test-shoulder@example.com',
  '{
    "injuries": [{
      "year": 2025,
      "body_region": "shoulder",
      "diagnosis": "rotator cuff strain",
      "severity": "severe"
    }]
  }'::jsonb
);
```

Test fast path (should return <100ms):

```bash
time supabase functions invoke ai-safety-check \
  --body '{
    "athlete_id":"11111111-1111-1111-1111-111111111111",
    "exercise_id":"overhead-press-exercise-id"
  }'

# Expected:
# - Response time: <100ms
# - warning_level: "danger"
# - fast_path: true
```

### Claude Path Test (AI Analysis)

Test comprehensive analysis:

```bash
# Athlete with no injuries
time supabase functions invoke ai-safety-check \
  --body '{
    "athlete_id":"healthy-athlete-id",
    "exercise_id":"bench-press-id"
  }'

# Expected:
# - Response time: 2-4 seconds
# - warning_level: "info"
# - fast_path: false
# - ai_analysis.tokens_used: 500-800
```

## Step 8: Integration Testing

### iOS Integration

Update iOS app Supabase client:

```swift
// In Config.swift or environment config
let supabaseFunctionsURL = "https://your-project.supabase.co/functions/v1"

// Test from iOS app
let result = try await supabase.functions.invoke(
    "ai-safety-check",
    options: FunctionInvokeOptions(
        body: [
            "athlete_id": athleteId.uuidString,
            "exercise_id": exerciseId.uuidString
        ]
    )
)
```

### Web Dashboard Integration

```javascript
// Test from web console
const { data, error } = await supabase.functions.invoke('ai-safety-check', {
  body: {
    athlete_id: 'test-athlete-id',
    exercise_id: 'test-exercise-id'
  }
});

console.log('Safety Check:', data);
```

## Troubleshooting

### Error: "ANTHROPIC_API_KEY not configured"

```bash
# Verify secret is set
supabase secrets list

# Re-set if needed
supabase secrets set ANTHROPIC_API_KEY=your-key-here

# Redeploy function (may be needed to pick up new secret)
supabase functions deploy ai-safety-check
```

### Error: "Athlete not found"

- Check that athlete_id exists in `patients` table
- Verify UUID format is correct (lowercase, with dashes)
- Check RLS policies allow service role access

### Error: "Exercise not found"

- Check that exercise_id exists in `exercise_templates` table
- Verify UUID format is correct

### Claude API Errors

```bash
# Check Anthropic API key validity
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: $ANTHROPIC_API_KEY" \
  -H "content-type: application/json" \
  -H "anthropic-version: 2023-06-01" \
  -d '{
    "model": "claude-3-5-sonnet-20241022",
    "max_tokens": 10,
    "messages": [{"role": "user", "content": "test"}]
  }'

# Should return valid JSON response, not 401 error
```

### Slow Response Times

- Check Claude API status: https://status.anthropic.com/
- Verify database queries are fast (add indexes if needed)
- Check function logs for bottlenecks

## Production Readiness Checklist

- [ ] Function deployed successfully
- [ ] Environment variables configured
- [ ] Test cases passing (all 7 scenarios)
- [ ] Logs showing no errors
- [ ] Database persistence working
- [ ] Fast path (<100ms) confirmed
- [ ] Claude path (2-4s) confirmed
- [ ] Cost monitoring set up (~$0.003/request)
- [ ] iOS integration tested
- [ ] Web integration tested (if applicable)
- [ ] Error alerts configured (Supabase dashboard)

## Rollback Procedure

If issues arise:

```bash
# Delete deployed function
supabase functions delete ai-safety-check

# Confirm deletion
supabase functions list
# ai-safety-check should not appear

# Database rollback (if needed)
supabase db reset --db-url your-db-url
```

## Monitoring

### Key Metrics to Track

1. **Request Volume**: Requests per day/hour
2. **Response Time**: p50, p95, p99
3. **Error Rate**: % of failed requests
4. **Fast Path %**: % caught by rule-based system
5. **Warning Distribution**: INFO/CAUTION/WARNING/DANGER counts
6. **Token Usage**: Daily Claude API cost

### Supabase Dashboard

Navigate to: `Functions > ai-safety-check > Logs & Metrics`

Set up alerts for:
- Error rate > 5%
- Response time > 10 seconds
- Request volume spike (>1000/hour)

## Success Criteria

✅ Function deploys without errors
✅ All 7 test cases pass
✅ Fast path returns <100ms
✅ Claude path returns valid JSON
✅ Safety checks saved to database
✅ iOS app can invoke function
✅ No errors in function logs

## Next Steps

After successful deployment:

1. **Monitor for 24 hours** - Watch logs, error rates, performance
2. **Gather real-world data** - Analyze warning level distribution
3. **Tune prompts** - Adjust Claude prompts based on accuracy
4. **Optimize costs** - Expand fast path rules to reduce Claude calls
5. **Add caching** - Cache athlete+exercise pairs for 1 hour

## Support

- Supabase Docs: https://supabase.com/docs/guides/functions
- Anthropic Docs: https://docs.anthropic.com/
- Build 79 Spec: See `.outcomes/build79_agent3_safety.md`

---

**Deployment Date**: ___________
**Deployed By**: ___________
**Production URL**: ___________
**Status**: [ ] Testing [ ] Staging [ ] Production
