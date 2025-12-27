# AI Safety Check Edge Function

**Build 79 - Agent 3: Claude Safety Integration**

## Overview

Supabase Edge Function that performs medical safety analysis using Anthropic's Claude 3.5 Sonnet to detect contraindications between prescribed exercises and athlete injury history.

## Purpose

- **Primary**: Prevent re-injury by flagging biomechanical conflicts between exercises and active injuries
- **Secondary**: Consider recovery state (WHOOP data) when assessing exercise appropriateness
- **Tertiary**: Provide actionable alternatives when contraindications are detected

## Architecture

### Two-Tier Analysis System

1. **Fast Path (Rule-Based)**
   - Quick pattern matching for common contraindications
   - Returns immediately for critical dangers
   - Zero API cost, <100ms response time

2. **Comprehensive Path (Claude AI)**
   - Nuanced biomechanical analysis
   - Considers injury severity, recovery state, and exercise complexity
   - Provides detailed reasoning and recommendations

## Warning Levels

| Level | Description | Should Alert? | Action |
|-------|-------------|---------------|--------|
| `info` | No contraindications detected | No | Exercise is safe to perform |
| `caution` | Minor concerns, monitoring suggested | No | Proceed with awareness, consider modifications |
| `warning` | Significant concerns, may impede recovery | Yes | Exercise risky, alternatives recommended |
| `danger` | Critical contraindication detected | Yes | Do not perform exercise |

## API Reference

### Endpoint

```
POST /ai-safety-check
```

### Request Body

```typescript
{
  athlete_id: string;      // UUID of athlete
  exercise_id: string;     // UUID of exercise template
  context?: {              // Optional context
    session_id?: string;   // Current session
    program_id?: string;   // Current program
  }
}
```

### Response

```typescript
{
  success: boolean;
  safety_check: {
    id: string;
    athlete_id: string;
    exercise_id: string;
    warning_level: "info" | "caution" | "warning" | "danger";
    reason: string;
    ai_analysis: {
      detailed_analysis: string;
      recommendations: string[];
      model: string;
      tokens_used: number;
      fast_path: boolean;
    };
    created_at: string;
  };
  should_alert: boolean;
  fast_path: boolean;
}
```

### Example Request

```bash
curl -X POST https://your-project.supabase.co/functions/v1/ai-safety-check \
  -H "Authorization: Bearer YOUR_AUTH_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "athlete_id": "123e4567-e89b-12d3-a456-426614174000",
    "exercise_id": "987fcdeb-51a2-43f7-8e5d-426614174001"
  }'
```

## Contraindication Rules

### Shoulder

Flags exercises: overhead press, pull-up, shoulder press, snatch, throwing

### Knee

Flags exercises: squat, lunge, running, jump, plyometrics

### Lower Back

Flags exercises: deadlift, good morning, back squat, romanian deadlift

### Elbow

Flags exercises: bench press, overhead press, tricep extension, dips, throwing

### Ankle

Flags exercises: running, jumping, calf raises, sprinting

### Hip

Flags exercises: squat, lunge, deadlift, running, split squat

### Wrist

Flags exercises: push-up, plank, bench press, front squat, olympic lifts

## Data Sources

### Athlete Data

1. **Medical History** (`patients.medical_history`)
   - Active injuries with severity levels
   - Past surgeries and chronic conditions
   - Current medications

2. **Recovery Data** (`whoop_recovery`)
   - Recovery score (0-100%)
   - HRV and resting heart rate
   - Sleep performance
   - Readiness band (green/yellow/red)

### Exercise Data

From `exercise_templates` table:
- Name and description
- Muscle groups targeted
- Movement patterns
- Load type
- Clinical tags

## Claude Prompt Engineering

### System Prompt

```
You are a medical safety analyzer specializing in sports medicine and
physical therapy. Your role is to identify contraindications between
prescribed exercises and patient injury history. Be conservative in
your analysis - patient safety is paramount. Provide clear, actionable
recommendations.
```

### Analysis Criteria

