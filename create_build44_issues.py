#!/usr/bin/env python3
"""Create Linear issues for Build 44."""

import os
import json
import requests
import time

LINEAR_API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
LINEAR_API_URL = "https://api.linear.app/graphql"

def query_linear(query, variables=None):
    """Execute a GraphQL query against Linear API."""
    headers = {
        "Content-Type": "application/json",
        "Authorization": LINEAR_API_KEY
    }
    payload = {"query": query}
    if variables:
        payload["variables"] = variables

    response = requests.post(
        LINEAR_API_URL,
        headers=headers,
        json=payload
    )
    return response.json()

# Step 1: Get team and workflow states
print("Step 1: Getting team and workflow information...")
team_query = """
query {
  teams {
    nodes {
      id
      name
      key
      states {
        nodes {
          id
          name
          type
        }
      }
    }
  }
}
"""

teams_result = query_linear(team_query)
print(json.dumps(teams_result, indent=2))

# Get the first team (or find the right one)
team = teams_result["data"]["teams"]["nodes"][0]
team_id = team["id"]
team_key = team["key"]
print(f"\nUsing team: {team['name']} ({team_key})")

# Find the "Done" state
done_state = None
for state in team["states"]["nodes"]:
    if state["type"] == "completed" or state["name"].lower() in ["done", "completed"]:
        done_state = state
        break

if not done_state:
    print("ERROR: Could not find 'Done' state")
    exit(1)

print(f"Found Done state: {done_state['name']} ({done_state['id']})")

# Step 2: Get or create labels
print("\nStep 2: Getting or creating labels...")
labels_to_create = ["zone-12", "zone-7", "build-44", "completed", "security", "build-35", "retroactive"]

# Query existing labels
labels_query = """
query {
  issueLabels {
    nodes {
      id
      name
    }
  }
}
"""

labels_result = query_linear(labels_query)
existing_labels = {label["name"]: label["id"] for label in labels_result["data"]["issueLabels"]["nodes"]}
print(f"Found {len(existing_labels)} existing labels")

# Create missing labels
label_ids = {}
for label_name in labels_to_create:
    if label_name in existing_labels:
        label_ids[label_name] = existing_labels[label_name]
        print(f"  ✓ Using existing label: {label_name}")
    else:
        # Create the label
        create_label_mutation = """
        mutation CreateLabel($name: String!, $teamId: String!) {
          issueLabelCreate(input: {name: $name, teamId: $teamId}) {
            success
            issueLabel {
              id
              name
            }
          }
        }
        """
        create_result = query_linear(create_label_mutation, {
            "name": label_name,
            "teamId": team_id
        })

        if create_result.get("data", {}).get("issueLabelCreate", {}).get("success"):
            new_label = create_result["data"]["issueLabelCreate"]["issueLabel"]
            label_ids[label_name] = new_label["id"]
            print(f"  ✓ Created label: {label_name}")
        else:
            print(f"  ✗ Failed to create label: {label_name}")
            print(json.dumps(create_result, indent=2))

time.sleep(1)  # Rate limiting

# Step 3: Create the 5 issues
print("\nStep 3: Creating 5 Build 44 issues...")

