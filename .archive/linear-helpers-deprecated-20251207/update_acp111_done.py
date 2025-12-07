#!/usr/bin/env python3
"""Mark ACP-111 as Done"""

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

    issue_id = "20f655e4-6d56-40d0-bc63-6f79404b4922"  # ACP-111
    
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

### Documentation Created

Created comprehensive runbook: `ios-app/TESTFLIGHT_RUNBOOK.md`

### Contents

1. **Overview** - Architecture and components
2. **Prerequisites** - Apple accounts, API keys, repos
3. **Initial Setup** - One-time fastlane match initialization
4. **Automated Deployment** - How to trigger builds
5. **Troubleshooting** - Common errors and fixes
6. **Certificate Rotation** - Annual renewal process
7. **Emergency Rollback** - How to revert builds
8. **Testing** - Local and CI validation
9. **Monitoring** - Where to check build status
10. **Security** - Secrets management and access control
11. **Maintenance** - Regular tasks schedule
12. **Appendix** - File locations and common commands

### Key Sections

- ✅ Complete GitHub secrets setup instructions
- ✅ Step-by-step deployment trigger process
- ✅ Troubleshooting guide for all common errors
- ✅ Certificate rotation procedure
- ✅ Emergency rollback steps

### Next Steps

Ready for ACP-112: Archive deprecated Linear helper scripts
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-111 as Done")

if __name__ == '__main__':
    asyncio.run(main())
