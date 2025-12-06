#!/usr/bin/env python3
"""
Create Complete MVP Plan in Linear
Populates 5-phase build plan with ~50 issues
"""

import asyncio
import os
import sys

# Import both bootstrap (for label creation) and client (for queries)
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from linear_bootstrap import LinearBootstrap
from linear_client import LinearClient


# Define all issues across 5 phases
MVP_ISSUES = [
    # ========== PHASE 1: Foundation & Database ==========
    {
        "phase": 1,
        "title": "Apply Supabase Schema to Dev Project",
        "description": """Apply the complete Supabase schema from `infra/001_init_supabase.sql`.

**Acceptance Criteria:**
- All tables created successfully
- All views created (vw_patient_adherence, vw_pain_trend)
- Schema validated via Supabase dashboard
- No errors in migration

**Files:**
- infra/001_init_supabase.sql

**Commands:**
```bash
psql -h db.PROJECT.supabase.co -U postgres -d postgres -f infra/001_init_supabase.sql
```""",
        "priority": "High",
        "zones": ["zone-7", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 1,
        "title": "Configure Row-Level Security Policies",
        "description": """Implement RLS policies for patient data privacy.

**Acceptance Criteria:**
- Patients can only see their own data
- Therapists can see their assigned patients
- Service role can access all data
- Policies tested with demo users

**Tables to Secure:**
- patients, exercise_logs, pain_logs, session_notes, bullpen_logs, body_comp_measurements""",
        "priority": "High",
        "zones": ["zone-7", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 1,
        "title": "Seed Demo Therapist (PT Profile)",
        "description": """Create demo therapist account in Supabase.

**Acceptance Criteria:**
- Therapist record created
- Linked to Supabase auth user
- Visible in Supabase dashboard
- Email: demo-pt@ptperformance.app

**Data:**
- First name: Sarah
- Last name: Thompson
- Credentials placeholder""",
        "priority": "High",
        "zones": ["zone-7", "zone-8"],
        "estimate": 1,
    },
    {
        "phase": 1,
        "title": "Seed Demo Patient (John Brebbia Profile)",
        "description": """Create demo patient based on Brebbia XLS profile.

**Acceptance Criteria:**
- Patient record created with demographics
- Medical history as JSON
- Goals populated
- Assigned to demo therapist

**Reference:**
- docs/PT_APP_DATA_MODEL_FROM_XLS.md (Patient Demographics section)

**Data:**
- Name: John Brebbia
- Sport: Baseball
- Position: Pitcher
- Dominant hand: Right
- Height: 73 inches
- Weight: 195 lbs""",
        "priority": "High",
        "zones": ["zone-7", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 1,
        "title": "Seed 8-Week On-Ramp Program",
        "description": """Create complete 8-week on-ramp program for demo patient.

**Acceptance Criteria:**
- Program created with 4 phases
- 3 sessions per week (24 total sessions)
- Sessions include plyo, strength, mobility exercises
- Data matches XLS structure

**Reference:**
- docs/PT_APP_DATA_MODEL_FROM_XLS.md (8-Week On-Ramp section)

**Program Structure:**
- Phase 1 (Weeks 1-2): Foundation
- Phase 2 (Weeks 3-4): Build
- Phase 3 (Weeks 5-6): Intensify
- Phase 4 (Weeks 7-8): Peak""",
        "priority": "High",
        "zones": ["zone-7", "zone-8"],
        "estimate": 4,
    },
    {
        "phase": 1,
        "title": "Create Exercise Template Library",
        "description": """Populate exercise_templates table with common exercises.

**Acceptance Criteria:**
- 30+ exercise templates created
- Categories: strength, plyo, mobility, bullpen
- Load types defined (weight, bodyweight, time, distance)
- RM methods specified where applicable

**Exercise Examples:**
- Back Squat (strength, weight, Epley)
- Medicine Ball Slam (plyo, bodyweight)
- Shoulder External Rotation (mobility, bodyweight)
- Bullpen Session (bullpen, count)""",
        "priority": "Medium",
        "zones": ["zone-7", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 1,
        "title": "Test Database Views with Demo Data",
        "description": """Validate that views return correct data for demo patient.

**Acceptance Criteria:**
- vw_patient_adherence returns 0% (no logs yet)
- vw_pain_trend returns empty (no logs yet)
- Views execute without errors
- Document expected output in docs/ANALYTICS.md

**Queries to Test:**
```sql
SELECT * FROM vw_patient_adherence WHERE patient_id = '<demo-patient-id>';
SELECT * FROM vw_pain_trend WHERE patient_id = '<demo-patient-id>';
```""",
        "priority": "Medium",
        "zones": ["zone-7", "zone-8", "zone-10b"],
        "estimate": 2,
    },
    {
        "phase": 1,
        "title": "Create Agent Service Skeleton",
        "description": """Set up Node/Express backend with basic structure.

**Acceptance Criteria:**
- Express server runs on port 4000
- /health endpoint responds
- Environment config loaded from .env
- Supabase and Linear keys configured
- README with setup instructions

**Files:**
- agent-service/src/server.js (already exists)
- agent-service/.env (from .env.example)
- agent-service/README.md

**Test:**
```bash
curl http://localhost:4000/health
# Expected: {"status":"ok"}
```""",
        "priority": "High",
        "zones": ["zone-3c", "zone-12"],
        "estimate": 2,
    },
    {
        "phase": 1,
        "title": "Implement Supabase Client in Agent Service",
        "description": """Add Supabase client library to agent service.

**Acceptance Criteria:**
- @supabase/supabase-js installed
- Client initialized with service role key
- Test query fetches demo patient
- Error handling for connection failures

**Test Query:**
```javascript
const { data, error } = await supabase
  .from('patients')
  .select('*')
  .eq('first_name', 'John');
```""",
        "priority": "High",
        "zones": ["zone-3c", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 1,
        "title": "Create Phase 1 Handoff Document",
        "description": """Document Phase 1 completion and Phase 2 setup.

**Acceptance Criteria:**
- Handoff doc created in .outcomes/
- Lists all completed tasks
- Database connection details documented
- Phase 2 prerequisites listed
- Estimated tokens used: ~150K

**Template:**
```markdown
# Phase 1 Complete - Foundation & Database

## Completed
- Database schema applied
- Demo data seeded
- Agent service skeleton ready

## Phase 2 Prerequisites
- Supabase project URL
- Demo patient ID
- Demo therapist ID

## Next Steps
- Begin Phase 2: Patient Mobile Flow
```""",
        "priority": "Medium",
        "zones": ["zone-13"],
        "estimate": 1,
    },

    # ========== PHASE 2: Patient Mobile Flow ==========
    {
        "phase": 2,
        "title": "Create Xcode Project for PTPerformance",
        "description": """Create new SwiftUI Xcode project.

**Acceptance Criteria:**
- Universal app (iPhone + iPad)
- Minimum iOS 17
- SwiftUI lifecycle
- Project compiles without errors
- Git initialized in ios-app/

**Project Settings:**
- Bundle ID: com.ptperformance.app
- Team: Personal Team
- Deployment target: iOS 17.0""",
        "priority": "High",
        "zones": ["zone-12"],
        "estimate": 1,
    },
    {
        "phase": 2,
        "title": "Integrate Supabase Swift SDK",
        "description": """Add Supabase SDK via Swift Package Manager.

**Acceptance Criteria:**
- supabase-swift package added
- Package resolved successfully
- Supabase client initialized in App
- Auth client configured with project URL

**Package:**
```
https://github.com/supabase/supabase-swift
Version: latest
```

**Init Code:**
```swift
import Supabase

let supabase = SupabaseClient(
  supabaseURL: URL(string: "https://PROJECT.supabase.co")!,
  supabaseKey: "ANON_KEY"
)
```""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 2,
        "title": "Implement Supabase Auth Flow",
        "description": """Wire up authentication with Supabase.

**Acceptance Criteria:**
- Sign in with email/password works
- Auth state persists across app launches
- Sign out functionality works
- Error handling for auth failures

**Files:**
- AuthView.swift (update from skeleton)
- Add SupabaseAuthService.swift

**Test Users:**
- Patient: john@demo.com / demo123
- Therapist: sarah@demo.com / demo123""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 2,
        "title": "Fetch Today's Session for Patient",
        "description": """Query Supabase for patient's current session.

**Acceptance Criteria:**
- Query fetches active program
- Gets today's session based on phase/sequence
- Fetches all session_exercises with templates
- Handles case when no session scheduled

**Query Logic:**
1. Get active program for patient
2. Get current phase based on date
3. Get today's session (weekday match or sequence)
4. Join session_exercises + exercise_templates

**Files:**
- Add SupabaseService.swift
- Update TodaySessionView.swift""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 2,
        "title": "Build Exercise Logging UI",
        "description": """Create UI for logging sets/reps/load/pain.

**Acceptance Criteria:**
- List of exercises for session
- Each exercise shows target sets/reps/load
- Stepper for sets (1-10)
- Number pad for reps
- Weight picker for load
- Pain slider (0-10) per exercise
- Local state before submission

**Design:**
- Card-based layout
- Clear visual hierarchy
- Easy thumb-friendly controls
- Progress indicator""",
        "priority": "High",
        "zones": ["zone-12"],
        "estimate": 4,
    },
    {
        "phase": 2,
        "title": "Implement Session Log Submission",
        "description": """POST exercise and pain logs to Supabase.

**Acceptance Criteria:**
- Create exercise_logs rows for each set
- Create pain_logs row for session
- Handle network errors gracefully
- Show success confirmation
- Clear form after successful submit
- Prevent duplicate submissions

**Tables:**
- exercise_logs (multiple rows)
- pain_logs (one row per session)

**Validation:**
- All exercises have at least one set logged
- Pain score between 0-10""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 2,
        "title": "Add Session Notes Input",
        "description": """Allow patient to add free-text notes.

**Acceptance Criteria:**
- Text field for session notes
- Character limit: 500
- Saves to session_notes table
- Author type: 'patient'
- Optional field

**UI:**
- Expandable text area
- Character counter
- Placeholder: "How did this session feel?"
""",
        "priority": "Medium",
        "zones": ["zone-12", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 2,
        "title": "Create Patient History View",
        "description": """Show past sessions and logs for patient.

**Acceptance Criteria:**
- List of completed sessions (last 30 days)
- Shows date, session name, completion status
- Tappable to see details
- Pain trend mini-chart
- Pulls from exercise_logs and pain_logs

**Data:**
```sql
SELECT DISTINCT
  s.name,
  el.performed_at::date,
  AVG(el.pain_score) as avg_pain
FROM sessions s
JOIN exercise_logs el ON el.session_id = s.id
WHERE el.patient_id = $1
GROUP BY s.id, el.performed_at::date
ORDER BY el.performed_at DESC
LIMIT 30;
```""",
        "priority": "Medium",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 2,
        "title": "Add Pain Trend Chart",
        "description": """Visual chart showing pain over time.

**Acceptance Criteria:**
- Line chart using Swift Charts
- X-axis: Date
- Y-axis: Pain (0-10)
- Data from vw_pain_trend view
- Last 14 days
- Color: red for pain >5, yellow 3-5, green <3

**Library:**
- Use native Swift Charts (iOS 16+)

**Query:**
```swift
let trendData = try await supabase
  .from("vw_pain_trend")
  .select()
  .eq("patient_id", patientId)
  .gte("day", fourteenDaysAgo)
  .order("day", ascending: true)
  .execute()
```""",
        "priority": "Medium",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 2,
        "title": "Create Phase 2 Handoff Document",
        "description": """Document Phase 2 completion and Phase 3 setup.

**Acceptance Criteria:**
- Handoff doc created
- Patient flow fully tested
- Screenshots of working UI
- Phase 3 prerequisites listed
- Estimated tokens used: ~150K

**Deliverables:**
- Patient can log full session
- Pain tracking works
- History view shows data""",
        "priority": "Medium",
        "zones": ["zone-13"],
        "estimate": 1,
    },

    # ========== PHASE 3: Therapist Mobile Flow ==========
    {
        "phase": 3,
        "title": "Implement Therapist Dashboard List",
        "description": """Show therapist's assigned patients with key metrics.

**Acceptance Criteria:**
- Query patients assigned to logged-in therapist
- Show patient name, sport, position
- Show adherence % from vw_patient_adherence
- Show last session date
- Show pain indicator (red/yellow/green)
- Tappable to drill into patient detail

**Query:**
```sql
SELECT
  p.id, p.first_name, p.last_name, p.sport, p.position,
  va.adherence_pct,
  MAX(el.performed_at) as last_session
FROM patients p
LEFT JOIN vw_patient_adherence va ON va.patient_id = p.id
LEFT JOIN exercise_logs el ON el.patient_id = p.id
WHERE p.therapist_id = $1
GROUP BY p.id, va.adherence_pct;
```""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 3,
        "title": "Create Patient Detail View",
        "description": """Detailed view of single patient for therapist.

**Acceptance Criteria:**
- Patient demographics displayed
- Current program name and progress
- Recent sessions (last 7)
- Pain trend chart
- Quick action: Add Note

**Sections:**
1. Patient Info (name, sport, age)
2. Active Program (name, phase, week)
3. Adherence (% complete, visual)
4. Pain Trend (7-day chart)
5. Recent Sessions (list)""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 4,
    },
    {
        "phase": 3,
        "title": "Build Program Viewer for Therapist",
        "description": """Show complete program structure (phases → sessions → exercises).

**Acceptance Criteria:**
- Hierarchical view: Program → Phases → Sessions → Exercises
- Expandable/collapsible sections
- Shows target sets/reps/load for each exercise
- Read-only for MVP (editing in later phase)

**UI Pattern:**
- Accordion/disclosure groups
- Phase cards with date ranges
- Session list per phase
- Exercise detail on tap""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 4,
    },
    {
        "phase": 3,
        "title": "Implement Session Log Review",
        "description": """Allow therapist to see patient's logged sets/reps/pain.

**Acceptance Criteria:**
- Select a completed session
- See all exercise_logs for that session
- Show actual vs target for each exercise
- Show pain scores per exercise
- Show session notes from patient

**Visual:**
- Side-by-side: Target | Actual
- Color coding: green if met, yellow if close, red if missed
- Pain values highlighted if >5""",
        "priority": "High",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 3,
        "title": "Add Therapist Notes Interface",
        "description": """Allow therapist to add notes for a patient.

**Acceptance Criteria:**
- Text editor for notes
- Can tag notes to specific session or general
- Saves to session_notes with author_type='therapist'
- Notes visible in patient detail view
- Timestamp displayed

**Fields:**
- Note content (text, 2000 char limit)
- Session ID (optional, for session-specific notes)
- Created timestamp""",
        "priority": "Medium",
        "zones": ["zone-12", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 3,
        "title": "Create Adherence Chart for Therapist",
        "description": """Visual representation of patient adherence over time.

**Acceptance Criteria:**
- Bar chart: weeks on X, completion % on Y
- Data from vw_patient_adherence
- Grouped by week
- Color: green >80%, yellow 50-80%, red <50%

**Query:**
```sql
SELECT
  DATE_TRUNC('week', el.performed_at) as week,
  COUNT(DISTINCT el.session_id)::float / COUNT(DISTINCT s.id) * 100 as pct
FROM sessions s
LEFT JOIN exercise_logs el ON el.session_id = s.id
WHERE s.phase_id IN (SELECT id FROM phases WHERE program_id = $1)
GROUP BY week
ORDER BY week;
```""",
        "priority": "Medium",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 3,
        "title": "Add Pain Alerts for Therapist",
        "description": """Highlight patients with concerning pain trends.

**Acceptance Criteria:**
- Alert badge on patient card if:
  - Pain >5 for 2+ consecutive sessions
  - Pain spike >3 in single session
- Alert detail view shows:
  - Which sessions triggered alert
  - Pain values
  - Date

**Logic:**
```sql
-- Pain spike detection
SELECT patient_id, session_id, pain_during
FROM pain_logs
WHERE pain_during > 5
ORDER BY logged_at DESC;
```

**UI:**
- Red badge with count on patient card
- Tap to see alert details""",
        "priority": "Medium",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 3,
        "title": "Implement Bullpen Log Viewer",
        "description": """Show pitching-specific logs for throwing athletes.

**Acceptance Criteria:**
- List of bullpen sessions
- Shows pitch type, velocity, command, pain
- Chart: velocity trend over time
- Chart: command rating trend
- Filters: last 7/14/30 days

**Data:**
```sql
SELECT pitch_type, velocity, command_rating, pain_score, logged_at
FROM bullpen_logs
WHERE patient_id = $1
ORDER BY logged_at DESC;
```

**Charts:**
- Line chart: Date vs Velocity (by pitch type)
- Line chart: Date vs Command
- Overlay pain as color intensity""",
        "priority": "Low",
        "zones": ["zone-12", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 3,
        "title": "Add iPad-Optimized Layout",
        "description": """Optimize therapist views for iPad split-view.

**Acceptance Criteria:**
- Sidebar: Patient list
- Main: Selected patient detail
- Uses NavigationSplitView (iOS 16+)
- Landscape orientation supported
- Compact mode works on iPhone

**UI:**
```swift
NavigationSplitView {
  PatientListView()
} detail: {
  PatientDetailView()
}
```""",
        "priority": "Medium",
        "zones": ["zone-12"],
        "estimate": 2,
    },
    {
        "phase": 3,
        "title": "Create Phase 3 Handoff Document",
        "description": """Document Phase 3 completion and Phase 4 setup.

**Acceptance Criteria:**
- Handoff doc created
- Therapist flow fully tested
- Screenshots of dashboards
- Phase 4 prerequisites listed
- Estimated tokens used: ~150K

**Deliverables:**
- Therapist can review all patients
- Charts and metrics working
- Notes interface functional""",
        "priority": "Medium",
        "zones": ["zone-13"],
        "estimate": 1,
    },

    # ========== PHASE 4: Agent Service + Approvals ==========
    {
        "phase": 4,
        "title": "Create /patient-summary Endpoint",
        "description": """Agent service endpoint for patient summary.

**Acceptance Criteria:**
- GET /patient-summary/:patientId
- Returns patient demographics
- Returns active program details
- Returns last 5 sessions
- Returns pain trend (7 days)
- Returns adherence %

**Response Schema:**
```json
{
  "patient": { "id": "...", "name": "...", "sport": "..." },
  "program": { "name": "...", "current_phase": "..." },
  "recent_sessions": [...],
  "pain_trend": [...],
  "adherence_pct": 85.5
}
```""",
        "priority": "High",
        "zones": ["zone-3c", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 4,
        "title": "Create /today-session Endpoint",
        "description": """Get today's session data for a patient.

**Acceptance Criteria:**
- GET /today-session/:patientId
- Returns session details
- Returns exercises with targets
- Returns completion status
- Handles no session scheduled case

**Used By:**
- Future PT assistant agent
- Slack integrations""",
        "priority": "Medium",
        "zones": ["zone-3c", "zone-8"],
        "estimate": 2,
    },
    {
        "phase": 4,
        "title": "Integrate Linear Client into Agent Service",
        "description": """Add Linear GraphQL client to agent service.

**Acceptance Criteria:**
- Can create issues in Agent-Control-Plane team
- Can add comments to issues
- Can update issue status
- Can query issues by label
- Error handling for API failures

**Functions:**
- createIssue(title, description, labels, priority)
- addComment(issueId, comment)
- updateStatus(issueId, stateId)
- getIssuesByLabel(label)

**Reference:**
- Use linear_client.py as reference for GraphQL queries""",
        "priority": "High",
        "zones": ["zone-3c"],
        "estimate": 3,
    },
    {
        "phase": 4,
        "title": "Build Plan Change Request Creator",
        "description": """Function to create zone-4b plan change requests.

**Acceptance Criteria:**
- POST /plan-change-request
- Accepts: patientId, change summary, reason, impact
- Creates Linear issue with zone-4b label
- Sets status to "In Review"
- Returns issue URL
- Logs request to agent log

**Request Body:**
```json
{
  "patientId": "...",
  "summary": "Reduce intensity week 5",
  "reason": "Pain trending up",
  "impact": "Delays phase 4 by 1 week"
}
```

**Linear Issue Template:**
```
Title: Plan Change for Patient {name}: {summary}
Description:
**Patient:** {name} ({id})
**Reason:** {reason}
**Impact:** {impact}
**Proposed Change:** {summary}

Labels: zone-4b, patient-{id}
Status: In Review
```""",
        "priority": "High",
        "zones": ["zone-3c", "zone-4b"],
        "estimate": 4,
    },
    {
        "phase": 4,
        "title": "Implement Clinical Safety Checks",
        "description": """Add automated checks for clinical safety rules.

**Acceptance Criteria:**
- Function: checkPainSafety(patientId)
  - Returns alerts if pain >5 for 2+ sessions
  - Returns alerts if pain spike >3
- Function: checkLoadProgression(patientId)
  - Flags if load increased >10% with pain increase
- Auto-creates zone-4b issue if safety check fails

**Safety Rules (from AGENT_GOVERNANCE.md):**
- Pain >5 for 2+ sessions → propose change
- Pain spike >3 in single session → alert
- Never auto-increase intensity if pain rising

**Test:**
- Seed pain_logs with concerning values
- Verify alerts generated
- Verify Linear issues created""",
        "priority": "High",
        "zones": ["zone-3c", "zone-4b", "zone-10b"],
        "estimate": 4,
    },
    {
        "phase": 4,
        "title": "Create Slack App for Approval Flow",
        "description": """Set up Slack app for PT approval notifications.

**Acceptance Criteria:**
- Slack app created in workspace
- Incoming webhook configured
- Interactive buttons enabled
- Webhook URL stored in .env
- Test message sent successfully

**Slack App Config:**
- App name: PT Agent Approvals
- Channel: #pt-agent-approvals
- Permissions: chat:write, commands

**Reference:**
- docs/SLACK_APPROVAL_FLOW.md""",
        "priority": "Medium",
        "zones": ["zone-3c", "zone-4b"],
        "estimate": 2,
    },
    {
        "phase": 4,
        "title": "Implement Slack Notification for zone-4b Issues",
        "description": """Send Slack message when plan change request created.

**Acceptance Criteria:**
- When zone-4b issue created, post to Slack
- Message includes:
  - Patient name
  - Change summary
  - Reason/impact
  - Linear issue link
  - Approve/Reject buttons
- Buttons trigger webhook back to agent service

**Slack Message Format:**
```
🚨 Plan Change Request

**Patient:** John Brebbia
**Change:** Reduce intensity week 5
**Reason:** Pain trending up (avg 6.5 last 3 sessions)
**Impact:** Delays phase 4 by 1 week

<Linear Issue Link>

[Approve] [Reject]
```""",
        "priority": "Medium",
        "zones": ["zone-3c", "zone-4b"],
        "estimate": 3,
    },
    {
        "phase": 4,
        "title": "Handle Slack Approval Webhook",
        "description": """Process approve/reject from Slack buttons.

**Acceptance Criteria:**
- POST /slack/interactions endpoint
- Verifies Slack signature
- On Approve:
  - Updates Linear issue to "Approved"
  - Adds comment with approver
  - Triggers plan change logic (future)
- On Reject:
  - Updates Linear issue to "Rejected"
  - Adds comment with reason
- Responds to Slack with confirmation

**Security:**
- Validate Slack signing secret
- Verify request authenticity""",
        "priority": "Medium",
        "zones": ["zone-3c", "zone-4b"],
        "estimate": 3,
    },
    {
        "phase": 4,
        "title": "Add Agent Action Logging",
        "description": """Log all agent service actions for observability.

**Acceptance Criteria:**
- Log format: JSON Lines
- Log location: logs/agent_actions.jsonl
- Fields: timestamp, action_type, patient_id, linear_issue_id, success, error
- Rotation: daily
- Max size: 100MB

**Action Types:**
- patient_summary_query
- plan_change_request_created
- clinical_safety_check
- slack_notification_sent
- linear_issue_created

**Example Log:**
```json
{"timestamp":"2025-01-15T10:30:00Z","action":"plan_change_request_created","patient_id":"abc","issue_id":"ACP-15","success":true}
```""",
        "priority": "Medium",
        "zones": ["zone-13"],
        "estimate": 2,
    },
    {
        "phase": 4,
        "title": "Create Phase 4 Handoff Document",
        "description": """Document Phase 4 completion and Phase 5 setup.

**Acceptance Criteria:**
- Handoff doc created
- Agent service fully tested
- Approval flow demonstrated
- Phase 5 prerequisites listed
- Estimated tokens used: ~150K

**Deliverables:**
- Agent service running
- Plan changes create Linear issues
- Slack approval working
- Safety checks active""",
        "priority": "Medium",
        "zones": ["zone-13"],
        "estimate": 1,
    },

    # ========== PHASE 5: Integration & Polish ==========
    {
        "phase": 5,
        "title": "End-to-End Test: Patient Session Flow",
        "description": """Complete patient workflow test.

**Test Scenario:**
1. Patient signs in
2. Views today's session
3. Logs all exercises with sets/reps/load
4. Logs pain (simulated pain >5)
5. Submits session
6. Views history to confirm log

**Acceptance Criteria:**
- All steps complete without errors
- Data appears in Supabase
- Views update correctly
- Safety check triggers if pain >5

**Document:**
- Screenshots of each step
- Test results in .outcomes/e2e_patient_test.md""",
        "priority": "High",
        "zones": ["zone-10b"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "End-to-End Test: Therapist Review Flow",
        "description": """Complete therapist workflow test.

**Test Scenario:**
1. Therapist signs in
2. Views patient dashboard
3. Selects patient with logged session
4. Reviews session logs
5. Checks pain trend
6. Adds therapist note

**Acceptance Criteria:**
- All data displays correctly
- Charts render
- Notes save successfully
- Adherence % accurate

**Document:**
- Test results in .outcomes/e2e_therapist_test.md""",
        "priority": "High",
        "zones": ["zone-10b"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "End-to-End Test: Plan Change Approval Flow",
        "description": """Complete agent approval workflow test.

**Test Scenario:**
1. Trigger safety check (pain >5 for 2 sessions)
2. Agent creates zone-4b issue
3. Slack notification sent
4. PT approves via Slack
5. Verify Linear issue updated

**Acceptance Criteria:**
- Safety check detects condition
- Linear issue created correctly
- Slack message sent
- Approval updates Linear
- All steps logged

**Document:**
- Test results in .outcomes/e2e_approval_test.md""",
        "priority": "High",
        "zones": ["zone-10b", "zone-4b"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "Performance Test: Database Queries",
        "description": """Validate query performance with realistic data volume.

**Acceptance Criteria:**
- Seed 100 patients, 500 sessions, 5000 exercise logs
- Test all views execute <500ms
- Test patient summary endpoint <1s
- Test dashboard query <2s
- Document slow queries
- Add indexes if needed

**Queries to Test:**
- vw_patient_adherence
- vw_pain_trend
- Patient dashboard query
- Session history query

**Document:**
- Results in .outcomes/performance_test.md
- Any indexes added""",
        "priority": "Medium",
        "zones": ["zone-10b", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "Security Audit: RLS Policies",
        "description": """Verify row-level security prevents unauthorized access.

**Test Cases:**
1. Patient A cannot see Patient B's data
2. Therapist can only see assigned patients
3. Service role can access all data
4. Unauthenticated requests rejected

**Tables to Test:**
- patients, exercise_logs, pain_logs, session_notes

**Acceptance Criteria:**
- All test cases pass
- No data leaks found
- Policies documented in infra/RLS_POLICIES.md

**Method:**
- Create test users with different roles
- Attempt cross-patient queries
- Verify 403/empty results""",
        "priority": "High",
        "zones": ["zone-10b", "zone-8"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "Fix Critical Bugs from Testing",
        "description": """Address any critical issues found during E2E testing.

**Acceptance Criteria:**
- All P0/critical bugs fixed
- Regression tests added
- Fixes documented
- Re-test affected flows

**Bug Tracking:**
- Create Linear issues for each bug
- Link to this issue
- Update status as fixed""",
        "priority": "High",
        "zones": ["zone-12", "zone-3c", "zone-8"],
        "estimate": 4,
    },
    {
        "phase": 5,
        "title": "Optimize iOS App Performance",
        "description": """Profile and optimize iOS app.

**Acceptance Criteria:**
- Xcode Instruments profile run
- Identify memory leaks (none found or fixed)
- Optimize image loading if needed
- Reduce network calls where possible
- App launch <2s

**Focus Areas:**
- View rendering performance
- Network request optimization
- Data caching strategy""",
        "priority": "Medium",
        "zones": ["zone-12"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "Create Deployment Documentation",
        "description": """Document how to deploy all components.

**Acceptance Criteria:**
- Supabase setup guide
- iOS app TestFlight deployment steps
- Agent service deployment (Docker or cloud)
- Environment variable reference
- Monitoring setup

**Files:**
- docs/DEPLOYMENT.md
- infra/docker-compose.yml (for agent service)
- .github/workflows/deploy.yml (optional CI/CD)

**Sections:**
1. Prerequisites
2. Supabase Configuration
3. iOS App Signing & Distribution
4. Agent Service Deployment
5. Slack Integration Setup
6. Monitoring & Logging""",
        "priority": "Medium",
        "zones": ["zone-13"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "Create User Documentation",
        "description": """End-user guides for PT and patients.

**Acceptance Criteria:**
- Patient guide: How to log sessions
- Therapist guide: How to review patients
- Screenshots for each major feature
- Troubleshooting section

**Files:**
- docs/USER_GUIDE_PATIENT.md
- docs/USER_GUIDE_THERAPIST.md

**Format:**
- Step-by-step instructions
- Annotated screenshots
- FAQ section
- Common issues + solutions""",
        "priority": "Low",
        "zones": ["zone-13"],
        "estimate": 3,
    },
    {
        "phase": 5,
        "title": "Final MVP Review & Sign-off",
        "description": """Comprehensive review of entire MVP.

**Acceptance Criteria:**
- All Phase 1-5 issues completed
- All tests passing
- Documentation complete
- Demo video recorded (5 min)
- Known issues documented
- Product owner sign-off

**Deliverables:**
1. Demo video showing full flow
2. Known issues list
3. Future enhancements backlog
4. Final handoff document

**Review Checklist:**
- ✅ Patient can log sessions
- ✅ Therapist can review patients
- ✅ Agent service creates plan changes
- ✅ Approval flow works end-to-end
- ✅ Security validated
- ✅ Performance acceptable""",
        "priority": "High",
        "zones": ["zone-10b", "zone-13"],
        "estimate": 3,
    },
]


async def create_phase_labels(bootstrap, team_id):
    """Create phase-1 through phase-5 labels."""
    print("\n📋 Creating phase labels...")
    phase_labels = {}

    for i in range(1, 6):
        label_name = f"phase-{i}"
        label = await bootstrap.get_or_create_label(team_id, label_name)
        phase_labels[i] = label["id"]
        print(f"  ✓ {label_name}: {label['id']}")

    return phase_labels


async def get_zone_labels(client, team_id):
    """Get existing zone label IDs."""
    print("\n🏷️  Fetching zone labels...")

    query = """
    query Labels($teamId: String!) {
        team(id: $teamId) {
            labels {
                nodes {
                    id
                    name
                }
            }
        }
    }
    """

    data = await client.query(query, {"teamId": team_id})
    labels = data.get("team", {}).get("labels", {}).get("nodes", [])

    zone_labels = {}
    for label in labels:
        if label["name"].startswith("zone-"):
            zone_labels[label["name"]] = label["id"]
            print(f"  ✓ {label['name']}: {label['id']}")

    return zone_labels


async def get_priority_value(priority_str):
    """Convert priority string to Linear priority value."""
    priority_map = {
        "High": 1,
        "Medium": 2,
        "Low": 3,
        "Urgent": 0,
    }
    return priority_map.get(priority_str, 2)


async def create_all_issues(client, team_id, project_id, phase_labels, zone_labels):
    """Create all MVP issues in Linear."""
    print(f"\n🎯 Creating {len(MVP_ISSUES)} issues across 5 phases...\n")

    created_issues = []

    for idx, issue_data in enumerate(MVP_ISSUES, 1):
        # Build label IDs list
        label_ids = []

        # Add phase label
        phase_num = issue_data["phase"]
        if phase_num in phase_labels:
            label_ids.append(phase_labels[phase_num])

        # Add zone labels
        for zone in issue_data["zones"]:
            if zone in zone_labels:
                label_ids.append(zone_labels[zone])

        # Get priority value
        priority = await get_priority_value(issue_data["priority"])

        # Create issue
        mutation = """
        mutation CreateIssue($teamId: String!, $projectId: String!, $title: String!, $description: String!, $labelIds: [String!]!, $priority: Int, $estimate: Int) {
            issueCreate(input: {
                teamId: $teamId,
                projectId: $projectId,
                title: $title,
                description: $description,
                labelIds: $labelIds,
                priority: $priority,
                estimate: $estimate
            }) {
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

        variables = {
            "teamId": team_id,
            "projectId": project_id,
            "title": issue_data["title"],
            "description": issue_data["description"],
            "labelIds": label_ids,
            "priority": priority,
            "estimate": issue_data.get("estimate", 2)
        }

        try:
            data = await client.query(mutation, variables)
            issue = data["issueCreate"]["issue"]
            created_issues.append(issue)

            phase_str = f"Phase {phase_num}"
            zones_str = ", ".join(issue_data["zones"])
            print(f"  [{idx}/{len(MVP_ISSUES)}] ✓ {issue['identifier']}: {issue['title'][:60]}...")
            print(f"           {phase_str} | {zones_str} | {issue_data['priority']}")

        except Exception as e:
            print(f"  ❌ Failed to create: {issue_data['title']}")
            print(f"     Error: {str(e)}")

    return created_issues


async def main():
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ LINEAR_API_KEY not set")
        sys.exit(1)

    print("🚀 Creating Complete MVP Plan in Linear")
    print("=" * 60)

    async with LinearBootstrap(api_key) as bootstrap:
        # Get/create team
        team = await bootstrap.get_or_create_team("Agent-Control-Plane")
        print(f"✓ Team: {team['name']} ({team['id']})")

        # Get/create project
        project = await bootstrap.get_or_create_project(team["id"], "MVP 1 — PT App & Agent Pilot")
        if not project:
            print("❌ Failed to get/create project")
            sys.exit(1)

        print(f"✓ Project: {project['name']} ({project['id']})")
        print(f"  URL: {project['url']}")

        # Create phase labels
        phase_labels = await create_phase_labels(bootstrap, team["id"])

        # Get zone labels
        zone_labels = await get_zone_labels(bootstrap, team["id"])

        # Create all issues
        created_issues = await create_all_issues(
            bootstrap,
            team["id"],
            project["id"],
            phase_labels,
            zone_labels
        )

        # Summary
        print("\n" + "=" * 60)
        print("✅ MVP Plan Created Successfully!")
        print("=" * 60)
        print(f"\n📊 Summary:")
        print(f"  Total issues created: {len(created_issues)}")

        # Count by phase
        phase_counts = {}
        for issue_data in MVP_ISSUES:
            phase = issue_data["phase"]
            phase_counts[phase] = phase_counts.get(phase, 0) + 1

        for phase in sorted(phase_counts.keys()):
            print(f"  Phase {phase}: {phase_counts[phase]} issues")

        print(f"\n🔗 View in Linear:")
        print(f"  {project['url']}")

        print(f"\n📋 Next Steps:")
        print(f"  1. Review issues in Linear")
        print(f"  2. Start with Phase 1 issues (filter: phase-1)")
        print(f"  3. Use /sync-linear to fetch plan")
        print(f"  4. Begin building!")


if __name__ == "__main__":
    asyncio.run(main())