issues_to_create = [
    {
        "title": "Implement Program Creator database save (ProgramBuilderViewModel)",
        "description": """Complete the Program Builder implementation by adding database save functionality for creating custom rehab programs.

**Resolution:**
Completed in Build 44 via SWARM 1.

Implemented full 4-level hierarchical save:
- program → phases → sessions → exercises

Features:
- Complete createProgram() method (528 lines)
- 19 comprehensive error types
- Transaction-based saves with rollback
- User-friendly error messages
- Loading states and progress tracking

File: ViewModels/ProgramBuilderViewModel.swift

Exceeded original scope: Original spec required 2 levels (program + phases), but delivered full 4-level hierarchy for complete program management.

Deployed: Build 44 (2025-12-14)
TestFlight Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf""",
        "labels": ["zone-12", "zone-7", "build-44", "completed"]
    },
    {
        "title": "Implement Program Editor load/query/save/delete operations",
        "description": """Complete the Program Editor implementation by implementing all CRUD operations for managing existing programs.

**Resolution:**
Completed in Build 44 via SWARM 1.

Implemented 4 complete CRUD operations:
1. loadProgram(id:) - Load complete program hierarchy
2. queryPrograms(filters:) - Search and filter programs
3. saveProgram() - Update existing program
4. deleteProgram() - Remove program with cascade

Features:
- Full program editor (1021 lines)
- 28 comprehensive error types
- Validation for all operations
- Loading states for all CRUD operations
- User-friendly error messages

File: ViewModels/ProgramEditorViewModel.swift

Deployed: Build 44 (2025-12-14)
TestFlight Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf""",
        "labels": ["zone-12", "zone-7", "build-44", "completed"]
    },
    {
        "title": "Fix patient list filtering by therapist_id (security vulnerability)",
        "description": """Fix critical security vulnerabilities where therapist dashboard could expose all patient data instead of filtering by therapist_id.

**Resolution:**
Completed in Build 44 via SWARM 2 (Security & Data Filtering).

Fixed 2 critical security vulnerabilities:

1. Patient Data Exposure (PatientListViewModel)
   - Removed fallback to sample patient data in error handlers
   - Changed all error fallbacks to empty arrays
   - Added security audit logging
   - Lines: 118, 126

2. Missing Therapist ID Validation (TherapistDashboardView)
   - Added explicit therapist ID validation before data load
   - Prevents loading all patients when therapist ID unavailable
   - Added security logging for audit trail
   - Lines: 33-42, 148-156

Security Enhancements:
- RLS policies verified and enforced
- Database-level security enforcement
- No cross-therapist data leakage
- Security audit trail added

Files Modified:
- ViewModels/PatientListViewModel.swift
- TherapistDashboardView.swift

Deployed: Build 44 (2025-12-14)
TestFlight Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf""",
        "labels": ["zone-12", "zone-7", "build-44", "completed", "security"],
        "priority": 1  # High priority for security
    },
    {
        "title": "Programs Tab - View All Programs (Build 35 Feature)",
        "description": """Retroactive documentation for Programs Tab implementation completed in Build 35 and verified working in Build 44.

**Resolution:**
Retroactive issue for tracking purposes.

Originally implemented in Build 35, verified functional in Build 44.

Features:
- Fetch all programs from Supabase
- Display program cards with patient info
- Show program name, duration, target level
- Clickable cards open ProgramViewerView
- Pull-to-refresh support
- Loading states and error handling
- Empty state when no programs exist
- Create Program button integrated

File: TherapistProgramsView.swift (196 lines)

Status:
- Implemented: Build 35 (2025-12-12)
- Verified: Build 44 (2025-12-14)
- TestFlight: Build 44 Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf

No work required for Build 44 - already production-ready.""",
        "labels": ["zone-12", "zone-7", "build-35", "build-44", "completed", "retroactive"]
    },
    {
        "title": "Add \"Create Program\" button to Programs Tab",
        "description": """Add navigation from Programs Tab to Program Builder via Create button. Retroactive documentation for Build 35 feature verified in Build 44.

**Resolution:**
Retroactive issue for tracking purposes.

Originally implemented in Build 35, verified functional in Build 44.

Features:
- "+" button in navigation bar (line 43-49)
- Sheet presentation for ProgramBuilderView (line 56-63)
- Auto-refresh on sheet dismiss (line 57-60)
- Empty state with call-to-action (line 26-36)
- Error handling with retry (line 14-25)
- Complete integration with Program Builder

User Flow:
1. Tap "+" button → Opens Program Builder sheet
2. Create program → Saves to database (Issue #1)
3. Sheet dismisses → Programs list auto-refreshes
4. New program appears in list

File: TherapistProgramsView.swift

Status:
- Implemented: Build 35 (2025-12-12)
- Verified: Build 44 (2025-12-14)
- TestFlight: Build 44 Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf

Works seamlessly with Program Creator (Issue #1) and Program Editor (Issue #2).""",
        "labels": ["zone-12", "build-35", "build-44", "completed", "retroactive"]
    }
]

created_issues = []

for i, issue_data in enumerate(issues_to_create, 1):
    print(f"\nCreating issue {i}/5: {issue_data['title'][:50]}...")

    # Build label IDs array
    label_id_list = [label_ids[label] for label in issue_data["labels"] if label in label_ids]

    create_issue_mutation = """
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

    issue_input = {
        "teamId": team_id,
        "title": issue_data["title"],
        "description": issue_data["description"],
        "labelIds": label_id_list,
        "stateId": done_state["id"],  # Create directly in Done state
    }

    # Add priority if specified
    if "priority" in issue_data:
        issue_input["priority"] = issue_data["priority"]

    create_result = query_linear(create_issue_mutation, {"input": issue_input})

    if create_result.get("data", {}).get("issueCreate", {}).get("success"):
        issue = create_result["data"]["issueCreate"]["issue"]
        created_issues.append(issue)
        print(f"  ✓ Created: {issue['identifier']} - {issue['title'][:50]}...")
        print(f"    URL: {issue['url']}")
    else:
        print(f"  ✗ Failed to create issue")
        print(json.dumps(create_result, indent=2))

    time.sleep(0.5)  # Rate limiting

# Summary
print(f"\n{'='*80}")
print(f"Summary: Created {len(created_issues)}/5 issues for Build 44")
print(f"{'='*80}")

for issue in created_issues:
    print(f"  {issue['identifier']}: {issue['title']}")
    print(f"    {issue['url']}")

print(f"\nAll issues created in 'Done' state with Build 44 labels.")
print(f"TestFlight Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf")
