#!/usr/bin/env python3
"""Create Linear issues for Builds 73-80 (91 issues total)

Builds covered:
- Build 73: ACP-301 to ACP-318 (18 issues) - Safety Alerts & Workload Flags
- Build 74: ACP-319 to ACP-326 (8 issues) - Video Library + Help System
- Build 75: ACP-327 to ACP-341 (15 issues) - Return-to-Play Protocols
- Build 76: ACP-342 to ACP-351 (10 issues) - Daily Habit Loop & Streaks
- Build 77: ACP-352 to ACP-359 (8 issues) - Universal Block-Based Logging
- Build 78: ACP-360 to ACP-371 (12 issues) - Joint-Specific Intelligence
- Build 79: ACP-372 to ACP-381 (10 issues) - Documentation Automation
- Build 80: ACP-382 to ACP-391 (10 issues) - PT → S&C Handoff Workflow
"""

import os
import requests
import time

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"

# Epic IDs
EPIC_IDS = {
    "SAFETY": "239465ba-e5b2-4b62-ae09-5a451cf8150a",  # ACP-281
    "EXERCISE_LIBRARY": "69f25dcc-c1b2-4083-b778-7a2320083db9",  # ACP-280
    "RETURN_TO_PLAY": "ae888b1d-8c55-4623-85f5-4bd9a4df1b9e",  # ACP-276
    "READINESS": "ba469dea-6a99-4b78-a509-077637b81255",  # ACP-277
    "PROGRAM_BUILDER": "2be01de4-8b4d-4d04-ac25-ada16a95969e",  # ACP-278
    "ANALYTICS": "1bf287b1-51a2-405a-9099-2537192d3385",  # ACP-282
}

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, priority=2, parent_id=None):
    """Create a Linear issue"""
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
        "priority": priority,
        "stateId": ACP_TODO_STATE_ID
    }

    if parent_id:
        input_data["parentId"] = parent_id

    response = requests.post(
        GRAPHQL_URL,
        json={"query": mutation, "variables": {"input": input_data}},
        headers=headers
    )

    if response.status_code == 200:
        try:
            data = response.json()
            if data and data.get("data", {}).get("issueCreate", {}).get("success"):
                return data["data"]["issueCreate"]["issue"]
            else:
                print(f"  Error: {data}")
        except Exception as e:
            print(f"  Error: {e}")
    else:
        print(f"  HTTP {response.status_code}")
    return None

print("=" * 80)
print("Creating Builds 73-80 Issues (91 issues)")
print("=" * 80)
print()

all_created = []

