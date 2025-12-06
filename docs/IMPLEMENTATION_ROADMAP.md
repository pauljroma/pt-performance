# PT Performance App - Implementation Roadmap

**Generated:** 2025-12-05
**Status:** Ready for Implementation
**Documentation Lines:** 1,487 (epics + runbooks)

---

## 📚 Documentation Inventory

### Core Documentation (10 files)
- PT_APP_VISION.md - System vision and goals
- PT_APP_ARCHITECTURE.md - Technical architecture
- PT_APP_PLAN.md - Original task breakdown
- PT_APP_DATA_MODEL_FROM_XLS.md - Database model from XLS
- PT_APP_USER_STORIES.md - User stories
- PT_APP_SYSTEM_GUIDE.md - Agent workflow guide
- AGENT_GOVERNANCE.md - Agent rules of engagement
- SLACK_APPROVAL_FLOW.md - Approval workflow
- PHASE_HANDOFF_TEMPLATE.md - Session continuity template
- LINEAR_MAPPING_GUIDE.md - Epic → Linear translation guide

### Epic Documents (12 files)
- **EPIC_A** - Personal & Clinical Context (Brebbia profile)
- **EPIC_B** - Strength & S&C Model (1RM, targets, progression)
- **EPIC_C** - Throwing, On-Ramp & Plyo Model
- **EPIC_D** - Exercise Library Metadata & Classification
- **EPIC_E** - Program Builder Specification
- **EPIC_F** - Program Execution Logic
- **EPIC_G** - Pain Interpretation Model
- **EPIC_H** - Therapist Dashboard (iPad)
- **EPIC_I** - Patient App UX & Flows (iPhone)
- **EPIC_J** - PT Assistant Agent Specification
- **EPIC_K** - Data Quality & Testing Strategy
- **EPIC_L** - Monitoring & Logging

### Runbooks (5 files)
- **RUNBOOK_DATA_SUPABASE** - Data layer implementation
- **RUNBOOK_MOBILE_SWIFTUI** - iOS/iPadOS app build
- **RUNBOOK_AGENT_BACKEND** - PT agent backend
- **RUNBOOK_FLAGS_RISK_ENGINE** - Risk detection system
- **RUNBOOK_THERAPIST_DASHBOARD** - Therapist monitoring UI

### Infrastructure (2 files)
- **001_init_supabase.sql** - Base schema (182 lines)
- **002_epic_enhancements.sql** - Epic-driven enhancements (500+ lines)

---

## 🎯 System Scope

### Database Layer
**Tables:** 15 core + 3 new = 18 total
- therapists, patients
- programs, phases, sessions
- exercise_templates, session_exercises
- exercise_logs, pain_logs, bullpen_logs, plyo_logs
- body_comp_measurements, session_notes
- session_status (new)
- pain_flags (new)

**Views:** 6 analytical
- vw_patient_adherence
- vw_pain_trend
- vw_pain_summary (new)
- vw_throwing_workload (new)
- vw_onramp_progress (new)
- vw_therapist_patient_summary (new)
- vw_performance_trends (new)

**Enhancements:**
- Full RLS policies
- Enhanced exercise_templates (movement patterns, clinical tags, throwing tags)
- 1RM computation fields (rm_estimate, is_pr)
- Bullpen command tracking (hit_spot_pct, missed_spot_count)
- Program metadata (target_level, role, return_to_throw_target)
- Phase constraints (JSON)
- Session intensity ratings

### Mobile App (SwiftUI)
**Patient Screens:**
- Today's session view
- Exercise logging with pain/RPE
- Session history
- Basic progress charts

**Therapist Screens:**
- Patient list with flags
- Patient detail with metrics
- Program/phase viewer
- Notes & assessments

### Backend Services (Node.js)
**Endpoints:**
- GET /health
- GET /patient-summary/{id}
- GET /today-session/{id}
- GET /pt-assistant/summary/{id}
- POST /pt-assistant/plan-change-proposal/{id}

**Integrations:**
- Supabase (data access)
- Linear (plan change requests)
- Slack (approval notifications - later)

### Flagging & Risk Engine
**Flag Types:**
- Pain-based (>5, sustained 3-5, increasing trend)
- Velocity drops (>3 mph, >5 mph critical)
- Command decline (hit-spot% drop >20%)
- Adherence (<60% over 7 days)

**Actions:**
- Auto-create Linear issues (zone-4b)
- Notify therapist
- Block unsafe progressions

---

## 📊 Workstream Breakdown

### Workstream 1: Data Foundation
**Runbook:** RUNBOOK_DATA_SUPABASE.md
**Zones:** zone-7, zone-8, zone-10b
**Effort:** ~40-50K tokens
**Dependencies:** None

**Deliverables:**
1. Full schema deployed to Supabase
2. Demo data seeded (1 therapist, 1 patient, 1 program)
3. All views working
4. Data quality tests passing

**Critical Path:** YES - All other workstreams depend on this

---

### Workstream 2: Mobile Patient App
**Runbook:** RUNBOOK_MOBILE_SWIFTUI.md
**Zones:** zone-12
**Effort:** ~50-60K tokens
**Dependencies:** Workstream 1 (data layer)

**Deliverables:**
1. Auth integration
2. Today's session screen
3. Exercise logging
4. History view with charts

**Critical Path:** YES - Core user value

---

### Workstream 3: PT Agent Backend
**Runbook:** RUNBOOK_AGENT_BACKEND.md
**Zones:** zone-3c, zone-12
**Effort:** ~40-50K tokens
**Dependencies:** Workstream 1 (data layer)

