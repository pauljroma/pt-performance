#!/usr/bin/env python3
"""Update ACP-107 with status and move to In Progress"""

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

    issue_id = "75b01a22-3867-4a96-b1ec-07215e90af8a"  # ACP-107
    
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
        comment = """## Status Update

✅ **Analysis Complete**

Current findings:
- Xcode project is set to `CODE_SIGN_STYLE = Automatic`
- Fastlane Matchfile already exists and is configured
- Match repo: https://github.com/pauljroma/apple-certificates.git
- Bundle ID: com.ptperformance.app

## Next Steps

1. Verify certificates exist in match repo
2. Update Xcode project to Manual signing
3. Configure provisioning profile specifier
4. Test local build with fastlane match

Working on this now...
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Updated ACP-107 to In Progress")

if __name__ == '__main__':
    asyncio.run(main())
