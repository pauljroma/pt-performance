# PT Performance Platform - End-to-End QA Assessment Guide

**Version:** 2.0 (Enhanced)
**Date:** 2025-02-11
**Purpose:** Comprehensive QA assessment guide for external developers
**Estimated Assessment Time:** 12-16 hours (expanded scope)

## 🆕 What's New in Version 2.0

**Major Clarifications:**
- ✅ **Architecture Correction:** Clarified that iOS app connects directly to Supabase (NOT via agent service)
- ✅ **Agent Service Status:** Documented that agent service is operational but standalone (not integrated with iOS yet)
- ✅ **Integration Reality:** Clear separation of current vs future architecture

**Added Depth:**
- ✅ **Performance Benchmarks:** Specific response time targets, load testing procedures, memory benchmarks
- ✅ **Security Deep Dive:** RLS testing, HIPAA compliance requirements, authentication security, input validation
- ✅ **Data Integrity Testing:** Foreign key integrity, cascade deletes, transaction consistency, edge cases
- ✅ **Edge Case Scenarios:** Boundary values, null handling, time zones, race conditions, extremely large datasets
- ✅ **20 New Integration Tests:** Detailed test cases with SQL queries and expected outcomes

**Document Size:** ~2,000+ lines (from ~1,000 lines)

---

## Table of Contents

