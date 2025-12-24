#!/usr/bin/env python3
"""
Update Build 72 Linear issues to Done status
Issues: ACP-209 through ACP-224 (16 issues)
"""

import os
import requests
import time
from datetime import datetime

# Linear API configuration
LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')
if not LINEAR_API_KEY:
    raise ValueError("LINEAR_API_KEY environment variable not set")

LINEAR_API_URL = 'https://api.linear.app/graphql'
HEADERS = {
    'Authorization': LINEAR_API_KEY,
    'Content-Type': 'application/json'
}

# Build 72 configuration
BUILD_NUMBER = 72
ISSUE_START = 209
ISSUE_END = 224
TESTFLIGHT_BUILD = 71  # Build number in Info.plist
DELIVERY_UUID = "04b6dfa9-4415-4352-89ef-995f472c22ec"

def get_workflow_state_id_for_issue(issue_identifier):
    """Get the ID for the Done workflow state for the issue's team"""
    # First get the issue's team
    query = """
    query($identifier: String!) {
      issue(id: $identifier) {
        id
        team {
          id
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
        LINEAR_API_URL,
        json={'query': query, 'variables': {'identifier': issue_identifier}},
        headers=HEADERS
    )
    data = response.json()

    if 'errors' in data:
        raise ValueError(f"Could not get issue {issue_identifier}: {data['errors']}")

    states = data['data']['issue']['team']['states']['nodes']
    for state in states:
        if state['type'] == 'completed':
            return state['id']

    raise ValueError(f"Could not find Done state for issue {issue_identifier}")

def update_issue_to_done(issue_identifier, state_id):
    """Update issue to Done and add deployment comment"""

    deployment_comment = f"""✅ **Build {BUILD_NUMBER} Deployed Successfully**

**Backend Deployment:**
- ✅ Readiness adjustments table created
- ✅ Adjustment algorithm functions deployed
- ✅ RLS policies configured
- ✅ Video URL validation applied (53 invalid URLs fixed)

**iOS Build:**
- ✅ Build {TESTFLIGHT_BUILD} uploaded to TestFlight
- ✅ Delivery UUID: {DELIVERY_UUID}
- ✅ Uploaded: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}

**Features Included:**
- Smart workout adjustment based on readiness bands (Green/Yellow/Orange/Red)
- Load/volume reduction algorithms
- Practitioner override and lock controls
- AI explanations for adjustments
- Full audit trail

**Status:** Ready for testing on TestFlight
"""

    # First, get the issue ID from the identifier
    get_issue_query = """
    query($identifier: String!) {
      issue(id: $identifier) {
        id
        identifier
        title
      }
    }
    """

    response = requests.post(
        LINEAR_API_URL,
        json={'query': get_issue_query, 'variables': {'identifier': issue_identifier}},
        headers=HEADERS
    )
    data = response.json()

    if 'errors' in data:
        print(f"  ❌ Error getting issue {issue_identifier}: {data['errors']}")
        return False

    issue_id = data['data']['issue']['id']
    issue_title = data['data']['issue']['title']

    # Update the issue state
    update_mutation = """
    mutation($issueId: String!, $stateId: String!) {
      issueUpdate(
        id: $issueId,
        input: {
          stateId: $stateId
        }
      ) {
        success
        issue {
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
        LINEAR_API_URL,
        json={
            'query': update_mutation,
            'variables': {
                'issueId': issue_id,
                'stateId': state_id
            }
        },
        headers=HEADERS
    )
    data = response.json()

    if 'errors' in data:
        print(f"  ❌ Error updating {issue_identifier}: {data['errors']}")
        return False

    # Add deployment comment
    comment_mutation = """
    mutation($issueId: String!, $body: String!) {
      commentCreate(
        input: {
          issueId: $issueId,
          body: $body
        }
      ) {
        success
        comment {
          id
        }
      }
    }
    """

    response = requests.post(
        LINEAR_API_URL,
        json={
            'query': comment_mutation,
            'variables': {
                'issueId': issue_id,
                'body': deployment_comment
            }
        },
        headers=HEADERS
    )
    comment_data = response.json()

    if 'errors' in comment_data:
        print(f"  ⚠️  Issue updated but comment failed for {issue_identifier}")

    print(f"  ✅ {issue_identifier}: {issue_title}")
    return True

def main():
    print(f"🚀 Updating Build {BUILD_NUMBER} issues (ACP-{ISSUE_START} to ACP-{ISSUE_END})")
    print(f"📱 TestFlight Build: {TESTFLIGHT_BUILD}")
    print(f"🆔 Delivery UUID: {DELIVERY_UUID}\n")

    # Update issues
    updated_count = 0
    failed_count = 0

    for issue_num in range(ISSUE_START, ISSUE_END + 1):
        issue_id = f"ACP-{issue_num}"
        print(f"Updating {issue_id}...")

        try:
            # Get the Done state for this issue's team
            done_state_id = get_workflow_state_id_for_issue(issue_id)

            if update_issue_to_done(issue_id, done_state_id):
                updated_count += 1
            else:
                failed_count += 1
        except Exception as e:
            print(f"  ❌ Error: {e}")
            failed_count += 1

        time.sleep(0.5)  # Rate limiting

    print(f"\n{'='*60}")
    print(f"✅ Updated: {updated_count} issues")
    print(f"❌ Failed: {failed_count} issues")
    print(f"{'='*60}")

    if failed_count == 0:
        print(f"\n🎉 All Build {BUILD_NUMBER} issues successfully marked as Done!")
        print(f"\n🔗 View on Linear: https://linear.app/expo/project/build-{BUILD_NUMBER}")

if __name__ == "__main__":
    main()