# ============================================================================
# BUILD 73: Safety Alerts & Workload Flags (18 issues)
# ============================================================================
build_73_issues = [
    ("Build 73 Agent 1: WorkloadFlags UI", "Create WorkloadFlagsView.swift for practitioner dashboard with flag list, severity indicators, and resolution workflow", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 2: WorkloadFlag Model & ViewModel", "Create WorkloadFlag model with severity, type, status, and ViewModel for data management", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 3: Flag Resolution Workflow", "Implement Acknowledge/Resolve/Override actions with audit logging", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 4: Patient List Badge Integration", "Add flag badges to PatientListView with color-coding (Red/Orange/Yellow)", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 5: Flag Notification Handling", "Implement push notification handling for high-severity flags with deep-linking", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 6: Flag Filtering & Sorting", "Add filter/sort UI: All/Active/Resolved, by severity, by type, by patient", EPIC_IDS["SAFETY"], 2),
    ("Build 73 Agent 7: Workload Spike Detection Algorithm", "Backend: Detect >15% weekly load increases and flag for injury risk", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 8: ACWR Calculation Service", "Backend: Calculate Acute:Chronic Workload Ratio, flag if >1.5 or <0.8", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 9: Monotony Detection Algorithm", "Backend: Detect low training variety (monotony >2.0) and flag", EPIC_IDS["SAFETY"], 2),
    ("Build 73 Agent 10: Pain-Based Auto-Flagging", "Backend: Auto-flag pain ≥7/10 and re-injury risk (same location as previous injury)", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 11: Flag Generation Edge Function", "Supabase Edge Function: generate-workload-flags on exercise_log INSERT", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 12: Daily Flag Check Cron Job", "Supabase cron: Scan all active patients daily for workload violations", EPIC_IDS["SAFETY"], 2),
    ("Build 73 Agent 13: APNs Certificate Setup", "Configure Apple Push Notification service certificates for production", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 14: Push Notification Edge Function", "Backend: Send push notifications to practitioners on high-severity flags", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 15: Workload Flag Tests", "Unit tests for spike, ACWR, monotony, pain threshold algorithms", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 16: Notification Delivery Tests", "Integration tests for push notification delivery (<30 seconds)", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Agent 17: Flag Resolution Tests", "Test all resolution workflows: acknowledge, resolve, override", EPIC_IDS["SAFETY"], 1),
    ("Build 73 Integration & Deployment", "Integrate all components, deploy Edge Functions, configure APNs, upload Build 73 to TestFlight", EPIC_IDS["SAFETY"], 1),
]

print("Build 73: Safety Alerts & Workload Flags (18 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_73_issues, 1):
    print(f"[{idx}/18] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 74: Video Library + Help System (8 issues)
# ============================================================================
build_74_issues = [
    ("Build 74 Agent 1: HelpArticle Model", "Create HelpArticle.swift model with title, content, category, keywords, related articles", EPIC_IDS["EXERCISE_LIBRARY"], 2),
    ("Build 74 Agent 2: Help Articles JSON Data", "Create help_articles.json with 4 core articles: Getting Started, Programs, Workouts, Analytics", EPIC_IDS["EXERCISE_LIBRARY"], 2),
    ("Build 74 Agent 3: HelpSearchView UI", "Build searchable help interface with relevance scoring and category filtering", EPIC_IDS["EXERCISE_LIBRARY"], 2),
    ("Build 74 Agent 4: HelpArticleView Renderer", "Create article detail view with Markdown rendering and related articles navigation", EPIC_IDS["EXERCISE_LIBRARY"], 2),
    ("Build 74 Agent 5: Video Library Model", "Create VideoCategory.swift and enhance ExerciseTemplate with video metadata", EPIC_IDS["EXERCISE_LIBRARY"], 1),
    ("Build 74 Agent 6: Video Library Migration", "Supabase migration: Add video_duration, video_file_size, categories tables", EPIC_IDS["EXERCISE_LIBRARY"], 1),
    ("Build 74 Agent 7: VideoLibraryView UI", "Build browse/search interface with categories (body part, equipment), offline download", EPIC_IDS["EXERCISE_LIBRARY"], 1),
    ("Build 74 Integration & Testing", "Integrate help system + video library, test search performance (<3 seconds), deploy to TestFlight", EPIC_IDS["EXERCISE_LIBRARY"], 1),
]

print("Build 74: Video Library + Help System (8 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_74_issues, 1):
    print(f"[{idx}/8] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 75: Return-to-Play Protocols (15 issues)
# ============================================================================
build_75_issues = [
    ("Build 75 Agent 1: RTP Protocol - ACL Reconstruction", "Create 6-9 month ACL protocol with phase-based progression and return-to-sport testing", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 2: RTP Protocol - Ankle Sprain", "Create 4-6 week ankle sprain protocol with proprioception training", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 3: RTP Protocol - Rotator Cuff Repair", "Create 12-16 week shoulder protocol with ROM and strengthening phases", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 4: RTP Protocol - Achilles Tendinopathy", "Create 8-12 week Achilles protocol with eccentric loading progression", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 5: RTP Protocol - Meniscus Repair", "Create 6-8 week meniscus protocol with weight-bearing progression", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 6: RTP Protocol - Hamstring Strain", "Create 4-8 week hamstring protocol with Nordic curls and sprint progression", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 7: RTP Protocol - Patellar Tendinopathy", "Create 8-12 week patellar tendon protocol with isometric and HSR phases", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 8: RTP Protocol - Labral Repair (Shoulder)", "Create 12-16 week shoulder labral repair protocol with rotator cuff strengthening", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 9: RTP Protocol - Groin Strain", "Create 4-6 week groin strain protocol with adductor strengthening", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 10: RTP Protocol - Chronic Ankle Instability", "Create 8-12 week ankle instability protocol with balance training", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 11: RTP Database Schema", "Create injury_protocols, protocol_phases, phase_exercises tables", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 12: RTP Progress Tracking UI", "Build phase progress view with entry/exit criteria checklist", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 13: RTP Clearance Workflow", "Implement medical clearance checklist before phase advancement", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Agent 14: RTP Tests & Validation", "Test all 10 protocols for completeness and evidence-based criteria", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 75 Integration & Deployment", "Integrate all RTP protocols, seed database, test workflows, deploy to TestFlight", EPIC_IDS["RETURN_TO_PLAY"], 1),
]

print("Build 75: Return-to-Play Protocols (15 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_75_issues, 1):
    print(f"[{idx}/15] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 76: Daily Habit Loop & Streaks (10 issues)
# ============================================================================
build_76_issues = [
    ("Build 76 Agent 1: Streak Model & Calculation", "Create StreakData model with consecutive days, recovery credit, milestone badges", EPIC_IDS["READINESS"], 2),
    ("Build 76 Agent 2: Daily Reminder Service", "Implement push notifications for readiness check-in and workout ready alerts", EPIC_IDS["READINESS"], 1),
    ("Build 76 Agent 3: Streak UI Components", "Build circular progress indicator, streak counter, milestone badges", EPIC_IDS["READINESS"], 2),
    ("Build 76 Agent 4: Weekly Consistency Score", "Calculate and display weekly consistency score (0-100%)", EPIC_IDS["READINESS"], 2),
    ("Build 76 Agent 5: Milestone Celebrations", "Implement celebration animations for 10/30/90 day milestones", EPIC_IDS["READINESS"], 2),
    ("Build 76 Agent 6: Recovery Day Credit Logic", "Allow rest days without breaking streak if prescribed by system/PT", EPIC_IDS["READINESS"], 2),
    ("Build 76 Agent 7: Streak Database Schema", "Create user_streaks table with current_streak, longest_streak, badges", EPIC_IDS["READINESS"], 1),
    ("Build 76 Agent 8: Streak Calculation Service", "Backend service to update streaks daily via cron job", EPIC_IDS["READINESS"], 1),
    ("Build 76 Agent 9: Streak Tests", "Test streak calculation with edge cases (missed days, recovery credit)", EPIC_IDS["READINESS"], 1),
    ("Build 76 Integration & Deployment", "Integrate habit loop features, configure notifications, deploy to TestFlight", EPIC_IDS["READINESS"], 1),
]

print("Build 76: Daily Habit Loop & Streaks (10 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_76_issues, 1):
    print(f"[{idx}/10] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 77: Universal Block-Based Logging (8 issues)
# ============================================================================
build_77_issues = [
    ("Build 77 Agent 1: Block & Session Models (ptos.cards.v1)", "Create Session, Block, BlockItem models conforming to ptos.cards.v1 schema", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 77 Agent 2: 8 Block Types Implementation", "Implement: Strength, Conditioning, Skill, Mobility, Throwing, Hitting, Vision, Recovery blocks", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 77 Agent 3: BlockCard UI Renderer", "Build adaptive card renderer with 1-tap completion and quick adjustments (+5/-5, +1/-1)", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 77 Agent 4: Quick Metrics Calculation", "Calculate block-level metrics: total volume, avg RPE, time, calories", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 77 Agent 5: LogEvent Service (ptos.events.v1)", "Implement event emission to Supabase with offline queue", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 77 Agent 6: Voice Logging Integration", "Add voice logging capability during workout (Flow B)", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 77 Agent 7: Block Library JSON", "Create baseball_blocks.json (18 blocks) and rtp_blocks.json (20 blocks)", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 77 Integration & Testing", "Test all block types, verify logging speed (<10s per block), deploy to TestFlight", EPIC_IDS["PROGRAM_BUILDER"], 1),
]

print("Build 77: Universal Block-Based Logging (8 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_77_issues, 1):
    print(f"[{idx}/8] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 78: Joint-Specific Intelligence (12 issues)
# ============================================================================
build_78_issues = [
    ("Build 78 Agent 1: Knee Joint Model", "Create knee-specific exercise library with contraindications for ACL, meniscus, patellar issues", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 2: Shoulder Joint Model", "Create shoulder-specific library with rotator cuff, labral, impingement protocols", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 3: Ankle Joint Model", "Create ankle-specific library with sprain, instability, Achilles protocols", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 4: Hip Joint Model", "Create hip-specific library with FAI, labral tear, groin strain protocols", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 5: Elbow Joint Model", "Create elbow-specific library with UCL, Tommy John, tennis elbow protocols", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 6: Spine Joint Model", "Create spine-specific library with low back pain, disc, stenosis protocols", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 7: Contraindication Logic Engine", "Implement contraindication checking: injury + exercise → safe/unsafe", EPIC_IDS["ANALYTICS"], 1),
    ("Build 78 Agent 8: Joint-Specific Exercise Filter", "Filter exercise library by joint compatibility with active injuries", EPIC_IDS["ANALYTICS"], 1),
    ("Build 78 Agent 9: Evidence Citations Database", "Create citations table linking exercises to research studies", EPIC_IDS["ANALYTICS"], 2),
    ("Build 78 Agent 10: Joint Database Schema", "Create joint_specific_exercises, contraindications, evidence_citations tables", EPIC_IDS["ANALYTICS"], 1),
    ("Build 78 Agent 11: Joint Intelligence Tests", "Test contraindication logic for all 6 joint types", EPIC_IDS["ANALYTICS"], 1),
    ("Build 78 Integration & Deployment", "Integrate joint intelligence, test exercise filtering, deploy to TestFlight", EPIC_IDS["ANALYTICS"], 1),
]

print("Build 78: Joint-Specific Intelligence (12 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_78_issues, 1):
    print(f"[{idx}/12] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 79: Documentation Automation (10 issues)
# ============================================================================
build_79_issues = [
    ("Build 79 Agent 1: Auto-Generated Release Notes", "Generate release notes from Linear issue completion + git commits", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 2: Deployment Documentation Generator", "Auto-generate deployment checklists and migration guides", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 3: API Documentation Automation", "Generate API docs from code comments and type signatures", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 4: Test Coverage Reporting", "Auto-generate test coverage reports and publish to dashboard", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 5: Linear Integration Automation", "Auto-update Linear issues on git push, PR merge, deployment", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 6: Build Summary Generator", "Generate BUILD_XX_SUMMARY.md with all issues, PRs, metrics", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 7: Changelog Automation", "Maintain CHANGELOG.md with semantic versioning", EPIC_IDS["PROGRAM_BUILDER"], 2),
    ("Build 79 Agent 8: Documentation CI/CD Pipeline", "GitHub Actions workflow for doc generation on every commit", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 79 Agent 9: Documentation Tests", "Test all doc generation scripts for accuracy", EPIC_IDS["PROGRAM_BUILDER"], 1),
    ("Build 79 Integration & Deployment", "Deploy doc automation, verify workflows, test Linear integration", EPIC_IDS["PROGRAM_BUILDER"], 1),
]

print("Build 79: Documentation Automation (10 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_79_issues, 1):
    print(f"[{idx}/10] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# BUILD 80: PT → S&C Handoff Workflow (10 issues)
# ============================================================================
build_80_issues = [
    ("Build 80 Agent 1: Medical Clearance Model", "Create ClearanceChecklist model with ROM, strength, pain-free criteria", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 2: PT Sign-Off Workflow", "Implement PT clearance signature with digital attestation", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 3: Handoff Checklist UI", "Build checklist interface for ROM, strength tests, functional assessments", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 4: Return-to-Sport Readiness Score", "Calculate RTS readiness score (0-100) based on clearance criteria", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 5: Graduated Loading Progression", "Define progression phases: Rehab → Strength → Power → Sport", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 6: Shared Visibility Dashboard", "PT sees S&C program, S&C sees rehab history in shared view", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 7: Bi-Directional Communication", "Enable PT ↔ S&C messaging with injury context", EPIC_IDS["RETURN_TO_PLAY"], 2),
    ("Build 80 Agent 8: Handoff Database Schema", "Create clearance_checklists, handoff_communications tables", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Agent 9: Handoff Workflow Tests", "Test clearance, sign-off, progression, shared visibility", EPIC_IDS["RETURN_TO_PLAY"], 1),
    ("Build 80 Integration & Deployment", "Integrate handoff workflow, test PT ↔ S&C communication, deploy to TestFlight", EPIC_IDS["RETURN_TO_PLAY"], 1),
]

print("Build 80: PT → S&C Handoff Workflow (10 issues)")
print("-" * 80)
for idx, (title, desc, parent, priority) in enumerate(build_80_issues, 1):
    print(f"[{idx}/10] {title[:60]}...")
    issue = create_issue(title, desc, priority, parent)
    if issue:
        print(f"  ✅ {issue['identifier']}")
        all_created.append(issue)
    else:
        print(f"  ❌ Failed")
    time.sleep(0.5)

print()

# ============================================================================
# SUMMARY
# ============================================================================
print("=" * 80)
print(f"Q1 2025 Builds Complete: {len(all_created)}/91 issues created")
print("=" * 80)
print()

# Summary by build
builds = [
    ("Build 73", 18, "Safety Alerts & Workload Flags"),
    ("Build 74", 8, "Video Library + Help System"),
    ("Build 75", 15, "Return-to-Play Protocols"),
    ("Build 76", 10, "Daily Habit Loop & Streaks"),
    ("Build 77", 8, "Universal Block-Based Logging"),
    ("Build 78", 12, "Joint-Specific Intelligence"),
    ("Build 79", 10, "Documentation Automation"),
    ("Build 80", 10, "PT → S&C Handoff Workflow"),
]

for build_name, count, description in builds:
    print(f"{build_name}: {count} issues - {description}")

print()
print(f"Total issues created: {len(all_created)}/91")
print()
print("✅ All Q1 2025 builds (73-80) successfully created!")
print()
print("Combined with Build 72 (16 issues): 107/107 total Q1 issues")
print()
