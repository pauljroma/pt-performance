# PT Performance Platform - Master Execution Plan
**Version:** 1.0
**Created:** 2025-12-06
**Status:** Ready for Swarm Execution
**Linear Project:** [MVP 1 — PT App & Agent Pilot](https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b)

---

## Executive Summary

This master plan orchestrates the development of the PT Performance Platform from documentation → production-ready MVP using agent swarm coordination. The plan is structured in 6 phases with clear dependencies, quality gates, and handoff procedures.

**Total Issues:** 45+ in Linear
**Estimated Duration:** 6-8 weeks (swarm-accelerated)
**Key Deliverable:** Working PT app with AI agent backend

---

## Phase Structure

```
Phase 0: Foundation & Setup (COMPLETE) ✅
  ├─ Documentation complete
  ├─ Linear populated (45 issues)
  └─ Agent backend skeleton ready

Phase 1: Data Layer (zone-7, zone-8, zone-10b) 🎯 START HERE
  ├─ Supabase schema deployment
  ├─ Analytics views
  ├─ Demo data seeding
  └─ Data quality tests

Phase 2: Backend Intelligence (zone-3c, zone-4b)
  ├─ PT Assistant endpoints
  ├─ Flag computation engine
  ├─ Plan Change Request automation
  └─ Linear integration

Phase 3: Mobile App (zone-12)
  ├─ SwiftUI patient flow
  ├─ SwiftUI therapist dashboard
  ├─ Supabase integration
  └─ Real-time data sync

Phase 4: Integration & Testing (zone-10b, zone-13)
  ├─ End-to-end testing
  ├─ Clinical validation
  ├─ Performance testing
  └─ Security audit

Phase 5: Deployment & Monitoring (zone-13)
  ├─ Production deployment
  ├─ Monitoring setup
  ├─ Documentation finalization
  └─ Handoff preparation
```

---

## Phase 1: Data Layer (🎯 PRIORITY 1)

### Objective
Deploy fully functional Supabase data layer with schema, views, seed data, and validation.

### Issues (Filter: `zone-7` OR `zone-8` OR `zone-10b`)
- ACP-83: Validate and apply Supabase schema
- ACP-84: Seed demo data
- ACP-85: Create analytics views
- ACP-86: Implement data quality tests
- ACP-58: Implement 1RM computation utils
- ACP-59: Add rm_estimate to exercise_logs
- ACP-62: Normalize bullpen_logs
- ACP-63: Model 8-week on-ramp
- ACP-64: Implement throwing workload views
- ACP-67: Seed exercise library
- ACP-69: Add CHECK constraints
- ACP-70: Create vw_data_quality_issues
- ACP-79: Build protocol schema

