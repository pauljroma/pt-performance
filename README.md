# PT Performance Platform
_Rehab x Performance x AI Control Plane_

This repo contains the full system powering:
- Therapist + Athlete mobile app (SwiftUI)
- Supabase backend (Postgres + Auth)
- PT Assistant agent (Node/Python)
- Linear agent-control-plane
- Throwing + Strength analytics
- Return-to-throw engine

---

## Features

### Athlete (iPhone)
- See today's session
- Log sets/reps/load, RPE, pain
- Track progress (pain, adherence)

### Therapist (iPad)
- Dashboard for all patients
- Pain & velocity trends
- Flags for risk (pain ↑, velocity ↓)
- Program builder (phases + sessions)
- Approvals for plan changes

### AI Agents
- Read-only program analysis
- Suggest plan adjustments
- Create Plan Change Requests in Linear
- Never change patient plan without approval

---

## Architecture

### Supabase (Data Layer)
**Tables:**
- patients
- programs, phases, sessions
- exercise_templates
- session_exercises
- exercise_logs
- pain_logs
- bullpen_logs
- plyo_logs

**Views:**
- vw_patient_adherence
- vw_pain_trend
- vw_throwing_workload

### Mobile App
- SwiftUI universal app
- Supabase auth
- Today session
- History (pain + adherence)

### Agent Service (Backend)
- Node/Python
- Linear GraphQL API
- PT Assistant summaries
- Plan change proposal engine

### Linear Control Plane
- zone-* labels
- automation rules
- project: MVP 1 — PT App & Agent Pilot
- templates for:
  - agent tasks
  - plan changes
  - simulation scenarios
  - clinical tests

---

## Demo Workflow

1. Patient logs today's session
2. Supabase updates instantly
3. Therapist dashboard updates
4. AI PT Assistant summarizes risk
5. Approval flow via Linear
6. Plan updates reflected next session

---

## Development

```bash
# Apply database schema
supabase db push

# Start agent service
node agent-service/src/server.js

# Open mobile app
open ios-app/PTPerformance.xcodeproj
```

---

## Documentation

- **`/docs/epics/`** - 15 comprehensive epics (A-N + specialized)
- **`/docs/runbooks/`** - 13 step-by-step implementation guides
- **`/docs/agents/`** - Agent operating manual & prompts
- **`/docs/system/`** - Architecture, glossary, design tokens, traceability matrix
- **`/docs/demo/`** - MVP demo script
- **`/docs/data/`** - Mock athlete profiles
- **`/docs/ux/`** - Wireframe specifications
- **`/infra/`** - Database schema migrations

---

## Quick Start

See: [`docs/RUNBOOK_ZERO_TO_DEMO.md`](docs/RUNBOOK_ZERO_TO_DEMO.md)

---

## Contributing

- All changes start as Linear tasks
- Every issue must have:
  - zone label
  - Objective
  - Scope
  - DoD
- Agents sync Linear before coding
- See: [`docs/agents/AGENT_OPERATING_MANUAL.md`](docs/agents/AGENT_OPERATING_MANUAL.md)

---

## Project Statistics

- **62 Markdown Documents** (~5,000+ lines)
- **2 SQL Schema Files** (~700 lines)
- **5 Python Test Files**
- **Complete XLS → Code Traceability**
- **15 Comprehensive Epics**
- **13 Implementation Runbooks**
- **Total Project Size:** 512 KB

---

## License

Proprietary - All Rights Reserved
