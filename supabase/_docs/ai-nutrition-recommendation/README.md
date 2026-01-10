# AI Nutrition Recommendation Edge Function

## Overview

Context-aware nutrition recommendation system that provides personalized meal suggestions based on:
- Current daily nutrition intake vs goals
- Upcoming workout schedule and timing
- Recovery status (sleep, soreness, energy, stress)
- Time of day
- Available food options

Built for BUILD 138 - Nutrition Tracking Enhancement.

## Features

### Context Awareness
- **Workout Timing**: Adjusts recommendations based on proximity to scheduled sessions
  - Pre-workout (1-2 hours): Easily digestible carbs + moderate protein
  - Post-workout (within 2 hours): Protein-rich + fast carbs for recovery
  - General meals: Balanced macros based on remaining daily needs

- **Recovery Status**: Factors in daily readiness metrics
  - Low recovery score (<60): Lighter, easily digestible meals
  - High soreness (>7): Anti-inflammatory foods, adequate protein
  - Low energy (<5): Quick energy sources

- **Daily Progress**: Calculates remaining macros to hit daily goals
  - Won't recommend exceeding targets unless severely under-eating
  - Balances remaining protein, carbs, fats, and calories

### Caching
- Recommendations cached for 30 minutes
- Prevents excessive OpenAI API calls
- Returns cached result if recent recommendation exists

### Smart Defaults
- Falls back gracefully if data unavailable
- Uses reasonable defaults (2000 cal, 150g protein, etc.)
- Works even without recovery or workout data

## API

### Request

**Endpoint:** `POST /ai-nutrition-recommendation`

**Headers:**
```json
{
  "Content-Type": "application/json",
  "Authorization": "Bearer <supabase-anon-key>"
}
```

**Body:**
```typescript
{
  "patient_id": "uuid",           // Required
  "time_of_day": "2:00 PM",       // Required
  "available_foods": [            // Optional
    "chicken",
    "rice",
    "vegetables"
  ],
  "context": {                    // Optional
    "next_workout_time": "4:00 PM",
    "workout_type": "strength training"
  }
}
```

### Response

**Success (200):**
```json
{
  "recommendation_id": "uuid",
  "recommendation_text": "Grilled chicken breast (6oz) with 1 cup brown rice and steamed broccoli",
  "target_macros": {
    "protein": 45,
    "carbs": 50,
    "fats": 12,
    "calories": 480
  },
  "reasoning": "This balanced meal provides adequate protein for your upcoming workout in 2 hours, with complex carbs for sustained energy. Your readiness score is good (72/100), so a full meal is appropriate.",
  "suggested_timing": "Eat now (2 hours before workout)"
}
```

**Cached Response (200):**
```json
{
  "recommendation_id": "uuid",
  "recommendation_text": "...",
  "target_macros": { ... },
  "reasoning": "...",
  "suggested_timing": "...",
  "cached": true
}
```

**Error (400):**
```json
{
  "error": "patient_id and time_of_day required"
}
```

**Error (500):**
```json
{
  "error": "Failed to generate nutrition recommendation",
  "details": "..."
}
```

## Database Dependencies

### Tables Used

1. **nutrition_logs** - Daily food intake
   - Columns: `patient_id`, `log_date`, `calories`, `protein_grams`, `carbs_grams`, `fats_grams`

2. **nutrition_goals** - Target macros
   - Columns: `patient_id`, `daily_calories`, `daily_protein_grams`, `daily_carbs_grams`, `daily_fats_grams`

3. **nutrition_recommendations** - Saved recommendations
   - Columns: `id`, `patient_id`, `recommendation_text`, `target_macros`, `reasoning`, `context`, `created_at`

4. **scheduled_sessions** - Upcoming workouts
   - Columns: `patient_id`, `scheduled_date`, `scheduled_time`, `status`, `session_id`

5. **sessions** - Workout details
   - Columns: `id`, `name`, `description`

6. **daily_readiness** - Recovery metrics
   - Columns: `patient_id`, `date`, `readiness_score`, `sleep_hours`, `soreness_level`, `energy_level`, `stress_level`

### Functions Used

- `get_daily_nutrition_summary(patient_id, date)` - Returns daily totals vs goals

## Algorithm

### Step 1: Check Cache
- Query `nutrition_recommendations` for entries in last 30 minutes
- If found, return cached result immediately

### Step 2: Gather Context
1. Get daily nutrition summary (consumed vs goals)
2. Fetch today's scheduled sessions
3. Find next upcoming workout (if any)
4. Get latest daily readiness data

### Step 3: Build OpenAI Prompt
Structured prompt includes:
- Current time of day
- Consumed macros vs goals
- Remaining macros needed
- Next workout timing and type
- Recovery metrics (sleep, soreness, energy, stress)
- Available foods (if provided)
- Context-specific guidelines

### Step 4: Generate Recommendation
- Call OpenAI GPT-4 mini (cost-effective, fast)
- Request JSON-formatted response
- Validate structure

### Step 5: Save and Return
- Store recommendation in database with full context
- Return structured response to client

## Prompt Engineering

### Pre-Workout (1-2 hours before)
- Prioritize easily digestible carbs (30-40g)
- Moderate protein (15-20g)
- Lower fat to speed digestion

### Pre-Workout (2-4 hours before)
- Balanced meal
- Protein (25-35g)
- Complex carbs (40-60g)
- Moderate fats

