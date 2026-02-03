#!/usr/bin/env python3
"""
Create 30 Health Intelligence Platform issues in Linear (Epics 8-12).
Parses PRODUCT_ROADMAP_HEALTH_INTELLIGENCE.md and creates issues in Linear.
"""

import asyncio
import os
import re
import sys
from pathlib import Path

# Add parent expo directory to path for linear_client
sys.path.insert(0, str(Path(__file__).parent.parent.parent / "Code/expo/scripts/linear"))
from linear_client import LinearClient

# Load .env from expo directory
env_path = Path(__file__).parent.parent.parent / "Code/expo/.env"
if env_path.exists():
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                os.environ[key] = value

# Configuration
TEAM_NAME = "Agent-Control-Plane"
PROJECT_NAME = "MVP 1 — PT App & Agent Pilot"

# Zone label mappings
ZONE_LABELS = {
    "zone-7": "Supabase/Database",
    "zone-8": "Edge Functions",
    "zone-12": "iOS",
    "zone-13": "Android",
}

# New epics for health intelligence (Epics 8-12)
HEALTH_EPICS = [
    {
        "title": "Epic 8: Health Intelligence Platform",
        "description": "Your labs, decoded for performance - Lab results PDF upload, biomarker tracking, and AI-powered analysis",
        "priority": 2,  # High
        "issues": [
            {"acp": "ACP-801", "title": "Lab Results PDF Upload & Parsing", "zone": "zone-12", "priority": 2,
             "description": "Enable athletes to upload Quest and Labcorp PDF lab results directly in the app. AI-powered OCR extracts biomarker values from common panels including CBC, CMP, lipid, thyroid, and hormone panels."},
            {"acp": "ACP-802", "title": "Biomarker Database & Reference Ranges", "zone": "zone-7", "priority": 2,
             "description": "Create comprehensive database schema for lab results with optimal ranges (not just clinical 'normal' ranges). Store trends over time and support multiple lab providers."},
            {"acp": "ACP-803", "title": "Biomarker Dashboard & Trends", "zone": "zone-12", "priority": 2,
             "description": "Visual dashboard showing key biomarkers with traffic light system (optimal/normal/concern). Historical trend charts enable athletes to track progress over time."},
            {"acp": "ACP-804", "title": "AI Lab Analysis & Recommendations", "zone": "zone-8", "priority": 2,
             "description": "AI analysis of lab results in context of training load, sleep patterns, and nutrition. Generates actionable recommendations for performance optimization."},
            {"acp": "ACP-805", "title": "Lab-Based Training Adjustments", "zone": "zone-8", "priority": 3,
             "description": "Automatically adjust training recommendations based on biomarker values. Low testosterone → reduce volume, high CRP → reduce intensity, low vitamin D → suggest outdoor training."},
            {"acp": "ACP-806", "title": "Ask Questions About Labs (AI Chat)", "zone": "zone-12", "priority": 2,
             "description": "Natural language Q&A interface for athletes to understand their lab results. Context-aware responses using patient history, training data, and nutrition logs."},
        ]
    },
    {
        "title": "Epic 9: Recovery Protocols",
        "description": "Science-backed recovery, tracked and optimized - Sauna, cold plunge, and contrast therapy tracking",
        "priority": 2,  # High
        "issues": [
            {"acp": "ACP-901", "title": "Sauna Session Tracking", "zone": "zone-12", "priority": 2,
             "description": "Log sauna sessions with type, duration, and temperature. Track frequency and total weekly minutes. Correlate with HRV and sleep improvements over time."},
            {"acp": "ACP-902", "title": "Cold Plunge/Ice Bath Tracking", "zone": "zone-12", "priority": 2,
             "description": "Log cold exposure sessions with temperature and duration. Include protocol recommendations from Huberman and Wim Hof. Track progressive cold adaptation."},
            {"acp": "ACP-903", "title": "Contrast Therapy Protocols", "zone": "zone-12", "priority": 3,
             "description": "Combined sauna and cold plunge protocols with guided sessions. Timer alternates between phases with audio/haptic cues. Protocol library includes evidence-based ratios."},
            {"acp": "ACP-904", "title": "Recovery Protocol Database", "zone": "zone-7", "priority": 2,
             "description": "Database schema for all recovery modalities. Track sessions over time and store protocol templates for guided recovery."},
            {"acp": "ACP-905", "title": "Recovery Impact Analysis", "zone": "zone-8", "priority": 3,
             "description": "Correlate recovery sessions with measurable outcomes. Personalized insights like 'Your HRV improved 15% after sauna days'."},
            {"acp": "ACP-906", "title": "Recovery Scheduling & Reminders", "zone": "zone-12", "priority": 3,
             "description": "Schedule recovery sessions with optimal timing recommendations. Push notifications ensure consistency. Integration with training calendar."},
        ]
    },
    {
        "title": "Epic 10: Fasting Intelligence",
        "description": "Fast smarter, train harder - Intermittent fasting tracking with training integration",
        "priority": 2,  # High
        "issues": [
            {"acp": "ACP-1001", "title": "Intermittent Fasting Tracker", "zone": "zone-12", "priority": 2,
             "description": "Track fasting windows with one-tap start/stop. Support common protocols (16:8, 18:6, 20:4, OMAD, 5:2). Visual timer shows current fasting state with motivational milestones."},
            {"acp": "ACP-1002", "title": "Fasting Database Schema", "zone": "zone-7", "priority": 2,
             "description": "Database schema for fasting logs tracking planned vs actual windows. Support multiple protocol types with adherence analytics."},
            {"acp": "ACP-1003", "title": "Fasting-Aware Workout Scheduling", "zone": "zone-8", "priority": 2,
             "description": "Adjust workout timing and intensity based on current fasting state. Goal-aware recommendations for hypertrophy vs fat loss."},
            {"acp": "ACP-1004", "title": "Fasting & Readiness Integration", "zone": "zone-12", "priority": 3,
             "description": "Factor fasting state into the daily readiness score. Extended fasting periods appropriately reduce intensity recommendations."},
            {"acp": "ACP-1005", "title": "Meal Timing Optimization", "zone": "zone-8", "priority": 3,
             "description": "AI recommendations for optimal meal timing around training. Considers fasting protocol, workout type, and performance goals."},
            {"acp": "ACP-1006", "title": "Fasting Benefits Tracking", "zone": "zone-12", "priority": 4,
             "description": "Track estimated autophagy windows and ketone states based on fasting duration. Educational content explains the science behind fasting benefits."},
        ]
    },
    {
        "title": "Epic 11: Supplement Intelligence",
        "description": "Powered by Momentous - the athlete's choice - Supplement tracking with evidence-based recommendations",
        "priority": 2,  # High
        "issues": [
            {"acp": "ACP-1101", "title": "Supplement Tracking", "zone": "zone-12", "priority": 2,
             "description": "Log daily supplement intake with searchable database. Track timing (AM/PM, with food, pre-workout) and dosage with proper units. Quick-log favorites for daily routine."},
            {"acp": "ACP-1102", "title": "Supplement Database", "zone": "zone-7", "priority": 2,
             "description": "Comprehensive supplement catalog with evidence ratings, interaction warnings, and optimal dosing guidelines. Momentous products featured with deep integration."},
            {"acp": "ACP-1103", "title": "AI Supplement Recommendations", "zone": "zone-8", "priority": 2,
             "description": "Personalized supplement recommendations based on training goals, lab results, sleep quality, and recovery needs. Momentous products recommended where applicable."},
            {"acp": "ACP-1104", "title": "Supplement Bundle Builder", "zone": "zone-12", "priority": 3,
             "description": "Create custom supplement stacks or choose from pre-built Momentous bundles. One-click purchasing with affiliate revenue."},
            {"acp": "ACP-1105", "title": "Supplement Timing Optimizer", "zone": "zone-8", "priority": 3,
             "description": "Optimal timing recommendations for each supplement. Considers fasting windows, workout timing, and supplement interactions."},
            {"acp": "ACP-1106", "title": "Supplement-Lab Correlation", "zone": "zone-8", "priority": 4,
             "description": "Track supplement effectiveness through lab result changes. Show before/after comparisons with statistical analysis."},
        ]
    },
    {
        "title": "Epic 12: Competitive Advantage",
        "description": "Beat Ladder. Beat Volt. Win the market. - Features that make PT Performance the best choice",
        "priority": 1,  # Urgent
        "issues": [
            {"acp": "ACP-1201", "title": "Unified AI Health Coach", "zone": "zone-8", "priority": 1,
             "description": "Single AI coach that understands ALL data streams simultaneously: training, sleep, HRV, labs, recovery, fasting, supplements, nutrition. No competitor has this integrated view."},
            {"acp": "ACP-1202", "title": "Accurate AI Nutrition (Beat Ladder)", "zone": "zone-8", "priority": 2,
             "description": "Photo-based meal logging with superior accuracy to Ladder's inaccurate AI nutrition. Powered by Claude Vision for best-in-class food recognition."},
            {"acp": "ACP-1203", "title": "Android App (Beat Ladder)", "zone": "zone-13", "priority": 2,
             "description": "Native Android app with full feature parity. Ladder is iOS-only, leaving 50%+ of the market unaddressed. Volt has Android but with poor UX."},
            {"acp": "ACP-1204", "title": "Progress Visualization (Beat Volt)", "zone": "zone-12", "priority": 2,
             "description": "Long-term progress charts addressing Volt's biggest user complaint. Comprehensive visualization of strength, body composition, and performance trends."},
            {"acp": "ACP-1205", "title": "Custom Exercise Library (Beat Volt)", "zone": "zone-12", "priority": 3,
             "description": "User-created exercises addressing Volt's limitation. Full video upload support with sharing capabilities."},
            {"acp": "ACP-1206", "title": "Flexible Training Structure (Beat Volt)", "zone": "zone-8", "priority": 3,
             "description": "Support non-athlete training patterns with flexible scheduling. Skip/swap workouts without penalty. Volt's rigid blocks don't work for recreational athletes."},
        ]
    },
]


