#!/usr/bin/env python3
"""Create Linear issues for Build 60 Swarm - Program Builder Completion + Security Fix"""

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

def get_labels():
    """Get label IDs from Linear"""
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

def update_existing_issue(identifier, status):
    """Update existing issue status"""
    # First get issue ID from identifier
    query = """
    query GetIssue($id: String!) {
        issue(id: $id) {
            id
            identifier
            title
        }
    }
    """

    # Try to find issue by identifier
    search_query = """
    query SearchIssues($filter: IssueFilter!) {
        issues(filter: $filter, first: 1) {
            nodes {
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
            "query": search_query,
            "variables": {
                "filter": {
                    "number": {"eq": int(identifier.split("-")[1])}
                }
            }
        },
        headers=headers
    )

    if response.status_code == 200:
        data = response.json()
        issues = data.get("data", {}).get("issues", {}).get("nodes", [])
        if issues:
            issue_id = issues[0]["id"]
            print(f"  Found existing issue: {identifier}")
            return True
    return False

print("="*80)
print("Build 60 Swarm - Linear Issues Setup")
print("="*80)
print()

# Get label IDs
print("Fetching label IDs...")
labels = get_labels()
build60_label = labels.get("build-60") or labels.get("build60")
feature_label = labels.get("feature")
bug_label = labels.get("bug")
swarm_label = labels.get("swarm")
ux_label = labels.get("ux")
security_label = labels.get("security") or labels.get("critical")

print(f"  build-60: {build60_label or 'NOT FOUND'}")
print(f"  feature: {feature_label or 'NOT FOUND'}")
print(f"  swarm: {swarm_label or 'NOT FOUND'}")
print()

# Check existing issues (ACP-113, ACP-114, ACP-115, ACP-116)
print("Checking existing issues...")
existing_issues = {
    "ACP-113": "Program Creator Save",
    "ACP-114": "Program Editor CRUD",
    "ACP-115": "Filter patient list by therapist_id",
    "ACP-116": "Add Create Program button"
}

for identifier, title in existing_issues.items():
    if update_existing_issue(identifier, "In Progress"):
        print(f"  ✅ {identifier} exists - will be updated to 'In Progress'")
    else:
        print(f"  ⚠️  {identifier} not found - needs to be created")
print()

# New issues to create
new_issues = [
    {
        "title": "Agent 4: Session Summary & UX Polish (Build 60)",
        "description": """Build post-workout summary and improve UX throughout app

**Deliverables:**
- SessionSummaryView (post-workout stats)
- SessionSummaryViewModel (calculate stats)
- LoadingStateView (skeleton screens)
- ErrorStateView (user-friendly errors)
- Pull-to-refresh on all list views
- Improved error messages

**Session Summary Stats:**
- Exercises completed
- Total volume (sets × reps × weight)
- Workout duration
- Personal records set
- Compliance score (% of prescribed reps achieved)

**UX Improvements:**
- Skeleton loading states
- Actionable error messages
- Pull-to-refresh on lists
- Smooth transitions

**Files to Create:**
- Views/Patient/SessionSummaryView.swift
- ViewModels/SessionSummaryViewModel.swift
- Utils/LoadingStateView.swift
- Utils/ErrorStateView.swift

**Files to Modify:**
- TodaySessionView.swift (navigate to summary)
- PatientListView.swift (pull-to-refresh)
- TherapistProgramsView.swift (pull-to-refresh)
- HistoryView.swift (loading states)

**Priority:** P2 - MEDIUM
**Effort:** 3-4 hours
**Risk:** Low
**Dependencies:** None
""",
        "labels": [build60_label, feature_label, swarm_label, ux_label]
    },
    {
        "title": "Agent 5: Build 60 Coordination & Deployment",
        "description": """Coordinate all Build 60 agents and deploy to TestFlight

**Deliverables:**
- Monitor agent progress (Agents 1-4)
- Resolve integration conflicts
- Run integration tests
- Update build number to 60
- Run fastlane beta
- Upload to TestFlight
- Create BUILD60_DEPLOYMENT.md
- Update Linear issues to Done
- Commit all changes

**Integration Checks:**
- All Swift files compile
- No merge conflicts
- Unit tests pass
- Integration tests pass
- App launches without crashes
- Create Program works end-to-end
- Patient list filtering works
- Session summary displays correctly

**Deployment Steps:**
1. Update Config.swift (build 59 → 60)
2. Update Fastfile (build 59 → 60)
3. Run clean build
4. Run fastlane beta
5. Upload to TestFlight
6. Create deployment document
7. Update Linear (ACP-113, ACP-114, ACP-115, ACP-116 → Done)
8. Commit: "feat(build-60): Complete Program Builder + security fixes"

**Files to Modify:**
- Config.swift
- fastlane/Fastfile

**Priority:** P0 - CRITICAL
**Effort:** 2-3 hours
**Risk:** Low
**Dependencies:** Agents 1-4 complete
""",
        "labels": [build60_label, swarm_label]
    }
]

print("Creating new issues...")
for i, issue in enumerate(new_issues, 1):
    identifier = create_issue(
        issue["title"],
        issue["description"],
        [l for l in issue["labels"] if l]
    )
    if identifier:
        print(f"  ✅ Created {identifier}: {issue['title']}")
    else:
        print(f"  ❌ Failed to create: {issue['title']}")

print()
print("="*80)
print("Build 60 Swarm - Issues Setup Complete")
print("="*80)
print()
print("Summary:")
print("  • 4 existing issues (ACP-113, ACP-114, ACP-115, ACP-116)")
print("  • 2 new issues (Session Summary, Coordination)")
print("  • Total: 6 issues for Build 60 swarm")
print()
print("Next Steps:")
print("  1. Update ACP-113, ACP-114, ACP-115, ACP-116 to 'In Progress' in Linear UI")
print("  2. Launch swarm with /swarm-it command")
print("  3. Monitor agent progress")
print("  4. Deploy Build 60 to TestFlight")
print()
print("Ready to execute swarm! 🚀")
print()
