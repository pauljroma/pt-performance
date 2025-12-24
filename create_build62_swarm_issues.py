#!/usr/bin/env python3
"""Create Build 62 Linear issues for Patient Communication, Video Library, and AI Chat"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"  # "Todo" state

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, priority=2):
    """Create a Linear issue"""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
            success
            issue {
                id
                identifier
                title
                url
            }
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {
                "input": {
                    "teamId": ACP_TEAM_ID,
                    "title": title,
                    "description": description,
                    "priority": priority,
                    "stateId": ACP_TODO_STATE_ID
                }
            }
        },
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueCreate", {}).get("success"):
                issue = data["data"]["issueCreate"]["issue"]
                return issue
            else:
                print(f"  Error: {data}")
        except Exception as e:
            print(f"  Error parsing response: {e}")
            print(f"  Response: {response.text}")
    else:
        print(f"  HTTP {response.status_code}: {response.text}")
    return None

print("="*80)
print("Build 62 - Creating Linear Issues")
print("="*80)
print()

issues_to_create = [
    {
        "title": "Build 62 Agent 1: Patient Communication System",
        "description": """Create in-app messaging system between therapist and patient with video upload

**Core Deliverables:**
1. **MessageThread.swift** (new) - Thread model with video support
2. **Message.swift** (new) - Message model (text, video, image types)
3. **MessagingService.swift** (new) - Supabase realtime messaging
4. **MessageThreadView.swift** (new) - Thread list view
5. **ChatView.swift** (new) - Conversation interface
6. **VideoRecorderView.swift** (new) - In-app video recording
7. **VideoPlayerView.swift** (update) - Enhanced for form check playback
8. **FormCheckAnnotationView.swift** (new) - Drawing annotations on video frames

**Database Schema:**
```sql
-- Message threads
CREATE TABLE message_threads (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  patient_id UUID REFERENCES profiles(id),
  therapist_id UUID REFERENCES profiles(id),
  last_message_at TIMESTAMPTZ,
  unread_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Messages
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  thread_id UUID REFERENCES message_threads(id),
  sender_id UUID REFERENCES profiles(id),
  message_type TEXT CHECK (message_type IN ('text', 'video', 'image', 'form_check')),
  content TEXT,
  media_url TEXT,
  video_thumbnail_url TEXT,
  annotations JSONB,  -- For form check annotations
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Video Form Check Features:**
- Record video (max 2 minutes)
- Upload to Supabase Storage
- Therapist can annotate specific frames
- Drawing tools (arrows, circles, text)
- Playback controls (slow-motion, frame-by-frame)

**Real-time Features:**
- Supabase Realtime subscriptions
- Typing indicators
- Read receipts
- Push notifications (future build)

**Acceptance Criteria:**
- ✅ Patient can send text messages to therapist
- ✅ Patient can record and send form check videos
- ✅ Therapist receives real-time notifications
- ✅ Therapist can annotate videos with feedback
- ✅ Video uploads compressed and optimized
- ✅ All messages encrypted at rest
- ✅ RLS policies enforce privacy

**Estimated Effort:** 8-10 hours
**Priority:** P0 (Critical)
**Dependencies:** Supabase Storage, Realtime
""",
        "priority": 1  # Urgent
    },
    {
        "title": "Build 62 Agent 2: Exercise Video Library",
        "description": """Build comprehensive exercise technique video library

**Deliverables:**
1. **VideoLibraryView.swift** (new) - Browse all exercise videos
2. **VideoCategory.swift** (new) - Category model (body part, equipment)
3. **ExerciseVideoDetail.swift** (new) - Full video player with technique cues
4. **VideoDownloadManager.swift** (new) - Offline video caching
5. **20251218000000_seed_exercise_videos.sql** (new) - Seed 50+ videos

**Database Updates:**
```sql
-- Update exercise_templates to add video metadata
ALTER TABLE exercise_templates ADD COLUMN video_duration INT;
ALTER TABLE exercise_templates ADD COLUMN video_file_size BIGINT;
ALTER TABLE exercise_templates ADD COLUMN video_thumbnail_timestamp FLOAT;

