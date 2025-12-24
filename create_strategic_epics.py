#!/usr/bin/env python3
"""Create 10 Strategic Epics for PT Performance Competitive Strategy (Q1-Q2 2025)

These epics map to the BridgeAthletic competitive strategy and Phase-1 MVP Kill-Matrix.
"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, priority=2, labels=None):
    """Create a Linear issue (epics are created as regular issues with epic label)"""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
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

    input_data = {
        "teamId": ACP_TEAM_ID,
        "title": title,
        "description": description,
        "priority": priority
    }

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {"input": input_data}
        },
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueCreate", {}).get("success"):
                issue = data["data"]["issueCreate"]["issue"]
                return issue
            else:
                print(f"  Error: {data}")
        except Exception as e:
            print(f"  Error parsing response: {e}")
            print(f"  Response: {response.text}")
    else:
        print(f"  HTTP {response.status_code}: {response.text}")
    return None

print("="*80)
print("Creating 10 Strategic Epics for PT Performance (Q1-Q2 2025)")
print("="*80)
print()

epics = [
    {
        "title": "EPIC-01: AI-Driven Program Intelligence Layer",
        "description": """**Strategic Priority:** 🔴 High - Phase 2 (Q2 2025)
**Builds:** Build 81

## Overview
AI-powered program generation that reduces PT authoring time by 50%+ while maintaining medical authority and evidence-based protocols.

## Core Features
- AI suggests complete programs from injury diagnosis + patient profile
- PT reviews and approves (not fully automated)
- Evidence citations for every exercise selection
- One-click deployment to patient
- Learning from PT edits (feedback loop)
- Contraindication logic (injury-aware)

## Competitive Advantage
**vs BridgeAthletic:** They have manual authoring templates, we have AI-assisted generation with medical context awareness
**vs VOLT:** They have generic algorithms, we have injury-specific intelligence

## Success Metrics
- 80%+ program generation accuracy
- 50%+ PT authoring time reduction
- 90%+ PT review approval rate (minimal edits needed)
- 100% evidence-based exercise selection

## Implementation
- **Backend:** OpenAI/Anthropic API integration with custom training
- **Frontend:** Program review and approval workflow
- **Database:** Program templates, exercise contraindications, evidence library

## Related Issues
- Build 81: ACP-316 through ACP-330 (15 issues)

## Status
📋 Planned for Q2 2025
""",
        "priority": 1  # Urgent
    },
    {
        "title": "EPIC-02: Return-to-Play Intelligence",
        "description": """**Strategic Priority:** 🔴 High - Phase 1 (Q1 2025)
**Builds:** Build 75, Build 80

## Overview
Medical authority layer that bridges injury → rehab → performance continuum. Core differentiator vs Physitrack (stops at rehab) and BridgeAthletic (starts at healthy athletes).

## Core Features
### Build 75 - RTP Protocols (10 Injuries)
1. ACL reconstruction (6-9 month protocol)
2. Ankle sprain (4-6 week protocol)
3. Rotator cuff repair (12-16 week protocol)
4. Achilles tendinopathy (8-12 week protocol)
5. Meniscus repair (6-8 week protocol)
6. Hamstring strain (4-8 week protocol)
7. Patellar tendinopathy (8-12 week protocol)
8. Labral repair (shoulder, 12-16 week protocol)
9. Groin strain (4-6 week protocol)
10. Chronic ankle instability (8-12 week protocol)

### Build 80 - PT → S&C Handoff Workflow
- Medical clearance workflow (PT signs off before S&C)
- Handoff checklist (ROM, strength, pain-free criteria)
- Graduated loading progression (rehab → strength → power → sport)
- Return-to-sport readiness scoring (0-100 scale)
- Shared visibility (PT sees S&C program, S&C sees rehab history)
- Bi-directional communication (PT ↔ S&C)

## Competitive Advantage
**vs Physitrack:** They stop at rehab exercises, we bridge to elite performance
**vs BridgeAthletic:** They start at healthy athletes, we own the injury recovery market
**vs VOLT:** No injury-specific intelligence

