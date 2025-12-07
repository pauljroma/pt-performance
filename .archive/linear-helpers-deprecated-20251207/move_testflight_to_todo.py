#!/usr/bin/env python3
"""Move TestFlight issues from Backlog to Todo"""

import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient

# TestFlight issue IDs (from find script)
TESTFLIGHT_ISSUES = {
    "ACP-107": "75b01a22-3867-4a96-b1ec-07215e90af8a",
    "ACP-108": "b7feee7e-5227-4b06-a6ef-229f0cd2db2a",
    "ACP-109": "9ac628f3-6ad0-4e99-9553-64c7abd24e66",
    "ACP-110": "56c41e97-1626-460a-ad96-a5d9dc2e0c33",
    "ACP-111": "20f655e4-6d56-40d0-bc63-6f79404b4922",
    "ACP-112": "08d103e4-aa14-4fbf-9861-4ce68ffb0bef",
}

# Root cause issues to cancel/skip (duplicates)
SKIP_ISSUES = ["ACP-104", "ACP-105", "ACP-106"]

async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set')
        return

    async with LinearClient(api_key) as client:
        # Get team
        team = await client.get_team_by_name("Agent-Control-Plane")
        if not team:
            print('❌ Team not found')
            return
        
        # Get workflow states
        states = await client.get_workflow_states(team['id'])
        todo_state_id = None
        for state in states:
            if state['name'] == 'Todo':
                todo_state_id = state['id']
                break
        
        if not todo_state_id:
            print('❌ Todo state not found')
            return
        
        print("\n" + "="*80)
        print("🔄 MOVING TESTFLIGHT ISSUES FROM BACKLOG TO TODO")
        print("="*80 + "\n")
        
        updated_count = 0
        for identifier, issue_id in TESTFLIGHT_ISSUES.items():
            print(f"Moving {identifier} to Todo...")
            try:
                result = await client.update_issue_status(issue_id, todo_state_id)
                print(f"  ✅ {result['identifier']}: {result['title'][:60]}")
                await client.add_issue_comment(
                    issue_id,
                    "Moving to Todo - starting work on TestFlight deployment pipeline"
                )
                updated_count += 1
            except Exception as e:
                print(f"  ❌ Error: {e}")
            print()
        
        print("="*80)
        print(f"✅ Updated {updated_count}/6 issues to Todo state")
        print("="*80)

if __name__ == '__main__':
    asyncio.run(main())
