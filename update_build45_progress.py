#!/usr/bin/env python3
"""
Update Build 45 Linear issues with completion status
"""

import os
import requests
from datetime import datetime

# Linear API configuration
GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}


def update_issue(issue_id: str, state_name: str, comment: str):
    """Update an issue's state and add a comment"""

    # First, get the workflow state ID for "Done"
    get_states_query = """
    query GetWorkflowStates($issueId: String!) {
        issue(id: $issueId) {
            team {
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

    response = requests.post(
        GRAPHQL_URL,
        json={"query": get_states_query, "variables": {"issueId": issue_id}},
        headers=headers
    )

    if response.status_code != 200:
        print(f"Error fetching states: {response.text}")
        return False

    states = response.json()["data"]["issue"]["team"]["states"]["nodes"]
    done_state_id = next(
        (state["id"] for state in states if state["name"] == state_name),
        None
    )

    if not done_state_id:
        print(f"Error: State '{state_name}' not found")
        return False

    # Update issue state
    update_mutation = """
    mutation UpdateIssue($issueId: String!, $stateId: String!) {
        issueUpdate(id: $issueId, input: { stateId: $stateId }) {
            success
            issue {
                id
                identifier
                title
                state {
                    name
                }
            }
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": update_mutation,
            "variables": {"issueId": issue_id, "stateId": done_state_id}
        },
        headers=headers
    )

    if response.status_code != 200:
        print(f"Error updating issue: {response.text}")
        return False

    result = response.json()
    if not result["data"]["issueUpdate"]["success"]:
        print(f"Failed to update issue")
        return False

    # Add comment
    comment_mutation = """
    mutation CreateComment($issueId: String!, $body: String!) {
        commentCreate(input: { issueId: $issueId, body: $body }) {
            success
            comment {
                id
            }
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={
            "query": comment_mutation,
            "variables": {"issueId": issue_id, "body": comment}
        },
        headers=headers
    )

    if response.status_code != 200:
        print(f"Error adding comment: {response.text}")
        return False

    return True


def get_issue_id(identifier: str):
    """Get issue UUID from identifier like ACP-140"""
    query = """
    query GetIssue($identifier: String!) {
        issue(id: $identifier) {
            id
            identifier
            title
        }
    }
    """

    response = requests.post(
        GRAPHQL_URL,
        json={"query": query, "variables": {"identifier": identifier}},
        headers=headers
    )

    if response.status_code != 200:
        print(f"Error fetching issue {identifier}: {response.text}")
        return None

    data = response.json()
    if "errors" in data:
        print(f"GraphQL error: {data['errors']}")
        return None

    return data["data"]["issue"]["id"]


def main():
    """Update completed issues"""

    # Get issue IDs
    print("Fetching issue IDs...")
    acp140_id = get_issue_id("ACP-140")
    acp144_id = get_issue_id("ACP-144")

    if not acp140_id or not acp144_id:
        print("Error: Could not fetch issue IDs")
        return

    print(f"Found ACP-140: {acp140_id}")
    print(f"Found ACP-144: {acp144_id}")
    print()

    # Agent 1: Schema Validation (ACP-140)
    print("Updating ACP-140 (Schema Validation)...")
    agent1_comment = """## ✅ Agent 1 Completed

**Deliverables:**
1. ✅ `scripts/validate_ios_schema.py` - Complete schema validation script (600+ lines)
2. ✅ `.github/workflows/schema-validation.yml` - CI/CD integration
3. ✅ `docs/SCHEMA_VALIDATION.md` - Comprehensive documentation (400+ lines)

**Testing:**
- Successfully parsed 12 Swift models
- Validates CodingKeys against database schema
- Detects missing columns, nullability mismatches, extra columns
- Exit codes: 0 (success), 1 (errors), 2 (warnings)

**Key Features:**
- Regex-based Swift file parsing
- PostgreSQL schema querying via psql
- GitHub Actions integration with PR comments
- Detailed error reporting with remediation steps

**Impact:**
- Prevents Build 44-style schema mismatches
- Blocks deployment on validation failures
- Saves debugging time by catching issues pre-production

**Status:** Ready for production use

**Date Completed:** 2025-12-15
"""

    agent1_success = update_issue(
        acp140_id,
        "Done",
        agent1_comment
    )

    if agent1_success:
        print("✅ Updated ACP-140")
    else:
        print("❌ Failed to update ACP-140")

    # Agent 5: Error Monitoring (ACP-144)
    print("\nUpdating ACP-144 (Error Monitoring)...")
    agent5_comment = """## ✅ Agent 5 Completed

**Deliverables:**
1. ✅ `ios-app/PTPerformance/Utils/ErrorLogger.swift` - Centralized error logging (240+ lines)
2. ✅ `ios-app/PTPerformance/Utils/PerformanceMonitor.swift` - Performance tracking (340+ lines)
3. ✅ `ios-app/PTPerformance/PTPerformanceApp.swift` - Sentry SDK integration
4. ✅ `docs/MONITORING_DASHBOARD.md` - Dashboard usage guide (500+ lines)
5. ✅ `docs/ERROR_HANDLING.md` - Best practices guide (800+ lines)

**Key Features:**

**ErrorLogger:**
- Specialized methods: network, database, validation, decoding errors
- Automatic breadcrumb tracking
- User context management
- Schema mismatch detection (marked as fatal)

**PerformanceMonitor:**
- App launch tracking
- View load time monitoring (threshold: 2s)
- Database query tracking (threshold: 1s)
- Network request tracking (threshold: 3s)
- Memory usage monitoring (threshold: 500MB)
- SwiftUI View extension for automatic tracking

**Sentry Integration:**
- Initialized in app startup
- User context auto-updated on auth changes
- Environment-based configuration (dev/prod)
- Release versioning
- Privacy-safe (no email/PII tracking)

**Documentation:**
- Complete monitoring dashboard guide
- Error handling best practices
- Common scenarios with solutions
- Alert configuration examples
- Troubleshooting guide

**Impact:**
- Real-time production error tracking
- Performance metrics and trends
- Early detection of issues
- Reduced debugging time
- Better user experience

**Status:** Ready for production use

**Date Completed:** 2025-12-15
"""

    agent5_success = update_issue(
        acp144_id,
        "Done",
        agent5_comment
    )

    if agent5_success:
        print("✅ Updated ACP-144")
    else:
        print("❌ Failed to update ACP-144")

    print("\n" + "="*80)
    print("Build 45 Phase 1 Update Complete")
    print("="*80)
    print("\nCompleted Agents: 2/5")
    print("  ✅ Agent 1: Schema Validation")
    print("  ✅ Agent 5: Error Monitoring")
    print("\nRemaining Agents: 3/5")
    print("  ⏳ Agent 2: Integration Testing")
    print("  ⏳ Agent 3: Migration Testing")
    print("  ⏳ Agent 4: RLS Policy Verification")
    print("\nNext Steps:")
    print("  1. Begin Phase 2 (Testing Infrastructure)")
    print("  2. Agent 2: Build integration test framework")
    print("  3. Agent 3: Create migration testing system")


if __name__ == "__main__":
    main()
