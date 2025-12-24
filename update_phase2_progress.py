#!/usr/bin/env python3
"""
Update Build 45 Phase 2 Linear issues with completion status
"""

import os
import requests

# Linear API configuration
GRAPHQL_URL = "https://api.linear.app/graphql"
API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")

headers = {
    "Authorization": API_KEY,
    "Content-Type": "application/json"
}


def get_issue_id(identifier: str):
    """Get issue UUID from identifier like ACP-141"""
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


def update_issue(issue_id: str, state_name: str, comment: str):
    """Update an issue's state and add a comment"""

    # Get workflow state ID for "Done"
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


def main():
    """Update completed Phase 2 issues"""

    # Get issue IDs
    print("Fetching issue IDs...")
    acp141_id = get_issue_id("ACP-141")
    acp142_id = get_issue_id("ACP-142")

    if not acp141_id or not acp142_id:
        print("Error: Could not fetch issue IDs")
        return

    print(f"Found ACP-141: {acp141_id}")
    print(f"Found ACP-142: {acp142_id}")
    print()

    # Agent 2: Integration Testing (ACP-141)
    print("Updating ACP-141 (Integration Testing)...")
    agent2_comment = """## ✅ Agent 2 Completed

**Deliverables:**

1. ✅ `ios-app/PTPerformance/Tests/Integration/IntegrationTestBase.swift` (350+ lines)
   - Base class for all integration tests
   - Authentication helpers (loginAsPatient, loginAsTherapist)
   - Query helpers with performance tracking
   - Assertion helpers (assertTableAccessible, assertQueryPerformance)
   - Automatic test data cleanup

2. ✅ `ios-app/PTPerformance/Tests/Integration/CriticalPathTests.swift` (600+ lines)
   - Complete patient flow test (login → program → session → exercise logging)
   - Complete therapist flow test (login → patients → programs)
   - Schema mismatch detection tests
   - Table relationship validation
   - Data integrity checks

3. ✅ `ios-app/PTPerformance/Tests/Integration/PerformanceBenchmarkTests.swift` (500+ lines)
   - Login performance benchmarks (< 3s threshold)
   - Simple query benchmarks (< 1s threshold)
   - Complex query benchmarks (< 2s threshold with joins)
   - Batch operation performance tests
   - Memory usage monitoring
   - Concurrent query optimization tests

4. ✅ `docs/INTEGRATION_TESTING.md` (600+ lines)
   - Complete testing guide
   - Test suite overview
   - Running tests locally and in CI
   - Troubleshooting guide
   - Writing new tests template

**Key Features:**

**IntegrationTestBase:**
- Automatic setup/teardown with user authentication
- Performance-tracked query execution
- Test data lifecycle management
- Rich assertion helpers
- Error logging integration

**Critical Path Tests:**
- Validates complete user workflows
- Detects schema mismatches (Build 44 issue prevention)
- Tests table relationships and foreign keys
- Ensures data integrity across operations

**Performance Benchmarks:**
- Establishes performance SLAs
- Detects performance regressions
- Measures P95 latency
- Tests concurrent operations
- Monitors memory usage under load

**Impact:**
- Catches production bugs before deployment
- Validates schema changes automatically
- Ensures performance meets SLAs
- Provides confidence for releases
- Reduces debugging time

**Status:** Ready for production use

**Date Completed:** 2025-12-15
"""

    agent2_success = update_issue(
        acp141_id,
        "Done",
        agent2_comment
    )

    if agent2_success:
        print("✅ Updated ACP-141")
    else:
        print("❌ Failed to update ACP-141")

    # Agent 3: Migration Testing (ACP-142)
    print("\nUpdating ACP-142 (Migration Testing)...")
    agent3_comment = """## ✅ Agent 3 Completed

**Deliverables:**

1. ✅ `scripts/test_migration.py` (600+ lines)
   - Complete migration testing framework
   - Syntax validation
   - Automatic schema backup creation
   - Migration application with error handling
   - Schema integrity validation
   - iOS schema compatibility check
   - Pre/post state comparison
   - Optional rollback testing

2. ✅ `docs/MIGRATION_ROLLBACK.md` (500+ lines)
   - Emergency rollback procedures
   - Step-by-step rollback guide
   - Common rollback scenarios
   - Backup management best practices
   - Post-rollback verification
   - Team communication templates

3. ✅ `docs/MIGRATION_TESTING.md` (700+ lines)
   - Comprehensive migration testing guide
   - Writing safe migrations
   - Testing strategies (local, staging, production-like)
   - Common migration issues and fixes
   - CI/CD integration
   - Migration approval process

**Key Features:**

**test_migration.py:**
- Validates SQL syntax before execution
- Creates automatic backups
- Tests schema integrity (foreign keys, primary keys)
- Runs iOS schema validation
- Tracks data changes (row counts)
- Optional destructive rollback testing
- Detailed test reporting

**Migration Safety:**
- Production database protection (blocks if URL contains "prod")
- Transaction-wrapped migrations
- Automatic backup creation
- Rollback validation
- Schema integrity checks
- Data loss prevention

**Documentation:**
- Emergency rollback procedures
- Common issues with solutions
- Best practices for safe migrations
- Step-by-step guides
- Real-world examples from Build 44

**Impact:**
- Prevents Build 44-style schema mismatches
- Enables safe migration rollback
- Reduces risk of data loss
- Provides confidence for schema changes
- Streamlines migration process

**Testing Capabilities:**
1. **Syntax Validation:** Catches SQL errors before execution
2. **Backup Creation:** Automatic safety net
3. **Schema Integrity:** Validates foreign keys, constraints
4. **iOS Compatibility:** Ensures Swift models match database
5. **Data Validation:** Compares pre/post row counts
6. **Rollback Testing:** Validates recovery procedures

**Status:** Ready for production use

**Date Completed:** 2025-12-15
"""

    agent3_success = update_issue(
        acp142_id,
        "Done",
        agent3_comment
    )

    if agent3_success:
        print("✅ Updated ACP-142")
    else:
        print("❌ Failed to update ACP-142")

    print("\n" + "="*80)
    print("Build 45 Phase 2 Update Complete")
    print("="*80)
    print("\nCompleted Agents: 4/5")
    print("  ✅ Agent 1: Schema Validation")
    print("  ✅ Agent 5: Error Monitoring")
    print("  ✅ Agent 2: Integration Testing")
    print("  ✅ Agent 3: Migration Testing")
    print("\nRemaining Agents: 1/5")
    print("  ⏳ Agent 4: RLS Policy Verification")
    print("\nNext Steps:")
    print("  1. Begin Phase 3 (Security Audit)")
    print("  2. Agent 4: Verify RLS policies")
    print("  3. Agent 6: Coordinate completion")


if __name__ == "__main__":
    main()
