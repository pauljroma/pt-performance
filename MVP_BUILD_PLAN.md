# MVP Build Plan - PT Performance App

**Created:** 2025-12-06
**Total Issues:** 50
**Phases:** 5
**Estimated Duration:** ~750K tokens (150K per phase)

**Linear Project:** https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

---

## 📋 Overview

This document outlines the complete 5-phase build plan for the PT Performance MVP. Each phase is designed to take approximately 150K tokens, allowing for clean session handoffs between phases.

### Success Criteria

By the end of Phase 5, we will have:
- ✅ Fully functional iOS app (patient + therapist flows)
- ✅ Supabase backend with secure data storage
- ✅ Agent service with Linear integration
- ✅ Approval workflow via Slack
- ✅ End-to-end tested system
- ✅ Production-ready deployment

---

## 🎯 Phase Breakdown

### Phase 1: Foundation & Database (~150K tokens)
**Issues:** ACP-8 through ACP-17 (10 issues)
**Focus:** Database schema, demo data, basic agent service

**Key Deliverables:**
- Supabase schema applied with RLS policies
- Demo data seeded (therapist, patient, 8-week program)
- Exercise template library (30+ exercises)
- Agent service skeleton running
- Database views tested

**Zones:** zone-7, zone-8, zone-3c, zone-13
**Filter in Linear:** `phase-1`

**Entry Requirements:**
- Supabase project created
- LINEAR_API_KEY configured

**Exit Criteria:**
- All 10 Phase 1 issues marked "Done"
- Database queries working
- Demo data visible in Supabase dashboard
- Agent service health endpoint responding
- Handoff document created

---

### Phase 2: Patient Mobile Flow (~150K tokens)
**Issues:** ACP-18 through ACP-27 (10 issues)
**Focus:** SwiftUI patient app with session logging

**Key Deliverables:**
- Xcode project for PTPerformance
- Supabase auth integration
- Today's session screen (fetch & display)
- Exercise logging UI with pain tracking
- Session submission to database
- Patient history view with pain trends

**Zones:** zone-12, zone-8, zone-13
**Filter in Linear:** `phase-2`

**Entry Requirements:**
- Phase 1 complete
- Supabase project accessible
- Demo patient data available
- Xcode installed

**Exit Criteria:**
- Patient can sign in
- Patient can view today's session
- Patient can log sets/reps/load/pain
- Data saves to Supabase
- History view displays correctly
- Handoff document created

---

### Phase 3: Therapist Mobile Flow (~150K tokens)
**Issues:** ACP-28 through ACP-37 (10 issues)
**Focus:** SwiftUI therapist dashboard and patient review

**Key Deliverables:**
- Therapist dashboard with patient list
- Patient detail view with metrics
- Program viewer (phases → sessions → exercises)
- Session log review interface
- Therapist notes functionality
- Adherence and pain charts
- Pain alerts for concerning trends
- iPad-optimized layout

**Zones:** zone-12, zone-8, zone-13
**Filter in Linear:** `phase-3`

**Entry Requirements:**
- Phase 2 complete
- Demo patient has logged sessions
- Pain data available for charts

**Exit Criteria:**
- Therapist can review all patients
- Charts and metrics display correctly
- Notes can be added
- Alerts show for pain spikes
- iPad layout works
- Handoff document created

---

### Phase 4: Agent Service + Approvals (~150K tokens)
**Issues:** ACP-38 through ACP-47 (10 issues)
**Focus:** Backend service with Linear integration and approval flow

**Key Deliverables:**
- Patient summary endpoint
- Today's session endpoint
- Linear client integration
- Plan change request creator
- Clinical safety checks
- Slack app for approvals
- Slack notification system
- Approval webhook handler
- Agent action logging

**Zones:** zone-3c, zone-4b, zone-8, zone-13
**Filter in Linear:** `phase-4`

**Entry Requirements:**
- Phase 3 complete
- Node.js installed
- Slack workspace access
- LINEAR_API_KEY working

**Exit Criteria:**
- Agent service endpoints working
- Can create Linear issues programmatically
- Safety checks detect pain issues
- Slack notifications send
- Approval flow end-to-end functional
- All actions logged
- Handoff document created

