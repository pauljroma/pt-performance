#!/usr/bin/env python3
"""
Populate Linear from Documentation
Creates Linear issues for ALL epics, runbooks, and test tasks from documentation.
"""

import asyncio
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_bootstrap import LinearBootstrap
from linear_client import LinearClient


# ========== EPIC TASKS (Extracted from all 15 epics) ==========
EPIC_TASKS = [
    # EPIC_B: Strength & Conditioning Model
    {
        "epic": "EPIC_B",
        "title": "Implement 1RM computation utils from XLS formulas",
        "description": """Create utilities to calculate 1RM using Epley, Brzycki, and Lombardi formulas exactly as used in the XLS.

**Formulas:**
- Epley: `1RM = W * (1 + R / 30)`
- Brzycki: `1RM = W * 36 / (37 - R)`
- Lombardi: `1RM = W * R^0.10`

**Acceptance Criteria:**
- Functions return accurate 1RM values matching XLS calculations
- All three methods implemented
- Unit tests cover edge cases (low reps, high reps)

**Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md""",
        "zones": ["zone-7", "zone-10b"],
        "priority": "High",
        "estimate": 2
    },
    {
        "epic": "EPIC_B",
        "title": "Add rm_estimate to exercise_logs and backfill logic",
        "description": """Add rm_estimate field to exercise_logs table and implement backfill logic for existing data.

**Acceptance Criteria:**
- exercise_logs table has rm_estimate column (numeric)
- is_pr boolean field added
- Backfill script calculates RM for existing logs
- Computed for each set based on default_rm_method

**Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md""",
        "zones": ["zone-7", "zone-8"],
        "priority": "High",
        "estimate": 3
    },
    {
        "epic": "EPIC_B",
        "title": "Build getStrengthTargets() backend endpoint",
        "description": """Create backend API that returns strength_load, hypertrophy_load, endurance_load with notes on which 1RM method was used.

**Endpoint:** `GET /api/strength-targets/:patientId/:exerciseTemplateId`

**Response:**
```json
{
  "strength_load": 255,
  "hypertrophy_load": 220,
  "endurance_load": 185,
  "rm_method": "epley",
  "estimated_1rm": 285
}
```

**Acceptance Criteria:**
- Endpoint returns correct strength targets (90% of 1RM)
- Hypertrophy targets (77.5% of 1RM)
- Endurance targets (65% of 1RM)
- Based on recent patient logs

**Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md""",
        "zones": ["zone-3c", "zone-7"],
        "priority": "High",
        "estimate": 3
    },
    {
        "epic": "EPIC_B",
        "title": "Display strength targets in therapist program editor",
        "description": """Build UI in therapist program editor to show estimated 1RM and recommended strength/hypertrophy/endurance loads.

**UI Elements:**
- Estimated 1RM display
- Recommended loads for each training goal
- Last 3 session performance
- PT override capability

**Acceptance Criteria:**
- Therapist sees recommended loads
- Can override with custom values
- Shows which RM method used
- Updates based on latest logs

**Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md""",
        "zones": ["zone-12"],
        "priority": "Medium",
        "estimate": 4
    },

    # EPIC_C: Throwing, On-Ramp, and Plyo Model
    {
        "epic": "EPIC_C",
        "title": "Normalize bullpen tracker into bullpen_logs and add command metrics",
        "description": """Convert bullpen tracker data into bullpen_logs table with pitch_type, missed_spot_count, hit_spot_count, hit_spot_pct, and avg_velocity fields.

**Table Structure:**
- pitch_type (text)
- missed_spot_count (int)
- hit_spot_count (int)
- hit_spot_pct (numeric)
- avg_velocity (numeric)
- pain_score (0-10)

**Acceptance Criteria:**
- bullpen_logs table created
- Seed with sample Brebbia data
- Command metrics calculated correctly

**Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md""",
        "zones": ["zone-7", "zone-8"],
        "priority": "High",
        "estimate": 3
    },
    {
        "epic": "EPIC_C",
        "title": "Model 8-week on-ramp as program → phases → sessions",
        "description": """Structure the 8-week on-ramp progression as a Program with Phases representing weeks and Sessions representing individual throwing days.

**Structure:**
- Program: "8-Week On-Ramp"
- 8 Phases (one per week)
- 2-3 Sessions per phase (throwing days)
- Progressive volume/intensity

**Acceptance Criteria:**
- Sample 8-week program created
- Phases properly sequenced
- Throwing volume increases appropriately
- XLS data structure preserved

**Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md""",
        "zones": ["zone-7", "zone-12"],
        "priority": "High",
        "estimate": 4
    },
    {
        "epic": "EPIC_C",
        "title": "Implement vw_throwing_workload and vw_onramp_progress",
        "description": """Create database views for throwing workload summary and on-ramp progress tracking.

**Views:**
- vw_throwing_workload: aggregate pitch counts, velocity trends
- vw_onramp_progress: progression through 8-week program

**Acceptance Criteria:**
- Views return correct data for seeded patient
- Execute without errors
- Performance optimized (<500ms)

**Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md""",
        "zones": ["zone-7", "zone-10b"],
        "priority": "Medium",
        "estimate": 3
    },
    {
        "epic": "EPIC_C",
        "title": "Wire throwing workload flags into therapist dashboard",
        "description": """Display throwing workload flags (high workload, velocity drop) in the therapist dashboard UI.

**Flags to Display:**
- High workload (pitch count > threshold)
- Velocity drop (>3 mph decline)
- Command decline (>20% hit rate drop)
- Pain spike during throwing

**Acceptance Criteria:**
- Flags visible on patient card
- Color-coded by severity
- Tap to see detail
- Updates in real-time

**Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md""",
        "zones": ["zone-12"],
        "priority": "High",
        "estimate": 3
    },
    {
        "epic": "EPIC_C",
        "title": "Create Plan Change Request generator for throwing flags",
        "description": """Implement logic to auto-generate Plan Change Requests when throwing flags are triggered (velocity drops, command decline, pain spikes).

**Trigger Conditions:**
- Velocity drop >3 mph
- Command decline >20%
- Pain >5 during throwing
- Excessive pitch count

**Acceptance Criteria:**
- Auto-creates Linear issue in zone-4b
- Includes patient context
- Suggests specific interventions
- Requires PT approval

**Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md""",
        "zones": ["zone-3c", "zone-4b"],
        "priority": "High",
        "estimate": 4
    },

    # EPIC_D: Exercise Library
    {
        "epic": "EPIC_D",
        "title": "Seed exercise library in Supabase (50-100 items)",
        "description": """Create initial exercise library with at least 50-100 common exercises including all required metadata.

**Metadata Required:**
- category (strength, plyo, mobility, bullpen)
- body_region (shoulder, elbow, core, lower_body)
- movement_pattern (push, pull, hinge, squat, rotation)
- equipment (barbell, dumbbell, bodyweight, medicine ball)
- load_type (weight, time, distance, reps)

**Acceptance Criteria:**
- 50+ exercises seeded
- All metadata fields populated
- Includes Brebbia XLS exercises
- Clinical tags added where applicable

**Reference:** docs/epics/EPIC_D_EXERCISE_LIBRARY_METADATA.md""",
        "zones": ["zone-7", "zone-8"],
        "priority": "Medium",
        "estimate": 4
    },
    {
        "epic": "EPIC_D",
        "title": "Build search/filter API for therapists",
        "description": """Create API endpoints for therapists to search and filter exercises based on various metadata criteria.

**Endpoints:**
- GET /api/exercises/search?q=shoulder&category=strength
- GET /api/exercises/filter?body_region=shoulder&movement_pattern=push

**Acceptance Criteria:**
- Full-text search on exercise name
- Filter by any metadata field
- Paginated results
- Returns exercise templates with all metadata

**Reference:** docs/epics/EPIC_D_EXERCISE_LIBRARY_METADATA.md""",
        "zones": ["zone-3c", "zone-7"],
        "priority": "Medium",
        "estimate": 3
    },

    # EPIC_K: Data Quality & Testing
    {
        "epic": "EPIC_K",
        "title": "Add CHECK constraints for pain/RPE/velocity in schema",
        "description": """Add database CHECK constraints to ensure pain scores are 0-10, RPE is 0-10, and velocities are within realistic bounds.

**Constraints:**
- pain_score >= 0 AND pain_score <= 10
- rpe >= 0 AND rpe <= 10
- velocity >= 40 AND velocity <= 110 (for baseball)

**Acceptance Criteria:**
- Constraints added to all relevant tables
- Invalid data rejected by database
- Error messages clear for users

**Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md""",
        "zones": ["zone-7", "zone-10b"],
        "priority": "High",
        "estimate": 2
    },
    {
        "epic": "EPIC_K",
        "title": "Create vw_data_quality_issues view",
        "description": """Create database view to identify invalid records, summarize missing data, and report orphaned logs.

**View Should Identify:**
- Missing required fields
- Invalid foreign keys
- Orphaned exercise logs
- Out-of-range values
- Future dates

**Acceptance Criteria:**
- View executes without errors
- Returns actionable quality issues
- Documented in DATA_DICTIONARY.md

**Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md""",
        "zones": ["zone-7", "zone-10b"],
        "priority": "Medium",
        "estimate": 3
    },
    {
        "epic": "EPIC_K",
        "title": "Add unit tests for 1RM / strength target functions",
        "description": """Write unit tests for 1RM computation utilities and strength target calculation functions.

**Test Coverage:**
- Epley formula accuracy
- Brzycki formula accuracy
- Lombardi formula accuracy
- Strength/hypertrophy/endurance target calculations
- Edge cases (1 rep, 10+ reps)

**Acceptance Criteria:**
- 95%+ code coverage
- All tests pass
- CI/CD integration

**Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md""",
        "zones": ["zone-10b"],
        "priority": "High",
        "estimate": 3
    },
    {
        "epic": "EPIC_K",
        "title": "Add PT assistant behavior tests (prompt harness)",
        "description": """Create tests to verify PT Assistant never provides clinical diagnosis, always creates Plan Change Requests for structural changes, and respects pain/workload thresholds.

**Test Scenarios:**
- PT assistant never gives diagnosis
- Always creates PCR for structural changes
- Respects pain thresholds
- Respects workload limits

**Acceptance Criteria:**
- Automated test harness
- All safety checks validated
- Regression tests for agent behavior

**Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md""",
        "zones": ["zone-3c", "zone-10b"],
        "priority": "High",
        "estimate": 4
    },

    # EPIC_L: Monitoring & Logging
    {
        "epic": "EPIC_L",
        "title": "Implement agent_logs table + writing from backend",
        "description": """Create agent_logs table and implement logging from backend services.

**Schema:**
- timestamp
- endpoint
- patient_id
- linear_issue_id
- success (boolean)
- error (text)

**Acceptance Criteria:**
- Table created
- Backend writes logs on every action
- Indexed for performance

**Reference:** docs/epics/EPIC_L_MONITORING_AND_LOGGING.md""",
        "zones": ["zone-7", "zone-13"],
        "priority": "Medium",
        "estimate": 2
    },
    {
        "epic": "EPIC_L",
        "title": "Add logging to /patient-summary and /pt-assistant routes",
        "description": """Instrument patient-summary and pt-assistant endpoints with logging.

**Log Events:**
- Request received
- Patient data fetched
- Summary generated
- Response sent
- Errors encountered

**Acceptance Criteria:**
- All endpoints log appropriately
- Log levels correct (info, warn, error)
- Structured logging format (JSON)

**Reference:** docs/epics/EPIC_L_MONITORING_AND_LOGGING.md""",
        "zones": ["zone-3c", "zone-13"],
        "priority": "Medium",
        "estimate": 2
    },

    # EPIC_I: Patient App UX
    {
        "epic": "EPIC_I",
        "title": "Design Today Session view UX in SwiftUI",
        "description": """Create iPhone-optimized SwiftUI view showing today's program, phase, session, and Start Session button.

**UI Elements:**
- Session title
- Phase context
- Time estimate
- Exercise count
- Start Session button
- Rest day messaging

**Acceptance Criteria:**
- Clean, thumb-friendly design
- <1 second load time
- Handles empty state gracefully

**Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md""",
        "zones": ["zone-12"],
        "priority": "High",
        "estimate": 3
    },
    {
        "epic": "EPIC_I",
        "title": "Wire Today Session to Supabase today-session endpoint",
        "description": """Connect Today Session view to backend endpoint that determines current session.

**Integration:**
- Fetch from GET /api/today-session/:patientId
- Display exercises with targets
- Handle no session scheduled
- Error handling

**Acceptance Criteria:**
- Real data loads correctly
- No hardcoded placeholders
- Error states handled gracefully

**Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md""",
        "zones": ["zone-12", "zone-7"],
        "priority": "High",
        "estimate": 2
    },
    {
        "epic": "EPIC_I",
        "title": "Implement session logging UI and submission",
        "description": """Build session execution screen with exercise logging (reps, load, RPE, pain), session-level pain tracking, and submission logic.

**Features:**
- Per-exercise logging (sets, reps, load)
- RPE slider (0-10)
- Pain slider (0-10)
- Session notes
- Submit to Supabase

**Acceptance Criteria:**
- Logs saved to exercise_logs
- Pain saved to pain_logs
- Validation before submit
- Success confirmation

**Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md""",
        "zones": ["zone-12"],
        "priority": "High",
        "estimate": 5
    },
    {
        "epic": "EPIC_I",
        "title": "Implement basic pain/adherence charts in History tab",
        "description": """Create simple charts showing pain trends and adherence over last 4 weeks in patient app.

**Charts:**
- Pain trend line chart
- Adherence percentage bar
- Last 4 weeks data

**Acceptance Criteria:**
- Uses Swift Charts
- Data from vw_pain_trend
- Updates with new logs
- Color-coded by severity

**Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md""",
        "zones": ["zone-12", "zone-7"],
        "priority": "Medium",
        "estimate": 3
    },

    # EPIC_THERAPY_PROTOCOL_MANAGER
    {
        "epic": "EPIC_THERAPY_PROTOCOL_MANAGER",
        "title": "Build Protocol Schema (tables: protocol_templates, protocol_phases, protocol_constraints)",
        "description": """Create tables for protocol management and seed common protocols.

**Tables:**
- protocol_templates (id, name, description, injury_type)
- protocol_phases (id, protocol_id, phase_num, duration_weeks, constraints)
- protocol_constraints (id, protocol_id, rule_type, rule_config)

**Seed Protocols:**
- Tommy John (conservative & aggressive)
- Rotator cuff repair
- ACL reconstruction
- General return-to-sport

**Acceptance Criteria:**
- Tables created
- 4+ protocols seeded
- Constraints properly defined

**Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md""",
        "zones": ["zone-7", "zone-8"],
        "priority": "Medium",
        "estimate": 4
    },
    {
        "epic": "EPIC_THERAPY_PROTOCOL_MANAGER",
        "title": "Program Builder Integration (protocol selector, constraint enforcement)",
        "description": """Add protocol selector in program creation and ensure phase editor respects protocol constraints.

**Features:**
- Protocol dropdown in program builder
- Phase editor respects constraints
- Exercise picker filtered by protocol rules
- Visual indicators for allowed/forbidden exercises

**Acceptance Criteria:**
- PT can select protocol
- Constraints enforced in UI
- Clear visual feedback
- Can override with warning

**Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md""",
        "zones": ["zone-12"],
        "priority": "Medium",
        "estimate": 5
    },
    {
        "epic": "EPIC_THERAPY_PROTOCOL_MANAGER",
        "title": "PT Assistant Validation (check protocol before suggesting changes)",
        "description": """Before suggesting plan changes, check protocol. If change violates protocol, escalate to zone-4b.

**Logic:**
- Check proposed change against protocol rules
- If within protocol → suggest directly
- If violates protocol → escalate to zone-4b
- Include protocol rationale

**Acceptance Criteria:**
- Protocol validation integrated
- Escalation flow working
- Clear messaging to PT

**Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md""",
        "zones": ["zone-3c"],
        "priority": "Medium",
        "estimate": 3
    },
    {
        "epic": "EPIC_THERAPY_PROTOCOL_MANAGER",
        "title": "Linear Workflow (protocol override requests require higher approval)",
        "description": """Protocol override requests require higher approval level and special flagging.

**Implementation:**
- Flag 'protocol-deviation' label
- Higher approval required
- Include protocol rationale in issue
- Track overrides for audit

**Acceptance Criteria:**
- Protocol deviations clearly flagged
- Approval workflow enforced
- Audit trail maintained

**Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md""",
        "zones": ["zone-4b"],
        "priority": "Medium",
        "estimate": 2
    }
]


