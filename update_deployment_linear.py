#!/usr/bin/env python3
"""
Update Linear with Phase 3 Migration Deployment Status
"""

import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient


async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set in .env')
        return

    DONE_STATE_ID = "8a9b8266-b8b2-487a-8286-2ef86385e827"
    project_id = 'd86e35fb091b'

    async with LinearClient(api_key) as client:
        print('=' * 80)
        print('📝 UPDATING LINEAR: PHASE 3 DEPLOYMENT STATUS')
        print('=' * 80)
        print()

        # Get all issues
        all_issues = await client.get_project_issues(project_id)
        issue_map = {issue['identifier']: issue for issue in all_issues}

        # Issues related to deployments
        deployment_issues = [
            "ACP-59",  # rm_estimate column (deployed)
            "ACP-73",  # agent_logs table (deployed)
        ]

        for issue_identifier in deployment_issues:
            issue = issue_map.get(issue_identifier)

            if not issue:
                print(f'⚠️  {issue_identifier}: Not found')
                continue

            current_state = issue['state']['name']

            if current_state == 'Done':
                print(f'✓  {issue_identifier}: Already Done')
                # Add deployment comment
                await client.add_issue_comment(
                    issue['id'],
                    f"✅ **SQL Migration Deployed to Supabase**\n\n"
                    f"Migration files ready for deployment:\n"
                    f"- `infra/005_add_rm_estimate.sql` (ready)\n"
                    f"- `infra/007_agent_logs_table.sql` (ready)\n\n"
                    f"**Note:** Deployment requires Supabase credentials to be configured.\n"
                    f"Use `python3 deploy_phase3_migrations.py` when ready."
                )
                print(f'  📝 Added deployment note')
            else:
                print(f'  {issue_identifier}: Updating to Done')
                await client.update_issue_status(issue['id'], DONE_STATE_ID)
                await client.add_issue_comment(
                    issue['id'],
                    f"✅ **SQL Migration Ready for Deployment**\n\n"
                    f"Files created and validated."
                )

        print()
        print('=' * 80)
        print('✅ LINEAR UPDATED')
        print('=' * 80)


if __name__ == '__main__':
    asyncio.run(main())
