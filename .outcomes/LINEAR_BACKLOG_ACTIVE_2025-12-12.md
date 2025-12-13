# MVP 1 — PT App & Agent Pilot
**Team:** Agent-Control-Plane (ACP)
**Project URL:** https://linear.app/x2machines/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

**Progress:** 0.5%

## Issues (50 total)

### Done (50)
- **[ACP-103](https://linear.app/x2machines/issue/ACP-103/session-handoff-2025-12-06-foundation-complete-phase-1-ready)** 🎯 Session Handoff: 2025-12-06 - Foundation Complete, Phase 1 Ready `zone-13`
  # Session Handoff: 2025-12-06
  
  **Status:** Foundation Complete ✅ | Phase 1 Ready 🎯
  **Token Usage:** \~100K / 150K
  **Next Action:** Launch Phase 1 swarm (6-8 hours)
  
  ---
  
  ## 🎉 Session Achievements
  
  ### ✅ Completed This Session
  
  1. **Linear Population (45 Issues)**
     * 25 Epic tasks from all 15 epics
     * 20 Runbook implementation tasks
     * All zoned, prioritized, and ready for execution
     * [View Project](https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b)
  2. **Documentation Analysis**
     * Read all 15 epics → extracted 47 tasks
     * Read all 12 runbooks → extracted 82 steps
     * Categorized by zone and priority
  3. **Agent Backend Skeleton** ⚙️
     * Express server + health endpoint
     * Supabase integration ready
     * Environment configured
     * Location: `agent-service/`
  4. **Master Execution Plan** 📖
     * 6-phase structured plan
     * Swarm coordination strategy
     * Quality gates & testing
     * File: `MASTER_EXECUTION_PLAN.md`
  5. **Quick Start Guide** 🚀
     * Instant launch commands
     * Pre-flight checklist
     * File: `QUICK_START.md`
  
  ---
  
  ## 📊 Linear State
  
  ### Issues by Status
  
  * **Backlog:** 45 issues (ready to start)
  * **In Progress:** 0
  * **Done:** 0
  
  ### Issues by Zone
  
  * `zone-7` (Data Access): 15 issues
  * `zone-12` (UI/Mobile): 17 issues
  * `zone-10b` (Testing): 8 issues
  * `zone-3c` (Agents): 12 issues
  * `zone-4b` (Plan Changes): 5 issues
  * `zone-8` (Ingestion): 11 issues
  * `zone-13` (Monitoring): 3 issues
  
  ### Priority Distribution
  
  * **High:** 25 issues
  * **Medium:** 20 issues
  
  ---
  
  ## 🎯 IMMEDIATE NEXT STEPS
  
  ### Phase 1: Data Layer (START HERE)
  
  **Execute with 3-agent swarm:**
  
  #### Agent 1 - Schema & Tables (zone-7, zone-8)
  
  * ACP-83: Validate and apply Supabase schema
  * ACP-69: Add CHECK constraints for pain/RPE/velocity
  * ACP-79: Build protocol schema
  
  #### Agent 2 - Views & Analytics (zone-7, zone-10b)
  
  * ACP-85: Create analytics views (vw_patient_adherence, vw_pain_trend, vw_throwing_workload)
  * ACP-64: Implement throwing workload views
  * ACP-70: Create vw_data_quality_issues view
  
  #### Agent 3 - Seed & Test (zone-7, zone-8, zone-10b)
  
  * ACP-84: Seed demo data (therapist, patient, program, sessions)
  * ACP-67: Seed exercise library (50-100 exercises)
  * ACP-86: Implement data quality tests
  
  **Swarm Launch Command:**
  
  ```bash
  /swarm-it "Execute Phase 1: Data Layer - PT Performance Platform
  
  Context: Building PT performance platform MVP. Supabase data layer deployment.
  
  Use 3 agents in parallel working in separate zones:
  
  AGENT 1 - Schema & Tables (zone-7, zone-8):
  - ACP-83: Validate and apply Supabase schema from infra/*.sql files
  - ACP-69: Add CHECK constraints for pain/RPE/velocity
  - ACP-79: Build protocol schema (protocol_templates, protocol_phases, protocol_constraints)
  
  AGENT 2 - Views & Analytics (zone-7, zone-10b):
  - ACP-85: Create analytics views (vw_patient_adherence, vw_pain_trend, vw_throwing_workload)
  - ACP-64: Implement throwing workload views
  - ACP-70: Create vw_data_quality_issues view
  
  AGENT 3 - Seed & Test (zone-7, zone-8, zone-10b):
  - ACP-84: Seed demo data (therapist, patient, program, sessions)
  - ACP-67: Seed exercise library (50-100 exercises)
  - ACP-86: Implement data quality tests and validation
  
  Reference docs:
  - MASTER_EXECUTION_PLAN.md (Phase 1 section)
  - docs/runbooks/RUNBOOK_DATA_SUPABASE.md
  - infra/001_init_supabase.sql
  - infra/002_epic_enhancements.sql
  
  Success criteria:
  - All tables created in Supabase
  - Views execute without errors
  - Demo patient returns valid data
  - Data quality tests pass (0 issues)
  - 1RM calculations match XLS ±2%
  
  Coordination:
  - Update Linear issues with progress
  - Use Linear comments for communication
  - Create .outcomes/phase1_handoff.md when complete
  
  Target: 6-8 hours total execution time"
  ```
  
  ---
  
  ## 📚 Essential Documents
  
  ### Quick Reference (Read First)
  
  1. **QUICK_START.md** (5 min) - Instant launch guide
  2. **MASTER_EXECUTION_PLAN.md** (10 min) - Complete strategy
  3. **SESSION_HANDOFF_2025-12-06.md** (5 min) - Detailed state
  4. **.outcomes/** directory - Session artifacts
  
  ### Phase 1 References
  
  * `docs/runbooks/RUNBOOK_DATA_SUPABASE.md` - Implementation guide
  * `docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md` - 1RM formulas
  * `docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md` - Throwing model
  * `docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md` - Testing
  * `infra/001_init_supabase.sql` - Initial schema
  * `infra/002_epic_enhancements.sql` - Epic additions
  
  ---
  
  ## 🔧 Environment State
  
  ### Files Created This Session
  
  ```
  clients/linear-bootstrap/
  ├── .env                                    # Linear + Supabase keys ✅
  ├── MASTER_EXECUTION_PLAN.md               # Complete strategy ✅
  ├── QUICK_START.md                         # Launch guide ✅
  ├── populate_linear_from_docs.py           # Linear population ✅
  ├── agent-service/
  │   ├── .env                               # Backend config ✅
  │   ├── package.json                       # Dependencies ✅
  │   ├── src/server.js                      # Express server ✅
  │   └── README.md                          # Documentation ✅
  └── .outcomes/
      └── SESSION_HANDOFF_2025-12-06.md      # Detailed handoff ✅
  ```
  
  ### Git State
  
  * **Branch:** `restore-phase1-3-agents`
  * **Status:** Uncommitted changes (new files created)
  * **Recommendation:** Commit before starting Phase 1
  
  ### Supabase Configuration
  
  * **Schema Files:** `infra/001_init_supabase.sql`, `infra/002_epic_enhancements.sql`
  * **Project URL:** \[To be configured - create Supabase project\]
  * **Service Key:** Configured in `.env`
  * **Status:** Ready for deployment
  
  ### Agent Backend
  
  * **Location:** `agent-service/`
  * **Status:** Skeleton complete
  * **Next:** `npm install` → `npm run dev`
  * **Port:** 4000
  * **Health:** [http://localhost:4000/health](http://localhost:4000/health)
  
  ---
  
  ## 🔑 Critical Credentials
  
  ### Linear
  
  * **API Key:** `lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa`
  * **Team ID:** `5296cff8-9c53-4cb3-9df3-ccb83601805e`
  * **Team Key:** `ACP`
  * **Project URL:** [MVP 1 — PT App & Agent Pilot](https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b)
  
  ### Supabase
  
  * **Service Key:** `sb_secret_FYMKefuStzD82VUTplnsuw_GHN_0hb3`
  * **Project URL:** \[To be configured\]
  
  ### Configuration Files
  
  * `.env` (root): Linear + Supabase keys
  * `agent-service/.env`: Backend service config
  
  ---
  
  ## 🚧 Pre-Flight Checklist
  
  Before launching Phase 1:
  
  - [ ] **Supabase Project:** Create project OR configure existing URL
  - [ ] **Update .env:** Add SUPABASE_URL to both .env files
  - [ ] **Test Connection:** Verify Supabase connection works
  - [ ] **Review Plan:** Read Phase 1 section of MASTER_EXECUTION_PLAN.md
  - [ ] **Git Commit:** Commit current changes (optional but recommended)
  
  ---
  
  ## 📈 Phase Progress Tracker
  
  ### Phase 0: Foundation ✅ 100%
  
  - [X] Documentation analyzed
  - [X] Linear populated (45 issues)
  - [X] Agent backend skeleton
  - [X] Master plan created
  - [X] Environment configured
  
  ### Phase 1: Data Layer 🎯 0%
  
  - [ ] Schema deployed to Supabase
  - [ ] Analytics views created
  - [ ] Demo data seeded
  - [ ] Data quality tests passing
  
  ### Phase 2: Backend Intelligence ⏸️ 0%
  
  - [ ] PT Assistant endpoints
  - [ ] Flag computation engine
  - [ ] Plan Change Request automation
  
  ### Phase 3: Mobile App ⏸️ 0%
  
  - [ ] SwiftUI patient flow
  - [ ] SwiftUI therapist dashboard
  
  ### Phase 4: Integration & Testing ⏸️ 0%
  
  - [ ] Clinical validation
  - [ ] Performance testing
  
  ### Phase 5: Deployment ⏸️ 0%
  
  - [ ] Production deployment
  
  **Overall Progress:** 16.7% (1/6 phases complete)
  
  ---
  
  ## 💡 Important Context for Next Agent
  
  ### Project Overview
  
  * **What:** PT (physical therapy) performance platform
  * **Who:** For MLB pitcher John Brebbia (post-tricep strain)
  * **Core Flow:** Patient logs sessions → PT reviews → AI flags risks → Plan changes approved via Linear
  * **Clinical Safety:** No diagnoses, PT approval required for all plan changes
  
  ### Technical Stack
  
  * **Backend:** Node.js + Express + Supabase
  * **Mobile:** SwiftUI (iOS 17+, iPhone + iPad)
  * **Database:** PostgreSQL via Supabase
  * **Auth:** Supabase Auth (email/password)
  * **Workflow:** Linear (zone-based issue management)
  
  ### Key Architectural Concepts
  
  * **Zones:** Work isolation (zone-7 = data, zone-12 = UI, zone-3c = agents, etc.)
  * **Swarms:** Multiple agents working in parallel on different zones
  * **Quality Gates:** Each phase must pass validation before proceeding
  * **Clinical Rules:** Pain >5 flags, velocity drops alert, no auto-intensity increases
  
  ### Design Decisions Made
  
  1. **3 agents per phase** for parallel execution
  2. **Zone isolation** to avoid conflicts
  3. **Linear-based coordination** via issue comments
  4. **Handoff documents** at end of each phase
  
  ---
  
  ## 🧪 Phase 1 Validation (Run After Completion)
  
  ### SQL Tests
  
  ```sql
  -- Test 1: Verify all tables exist
  SELECT table_name FROM information_schema.tables
  WHERE table_schema = 'public'
  ORDER BY table_name;
  
  -- Test 2: Verify views work
  SELECT * FROM vw_patient_adherence LIMIT 5;
  SELECT * FROM vw_pain_trend LIMIT 5;
  SELECT * FROM vw_throwing_workload LIMIT 5;
  
  -- Test 3: Verify demo patient exists
  SELECT * FROM patients
  WHERE first_name = 'John' AND last_name = 'Brebbia';
  
  -- Test 4: Verify data quality (should return 0 rows)
  SELECT * FROM vw_data_quality_issues;
  
  -- Test 5: Verify 1RM calculations
  SELECT exercise_template_id,
         actual_load,
         actual_reps,
         rm_estimate
  FROM exercise_logs
  WHERE rm_estimate IS NOT NULL
  LIMIT 10;
  ```
  
  ### Success Criteria
  
  * ✅ All tables created (20+ tables)
  * ✅ All views execute without errors
  * ✅ Demo patient returns valid data
  * ✅ Data quality: 0 issues
  * ✅ 1RM calculations match XLS ±2%
  * ✅ Exercise library: 50+ exercises
  * ✅ Demo program: 3+ sessions seeded
  
  ---
  
  ## 🚀 Commands You'll Need
  
  ### Start Agent Backend
  
  ```bash
  cd agent-service
  npm install
  npm run dev
  # Server starts on http://localhost:4000
  ```
  
  ### Apply Supabase Schema
  
  ```bash
  # Option 1: Supabase CLI
  supabase db push
  
  # Option 2: Direct psql
  psql -h db.PROJECT.supabase.co -U postgres -d postgres -f infra/001_init_supabase.sql
  psql -h db.PROJECT.supabase.co -U postgres -d postgres -f infra/002_epic_enhancements.sql
  ```
  
  ### Test Backend Endpoints
  
  ```bash
  # Health check
  curl http://localhost:4000/health
  
  # Patient summary (after Phase 1 + 2)
  curl http://localhost:4000/api/patient-summary/PATIENT_ID
  ```
  
  ### View Linear Issues by Zone
  
  ```
  # Phase 1 work
  zone-7 OR zone-8 OR zone-10b
  
  # Backend work (Phase 2)
  zone-3c OR zone-4b
  
  # Mobile work (Phase 3)
  zone-12
  ```
  
  ---
  
  ## 📝 Agent Coordination Protocol
  
  ### Starting Work
  
  Post to Linear issue:
  
  ```
  🤖 Agent starting work on ACP-XX
  Zone: zone-7
  Estimated completion: 2 hours
  Dependencies: None
  ```
  
  ### Progress Updates (every 30 min)
  
  ```
  ⏳ In progress - Step 2/4 complete
  Current: Creating vw_patient_adherence view
  Blockers: None
  Next: Create vw_pain_trend view
  ```
  
  ### Completion
  
  ```
  ✅ Work complete on ACP-XX
  
  Deliverables:
  - View created: vw_patient_adherence
  - Query tested: Returns correct data for demo patient
  - Screenshot: [link to Supabase dashboard]
  - Code: [commit hash if applicable]
  
  Moving to In Review
  ```
  
  ---
  
  ## 🎯 Phase 1 Success Indicators
  
  When Phase 1 is complete, you should have:
  
  - [ ] All Phase 1 Linear issues (13 issues) marked "Done"
  - [ ] Supabase dashboard showing all tables + views
  - [ ] Demo patient query returns realistic data
  - [ ] All views execute in <500ms
  - [ ] Data quality view returns 0 issues
  - [ ] `.outcomes/phase1_handoff.md` document created
  - [ ] Ready to start Phase 2
  
  ---
  
  ## 🔄 How to Update This Handoff
  
  ### After Phase 1 Completion
  
  Create a new handoff issue:
  
  ```bash
  python3 create_handoff_issue.py --phase 1
  ```
  
  Or manually create issue with title:
  
  ```
  🎯 Session Handoff: [DATE] - Phase 1 Complete, Phase 2 Ready
  ```
  
  ### Include in New Handoff
  
  1. Phase 1 completion summary
  2. Deliverables created
  3. Test results
  4. Phase 2 launch command
  5. Updated progress metrics
  6. Any blockers or issues encountered
  
  ---
  
  ## 🆘 Troubleshooting
  
  ### Supabase Connection Fails
  
  ```bash
  # Verify environment variables
  cat .env | grep SUPABASE
  cat agent-service/.env | grep SUPABASE
  
  # Test connection
  psql -h YOUR_PROJECT.supabase.co -U postgres -d postgres -c "SELECT version();"
  ```
  
  ### Linear API Fails
  
  ```bash
  # Verify API key
  cat .env | grep LINEAR
  
  # Test connection
  python3 -c "
  import os
  from linear_bootstrap import LinearBootstrap
  import asyncio
  
  async def test():
      async with LinearBootstrap(os.getenv('LINEAR_API_KEY')) as lb:
          team = await lb.get_or_create_team('Agent-Control-Plane')
          print('✓ Connected:', team['name'])
  
  asyncio.run(test())
  "
  ```
  
  ### Agent Conflicts
  
  1. Check Linear issue comments for agent activity
  2. Lower-numbered issue (ACP-XX) takes priority
  3. Other agent pauses with comment: "⏸️ Pausing due to conflict with ACP-XX"
  4. Reassign or coordinate via Linear
  
  ---
  
  ## 📖 Reading Order for Next Session
  
  1. **This Issue** (3 min) - Current state and next steps
  2. **QUICK_START.md** (5 min) - Launch procedures
  3. **MASTER_EXECUTION_PLAN.md** Phase 1 (10 min) - Detailed phase guide
  4. **Launch Phase 1 swarm** - Execute!
  
  ---
  
  ## ✅ Session Completion Checklist
  
  - [X] All epics analyzed (15/15)
  - [X] All runbooks analyzed (12/12)
  - [X] Linear populated (45 issues)
  - [X] Agent backend skeleton created
  - [X] Master execution plan written
  - [X] Quick start guide written
  - [X] Environment configured
  - [X] Session handoff created
  - [X] **Handoff issue created in Linear** ← YOU ARE HERE
  
  ---
  
  ## 🎬 READY TO LAUNCH
  
  **Next Action:** Copy the swarm launch command above and execute
  
  **Estimated Time:** 6-8 hours (Phase 1)
  
  **Success Guaranteed:** Quality gates ensure production-ready output
  
  ---
  
  **Status:** ✅ FOUNDATION COMPLETE | 🎯 PHASE 1 READY
  
  *Last Updated: 2025-12-06*
  *Session: Foundation & Planning*
  *Next: Phase 1 Data Layer Execution*
  💬 1 comment(s)
- **[ACP-102](https://linear.app/x2machines/issue/ACP-102/auto-create-plan-change-requests-for-high-severity-flags)** Auto-create Plan Change Requests for HIGH severity flags `zone-3c, zone-4b`
  Implement automatic PCR creation.
  
  **Logic:**
  
  * If severity = HIGH
  * Create Linear issue in zone-4b
  * Status: In Review
  * Include: patient_id, trigger_metric, last sessions, rationale
  
  **Acceptance Criteria:**
  
  * PCR created automatically
  * Visible in Linear
  * Includes all required context
  
  **Reference:** docs/runbooks/RUNBOOK_FLAGS_RISK_ENGINE.md
  💬 1 comment(s)
- **[ACP-101](https://linear.app/x2machines/issue/ACP-101/attach-flags-to-summary-endpoints-patient-summary-pt-assistantsummary)** Attach flags to summary endpoints (/patient-summary, /pt-assistant/summary) `zone-3c`
  Integrate flags into API responses.
  
  **Updates:**
  
  * Modify /patient-summary to include flag count
  * Include top 3 highest severity flags
  * Match flag logic exactly
  
  **Acceptance Criteria:**
  
  * Summaries include flags
  * Flag data accurate
  * Performance not degraded
  
  **Reference:** docs/runbooks/RUNBOOK_FLAGS_RISK_ENGINE.md
  💬 1 comment(s)
- **[ACP-100](https://linear.app/x2machines/issue/ACP-100/build-flag-computation-logic-computeflags-function)** Build flag computation logic (computeFlags function) `zone-7, zone-10b, zone-3c`
  Implement risk flag engine.
  
  **Flag Types:**
  
  * Pain: >5 immediate, 3-5 for 2+ sessions
  * Velocity: >3 mph drop
  * Command: >20% decline
  * Adherence: <60% over 7 days
  
  **Returns:** `{flag_type, severity, rationale}`
  
  **Acceptance Criteria:**
  
  * Function handles missing data
  * All flag types implemented
  * Severity levels correct
  
  **Reference:** docs/runbooks/RUNBOOK_FLAGS_RISK_ENGINE.md
  💬 1 comment(s)
- **[ACP-99](https://linear.app/x2machines/issue/ACP-99/add-patient-notes-and-assessment-interface)** Add patient notes and assessment interface `zone-12, zone-8`
  Implement therapist note-taking.
  
  **Features:**
  
  * Add therapist note
  * View historical notes
  * Tag notes to sessions
  * Chronological display
  
  **Acceptance Criteria:**
  
  * Notes save to session_notes
  * Display chronologically
  * Session tagging works
  * 2000 char limit enforced
  
  **Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md
  💬 4 comment(s)
- **[ACP-98](https://linear.app/x2machines/issue/ACP-98/implement-program-viewer-phases-→-sessions-→-exercises)** Implement program viewer (phases → sessions → exercises) `zone-12, zone-8`
  Create hierarchical program viewer.
  
  **UI:**
  
  * Accordion/disclosure groups
  * Phase list with date ranges
  * Sessions per phase
  * Exercises per session
  * Read-only for v1
  
  **Acceptance Criteria:**
  
  * Matches database state
  * Clean navigation
  * SwiftUI performance optimized
  
  **Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md
  💬 4 comment(s)
- **[ACP-97](https://linear.app/x2machines/issue/ACP-97/create-patient-detail-screen-with-charts-and-flags)** Create patient detail screen with charts and flags `zone-12, zone-3c, zone-7`
  Build comprehensive patient detail view.
  
  **Sections:**
  
  * Header (name, program, phase)
  * Pain trend chart
  * Velocity chart (if pitcher)
  * Session history
  * Active flags
  
  **Acceptance Criteria:**
  
  * All data loads correctly
  * Charts render smoothly
  * Flags clearly displayed
  * No crashes
  
  **Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md
  💬 4 comment(s)
- **[ACP-96](https://linear.app/x2machines/issue/ACP-96/build-therapist-patient-list-view)** Build therapist patient list view `zone-12, zone-7`
  Create patient list for therapist dashboard.
  
  **Display Fields:**
  
  * Patient name
  * Adherence %
  * Last session date
  * Pain indicator (color-coded)
  * Active flags
  
  **Acceptance Criteria:**
  
  * Query returns correct patients
  * Color-coded pain/flags
  * Tap to view detail
  * iPad-optimized layout
  
  **Reference:** docs/runbooks/RUNBOOK_THERAPIST_DASHBOARD.md
  💬 4 comment(s)
- **[ACP-95](https://linear.app/x2machines/issue/ACP-95/create-history-view-with-painadherence-charts)** Create History view with pain/adherence charts `zone-12, zone-8`
  Build patient history view with charts.
  
  **Features:**
  
  * Pain trend chart (Swift Charts)
  * Adherence percentage
  * Last 30 days data
  * Pull from views
  
  **Acceptance Criteria:**
  
  * Charts display correctly
  * Data matches database
  * Color-coded by severity
  
  **Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md
  💬 4 comment(s)
- **[ACP-94](https://linear.app/x2machines/issue/ACP-94/implement-exercise-logging-ui-with-submission)** Implement exercise logging UI with submission `zone-12, zone-8`
  Build session execution and logging.
  
  **Features:**
  
  * Log sets/reps/load per exercise
  * RPE slider (0-10)
  * Pain slider (0-10) per exercise
  * Session notes input
  * Submit to Supabase
  
  **Acceptance Criteria:**
  
  * Logs save to exercise_logs
  * Pain logs save to pain_logs
  * Validation before submit
  * Success confirmation
  
  **Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md
  💬 4 comment(s)
- **[ACP-93](https://linear.app/x2machines/issue/ACP-93/build-today-session-screen-with-real-data)** Build Today Session screen with real data `zone-12, zone-8`
  Create Today Session view pulling from backend.
  
  **Features:**
  
  * Exercise list from /today-session/:id
  * Session metadata (phase, name)
  * Start Session button
  * Loading states
  * Error handling
  
  **Acceptance Criteria:**
  
  * Real data loads (no placeholders)
  * <1 second load
  * Handles rest days
  
  **Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md
  💬 3 comment(s)
- **[ACP-92](https://linear.app/x2machines/issue/ACP-92/integrate-supabase-swift-sdk-and-auth-flow)** Integrate Supabase Swift SDK and auth flow `zone-12, zone-8`
  Add Supabase SDK and implement authentication.
  
  **Implementation:**
  
  * Add supabase-swift via SPM
  * Initialize Supabase client
  * Login/logout flow
  * Map user to patient/therapist
  * Persist session
  
  **Acceptance Criteria:**
  
  * Demo users can sign in/out
  * Session persists across launches
  * Error handling for auth failures
  
  **Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md
  💬 3 comment(s)
- **[ACP-91](https://linear.app/x2machines/issue/ACP-91/create-xcode-project-skeleton-ptperformance-app)** Create Xcode project skeleton (PTPerformance app) `zone-12`
  Initialize SwiftUI Xcode project.
  
  **Configuration:**
  
  * Universal app (iPhone + iPad)
  * iOS 17 minimum
  * SwiftUI lifecycle
  * Bundle ID: com.ptperformance.app
  
  **Acceptance Criteria:**
  
  * App compiles
  * Switches between patient/therapist modes
  * Navigation scaffolding in place
  
  **Reference:** docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md
  💬 1 comment(s)
- **[ACP-90](https://linear.app/x2machines/issue/ACP-90/implement-plan-change-request-creation-endpoint)** Implement Plan Change Request creation endpoint `zone-3c, zone-4b`
  Create endpoint to generate Plan Change Requests.
  
  **Endpoint:** POST /pt-assistant/plan-change-proposal/:id
  
  **Logic:**
  
  * Evaluate conditions (pain >5, velocity drop, poor adherence)
  * Create Linear issue in zone-4b
  * Set status to In Review
  * Return issue ID + summary
  
  **Acceptance Criteria:**
  
  * Linear issue created successfully
  * Includes patient context
  * Requires PT approval
  * Logged to agent_logs
  
  **Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md
  💬 1 comment(s)
- **[ACP-89](https://linear.app/x2machines/issue/ACP-89/implement-pt-assistant-summaries-endpoint)** Implement PT Assistant summaries endpoint `zone-3c`
  Create endpoint for PT assistant text summaries.
  
  **Endpoint:** GET /pt-assistant/summary/:id
  
  **Summary Includes:**
  
  * Pain trend summary
  * Adherence summary
  * Strength signals
  * Velocity signals (if pitcher)
  
  **Acceptance Criteria:**
  
  * Text is accurate, concise, safe
  * No medical diagnoses
  * Matches clinical rules
  
  **Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md
  💬 1 comment(s)
- **[ACP-88](https://linear.app/x2machines/issue/ACP-88/implement-supabase-query-endpoints-patient-summary-today-session)** Implement Supabase query endpoints (/patient-summary, /today-session) `zone-3c, zone-8`
  Create backend endpoints for patient data.
  
  **Endpoints:**
  
  * GET /patient-summary/:id
    * Patient profile, recent logs, pain trend, bullpen metrics
  * GET /today-session/:id
    * Exercises for today, phase/session metadata
  
  **Acceptance Criteria:**
  
  * Responses match seeded data
  * Error handling for missing patients
  * No 500-level errors
  * Response time <1s
  
  **Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md
  💬 1 comment(s)
- **[ACP-87](https://linear.app/x2machines/issue/ACP-87/create-agent-backend-skeleton-express-health-endpoint)** Create agent backend skeleton (Express + health endpoint) `zone-3c, zone-12`
  Set up Node/Express backend with basic structure.
  
  **Structure:**
  
  * Express server on port 4000
  * /health endpoint
  * Environment config (.env)
  * SUPABASE_URL, LINEAR_API_KEY
  * README with setup instructions
  
  **Acceptance Criteria:**
  
  * Server starts without errors
  * /health returns 200 OK
  * Environment variables loaded
  * Documented in README
  
  **Reference:** docs/runbooks/RUNBOOK_AGENT_BACKEND.md
  💬 1 comment(s)
- **[ACP-86](https://linear.app/x2machines/issue/ACP-86/implement-data-quality-tests-and-validation)** Implement data quality tests and validation `zone-10b`
  Create SQL queries and unit tests for data quality.
  
  **Tests:**
  
  * Detect missing/invalid fields
  * Validate foreign keys
  * Unit tests for RM formulas
  * Unit tests for pain interpretation
  
  **Acceptance Criteria:**
  
  * Data quality script runs clean on seeded data
  * All unit tests pass
  * Automated quality checks
  
  **Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md
  💬 2 comment(s)
- **[ACP-85](https://linear.app/x2machines/issue/ACP-85/create-analytics-views-vw-patient-adherence-vw-pain-trend-vw-throwing)** Create analytics views (vw_patient_adherence, vw_pain_trend, vw_throwing_workload) `zone-7, zone-10b`
  Implement database views for analytics.
  
  **Views:**
  
  * vw_patient_adherence: completion percentage by patient
  * vw_pain_trend: pain over time
  * vw_throwing_workload: throwing volume and intensity
  
  **Acceptance Criteria:**
  
  * Views execute without errors
  * Return correct data for seeded patient
  * Performance <500ms
  * Documented in DATA_DICTIONARY.md
  
  **Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md
  💬 2 comment(s)
- **[ACP-84](https://linear.app/x2machines/issue/ACP-84/seed-demo-data-therapist-patient-program-sessions)** Seed demo data (therapist, patient, program, sessions) `zone-7, zone-8`
  Insert seed data for demo/testing.
  
  **Data to Seed:**
  
  * 1 therapist (Sarah Thompson)
  * 1 patient (John Brebbia)
  * 1 active program (8-week on-ramp)
  * 1 phase (week 1)
  * 3 sessions
  * 5-10 exercises per session
  * Sample bullpen + plyo logs
  
  **Acceptance Criteria:**
  
  * All data inserted successfully
  * Foreign keys valid
  * Today-session API returns data
  * Dashboard shows meaningful signals
  
  **Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md
  💬 2 comment(s)
- **[ACP-83](https://linear.app/x2machines/issue/ACP-83/validate-and-apply-supabase-schema-from-sql-files)** Validate and apply Supabase schema from SQL files `zone-7, zone-8`
  Load and validate schema from 001_init_supabase.sql and 002_epic_enhancements.sql.
  
  **Steps:**
  
  1. Load SQL files
  2. Validate foreign keys, timestamps, CHECK constraints
  3. Compare to XLS-derived model
  4. Fix any gaps
  5. Run supabase db push
  
  **Acceptance Criteria:**
  
  * Schema covers all XLS entities
  * No missing tables or fields
  * Foreign keys valid
  * Constraints enforced
  
  **Reference:** docs/runbooks/RUNBOOK_DATA_SUPABASE.md
  💬 2 comment(s)
- **[ACP-82](https://linear.app/x2machines/issue/ACP-82/linear-workflow-protocol-override-requests-require-higher-approval)** Linear Workflow (protocol override requests require higher approval) `zone-4b`
  Protocol override requests require higher approval level and special flagging.
  
  **Implementation:**
  
  * Flag 'protocol-deviation' label
  * Higher approval required
  * Include protocol rationale in issue
  * Track overrides for audit
  
  **Acceptance Criteria:**
  
  * Protocol deviations clearly flagged
  * Approval workflow enforced
  * Audit trail maintained
  
  **Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md
  💬 1 comment(s)
- **[ACP-81](https://linear.app/x2machines/issue/ACP-81/pt-assistant-validation-check-protocol-before-suggesting-changes)** PT Assistant Validation (check protocol before suggesting changes) `zone-3c`
  Before suggesting plan changes, check protocol. If change violates protocol, escalate to zone-4b.
  
  **Logic:**
  
  * Check proposed change against protocol rules
  * If within protocol → suggest directly
  * If violates protocol → escalate to zone-4b
  * Include protocol rationale
  
  **Acceptance Criteria:**
  
  * Protocol validation integrated
  * Escalation flow working
  * Clear messaging to PT
  
  **Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md
  💬 1 comment(s)
- **[ACP-80](https://linear.app/x2machines/issue/ACP-80/program-builder-integration-protocol-selector-constraint-enforcement)** Program Builder Integration (protocol selector, constraint enforcement) `zone-12`
  Add protocol selector in program creation and ensure phase editor respects protocol constraints.
  
  **Features:**
  
  * Protocol dropdown in program builder
  * Phase editor respects constraints
  * Exercise picker filtered by protocol rules
  * Visual indicators for allowed/forbidden exercises
  
  **Acceptance Criteria:**
  
  * PT can select protocol
  * Constraints enforced in UI
  * Clear visual feedback
  * Can override with warning
  
  **Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md
  💬 1 comment(s)
- **[ACP-79](https://linear.app/x2machines/issue/ACP-79/build-protocol-schema-tables-protocol-templates-protocol-phases)** Build Protocol Schema (tables: protocol_templates, protocol_phases, protocol_constraints) `zone-7, zone-8`
  Create tables for protocol management and seed common protocols.
  
  **Tables:**
  
  * protocol_templates (id, name, description, injury_type)
  * protocol_phases (id, protocol_id, phase_num, duration_weeks, constraints)
  * protocol_constraints (id, protocol_id, rule_type, rule_config)
  
  **Seed Protocols:**
  
  * Tommy John (conservative & aggressive)
  * Rotator cuff repair
  * ACL reconstruction
  * General return-to-sport
  
  **Acceptance Criteria:**
  
  * Tables created
  * 4+ protocols seeded
  * Constraints properly defined
  
  **Reference:** docs/epics/EPIC_THERAPY_PROTOCOL_MANAGER.md
  💬 2 comment(s)
- **[ACP-78](https://linear.app/x2machines/issue/ACP-78/implement-basic-painadherence-charts-in-history-tab)** Implement basic pain/adherence charts in History tab `zone-12, zone-7`
  Create simple charts showing pain trends and adherence over last 4 weeks in patient app.
  
  **Charts:**
  
  * Pain trend line chart
  * Adherence percentage bar
  * Last 4 weeks data
  
  **Acceptance Criteria:**
  
  * Uses Swift Charts
  * Data from vw_pain_trend
  * Updates with new logs
  * Color-coded by severity
  
  **Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md
  💬 4 comment(s)
- **[ACP-77](https://linear.app/x2machines/issue/ACP-77/implement-session-logging-ui-and-submission)** Implement session logging UI and submission `zone-12`
  Build session execution screen with exercise logging (reps, load, RPE, pain), session-level pain tracking, and submission logic.
  
  **Features:**
  
  * Per-exercise logging (sets, reps, load)
  * RPE slider (0-10)
  * Pain slider (0-10)
  * Session notes
  * Submit to Supabase
  
  **Acceptance Criteria:**
  
  * Logs saved to exercise_logs
  * Pain saved to pain_logs
  * Validation before submit
  * Success confirmation
  
  **Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md
  💬 1 comment(s)
- **[ACP-76](https://linear.app/x2machines/issue/ACP-76/wire-today-session-to-supabase-today-session-endpoint)** Wire Today Session to Supabase today-session endpoint `zone-12, zone-7`
  Connect Today Session view to backend endpoint that determines current session.
  
  **Integration:**
  
  * Fetch from GET /api/today-session/:patientId
  * Display exercises with targets
  * Handle no session scheduled
  * Error handling
  
  **Acceptance Criteria:**
  
  * Real data loads correctly
  * No hardcoded placeholders
  * Error states handled gracefully
  
  **Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md
  💬 4 comment(s)
- **[ACP-75](https://linear.app/x2machines/issue/ACP-75/design-today-session-view-ux-in-swiftui)** Design Today Session view UX in SwiftUI `zone-12`
  Create iPhone-optimized SwiftUI view showing today's program, phase, session, and Start Session button.
  
  **UI Elements:**
  
  * Session title
  * Phase context
  * Time estimate
  * Exercise count
  * Start Session button
  * Rest day messaging
  
  **Acceptance Criteria:**
  
  * Clean, thumb-friendly design
  * <1 second load time
  * Handles empty state gracefully
  
  **Reference:** docs/epics/EPIC_I_PATIENT_APP_UX_AND_FLOWS.md
  💬 1 comment(s)
- **[ACP-74](https://linear.app/x2machines/issue/ACP-74/add-logging-to-patient-summary-and-pt-assistant-routes)** Add logging to /patient-summary and /pt-assistant routes `zone-3c, zone-13`
  Instrument patient-summary and pt-assistant endpoints with logging.
  
  **Log Events:**
  
  * Request received
  * Patient data fetched
  * Summary generated
  * Response sent
  * Errors encountered
  
  **Acceptance Criteria:**
  
  * All endpoints log appropriately
  * Log levels correct (info, warn, error)
  * Structured logging format (JSON)
  
  **Reference:** docs/epics/EPIC_L_MONITORING_AND_LOGGING.md
  💬 1 comment(s)
- **[ACP-73](https://linear.app/x2machines/issue/ACP-73/implement-agent-logs-table-writing-from-backend)** Implement agent_logs table + writing from backend `zone-7, zone-13`
  Create agent_logs table and implement logging from backend services.
  
  **Schema:**
  
  * timestamp
  * endpoint
  * patient_id
  * linear_issue_id
  * success (boolean)
  * error (text)
  
  **Acceptance Criteria:**
  
  * Table created
  * Backend writes logs on every action
  * Indexed for performance
  
  **Reference:** docs/epics/EPIC_L_MONITORING_AND_LOGGING.md
  💬 5 comment(s)
- **[ACP-72](https://linear.app/x2machines/issue/ACP-72/add-pt-assistant-behavior-tests-prompt-harness)** Add PT assistant behavior tests (prompt harness) `zone-3c, zone-10b`
  Create tests to verify PT Assistant never provides clinical diagnosis, always creates Plan Change Requests for structural changes, and respects pain/workload thresholds.
  
  **Test Scenarios:**
  
  * PT assistant never gives diagnosis
  * Always creates PCR for structural changes
  * Respects pain thresholds
  * Respects workload limits
  
  **Acceptance Criteria:**
  
  * Automated test harness
  * All safety checks validated
  * Regression tests for agent behavior
  
  **Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md
  💬 1 comment(s)
- **[ACP-71](https://linear.app/x2machines/issue/ACP-71/add-unit-tests-for-1rm-strength-target-functions)** Add unit tests for 1RM / strength target functions `zone-10b`
  Write unit tests for 1RM computation utilities and strength target calculation functions.
  
  **Test Coverage:**
  
  * Epley formula accuracy
  * Brzycki formula accuracy
  * Lombardi formula accuracy
  * Strength/hypertrophy/endurance target calculations
  * Edge cases (1 rep, 10+ reps)
  
  **Acceptance Criteria:**
  
  * 95%+ code coverage
  * All tests pass
  * CI/CD integration
  
  **Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md
  💬 4 comment(s)
- **[ACP-70](https://linear.app/x2machines/issue/ACP-70/create-vw-data-quality-issues-view)** Create vw_data_quality_issues view `zone-7, zone-10b`
  Create database view to identify invalid records, summarize missing data, and report orphaned logs.
  
  **View Should Identify:**
  
  * Missing required fields
  * Invalid foreign keys
  * Orphaned exercise logs
  * Out-of-range values
  * Future dates
  
  **Acceptance Criteria:**
  
  * View executes without errors
  * Returns actionable quality issues
  * Documented in DATA_DICTIONARY.md
  
  **Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md
  💬 2 comment(s)
- **[ACP-69](https://linear.app/x2machines/issue/ACP-69/add-check-constraints-for-painrpevelocity-in-schema)** Add CHECK constraints for pain/RPE/velocity in schema `zone-7, zone-10b`
  Add database CHECK constraints to ensure pain scores are 0-10, RPE is 0-10, and velocities are within realistic bounds.
  
  **Constraints:**
  
  * pain_score >= 0 AND pain_score <= 10
  * rpe >= 0 AND rpe <= 10
  * velocity >= 40 AND velocity <= 110 (for baseball)
  
  **Acceptance Criteria:**
  
  * Constraints added to all relevant tables
  * Invalid data rejected by database
  * Error messages clear for users
  
  **Reference:** docs/epics/EPIC_K_DATA_QUALITY_AND_TESTING_STRATEGY.md
  💬 2 comment(s)
- **[ACP-68](https://linear.app/x2machines/issue/ACP-68/build-searchfilter-api-for-therapists)** Build search/filter API for therapists `zone-3c, zone-7`
  Create API endpoints for therapists to search and filter exercises based on various metadata criteria.
  
  **Endpoints:**
  
  * GET /api/exercises/search?q=shoulder&category=strength
  * GET /api/exercises/filter?body_region=shoulder&movement_pattern=push
  
  **Acceptance Criteria:**
  
  * Full-text search on exercise name
  * Filter by any metadata field
  * Paginated results
  * Returns exercise templates with all metadata
  
  **Reference:** docs/epics/EPIC_D_EXERCISE_LIBRARY_METADATA.md
  💬 4 comment(s)
- **[ACP-67](https://linear.app/x2machines/issue/ACP-67/seed-exercise-library-in-supabase-50-100-items)** Seed exercise library in Supabase (50-100 items) `zone-7, zone-8`
  Create initial exercise library with at least 50-100 common exercises including all required metadata.
  
  **Metadata Required:**
  
  * category (strength, plyo, mobility, bullpen)
  * body_region (shoulder, elbow, core, lower_body)
  * movement_pattern (push, pull, hinge, squat, rotation)
  * equipment (barbell, dumbbell, bodyweight, medicine ball)
  * load_type (weight, time, distance, reps)
  
  **Acceptance Criteria:**
  
  * 50+ exercises seeded
  * All metadata fields populated
  * Includes Brebbia XLS exercises
  * Clinical tags added where applicable
  
  **Reference:** docs/epics/EPIC_D_EXERCISE_LIBRARY_METADATA.md
  💬 2 comment(s)
- **[ACP-66](https://linear.app/x2machines/issue/ACP-66/create-plan-change-request-generator-for-throwing-flags)** Create Plan Change Request generator for throwing flags `zone-3c, zone-4b`
  Implement logic to auto-generate Plan Change Requests when throwing flags are triggered (velocity drops, command decline, pain spikes).
  
  **Trigger Conditions:**
  
  * Velocity drop >3 mph
  * Command decline >20%
  * Pain >5 during throwing
  * Excessive pitch count
  
  **Acceptance Criteria:**
  
  * Auto-creates Linear issue in zone-4b
  * Includes patient context
  * Suggests specific interventions
  * Requires PT approval
  
  **Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md
  💬 1 comment(s)
- **[ACP-65](https://linear.app/x2machines/issue/ACP-65/wire-throwing-workload-flags-into-therapist-dashboard)** Wire throwing workload flags into therapist dashboard `zone-12`
  Display throwing workload flags (high workload, velocity drop) in the therapist dashboard UI.
  
  **Flags to Display:**
  
  * High workload (pitch count > threshold)
  * Velocity drop (>3 mph decline)
  * Command decline (>20% hit rate drop)
  * Pain spike during throwing
  
  **Acceptance Criteria:**
  
  * Flags visible on patient card
  * Color-coded by severity
  * Tap to see detail
  * Updates in real-time
  
  **Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md
  💬 1 comment(s)
- **[ACP-64](https://linear.app/x2machines/issue/ACP-64/implement-vw-throwing-workload-and-vw-onramp-progress)** Implement vw_throwing_workload and vw_onramp_progress `zone-7, zone-10b`
  Create database views for throwing workload summary and on-ramp progress tracking.
  
  **Views:**
  
  * vw_throwing_workload: aggregate pitch counts, velocity trends
  * vw_onramp_progress: progression through 8-week program
  
  **Acceptance Criteria:**
  
  * Views return correct data for seeded patient
  * Execute without errors
  * Performance optimized (<500ms)
  
  **Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md
  💬 2 comment(s)
- **[ACP-63](https://linear.app/x2machines/issue/ACP-63/model-8-week-on-ramp-as-program-→-phases-→-sessions)** Model 8-week on-ramp as program → phases → sessions `zone-7, zone-12`
  Structure the 8-week on-ramp progression as a Program with Phases representing weeks and Sessions representing individual throwing days.
  
  **Structure:**
  
  * Program: "8-Week On-Ramp"
  * 8 Phases (one per week)
  * 2-3 Sessions per phase (throwing days)
  * Progressive volume/intensity
  
  **Acceptance Criteria:**
  
  * Sample 8-week program created
  * Phases properly sequenced
  * Throwing volume increases appropriately
  * XLS data structure preserved
  
  **Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md
  💬 4 comment(s)
- **[ACP-62](https://linear.app/x2machines/issue/ACP-62/normalize-bullpen-tracker-into-bullpen-logs-and-add-command-metrics)** Normalize bullpen tracker into bullpen_logs and add command metrics `zone-7, zone-8`
  Convert bullpen tracker data into bullpen_logs table with pitch_type, missed_spot_count, hit_spot_count, hit_spot_pct, and avg_velocity fields.
  
  **Table Structure:**
  
  * pitch_type (text)
  * missed_spot_count (int)
  * hit_spot_count (int)
  * hit_spot_pct (numeric)
  * avg_velocity (numeric)
  * pain_score (0-10)
  
  **Acceptance Criteria:**
  
  * bullpen_logs table created
  * Seed with sample Brebbia data
  * Command metrics calculated correctly
  
  **Reference:** docs/epics/EPIC_C_THROWING_ONRAMP_PLYO_MODEL.md
  💬 4 comment(s)
- **[ACP-61](https://linear.app/x2machines/issue/ACP-61/display-strength-targets-in-therapist-program-editor)** Display strength targets in therapist program editor `zone-12`
  Build UI in therapist program editor to show estimated 1RM and recommended strength/hypertrophy/endurance loads.
  
  **UI Elements:**
  
  * Estimated 1RM display
  * Recommended loads for each training goal
  * Last 3 session performance
  * PT override capability
  
  **Acceptance Criteria:**
  
  * Therapist sees recommended loads
  * Can override with custom values
  * Shows which RM method used
  * Updates based on latest logs
  
  **Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md
  💬 1 comment(s)
- **[ACP-60](https://linear.app/x2machines/issue/ACP-60/build-getstrengthtargets-backend-endpoint)** Build getStrengthTargets() backend endpoint `zone-3c, zone-7`
  Create backend API that returns strength_load, hypertrophy_load, endurance_load with notes on which 1RM method was used.
  
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
  
  * Endpoint returns correct strength targets (90% of 1RM)
  * Hypertrophy targets (77.5% of 1RM)
  * Endurance targets (65% of 1RM)
  * Based on recent patient logs
  
  **Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md
  💬 1 comment(s)
- **[ACP-59](https://linear.app/x2machines/issue/ACP-59/add-rm-estimate-to-exercise-logs-and-backfill-logic)** Add rm_estimate to exercise_logs and backfill logic `zone-7, zone-8`
  Add rm_estimate field to exercise_logs table and implement backfill logic for existing data.
  
  **Acceptance Criteria:**
  
  * exercise_logs table has rm_estimate column (numeric)
  * is_pr boolean field added
  * Backfill script calculates RM for existing logs
  * Computed for each set based on default_rm_method
  
  **Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md
  💬 5 comment(s)
- **[ACP-58](https://linear.app/x2machines/issue/ACP-58/implement-1rm-computation-utils-from-xls-formulas)** Implement 1RM computation utils from XLS formulas `zone-7, zone-10b`
  Create utilities to calculate 1RM using Epley, Brzycki, and Lombardi formulas exactly as used in the XLS.
  
  **Formulas:**
  
  * Epley: `1RM = W * (1 + R / 30)`
  * Brzycki: `1RM = W * 36 / (37 - R)`
  * Lombardi: `1RM = W * R^0.10`
  
  **Acceptance Criteria:**
  
  * Functions return accurate 1RM values matching XLS calculations
  * All three methods implemented
  * Unit tests cover edge cases (low reps, high reps)
  
  **Reference:** docs/epics/EPIC_B_STRENGTH_SC_MODEL_FROM_XLS.md
  💬 4 comment(s)
- **[ACP-57](https://linear.app/x2machines/issue/ACP-57/final-mvp-review-and-sign-off)** Final MVP Review & Sign-off `phase-5, zone-10b, zone-13`
  Comprehensive review of entire MVP.
  
  **Acceptance Criteria:**
  
  * All Phase 1-5 issues completed
  * All tests passing
  * Documentation complete
  * Demo video recorded (5 min)
  * Known issues documented
  * Product owner sign-off
  
  **Deliverables:**
  
  1. Demo video showing full flow
  2. Known issues list
  3. Future enhancements backlog
  4. Final handoff document
  
  **Review Checklist:**
  
  * ✅ Patient can log sessions
  * ✅ Therapist can review patients
  * ✅ Agent service creates plan changes
  * ✅ Approval flow works end-to-end
  * ✅ Security validated
  * ✅ Performance acceptable
  💬 7 comment(s)
- **[ACP-56](https://linear.app/x2machines/issue/ACP-56/create-user-documentation)** Create User Documentation `phase-5, zone-13`
  End-user guides for PT and patients.
  
  **Acceptance Criteria:**
  
  * Patient guide: How to log sessions
  * Therapist guide: How to review patients
  * Screenshots for each major feature
  * Troubleshooting section
  
  **Files:**
  
  * docs/USER_GUIDE_PATIENT.md
  * docs/USER_GUIDE_THERAPIST.md
  
  **Format:**
  
  * Step-by-step instructions
  * Annotated screenshots
  * FAQ section
  * Common issues + solutions
  💬 1 comment(s)
- **[ACP-55](https://linear.app/x2machines/issue/ACP-55/create-deployment-documentation)** Create Deployment Documentation `phase-5, zone-13`
  Document how to deploy all components.
  
  **Acceptance Criteria:**
  
  * Supabase setup guide
  * iOS app TestFlight deployment steps
  * Agent service deployment (Docker or cloud)
  * Environment variable reference
  * Monitoring setup
  
  **Files:**
  
  * docs/DEPLOYMENT.md
  * infra/docker-compose.yml (for agent service)
  * .github/workflows/deploy.yml (optional CI/CD)
  
  **Sections:**
  
  1. Prerequisites
  2. Supabase Configuration
  3. iOS App Signing & Distribution
  4. Agent Service Deployment
  5. Slack Integration Setup
  6. Monitoring & Logging
  💬 1 comment(s)
- **[ACP-54](https://linear.app/x2machines/issue/ACP-54/optimize-ios-app-performance)** Optimize iOS App Performance `phase-5, zone-12`
  Profile and optimize iOS app.
  
  **Acceptance Criteria:**
  
  * Xcode Instruments profile run
  * Identify memory leaks (none found or fixed)
  * Optimize image loading if needed
  * Reduce network calls where possible
  * App launch <2s
  
  **Focus Areas:**
  
  * View rendering performance
  * Network request optimization
  * Data caching strategy
  💬 1 comment(s)

---
*Exported: 2025-12-13T00:10:58.852928*