### Post-Workout (within 2 hours)
- Protein-rich (30-40g) for recovery
- Fast carbs (40-50g) to replenish glycogen
- Minimal fat

### Low Recovery Considerations
- Lighter portions
- Easily digestible foods
- Anti-inflammatory options

### High Soreness
- Anti-inflammatory foods (omega-3s, berries, leafy greens)
- Adequate protein for repair
- Hydration emphasis

## Example Use Cases

### Case 1: Pre-Workout Snack
```json
{
  "patient_id": "user-123",
  "time_of_day": "2:30 PM",
  "context": {
    "next_workout_time": "4:00 PM",
    "workout_type": "Upper Body Strength"
  }
}
```

**AI Response:**
"Banana with 2 tablespoons almond butter and 1 scoop whey protein shake"
- Protein: 35g, Carbs: 45g, Fats: 18g, Calories: 470
- Reasoning: "Quick-digesting carbs and protein 90 minutes before workout. Light on fats for easy digestion."

### Case 2: Post-Workout Recovery
```json
{
  "patient_id": "user-123",
  "time_of_day": "5:30 PM"
}
```
(Function detects recently completed workout at 4:00 PM)

**AI Response:**
"Grilled salmon (6oz) with sweet potato (1 medium) and asparagus"
- Protein: 42g, Carbs: 50g, Fats: 14g, Calories: 490
- Reasoning: "Post-workout recovery meal within 90 minutes. High protein for muscle repair, complex carbs to replenish glycogen."

### Case 3: Low Recovery Day
```json
{
  "patient_id": "user-123",
  "time_of_day": "12:00 PM"
}
```
(Function detects readiness_score = 55, soreness = 8)

**AI Response:**
"Greek yogurt bowl with berries, honey, and chia seeds"
- Protein: 20g, Carbs: 35g, Fats: 8g, Calories: 290
- Reasoning: "Light, anti-inflammatory meal for low recovery day. Greek yogurt provides protein, berries reduce inflammation, easy to digest."

## Deployment

### Prerequisites
- Supabase project with Edge Functions enabled
- OpenAI API key set in project secrets
- Database migrations applied (BUILD 138)

### Deploy Command
```bash
cd /Users/expo/Code/expo/supabase/functions
supabase functions deploy ai-nutrition-recommendation
```

### Set Secrets
```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

### Test
```bash
curl -X POST https://your-project.supabase.co/functions/v1/ai-nutrition-recommendation \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <anon-key>" \
  -d '{
    "patient_id": "test-user-id",
    "time_of_day": "2:00 PM"
  }'
```

## Cost Analysis

### OpenAI API Costs (GPT-4 mini)
- Input: ~600 tokens per request (context + prompt)
- Output: ~300 tokens per response
- Total: ~900 tokens per recommendation

**Pricing (GPT-4 mini):**
- $0.150 per 1M input tokens
- $0.600 per 1M output tokens
- Cost per recommendation: ~$0.00027 (0.027 cents)

**With 30-minute cache:**
- Assuming 3 requests/day per user
- Actual API calls: ~1/day (due to caching)
- Monthly cost per user: $0.008
- 1000 active users: $8/month

## Performance

- **Latency:** 1-2 seconds (OpenAI API call)
- **Cached response:** <100ms
- **Database queries:** 4-5 per uncached request
- **Concurrent requests:** Scales with Supabase Edge Functions

## Monitoring

### Key Metrics
1. Cache hit rate (target: >60%)
2. Average response time
3. OpenAI API call frequency
4. Error rate
5. User satisfaction with recommendations

### Logging
- All errors logged to console
- OpenAI API errors captured
- Database query errors captured

## Future Enhancements

1. **Photo Analysis**: Use OpenAI Vision to estimate macros from meal photos
2. **Learning**: Track which recommendations users follow, improve over time
3. **Allergies/Preferences**: Filter foods based on user preferences
4. **Meal Plans**: Generate full-day meal plans instead of single meals
5. **Shopping Lists**: Auto-generate grocery lists from recommendations
6. **Integration**: Connect with MyFitnessPal, Lose It, etc.

## Security

- Row Level Security enforced on all tables
- Patients can only access their own data
- Therapists can view patient recommendations
- Service role key used server-side only
- Input validation on all parameters

## Troubleshooting

### "patient_id and time_of_day required"
- Ensure both fields present in request body

### "Failed to generate nutrition recommendation"
- Check OpenAI API key is set correctly
- Verify OpenAI account has credits
- Check network connectivity

### "Error fetching nutrition summary"
- Verify `get_daily_nutrition_summary` function exists
- Check patient has nutrition_goals record
- Ensure migrations applied

### Recommendations seem off-target
- Verify nutrition_goals are set for patient
- Check scheduled_sessions data is accurate
- Review daily_readiness entries

## Related Documentation

- [BUILD 138 Migration](../../migrations/20260108000003_create_nutrition_storage.sql)
- [Nutrition Logs Migration](../../migrations/20251215150000_create_nutrition_tracking.sql)
- [Daily Readiness System](../../migrations/20260105000010_create_daily_readiness.sql)
- [Scheduled Sessions](../../migrations/20251215120000_create_scheduled_sessions.sql)

## Changelog

### 2026-01-04 - Initial Implementation
- Created Edge Function for BUILD 138
- Context-aware recommendations
- 30-minute caching
- OpenAI GPT-4 mini integration
- Full context gathering (nutrition, workouts, recovery)
