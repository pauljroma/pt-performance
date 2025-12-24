#!/usr/bin/env python3
"""Create Linear issues for Build 44 in ACP team."""

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

# Use Agent-Control-Plane team
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_DONE_STATE_ID = "8a9b8266-b8b2-487a-8286-2ef86385e827"

print("Creating Build 44 issues in Agent-Control-Plane (ACP) team...")
print(f"Team ID: {ACP_TEAM_ID}")
print(f"Done State ID: {ACP_DONE_STATE_ID}\n")

# Step 1: Get or create labels
print("Step 1: Getting or creating labels...")
labels_to_create = ["zone-12", "zone-7", "build-44", "completed", "security", "build-35", "retroactive"]

# Query existing labels for ACP team
labels_query = """
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

labels_result = query_linear(labels_query, {"teamId": ACP_TEAM_ID})
existing_labels = {}
if labels_result.get("data", {}).get("team", {}).get("labels"):
    existing_labels = {label["name"]: label["id"] for label in labels_result["data"]["team"]["labels"]["nodes"]}

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
            "teamId": ACP_TEAM_ID
        })

        if create_result.get("data", {}).get("issueLabelCreate", {}).get("success"):
            new_label = create_result["data"]["issueLabelCreate"]["issueLabel"]
            label_ids[label_name] = new_label["id"]
            print(f"  ✓ Created label: {label_name}")
        else:
            print(f"  ✗ Failed to create label: {label_name}")

time.sleep(1)

# Step 2: Create the 5 issues
print("\nStep 2: Creating 5 Build 44 issues in ACP team...\n")

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
        "priority": 1
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
2. Create program → Saves to database
3. Sheet dismisses → Programs list auto-refreshes
4. New program appears in list

File: TherapistProgramsView.swift

Status:
- Implemented: Build 35 (2025-12-12)
- Verified: Build 44 (2025-12-14)
- TestFlight: Build 44 Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf""",
        "labels": ["zone-12", "build-35", "build-44", "completed", "retroactive"]
    }
]

created_issues = []

for i, issue_data in enumerate(issues_to_create, 1):
    print(f"Creating issue {i}/5: {issue_data['title'][:50]}...")

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
        "teamId": ACP_TEAM_ID,
        "title": issue_data["title"],
        "description": issue_data["description"],
        "labelIds": label_id_list,
        "stateId": ACP_DONE_STATE_ID,
    }

    if "priority" in issue_data:
        issue_input["priority"] = issue_data["priority"]

    create_result = query_linear(create_issue_mutation, {"input": issue_input})

    if not create_result:
        print(f"  ✗ Failed: No response from Linear API")
        continue

    if "errors" in create_result:
        print(f"  ✗ Failed with errors:")
        print(json.dumps(create_result["errors"], indent=2))
        continue

    if create_result.get("data", {}).get("issueCreate", {}).get("success"):
        issue = create_result["data"]["issueCreate"]["issue"]
        created_issues.append(issue)
        print(f"  ✓ Created: {issue['identifier']} - {issue['title'][:50]}...")
        print(f"    URL: {issue['url']}")
    else:
        print(f"  ✗ Failed to create issue")
        print(json.dumps(create_result, indent=2))

    time.sleep(0.5)

# Summary
print(f"\n{'='*80}")
print(f"Summary: Created {len(created_issues)}/5 issues for Build 44 in ACP team")
print(f"{'='*80}")

for issue in created_issues:
    print(f"  {issue['identifier']}: {issue['title']}")
    print(f"    {issue['url']}")

print(f"\nAll issues created in 'Done' state with Build 44 labels.")
print(f"Team: Agent-Control-Plane (ACP)")
print(f"TestFlight Delivery UUID: 5839e3c3-dfaf-4bd6-b25a-bfe72ab46dcf")