## Success Metrics
- 15%+ faster time-to-clearance
- 25%+ re-injury rate reduction
- 90%+ PT satisfaction with protocols
- 100% of protocols evidence-based
- 100% clearance decisions documented
- 90%+ S&C coaches use handoff checklist

## Status
📋 Build 75 planned for Q1 2025
📋 Build 80 planned for Q1 2025
""",
        "priority": 1  # Urgent
    },
    {
        "title": "EPIC-03: Readiness & Auto-Regulation Engine",
        "description": """**Strategic Priority:** 🔴 High - Phase 1 (Q1 2025)
**Builds:** Build 72 (IN PROGRESS), Build 76

## Overview
Proactive load management that automatically adjusts workouts based on daily readiness. Category-defining feature that beats VOLT on adaptivity depth.

## Core Features
### Build 72 - Readiness-Based Auto-Adjustment ✅ IN PROGRESS
- Daily readiness bands (Green/Yellow/Orange/Red)
- Smart workout adjustment algorithm:
  - Green: No adjustment
  - Yellow: -10% load OR -1 set
  - Orange: -20% load AND -1 set
  - Red: Rest day or active recovery
- Practitioner override and lock controls
- AI explanations for adjustments
- Full audit trail for compliance

### Build 76 - Daily Habit Loop & Streaks
- Daily readiness check-in reminder (push notification)
- "Your workout is ready" personalized notification
- Streak tracking (consecutive days, with recovery credit)
- Visual progress indicators (circular progress, badges)
- Weekly consistency score
- Milestone celebrations (10/30/90 day badges)
- Recovery day credit (doesn't break streak)

## Competitive Advantage
**vs VOLT:** They have generic auto-regulation, we have medical-context-aware adaptation
**vs Peloton:** They have instructor dependency, we have algorithmic engagement + medical authority

## Success Metrics
### Build 72
- 80%+ auto-adjustment adoption
- <20% practitioner override rate
- 95%+ patient satisfaction with adjustments
- Zero unsafe progressions

### Build 76
- 70%+ daily active usage (vs Peloton's 65%)
- 50%+ users maintain 7+ day streak
- 30%+ users reach 30-day milestone
- 5%+ users reach 90-day milestone

## Status
🏗️ Build 72 IN PROGRESS (ACP-209 through ACP-224)
📋 Build 76 Planned for Q1 2025
""",
        "priority": 1  # Urgent
    },
    {
        "title": "EPIC-04: Parity - Program Builder & Periodization",
        "description": """**Strategic Priority:** 🟡 Medium - Phase 2 (Q2 2025)
**Builds:** Build 77

## Overview
Table stakes program builder with universal block-based logging across all training modalities. Match BridgeAthletic features + add intelligent automation.

## Core Features
### Build 77 - Universal Block-Based Logging System
- **Canonical Block Programming Architecture** (ptos.cards.v1)
  - Session → Blocks → Items (sets, intervals, throws, swings, poses)
  - Event-driven logging (ptos.events.v1)
  - Adaptive Card rendering for all modalities

- **8 Block Types (Universal Coverage):**
  1. Strength / Power Set Block
  2. Conditioning / Endurance Block
  3. Skill / Technique Block (baseball, jump rope, Olympic lifting)
  4. Mobility / Yoga Block
  5. Throwing Block (bullpen, long toss, plyos, pulldowns)
  6. Hitting Block (tee, BP, live ABs, cage)
  7. Vision / Reaction / Hand-eye Block
  8. Recovery Block (sauna, cold plunge, breathwork, RLT)

- **iPhone Fast-Logging UX:**
  - Flow A: 1-tap completion (1-2 seconds per block)
  - Flow B: Voice logging during workout
  - Flow C: Manual ultra-fast corrections (+5/-5 load, +1/-1 reps)
  - Flow D: Baseball real-time (pitch mix counters)
  - Flow E: Quick add unplanned work (<5 seconds)

- **Specialized Templates:**
  - Bullpen quick log
  - Long toss / Plyoballs
  - Murph (with auto comparison)
  - Hyrox (station times)
  - Vision / Hand-eye drills

## Competitive Advantage
**vs BridgeAthletic:** Match set/rep/load granularity + add AI adaptation
**vs TrainHeroic/KOT:** Universal modality coverage (not just strength)
**vs VOLT:** Faster logging, better UX, voice integration

## Success Metrics
- <10 seconds per block logged (average)
- 90%+ blocks logged with 1-tap completion
- 80%+ user satisfaction with logging speed
- Voice logging accuracy >85% (phase 2)
- Zero modality fragmentation (same UX for yoga + baseball)

## Status
📋 Planned for Q1 2025 (ACP-276 to ACP-283)
""",
        "priority": 2  # High
    },
    {
        "title": "EPIC-05: Parity - Athlete Assignment & Delivery",
        "description": """**Strategic Priority:** 🟡 Medium - Phase 2 (Q2 2025)
**Builds:** Build 82

## Overview
Team management at scale. Required for institutional adoption (collegiate programs, professional teams).

## Core Features
- Team roster management (tags, cohorts)
- Bulk program assignment (one-to-many)
- Multi-athlete dashboard
- Filtering and search
- Team analytics (compliance, injury rates)
- Export capabilities

## Competitive Advantage
**vs BridgeAthletic:** Match their scale capabilities + add medical status tracking (injury phase, return-to-play stage)

## Success Metrics
- <5 minutes to onboard 50 athletes
- 90%+ feature parity with BridgeAthletic team management
- Support for 500+ athletes per team

## Status
📋 Planned for Q2 2025 (ACP-331 to ACP-338)
""",
        "priority": 2  # High
    },
    {
        "title": "EPIC-06: Intelligent Exercise Library",
        "description": """**Strategic Priority:** 🟡 Medium - Phase 1 (Q1 2025)
**Builds:** Build 74

## Overview
Video-first exercise library with medical intelligence layer. Table stakes + help system for patient education.

## Core Features
### Video Library (500+ exercises)
- 500+ exercise video demonstrations
- Video categorization (body region, equipment, difficulty)
- Offline video caching
- Quality selection (720p, 1080p)
- Video search and filtering
- Slow-motion playback

### In-App Help System
- 4 core patient-facing articles:
  1. Getting Started: How to Begin Your Performance Program
  2. Programs: Understanding Your Training Plan
  3. Workouts: How to Complete and Log Training Sessions
  4. Analytics: Tracking Progress and Recovery
- Searchable help interface
- Context-aware help suggestions

### Medical Intelligence
- Injury-aware exercise catalog
- Contraindication logic
- Evidence citations for each exercise
- Progression/regression pathways

## Content Strategy
- Phase 1: License existing libraries (ATG, FRC, Functional Movement Systems) - 200 videos
- Phase 2: Create custom clinical videos with PTs - 200 videos
- Phase 3: User-generated content review - 100+ videos

## Competitive Advantage
**vs BridgeAthletic:** Match video library + add contraindication intelligence
**vs Physitrack:** Better video production quality, more comprehensive coverage

## Success Metrics
- 60%+ exercise completion with video reference
- 500+ videos available by Q1 end
- <5MB average video size (compressed)
- Offline caching works seamlessly
- 80%+ help article search success rate
- <3 seconds to find help article

## Status
📋 Planned for Q1 2025 (ACP-243 to ACP-250)
""",
        "priority": 2  # High
    },
    {
        "title": "EPIC-07: Pain Interpretation & Safety System",
        "description": """**Strategic Priority:** 🔴 High - Phase 1 (Q1 2025)
**Builds:** Build 73

## Overview
Medical-grade safety layer that prevents unsafe progressions. Category-defining feature that BridgeAthletic cannot replicate.

## Core Features
### Workload Monitoring
- Workload spike detection (>25% weekly volume increase)
- ACWR monitoring (flag if >1.5 or <0.8)
- Monotony detection (low training variety)

### Pain & Safety Alerts
- Pain-severity alerts (automatic PT notification on pain ≥7/10)
- Push notifications for high-severity flags
- Practitioner alert dashboard
- Automated workout modification on pain flags

### Audit & Compliance
- Full audit trail for all safety events
- Liability protection documentation
- Medical-grade event logging

## Competitive Advantage
**vs BridgeAthletic:** They have passive feedback forms, we have active medical-grade alerts
**vs VOLT:** No pain interpretation layer
**vs Physitrack:** Match safety focus + add predictive analytics

## Success Metrics
- 95%+ pain flagging accuracy
- 90%+ workload flag accuracy
- <1 hour PT notification latency
- 30%+ injury rate reduction (vs baseline)
- Zero unsafe progressions

## Status
📋 Next after Build 72 (ACP-225 to ACP-242)
""",
        "priority": 1  # Urgent
    },
    {
        "title": "EPIC-08: Analytics & Predictive Intelligence",
        "description": """**Strategic Priority:** 🟢 Lower - Phase 3 (Q3 2025)
**Builds:** Build 81 (Q2 kickoff)

## Overview
Shift from reactive to predictive care. Clinical decision support layer that BridgeAthletic deliberately avoids.

## Core Features
- Volume load tracking (tonnage + predictive injury risk modeling)
- Attendance & adherence (compliance + recovery adherence scoring)
- Trend visualization with predictive insights
- Actionable recommendations
- Clinical decision support alerts

## Competitive Advantage
**vs BridgeAthletic:** They deliberately avoid predictive analytics, we embrace it with medical context

## Success Metrics
- Injury prediction accuracy: 70%+
- Time-to-clearance reduction: 15%+
- Multi-role adoption: 80%+

## Status
📋 Deferred to Q3 2025 (Phase 3)
""",
        "priority": 3  # Normal
    },
    {
        "title": "EPIC-09: Collaboration & Communication Hub",
        "description": """**Strategic Priority:** 🟢 Lower - Phase 3 (Q3 2025)
**Builds:** Build 83

## Overview
Multi-role care team coordination. Beyond 1:1 PT-patient, into PT-MD-Coach-AT workflows.

## Core Features
- Multi-role messaging (PT/MD/Coach/AT)
- Care team coordination workflows
- Shared care plans
- Role-based permissions
- Team dashboards

## Competitive Advantage
**vs BridgeAthletic:** They have coach-athlete only, we have full care team
**vs Physitrack:** Match care team features + add performance context

## Success Metrics
- Multi-role adoption: 80%+
- Care team collaboration events tracked

## Status
📋 Deferred to Q3 2025 (Phase 3)
""",
        "priority": 3  # Normal
    },
    {
        "title": "EPIC-10: Video Intelligence & Form Analysis",
        "description": """**Strategic Priority:** ⚪ Future - Phase 4 (Q4 2025)
**Builds:** Build 86-87

## Overview
Cutting-edge computer vision capabilities. Future innovation layer.

## Core Features
- Computer vision form analysis
- Movement quality scoring
- Real-time coaching feedback
- Normative data comparison

## Competitive Advantage
**vs All Competitors:** Cutting-edge capability, not yet available in market

## Success Metrics
- Form analysis accuracy: 80%+
- Movement quality correlation with injury risk

## Status
📋 Deferred to Q4 2025 (Phase 4) - Research & Explore
""",
        "priority": 4  # Low
    }
]

created_epics = []

for epic_data in epics:
    print(f"Creating: {epic_data['title']}")
    epic = create_issue(
        epic_data["title"],
        epic_data["description"],
        epic_data["priority"]
    )

    if epic:
        print(f"  ✅ Created: {epic['identifier']}")
        print(f"     URL: {epic['url']}")
        created_epics.append(epic)
    else:
        print(f"  ❌ Failed to create epic")
    print()

print("="*80)
print("Strategic Epics Created")
print("="*80)
print()
print("Summary:")
for epic in created_epics:
    print(f"  • {epic['identifier']}: {epic['title']}")
print()
print(f"Total epics created: {len(created_epics)}/10")
print()
print("Next Steps:")
print("1. Run create_q1_2025_issues.py to batch create Q1 issues (ACP-209 to ACP-315)")
print("2. Run create_q2_2025_issues.py to batch create Q2 issues (ACP-316 to ACP-415)")
print("3. Verify all epics visible at: https://linear.app/x2machines/team/ACP")
print()