### Dependencies
- ✅ Supabase project created
- ✅ SQL schema files exist (infra/*.sql)
- ✅ XLS data model documented

### Success Criteria
- [ ] All tables created in Supabase
- [ ] Views execute without errors
- [ ] Demo patient returns valid data
- [ ] Data quality tests pass (0 issues)
- [ ] 1RM calculations match XLS formulas ±2%

### Swarm Strategy
**Agent Count:** 2-3 agents in parallel

**Agent 1 (Schema & Tables):**
- Execute ACP-83 (schema validation)
- Execute ACP-69 (CHECK constraints)
- Execute ACP-79 (protocol schema)

**Agent 2 (Views & Analytics):**
- Execute ACP-85 (analytics views)
- Execute ACP-64 (throwing workload views)
- Execute ACP-70 (data quality view)

**Agent 3 (Seed & Test):**
- Execute ACP-84 (seed demo data)
- Execute ACP-67 (exercise library)
- Execute ACP-86 (data quality tests)

### Handoff Deliverables
1. Supabase dashboard screenshot showing all tables
2. Query results for each view (patient_id = demo)
3. Data quality report (0 issues)
4. Phase 1 completion checklist
5. `.outcomes/phase1_handoff.md` document

---

## Phase 2: Backend Intelligence (PRIORITY 2)

### Objective
Build PT Assistant backend with intelligent summaries, flag detection, and automated Plan Change Requests.

### Issues (Filter: `zone-3c` OR `zone-4b`)
- ACP-87: Create agent backend skeleton ✅ (DONE)
- ACP-88: Implement Supabase query endpoints
- ACP-89: Implement PT Assistant summaries
- ACP-90: Implement Plan Change Request endpoint
- ACP-60: Build getStrengthTargets() endpoint
- ACP-66: Create PCR generator for throwing flags
- ACP-68: Build search/filter API
- ACP-72: Add PT assistant behavior tests
- ACP-74: Add logging to endpoints
- ACP-81: PT Assistant protocol validation
- ACP-100: Build flag computation logic
- ACP-101: Attach flags to summary endpoints
- ACP-102: Auto-create PCRs for HIGH severity flags

### Dependencies
- ✅ Phase 1 complete (data layer working)
- ✅ Agent backend skeleton exists
- Linear API key configured

### Success Criteria
- [ ] `/api/patient-summary/:id` returns complete data
- [ ] `/api/pt-assistant/summary/:id` generates safe text
- [ ] Flag engine detects pain >5, velocity drops, low adherence
- [ ] Plan Change Requests auto-created in Linear (zone-4b)
- [ ] PT assistant behavior tests pass (no diagnoses, safe language)

### Swarm Strategy
**Agent Count:** 3 agents in parallel

**Agent 1 (Core Endpoints):**
- Execute ACP-88 (Supabase query endpoints)
- Execute ACP-60 (strength targets endpoint)
- Execute ACP-68 (search/filter API)

**Agent 2 (PT Assistant):**
- Execute ACP-89 (PT Assistant summaries)
- Execute ACP-81 (protocol validation)
- Execute ACP-72 (behavior tests)

**Agent 3 (Flags & PCRs):**
- Execute ACP-100 (flag computation)
- Execute ACP-101 (attach flags)
- Execute ACP-102 (auto-create PCRs)
- Execute ACP-90 (PCR endpoint)
- Execute ACP-66 (throwing PCR generator)

### Testing Protocol
```bash
# Test patient summary
curl http://localhost:4000/api/patient-summary/DEMO_PATIENT_ID

# Test PT assistant
curl http://localhost:4000/api/pt-assistant/summary/DEMO_PATIENT_ID

# Trigger flag (seed pain >5 for 2 sessions)
# Verify Linear issue created automatically
```

### Handoff Deliverables
1. Postman/curl test collection
2. Sample PT Assistant summaries (3+ scenarios)
3. Linear screenshot showing auto-created PCR
4. Behavior test results (all passing)
5. `.outcomes/phase2_handoff.md` document

---

## Phase 3: Mobile App (PRIORITY 3)

### Objective
Build SwiftUI mobile app for patient (iPhone) and therapist (iPad) with full Supabase integration.

### Issues (Filter: `zone-12`)
- ACP-91: Create Xcode project skeleton
- ACP-92: Integrate Supabase Swift SDK
- ACP-93: Build Today Session screen
- ACP-94: Implement exercise logging UI
- ACP-95: Create History view with charts
- ACP-96: Build therapist patient list
- ACP-97: Create patient detail screen
- ACP-98: Implement program viewer
- ACP-99: Add patient notes interface
- ACP-61: Display strength targets in editor
- ACP-65: Wire throwing workload flags to dashboard
- ACP-75: Design Today Session UX
- ACP-76: Wire Today Session to endpoint
- ACP-77: Implement session logging UI
- ACP-78: Implement pain/adherence charts
- ACP-80: Program Builder protocol integration

### Dependencies
- ✅ Phase 1 complete (data layer)
- ✅ Phase 2 complete (backend APIs)
- Xcode 15+ installed
- iOS 17+ simulator

### Success Criteria
- [ ] Patient can view today's session
- [ ] Patient can log sets/reps/load/pain
- [ ] Logs save to Supabase successfully
- [ ] Therapist dashboard shows all patients
- [ ] Charts render correctly (pain trend, adherence)
- [ ] App compiles without errors

### Swarm Strategy
**Agent Count:** 3 agents in parallel

**Agent 1 (Patient Flow):**
- Execute ACP-91 (Xcode project)
- Execute ACP-92 (Supabase SDK)
- Execute ACP-93 (Today Session screen)
- Execute ACP-75 (Today Session UX)
- Execute ACP-76 (Wire to endpoint)
- Execute ACP-94 (Logging UI)
- Execute ACP-77 (Session logging)

**Agent 2 (Patient Features):**
- Execute ACP-95 (History view)
- Execute ACP-78 (Charts)

**Agent 3 (Therapist Dashboard):**
- Execute ACP-96 (Patient list)
- Execute ACP-97 (Patient detail)
- Execute ACP-98 (Program viewer)
- Execute ACP-99 (Notes interface)
- Execute ACP-61 (Strength targets display)
- Execute ACP-65 (Throwing flags)
- Execute ACP-80 (Protocol integration)

### Testing Protocol
1. **Patient Flow Test:**
   - Open app → sign in as patient
   - View today's session
   - Log 3 exercises with pain scores
   - Submit → verify in Supabase
   - View history → verify charts

2. **Therapist Flow Test:**
   - Open app → sign in as therapist
   - View patient list (see demo patient)
   - Tap patient → see detail screen
   - View pain trend chart
   - Add therapist note
   - Verify note in Supabase

### Handoff Deliverables
1. Screen recordings of patient + therapist flows
2. Xcode project compiles without warnings
3. Screenshots of all major screens
4. `.outcomes/phase3_handoff.md` document

---

## Phase 4: Integration & Testing (PRIORITY 4)

### Objective
Validate end-to-end workflows, clinical rules, performance, and security.

### Issues (Filter: `zone-10b`)
- ACP-71: Add unit tests for 1RM functions
- ACP-73: Implement agent_logs table
- Plus all runbook test tasks (see below)

### Test Suites

#### 1. Clinical Validation Tests
**Reference:** `docs/runbooks/RUNBOOK_CLINICAL_VALIDATION.md`

Test scenarios:
- ✅ Pain spike under load (pain 3→6) → flag raised, PCR created
- ✅ Persistent medium pain (3-5 for 3 sessions) → warn only
- ✅ Acute pain drop on lower load → positive adaptation
- ✅ Chronic high pain (>5 for 4+ sessions) → urgent PCR
- ✅ Velocity decline (4+ mph) → high severity flag
- ✅ Poor command (<50% hit rate) → medium flag
- ✅ Gradual velocity increase → positive note
- ✅ High workload + pain spike → critical flag

#### 2. Analytics I/O Tests
**Reference:** `docs/runbooks/RUNBOOK_ANALYTICS_IO_TESTS.md`

Validate outputs match XLS within ±2%:
- 1RM calculations (Epley, Brzycki, Lombardi)
- Strength targets (90%, 77.5%, 65%)
- Pain trend computation
- Readiness score calculation
- Throwing workload metrics

#### 3. Performance Tests
**Reference:** `docs/runbooks/RUNBOOK_PERFORMANCE_TESTS.md`

Targets:
- API median latency < 300ms (95th percentile)
- Mobile screen load < 1.0s (Today Session)
- Dashboard load < 2.0s (20 patients)
- Agent batch summaries (50 patients) < 30 min

#### 4. Security Audit
- RLS policies prevent cross-patient data access
- Unauthenticated requests rejected
- Service role isolation validated

### Swarm Strategy
**Agent Count:** 2 agents in parallel

**Agent 1 (Clinical + Analytics Tests):**
- Execute all clinical validation scenarios
- Execute all analytics I/O tests
- Document results

**Agent 2 (Performance + Security):**
- Execute performance load tests
- Execute security audit tests
- Document results

### Success Criteria
- [ ] All clinical tests pass
- [ ] Analytics outputs match XLS ±2%
- [ ] Performance meets targets
- [ ] Security audit: 0 violations
- [ ] Comprehensive test report generated

### Handoff Deliverables
1. Test report (all passing)
2. Performance benchmarks
3. Security audit results
4. `.outcomes/phase4_handoff.md` document

---

## Phase 5: Deployment & Monitoring (PRIORITY 5)

### Objective
Deploy to production, set up monitoring, and prepare final handoff.

### Issues (Filter: `zone-13`)
- ACP-73: Implement agent_logs table
- ACP-74: Add logging to endpoints

### Deployment Checklist

#### Backend Deployment
- [ ] Deploy agent-service to cloud (Fly.io, Railway, or Vercel)
- [ ] Configure environment variables
- [ ] Set up health check monitoring
- [ ] Configure auto-scaling (if needed)

#### Mobile Deployment
- [ ] Configure App Store Connect
- [ ] Create TestFlight build
- [ ] Invite beta testers (therapists + athletes)
- [ ] Document feedback process

#### Monitoring Setup
- [ ] Configure agent_logs table
- [ ] Set up log aggregation (Supabase logs or external)
- [ ] Create monitoring dashboard
- [ ] Set up alerts (error rate, latency spikes)

#### Documentation
- [ ] Deployment guide
- [ ] User guide (patient)
- [ ] User guide (therapist)
- [ ] Agent operating manual (final version)

### Handoff Deliverables
1. Production URLs (backend + TestFlight)
2. Monitoring dashboard access
3. Complete documentation package
4. Demo video (5 min end-to-end)
5. `.outcomes/phase5_handoff.md` document
6. **`.outcomes/FINAL_HANDOFF.md`** (comprehensive)

---

## Swarm Coordination Strategy

### Swarm Execution Principles

1. **Parallel Execution:** Run 2-4 agents concurrently per phase
2. **Zone Isolation:** Agents work in different zones to avoid conflicts
3. **Clear Ownership:** One agent = one Linear issue at a time
4. **Handoff Protocol:** Each agent updates Linear with progress
5. **Quality Gates:** Phase cannot proceed until all tests pass

### Agent Communication Protocol

**Before Starting Work:**
```markdown
Agent posts to Linear issue:
"🤖 Agent starting work on ACP-XX
Zone: zone-7
Estimated completion: 2 hours
Dependencies: ACP-YY (complete)"
```

**During Work:**
```markdown
Agent updates Linear issue every 30 min:
"⏳ In progress - Step 2/4 complete
Current: Creating analytics views
Blockers: None"
```

**Upon Completion:**
```markdown
Agent posts final update:
"✅ Work complete on ACP-XX
Deliverables:
- View created: vw_patient_adherence
- Tests passing: 5/5
- Supabase screenshot: [link]
Moving to In Review"
```

### Conflict Resolution

If two agents conflict:
1. Agent with lower-numbered issue takes priority
2. Other agent pauses and comments: "⏸️ Pausing due to conflict with ACP-XX"
3. Coordinator (human or lead agent) resolves

### Quality Gates

Each phase must pass before proceeding:
- ✅ All Linear issues in phase moved to "Done"
- ✅ Phase handoff document created
- ✅ Tests passing (where applicable)
- ✅ Demo/screenshot evidence provided

---

## Linear Workflow

### Issue States
- **Backlog:** Not yet started
- **In Progress:** Agent actively working
- **In Review:** Work complete, awaiting validation
- **Done:** Validated and merged

### Labels
- **zone-*** : Architectural zone (required)
- **phase-*** : Execution phase (optional)
- **priority** : High/Medium/Low (required)
- **blocked** : Cannot proceed (add blocker comment)

### Filtering Strategies

**View Phase 1 work:**
```
zone-7 OR zone-8 OR zone-10b
```

**View Backend work:**
```
zone-3c OR zone-4b
```

**View Mobile work:**
```
zone-12
```

**View current sprint:**
```
status:in-progress OR status:in-review
```

---

## Success Metrics

### Phase Completion Metrics
- Phase 1: Data layer operational (5-7 days)
- Phase 2: Backend intelligence working (5-7 days)
- Phase 3: Mobile app functional (7-10 days)
- Phase 4: All tests passing (3-5 days)
- Phase 5: Production deployment (2-3 days)

### Quality Metrics
- Test coverage: >80%
- Analytics accuracy: ±2% of XLS
- API latency: <300ms (p95)
- Mobile load time: <1s
- Security audit: 0 critical issues

### Business Metrics
- Demo-ready: Week 3
- Beta-ready: Week 5
- Production-ready: Week 6-8

---

## Risk Mitigation

### Technical Risks
| Risk | Mitigation |
|------|------------|
| Supabase RLS complexity | Test with multiple users early |
| SwiftUI learning curve | Start with simple screens, iterate |
| Agent behavior unpredictability | Comprehensive test harness |
| Performance issues | Load testing in Phase 4 |

### Process Risks
| Risk | Mitigation |
|------|------------|
| Agent conflicts | Clear zone ownership, communication protocol |
| Scope creep | Stick to MVP, defer nice-to-haves |
| Documentation drift | Update docs during work, not after |
| Integration failures | Daily integration tests |

---

## Handoff Preparation (for 150K token limit)

### What to Include in Handoff
1. **Status Summary**
   - Phases completed
   - Current phase progress
   - Blocked items (if any)

2. **Linear State**
   - Issues: Done / In Progress / Backlog
   - Links to key issues

3. **Code State**
   - Git commit hash
   - Branch name
   - Build status

4. **Environment State**
   - Supabase project URL
   - Agent backend URL
   - TestFlight build (if available)

5. **Next Steps**
   - Specific next issue to tackle
   - Dependencies to check
   - Recommended swarm composition

### Handoff Template
```markdown
# Session Handoff: [DATE]

## Completed
- Phase X: [status]
- Issues: ACP-XX, ACP-YY (moved to Done)
- Key achievement: [specific deliverable]

## In Progress
- Issue ACP-ZZ (60% complete)
- Agent working on: [specific task]
- ETA: [hours remaining]

## Blocked
- None / [issue details]

## Next Session Priorities
1. Complete ACP-ZZ
2. Start Phase Y
3. Review [specific item]

## Environment
- Supabase: [URL]
- Agent backend: [URL]
- Git: [branch]@[commit]

## Notes
[Any important context for next session]
```

---

## Commands for Swarm Execution

### Launch Phase 1 Swarm
```bash
/swarm-it "Execute Phase 1: Data Layer
Use 3 agents in parallel.
Agent 1: Schema (ACP-83, ACP-69, ACP-79)
Agent 2: Views (ACP-85, ACP-64, ACP-70)
Agent 3: Seed (ACP-84, ACP-67, ACP-86)
Coordinate via Linear comments.
Target: 6-8 hours total."
```

### Launch Phase 2 Swarm
```bash
/swarm-it "Execute Phase 2: Backend Intelligence
Use 3 agents in parallel.
Agent 1: Core endpoints (ACP-88, ACP-60, ACP-68)
Agent 2: PT Assistant (ACP-89, ACP-81, ACP-72)
Agent 3: Flags & PCRs (ACP-100, ACP-101, ACP-102, ACP-90, ACP-66)
Target: 6-8 hours total."
```

### Launch Phase 3 Swarm
```bash
/swarm-it "Execute Phase 3: Mobile App
Use 3 agents in parallel.
Agent 1: Patient flow (ACP-91 through ACP-94)
Agent 2: Patient features (ACP-95, ACP-78)
Agent 3: Therapist dashboard (ACP-96 through ACP-99, ACP-61, ACP-65, ACP-80)
Target: 10-12 hours total."
```

---

## Appendix: Quick Reference

### Key Documents
- [Linear Project](https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b)
- [Linear Mapping Guide](docs/LINEAR_MAPPING_GUIDE.md)
- [Runbook Zero to Demo](docs/RUNBOOK_ZERO_TO_DEMO.md)
- [Agent Operating Manual](docs/agents/AGENT_OPERATING_MANUAL.md)

### Environment Files
- `.env` (root): Linear + Supabase keys
- `agent-service/.env`: Backend service config

### Key Scripts
- `populate_linear_from_docs.py`: Regenerate Linear issues
- `create_mvp_plan.py`: Create 5-phase MVP plan (original)

### Supabase
- Project: [URL to be added]
- Schema: `infra/001_init_supabase.sql`, `infra/002_epic_enhancements.sql`

### Contact & Support
- Linear team: Agent-Control-Plane
- Project lead: [To be assigned]

---

**END OF MASTER EXECUTION PLAN**

_This plan is designed for autonomous agent swarm execution with human coordination. Update as phases complete._
