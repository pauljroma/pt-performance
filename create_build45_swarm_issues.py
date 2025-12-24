#!/usr/bin/env python3
"""Create Linear issues for Build 45 Quality Swarm."""

import os
import json
import requests
import time

LINEAR_API_KEY = os.getenv("LINEAR_API_KEY", "lin_api_fMj4OrC0XqallztdPaS0WAmEvcXDlbKA9jULoZNa")
LINEAR_API_URL = "https://api.linear.app/graphql"

# Agent-Control-Plane team
ACP_TEAM_ID = "5296cff8-9c53-4cb3-9df3-ccb83601805e"
ACP_TODO_STATE_ID = "6806266a-71d7-41d2-8fab-b8b84651ea37"  # Todo state

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

print("Creating Build 45 Swarm Issues in Agent-Control-Plane (ACP) team...")
print(f"Team ID: {ACP_TEAM_ID}")
print(f"Todo State ID: {ACP_TODO_STATE_ID}\n")

# Step 1: Get or create labels
print("Step 1: Getting or creating labels...")
labels_to_create = ["build-45", "swarm", "quality", "testing", "critical", "infrastructure"]

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

label_ids = {}
for label_name in labels_to_create:
    if label_name in existing_labels:
        label_ids[label_name] = existing_labels[label_name]
        print(f"  ✓ Using existing label: {label_name}")
    else:
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

time.sleep(1)

# Step 2: Create the swarm issues
print("\nStep 2: Creating Build 45 swarm issues...\n")

