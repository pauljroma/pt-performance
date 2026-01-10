# AI Helper Edge Functions - Quick Reference

**Build 79 - Agent 2**
**Created:** 2025-12-24

## Overview

Two OpenAI-powered Edge Functions for PT Performance AI Helper MVP:
1. **ai-chat-completion** - Real-time AI assistant chat
2. **ai-exercise-substitution** - Intelligent exercise alternatives

---

## Quick Start

### 1. Deploy to Supabase

```bash
cd /Users/expo/Code/expo
./supabase/functions/deploy_ai_functions.sh
```

### 2. Set Environment Variables

**CRITICAL: AI Chat will NOT work without OPENAI_API_KEY**

**Option 1: Via Supabase Dashboard (RECOMMENDED for Production)**
1. Go to [Supabase Dashboard](https://app.supabase.com/project/rpbxeaxlaoyoqkohytlw/settings/functions)
2. Navigate to: **Settings → Edge Functions → Secrets**
3. Click **"Add new secret"**
4. Set:
   - **Name:** `OPENAI_API_KEY`
   - **Value:** `sk-proj-...` (your OpenAI API key)
5. Click **Save**
6. Redeploy functions: `./supabase/functions/deploy_ai_functions.sh`

**Option 2: Via Supabase CLI**
```bash
supabase login
supabase secrets set OPENAI_API_KEY=sk-proj-YOUR_KEY --project-ref rpbxeaxlaoyoqkohytlw
```

**Option 3: For Local Development**
Create `supabase/.env.local`:
```bash
OPENAI_API_KEY=sk-proj-YOUR_KEY_HERE
SUPABASE_URL=http://localhost:54321
SUPABASE_SERVICE_ROLE_KEY=YOUR_LOCAL_SERVICE_KEY
```

### 3. Test Locally

```bash
cd /Users/expo/Code/expo/supabase
supabase start
supabase functions serve ai-chat-completion --env-file .env.local
```

---

## Function 1: ai-chat-completion

**Endpoint:** `/functions/v1/ai-chat-completion`

**Purpose:** Conversational AI assistant for patients

**Request:**
```json
{
  "athlete_id": "uuid",
  "message": "What exercises should I do today?",
  "session_id": "uuid" // Optional: resume session
}
```

**Response:**
```json
{
  "success": true,
  "session_id": "uuid",
  "message": "AI response here...",
  "tokens_used": 450,
  "model": "gpt-4-turbo-preview",
  "duration_ms": 1200
}
```

**Features:**
- ✅ Context-aware (athlete profile, injuries, program)
- ✅ Conversation history (last 10 messages)
- ✅ Safety-first responses
- ✅ Token tracking
- ✅ Session management

**Cost:** ~$0.005-0.015 per chat exchange

---

## Function 2: ai-exercise-substitution

**Endpoint:** `/functions/v1/ai-exercise-substitution`

**Purpose:** Find exercise alternatives based on equipment/injuries

**Request:**
```json
{
  "athlete_id": "uuid",
  "exercise_id": "uuid",
  "reason": "No barbell available"
}
```

**Response:**
```json
{
  "success": true,
  "substitution": {
    "id": "uuid",
    "original_exercise_id": "uuid",
    "suggested_exercise_id": "uuid",
    "reason": "Dumbbell bench press targets same muscles...",
    "ai_confidence": 92.5
  },
  "ai_suggestion": {
    "exercise_name": "Dumbbell Bench Press",
    "confidence": 0.925,
    "alternative_exercises": ["Push-ups", "Cable Chest Press"]
  },
  "found_in_database": true,
  "tokens_used": 280
}
```

**Features:**
- ✅ Muscle group matching
- ✅ Injury contraindication awareness
- ✅ Equipment availability checking
- ✅ Confidence scoring
- ✅ Multiple alternatives if low confidence

**Cost:** ~$0.003-0.008 per substitution

---

## Database Tables

### ai_chat_sessions
Tracks chat conversations
- `id`, `athlete_id`, `started_at`, `message_count`, `total_tokens_used`

### ai_chat_messages
Individual messages in sessions
- `id`, `session_id`, `role`, `content`, `tokens_used`, `model`

### ai_exercise_substitutions
Exercise alternatives suggested
- `id`, `athlete_id`, `original_exercise_id`, `suggested_exercise_id`, `reason`, `ai_confidence`, `accepted`

---

## Testing

### Manual Test - Chat
```bash
curl -X POST http://localhost:54321/functions/v1/ai-chat-completion \
  -H 'Content-Type: application/json' \
  -d '{
    "athlete_id": "test-uuid",
    "message": "How should I warm up before squats?"
  }'
```

### Manual Test - Substitution
```bash
curl -X POST http://localhost:54321/functions/v1/ai-exercise-substitution \
  -H 'Content-Type: application/json' \
  -d '{
    "athlete_id": "test-uuid",
    "exercise_id": "exercise-uuid",
    "reason": "Shoulder pain during overhead press"
  }'
```

### Automated Tests
```bash
./supabase/functions/test_ai_functions.sh
```

---

## Error Handling

### Common Errors

**400 Bad Request:**
- Missing required fields
- Invalid UUID format
- Message too long (>2000 chars)

**404 Not Found:**
- Invalid athlete_id
- Invalid exercise_id

**500 Internal Server Error:**
- OpenAI API error
- Database connection error
- Missing OPENAI_API_KEY

---

## Cost Monitoring

### Token Usage Estimates
- Chat completion: ~500 tokens/request
- Exercise substitution: ~300 tokens/request

### Monthly Projections
- 100 patients, 5 chats/day: ~$150/month
- 100 patients, 2 substitutions/week: ~$4/month
- **Total: ~$1.54/patient/month**

### Track Costs
Monitor in `ai_chat_sessions.total_tokens_used` and function logs

---

## iOS Integration

```swift
class AIAssistantService {
    func sendMessage(_ message: String) async throws -> String {
        let url = URL(string: "\(supabaseURL)/functions/v1/ai-chat-completion")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")

        let body = [
            "athlete_id": currentUserId,
            "message": message
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(AIResponse.self, from: data)
        return response.message
    }
}
```

---

## Production Checklist

- [ ] Set OPENAI_API_KEY in Supabase Dashboard
- [ ] Deploy functions: `./supabase/functions/deploy_ai_functions.sh`
- [ ] Test endpoints with curl commands
- [ ] Monitor function logs for errors
- [ ] Set up cost alerts in OpenAI dashboard
- [ ] Add rate limiting for production (optional)
- [ ] Enable Sentry/logging for errors (optional)

---

## Support & Documentation

**Full Documentation:** `.outcomes/build79_agent2_openai.md`

**Function Code:**
- `supabase/functions/ai-chat-completion/index.ts`
- `supabase/functions/ai-exercise-substitution/index.ts`

**Scripts:**
- `supabase/functions/deploy_ai_functions.sh`
- `supabase/functions/test_ai_functions.sh`

---

## Next Steps

**Agent 3:** iOS UI Components
- AI Chat View with message bubbles
- Exercise substitution modal
- Loading/error states

**Agent 4:** Integration & Testing
- Connect iOS to edge functions
- End-to-end testing
- Performance optimization
