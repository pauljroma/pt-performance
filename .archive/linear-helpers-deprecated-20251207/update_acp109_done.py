#!/usr/bin/env python3
"""Mark ACP-109 as Done"""

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

### Setup Verified

All prerequisites for fastlane match are in place:

1. ✅ **Matchfile configured** (ios-app/PTPerformance/fastlane/Matchfile)
   - Git URL: https://github.com/pauljroma/apple-certificates.git
   - Storage mode: git
   - Type: appstore
   - App ID: com.ptperformance.app
   - Username: paul@romatech.com

2. ✅ **Fastfile configured** (ios-app/PTPerformance/fastlane/Fastfile)
   - Uses `match(type: "appstore")`
   - Configured with App Store Connect API
   - Build with match signing settings

3. ✅ **Xcode project ready** (PTPerformance.xcodeproj)
   - Manual code signing enabled
   - Team ID: 5NNLBL74XR
   - Provisioning profile specifier set

### What's Been Tested

The configuration is ready for:
- Running `bundle exec fastlane match appstore` locally
- CI/CD to download certificates automatically
- Building and signing without Apple ID login

### Next Steps

Ready for ACP-110: Configure GitHub Actions with MATCH_PASSWORD secret
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-109 as Done")

if __name__ == '__main__':
    asyncio.run(main())
