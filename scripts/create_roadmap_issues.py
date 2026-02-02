#!/usr/bin/env python3
"""
Create all 100 Product Roadmap issues in Linear organized by Epic.
Parses PRODUCT_ROADMAP_100_ISSUES.md and creates issues in Linear.
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

# Epic definitions with their issue ranges
EPICS = [
    {
        "title": "Epic 1: Friction-Free UX",
        "description": "Every tap costs you a user - Apple-level simplicity and one-tap experiences",
        "priority": 1,  # Urgent
        "issue_range": (1, 20),
    },
    {
        "title": "Epic 2: Baseball Pack Premium",
        "description": "The only arm care program designed by PTs, not trainers - 180+ baseball workouts",
        "priority": 2,  # High
        "issue_range": (21, 45),
    },
    {
        "title": "Epic 3: Intelligent Personalization",
        "description": "Smarter than Volt's Cortex - AI adaptation with human PT oversight",
        "priority": 2,  # High
        "issue_range": (46, 60),
    },
    {
        "title": "Epic 4: Coach & Team Platform",
        "description": "Better than Volt's coach platform - with parent transparency",
        "priority": 2,  # High
        "issue_range": (61, 70),
    },
    {
        "title": "Epic 5: Content & Education",
        "description": "Not just workouts - a baseball training education",
        "priority": 3,  # Medium
        "issue_range": (71, 80),
    },
    {
        "title": "Epic 6: Platform & Integrations",
        "description": "Everywhere you train - Apple ecosystem and third-party integrations",
        "priority": 3,  # Medium
        "issue_range": (81, 90),
    },
    {
        "title": "Epic 7: Engagement & Retention",
        "description": "Make training a habit, not a chore - gamification and social features",
        "priority": 3,  # Medium
        "issue_range": (91, 100),
    },
]

# Parse issues from roadmap
def parse_roadmap(roadmap_path: str) -> list:
    """Parse the roadmap markdown and extract all 100 issues."""
    with open(roadmap_path) as f:
        content = f.read()

    issues = []

    # Regex to match issue entries
    # Format: 1. **ACP-501: Title**
    #    - Description
    #    - Priority: X | Est: Y pts
    issue_pattern = r'(\d+)\.\s+\*\*ACP-(\d+):\s+(.+?)\*\*\s*\n((?:.*?\n)*?)(?=\d+\.\s+\*\*ACP-|\n---|\Z)'

    matches = re.findall(issue_pattern, content)

    for match in matches:
        issue_num = int(match[0])
        acp_num = match[1]
        title = match[2].strip()
        details = match[3].strip()

        # Extract priority from details
        priority = 3  # Default medium
        if "Priority: Critical" in details:
            priority = 1
        elif "Priority: High" in details:
            priority = 2
        elif "Priority: Low" in details:
            priority = 4

        # Extract estimate
        estimate = None
        est_match = re.search(r'Est:\s+(\d+)\s+pts', details)
        if est_match:
            estimate = int(est_match.group(1))

        # Build description from bullet points
        description_lines = []
        for line in details.split('\n'):
            line = line.strip()
            if line.startswith('-') and 'Priority:' not in line:
                description_lines.append(line)

        description = '\n'.join(description_lines) if description_lines else f"Implementation for {title}"

        issues.append({
            "number": issue_num,
            "acp": f"ACP-{acp_num}",
            "title": title,
            "description": description,
            "priority": priority,
            "estimate": estimate,
        })

    return issues


async def create_epic(client: LinearClient, team_id: str, project_id: str, epic: dict) -> dict:
    """Create an epic (parent issue) in Linear."""
    issue = await client.create_issue(
        team_id=team_id,
        title=epic["title"],
        description=epic["description"],
        priority=epic["priority"],
        project_id=project_id,
    )
    print(f"✅ Created Epic: {issue['identifier']} - {epic['title']}")
    return issue


async def create_issue(client: LinearClient, team_id: str, project_id: str,
                       issue_data: dict, parent_id: str) -> dict:
    """Create a child issue under an epic."""
    issue = await client.create_issue(
        team_id=team_id,
        title=f"{issue_data['acp']}: {issue_data['title']}",
        description=issue_data["description"],
        priority=issue_data["priority"],
        project_id=project_id,
        parent_id=parent_id,
        estimate=issue_data.get("estimate"),
    )
    print(f"  ✅ {issue['identifier']} - {issue_data['acp']}: {issue_data['title'][:40]}...")
    return issue


async def main():
    # Get API key
    api_key = os.getenv("LINEAR_API_KEY")
    if not api_key:
        print("❌ Error: LINEAR_API_KEY not set")
        print("   Source the .env file or export LINEAR_API_KEY")
        sys.exit(1)

    # Parse roadmap
    roadmap_path = Path(__file__).parent.parent / "PRODUCT_ROADMAP_100_ISSUES.md"
    if not roadmap_path.exists():
        print(f"❌ Roadmap not found at {roadmap_path}")
        sys.exit(1)

    print(f"📖 Parsing roadmap: {roadmap_path}")
    issues = parse_roadmap(str(roadmap_path))
    print(f"   Found {len(issues)} issues\n")

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
        print(f"📋 Project: {project['name']}\n")

        # Create epics and their child issues
        total_created = 0

        for epic in EPICS:
            print(f"\n🏷️  Creating {epic['title']}...")

            # Create the epic parent issue
            epic_issue = await create_epic(client, team["id"], project["id"], epic)

            # Find issues in this epic's range
            start, end = epic["issue_range"]
            epic_issues = [i for i in issues if start <= i["number"] <= end]

            print(f"   Creating {len(epic_issues)} child issues...")

            for issue_data in epic_issues:
                await create_issue(
                    client,
                    team["id"],
                    project["id"],
                    issue_data,
                    epic_issue["id"]
                )
                total_created += 1

                # Small delay to avoid rate limiting
                await asyncio.sleep(0.2)

        print(f"\n✅ Created {total_created} issues across {len(EPICS)} epics")
        print(f"   View in Linear: {project['url']}")


if __name__ == "__main__":
    asyncio.run(main())