# ========== RUNBOOK IMPLEMENTATION TASKS ==========
RUNBOOK_TASKS = [
    # RUNBOOK_DATA_SUPABASE
    {
        "runbook": "RUNBOOK_DATA_SUPABASE",
        "title": "Validate and apply Supabase schema from SQL files",
        "description": """Load and validate schema from 001_init_supabase.sql and 002_epic_enhancements.sql.

**Steps:**
1. Load SQL files
2. Validate foreign keys, timestamps, CHECK constraints
3. Compare to XLS-derived model
4. Fix any gaps
5. Run supabase db push

**Acceptance Criteria:**
- Schema covers all XLS entities
- No missing tables or fields
- Foreign keys valid
- Constraints enforced

**Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md""",
        "zones": ["zone-7", "zone-8"],
        "priority": "High",
        "estimate": 3
    },
    {
        "runbook": "RUNBOOK_DATA_SUPABASE",
        "title": "Seed demo data (therapist, patient, program, sessions)",
        "description": """Insert seed data for demo/testing.

**Data to Seed:**
- 1 therapist (Sarah Thompson)
- 1 patient (John Brebbia)
- 1 active program (8-week on-ramp)
- 1 phase (week 1)
- 3 sessions
- 5-10 exercises per session
- Sample bullpen + plyo logs

**Acceptance Criteria:**
- All data inserted successfully
- Foreign keys valid
- Today-session API returns data
- Dashboard shows meaningful signals

**Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md""",
        "zones": ["zone-7", "zone-8"],
        "priority": "High",
        "estimate": 3
    },
    {
        "runbook": "RUNBOOK_DATA_SUPABASE",
        "title": "Create analytics views (vw_patient_adherence, vw_pain_trend, vw_throwing_workload)",
        "description": """Implement database views for analytics.

**Views:**
- vw_patient_adherence: completion percentage by patient
- vw_pain_trend: pain over time
- vw_throwing_workload: throwing volume and intensity

**Acceptance Criteria:**
- Views execute without errors
- Return correct data for seeded patient
- Performance <500ms
- Documented in DATA_DICTIONARY.md

**Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md""",
        "zones": ["zone-7", "zone-10b"],
        "priority": "High",
        "estimate": 4
    },
    {
        "runbook": "RUNBOOK_DATA_SUPABASE",
        "title": "Implement data quality tests and validation",
        "description": """Create SQL queries and unit tests for data quality.

**Tests:**
- Detect missing/invalid fields
- Validate foreign keys
- Unit tests for RM formulas
- Unit tests for pain interpretation

**Acceptance Criteria:**
- Data quality script runs clean on seeded data
- All unit tests pass
- Automated quality checks

**Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md""",
        "zones": ["zone-10b"],
        "priority": "Medium",
        "estimate": 3
    },

    # RUNBOOK_AGENT_BACKEND
    {
        "runbook": "RUNBOOK_AGENT_BACKEND",
        "title": "Create agent backend skeleton (Express + health endpoint)",
        "description": """Set up Node/Express backend with basic structure.

**Structure:**
- Express server on port 4000
- /health endpoint
- Environment config (.env)
- SUPABASE_URL, LINEAR_API_KEY
- README with setup instructions

**Acceptance Criteria:**
- Server starts without errors
- /health returns 200 OK
- Environment variables loaded
- Documented in README

**Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md""",
        "zones": ["zone-3c", "zone-12"],
        "priority": "High",
        "estimate": 2
    },
    {
        "runbook": "RUNBOOK_AGENT_BACKEND",
        "title": "Implement Supabase query endpoints (/patient-summary, /today-session)",
        "description": """Create backend endpoints for patient data.

**Endpoints:**
- GET /patient-summary/:id
  - Patient profile, recent logs, pain trend, bullpen metrics
- GET /today-session/:id
  - Exercises for today, phase/session metadata

**Acceptance Criteria:**
- Responses match seeded data
- Error handling for missing patients
- No 500-level errors
- Response time <1s

**Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md""",
        "zones": ["zone-3c", "zone-8"],
        "priority": "High",
        "estimate": 4
    },
    {
        "runbook": "RUNBOOK_AGENT_BACKEND",
        "title": "Implement PT Assistant summaries endpoint",
        "description": """Create endpoint for PT assistant text summaries.

**Endpoint:** GET /pt-assistant/summary/:id

**Summary Includes:**
- Pain trend summary
- Adherence summary
- Strength signals
- Velocity signals (if pitcher)

**Acceptance Criteria:**
- Text is accurate, concise, safe
- No medical diagnoses
- Matches clinical rules

**Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md""",
        "zones": ["zone-3c"],
        "priority": "High",
        "estimate": 4
    },
    {
        "runbook": "RUNBOOK_AGENT_BACKEND",
        "title": "Implement Plan Change Request creation endpoint",
        "description": """Create endpoint to generate Plan Change Requests.

**Endpoint:** POST /pt-assistant/plan-change-proposal/:id

**Logic:**
- Evaluate conditions (pain >5, velocity drop, poor adherence)
- Create Linear issue in zone-4b
- Set status to In Review
- Return issue ID + summary

**Acceptance Criteria:**
- Linear issue created successfully
- Includes patient context
- Requires PT approval
- Logged to agent_logs

**Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md""",
        "zones": ["zone-3c", "zone-4b"],
        "priority": "High",
        "estimate": 5
    },

    # RUNBOOK_MOBILE_SWIFTUI
    {
        "runbook": "RUNBOOK_MOBILE_SWIFTUI",
        "title": "Create Xcode project skeleton (PTPerformance app)",
        "description": """Initialize SwiftUI Xcode project.

**Configuration:**
- Universal app (iPhone + iPad)
- iOS 17 minimum
- SwiftUI lifecycle
- Bundle ID: com.ptperformance.app

**Acceptance Criteria:**
- App compiles
- Switches between patient/therapist modes
- Navigation scaffolding in place

**Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md""",
        "zones": ["zone-12"],
        "priority": "High",
        "estimate": 2
    },
    {
        "runbook": "RUNBOOK_MOBILE_SWIFTUI",
        "title": "Integrate Supabase Swift SDK and auth flow",
        "description": """Add Supabase SDK and implement authentication.

**Implementation:**
- Add supabase-swift via SPM
- Initialize Supabase client
- Login/logout flow
- Map user to patient/therapist
- Persist session

**Acceptance Criteria:**
- Demo users can sign in/out
- Session persists across launches
- Error handling for auth failures

**Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md""",
        "zones": ["zone-12", "zone-8"],
        "priority": "High",
        "estimate": 3
    },
    {
        "runbook": "RUNBOOK_MOBILE_SWIFTUI",
        "title": "Build Today Session screen with real data",
        "description": """Create Today Session view pulling from backend.

**Features:**
- Exercise list from /today-session/:id
- Session metadata (phase, name)
- Start Session button
- Loading states
- Error handling

**Acceptance Criteria:**
- Real data loads (no placeholders)
- <1 second load
- Handles rest days

**Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md""",
        "zones": ["zone-12", "zone-8"],
        "priority": "High",
        "estimate": 4
    },
    {
        "runbook": "RUNBOOK_MOBILE_SWIFTUI",
        "title": "Implement exercise logging UI with submission",
        "description": """Build session execution and logging.

**Features:**
- Log sets/reps/load per exercise
- RPE slider (0-10)
- Pain slider (0-10) per exercise
- Session notes input
- Submit to Supabase

**Acceptance Criteria:**
- Logs save to exercise_logs
- Pain logs save to pain_logs
- Validation before submit
- Success confirmation

**Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md""",
        "zones": ["zone-12", "zone-8"],
        "priority": "High",
        "estimate": 5
    },
    {
        "runbook": "RUNBOOK_MOBILE_SWIFTUI",
        "title": "Create History view with pain/adherence charts",
        "description": """Build patient history view with charts.

**Features:**
- Pain trend chart (Swift Charts)
- Adherence percentage
- Last 30 days data
- Pull from views

**Acceptance Criteria:**
- Charts display correctly
- Data matches database
- Color-coded by severity

**Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md""",
        "zones": ["zone-12", "zone-8"],
        "priority": "Medium",
        "estimate": 3
    },

    # RUNBOOK_THERAPIST_DASHBOARD
    {
        "runbook": "RUNBOOK_THERAPIST_DASHBOARD",
        "title": "Build therapist patient list view",
        "description": """Create patient list for therapist dashboard.

**Display Fields:**
- Patient name
- Adherence %
- Last session date
- Pain indicator (color-coded)
- Active flags

**Acceptance Criteria:**
- Query returns correct patients
- Color-coded pain/flags
- Tap to view detail
- iPad-optimized layout

**Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md""",
        "zones": ["zone-12", "zone-7"],
        "priority": "High",
        "estimate": 3
    },
    {
        "runbook": "RUNBOOK_THERAPIST_DASHBOARD",
        "title": "Create patient detail screen with charts and flags",
        "description": """Build comprehensive patient detail view.

**Sections:**
- Header (name, program, phase)
- Pain trend chart
- Velocity chart (if pitcher)
- Session history
- Active flags

**Acceptance Criteria:**
- All data loads correctly
- Charts render smoothly
- Flags clearly displayed
- No crashes

**Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md""",
        "zones": ["zone-12", "zone-3c", "zone-7"],
        "priority": "High",
        "estimate": 5
    },
    {
        "runbook": "RUNBOOK_THERAPIST_DASHBOARD",
        "title": "Implement program viewer (phases → sessions → exercises)",
        "description": """Create hierarchical program viewer.

**UI:**
- Accordion/disclosure groups
- Phase list with date ranges
- Sessions per phase
- Exercises per session
- Read-only for v1

**Acceptance Criteria:**
- Matches database state
- Clean navigation
- SwiftUI performance optimized

**Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md""",
        "zones": ["zone-12", "zone-8"],
        "priority": "High",
        "estimate": 4
    },
    {
        "runbook": "RUNBOOK_THERAPIST_DASHBOARD",
        "title": "Add patient notes and assessment interface",
        "description": """Implement therapist note-taking.

**Features:**
- Add therapist note
- View historical notes
- Tag notes to sessions
- Chronological display

**Acceptance Criteria:**
- Notes save to session_notes
- Display chronologically
- Session tagging works
- 2000 char limit enforced

**Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md""",
        "zones": ["zone-12", "zone-8"],
        "priority": "Medium",
        "estimate": 3
    },

    # RUNBOOK_FLAGS_RISK_ENGINE
    {
        "runbook": "RUNBOOK_FLAGS_RISK_ENGINE",
        "title": "Build flag computation logic (computeFlags function)",
        "description": """Implement risk flag engine.

**Flag Types:**
- Pain: >5 immediate, 3-5 for 2+ sessions
- Velocity: >3 mph drop
- Command: >20% decline
- Adherence: <60% over 7 days

**Returns:** `{flag_type, severity, rationale}`

**Acceptance Criteria:**
- Function handles missing data
- All flag types implemented
- Severity levels correct

**Reference:** docs/runbooks/RUNBOOK_FLAGS_RISK_ENGINE.md""",
        "zones": ["zone-7", "zone-10b", "zone-3c"],
        "priority": "High",
        "estimate": 4
    },
    {
        "runbook": "RUNBOOK_FLAGS_RISK_ENGINE",
        "title": "Attach flags to summary endpoints (/patient-summary, /pt-assistant/summary)",
        "description": """Integrate flags into API responses.

**Updates:**
- Modify /patient-summary to include flag count
- Include top 3 highest severity flags
- Match flag logic exactly

**Acceptance Criteria:**
- Summaries include flags
- Flag data accurate
- Performance not degraded

**Reference:** docs/runbooks/RUNBOOK_FLAGS_RISK_ENGINE.md""",
        "zones": ["zone-3c"],
        "priority": "High",
        "estimate": 2
    },
    {
        "runbook": "RUNBOOK_FLAGS_RISK_ENGINE",
        "title": "Auto-create Plan Change Requests for HIGH severity flags",
        "description": """Implement automatic PCR creation.

**Logic:**
- If severity = HIGH
- Create Linear issue in zone-4b
- Status: In Review
- Include: patient_id, trigger_metric, last sessions, rationale

**Acceptance Criteria:**
- PCR created automatically
- Visible in Linear
- Includes all required context

**Reference:** docs/runbooks/RUNBOOK_FLAGS_RISK_ENGINE.md""",
        "zones": ["zone-3c", "zone-4b"],
        "priority": "High",
        "estimate": 3
    },
]


