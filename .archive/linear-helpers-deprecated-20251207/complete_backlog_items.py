#!/usr/bin/env python3
"""
Mark completed backlog items as Done in Linear
"""
import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient

# Issues that are actually complete
COMPLETED_ISSUES = {
    'ACP-91': '✅ Xcode project skeleton created - PTPerformance app exists with Models/, Views/, ViewModels/, Services/ structure',
    'ACP-75': '✅ Today Session view implemented in TodaySessionView.swift with full SwiftUI layout and user experience',
    'ACP-77': '✅ Session logging UI implemented with ExerciseLog models, submission logic, and full tracking capabilities',
    'ACP-103': '✅ Session handoff document created with comprehensive status, achievements, and next actions',
}

async def get_done_state_id(client, issue_id):
    """Get Done state ID by querying an issue's available states"""
    query = """
    query Issue($issueId: String!) {
        issue(id: $issueId) {
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

    data = await client.query(query, {"issueId": issue_id})
    states = data.get("issue", {}).get("team", {}).get("states", {}).get("nodes", [])

    done_state = next((s for s in states if s['type'] == 'completed'), None)
    return done_state['id'] if done_state else None

async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set in .env')
        return

    project_id = 'd86e35fb091b'

    async with LinearClient(api_key) as client:
        # Get all issues
        issues = await client.get_project_issues(project_id)

        if not issues:
            print('No issues found')
            return

        # Get Done state ID from first issue
        done_state_id = await get_done_state_id(client, issues[0]['id'])

        if not done_state_id:
            print('❌ ERROR: Could not find "Done" state')
            return

        print(f'✅ Found "Done" state ID: {done_state_id}')
        print()

        # Find issues to complete
        backlog = [i for i in issues if i['state']['name'] == 'Backlog']

        print('='*80)
        print('🔄 MARKING COMPLETED ISSUES AS DONE')
        print('='*80)
        print()

        completed_count = 0

        for issue in backlog:
            identifier = issue['identifier']

            if identifier in COMPLETED_ISSUES:
                comment = COMPLETED_ISSUES[identifier]

                print(f'Processing {identifier}: {issue["title"][:60]}...')
                print(f'  Comment: {comment}')

                try:
                    # Update to Done
                    updated = await client.update_issue_status(issue['id'], done_state_id)
                    print(f'  ✅ Updated to Done')

                    # Add comment
                    await client.add_issue_comment(issue['id'], comment)
                    print(f'  ✅ Added comment')

                    completed_count += 1
                except Exception as e:
                    print(f'  ❌ Failed: {e}')

                print()

        print('='*80)
        print(f'✅ COMPLETED! Marked {completed_count} issues as Done')
        print('='*80)

if __name__ == '__main__':
    asyncio.run(main())
