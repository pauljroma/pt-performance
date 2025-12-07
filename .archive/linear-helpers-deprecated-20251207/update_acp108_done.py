#!/usr/bin/env python3
"""Mark ACP-108 as Done"""

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

    issue_id = "b7feee7e-5227-4b06-a6ef-229f0cd2db2a"  # ACP-108
    
    async with LinearClient(api_key) as client:
        # Get Done state
        team = await client.get_team_by_name("Agent-Control-Plane")
        states = await client.get_workflow_states(team['id'])
        done_id = None
        for state in states:
            if state['name'] == 'Done':
                done_id = state['id']
                break
        
        # Update to Done
        await client.update_issue_status(issue_id, done_id)
        
        # Add comment
        comment = """## ✅ COMPLETED

Updated Xcode project to use Manual code signing:

### Changes Made

1. **CODE_SIGN_STYLE**: Changed from `Automatic` to `Manual`
2. **CODE_SIGN_IDENTITY**: Set to `Apple Distribution`
3. **DEVELOPMENT_TEAM**: Set to `5NNLBL74XR`
4. **PROVISIONING_PROFILE_SPECIFIER**: Set to `match AppStore com.ptperformance.app`

### Files Modified

- `PTPerformance.xcodeproj/project.pbxproj` (backup created)

All 4 build configurations updated (Debug/Release for both project and target).

### Next Steps

Ready for ACP-109: Verify local build with fastlane match
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-108 as Done")

if __name__ == '__main__':
    asyncio.run(main())