async def get_priority_value(priority_str):
    """Convert priority string to Linear priority value."""
    priority_map = {
        "High": 1,
        "Medium": 2,
        "Low": 3,
        "Urgent": 0,
    }
    return priority_map.get(priority_str, 2)


async def main():
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ LINEAR_API_KEY environment variable not set")
        print("\nTo set it:")
        print("  export LINEAR_API_KEY='your-api-key-here'")
        print("\nGet your API key from: https://linear.app/settings/api")
        sys.exit(1)

    print("🚀 Populating Linear from Documentation")
    print("=" * 70)

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

        # Get zone labels
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
        data = await bootstrap.query(query, {"teamId": team["id"]})
        labels = data.get("team", {}).get("labels", {}).get("nodes", [])

        zone_labels = {}
        for label in labels:
            if label["name"].startswith("zone-"):
                zone_labels[label["name"]] = label["id"]
                print(f"  ✓ {label['name']}: {label['id']}")

        # Create issues
        all_tasks = EPIC_TASKS + RUNBOOK_TASKS
        print(f"\n🎯 Creating {len(all_tasks)} issues from epics and runbooks...\n")

        created_issues = []
        for idx, task_data in enumerate(all_tasks, 1):
            # Build label IDs list
            label_ids = []
            for zone in task_data["zones"]:
                if zone in zone_labels:
                    label_ids.append(zone_labels[zone])

            # Get priority value
            priority = await get_priority_value(task_data["priority"])

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
                "teamId": team["id"],
                "projectId": project["id"],
                "title": task_data["title"],
                "description": task_data["description"],
                "labelIds": label_ids,
                "priority": priority,
                "estimate": task_data.get("estimate", 2)
            }

            try:
                data = await bootstrap.query(mutation, variables)
                issue = data["issueCreate"]["issue"]
                created_issues.append(issue)

                source = task_data.get("epic", task_data.get("runbook", "Unknown"))
                zones_str = ", ".join(task_data["zones"])
                print(f"  [{idx}/{len(all_tasks)}] ✓ {issue['identifier']}: {issue['title'][:55]}...")
                print(f"           {source} | {zones_str} | {task_data['priority']}")

            except Exception as e:
                print(f"  ❌ Failed to create: {task_data['title']}")
                print(f"     Error: {str(e)}")

        # Summary
        print("\n" + "=" * 70)
        print("✅ Linear Population Complete!")
        print("=" * 70)
        print(f"\n📊 Summary:")
        print(f"  Total issues created: {len(created_issues)}")
        print(f"  Epic tasks: {len(EPIC_TASKS)}")
        print(f"  Runbook tasks: {len(RUNBOOK_TASKS)}")

        print(f"\n🔗 View in Linear:")
        print(f"  {project['url']}")

        print(f"\n📋 Next Steps:")
        print(f"  1. Review all issues in Linear")
        print(f"  2. Filter by zone to see workstreams")
        print(f"  3. Prioritize and assign")
        print(f"  4. Begin implementation!")


if __name__ == "__main__":
    asyncio.run(main())
