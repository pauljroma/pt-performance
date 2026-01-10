# AI Meal Parser Edge Function

**Build 138 - Nutrition Tracking**

Parses natural language meal descriptions into structured macro data using OpenAI GPT models.

## Overview

This Edge Function analyzes meal descriptions (text and/or photos) and returns structured nutrition data including:
- Meal type classification
- Individual food items
- Estimated calories and macronutrients
- AI confidence level

## Endpoint

```
POST /functions/v1/ai-meal-parser
```

## Request

### Headers
```
Authorization: Bearer <SUPABASE_ANON_KEY>
Content-Type: application/json
```

### Body

```typescript
{
  description: string;   // Required: Natural language meal description
  image_url?: string;    // Optional: URL to meal photo in Supabase Storage
}
```

## Response

### Success (200)

```typescript
{
  success: true,
  parsed_meal: {
    meal_type: 'breakfast' | 'lunch' | 'dinner' | 'snack',
    foods: string[],              // Individual food items identified
    calories: number,             // Total estimated calories
    protein: number,              // Protein in grams (1 decimal)
    carbs: number,                // Carbs in grams (1 decimal)
    fats: number,                 // Fats in grams (1 decimal)
    ai_confidence: 'high' | 'medium' | 'low'
  },
  model_used: string,             // 'gpt-4-vision-preview' or 'gpt-4o-mini'
  tokens_used: number
}
```

### Error (400/500)

```typescript
{
  success: false,
  error: string
}
```

## AI Model Selection

- **Text-only** (`description` provided): Uses `gpt-4o-mini` (faster, cheaper)
- **With image** (`image_url` provided): Uses `gpt-4-vision-preview` (multimodal analysis)

## Confidence Levels

### High Confidence
- Description includes specific foods AND portions
- Example: "8oz grilled chicken breast, 1 cup brown rice, 1 cup steamed broccoli"

### Medium Confidence
- Description includes specific foods WITHOUT portions
- Example: "chicken breast with rice and vegetables"

### Low Confidence
- Vague or generic descriptions
- Example: "lunch", "had some food", "ate dinner"

## Usage Examples

### Example 1: Text-Only Description

```bash
curl -X POST 'https://<project-ref>.supabase.co/functions/v1/ai-meal-parser' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "8oz grilled chicken breast with 1 cup brown rice and steamed broccoli"
  }'
```

**Response:**
```json
{
  "success": true,
  "parsed_meal": {
    "meal_type": "lunch",
    "foods": ["8oz grilled chicken breast", "1 cup brown rice", "steamed broccoli"],
    "calories": 520,
    "protein": 62.0,
    "carbs": 50.0,
    "fats": 8.0,
    "ai_confidence": "high"
  },
  "model_used": "gpt-4o-mini",
  "tokens_used": 245
}
```

### Example 2: Vague Description (Low Confidence)

```bash
curl -X POST 'https://<project-ref>.supabase.co/functions/v1/ai-meal-parser' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "had lunch"
  }'
```

**Response:**
```json
{
  "success": true,
  "parsed_meal": {
    "meal_type": "lunch",
    "foods": ["generic lunch meal"],
    "calories": 600,
    "protein": 30.0,
    "carbs": 70.0,
    "fats": 20.0,
    "ai_confidence": "low"
  },
  "model_used": "gpt-4o-mini",
  "tokens_used": 180
}
```

### Example 3: With Meal Photo

```bash
curl -X POST 'https://<project-ref>.supabase.co/functions/v1/ai-meal-parser' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "my dinner tonight",
    "image_url": "https://<project-ref>.supabase.co/storage/v1/object/public/meal_photos/<patient-id>/meal_123.jpg"
  }'
```

**Response:**
```json
{
  "success": true,
  "parsed_meal": {
    "meal_type": "dinner",
    "foods": ["grilled salmon fillet", "roasted sweet potato", "mixed green salad", "olive oil dressing"],
    "calories": 650,
    "protein": 45.0,
    "carbs": 48.0,
    "fats": 28.0,
    "ai_confidence": "high"
  },
  "model_used": "gpt-4-vision-preview",
  "tokens_used": 890
}
```

## iOS Integration

```swift
func parseMeal(description: String, photoURL: String? = nil) async throws -> ParsedMeal {
    let requestBody: [String: Any] = [
        "description": description,
        "image_url": photoURL as Any
    ].compactMapValues { $0 }

    let url = URL(string: "\(supabaseURL)/functions/v1/ai-meal-parser")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        throw NSError(domain: "MealParser", code: -1)
    }

    let result = try JSONDecoder().decode(MealParserResponse.self, from: data)
    return result.parsed_meal
}
```

## Nutrition Logging Flow

1. **User Input**: Patient types meal description or uploads photo
2. **Parse**: Call `ai-meal-parser` function
3. **Review**: Display parsed macros to user for confirmation/editing
4. **Save**: Insert to `nutrition_logs` table with `ai_generated = true`

```sql
INSERT INTO nutrition_logs (
    patient_id,
    meal_type,
    description,
    calories,
    protein_grams,
    carbs_grams,
    fats_grams,
    photo_url,
    ai_generated
) VALUES (
    $1,  -- patient_id
    $2,  -- meal_type from parsed_meal
    $3,  -- original description
    $4,  -- calories from parsed_meal
    $5,  -- protein from parsed_meal
    $6,  -- carbs from parsed_meal
    $7,  -- fats from parsed_meal
    $8,  -- image_url (if provided)
    true -- ai_generated
);
```

## Macro Validation

The function validates that macros are physiologically reasonable:

- **Protein**: 4 calories per gram
- **Carbs**: 4 calories per gram
- **Fats**: 9 calories per gram

Formula: `(protein * 4) + (carbs * 4) + (fats * 9) ≈ calories`

All macros are rounded to 1 decimal place for consistency.

## Cost Considerations

### GPT-4o-mini (text-only)
- **Cost**: ~$0.15 per 1M input tokens, ~$0.60 per 1M output tokens
- **Typical usage**: ~250 tokens per request
- **Estimated cost**: ~$0.0002 per request

### GPT-4 Vision (with photo)
- **Cost**: ~$10 per 1M input tokens, ~$30 per 1M output tokens
- **Typical usage**: ~900 tokens per request
- **Estimated cost**: ~$0.01 per request

**Recommendation**: Encourage text descriptions when possible, use photos for complex/ambiguous meals.

## Error Handling

Common errors and solutions:

| Error | Cause | Solution |
|-------|-------|----------|
| `description is required` | Missing or empty description | Provide non-empty description |
| `Failed to parse AI response` | OpenAI returned invalid JSON | Retry request, check API logs |
| `OpenAI API failed: 401` | Invalid OPENAI_API_KEY | Update Supabase secrets |
| `OpenAI API failed: 429` | Rate limit exceeded | Implement retry with backoff |

## Environment Variables

Required in Supabase Edge Functions secrets:

```bash
OPENAI_API_KEY=sk-...
```

Set via Supabase CLI:
```bash
supabase secrets set OPENAI_API_KEY=sk-...
```

## Testing

See `test_meal_parser.sh` for integration tests.

## Deployment

```bash
cd /Users/expo/Code/expo/supabase/functions
supabase functions deploy ai-meal-parser
```

## Related Files

- **Database**: `/supabase/migrations/20260108000003_create_nutrition_storage.sql`
- **iOS Models**: (to be implemented in Agent 6)
- **iOS Views**: (to be implemented in Agent 6)

## Version History

- **v1.0** (BUILD 138): Initial implementation
  - Natural language parsing
  - Vision support for meal photos
  - Confidence scoring
  - Macro estimation
