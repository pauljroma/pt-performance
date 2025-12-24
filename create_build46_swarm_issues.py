#!/usr/bin/env python3
"""Create Linear issues for Build 46 Feature Swarm"""

import os
import requests

GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}

def create_issue(title, description, labels):
    """Create a Linear issue"""
    mutation = """
    mutation CreateIssue($title: String!, $description: String!, $teamId: String!, $stateId: String!, $labelIds: [String!]!) {
        issueCreate(input: {
            title: $title
            description: $description
            teamId: $teamId
            stateId: $stateId
            labelIds: $labelIds
        }) {
            success
            issue {
                id
                identifier
                title
            }
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": mutation,
            "variables": {
                "title": title,
                "description": description,
                "teamId": ACP_TEAM_ID,
                "stateId": ACP_TODO_STATE_ID,
                "labelIds": labels
            }
        },
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        if data.get("data", {}).get("issueCreate", {}).get("success"):
            issue = data["data"]["issueCreate"]["issue"]
            return issue["identifier"]
    return None

# Get label IDs (reuse from Build 45)
def get_labels():
    query = """
    query GetTeamLabels($teamId: String!) {
        team(id: $teamId) {
            labels {
                nodes {
                    id
                    name
                }
            }
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={"query": query, "variables": {"teamId": ACP_TEAM_ID}},
        headers=headers
    )

    if response.status_code == 200:
        labels = response.json()["data"]["team"]["labels"]["nodes"]
        return {label["name"]: label["id"] for label in labels}
    return {}

print("Creating Build 46 Feature Swarm Issues...")
labels = get_labels()

# Get relevant label IDs
build46_label = labels.get("build-46")
feature_label = labels.get("feature")
swarm_label = labels.get("swarm")

issues = [
    {
        "title": "Agent 1: Patient Scheduling System",
        "description": """Build complete patient scheduling system

**Deliverables:**
- Database migration for scheduled_sessions
- Swift model (ScheduledSession)
- CalendarView UI
- ScheduleSessionView UI
- UpcomingSessionsView UI
- SchedulingService business logic
- Integration tests

**Priority:** HIGH (User requested)
**Phase:** 1 & 2
**Dependencies:** None
""",
        "labels": [build46_label, feature_label, swarm_label]
    },
    {
        "title": "Agent 2: Workout Templates Library",
        "description": """Build workout templates for therapists

**Deliverables:**
- Database migrations (templates, phases, sessions)
- Swift models (WorkoutTemplate, TemplatePhase, TemplateSession)
- TemplateLibraryView UI
- TemplateDetailView UI
- CreateTemplateView UI
- TemplatesService business logic
- Integration tests

**Priority:** HIGH
**Phase:** 1 & 2
**Dependencies:** None
""",
        "labels": [build46_label, feature_label, swarm_label]
    },
    {
        "title": "Agent 3: Progress Charts & Analytics",
        "description": """Build visual progress tracking

**Deliverables:**
- AnalyticsService (calculate metrics)
- ProgressChartsView dashboard
- VolumeChartView
- StrengthChartView
- ConsistencyChartView
- ChartData models

**Priority:** MEDIUM
**Phase:** 2
**Dependencies:** Existing exercise_logs data
""",
        "labels": [build46_label, feature_label, swarm_label]
    },
    {
        "title": "Agent 4: Video Exercise Infrastructure",
        "description": """Prepare video infrastructure

**Deliverables:**
- Database migration (add video fields to exercises)
- Updated Exercise model
- ExerciseVideoView player
- VideoService (loading/caching)
- Video content guide documentation

**Priority:** MEDIUM
**Phase:** 1 & 2
**Dependencies:** None
""",
        "labels": [build46_label, feature_label, swarm_label]
    },
    {
        "title": "Agent 5: Nutrition Tracking",
        "description": """Basic nutrition tracking

**Deliverables:**
- Database migration (nutrition_logs, nutrition_goals)
- Swift models (NutritionLog, NutritionGoal)
- NutritionDashboardView
- LogMealView
- NutritionService

**Priority:** MEDIUM
**Phase:** 1 & 2
**Dependencies:** None
""",
        "labels": [build46_label, feature_label, swarm_label]
    },
    {
        "title": "Agent 6: Feature Coordination & Integration",
        "description": """Integrate all features and coordinate release

**Deliverables:**
- Integration plan documentation
- RootView navigation updates
- FeatureFlags system
- E2E tests for all features
- Release notes
- Completion report

**Priority:** HIGH
**Phase:** 3
**Dependencies:** Agents 1-5 complete
""",
        "labels": [build46_label, swarm_label]
    }
]

print("\nCreating issues...")
for i, issue in enumerate(issues, 1):
    identifier = create_issue(
        issue["title"],
        issue["description"],
        [l for l in issue["labels"] if l]
    )
    if identifier:
        print(f"✅ Created {identifier}: {issue['title']}")
    else:
        print(f"❌ Failed to create: {issue['title']}")

print("\n" + "="*80)
print("Build 46 Feature Swarm Issues Created")
print("="*80)
print("\nTotal: 6 issues (5 features + 1 coordinator)")
print("Ready to execute swarm!")