async def get_or_create_label(client: LinearClient, team_id: str, label_name: str) -> str:
    """Get existing label or create it if it doesn't exist."""
    query = """
    query Labels {
        issueLabels {
            nodes {
                id
                name
                team {
                    id
                }
            }
        }
    }
    """
    data = await client.query(query)
    labels = data.get("issueLabels", {}).get("nodes", [])

    for label in labels:
        if label["name"].lower() == label_name.lower():
            if label.get("team") and label["team"]["id"] == team_id:
                return label["id"]
            elif not label.get("team"):
                return label["id"]

    # Create label if not found
    mutation = """
    mutation CreateLabel($input: IssueLabelCreateInput!) {
        issueLabelCreate(input: $input) {
            issueLabel {
                id
                name
            }
        }
    }
    """
    result = await client.query(mutation, {"input": {"teamId": team_id, "name": label_name}})
    return result["issueLabelCreate"]["issueLabel"]["id"]


async def create_epic(client: LinearClient, team_id: str, project_id: str, epic: dict) -> dict:
    """Create an epic (parent issue) in Linear."""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
            issue {
                id
                identifier
                title
                url
            }
        }
    }
    """

    variables = {
        "input": {
            "teamId": team_id,
            "title": epic["title"],
            "description": epic["description"],
            "priority": epic["priority"],
            "projectId": project_id,
        }
    }

    result = await client.query(mutation, variables)
    issue = result["issueCreate"]["issue"]
    print(f"✅ Created Epic: {issue['identifier']} - {epic['title']}")
    return issue


async def create_issue(client: LinearClient, team_id: str, project_id: str,
                       issue_data: dict, parent_id: str, label_ids: list = None) -> dict:
    """Create a child issue under an epic."""
    mutation = """
    mutation CreateIssue($input: IssueCreateInput!) {
        issueCreate(input: $input) {
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
        "teamId": team_id,
        "title": f"{issue_data['acp']}: {issue_data['title']}",
        "description": issue_data["description"],
        "priority": issue_data["priority"],
        "projectId": project_id,
        "parentId": parent_id,
    }

    if label_ids:
        input_data["labelIds"] = label_ids

    result = await client.query(mutation, {"input": input_data})
    issue = result["issueCreate"]["issue"]
    print(f"  ✅ {issue['identifier']} - {issue_data['acp']}: {issue_data['title'][:40]}...")
    return issue


async def main():
    # Get API key
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ Error: LINEAR_API_KEY not set")
        print("   Source the .env file or export LINEAR_API_KEY")
        sys.exit(1)

    print("🏥 Creating Health Intelligence Platform Issues in Linear")
    print("=" * 60)
    print(f"   5 Epics, 30 Issues (ACP-801 to ACP-1206)")
    print("")

    async with LinearClient(api_key) as client:
        # Get team
        team = await client.get_team_by_name(TEAM_NAME)
        if not team:
            print(f"❌ Team '{TEAM_NAME}' not found")
            sys.exit(1)
        print(f"📁 Team: {team['name']} ({team['key']})")

        # Get project
        project = await client.get_project_by_name(team["id"], PROJECT_NAME)
        if not project:
            print(f"❌ Project '{PROJECT_NAME}' not found")
            sys.exit(1)
        print(f"📋 Project: {project['name']}")
        print("")

        # Get or create zone labels
        print("🏷️  Setting up zone labels...")
        zone_label_ids = {}
        for zone, label_name in ZONE_LABELS.items():
            label_id = await get_or_create_label(client, team["id"], label_name)
            zone_label_ids[zone] = label_id
            print(f"   ✅ {zone} → {label_name}")
        print("")

        # Create epics and their child issues
        total_created = 0

        for epic in HEALTH_EPICS:
            print(f"\n🏷️  Creating {epic['title']}...")

            # Create the epic parent issue
            epic_issue = await create_epic(client, team["id"], project["id"], epic)

            print(f"   Creating {len(epic['issues'])} child issues...")

            for issue_data in epic["issues"]:
                # Get label ID for zone
                label_ids = []
                if issue_data.get("zone") and issue_data["zone"] in zone_label_ids:
                    label_ids.append(zone_label_ids[issue_data["zone"]])

                await create_issue(
                    client,
                    team["id"],
                    project["id"],
                    issue_data,
                    epic_issue["id"],
                    label_ids
                )
                total_created += 1

                # Small delay to avoid rate limiting
                await asyncio.sleep(0.3)

        print(f"\n{'=' * 60}")
        print(f"✅ Created {total_created} issues across {len(HEALTH_EPICS)} epics")
        print(f"   View in Linear: {project['url']}")
        print("")
        print("📊 Summary:")
        print("   - Epic 8: Health Intelligence Platform (6 issues)")
        print("   - Epic 9: Recovery Protocols (6 issues)")
        print("   - Epic 10: Fasting Intelligence (6 issues)")
        print("   - Epic 11: Supplement Intelligence (6 issues)")
        print("   - Epic 12: Competitive Advantage (6 issues)")


if __name__ == "__main__":
    asyncio.run(main())
