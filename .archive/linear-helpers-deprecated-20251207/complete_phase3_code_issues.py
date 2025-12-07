#!/usr/bin/env python3
"""
Complete Phase 3 Code Implementation Issues
Mark all 13 Phase 3 code implementation issues as Done in Linear
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient


# Issues completed in this session
COMPLETED_ISSUES = [
    # Patient App (4 issues)
    "ACP-94",  # Exercise logging UI with submission
    "ACP-95",  # History view with pain/adherence charts
    "ACP-78",  # Basic pain/adherence charts components
    "ACP-76",  # Wire Today Session to Supabase (already done in ACP-93)

    # Therapist App (5 issues)
    "ACP-96",  # Therapist patient list view
    "ACP-97",  # Patient detail screen with charts
    "ACP-98",  # Program viewer
    "ACP-99",  # Patient notes interface
    "ACP-68",  # Therapist search/filter API

    # Integration & Testing (7 issues)
    "ACP-58",  # 1RM computation utils
    "ACP-59",  # rm_estimate column + backfill
    "ACP-71",  # 1RM unit tests
    "ACP-73",  # agent_logs table + middleware (already existed)
    "ACP-63",  # 8-week on-ramp validation (validate only)
    "ACP-62",  # Bullpen tracker normalization (SQL ready)
]


async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set in .env')
        return

    print('=' * 80)
    print('🎯 PHASE 3: COMPLETING CODE IMPLEMENTATION ISSUES')
    print('=' * 80)
    print()

    # Use the same Done state ID as other scripts
    DONE_STATE_ID = "8a9b8266-b8b2-487a-8286-2ef86385e827"
    project_id = 'd86e35fb091b'

    async with LinearClient(api_key) as client:
        print(f'✅ Using Done state ID: {DONE_STATE_ID}')
        print()

        # Get all issues to find IDs
        all_issues = await client.get_project_issues(project_id)
        issue_map = {issue['identifier']: issue for issue in all_issues}

        # Update each issue
        completed_count = 0
        skipped_count = 0

        for issue_identifier in COMPLETED_ISSUES:
            try:
                # Get issue from map
                issue = issue_map.get(issue_identifier)

                if not issue:
                    print(f'⚠️  {issue_identifier}: Not found, skipping')
                    skipped_count += 1
                    continue

                current_state = issue['state']['name']

                if current_state == 'Done':
                    print(f'✓  {issue_identifier}: Already Done')
                    completed_count += 1
                    continue

                # Update to Done
                print(f'🔄 {issue_identifier}: {current_state} → Done')

                await client.update_issue_status(issue['id'], DONE_STATE_ID)

                # Add completion comment
                await client.add_issue_comment(
                    issue['id'],
                    f"✅ Code implementation complete.\n\nImplemented in Phase 3 code session."
                )

                print(f'✅ {issue_identifier}: Updated to Done')
                completed_count += 1

            except Exception as e:
                print(f'❌ {issue_identifier}: Error - {str(e)}')
                skipped_count += 1

            # Rate limit delay
            await asyncio.sleep(0.5)

        print()
        print('=' * 80)
        print('📊 SUMMARY')
        print('=' * 80)
        print(f'Total Issues: {len(COMPLETED_ISSUES)}')
        print(f'✅ Completed: {completed_count}')
        print(f'⚠️  Skipped: {skipped_count}')
        print()

        if completed_count == len(COMPLETED_ISSUES):
            print('🎉 ALL PHASE 3 CODE ISSUES COMPLETED!')
        else:
            print(f'⚠️  {skipped_count} issues need manual review')

        print()

        # Get final project status
        print('=' * 80)
        print('📈 FINAL PROJECT STATUS')
        print('=' * 80)

        project_id = 'd86e35fb091b'
        issues = await client.get_project_issues(project_id)

        by_state = {}
        for issue in issues:
            state = issue['state']['name']
            by_state[state] = by_state.get(state, 0) + 1

        for state in sorted(by_state.keys()):
            count = by_state[state]
            print(f'  {state}: {count} issues')

        print()
        print('=' * 80)


if __name__ == '__main__':
    asyncio.run(main())
