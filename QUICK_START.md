# Quick Start Guide - PT Performance Platform

**For:** Agent swarm execution
**Status:** Ready to execute Phase 1
**Time to first deployment:** 6-8 hours (Phase 1)

---

## 🚀 Instant Launch (Next Session)

### Option 1: Execute Phase 1 Immediately

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

Coordination:
- Update Linear issues with progress
- Use Linear comments for agent-to-agent communication
- Create .outcomes/phase1_handoff.md when complete

Target: 6-8 hours total execution time"
```

### Option 2: Review First, Then Execute

```bash
# 1. Review the master plan
cat MASTER_EXECUTION_PLAN.md | head -200

# 2. Review Linear issues
# https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

# 3. Review session handoff
cat .outcomes/SESSION_HANDOFF_2025-12-06.md

# 4. Launch swarm (use command from Option 1)
```

---

## 📚 Essential Documents (Read These First)

### 1. **MASTER_EXECUTION_PLAN.md** (10 min read)
The complete roadmap. Read sections:
- Executive Summary
- Phase 1: Data Layer
- Swarm Coordination Strategy

### 2. **SESSION_HANDOFF_2025-12-06.md** (5 min read)
Current status and immediate next steps.

### 3. **Linear Project** (2 min browse)
https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b
- 45 issues ready to execute
- Filter by `zone-7` to see Phase 1 work

---

## 🎯 Phase Overview (6 Phases Total)

```
Phase 0: Foundation ✅ COMPLETE
├─ Documentation analyzed
├─ Linear populated (45 issues)
└─ Agent backend skeleton ready

Phase 1: Data Layer 🎯 NEXT (6-8 hours)
├─ Supabase schema deployment
├─ Analytics views
├─ Demo data seeding
└─ Data quality tests

Phase 2: Backend Intelligence (6-8 hours)
├─ PT Assistant endpoints
├─ Flag computation engine
└─ Plan Change Request automation

Phase 3: Mobile App (10-12 hours)
├─ SwiftUI patient flow
└─ SwiftUI therapist dashboard

Phase 4: Integration & Testing (5-7 hours)
├─ Clinical validation
└─ Performance testing