---

### Phase 5: Integration & Polish (~150K tokens)
**Issues:** ACP-48 through ACP-57 (10 issues)
**Focus:** Testing, optimization, and deployment prep

**Key Deliverables:**
- E2E test: Patient session flow
- E2E test: Therapist review flow
- E2E test: Plan change approval flow
- Performance testing with realistic data
- Security audit of RLS policies
- Critical bug fixes
- iOS app optimization
- Deployment documentation
- User documentation
- Final MVP review and sign-off

**Zones:** zone-10b, zone-12, zone-3c, zone-8, zone-13
**Filter in Linear:** `phase-5`

**Entry Requirements:**
- Phases 1-4 complete
- All major features implemented
- Ready for comprehensive testing

**Exit Criteria:**
- All E2E tests passing
- Performance acceptable (<2s queries)
- Security validated
- P0/P1 bugs fixed
- Documentation complete
- Product owner sign-off
- Ready for production deployment

---

## 🔄 Phase Transition Workflow

### Completing a Phase

1. **Verify all issues Done**
   ```bash
   /sync-linear
   # Check: All phase-X issues marked Done
   ```

2. **Create handoff document**
   - Use template: `docs/PHASE_HANDOFF_TEMPLATE.md`
   - Save as: `.outcomes/PHASE_X_HANDOFF_YYYY-MM-DD.md`
   - Document:
     - Completed tasks
     - Key decisions
     - Testing results
     - Known issues
     - Prerequisites for next phase

3. **Verify exit criteria**
   - All acceptance criteria met
   - No blocking issues
   - Demo/test data validates functionality

4. **Commit and push**
   ```bash
   git add .
   git commit -m "Phase X complete - [summary]"
   git push origin feature/phase-X
   ```

5. **Close session**
   - Session can be closed
   - Context is preserved in:
     - Linear issues (source of truth)
     - Handoff document
     - Git commits

### Starting Next Phase

1. **New session - sync Linear**
   ```bash
   /sync-linear
   # or
   python3 linear_client.py export-md
   ```

2. **Read handoff document**
   ```bash
   cat .outcomes/PHASE_X_HANDOFF_*.md
   ```

3. **Verify prerequisites**
   - Check environment configured
   - Demo data available
   - Previous phase deliverables working

4. **Filter for next phase**
   - Linear: Apply filter `phase-X+1`
   - Sort by priority (High first)

5. **Pick first task**
   - Select highest priority issue
   - Read issue description and acceptance criteria
   - Create feature branch
   - Update issue to "In Progress"
   - Begin work!

---

## 📊 Token Budget Guidelines

### Per-Phase Allocation (~150K tokens)

- **Planning & Context** (10-15K)
  - Read documentation
  - Sync Linear
  - Understand requirements

- **Implementation** (100-110K)
  - Write code
  - Debug issues
  - Iterative development

- **Testing** (20-25K)
  - Manual testing
  - Fix bugs
  - Validate acceptance criteria

- **Documentation** (10-15K)
  - Code comments
  - Update README
  - Create handoff doc

### Staying Within Budget

- ✅ **Do:** Focus on acceptance criteria
- ✅ **Do:** Test incrementally
- ✅ **Do:** Reuse existing code
- ✅ **Do:** Keep solutions simple

- ❌ **Don't:** Over-engineer
- ❌ **Don't:** Add unplanned features
- ❌ **Don't:** Refactor working code unnecessarily
- ❌ **Don't:** Create extensive documentation mid-phase

### If Running Over Budget

If approaching 150K tokens before phase complete:

1. **Prioritize remaining tasks**
   - Focus on High priority issues only
   - Defer Medium/Low to next phase

2. **Create interim handoff**
   - Document what's complete
   - List what's deferred
   - Note blockers

3. **Close session strategically**
   - Commit all work
   - Update Linear issues
   - Prepare clear resume point

---

## 🎯 Success Metrics by Phase

### Phase 1 Success
- [ ] Database schema deployed
- [ ] Can query demo data
- [ ] Agent service health check works

### Phase 2 Success
- [ ] Patient can sign in
- [ ] Patient can log a complete session
- [ ] Data persists to Supabase

