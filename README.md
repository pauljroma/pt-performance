# PT Performance Platform

iOS app + Supabase backend for physical therapy performance tracking and AI-assisted program management.

## Current Status

**Build:** 32 (TestFlight)
**Phase:** Exercise Logging (Phase 1.1 - 95% complete)
**Blocker:** Migration `20251212000001_create_exercise_logs_table.sql` pending application

See `.claude/AUTOMATED_MIGRATIONS.md` for migration workflow.

## Features

### Patient App (iOS)
- ✅ Login with Supabase auth
- ✅ View assigned exercise programs
- ✅ Navigate program → phases → sessions → exercises
- ✅ Exercise logging UI (sets, reps, load, RPE, pain)
- ⏳ Exercise log persistence (Build 32 - pending migration)
- 🔜 Session completion & summary (Build 33)
- 🔜 Session history with trends (Build 34)

### Therapist Dashboard (iOS)
- ✅ Login and patient list
- ✅ Patient detail view with program overview
- 🔜 Pain trend charts (Build 35)
- 🔜 Volume & velocity metrics (Build 36)
- 🔜 Readiness score algorithm (Build 37)

### PT Assistant (Backend + iOS)
- 🔜 Patient analysis engine (Build 38)
- 🔜 Linear integration for plan changes (Build 39)
- 🔜 iOS tab for reviewing suggestions (Build 40)

### Program Builder (iOS)
- 🔜 Program template library (Build 41)
- 🔜 Program editor (phases, sessions) (Build 42)
- 🔜 Exercise prescription builder (Build 43)

### Video Examples
- 🔜 Video library setup (Build 44)
- 🔜 Video player in exercise detail (Build 45)

## Architecture

- **Frontend:** SwiftUI (iOS 16+)
- **Backend:** Supabase (PostgreSQL, Auth, Storage)
- **PT Assistant:** Python FastAPI + Claude API
- **Project Management:** Linear (GraphQL API)

## Development

### Prerequisites
- Xcode 15+
- Supabase CLI
- Python 3.11+ (for PT Assistant)

### Setup
1. Clone repository
2. Configure Supabase: `ios-app/PTPerformance/Config.swift`
3. Apply migrations: See `.claude/HOW_TO_APPLY_MIGRATIONS.md`
4. Build: `cd ios-app/PTPerformance && bundle exec fastlane beta`

### Documentation

**Runbooks (Read FIRST for repetitive tasks):**
- `.claude/MIGRATION_RUNBOOK.md` - **PRIMARY** - Migration execution checklist
- `.claude/BUILD_RUNBOOK.md` - iOS build & TestFlight deployment
- `.claude/TROUBLESHOOTING_RUNBOOK.md` - Common errors & solutions
- `.claude/MIGRATION_SCRIPTS_INVENTORY.md` - Existing scripts catalog

**Reference Documentation:**
- `.claude/HOW_TO_APPLY_MIGRATIONS.md` - Migration details & manual steps
- `.claude/AUTOMATED_MIGRATIONS.md` - Automation history (31 builds)
- `docs/epics/` - Product roadmap (15 epics)
- `docs/demo/MVP_DEMO_SCRIPT.md` - 5-7 minute demo flow
- `.outcomes/BUILD32_MIGRATION_REQUIRED.md` - Current blocker details

**Claude Instructions:**
When encountering these tasks, **read the runbook FIRST** (don't explore/research):
- "Migration" → Read `.claude/MIGRATION_RUNBOOK.md`
- "Build" or "TestFlight" → Read `.claude/BUILD_RUNBOOK.md`
- Error message → Search `.claude/TROUBLESHOOTING_RUNBOOK.md`

### Archive
- `.archive/` - Completed work from Builds 3-31 (archived 2025-12-12)

## Roadmap

| Phase | Builds | Status |
|-------|--------|--------|
| **Exercise Logging** | 32-34 | 🟡 In Progress |
| **Dashboard Analytics** | 35-37 | ⚪ Planned |
| **PT Assistant AI** | 38-40 | ⚪ Planned |
| **Program Builder** | 41-43 | ⚪ Planned |
| **Video Examples** | 44-45 | ⚪ Planned |

See plan at: `.claude/plans/reactive-exploring-metcalfe.md`

## Linear Project

**Team:** Agent-Control-Plane
**Project:** MVP 1 — PT App & Agent Pilot
**Issues:** ~60-70 estimated (across 5 phases)

## Demo Accounts

**Patient:**
- Email: `demo-athlete@ptperformance.app`
- Password: `demo-patient-2025`

**Therapist:**
- Email: `demo-pt@ptperformance.app`
- Password: `demo-therapist-2025`
