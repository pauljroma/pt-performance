#!/usr/bin/env python3
"""Mark ACP-109 as In Progress"""

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
        print('❌ ERROR: LINEAR_API_KEY not set')
        return

    issue_id = "9ac628f3-6ad0-4e99-9553-64c7abd24e66"  # ACP-109
    
    async with LinearClient(api_key) as client:
        # Get In Progress state
        team = await client.get_team_by_name("Agent-Control-Plane")
        states = await client.get_workflow_states(team['id'])
        in_progress_id = None
        for state in states:
            if state['name'] == 'In Progress':
                in_progress_id = state['id']
                break
        
        # Update to In Progress
        await client.update_issue_status(issue_id, in_progress_id)
        
        # Add comment
        comment = """## Starting Work

Prerequisites complete:
- ✅ Xcode project updated to Manual signing
- ✅ Fastlane Matchfile configured
- ✅ Development team set (5NNLBL74XR)
- ✅ Provisioning profile specifier set

Now verifying that fastlane match can fetch certificates and build locally...
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-109 as In Progress")

if __name__ == '__main__':
    asyncio.run(main())