1. Biomechanical conflict detection
2. Loading pattern vs injury recovery phase
3. Recovery state assessment
4. Clinical tag red flags
5. Conservative risk evaluation

### Response Format

Claude returns structured JSON:

```json
{
  "warning_level": "info|caution|warning|danger",
  "reason": "Brief 1-2 sentence explanation",
  "detailed_analysis": "Comprehensive medical reasoning",
  "recommendations": ["Alternative 1", "Alternative 2"]
}
```

## Environment Variables

Required:

- `ANTHROPIC_API_KEY` - Anthropic API key for Claude access
- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access

## Database Schema

### ai_safety_checks Table

```sql
CREATE TABLE ai_safety_checks (
    id UUID PRIMARY KEY,
    athlete_id UUID REFERENCES patients(id),
    exercise_id UUID REFERENCES exercise_templates(id),
    warning_level TEXT CHECK (warning_level IN ('info', 'caution', 'warning', 'danger')),
    reason TEXT NOT NULL,
    ai_analysis JSONB,
    dismissed BOOLEAN DEFAULT FALSE,
    dismissed_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

## Error Handling

### Common Errors

| Error | Status | Cause |
|-------|--------|-------|
| `ANTHROPIC_API_KEY not configured` | 500 | Missing env var |
| `Athlete not found` | 404 | Invalid athlete_id |
| `Exercise not found` | 404 | Invalid exercise_id |
| `Database insert failed` | 500 | Database error |

### Fallback Behavior

If Claude API fails or returns unparseable response:
- Returns `caution` warning level
- Includes raw response in detailed_analysis
- Recommends manual review

## Performance

- **Fast Path**: <100ms (rule-based)
- **Claude Path**: ~2-4 seconds (API call + analysis)
- **Token Usage**: ~500-800 tokens per request
- **Cost**: ~$0.003 per Claude analysis

## Testing

See `test-cases.ts` for comprehensive test suite:

1. ✅ Shoulder injury + overhead press → DANGER
2. ✅ Knee injury + squat → WARNING
3. ✅ No injuries + any exercise → INFO
4. ✅ Low recovery + high intensity → CAUTION
5. ✅ Elbow injury + bench press → WARNING
6. ✅ Multiple injuries + olympic lift → DANGER
7. ✅ Resolved injury + cautious return → CAUTION

## Deployment

```bash
# Deploy function
supabase functions deploy ai-safety-check

# Set environment variables
supabase secrets set ANTHROPIC_API_KEY=your_api_key_here

# Test deployment
supabase functions invoke ai-safety-check --body '{"athlete_id":"...","exercise_id":"..."}'
```

## Integration Examples

### iOS (Swift)

```swift
func checkExerciseSafety(athleteId: UUID, exerciseId: UUID) async throws -> SafetyCheck {
    let url = URL(string: "\(supabaseUrl)/functions/v1/ai-safety-check")!

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = [
        "athlete_id": athleteId.uuidString,
        "exercise_id": exerciseId.uuidString
    ]
    request.httpBody = try JSONEncoder().encode(body)

    let (data, _) = try await URLSession.shared.data(for: request)
    let response = try JSONDecoder().decode(SafetyCheckResponse.self, from: data)

    return response.safety_check
}
```

### JavaScript

```javascript
const checkExerciseSafety = async (athleteId, exerciseId) => {
  const { data, error } = await supabase.functions.invoke('ai-safety-check', {
    body: { athlete_id: athleteId, exercise_id: exerciseId }
  });

  if (error) throw error;
  return data.safety_check;
};
```

## Future Enhancements

- [ ] Multi-exercise batch analysis
- [ ] Historical safety check trends
- [ ] Therapist override tracking
- [ ] Integration with program builder for proactive checking
- [ ] Custom contraindication rules per therapist
- [ ] Patient-specific risk profiles

## References

- Anthropic Claude API: https://docs.anthropic.com/
- Supabase Edge Functions: https://supabase.com/docs/guides/functions
- Build 79 Spec: See `.outcomes/build79_agent3_safety.md`