-- Create video categories
CREATE TABLE video_categories (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name TEXT NOT NULL,
  icon TEXT,
  sort_order INT
);

-- Link exercises to categories
CREATE TABLE exercise_video_categories (
  exercise_id UUID REFERENCES exercise_templates(id),
  category_id UUID REFERENCES video_categories(id),
  PRIMARY KEY (exercise_id, category_id)
);
```

**Video Library Features:**
- Browse by body part (Upper, Lower, Core)
- Browse by equipment (Barbell, Dumbbell, Bodyweight, Machine)
- Search by exercise name
- Filter by difficulty level
- Mark favorites
- Download for offline viewing
- Slow-motion playback
- Looping option

**Video Content (Initial 50 exercises):**
- 15 upper body (push, pull, shoulders)
- 15 lower body (squat, hinge, lunge)
- 10 core exercises
- 10 accessory movements

**Video Specs:**
- Format: MP4 (H.264)
- Resolution: 1080p
- Duration: 30-90 seconds per video
- Size: 5-15MB per video (compressed)
- Hosted: Supabase Storage

**Acceptance Criteria:**
- ✅ 50+ exercise videos seeded
- ✅ Browse by category works smoothly
- ✅ Search returns relevant results
- ✅ Videos play without buffering
- ✅ Offline download works
- ✅ Slow-motion and looping work
- ✅ Integrates with existing ExerciseTechniqueView

**Estimated Effort:** 6-8 hours (code) + video content acquisition
**Priority:** P0 (Critical)
**Dependencies:** Video content, Supabase Storage
""",
        "priority": 1  # Urgent
    },
    {
        "title": "Build 62 Agent 3: AI Exercise Assistant",
        "description": """Build AI-powered chat assistant for exercise questions

**Deliverables:**
1. **AIAssistantView.swift** (new) - Chat interface
2. **AIAssistantService.swift** (new) - OpenAI/Anthropic API integration
3. **ExerciseContext.swift** (new) - Exercise knowledge base
4. **AssistantMessage.swift** (new) - Message model
5. **QuickPrompts.swift** (new) - Suggested questions UI

**AI Capabilities:**
- **Exercise Substitutions:** "What can I use instead of barbell squats?"
- **Technique Questions:** "How do I improve my deadlift form?"
- **Programming Advice:** "Should I do more volume or intensity?"
- **Injury Modifications:** "I have shoulder pain, what exercises are safe?"
- **Equipment Alternatives:** "I only have dumbbells, what can I do?"

**Integration Features:**
- Context-aware (knows user's current program)
- Exercise database integration
- Video recommendations from library
- Cites research/sources when available
- Safe, conservative advice (disclaimers for medical issues)

**System Prompt Template:**
```
You are a physical therapy AI assistant helping patients with exercise questions.
You have access to:
- Exercise technique database
- User's current program: {program_data}
- Exercise video library
- Common substitutions and progressions