**Deliverables:**
1. Backend service running
2. Patient summary endpoint
3. PT assistant summaries
4. Plan change request creation

**Critical Path:** YES - Enables intelligent features

---

### Workstream 4: Risk Engine
**Runbook:** RUNBOOK_FLAGS_RISK_ENGINE.md
**Zones:** zone-7, zone-10b, zone-3c, zone-4b
**Effort:** ~30-40K tokens
**Dependencies:** Workstream 1, 3

**Deliverables:**
1. Flag computation logic
2. Auto plan-change requests
3. Integration with endpoints

**Critical Path:** MEDIUM - Adds safety intelligence

---

### Workstream 5: Therapist Dashboard
**Runbook:** RUNBOOK_THERAPIST_DASHBOARD.md
**Zones:** zone-12, zone-3c, zone-7
**Effort:** ~40-50K tokens
**Dependencies:** Workstream 1, 4

**Deliverables:**
1. Patient list
2. Patient detail screen
3. Program viewer
4. Notes interface

**Critical Path:** MEDIUM - Professional interface

---

## 🚀 Recommended Execution Order

### Phase 1: Foundation (Must Complete First)
**Workstream:** Data Foundation
**Runbook:** RUNBOOK_DATA_SUPABASE.md
**Why First:**
- All other workstreams depend on it
- Establishes data integrity
- Enables parallel development after completion
- Validates XLS → schema mapping

**Estimated:** ~40-50K tokens
**Timeline:** 1 session

---

### Phase 2: Core Value Delivery (Parallel)
**Workstreams:** Mobile Patient App + PT Agent Backend
**Runbooks:** RUNBOOK_MOBILE_SWIFTUI.md + RUNBOOK_AGENT_BACKEND.md
**Why Parallel:**
- Independent after data layer
- Both deliver immediate user value
- Mobile = patient experience
- Backend = intelligent features

**Estimated:** ~90-110K tokens total
**Timeline:** 1-2 sessions (can run in parallel)

---

### Phase 3: Intelligence Layer
**Workstream:** Risk Engine
**Runbook:** RUNBOOK_FLAGS_RISK_ENGINE.md
**Why After Phase 2:**
- Requires backend endpoints
- Enhances existing features
- Adds clinical safety

**Estimated:** ~30-40K tokens
**Timeline:** 1 session

---

### Phase 4: Professional Polish
**Workstream:** Therapist Dashboard
**Runbook:** RUNBOOK_THERAPIST_DASHBOARD.md
**Why Last:**
- Requires all data and flags
- Pulls from all other systems
- Non-blocking for patient value

**Estimated:** ~40-50K tokens
**Timeline:** 1 session

---

## 💡 Recommendation: START WITH DATA FOUNDATION

### Why Start Here?
1. **Zero Dependencies** - Can start immediately
2. **Unblocks Everything** - All other work depends on it
3. **Validates Architecture** - Proves XLS → database mapping works
4. **Provides Test Data** - Enables realistic development
5. **Clear DoD** - Schema + seed data + views working

### First 3 Steps (Immediate)
1. **Apply Base Schema**
   ```bash
   # Connect to Supabase
   psql -h db.YOUR_PROJECT.supabase.co -U postgres

   # Run base schema
   \i infra/001_init_supabase.sql

   # Run enhancements
   \i infra/002_epic_enhancements.sql
   ```

2. **Seed Demo Data**
   - Create demo therapist
   - Create demo patient (Brebbia profile)
   - Create 8-week on-ramp program
   - Add sample exercises and logs

3. **Validate Views**
   ```sql
   SELECT * FROM vw_patient_adherence;
   SELECT * FROM vw_pain_summary;
   SELECT * FROM vw_throwing_workload;
   ```

### Expected Outcomes
- ✅ All tables created
- ✅ Demo patient visible in dashboard
- ✅ Views return realistic data
- ✅ Ready for mobile + backend development

---

## 📈 Token Budget Projection

| Workstream | Estimate | Critical Path |
|-----------|----------|--------------|
| Data Foundation | 40-50K | ✅ YES |
| Mobile Patient App | 50-60K | ✅ YES |
| PT Agent Backend | 40-50K | ✅ YES |
| Risk Engine | 30-40K | ⚠️ MEDIUM |
| Therapist Dashboard | 40-50K | ⚠️ MEDIUM |
| **TOTAL** | **200-250K** | |

**Available Budget:** ~750K tokens (per original plan)
**Usage After 5 Workstreams:** ~33% of budget
**Remaining:** ~500K for refinement, testing, deployment

---

## ✅ Success Criteria

### Data Foundation Complete When:
- [ ] Schema deployed to Supabase
- [ ] Demo data loaded and queryable
- [ ] All views return correct results
- [ ] Data quality tests pass

### MVP Complete When:
- [ ] Patient can log sessions via mobile app
- [ ] Therapist can view patient progress
- [ ] PT assistant generates summaries
- [ ] Risk flags auto-create plan changes
- [ ] All 5 workstreams delivered

### Production Ready When:
- [ ] E2E tests passing
- [ ] Performance acceptable (<2s queries)
- [ ] Security validated (RLS policies)
- [ ] Monitoring and logging active
- [ ] Product owner sign-off

---

## 🎯 Next Action

**Recommended:** Execute Workstream 1 (Data Foundation)

**Command:**
```
Execute RUNBOOK_DATA_SUPABASE.md starting with Step A (Validate Schema).
Update Linear issues as each step completes.
```

**Expected Duration:** 1 session (~40-50K tokens)
**Output:** Fully functional data layer ready for mobile + backend development