### Phase 3 Success
- [ ] Therapist can view all patients
- [ ] Charts display correctly
- [ ] Can add notes

### Phase 4 Success
- [ ] Safety check creates Linear issue
- [ ] Slack notification sends
- [ ] Approval updates Linear

### Phase 5 Success
- [ ] All E2E tests pass
- [ ] Performance meets targets
- [ ] Security validated
- [ ] Product owner approves

---

## 🔧 Tools & Commands

### Linear Integration

```bash
# Sync plan
/sync-linear

# Export to markdown
python3 linear_client.py export-md

# List issues
python3 linear_client.py list-issues --team "Agent-Control-Plane"

# Add comment
python3 linear_client.py add-comment --issue-id <id> --comment "Update"

# Update status
python3 linear_client.py update-status --issue-id <id> --state-id <state>
```

### Phase Management

```bash
# View current phase issues (in Linear web UI)
Filter: phase-1 (or phase-2, phase-3, etc.)

# View phase handoff docs
ls .outcomes/PHASE_*_HANDOFF_*.md

# Check token usage estimate
# (Track manually or use token counter tool)
```

### Git Workflow

```bash
# Create phase branch
git checkout -b feature/phase-1

# Work on issue
git checkout -b feature/acp-8-supabase-schema

# Commit with issue reference
git commit -m "ACP-8: Apply Supabase schema

- Created all tables
- Added RLS policies
- Tested with demo data"

# Push and continue
git push origin feature/acp-8-supabase-schema
```

---

## 📚 Key Documents Reference

### Before Starting Any Phase
- `docs/PT_APP_VISION.md` - Overall vision
- `docs/PT_APP_ARCHITECTURE.md` - System architecture
- `docs/AGENT_GOVERNANCE.md` - Agent rules

### Phase-Specific Guides
- **Phase 1:** `docs/PT_APP_DATA_MODEL_FROM_XLS.md`
- **Phase 2:** `docs/PT_APP_USER_STORIES.md` (Patient stories)
- **Phase 3:** `docs/PT_APP_USER_STORIES.md` (Therapist stories)
- **Phase 4:** `docs/SLACK_APPROVAL_FLOW.md`
- **Phase 5:** `docs/PT_APP_SYSTEM_GUIDE.md`

### During Any Phase
- `docs/AGENT_GOVERNANCE.md` - Rules of engagement
- `docs/PT_APP_SYSTEM_GUIDE.md` - Workflow guide
- Linear issues - Source of truth

### After Each Phase
- `.outcomes/PHASE_X_HANDOFF_*.md` - Session handoff

---

## 🚦 Getting Started

### Start Phase 1 Now

1. **Sync the plan**
   ```bash
   /sync-linear
   ```

2. **Read Phase 1 docs**
   - `docs/PT_APP_ARCHITECTURE.md`
   - `docs/PT_APP_DATA_MODEL_FROM_XLS.md`
   - `infra/001_init_supabase.sql`

3. **Pick first issue**
   - Filter Linear: `phase-1`
   - First task: **ACP-8: Apply Supabase Schema to Dev Project**
   - URL: https://linear.app/bb-pt/issue/ACP-8

4. **Begin building!**
   ```bash
   git checkout -b feature/acp-8-supabase-schema
   # Update Linear issue to "In Progress"
   # Start implementing...
   ```

---

## ✨ Final Notes

### This Plan Provides

- ✅ Clear phase boundaries for session management
- ✅ ~150K token budget per phase
- ✅ Complete task breakdown (50 issues)
- ✅ Handoff templates for context preservation
- ✅ Linear as single source of truth
- ✅ Testable deliverables at each phase

### Keys to Success

1. **Always sync Linear first** - It's the source of truth
2. **Stay focused on acceptance criteria** - Don't over-engineer
3. **Test incrementally** - Don't save testing for the end
4. **Document as you go** - Handoffs are critical
5. **Update Linear frequently** - Keep status current

### When in Doubt

- Check Linear for current status
- Read the handoff doc from previous phase
- Review `docs/AGENT_GOVERNANCE.md` for rules
- Ask clarifying questions before proceeding

---

**Ready to build?** Start with Phase 1: https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b?filter=phase-1

**Good luck!** 🚀