Provide helpful, safe, conservative advice. Always recommend consulting
their therapist for personalized guidance. Cite sources when possible.
```

**UI Features:**
- Chat bubbles (user vs AI)
- Quick prompt chips ("Find substitutions", "Check technique", "Equipment alternatives")
- Exercise card embeds in responses
- Video previews inline
- Share conversation with therapist
- Conversation history

**Database Schema:**
```sql
CREATE TABLE ai_conversations (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID REFERENCES profiles(id),
  title TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE ai_messages (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID REFERENCES ai_conversations(id),
  role TEXT CHECK (role IN ('user', 'assistant')),
  content TEXT,
  context_data JSONB,  -- Exercise IDs, program data referenced
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Safety & Compliance:**
- Disclaimer: "This is educational information, not medical advice"
- Flag medical/injury questions for therapist review
- Don't diagnose conditions
- Encourage consulting licensed professionals
- Privacy: conversations encrypted, user can delete

**Acceptance Criteria:**
- ✅ Chat interface is responsive and intuitive
- ✅ AI provides helpful exercise substitutions
- ✅ AI explains technique with video references
- ✅ Quick prompts work for common questions
- ✅ Context includes user's program data
- ✅ Disclaimers shown appropriately
- ✅ Conversation can be shared with therapist
- ✅ API costs are reasonable (<$0.05 per conversation)

**Estimated Effort:** 6-8 hours
**Priority:** P1 (High)
**Dependencies:** OpenAI or Anthropic API key
**API Cost Estimate:** ~$0.02-0.05 per conversation (using GPT-4 or Claude)
""",
        "priority": 2  # High
    },
    {
        "title": "Build 62 Agent 4: Integration & Testing",
        "description": """Integrate all Build 62 features and test comprehensively

**Tasks:**
1. **Add all new files to Xcode project**
   - Run Ruby integration script
   - Verify all files in correct groups
   - Check build phases

2. **Database Migration Application**
   - Apply message_threads, messages tables
   - Apply video_categories, exercise_video_categories tables
   - Apply ai_conversations, ai_messages tables
   - Seed video library data
   - Test RLS policies

3. **Feature Integration Testing**
   - Test messaging with video upload
   - Test video library browsing and download
   - Test AI assistant with real questions
   - Test cross-feature integration (e.g., AI recommending video from library)

4. **Security & Privacy Review**
   - Verify RLS policies on all new tables
   - Test that patients can't see other patients' messages
   - Test video upload size limits
   - Test API key security (not exposed in client)

5. **Performance Testing**
   - Video upload speed (compress before upload)
   - Video playback smoothness
   - AI response time (<3 seconds)
   - Real-time message delivery (<1 second)

6. **Build Number & Deployment**
   - Increment build number to 62
   - Update Config.swift
   - Archive and upload to TestFlight
   - Update Linear issues to Done

**Acceptance Criteria:**
- ✅ All features compiled without errors
- ✅ All database migrations applied successfully
- ✅ All tests pass
- ✅ Performance benchmarks met
- ✅ Security review complete
- ✅ Build 62 on TestFlight

**Estimated Effort:** 4-6 hours
**Priority:** P0 (Critical)
**Dependencies:** Agents 1, 2, 3 complete
""",
        "priority": 1  # Urgent
    },
    {
        "title": "Build 62 Swarm Coordination",
        "description": """Coordinate Build 62 swarm execution

**Swarm Structure:**
- Agent 1: Patient Communication (8-10 hours)
- Agent 2: Exercise Video Library (6-8 hours)
- Agent 3: AI Exercise Assistant (6-8 hours)
- Agent 4: Integration & Testing (4-6 hours)

**Execution Plan:**
1. Agents 1, 2, 3 work in parallel (no dependencies)
2. Agent 4 runs after 1, 2, 3 complete
3. Coordinator monitors progress and unblocks issues

**Success Metrics:**
- All 4 agents complete successfully
- Build 62 deployed to TestFlight
- Zero regressions from Build 61
- All acceptance criteria met

**Deliverables:**
- BUILD62_SWARM_SUMMARY.md
- BUILD62_DEPLOYMENT.md
- All Linear issues marked Done

**Estimated Total Time:** 24-32 hours (8-10 hours with parallelization)
**Priority:** P0 (Critical)
""",
        "priority": 1  # Urgent
    }
]

created_issues = []

for issue_data in issues_to_create:
    print(f"Creating: {issue_data['title']}")
    issue = create_issue(
        issue_data["title"],
        issue_data["description"],
        issue_data["priority"]
    )

    if issue:
        print(f"  ✅ Created: {issue['identifier']}")
        print(f"     URL: {issue['url']}")
        created_issues.append(issue)
    else:
        print(f"  ❌ Failed to create issue")
    print()

print("="*80)
print("Build 62 Linear Issues Created")
print("="*80)
print()
print("Summary:")
for issue in created_issues:
    print(f"  • {issue['identifier']}: {issue['title']}")
print()
print(f"Total issues created: {len(created_issues)}/5")
print()