Phase 5: Deployment (2-3 hours)
└─ Production deployment
```

**Total MVP Time:** 3-4 weeks (swarm-accelerated)

---

## 🔑 Pre-Flight Checklist

Before launching Phase 1, verify:

### Environment
- [ ] `.env` exists with LINEAR_API_KEY
- [ ] `agent-service/.env` exists with Supabase keys
- [ ] Supabase project created (or URL configured)

### Documentation
- [ ] Can access Linear project
- [ ] `MASTER_EXECUTION_PLAN.md` exists
- [ ] `infra/*.sql` files exist

### Tools
- [ ] Python 3.8+ (for scripts)
- [ ] Node.js 18+ (for agent-service)
- [ ] Supabase CLI (optional, for local dev)

### Knowledge
- [ ] Read Phase 1 section of master plan
- [ ] Understand swarm coordination protocol
- [ ] Know how to filter Linear issues by zone

---

## 📊 Linear Filters (Use These Often)

```
# View Phase 1 work
zone-7 OR zone-8 OR zone-10b

# View backend work (Phase 2)
zone-3c OR zone-4b

# View mobile work (Phase 3)
zone-12

# View in-progress work
status:in-progress

# View high priority
priority:high

# View specific epic tasks
label:EPIC_B

# View specific runbook tasks
label:RUNBOOK_DATA_SUPABASE
```

---

## 🤖 Agent Coordination Rules

### Before Starting
Each agent posts to Linear issue:
```
🤖 Agent starting work on ACP-XX
Zone: zone-7
Estimated completion: 2 hours
Dependencies: None
```

### During Work
Update every 30 minutes:
```
⏳ In progress - Step 2/4 complete
Current: Creating vw_patient_adherence view
Blockers: None
```

### Upon Completion
Final update:
```
✅ Work complete on ACP-XX
Deliverables:
- Table created: patients (12 fields)
- View created: vw_patient_adherence
- Tests passing: 5/5
- Screenshot: [Supabase dashboard link]
Moving to In Review
```

---

## 🎬 Swarm Launch Commands

### Phase 1: Data Layer
```bash
/swarm-it "Execute Phase 1: Data Layer
[Use full command from Option 1 above]"
```

### Phase 2: Backend Intelligence (After Phase 1)
```bash
/swarm-it "Execute Phase 2: Backend Intelligence
Use 3 agents in parallel.
Agent 1: Core endpoints (ACP-88, ACP-60, ACP-68)
Agent 2: PT Assistant (ACP-89, ACP-81, ACP-72)
Agent 3: Flags & PCRs (ACP-100, ACP-101, ACP-102, ACP-90, ACP-66)
Reference: MASTER_EXECUTION_PLAN.md Phase 2
Target: 6-8 hours"
```

### Phase 3: Mobile App (After Phase 2)
```bash
/swarm-it "Execute Phase 3: Mobile App
Use 3 agents in parallel.
Agent 1: Patient flow (ACP-91 through ACP-94)
Agent 2: Patient features (ACP-95, ACP-78)
Agent 3: Therapist dashboard (ACP-96 through ACP-99)
Reference: MASTER_EXECUTION_PLAN.md Phase 3
Target: 10-12 hours"
```

---

## 📁 Project Structure

```
clients/linear-bootstrap/
├── README.md                          # Project overview
├── MASTER_EXECUTION_PLAN.md          # 👈 Complete execution strategy
├── QUICK_START.md                    # 👈 This file
├── .env                              # Linear + Supabase keys
├── populate_linear_from_docs.py      # Regenerate Linear issues
│
├── agent-service/                    # Backend service
│   ├── src/server.js                # Express server
│   ├── package.json                 # Dependencies
│   ├── .env                         # Service config
│   └── README.md                    # Backend docs
│
├── infra/                            # Database schemas
│   ├── 001_init_supabase.sql       # Initial schema
│   └── 002_epic_enhancements.sql   # Epic additions
│
├── docs/                             # Comprehensive documentation
│   ├── LINEAR_MAPPING_GUIDE.md      # Linear issue guide
│   ├── RUNBOOK_ZERO_TO_DEMO.md      # Demo walkthrough
│   ├── epics/                       # 15 epic specifications
│   ├── runbooks/                    # 12 implementation runbooks
│   ├── agents/                      # Agent operating manual
│   ├── system/                      # System architecture
│   ├── data/                        # Mock data
│   └── demo/                        # Demo scripts
│
└── .outcomes/                        # Session artifacts
    └── SESSION_HANDOFF_2025-12-06.md # 👈 Current session state
```

---

## 🧪 Testing Strategy

### Phase 1 Testing
After Phase 1 completion, validate:
```sql
-- Test 1: All tables exist
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public';

-- Test 2: Views execute
SELECT * FROM vw_patient_adherence LIMIT 5;
SELECT * FROM vw_pain_trend LIMIT 5;
SELECT * FROM vw_throwing_workload LIMIT 5;

-- Test 3: Demo patient exists
SELECT * FROM patients WHERE first_name = 'John' AND last_name = 'Brebbia';

-- Test 4: Data quality
SELECT * FROM vw_data_quality_issues;
-- Expected: 0 rows (no issues)
```

### Phase 2 Testing
```bash
# Test 1: Health check
curl http://localhost:4000/health

# Test 2: Patient summary
curl http://localhost:4000/api/patient-summary/PATIENT_ID

# Test 3: PT Assistant
curl http://localhost:4000/api/pt-assistant/summary/PATIENT_ID

# Test 4: Verify Linear PCR created
# Check Linear for zone-4b issue after triggering high pain flag
```

---

## 🚨 Troubleshooting

### Issue: Supabase connection fails
```bash
# Check environment variables
echo $SUPABASE_URL
echo $SUPABASE_SERVICE_ROLE_KEY

# Verify in .env file
cat agent-service/.env | grep SUPABASE
```

### Issue: Linear API fails
```bash
# Check Linear key
echo $LINEAR_API_KEY

# Test Linear connection
python3 -c "
import os
from linear_bootstrap import LinearBootstrap
import asyncio

async def test():
    async with LinearBootstrap(os.getenv('LINEAR_API_KEY')) as lb:
        team = await lb.get_or_create_team('Agent-Control-Plane')
        print('✓ Linear connection OK:', team['name'])

asyncio.run(test())
"
```

### Issue: Swarm agents conflict
1. Check Linear issue comments
2. Identify which agent started first
3. Other agent pauses and comments: "⏸️ Pausing due to conflict"
4. Manually reassign conflicting issue

---

## 📞 Quick Reference

### Key Links
- **Linear Project:** https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b
- **Linear Team:** Agent-Control-Plane (ACP)
- **Supabase:** [To be configured]

### Key Commands
```bash
# Regenerate Linear issues
python3 populate_linear_from_docs.py

# Start agent backend
cd agent-service && npm install && npm run dev

# Apply Supabase schema
supabase db push

# Run tests
cd agent-service && npm test
```

### Key Files
- `MASTER_EXECUTION_PLAN.md` - Complete strategy
- `.outcomes/SESSION_HANDOFF_2025-12-06.md` - Current state
- `docs/LINEAR_MAPPING_GUIDE.md` - Issue creation guide
- `docs/RUNBOOK_ZERO_TO_DEMO.md` - Demo walkthrough

---

## ✅ Success Indicators

### Phase 1 Success
- [ ] All 13 Phase 1 issues in Linear marked "Done"
- [ ] Supabase dashboard shows all tables
- [ ] All views return data for demo patient
- [ ] Data quality view returns 0 issues
- [ ] `.outcomes/phase1_handoff.md` created

### Phase 2 Success
- [ ] All 13 Phase 2 issues marked "Done"
- [ ] Agent backend running on port 4000
- [ ] All API endpoints return 200 OK
- [ ] PT Assistant generates safe summaries
- [ ] Plan Change Request auto-created in Linear

### Phase 3 Success
- [ ] Xcode project compiles without errors
- [ ] Patient can log full session
- [ ] Therapist can view dashboard
- [ ] Charts render correctly
- [ ] TestFlight build created

---

## 🎯 Next Steps

1. **Right Now:** Review this guide (5 min)
2. **Next:** Read Phase 1 of MASTER_EXECUTION_PLAN.md (10 min)
3. **Then:** Launch Phase 1 swarm (use command from top)
4. **Monitor:** Check Linear for agent updates every 30-60 min
5. **Validate:** Run Phase 1 tests when agents complete
6. **Handoff:** Create phase1_handoff.md

---

**You are here:** Ready to execute Phase 1

**Time to first working demo:** 6-8 hours (Phase 1 complete)

**Time to MVP:** 3-4 weeks (all phases)

---

_Let's build something amazing! 🚀_
