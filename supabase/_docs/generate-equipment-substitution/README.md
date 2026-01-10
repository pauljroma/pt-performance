# Generate Equipment Substitution Edge Function

**BUILD 138** - Exercise Substitution System

## Overview

This Edge Function generates AI-powered exercise substitutions based on equipment availability and patient recovery data. It follows a **RULES-FIRST** approach where AI selects from pre-vetted candidate exercises only.

## Key Features

- **Pre-vetted Candidates Only**: AI selects ONLY from exercises in `exercise_substitution_candidates` table
- **Equipment-Based Filtering**: Automatically filters candidates by available equipment
- **Recovery-Aware Adjustments**: Adjusts intensity based on WHOOP recovery scores and readiness
- **Structured Output**: Returns JSONB patch ready for application to session instances

## Request Format

```typescript
POST /generate-equipment-substitution

{
  "patient_id": "uuid",
  "session_id": "uuid",
  "scheduled_date": "2025-01-08",
  "equipment_available": ["dumbbells", "resistance_band"],
  "intensity_preference": "recovery" | "standard" | "go_hard",
  "readiness_score": 75,        // Optional: 0-100
  "whoop_recovery_score": 58    // Optional: 0-100
}
```

## Response Format

```typescript
{
  "success": true,
  "recommendation_id": "uuid",
  "patch": {
    "exercise_substitutions": [
      {
        "original_exercise_id": "uuid",
        "original_exercise_name": "Barbell Bench Press",
        "substitute_exercise_id": "uuid",
        "substitute_exercise_name": "Dumbbell Bench Press",
        "reason": "Selected due to equipment availability. Maintains horizontal press pattern with similar muscle activation."
      }
    ],
    "intensity_adjustments": [
      {
        "exercise_id": "uuid",
        "exercise_name": "Dumbbell Bench Press",
        "original_sets": 3,
        "adjusted_sets": 3,
        "original_reps": 10,
        "adjusted_reps": 8,
        "original_rpe": 7,
        "adjusted_rpe": 6,
        "reason": "Reduced volume due to WHOOP recovery score of 58 (< 60 threshold)"
      }
    ]
  },
  "rationale": "Overall substitution plan based on available equipment and patient recovery status",
  "status": "pending",
  "tokens_used": 1250,
  "exercises_substituted": 1
}
```

## Algorithm

1. **Fetch Session Exercises**: Query `session_exercises` joined with `exercise_templates`
2. **Detect Mismatches**: Compare exercise equipment requirements with `equipment_available`
3. **Query Candidates**: Use `get_substitution_candidates()` RPC function for each exercise
4. **Build AI Prompt**: Include ONLY pre-vetted candidates (rules-first)
5. **Call OpenAI**: Select best candidate and adjust intensity
6. **Validate Selection**: Ensure AI picked from candidate list only
7. **Save Recommendation**: Insert into `recommendations` table with status='pending'
8. **Return JSONB Patch**: Client applies to create `session_instance`

## Intensity Adjustment Rules

### WHOOP Recovery Score < 60
- Reduce sets/reps by 10-20%
- Reduce RPE by 1-2 points
- Prioritize easier substitutes (negative difficulty_delta)

### Intensity Preference = 'recovery'
- Reduce RPE by 1-2 points
- Select easier substitutes when available

### Intensity Preference = 'go_hard'
- Can increase RPE by 1 if recovery > 80
- Select similar or slightly harder substitutes

## Error Handling

### No Equipment Mismatches
```json
{
  "message": "No equipment mismatches detected - all exercises can be performed",
  "exercises_checked": 5
}
```

### No Candidates Found
```json
{
  "error": "No pre-vetted substitution candidates found for: Barbell Squat, Leg Press",
  "exercises_without_candidates": 2
}
```

### AI Selection Validation Failure
```json
{
  "error": "AI selected exercise not in pre-vetted candidates: Kettlebell Swing"
}
```

## Database Schema Dependencies

### Tables
- `session_exercises` - Source exercises for the session
- `exercise_templates` - Exercise metadata and equipment requirements
- `exercise_substitution_candidates` - Pre-vetted substitution pairs
- `recommendations` - Stores generated recommendations
- `patients` - Patient context
- `sessions` - Session metadata

### RPC Functions
- `get_substitution_candidates(p_original_exercise_id, p_equipment_available)` - Returns filtered candidates

## Environment Variables

- `SUPABASE_URL` - Supabase project URL
- `SUPABASE_SERVICE_ROLE_KEY` - Service role key for database access
- `OPENAI_API_KEY` - OpenAI API key for GPT-4 calls

## Deployment

```bash
# Deploy function
supabase functions deploy generate-equipment-substitution

# Test locally
supabase functions serve generate-equipment-substitution

# Test with curl
curl -X POST 'http://localhost:54321/functions/v1/generate-equipment-substitution' \
  -H 'Authorization: Bearer YOUR_ANON_KEY' \
  -H 'Content-Type: application/json' \
  -d '{
    "patient_id": "...",
    "session_id": "...",
    "scheduled_date": "2025-01-08",
    "equipment_available": ["dumbbells"],
    "intensity_preference": "standard"
  }'
```

## Usage Example

```typescript
// iOS Swift client
let request = GenerateSubstitutionRequest(
    patientId: patient.id,
    sessionId: session.id,
    scheduledDate: "2025-01-08",
    equipmentAvailable: ["dumbbells", "resistance_band"],
    intensityPreference: "recovery",
    readinessScore: readiness.score,
    whoopRecoveryScore: whoop.recoveryScore
)

let response = try await supabase.functions
    .invoke("generate-equipment-substitution", options: FunctionInvokeOptions(body: request))

// Apply recommendation (creates session_instance)
await applyRecommendation(recommendationId: response.recommendation_id)
```

## Performance Metrics

- **Average OpenAI Tokens**: 1000-2000 per request
- **Average Latency**: 2-4 seconds
- **Cache Strategy**: Pre-vetted candidates cached in database

## Safety Features

1. **Rules-First Validation**: AI CANNOT suggest arbitrary exercises
2. **Equipment Filtering**: Only candidates matching available equipment
3. **Conservative Defaults**: Low recovery triggers protective adjustments
4. **Audit Trail**: All recommendations logged with full rationale

## Future Enhancements

- [ ] Support for multi-session substitution planning
- [ ] Preference learning (track accepted vs rejected substitutions)
- [ ] Integration with injury contraindications
- [ ] Real-time candidate ranking based on patient history

## Related Documentation

- [BUILD 138 Migration](../../migrations/20260108000001_create_substitution_system.sql)
- [Substitution System Overview](../../../docs/SUBSTITUTION_SYSTEM.md)
- [Edge Functions README](../AI_FUNCTIONS_README.md)