1. [Project Overview](#project-overview)
2. [Architecture & Components](#architecture--components)
3. [Technology Stack](#technology-stack)
4. [Environment Setup](#environment-setup)
5. [QA Testing Areas](#qa-testing-areas)
6. [End-to-End Test Scenarios](#end-to-end-test-scenarios)
7. [Known Issues & Risks](#known-issues--risks)
8. [Quality Checklist](#quality-checklist)
9. [Documentation References](#documentation-references)

---

## Project Overview

### What is PT Performance?

PT Performance is an intelligent physical therapy and performance training platform designed for therapists and athletes (particularly baseball pitchers). The platform combines:

- **iOS Mobile App** (Swift/SwiftUI) for patient and therapist workflows
- **Supabase Backend** for data storage, authentication, and analytics
- **Agent Service** (Node.js/Express) for intelligent summaries and automation
- **Linear Integration** for project management and agent coordination

### Key Stakeholders

- **Patients/Athletes**: Log workouts, track pain, view progress
- **Therapists**: Create programs, monitor patients, receive intelligent alerts
- **PT Agent**: Automated assistant that flags issues and proposes plan changes

### Project Status

- **Phase:** MVP Development (Phase 1 Complete: Data Layer)
- **Build Number:** 71+ (iOS builds in TestFlight)
- **Database:** 19 tables, 7 analytics views, fully deployed
- **Agent Backend:** Core endpoints operational
- **iOS App:** Patient and therapist flows implemented

---

## Architecture & Components

### System Architecture

**IMPORTANT:** Current vs Future Architecture

```
CURRENT ARCHITECTURE (MVP - What's Deployed):
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────┐                                             │
│  │   iOS App   │────────────────┐                            │
│  │  (SwiftUI)  │                │                            │
│  └─────────────┘                │                            │
│                                  │ Direct Connection         │
│                                  │ (Supabase Swift SDK)      │
│                                  ▼                            │
│                          ┌──────────────┐                    │
│                          │   Supabase   │                    │
│                          │  (Postgres)  │                    │
│                          │   + Auth     │                    │
│                          │   + RLS      │                    │
│                          └──────────────┘                    │
│                                  ▲                            │
│                                  │                            │
│                                  │ Queries data              │
│                          ┌───────┴────────┐                  │
│                          │ Agent Service  │ (Standalone)     │
│                          │   (Node.js)    │ Not used by iOS  │
│                          └────────────────┘                  │
│                                  │                            │
│                                  ▼                            │
│                          ┌────────────────┐                  │
│                          │ Linear + Slack │ (Future)         │
│                          │  Integrations  │                  │
│                          └────────────────┘                  │
└─────────────────────────────────────────────────────────────┘

FUTURE ARCHITECTURE (Planned):
┌─────────────────────────────────────────────────────────────┐
│  ┌─────────────┐      ┌──────────────┐      ┌────────────┐ │
│  │   iOS App   │◄────►│ Agent Service│◄────►│  Supabase  │ │
│  │  (SwiftUI)  │      │   (Node.js)  │      │ (Postgres) │ │
│  └─────────────┘      └──────────────┘      └────────────┘ │
│         │                     │                     ▲        │
│         │                     ▼                     │        │
│         │             ┌────────────────┐            │        │
│         │             │ Therapist Web  │────────────┘        │
│         │             │    Portal      │                     │
│         │             └────────────────┘                     │
│         ▼                     ▼                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │              External Integrations                    │   │
│  │  • Linear (Project Management)                        │   │
│  │  • Slack (Notifications)                              │   │
│  │  • TestFlight (iOS Distribution)                      │   │
│  └──────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Key Points for QA:**
- ✅ **iOS app connects DIRECTLY to Supabase** (no agent service calls)
- ✅ **Agent service is operational** but standalone (future integration)
- ✅ **Test iOS and Agent Service independently**
- ⚠️ **Agent service endpoints exist but are not consumed by iOS yet**

### Component Breakdown

#### 1. iOS App (`/ios-app/PTPerformance/`)

**Technology:** Swift 5.9+, SwiftUI, Xcode 15+

**Key Modules:**
- Authentication (Supabase Auth)
- Patient Flow (session logging, pain tracking, history)
- Therapist Dashboard (patient monitoring, program management)
- Exercise Library
- Analytics & Charts
- Help System (189 baseball articles)
- Video Library

**Project Structure:**
- `PTPerformance.xcodeproj` - Xcode project
- `PTPerformance/` - Source code
- `PTPerformanceTests/` - Unit tests
- `PTPerformanceWatch/` - Apple Watch extension
- `Shared/` - Shared code between targets

#### 2. Supabase Backend (`/supabase/`)

**Technology:** PostgreSQL 15+, Row Level Security (RLS), Edge Functions

**Database Schema:**
- **19 Tables**: patients, therapists, programs, phases, sessions, exercise_logs, pain_logs, bullpen_logs, etc.
- **7 Views**: adherence, pain trends, throwing workload, performance metrics
- **23 CHECK Constraints**: Data validation (pain 0-10, velocity 40-110 mph, etc.)
- **30+ RLS Policies**: Security for therapist/patient data isolation

**Key Features:**
- Full program/phase/session hierarchy
- Exercise template library with clinical metadata
- Pain & performance tracking
- Protocol templates with evidence-based constraints
- Analytics views for dashboards

**Migrations:** Located in `/supabase/migrations/`
- 50+ migration files
- Versioned schema changes
- Seed data included

#### 3. Agent Service (`/agent-service/`)

**Technology:** Node.js 18+, Express 4.x

**Purpose:** Intelligent backend for PT assistance and automation

**⚠️ CURRENT STATUS: STANDALONE SERVICE (Not integrated with iOS app yet)**

**Available Endpoints:**
- `GET /health` - Health check
- `GET /patient-summary/:patientId` - Comprehensive patient data
- `GET /today-session/:patientId` - Current session details
- `GET /pt-assistant/summary/:patientId` - Text summary for PTs
- `GET /flags/:patientId` - Risk flags computation
- `GET /strength-targets/:patientId` - 1RM estimates
- `POST /protocol/validate` - Safety validation
- `GET /protocol/summary/:patientId` - Protocol risk profile
- `GET /therapist/:therapistId/patients` - Therapist dashboard
- `GET /therapist/:therapistId/dashboard` - Aggregated metrics
- `GET /therapist/:therapistId/alerts` - Active alerts

**What It Does:**
1. Queries Supabase for patient data
2. Computes risk flags (pain spikes, workload issues)
3. Generates intelligent summaries for therapists
4. Validates program changes against protocol constraints
5. Auto-creates Plan Change Requests in Linear for high-severity flags
6. Provides aggregated dashboard data

**Integration Status:**
- ✅ Operational and testable via HTTP
- ✅ Connects to Supabase successfully
- ✅ Linear integration functional
- ❌ **NOT called by iOS app** (future integration)
- 🔄 **Designed for future therapist web portal**

**Future Features:**
- iOS app integration (replace direct Supabase calls)
- Real-time Slack notifications
- Automated PCR creation workflow
- ML-based injury prediction

#### 4. Linear Integration

**Purpose:** Project management and agent coordination

**Components:**
- `linear_client.py` - CLI for Linear operations
- `mcp_server.py` - MCP server for Claude Code
- Slash command: `/sync-linear`
- Auto-sync hook on session start

**Linear Workspace:**
- Team: Agent-Control-Plane (ACP)
- Project: MVP 1 — PT App & Agent Pilot
- 45+ issues with zone labels for routing

---

## Current vs Future Integration Status

### ✅ What's Currently Integrated (MVP)

**iOS App ↔ Supabase (Direct)**
- ✅ Authentication (Supabase Auth SDK)
- ✅ Patient data CRUD operations
- ✅ Therapist data CRUD operations
- ✅ Exercise logging (sets, reps, load, RPE, pain)
- ✅ Pain logging
- ✅ Bullpen logging (for pitchers)
- ✅ Program/Phase/Session hierarchy
- ✅ Analytics views (via direct SQL queries)
- ✅ Row Level Security (RLS) for data isolation
- ✅ Real-time subscriptions (if implemented)

**Agent Service ↔ Supabase**
- ✅ Patient summary aggregation
- ✅ Today's session lookup
- ✅ Pain trend analysis
- ✅ Flag computation (pain spikes, workload)
- ✅ Strength target calculations
- ✅ Protocol constraint validation
- ✅ Therapist dashboard endpoints

**Agent Service ↔ Linear**
- ✅ Plan Change Request creation
- ✅ Issue status updates
- ✅ Comment posting
- 🔄 Webhook integration (future)

### ❌ What's NOT Yet Integrated

**iOS App ↔ Agent Service**
- ❌ No calls from iOS to agent service endpoints
- ❌ iOS doesn't use PT Assistant summaries
- ❌ iOS doesn't display computed flags
- ❌ iOS doesn't use protocol validation
- ❌ iOS doesn't use strength target recommendations

**Agent Service ↔ Slack**
- ❌ No Slack notifications implemented
- ❌ No alert routing to therapists

**Therapist Web Portal**
- ❌ Doesn't exist yet
- 🔄 Agent service endpoints ready for it

### 🔄 Migration Path (Future)

When iOS integrates with Agent Service:
1. iOS will call agent service endpoints instead of direct Supabase queries
2. Agent service becomes the "backend for frontend" (BFF)
3. Benefits:
   - Centralized business logic
   - Easier to add features without iOS updates
   - Better caching and performance
   - Consistent data transformations
   - Rate limiting and security

**QA Impact:**
- For now, test iOS and Agent Service **independently**
- iOS testing focuses on Supabase integration
- Agent Service testing is **standalone API testing**
- Integration testing between iOS and Agent Service is **not applicable yet**

---

## Technology Stack

### iOS Development
- **Language:** Swift 5.9+
- **Framework:** SwiftUI
- **Minimum iOS:** 17.0+
- **Dependencies:**
  - Supabase Swift SDK
  - Charts framework
  - MarkdownUI (help articles)
  - XCTest (testing)

### Backend
- **Database:** PostgreSQL 15+ (via Supabase)
- **Backend Service:** Node.js 18+, Express 4.x
- **API:** REST (future: GraphQL consideration)
- **Authentication:** Supabase Auth (JWT)

### DevOps & Tools
- **Version Control:** Git, GitHub
- **CI/CD:** GitHub Actions (future)
- **Distribution:** TestFlight (iOS)
- **Monitoring:** Sentry (configured, not yet deployed)
- **Project Management:** Linear
- **AI Agents:** Claude Code, MCP servers

### Development Tools
- **Xcode:** 15.0+
- **Supabase CLI:** 1.50+
- **Node/NPM:** 18+
- **Python:** 3.8+ (for scripts)
- **Ruby:** 2.7+ (for Xcode automation scripts)

---

## Environment Setup

### Prerequisites

1. **macOS:** 13.0+ (for iOS development)
2. **Xcode:** 15.0+ (from Mac App Store)
3. **Homebrew:** Latest
4. **Node.js:** 18+ (`brew install node`)
5. **Supabase CLI:** `brew install supabase/tap/supabase`
6. **Git:** Latest

### Setup Steps

#### 1. Clone Repository

```bash
git clone git@github.com:pauljroma/pt-performance.git
cd pt-performance
```

#### 2. Environment Configuration

Create `.env` files:

**Root `.env`:**
```bash
# Copy from .env.example
cp .env.example .env

# Edit with your keys
LINEAR_API_KEY=lin_api_...
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJh...
```

**Agent Service `.env`:**
```bash
cd agent-service
cp .env.example .env

# Edit with your keys
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJh...
LINEAR_API_KEY=lin_api_...
```

#### 3. Database Setup

```bash
cd supabase

# Login to Supabase
supabase login

# Link to your project
supabase link --project-ref your-project-ref

# Apply migrations
supabase db push

# Verify tables
supabase db list-tables
```

Expected output: 19 tables including `patients`, `therapists`, `programs`, `sessions`, etc.

#### 4. Agent Service Setup

```bash
cd agent-service

# Install dependencies
npm install

# Start service
npm run dev

# Test health endpoint
curl http://localhost:4000/health
```

Expected response:
```json
{
  "status": "ok",
  "services": {
    "supabase": "configured",
    "linear": "configured"
  }
}
```

#### 5. iOS App Setup

```bash
cd ios-app/PTPerformance

# Open in Xcode
open PTPerformance.xcodeproj

# In Xcode:
# 1. Select PTPerformance scheme
# 2. Choose iOS Simulator (iPhone 15 Pro recommended)
# 3. Press Cmd+B to build
# 4. Press Cmd+R to run
```

**First Launch Configuration:**
- Create Supabase credentials in the app settings
- Or modify `Config.swift` with your Supabase URL and anon key

---

## QA Testing Areas

### 1. Database Layer Testing

**Location:** Supabase Dashboard or `psql`

#### Schema Validation

```sql
-- Test 1: Verify all tables exist
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
ORDER BY table_name;
-- Expected: 19 tables

-- Test 2: Verify all views exist
SELECT table_name
FROM information_schema.views
WHERE table_schema = 'public';
-- Expected: 7 views

-- Test 3: Check constraints
SELECT constraint_name, table_name
FROM information_schema.table_constraints
WHERE constraint_type = 'CHECK';
-- Expected: 23+ CHECK constraints
```

#### Data Validation

```sql
-- Test 4: Verify demo data exists
SELECT * FROM therapists LIMIT 5;
SELECT * FROM patients LIMIT 5;
SELECT * FROM exercise_templates LIMIT 10;

-- Test 5: Check pain score constraints (should fail)
INSERT INTO pain_logs (patient_id, logged_at, pain_during)
VALUES ('test-uuid', NOW(), 15);
-- Expected: ERROR (pain must be 0-10)

-- Test 6: Check velocity constraints (should fail)
INSERT INTO bullpen_logs (patient_id, logged_at, velocity)
VALUES ('test-uuid', NOW(), 150);
-- Expected: ERROR (velocity must be 40-110)
```

#### Analytics Views

```sql
-- Test 7: Patient adherence view
SELECT * FROM vw_patient_adherence;
-- Expected: Rows with adherence_pct calculated

-- Test 8: Pain trend view
SELECT * FROM vw_pain_trend
WHERE patient_id = 'demo-patient-id'
ORDER BY day DESC LIMIT 7;
-- Expected: 7 days of pain trends

-- Test 9: Throwing workload view
SELECT * FROM vw_throwing_workload
ORDER BY session_date DESC LIMIT 10;
-- Expected: Bullpen session summaries with flags
```

#### Row Level Security (RLS)

```sql
-- Test 10: RLS enabled on all tables
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public';
-- Expected: All tables have rowsecurity = true

-- Test 11: Patient can only see own data
-- (Requires authenticated session as patient)
-- In iOS app: Login as patient, verify can't see other patients
```

### 2. Agent Service Testing

**Location:** `http://localhost:4000`

#### Health & Configuration

```bash
# Test 1: Health check
curl http://localhost:4000/health
# Expected: {"status": "ok", ...}

# Test 2: Verify Supabase connection
# Should return "configured" in services.supabase
```

#### Patient Summary Endpoint

```bash
# Test 3: Get patient summary (replace with real patient ID)
curl http://localhost:4000/api/patient-summary/{PATIENT_ID}

# Expected response structure:
# {
#   "patient": {...},
#   "program": {...},
#   "recent_sessions": [...],
#   "pain_trend": [...],
#   "adherence_pct": 85.5,
#   "bullpen_metrics": [...]
# }
```

#### Today's Session Endpoint

```bash
# Test 4: Get today's session
curl http://localhost:4000/api/today-session/{PATIENT_ID}

# Expected:
# {
#   "program": {...},
#   "phase": {...},
#   "session": {
#     "session_exercises": [...]
#   }
# }
```

#### PT Assistant Endpoint

```bash
# Test 5: Get PT Assistant summary
curl http://localhost:4000/api/pt-assistant/summary/{PATIENT_ID}

# Expected:
# {
#   "patient_id": "...",
#   "summary": "**Patient:** John Doe...",
#   "generated_at": "2025-02-11T..."
# }
```

#### Error Handling

```bash
# Test 6: Invalid patient ID
curl http://localhost:4000/api/patient-summary/invalid-id
# Expected: 404 or 500 with error message

# Test 7: Missing patient ID
curl http://localhost:4000/api/patient-summary/
# Expected: 404 (route not found)
```

### 3. iOS App Testing

**Testing Device:** iPhone 15 Pro Simulator (or physical device)

#### Authentication Flow

**Test 1: Sign Up**
1. Launch app
2. Tap "Sign Up"
3. Enter email/password
4. Verify email verification flow
5. Expected: Navigate to role selection or main screen

**Test 2: Sign In**
1. Launch app
2. Tap "Sign In"
3. Enter credentials
4. Expected: Navigate to patient or therapist tab view

**Test 3: Sign Out**
1. Go to Settings/Profile
2. Tap "Sign Out"
3. Expected: Return to auth screen

#### Patient Flow

**Test 4: View Today's Session**
1. Login as patient
2. Navigate to "Today" tab
3. Expected: See current session with exercises

**Test 5: Log Exercise**
1. Select an exercise
2. Enter sets, reps, load, RPE
3. Tap "Save"
4. Expected: Exercise logged, visible in session

**Test 6: Log Pain**
1. After exercise or session
2. Enter pain scores (rest, during, after)
3. Tap "Save"
4. Expected: Pain logged, visible in trends

**Test 7: View History**
1. Navigate to "History" tab
2. Expected: List of past sessions
3. Tap a session
4. Expected: Detail view with all logged data

**Test 8: View Progress Charts**
1. Navigate to "Progress" or "Analytics"
2. Expected: Charts for pain trends, adherence, velocity (if pitcher)

#### Therapist Flow

**Test 9: View Dashboard**
1. Login as therapist
2. Navigate to "Dashboard" tab
3. Expected: List of all patients with status indicators

**Test 10: View Patient Detail**
1. Tap a patient from dashboard
2. Expected: Comprehensive patient view
   - Profile info
   - Active program
   - Pain trend chart
   - Adherence metrics
   - Recent activity

**Test 11: Create Program**
1. Navigate to "Programs"
2. Tap "Create Program"
3. Fill in details (name, dates, phases)
4. Add exercises to sessions
5. Tap "Save"
6. Expected: Program created and visible

**Test 12: Edit Program**
1. Open existing program
2. Modify session exercises or phase details
3. Save changes
4. Expected: Changes persisted

#### Help System

**Test 13: Browse Help Articles**
1. Navigate to "Help" tab
2. Browse categories (189 baseball articles)
3. Tap an article
4. Expected: Article content rendered (Markdown)

**Test 14: Search Help**
1. Use search bar in Help
2. Enter keyword (e.g., "fastball", "rotator cuff")
3. Expected: Filtered results

#### Video Library (if implemented)

**Test 15: Browse Videos**
1. Navigate to "Videos" tab
2. Expected: Grid of video thumbnails
3. Tap a video
4. Expected: Video plays

### 4. Integration Testing

#### iOS ↔ Supabase (PRIMARY INTEGRATION)

**Test 1: Authentication sync**
1. Sign up in iOS app with email: `qa-test-{timestamp}@example.com`
2. Check Supabase Auth dashboard → Users
3. Expected: New user in `auth.users` table
4. Verify: `id`, `email`, `created_at` populated
5. Check RLS: User should have UUID assigned

**Test 2: Data sync - Exercise logging**
1. Log exercise in iOS app:
   - Exercise: Bench Press
   - Sets: 3, Reps: 10, Load: 135 lbs
   - RPE: 7/10, Pain: 2/10
2. Query Supabase:
   ```sql
   SELECT * FROM exercise_logs
   WHERE patient_id = 'TEST_PATIENT_ID'
   ORDER BY created_at DESC LIMIT 1;
   ```
3. Expected: Recent log matches ALL app entry fields
4. Verify timestamps are in UTC
5. Check foreign key integrity (session_id, patient_id, session_exercise_id)

**Test 3: Data sync - Pain logging**
1. Log pain in iOS app:
   - Pain at rest: 2/10
   - Pain during: 5/10
   - Pain after: 3/10
   - Notes: "Shoulder felt tight"
2. Query Supabase:
   ```sql
   SELECT * FROM pain_logs
   WHERE patient_id = 'TEST_PATIENT_ID'
   ORDER BY logged_at DESC LIMIT 1;
   ```
3. Expected: All pain scores match
4. Verify CHECK constraints enforced (0-10 range)
5. Verify notes field populated

**Test 4: Row Level Security (RLS)**
1. Create 2 test patients: Patient A, Patient B
2. Login as Patient A in iOS app
3. Attempt to view Patient B's data
4. Expected: **FAIL** - Should not see any of Patient B's data
5. Verify in Supabase logs: RLS policy blocked the query
6. Test for therapist: Should see all their patients

**Test 5: Real-time updates (if implemented)**
1. Open app on iOS Simulator and physical device
2. Login as same patient on both
3. Log exercise on Simulator
4. Expected: Physical device updates within 1-2 seconds
5. If not implemented: Verify pull-to-refresh works

**Test 6: Concurrent write conflicts**
1. Open app on two devices with same patient
2. Edit same session on both devices simultaneously
3. Save on device 1, then device 2
4. Expected: Last write wins OR conflict resolution dialog
5. Verify data consistency in Supabase

#### Agent Service ↔ Supabase (STANDALONE TESTING)

**Test 7: Patient summary accuracy**
1. Create test patient in Supabase with known data:
   ```sql
   INSERT INTO patients (id, first_name, last_name, sport, position)
   VALUES ('test-uuid-123', 'QA', 'Test', 'Baseball', 'Pitcher');
   ```
2. Add 7 days of pain logs with known values
3. Call agent service: `GET /patient-summary/test-uuid-123`
4. Verify response:
   - Patient name matches
   - Pain trend has 7 entries
   - Adherence calculation correct
   - All foreign key relationships resolved

**Test 8: View queries accuracy**
1. Query `vw_patient_adherence` directly:
   ```sql
   SELECT * FROM vw_patient_adherence WHERE patient_id = 'test-uuid';
   ```
2. Call agent service: `GET /patient-summary/test-uuid`
3. Compare `adherence_pct` values
4. Expected: **EXACT MATCH** (floating point precision)
5. Test edge cases:
   - Patient with 0 sessions (should return 0%, not error)
   - Patient with 100% adherence
   - Patient with partial adherence (e.g., 7/10 = 70%)

**Test 9: Flag computation**
1. Create patient with pain spike (log pain 9/10)
2. Call: `GET /flags/test-patient-id`
3. Expected: Response includes HIGH severity flag
4. Verify flag details:
   - `flag_type`: "pain_spike"
   - `severity`: "HIGH"
   - `triggered_at`: Recent timestamp
   - `context`: Contains pain value and session info

**Test 10: Protocol validation**
1. Create patient with protocol constraint (max velocity: 85 mph)
2. POST to `/protocol/validate`:
   ```json
   {
     "patientId": "test-uuid",
     "recommendation": {
       "type": "bullpen_session",
       "velocity": 90
     }
   }
   ```
3. Expected: Validation fails with constraint violation
4. Verify response includes:
   - `is_valid`: false
   - `violations`: Array with velocity constraint
   - `severity`: "ERROR"

#### Linear Integration

**Test 11: Sync Linear plan**
```bash
cd /Users/expo/pt-performance
python3 linear_client.py export-md --output /tmp/linear_plan.md
```
Expected:
- Markdown file created
- Contains all issues from "Agent-Control-Plane" team
- Issues grouped by status (Backlog, In Progress, Done)

**Test 12: Create Plan Change Request via Agent Service**
1. Trigger high-severity flag (pain spike)
2. Call agent service: `GET /pt-assistant/summary/test-patient-id`
3. Expected: Agent service auto-creates PCR in Linear
4. Verify in Linear:
   - Issue created with title "Plan Change Request: Patient..."
   - Label: `zone-4b`
   - Status: "In Review"
   - Description contains flag details

**Test 13: Update issue status**
```bash
python3 linear_client.py update-status \
  --issue-id <id> \
  --state-id <done-state-id>
```
Expected:
- Issue status updated in Linear UI
- Status history shows transition
- No error messages

#### Edge Cases & Error Conditions

**Test 14: Invalid patient ID**
- iOS app: Pass non-existent patient ID to query
- Expected: Empty result or appropriate error message
- Agent service: `GET /patient-summary/invalid-uuid`
- Expected: 404 or 500 with clear error message

**Test 15: Malformed data**
- Insert exercise log with pain score > 10 (should fail CHECK constraint)
- Insert bullpen log with velocity > 110 mph (should fail)
- Insert pain log with negative values (should fail)
- Expected: All fail with constraint violation errors

**Test 16: Network interruption during write**
1. Start logging exercise in iOS app
2. Disconnect network (Airplane mode)
3. Complete exercise log entry
4. Reconnect network
5. Expected: Data saves when network restored OR clear error message

**Test 17: Concurrent session logging**
1. Patient logs session on iOS
2. Therapist modifies same session on web (future)
3. Expected: Conflict detection OR last write wins with notification

**Test 18: Large dataset performance**
1. Create patient with 1000+ exercise logs
2. Query patient history in iOS app
3. Expected:
   - Loads within 2-3 seconds
   - Pagination or lazy loading implemented
   - No memory issues or crashes

**Test 19: Stale authentication token**
1. Login to iOS app
2. Wait for token expiration (check Supabase JWT expiry)
3. Attempt to log exercise
4. Expected:
   - Auto-refresh token OR
   - Prompt to re-authenticate
   - Data not lost

**Test 20: Agent service down**
1. Stop agent service: `Ctrl+C` in terminal
2. iOS app should still function (since it doesn't call agent service)
3. Expected: No impact on iOS app functionality
4. Test future: When iOS uses agent service, should show appropriate error

---

## End-to-End Test Scenarios

### Scenario 1: New Patient Onboarding

**Actors:** Therapist, Patient

**Steps:**
1. **Therapist:** Create patient account (email: test-patient@example.com)
2. **Therapist:** Create 8-week program with 3 phases
3. **Therapist:** Add exercises to Day 1 session
4. **Patient:** Sign in with credentials
5. **Patient:** View "Today" tab - see Day 1 session
6. **Patient:** Log all exercises with sets/reps/load/RPE
7. **Patient:** Log pain scores (rest: 2, during: 4, after: 3)
8. **Patient:** Complete session
9. **Therapist:** View dashboard - verify patient appears with adherence
10. **Therapist:** View patient detail - verify logged data

**Expected Results:**
- ✅ Patient can authenticate
- ✅ Today's session displays correctly
- ✅ Exercise logs saved to database
- ✅ Pain logs saved and visible in trends
- ✅ Therapist sees updated adherence (100%)
- ✅ Charts display data

### Scenario 2: Pitcher Bullpen Session

**Actors:** Patient (Pitcher)

**Steps:**
1. **Patient:** Navigate to "Log Bullpen" or Today's session (if bullpen day)
2. **Patient:** Enter bullpen details:
   - Pitch type: Fastball
   - Pitch count: 30
   - Average velocity: 85 mph
   - Command rating: 7/10
   - Hit spots: 24/30
   - Pain score: 3/10
3. **Patient:** Save bullpen log
4. **Patient:** View progress charts
5. **Patient:** Check throwing workload view

**Expected Results:**
- ✅ Bullpen log saved with correct data
- ✅ Velocity trend chart updates
- ✅ Command rating visible
- ✅ Hit spot percentage calculated (80%)
- ✅ Pain score logged
- ✅ Workload flag computed (if high volume)

### Scenario 3: Pain Spike Detection

**Actors:** Agent Service, Therapist

**Steps:**
1. **Setup:** Patient logs session with pain spike (8/10)
2. **Agent:** Pain flag computation triggers (future feature)
3. **Agent:** Creates Plan Change Request in Linear
4. **Agent:** Sends Slack notification to therapist (future)
5. **Therapist:** Reviews PCR in Linear
6. **Therapist:** Approves or modifies plan change
7. **Patient:** Sees updated program with modifications

**Expected Results (Future):**
- ✅ Pain flag detected by agent
- ✅ PCR created in Linear with zone-4b label
- ✅ Slack notification sent
- ✅ Therapist can review and approve
- ✅ Program modified after approval

### Scenario 4: Adherence Tracking

**Actors:** Patient, Therapist

**Steps:**
1. **Therapist:** Create program with 3 sessions/week for 4 weeks (12 sessions)
2. **Patient:** Complete 10 sessions over 4 weeks
3. **Patient:** Miss 2 sessions
4. **Therapist:** View dashboard
5. **Therapist:** Check patient adherence metric

**Expected Results:**
- ✅ Adherence calculated: 10/12 = 83.3%
- ✅ Dashboard shows adherence indicator (yellow/warning if < 85%)
- ✅ Missed sessions visible in history
- ✅ Therapist can filter by low adherence patients

---

## Performance Testing & Benchmarks

### iOS App Performance

#### Cold Start Time
**Target:** < 3 seconds from tap to interactive

**Test Method:**
1. Force quit app completely
2. Clear app from memory
3. Tap app icon
4. Start timer
5. Stop when login screen or main screen is interactive

**Measure:**
- Time to first screen render
- Time to interactive (can tap buttons)
- Memory usage at launch

**Benchmarks:**
- iPhone 15 Pro: < 2 seconds ✅
- iPhone 13: < 2.5 seconds ✅
- iPhone SE (3rd gen): < 3 seconds ⚠️

#### Warm Start Time
**Target:** < 1 second from background to foreground

**Test Method:**
1. Launch app
2. Send to background (Home button/swipe)
3. Wait 5 seconds
4. Bring back to foreground
5. Measure time to interactive

#### Exercise Logging Performance
**Target:** < 1 second from save tap to confirmation

**Test Method:**
1. Fill exercise log form
2. Tap "Save"
3. Measure time until:
   - Loading indicator disappears
   - Success message shown
   - Navigation back to session view

**Includes:**
- Validation (< 50ms)
- Supabase write (< 500ms)
- UI update (< 300ms)
- Total: < 1 second

**Test with:**
- Good network (WiFi): Should be < 500ms
- Slow network (3G simulation): Should be < 2 seconds
- No network: Should show error immediately

#### Chart Rendering Performance
**Target:** < 2 seconds for charts with 100+ data points

**Test Method:**
1. Navigate to Progress/Analytics tab
2. Select patient with 90 days of data (~270 data points)
3. Measure time from tap to chart fully rendered

**Charts to Test:**
- Pain trend line chart (7-90 days)
- Velocity chart (bullpen sessions)
- Adherence bar chart (weekly)
- Strength progression chart (1RM estimates)

**Benchmarks:**
| Data Points | Target Time | Acceptable |
|-------------|-------------|------------|
| 7-30        | < 500ms     | < 1s       |
| 31-100      | < 1s        | < 2s       |
| 101-365     | < 2s        | < 3s       |
| 366+        | < 3s        | < 5s       |

#### List Scrolling Performance
**Target:** 60 FPS during scroll

**Test Method:**
1. Navigate to list with 100+ items:
   - Exercise history list
   - Patient list (therapist view)
   - Help articles list
2. Scroll rapidly up and down
3. Measure FPS using Xcode Instruments

**Expected:**
- Maintains 60 FPS on iPhone 12+
- Maintains 50+ FPS on older devices
- No janky scrolling or stutters
- Smooth deceleration

#### Memory Usage
**Target:** < 200 MB for typical usage

**Test Method:**
1. Launch app and login
2. Navigate through all main screens
3. Log 10 exercises
4. View charts
5. Browse help articles
6. Measure peak memory in Xcode

**Benchmarks:**
- Idle at login screen: < 50 MB
- Main session view: < 100 MB
- Charts rendered: < 150 MB
- Peak with all features: < 200 MB

**Red Flags:**
- Memory leaks (increasing over time)
- Memory warnings in console
- App crashes on older devices (iPhone SE, iPhone 8)

### Agent Service Performance

#### Endpoint Response Times
**Target:** 95th percentile < 500ms

**Test Method:**
Use `curl` with timing or Apache Bench (`ab`):
```bash
# Single request timing
time curl http://localhost:4000/patient-summary/test-patient-id

# Load test with 100 requests
ab -n 100 -c 10 http://localhost:4000/health
```

**Benchmarks:**

| Endpoint | P50 | P95 | P99 | Max Acceptable |
|----------|-----|-----|-----|----------------|
| `/health` | < 10ms | < 20ms | < 50ms | 100ms |
| `/patient-summary/:id` | < 200ms | < 500ms | < 1s | 2s |
| `/today-session/:id` | < 150ms | < 400ms | < 800ms | 1.5s |
| `/pt-assistant/summary/:id` | < 300ms | < 800ms | < 2s | 5s |
| `/flags/:id` | < 250ms | < 600ms | < 1.5s | 3s |
| `/strength-targets/:id` | < 200ms | < 500ms | < 1s | 2s |

**Factors affecting performance:**
- Network latency to Supabase
- Database query complexity
- Amount of patient data
- Concurrent requests

#### Load Testing
**Target:** Handle 10 concurrent users without degradation

**Test Method:**
```bash
# Install Apache Bench
brew install apache2

# Test with 1000 requests, 10 concurrent
ab -n 1000 -c 10 -g results.tsv \
  http://localhost:4000/patient-summary/test-patient-id

# Analyze results
# - Requests per second (target: > 20)
# - Failed requests (target: 0)
# - Time per request (target: < 500ms average)
```

**Test Scenarios:**
1. **Light load:** 5 concurrent users, 100 requests each
2. **Moderate load:** 10 concurrent users, 500 requests each
3. **Heavy load:** 20 concurrent users, 1000 requests each
4. **Spike test:** Ramp from 1 to 50 users over 1 minute

**Success Criteria:**
- ✅ No failed requests (500 errors)
- ✅ Response times stay within benchmarks
- ✅ No memory leaks (check `top` or Activity Monitor)
- ✅ CPU usage < 80% on average

#### Rate Limiting Verification
**Target:** Rate limits enforced correctly

**Test Method:**
```bash
# Test default limiter (100 requests per 15 min)
for i in {1..101}; do
  curl http://localhost:4000/patient-summary/test-id
  echo "Request $i"
done
# Expected: Request 101 returns 429 (Too Many Requests)

# Test LLM limiter (10 per minute)
for i in {1..11}; do
  curl http://localhost:4000/pt-assistant/summary/test-id
  echo "Request $i"
done
# Expected: Request 11 returns 429
```

**Verify Response:**
```json
{
  "error": "Too many requests, please try again later"
}
```

### Database Query Performance

#### Simple Queries
**Target:** < 100ms

**Test Method:**
```sql
-- Test in Supabase SQL Editor with EXPLAIN ANALYZE
EXPLAIN ANALYZE
SELECT * FROM patients WHERE id = 'test-uuid';

-- Check execution time in results
-- Expected: < 10ms (indexed lookup)
```

**Queries to Test:**
- Patient lookup by ID (< 10ms)
- Exercise templates by category (< 50ms)
- Recent exercise logs for patient (< 100ms)
- Pain logs for last 7 days (< 100ms)

#### Complex View Queries
**Target:** < 500ms

**Test Method:**
```sql
EXPLAIN ANALYZE
SELECT * FROM vw_patient_adherence WHERE patient_id = 'test-uuid';

EXPLAIN ANALYZE
SELECT * FROM vw_pain_trend WHERE patient_id = 'test-uuid';

EXPLAIN ANALYZE
SELECT * FROM vw_throwing_workload ORDER BY session_date DESC LIMIT 30;
```

**Benchmarks:**
- `vw_patient_adherence`: < 200ms
- `vw_pain_trend`: < 150ms
- `vw_throwing_workload`: < 300ms
- `vw_therapist_patient_summary`: < 500ms (aggregates multiple patients)

**Optimization Checks:**
- Indexes used (check EXPLAIN output)
- No sequential scans on large tables
- Joins are efficient (nested loop vs hash join)

#### Bulk Operations
**Target:** Handle 1000 records without timeout

**Test Method:**
```sql
-- Insert 1000 exercise logs
INSERT INTO exercise_logs (patient_id, session_id, performed_at, ...)
SELECT
  'test-patient-uuid',
  'test-session-uuid',
  NOW() - (n || ' days')::interval,
  ...
FROM generate_series(1, 1000) n;

-- Measure time
-- Expected: < 5 seconds
```

#### Connection Pool Performance
**Target:** No connection exhaustion under load

**Test Method:**
1. Start agent service
2. Run load test with 50 concurrent requests
3. Monitor Supabase dashboard → Database → Connections
4. Expected: Connections managed properly, no "too many connections" errors

**Supabase Connection Limits:**
- Free tier: 60 connections
- Pro tier: 200 connections
- Need to verify agent service doesn't exhaust pool

### Network Performance

#### API Payload Sizes
**Target:** Keep responses < 100 KB

**Test Method:**
```bash
# Measure response size
curl -w "%{size_download}\n" -o /dev/null -s \
  http://localhost:4000/patient-summary/test-id

# Example output: 12547 (bytes)
```

**Benchmarks:**
- `/health`: < 1 KB ✅
- `/patient-summary`: < 50 KB ✅
- `/pt-assistant/summary`: < 20 KB ✅
- `/therapist/:id/dashboard`: < 100 KB ⚠️

**Optimization:**
- Paginate large lists (don't return 1000 logs at once)
- Use compression (gzip)
- Minimize nested objects
- Omit null fields

#### iOS Network Calls
**Target:** < 10 API calls per screen load

**Test Method:**
1. Open Charles Proxy or Proxyman
2. Launch iOS app
3. Navigate to session view
4. Count Supabase API calls

**Expected:**
- Login screen: 1 call (auth check)
- Today's session: 3-5 calls (patient, program, session, exercises)
- Progress charts: 2-4 calls (logs, trends)
- Exercise log save: 1 call (insert)

**Red Flags:**
- N+1 query problem (1 call per item in a list)
- Redundant calls for same data
- No caching (same data fetched multiple times)

### Performance Testing Tools

**iOS:**
- Xcode Instruments (Time Profiler, Allocations, Leaks)
- SwiftUI View Debugging
- Network Link Conditioner (simulate slow networks)

**Backend:**
- Apache Bench (`ab`)
- `curl` with timing
- Node.js profiling (`node --prof`)
- Supabase Dashboard (query execution times)

**Database:**
- `EXPLAIN ANALYZE` in Supabase SQL Editor
- Supabase Dashboard → Performance
- `pg_stat_statements` (query statistics)

---

## Known Issues & Risks

### High Priority Issues

1. **Authentication Edge Cases**
   - Email verification flow may not be fully tested
   - Password reset flow needs validation
   - Token refresh on long sessions

2. **Data Sync Timing**
   - Potential race conditions when logging multiple exercises quickly
   - Real-time updates not implemented (requires manual refresh)

3. **Offline Functionality**
   - App requires network connection
   - No offline mode for logging sessions
   - Risk: Patient at gym with poor connectivity

4. **Agent Service Stability**
   - New service, limited production testing
   - Error handling for Supabase connection failures
   - No retry logic for failed requests

### Medium Priority Issues

5. **iOS App Memory Usage**
   - Large exercise template library may impact performance
   - Chart rendering with months of data needs optimization

6. **Database Query Performance**
   - Some analytics views may be slow with large datasets
   - Missing indexes on certain foreign keys (verify)

7. **Linear Integration**
   - Manual sync required (no webhooks)
   - API rate limits not handled
   - Offline fallback to cached plan

### Low Priority Issues

8. **UI/UX Polish**
   - Some screens need accessibility improvements
   - Loading states inconsistent
   - Error messages not user-friendly

9. **Documentation Gaps**
   - Some runbooks incomplete
   - API documentation needs OpenAPI spec
   - Help articles need review for accuracy

### Security Considerations

10. **RLS Policies - Deep Dive**
    - **Issue:** Row Level Security must prevent all data leakage
    - **Test Cases:**
      - Patient A cannot see Patient B's data (any table)
      - Therapist can only see their own patients
      - Therapist switching teams loses access to old patients
      - Admin role can see all data (if implemented)
      - Unauthenticated users see nothing
    - **Tables to test:** ALL 19 tables (patients, exercise_logs, pain_logs, etc.)
    - **Attack vectors:**
      - Direct SQL injection (should be prevented by Supabase)
      - JWT token manipulation (modify user_id claim)
      - Session hijacking (steal auth token)
    - **Testing approach:**
      ```sql
      -- Test as Patient A
      SET request.jwt.claims.sub = 'patient-a-uuid';
      SELECT * FROM patients; -- Should only see Patient A

      -- Test as Patient B
      SET request.jwt.claims.sub = 'patient-b-uuid';
      SELECT * FROM patients; -- Should only see Patient B

      -- Test data leakage via joins
      SELECT * FROM exercise_logs el
      JOIN patients p ON el.patient_id = p.id
      WHERE p.id = 'patient-b-uuid'; -- Should fail for Patient A
      ```

11. **API Security - Agent Service**
    - **Issue:** Agent service exposes patient IDs in URLs
    - **Risks:**
      - Patient IDs are UUIDs (enumeration difficult but possible)
      - No authentication layer on agent service (trusts all requests)
      - Rate limiting implemented but not tested under load
    - **Test Cases:**
      - Brute force patient ID enumeration (should be rate limited)
      - SQL injection via patientId parameter
      - XSS via patient notes/descriptions
      - CORS misconfiguration (check allowed origins)
    - **Recommendations:**
      - Add API key or JWT authentication to agent service
      - Use short-lived tokens instead of UUIDs in URLs
      - Implement request signing for sensitive operations

12. **HIPAA Compliance - Critical Requirements**
    - **What is PHI?** Protected Health Information includes:
      - Patient names, dates of birth
      - Medical history, medications
      - Exercise/injury data, pain scores
      - Therapist notes
    - **HIPAA Requirements:**
      - ✅ Encryption at rest (Supabase encrypts data)
      - ✅ Encryption in transit (HTTPS/TLS)
      - ⚠️ Access logs (need to verify Supabase logging)
      - ⚠️ Audit trail (need to implement change tracking)
      - ❌ Business Associate Agreement (BAA) with Supabase
      - ❌ Data retention policy (how long to keep old data?)
      - ❌ Data breach response plan
    - **Test Cases:**
      - Verify all API calls use HTTPS (no HTTP)
      - Check Supabase logs capture who accessed what patient
      - Test data export/deletion (patient right to data portability)
      - Verify password complexity requirements
      - Test session timeout (idle logout)
    - **Critical:** Full HIPAA audit required before production
    - See: `docs/COMPLIANCE_HIPAA_CHECKLIST.md`

13. **Authentication Security**
    - **Password Requirements:**
      - Test minimum length (should be 8+ characters)
      - Test complexity (uppercase, lowercase, number, symbol?)
      - Test common passwords blocked (e.g., "password123")
    - **Session Management:**
      - Test JWT expiration (default: 1 hour?)
      - Test refresh token flow
      - Test logout invalidates token
      - Test concurrent sessions (allowed or blocked?)
    - **Account Recovery:**
      - Test password reset flow
      - Verify reset links expire
      - Test account lockout after N failed attempts
      - Test email verification requirement

14. **Input Validation & Sanitization**
    - **SQL Injection:**
      - Test all text fields with SQL payloads
      - Example: `'; DROP TABLE patients; --`
      - Expected: Supabase SDK prevents this
    - **XSS (Cross-Site Scripting):**
      - Test notes fields with JavaScript
      - Example: `<script>alert('XSS')</script>`
      - Expected: iOS app should render safely (SwiftUI safe by default)
    - **NoSQL Injection:**
      - Not applicable (using PostgreSQL, not NoSQL)
    - **Command Injection:**
      - Test if any fields execute shell commands (should not)

15. **Data Encryption**
    - **At Rest:**
      - Verify Supabase encrypts database
      - Check encryption algorithm (AES-256?)
      - Verify encryption keys managed by Supabase
    - **In Transit:**
      - Verify all connections use TLS 1.2+
      - Check certificate validity
      - Test HTTPS enforcement (HTTP redirects to HTTPS?)
    - **iOS App Storage:**
      - Test if tokens stored in Keychain (secure)
      - Verify no sensitive data in UserDefaults
      - Check cache is encrypted or cleared on logout

---

## Data Integrity & Edge Case Testing

### Data Consistency Tests

#### Foreign Key Integrity
**Test Objective:** Ensure all relationships are maintained

**Test Cases:**
```sql
-- Test 1: Orphaned exercise logs (session_id doesn't exist)
SELECT el.id, el.session_id
FROM exercise_logs el
LEFT JOIN sessions s ON el.session_id = s.id
WHERE s.id IS NULL;
-- Expected: 0 rows

-- Test 2: Orphaned pain logs
SELECT pl.id, pl.patient_id
FROM pain_logs pl
LEFT JOIN patients p ON pl.patient_id = p.id
WHERE p.id IS NULL;
-- Expected: 0 rows

-- Test 3: Sessions without a parent phase
SELECT s.id, s.phase_id
FROM sessions s
LEFT JOIN phases ph ON s.phase_id = ph.id
WHERE ph.id IS NULL;
-- Expected: 0 rows

-- Test 4: Phases without a parent program
SELECT ph.id, ph.program_id
FROM phases ph
LEFT JOIN programs pr ON ph.program_id = pr.id
WHERE pr.id IS NULL;
-- Expected: 0 rows
```

**iOS App Test:**
1. Delete a program that has sessions logged
2. Expected: Cannot delete (foreign key constraint) OR cascade delete with warning
3. Check Supabase: Related data handled correctly

#### Cascade Delete Behavior
**Test Objective:** Verify data cleanup when parent records deleted

**Test Cases:**
1. **Delete Patient:**
   - Delete patient from Supabase
   - Verify all related data deleted:
     - Programs
     - Exercise logs
     - Pain logs
     - Bullpen logs
     - Session status
   - OR verify foreign keys prevent deletion

2. **Delete Program:**
   - Delete program
   - Verify phases, sessions, session_exercises deleted
   - Verify exercise_logs kept (historical data) OR deleted

**Expected Behavior:**
- Define in schema: CASCADE vs RESTRICT
- Historical data should be preserved (exercise logs)
- Active/future data can be deleted (sessions)

#### Transaction Consistency
**Test Objective:** Multi-step operations are atomic

**Test Scenario:**
1. Log exercise with multiple sets (3 sets)
2. Simulate failure after 2nd set insert
3. Expected: Either all 3 saved OR none saved (rollback)

**iOS App Test:**
1. Log session with 5 exercises
2. Airplane mode after 3rd exercise
3. Expected: Either all 5 or first 3 saved (depends on implementation)

### Edge Cases

#### Boundary Value Testing

**Pain Scores (0-10):**
- ✅ Valid: 0, 5, 10
- ❌ Invalid: -1, 11, 10.5 (if integer), null

**Velocity (40-110 mph):**
- ✅ Valid: 40, 75, 110
- ❌ Invalid: 39, 111, 0, null, negative

**RPE (0-10):**
- ✅ Valid: 0, 7, 10
- ❌ Invalid: -1, 11, null

**Date/Time:**
- ✅ Valid: Current date, past dates
- ❌ Invalid: Future dates (depends on use case), null
- Edge: Logging exercise at 11:59 PM vs 12:00 AM (date boundaries)

**Text Fields:**
- Test max lengths (names: 255?, notes: 1000?)
- Test empty strings vs null
- Test special characters: `', ", \, <, >, &`
- Test Unicode: 🏋️, 中文, Español

#### Null/Empty Value Handling

**Test Cases:**
```sql
-- Can patient have null sport?
INSERT INTO patients (first_name, last_name, sport)
VALUES ('Test', 'User', NULL);
-- Expected: Depends on schema (required vs optional)

-- Can exercise log have null pain score?
INSERT INTO exercise_logs (patient_id, session_id, performed_at, pain_score)
VALUES ('uuid', 'uuid', NOW(), NULL);
-- Expected: Allowed (pain is optional)

-- Can session have null weekday?
INSERT INTO sessions (phase_id, name, sequence, weekday)
VALUES ('uuid', 'Session 1', 1, NULL);
-- Expected: Depends on schema
```

**iOS App Tests:**
1. Leave optional fields blank in forms
2. Expected: Save successfully with null or default values
3. Display nulls as "Not specified" or "-"

#### Time Zone Handling

**Critical for Global Use:**
- All timestamps in UTC in database ✅
- iOS app displays in user's local time
- Test edge cases:
  - User logs exercise at 11 PM PST (midnight EST)
  - User travels across time zones
  - Daylight Saving Time transitions

**Test Cases:**
1. Set device to Tokyo time zone
2. Log exercise at 2 AM
3. Check Supabase: Timestamp in UTC
4. Change device to New York time zone
5. View exercise: Should show correct local time

#### Extremely Large Values

**Stress Test:**
- Patient with 10,000 exercise logs
- Program with 52 phases (1 year weekly)
- Session with 50 exercises
- Notes field with 10,000 characters

**Expected:**
- App handles gracefully (pagination, lazy loading)
- Database queries still performant
- No crashes or memory issues

#### Zero/Minimum Values

**Test Cases:**
- Program with 0 sessions (empty program)
- Session with 0 exercises (rest day?)
- Patient with 0 adherence (missed all sessions)
- Exercise with 0 load (bodyweight)
- Exercise with 0 reps (hold exercises)

**Expected:**
- No division by zero errors
- Charts display correctly (empty or "No data")
- Calculations handle edge case (0/0 = 0% adherence)

#### Duplicate Data

**Test Cases:**
- Insert exercise log with same timestamp twice
- Create two programs with same name
- Log pain twice for same session

**Expected:**
- Unique constraints prevent duplicates OR
- Duplicates allowed but clearly distinguished
- No accidental overwrites

#### Race Conditions

**Scenario 1: Concurrent Session Edits**
1. Therapist opens session editor
2. Patient logs exercises for same session
3. Therapist saves changes
4. Expected: Conflict detection or last write wins

**Scenario 2: Concurrent Flag Creation**
1. Agent service computes flags
2. Detects pain spike
3. Two concurrent requests trigger PCR creation
4. Expected: Only 1 PCR created (duplicate detection)

### Data Migration & Versioning

#### Schema Migration Testing

**If schema changes:**
1. Export production data
2. Apply migration locally
3. Verify:
   - All migrations apply successfully
   - No data loss
   - Foreign keys intact
   - Indexes recreated
4. Test rollback (if migrations support down)

**Test Cases:**
- Add new column (should default null or default value)
- Remove column (data lost - need backup)
- Rename column (need data migration)
- Change data type (e.g., varchar to integer)

#### Data Seeding

**Test with seed data:**
```bash
cd supabase
supabase db reset  # Drops all tables
supabase db push   # Reapplies migrations

# Verify:
# - All tables recreated
# - Seed data inserted
# - Views functional
```

**Seed Data Should Include:**
- 2-3 therapists
- 5-10 patients (various sports/positions)
- 3-5 programs (active, completed, paused)
- 50-100 exercise templates
- 100+ exercise logs (realistic data)
- Pain logs with trends (improving, worsening, stable)
- Bullpen logs for pitchers
- 3 protocol templates with constraints

### Data Export & Import

#### Patient Data Portability (HIPAA Requirement)

**Test Export:**
1. Patient requests all their data
2. Expected: JSON/CSV export with:
   - Profile info
   - All exercise logs
   - Pain logs
   - Bullpen logs
   - Programs and sessions
3. Verify data completeness
4. Verify no other patient's data included

**Test Import:**
1. Import exported data to new patient account
2. Expected: All data restored correctly
3. Foreign keys regenerated
4. Timestamps preserved

#### Backup & Restore

**Test Cases:**
1. Take database backup
2. Delete test patient
3. Restore from backup
4. Expected: Patient data restored

**Supabase Backups:**
- Automatic daily backups (Pro plan)
- Point-in-time recovery (if enabled)
- Test restoration process

### Referential Integrity Across Services

#### iOS ↔ Supabase Consistency

**Test Scenario:**
1. iOS app caches session data locally
2. Therapist modifies session in Supabase directly (SQL)
3. iOS app doesn't know about change
4. Patient logs exercise for modified session
5. Expected: Conflict detection or force refresh

**Mitigation:**
- Real-time subscriptions (Supabase Realtime)
- Version numbers on sessions (optimistic locking)
- Pull-to-refresh forces sync

#### Agent Service ↔ Supabase Consistency

**Test Scenario:**
1. Agent service caches patient summary
2. Patient logs exercise in iOS app
3. Call `/patient-summary/:id` again
4. Expected: Updated data (no stale cache)

**Verify:**
- Agent service doesn't cache Supabase data
- OR cache invalidation works correctly
- Response includes `generated_at` timestamp

---

## Quality Checklist

### Functional Testing

- [ ] **Authentication**
  - [ ] Sign up with email/password
  - [ ] Sign in with existing account
  - [ ] Sign out
  - [ ] Password reset (if implemented)
  - [ ] Email verification

- [ ] **Patient Flow**
  - [ ] View today's session
  - [ ] Log exercise (sets/reps/load/RPE/pain)
  - [ ] View history
  - [ ] View progress charts
  - [ ] Log bullpen session (for pitchers)
  - [ ] View help articles
  - [ ] Search help content

- [ ] **Therapist Flow**
  - [ ] View patient dashboard
  - [ ] View patient detail
  - [ ] Create new program
  - [ ] Edit existing program
  - [ ] Add exercises to sessions
  - [ ] View patient adherence
  - [ ] View pain trends

- [ ] **Agent Service**
  - [ ] Health check endpoint responds
  - [ ] Patient summary returns correct data
  - [ ] Today's session endpoint works
  - [ ] PT Assistant summary generates text

- [ ] **Database**
  - [ ] All migrations applied successfully
  - [ ] All tables exist
  - [ ] All views return data
  - [ ] CHECK constraints enforce validation
  - [ ] RLS policies protect data

### Non-Functional Testing

- [ ] **Performance** (See detailed benchmarks below)
  - [ ] App launches in < 3 seconds (cold start)
  - [ ] App launches in < 1 second (warm start)
  - [ ] Exercise logging completes in < 1 second
  - [ ] Charts render in < 2 seconds (with 100+ data points)
  - [ ] Agent service responds in < 500ms (95th percentile)
  - [ ] Database queries < 100ms (simple), < 500ms (complex views)

- [ ] **Usability**
  - [ ] Navigation is intuitive
  - [ ] Forms are easy to complete
  - [ ] Error messages are clear
  - [ ] Loading states are visible
  - [ ] Success confirmations are clear

- [ ] **Security**
  - [ ] Patients can only see own data
  - [ ] Therapists can only see their patients
  - [ ] Passwords are hashed
  - [ ] API keys are not exposed
  - [ ] RLS prevents data leakage

- [ ] **Reliability**
  - [ ] App doesn't crash during normal use
  - [ ] Agent service handles errors gracefully
  - [ ] Database connections are managed properly
  - [ ] No memory leaks in iOS app

- [ ] **Compatibility**
  - [ ] iOS 17.0+ supported
  - [ ] iPhone SE to iPhone 15 Pro Max
  - [ ] Light and dark mode
  - [ ] Portrait and landscape (where applicable)

### Code Quality

- [ ] **iOS App**
  - [ ] Swift code follows conventions
  - [ ] SwiftUI views are modular
  - [ ] ViewModels separate logic from UI
  - [ ] Error handling is comprehensive
  - [ ] Comments explain complex logic

- [ ] **Agent Service**
  - [ ] JavaScript/Node.js best practices
  - [ ] Express routes are organized
  - [ ] Async/await used correctly
  - [ ] Error handling in all routes
  - [ ] Environment variables used for config

- [ ] **Database**
  - [ ] Migrations are reversible (down migrations)
  - [ ] Indexes on foreign keys
  - [ ] Views are optimized
  - [ ] RLS policies are comprehensive
  - [ ] Naming conventions consistent

### Documentation

- [ ] **README files**
  - [ ] Root README is clear
  - [ ] Each component has README
  - [ ] Setup instructions work
  - [ ] Prerequisites listed

- [ ] **API Documentation**
  - [ ] Endpoints documented
  - [ ] Request/response examples
  - [ ] Error codes listed
  - [ ] Authentication explained

- [ ] **Code Comments**
  - [ ] Complex logic explained
  - [ ] TODO items tracked
  - [ ] Deprecated code marked
  - [ ] Public functions documented

---

## Documentation References

### Essential Reading

1. **[README.md](./README.md)** - Project overview
2. **[QUICK_START.md](./QUICK_START.md)** - Quick start guide
3. **[PT_APP_README.md](./PT_APP_README.md)** - Complete project structure
4. **[SCHEMA_STRUCTURE_SUMMARY.md](./SCHEMA_STRUCTURE_SUMMARY.md)** - Database schema
5. **[INTEGRATION_GUIDE.md](./INTEGRATION_GUIDE.md)** - Linear integration

### Architecture & Design

6. **[docs/PT_APP_SYSTEM_GUIDE.md](./docs/PT_APP_SYSTEM_GUIDE.md)** - System architecture
7. **[docs/AGENT_GOVERNANCE.md](./docs/AGENT_GOVERNANCE.md)** - Agent rules
8. **[docs/SCHEMA_VALIDATION.md](./docs/SCHEMA_VALIDATION.md)** - Database validation

### Setup & Configuration

9. **[SUPABASE_CLI_SETUP.md](./SUPABASE_CLI_SETUP.md)** - Supabase setup
10. **[docs/ENVIRONMENT_SETUP.md](./docs/ENVIRONMENT_SETUP.md)** - Environment config
11. **[agent-service/README.md](./agent-service/README.md)** - Agent service setup

### Testing & Deployment

12. **[ios-app/TESTFLIGHT_RUNBOOK.md](./ios-app/TESTFLIGHT_RUNBOOK.md)** - TestFlight deployment
13. **[ios-app/TESTFLIGHT_SETUP.md](./ios-app/TESTFLIGHT_SETUP.md)** - TestFlight config
14. **[docs/runbooks/](./docs/runbooks/)** - Various runbooks

### Compliance & Security

15. **[docs/COMPLIANCE_HIPAA_CHECKLIST.md](./docs/COMPLIANCE_HIPAA_CHECKLIST.md)** - HIPAA compliance
16. **[docs/ERROR_HANDLING.md](./docs/ERROR_HANDLING.md)** - Error handling guide

### User Documentation

17. **[docs/USER_GUIDE.md](./docs/USER_GUIDE.md)** - User guide
18. **[docs/VIDEO_CONTENT_GUIDE.md](./docs/VIDEO_CONTENT_GUIDE.md)** - Video content

### Product & Planning

19. **[PRODUCT_ROADMAP_100_ISSUES.md](./PRODUCT_ROADMAP_100_ISSUES.md)** - Product roadmap
20. **[PRODUCT_ROADMAP_HEALTH_INTELLIGENCE.md](./PRODUCT_ROADMAP_HEALTH_INTELLIGENCE.md)** - Health AI roadmap
21. **[docs/LINEAR_MAPPING_GUIDE.md](./docs/LINEAR_MAPPING_GUIDE.md)** - Linear issue mapping

---

## Contact & Support

### Repository
- **GitHub:** [github.com/pauljroma/pt-performance](https://github.com/pauljroma/pt-performance)
- **Issues:** Create issues in GitHub or Linear

### Linear Workspace
- **Team:** Agent-Control-Plane (ACP)
- **Project:** MVP 1 — PT App & Agent Pilot
- **URL:** https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

### Key Files for QA

```bash
# Database schema
/supabase/migrations/

# iOS app source
/ios-app/PTPerformance/PTPerformance/

# Agent service
/agent-service/src/

# Test data
/supabase/Data/
/sample_workouts/

# Documentation
/docs/
```

---

## QA Assessment Timeline

### Phase 1: Setup & Familiarization (2-3 hours)
- [ ] Clone repository
- [ ] Setup environment (.env files)
- [ ] Start Supabase (local or cloud)
- [ ] Start agent service (standalone testing)
- [ ] Build and run iOS app
- [ ] Read essential documentation
- [ ] Understand current vs future architecture

### Phase 2: Database Layer Testing (2-3 hours)
- [ ] Verify schema (19 tables, 7 views)
- [ ] Test CHECK constraints (23+ constraints)
- [ ] Test RLS policies (30+ policies)
- [ ] Test foreign key integrity
- [ ] Test analytics views
- [ ] Test data validation (boundary values)
- [ ] Test cascade delete behavior

### Phase 3: iOS App Functional Testing (3-4 hours)
- [ ] Test authentication flows (sign up, sign in, sign out)
- [ ] Test patient workflows (log exercise, pain, view history)
- [ ] Test therapist workflows (dashboard, create program, view patient detail)
- [ ] Test help system (189 articles)
- [ ] Test charts and analytics
- [ ] Test edge cases (null values, empty states, large datasets)

### Phase 4: Agent Service Testing (2-3 hours)
- [ ] Test all 10+ endpoints
- [ ] Test error handling (invalid IDs, missing data)
- [ ] Test flag computation
- [ ] Test PT Assistant summaries
- [ ] Test protocol validation
- [ ] Test Linear integration (PCR creation)
- [ ] Load testing (10+ concurrent users)

### Phase 5: Integration Testing (2-3 hours)
- [ ] Test iOS ↔ Supabase integration (20 test cases)
- [ ] Test agent service ↔ Supabase (10 test cases)
- [ ] Test data sync accuracy
- [ ] Test RLS enforcement (4 scenarios)
- [ ] Test concurrent operations
- [ ] Run 4 end-to-end scenarios

### Phase 6: Performance Testing (2-3 hours)
- [ ] iOS app launch times (cold/warm)
- [ ] Exercise logging speed
- [ ] Chart rendering performance
- [ ] Agent service response times (7 endpoints)
- [ ] Database query performance
- [ ] Load testing with Apache Bench
- [ ] Memory profiling

### Phase 7: Security Testing (2-3 hours)
- [ ] RLS policy audit (all 19 tables)
- [ ] Authentication security (tokens, sessions)
- [ ] Input validation (SQL injection, XSS)
- [ ] HIPAA compliance checks
- [ ] API security (rate limiting, authentication)
- [ ] Data encryption verification

### Phase 8: Edge Cases & Data Integrity (1-2 hours)
- [ ] Boundary value testing
- [ ] Null/empty value handling
- [ ] Time zone handling
- [ ] Large dataset stress testing
- [ ] Race condition scenarios
- [ ] Data consistency checks

### Phase 9: Non-Functional Testing (1-2 hours)
- [ ] Usability assessment
- [ ] Accessibility testing
- [ ] Compatibility testing (iOS versions, devices)
- [ ] Network interruption handling
- [ ] Offline functionality
- [ ] Error message clarity

### Phase 10: Reporting & Documentation (1-2 hours)
- [ ] Document all findings
- [ ] Prioritize issues (Critical/High/Medium/Low)
- [ ] Create detailed bug reports
- [ ] Compile test results summary
- [ ] Write recommendations
- [ ] Submit comprehensive QA report

**Total Estimated Time:** 12-16 hours (expanded from 8-12 hours)

**Recommended Schedule:**
- **Day 1 (8 hours):** Phases 1-5 (Setup through Integration Testing)
- **Day 2 (8 hours):** Phases 6-10 (Performance through Reporting)

**For Quick Assessment (8 hours):**
- Focus on Phases 1, 2, 3, 5, and 10 (skip deep performance and security audits)
- Prioritize functional testing and critical integration tests

---

## QA Report Template

When complete, submit a report with:

### 1. Executive Summary
- Overall quality assessment (Pass/Fail/Conditional)
- Critical issues found
- Recommended next steps

### 2. Test Results
- Functional tests: X passed, Y failed
- Integration tests: X passed, Y failed
- Non-functional tests: findings

### 3. Issues Found
For each issue:
- **Severity:** Critical/High/Medium/Low
- **Component:** iOS/Backend/Database
- **Steps to Reproduce:**
- **Expected vs Actual:**
- **Screenshots/Logs:**

### 4. Recommendations
- Must-fix before production
- Should-fix before launch
- Nice-to-have improvements

### 5. Positive Findings
- What works well
- Strengths of the platform

---

## Summary: Key Testing Priorities

### Critical Path Testing (Must Test)
1. ✅ **iOS ↔ Supabase Direct Integration** (this is how the app works NOW)
2. ✅ **Row Level Security** (prevents data leakage between patients)
3. ✅ **Authentication Flow** (sign up, sign in, token management)
4. ✅ **Exercise & Pain Logging** (core functionality)
5. ✅ **Database Constraints** (pain 0-10, velocity 40-110, etc.)

### Important Testing (Should Test)
6. ✅ **Agent Service Standalone** (test endpoints independently)
7. ✅ **Performance Benchmarks** (app launch < 3s, queries < 100ms)
8. ✅ **Data Integrity** (foreign keys, cascade deletes, consistency)
9. ✅ **Edge Cases** (boundary values, null handling, race conditions)
10. ✅ **HIPAA Compliance** (encryption, access logs, PHI protection)

### Nice to Have Testing (If Time Permits)
11. ✅ **Load Testing** (10+ concurrent users)
12. ✅ **Linear Integration** (PCR creation, issue updates)
13. ✅ **Memory Profiling** (check for leaks)
14. ✅ **Accessibility** (VoiceOver, Dynamic Type)
15. ✅ **Localization** (if multi-language support planned)

### What You'll Discover

**Current State:**
- iOS app is fully functional, connects directly to Supabase
- Database schema is comprehensive (19 tables, 7 views, 23 constraints)
- Agent service is operational but standalone (not used by iOS yet)
- RLS policies protect patient data
- Performance should be good for MVP scale (< 100 users)

**Known Gaps:**
- iOS doesn't use intelligent agent features (flags, PT Assistant, protocol validation)
- No therapist web portal (agent service ready for it)
- Limited offline functionality
- HIPAA compliance needs full audit
- No automated testing (unit tests, integration tests)

**Recommendations After QA:**
1. Integrate iOS app with agent service (unlock intelligent features)
2. Add comprehensive test suite (XCTest for iOS, Jest for backend)
3. Implement offline mode with conflict resolution
4. Complete HIPAA compliance audit
5. Add monitoring and alerting (Sentry, DataDog, or similar)

---

## Document Changelog

### Version 2.0 (2025-02-11)
- **Architecture Fix:** Corrected iOS → Supabase direct connection (not via agent service)
- **Added:** Performance benchmarks section (3,000+ words)
- **Added:** Security deep dive (RLS, HIPAA, authentication, input validation)
- **Added:** Data integrity testing (20+ test cases)
- **Added:** Edge case scenarios (boundary values, null handling, race conditions)
- **Expanded:** Integration testing from 7 to 20 test cases
- **Added:** Current vs Future integration status section
- **Updated:** QA timeline to 12-16 hours (from 8-12)
- **Total:** ~2,500+ lines (doubled from v1.0)

### Version 1.0 (2025-02-11)
- Initial comprehensive QA guide
- Basic architecture overview
- Functional testing checklists
- End-to-end scenarios
- Known issues and risks

---

**Good luck with your assessment! 🚀**

This document should give you everything needed for a thorough QA evaluation. The platform is well-architected and mostly functional, with clear paths for future enhancements.

For questions or clarifications:
- **GitHub:** [github.com/pauljroma/pt-performance](https://github.com/pauljroma/pt-performance)
- **Linear:** https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b
- **Issues:** Create in GitHub or Linear workspace
