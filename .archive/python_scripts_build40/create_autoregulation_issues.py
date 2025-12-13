#!/usr/bin/env python3
"""
Create Linear Issues for Auto-Regulation System Epic
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient


async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set in .env')
        return

    team_name = 'Agent-Control-Plane'

    async with LinearClient(api_key) as client:
        # Get team ID
        team = await client.get_team_by_name(team_name)
        if not team:
            print(f'❌ ERROR: Team "{team_name}" not found')
            return

        team_id = team['id']

        # Create Epic for Auto-Regulation System
        epic = await client.create_issue(
            team_id=team_id,
            title='EPIC: Auto-Regulation System + Winter Lift Program',
            description='''# Auto-Regulation System Implementation

This epic spans Builds 37-40 and implements:
1. Test patient Nic Roma with Winter Lift 3x/week program (4 storage methods)
2. Full auto-regulation system (load progression, deload triggers, phase advancement)
3. Readiness tracking with daily check-ins and workout modifications
4. Optional WHOOP integration

**Risk:** High (touches core workout flow, database schema, UI)
**Complexity:** 4-6 builds worth of work (47 story points)

**Plan:** `/Users/expo/.claude/plans/swirling-dreaming-lecun.md`

## Builds
- **Build 37:** Patient + Program Foundation (11 points)
- **Build 38:** Progression Layer (11 points)
- **Build 39:** Readiness System (16 points)
- **Build 40:** WHOOP Integration (6 points)
''',
            estimate=21  # Epic estimate
        )

        print(f'✅ Created Epic: {epic["identifier"]} - {epic["title"]}')

        # Build 37 Issues (Patient + Program Foundation)
        build37_issues = [
            {
                'title': 'ACP-120: Create test patient Nic Roma with auth',
                'description': '''Create test patient "Nic Roma" following demo patient pattern.

**Tasks:**
- Create SQL migration: `20251213000001_seed_nic_roma_patient.sql`
- Create auth user via Python script: `create_nic_roma_user.py`
- Email: nic.roma@ptperformance.app / Password: nic-demo-2025
- Link to therapist Sarah Thompson

**Files:**
- `supabase/migrations/20251213000001_seed_nic_roma_patient.sql`
- `create_nic_roma_user.py`

**Acceptance Criteria:**
- [ ] Patient record created with static UUID
- [ ] Auth user created and confirmed
- [ ] Linked to Sarah Thompson therapist
''',
                'estimate': 2
            },
            {
                'title': 'ACP-121: Seed Winter Lift 3x/week program (SQL)',
                'description': '''Create normalized Winter Lift program in database.

**Structure:**
- 1 Program (12 weeks, 3 phases)
- 3 Phases (4 weeks each: Foundation, Build, Intensify)
- 9 Sessions (3 per phase: Anterior Chain, Combo, Posterior Chain)
- ~120 exercises across all sessions

**Files:**
- `supabase/migrations/20251213000003_seed_winter_lift_program.sql`

**Challenges:**
- Map "blocks" to session_exercises (add block_number column)
- Create missing exercise templates
- Map nested JSON structure to normalized tables

**Acceptance Criteria:**
- [ ] Program created with 3 phases
- [ ] 9 sessions created with correct weekday mapping
- [ ] All exercises linked to templates
- [ ] Metadata JSON stored in programs.metadata
''',
                'estimate': 5
            },
            {
                'title': 'ACP-122: Add Winter Lift as Therapy Protocol template',
                'description': '''Add "Winter Lift 3x/week" to Protocol.swift for UI selection.

**Tasks:**
- Define 3 phases with progression criteria
- Add ProtocolPhaseConstraints struct
- Include in sampleProtocols array
- Add to Program Builder dropdown

**Files:**
- `ios-app/PTPerformance/Models/Protocol.swift`

**Acceptance Criteria:**
- [ ] winterLift protocol defined with 3 phases
- [ ] Progression criteria specified per phase
- [ ] Constraints include RPE ranges and intensity limits
- [ ] Visible in Program Builder UI
''',
                'estimate': 3
            },
            {
                'title': 'ACP-123: Store program JSON in metadata column',
                'description': '''Store complete Winter Lift JSON structure in programs.metadata for archival.

**Implementation:**
- Update programs.metadata with full JSON from spec
- Include phases, days, blocks, modules, progression_layer

**Benefit:** Preserves original structure for export/templates

**Files:**
- Part of SQL seed migration

**Acceptance Criteria:**
- [ ] Full JSON stored in programs.metadata
- [ ] JSON includes all blocks, warmups, arm care modules
- [ ] progression_layer rules stored
''',
                'estimate': 1
            }
        ]

        # Build 38 Issues (Progression Layer)
        build38_issues = [
            {
                'title': 'ACP-124: Add progression database schema',
                'description': '''Create database tables for load progression and deload tracking.

**Tables:**
- `load_progression_history` - Session-to-session load tracking
- `deload_history` - Deload events with trigger tracking
- `deload_triggers` - Rolling window trigger evaluation
- `phase_advancement_log` - Phase gate tracking

**Files:**
- `supabase/migrations/20251214000001_add_progression_schema.sql`

**Acceptance Criteria:**
- [ ] 4 tables created with proper indexes
- [ ] Foreign keys to patients, programs, phases
- [ ] Check constraints on enums and ranges
''',
                'estimate': 3
            },
            {
                'title': 'ACP-125: Create Swift models for progression',
                'description': '''Implement Swift models for load progression and deload.

**Models:**
- LoadProgressionHistory, ProgressionAction, ProgressionCalculator
- DeloadEvent, DeloadTrigger, DeloadStatus
- PhaseAdvancement

**Files:**
- `ios-app/PTPerformance/Models/LoadProgression.swift`
- `ios-app/PTPerformance/Models/DeloadEvent.swift`
- `ios-app/PTPerformance/Models/PhaseAdvancement.swift`

**Acceptance Criteria:**
- [ ] Models match database schema with CodingKeys
- [ ] ProgressionCalculator implements RPE-based logic
- [ ] Enums defined for actions and statuses
''',
                'estimate': 3
            },
            {
                'title': 'ACP-126: Implement ProgressionService',
                'description': '''Service layer for load progression algorithms and deload logic.

**Features:**
- Calculate next load based on RPE feedback
- Evaluate deload triggers (7-day rolling window)
- Schedule deload when ≥2 trigger types fire
- Track progression history

**Algorithm:**
- RPE ≤ target_high - 0.5 → increase load
- RPE within range → hold load
- RPE > target_high + 0.5 → decrease 5%

**Files:**
- `ios-app/PTPerformance/Services/ProgressionService.swift`

**Acceptance Criteria:**
- [ ] recordProgression() inserts to load_progression_history
- [ ] evaluateDeloadTriggers() checks 7-day window
- [ ] scheduleDeload() creates deload_history record
- [ ] Triggers marked as resolved after deload
''',
                'estimate': 5
            }
        ]

        # Build 39 Issues (Readiness System)
        build39_issues = [
            {
                'title': 'ACP-127: Add readiness database schema',
                'description': '''Create tables for daily readiness tracking and workout modifications.

**Tables:**
- `daily_readiness` - Daily check-in data (sleep, HRV, pain, etc.)
- `readiness_modifications` - Applied workout adjustments
- `hrv_baseline` - 7-day rolling HRV baseline

**Files:**
- `supabase/migrations/20251215000001_add_readiness_schema.sql`

**Acceptance Criteria:**
- [ ] 3 tables created with proper constraints
- [ ] UNIQUE constraint on (patient_id, check_in_date)
- [ ] Readiness band enum (green/yellow/orange/red)
''',
                'estimate': 3
            },
            {
                'title': 'ACP-128: Create Swift models for readiness',
                'description': '''Implement Swift models for daily readiness and bands.

**Models:**
- DailyReadiness, ReadinessBand (green/yellow/orange/red)
- ReadinessInput, JointPainLocation

**Band Logic:**
- Green: Full prescription (0% adjustment)
- Yellow: -7% load, -20% volume
- Orange: Skip top set, -35% volume
- Red: Technique only (-100% load)

**Files:**
- `ios-app/PTPerformance/Models/DailyReadiness.swift`

**Acceptance Criteria:**
- [ ] ReadinessBand enum with color/description/adjustments
- [ ] DailyReadiness model with all input fields
- [ ] ReadinessInput for form submission
''',
                'estimate': 3
            },
            {
                'title': 'ACP-129: Implement ReadinessService',
                'description': '''Service for readiness band calculation and workout modifications.

**Features:**
- Weighted scoring algorithm (sleep 30%, HRV 20%, WHOOP 20%, subjective 15%, pain 15%)
- Auto-red band if joint pain present
- Apply load/volume modifications to exercises

**Calculation Logic:**
- Start at 100 points
- Deduct points based on inputs
- Map score to band (≥85=green, ≥70=yellow, ≥50=orange, <50=red)
- Override to red if any joint pain

**Files:**
- `ios-app/PTPerformance/Services/ReadinessService.swift`

**Acceptance Criteria:**
- [ ] submitDailyReadiness() calculates band and saves
- [ ] calculateReadinessBand() implements weighted scoring
- [ ] applyReadinessModifications() adjusts exercise loads
''',
                'estimate': 5
            },
            {
                'title': 'ACP-130: Build Daily Check-in UI',
                'description': '''SwiftUI view for daily readiness check-in.

**Features:**
- Sleep hours + quality sliders
- Subjective readiness picker (1-5 scale)
- Arm soreness + joint pain toggles
- Real-time readiness band preview with color
- Pain notes text field

**Files:**
- `ios-app/PTPerformance/Views/Patient/DailyReadinessCheckInView.swift`

**Acceptance Criteria:**
- [ ] Form with all readiness inputs
- [ ] Live preview of readiness band
- [ ] Color-coded band indicator
- [ ] Save button calls ReadinessService
- [ ] Validation and error handling
''',
                'estimate': 5
            }
        ]

        # Build 40 Issues (WHOOP Integration - Optional)
        build40_issues = [
            {
                'title': 'ACP-131: WHOOP OAuth integration',
                'description': '''Implement WHOOP API OAuth 2.0 flow.

**Features:**
- Authorization URL generation
- Code exchange for access token
- Token refresh logic
- Scopes: read:recovery, read:sleep, read:cycles

**Files:**
- `ios-app/PTPerformance/Services/WHOOPService.swift`

**Acceptance Criteria:**
- [ ] getAuthorizationURL() returns WHOOP OAuth URL
- [ ] exchangeCodeForToken() exchanges code for tokens
- [ ] Token storage and refresh implemented
''',
                'estimate': 3
            },
            {
                'title': 'ACP-132: WHOOP data fetching',
                'description': '''Fetch recovery, sleep, and HRV data from WHOOP API.

**Models:**
- WHOOPRecovery, WHOOPSleep, WHOOPAccessToken
- Auto-populate readiness inputs from WHOOP data

**Integration:**
- Convert WHOOP recovery % to readiness input
- Convert sleep performance to sleep quality (1-5)
- Extract HRV value for baseline tracking

**Acceptance Criteria:**
- [ ] fetchTodayRecovery() gets latest recovery data
- [ ] fetchTodaySleep() gets latest sleep data
- [ ] Integration with ReadinessService
- [ ] Fallback to manual entry if WHOOP unavailable
''',
                'estimate': 3
            }
        ]

        # Create all issues
        all_created = []

        print('\n📝 Creating Build 37 Issues (Patient + Program)...')
        for issue_data in build37_issues:
            issue = await client.create_issue(
                team_id=team_id,
                title=issue_data['title'],
                description=issue_data['description'],
                parent_id=epic['id'],
                estimate=issue_data['estimate']
            )
            all_created.append(issue)
            print(f'  ✅ {issue["identifier"]}: {issue["title"][:60]}')

        print('\n📝 Creating Build 38 Issues (Progression Layer)...')
        for issue_data in build38_issues:
            issue = await client.create_issue(
                team_id=team_id,
                title=issue_data['title'],
                description=issue_data['description'],
                parent_id=epic['id'],
                estimate=issue_data['estimate']
            )
            all_created.append(issue)
            print(f'  ✅ {issue["identifier"]}: {issue["title"][:60]}')

        print('\n📝 Creating Build 39 Issues (Readiness System)...')
        for issue_data in build39_issues:
            issue = await client.create_issue(
                team_id=team_id,
                title=issue_data['title'],
                description=issue_data['description'],
                parent_id=epic['id'],
                estimate=issue_data['estimate']
            )
            all_created.append(issue)
            print(f'  ✅ {issue["identifier"]}: {issue["title"][:60]}')

        print('\n📝 Creating Build 40 Issues (WHOOP Integration)...')
        for issue_data in build40_issues:
            issue = await client.create_issue(
                team_id=team_id,
                title=issue_data['title'],
                description=issue_data['description'],
                parent_id=epic['id'],
                estimate=issue_data['estimate']
            )
            all_created.append(issue)
            print(f'  ✅ {issue["identifier"]}: {issue["title"][:60]}')

        # Summary
        total_points = sum(i['estimate'] for i in build37_issues + build38_issues + build39_issues + build40_issues)

        print('\n' + '=' * 80)
        print('✅ LINEAR ISSUES CREATED')
        print('=' * 80)
        print(f'Epic: {epic["identifier"]} - {epic["title"]}')
        print(f'Total Issues: {len(all_created)}')
        print(f'Total Story Points: {total_points}')
        print()
        print('Build Breakdown:')
        print(f'  Build 37 (Patient + Program): {len(build37_issues)} issues, {sum(i["estimate"] for i in build37_issues)} points')
        print(f'  Build 38 (Progression): {len(build38_issues)} issues, {sum(i["estimate"] for i in build38_issues)} points')
        print(f'  Build 39 (Readiness): {len(build39_issues)} issues, {sum(i["estimate"] for i in build39_issues)} points')
        print(f'  Build 40 (WHOOP): {len(build40_issues)} issues, {sum(i["estimate"] for i in build40_issues)} points')


if __name__ == '__main__':
    asyncio.run(main())