issues_to_create = [
    {
        "title": "[Swarm Agent 1] Schema Validation Automation",
        "description": """## Objective
Build automated schema validation system to prevent iOS-database schema mismatches.

## Context
Build 44 had 5 schema mismatches caught only in production, causing crashes and poor UX.

## Deliverables
1. **Schema Validation Script** (`scripts/validate_ios_schema.py`)
   - Compare Swift CodingKeys vs Supabase schema
   - Detect column name, type, and nullability mismatches
   - Detect enum value mismatches
   - Generate detailed diff reports
   - Exit with error if mismatches found

2. **GitHub Actions Workflow** (`.github/workflows/schema-validation.yml`)
   - Run on every PR and main branch commit
   - Fail build if mismatches detected
   - Post validation report as PR comment
   - Complete in <30 seconds

3. **Pre-Commit Hook** (`.git/hooks/pre-commit`)
   - Local validation before commit
   - Fast validation (<10 seconds)
   - Skippable with --no-verify

4. **Documentation** (`docs/SCHEMA_VALIDATION.md`)
   - Setup and usage instructions
   - Troubleshooting guide
   - How to add new models

## Acceptance Criteria
- ✅ Detects all types of schema mismatches
- ✅ Integrated into CI/CD pipeline
- ✅ Clear error messages with remediation steps
- ✅ Documentation complete

## Estimated Effort
2-3 days

## Priority
🔴 Critical - Blocks Build 45 completion""",
        "labels": ["build-45", "swarm", "critical", "infrastructure"],
        "priority": 1  # Urgent
    },
    {
        "title": "[Swarm Agent 2] Integration Testing Infrastructure",
        "description": """## Objective
Build comprehensive integration test suite to verify iOS app can decode real database records.

## Context
No automated tests verify database<->iOS integration. Schema bugs only found in production.

## Deliverables
1. **Database Decoding Tests** (`Tests/Integration/DatabaseDecodingTests.swift`)
   - Test all models decode from real database
   - Test null handling
   - Test enum conversions (yellow/red severity)
   - Test ISO8601 date decoding
   - 80%+ code coverage for models

2. **Full User Flow Tests** (`Tests/Integration/FullUserFlowTests.swift`)
   - Therapist dashboard load
   - Patient detail load
   - Exercise logging flow
   - Program creation flow
   - Run against staging database
   - Test run time <2 minutes

3. **Test Fixtures** (`Tests/Fixtures/TestData.swift`)
   - Reusable test data for all models
   - Cover edge cases (nulls, empty arrays)
   - Deterministic data

4. **Test Database Setup** (`scripts/setup_test_database.sh`)
   - Create isolated test database
   - Apply all migrations
   - Seed minimal test data
   - Reset between test runs

5. **CI Integration** (`.github/workflows/integration-tests.yml`)
   - Run on every PR
   - Upload test coverage report

## Acceptance Criteria
- ✅ All models have decode tests
- ✅ All user flows covered
- ✅ Tests pass consistently (no flakiness)
- ✅ 80%+ test coverage
- ✅ Integrated into CI

## Estimated Effort
3-4 days

## Dependencies
- Requires Agent 1 (schema validation) to complete first

## Priority
🔴 Critical - Blocks Build 45 completion""",
        "labels": ["build-45", "swarm", "critical", "testing"],
        "priority": 1
    },
    {
        "title": "[Swarm Agent 3] Migration Testing & Rollback System",
        "description": """## Objective
Automate migration testing and document rollback procedures.

## Context
Migrations tested manually. Edge cases missed. No documented rollback procedures.

## Deliverables
1. **Migration Test Script** (`scripts/test_migration.sh`)
   - Clone production schema to test database
   - Apply migration to test database
   - Run schema validation
   - Run integration tests
   - Verify no data loss
   - Generate migration report
   - Complete in <5 minutes

2. **Database Cloning Script** (`scripts/clone_prod_schema.sh`)
   - Clone schema (not data) from production
   - Anonymize any copied data (HIPAA)
   - Create isolated test database
   - Fast (<1 minute)

3. **Migration Rollback Template** (`supabase/migrations/ROLLBACK_TEMPLATE.md`)
   - Template for all future migrations
   - Forward and rollback SQL
   - Testing checklist
   - Risks and considerations

4. **Migration Verification Script** (`scripts/verify_migration.py`)
   - Verify all expected columns exist
   - Verify all constraints exist
   - Verify all indexes exist
   - Check data integrity

5. **Existing Migration Tests** (`tests/migrations/`)
   - Test all existing migrations
   - Verify rollback succeeds
   - Verify data integrity

## Acceptance Criteria
- ✅ All migrations testable before production
- ✅ All migrations have rollback SQL
- ✅ Migration testing automated
- ✅ Zero-downtime migration strategy

## Estimated Effort
2-3 days

## Dependencies
- Requires Agent 1 (schema validation)
- Requires Agent 2 (integration tests)

## Priority
🔴 Critical - Blocks Build 45 completion""",
        "labels": ["build-45", "swarm", "critical", "infrastructure"],
        "priority": 1
    },
    {
        "title": "[Swarm Agent 4] RLS Policy Verification & Security Audit",
        "description": """## Objective
Verify and test all Row Level Security (RLS) policies to prevent data leakage.

## Context
Build 44 had security vulnerability: therapists could see all patients. Need systematic RLS testing.

## Deliverables
1. **RLS Isolation Tests** (`supabase/tests/rls_isolation_tests.sql`)
   - Test therapist data isolation
   - Test patient data isolation
   - Test anonymous user access
   - Test all sensitive tables
   - Zero data leakage detected

2. **RLS Verification Script** (`scripts/verify_rls_policies.py`)
   - Verify all tables have RLS enabled
   - Detect overly permissive policies
   - Verify policy logic
   - Generate security report

3. **RLS Policy Documentation** (`docs/RLS_POLICIES.md`)
   - Document all RLS policies
   - Include policy SQL
   - Explain security rationale
   - Provide examples

4. **Security Audit Report** (`.outcomes/BUILD_45_SECURITY_AUDIT.md`)
   - Tables audited
   - Vulnerabilities found and fixed
   - Test results
   - Recommendations

## Test Scenarios
- ✅ Therapist A cannot see Therapist B's patients
- ✅ Therapist A cannot update Therapist B's programs
- ✅ Patient A cannot see Patient B's data
- ✅ Patient A cannot modify Patient B's data
- ✅ Anonymous users cannot access any data

## Acceptance Criteria
- ✅ All tables have RLS enabled
- ✅ All policies tested with real user roles
- ✅ Zero cross-therapist data leakage
- ✅ Zero cross-patient data leakage
- ✅ Security documentation complete

## Estimated Effort
2 days

## Dependencies
- May need Agent 2 (integration tests) for verification

## Priority
🔴 Critical - Security vulnerability""",
        "labels": ["build-45", "swarm", "critical", "security"],
        "priority": 1
    },
    {
        "title": "[Swarm Agent 5] Error Monitoring & Observability",
        "description": """## Objective
Integrate error reporting and monitoring to catch production issues early.

## Context
No visibility into production errors. Users hit bugs, we don't know.

## Deliverables
1. **Sentry Integration** (`ios-app/PTPerformance/PTPerformanceApp.swift`)
   - Initialize Sentry on app launch
   - Capture crashes automatically
   - Capture network/database errors
   - Set user context (anonymous)
   - Configure environment (dev/staging/prod)

2. **Custom Error Logging** (`ios-app/PTPerformance/Utils/ErrorLogger.swift`)
   - log(error:context:) method
   - logNetworkError() method
   - logDatabaseError() method
   - logValidationError() method
   - Automatic context capture

3. **Performance Monitoring** (`ios-app/PTPerformance/Utils/PerformanceMonitor.swift`)
   - Track app launch time
   - Track view load time
   - Track database query time
   - Track network request time
   - Track memory usage

4. **Monitoring Dashboard Setup** (`docs/MONITORING_DASHBOARD.md`)
   - Crashes dashboard
   - Errors dashboard
   - Performance dashboard
   - Alert configuration

5. **Error Handling Best Practices** (`docs/ERROR_HANDLING.md`)
   - When to throw vs return Result
   - How to log errors
   - User-facing error messages
   - Error recovery strategies

## Metrics to Track
- Crash rate (crashes/session)
- Error rate by type
- App launch time
- View load time
- API response time

## Acceptance Criteria
- ✅ Crashes reported to Sentry
- ✅ Error breadcrumbs captured
- ✅ Performance metrics tracked
- ✅ User privacy preserved (no PII)
- ✅ Team has access to dashboards

## Estimated Effort
1-2 days

## Priority
🔴 Critical - Observability required""",
        "labels": ["build-45", "swarm", "critical", "infrastructure"],
        "priority": 1
    },
    {
        "title": "[Build 45] Swarm Coordination & Completion Report",
        "description": """## Objective
Coordinate Build 45 swarm execution and create completion report.

## Responsibilities
- Monitor progress of all 5 agents
- Unblock agents if dependencies delayed
- Ensure all tests passing before deployment
- Create comprehensive completion report

## Execution Phases

### Phase 1: Foundation & Setup (Days 1-3)
- Agent 1: Schema Validation
- Agent 5: Error Monitoring
- **Goal:** Validation and monitoring in place

### Phase 2: Testing Infrastructure (Days 4-7)
- Agent 2: Integration Tests
- Agent 4: RLS Verification
- **Goal:** All tests passing, security verified

### Phase 3: Migration Testing & CI (Days 8-10)
- Agent 3: Migration Testing
- **Goal:** All automation in CI/CD

### Phase 4: Documentation & Validation (Days 11-12)
- All agents: Documentation
- **Goal:** Build 45 ready for TestFlight

## Pre-Deployment Checklist
- [ ] All unit tests pass (100%)
- [ ] All integration tests pass (100%)
- [ ] Schema validation passes
- [ ] RLS tests pass (zero data leakage)
- [ ] Migration tests pass
- [ ] Code coverage ≥80%
- [ ] No critical Sentry errors

## Completion Report Contents
- Test results summary
- Metrics achieved
- Known issues
- Next steps for Build 46

## Success Metrics
- 80%+ test coverage
- Zero schema mismatches
- Zero RLS vulnerabilities
- All migrations have rollback
- Error reporting active

## Estimated Effort
12 days total (all agents combined)

## Priority
🔴 Critical - Orchestrates entire swarm""",
        "labels": ["build-45", "swarm", "critical"],
        "priority": 1
    }
]

created_issues = []

for i, issue_data in enumerate(issues_to_create, 1):
    print(f"Creating issue {i}/{len(issues_to_create)}: {issue_data['title'][:60]}...")

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
        "stateId": ACP_TODO_STATE_ID,
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
        print(f"  ✓ Created: {issue['identifier']} - {issue['title'][:60]}...")
        print(f"    URL: {issue['url']}")
    else:
        print(f"  ✗ Failed to create issue")
        print(json.dumps(create_result, indent=2))

    time.sleep(0.5)

# Summary
print(f"\n{'='*80}")
print(f"Summary: Created {len(created_issues)}/{len(issues_to_create)} issues for Build 45 Swarm")
print(f"{'='*80}")

for issue in created_issues:
    print(f"  {issue['identifier']}: {issue['title']}")
    print(f"    {issue['url']}")

print(f"\nAll issues created in 'Todo' state with Build 45 labels.")
print(f"Team: Agent-Control-Plane (ACP)")
print(f"\n🎯 Build 45 Focus: Critical Quality & Testing Infrastructure")
print(f"📋 Total Issues: {len(created_issues)}")
print(f"⏱️  Estimated Effort: 8-12 days")
print(f"🔴 Priority: Critical")
