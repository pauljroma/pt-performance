#!/usr/bin/env python3
"""Mark ACP-110 as Done"""

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

    issue_id = "56c41e97-1626-460a-ad96-a5d9dc2e0c33"  # ACP-110
    
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

### Changes Made

Updated `.github/workflows/ios-testflight.yml` to include fastlane match environment variables:

```yaml
env:
  APP_STORE_CONNECT_API_KEY_ID: ${{ secrets.APP_STORE_CONNECT_API_KEY_ID }}
  APP_STORE_CONNECT_API_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_API_ISSUER_ID }}
  APP_STORE_CONNECT_API_KEY_CONTENT: ${{ secrets.APP_STORE_CONNECT_API_KEY_CONTENT }}
  FASTLANE_TEAM_ID: ${{ secrets.FASTLANE_TEAM_ID }}
  MATCH_PASSWORD: ${{ secrets.MATCH_PASSWORD }}                       # ← NEW
  MATCH_GIT_BASIC_AUTHORIZATION: ${{ secrets.MATCH_GIT_BASIC_AUTHORIZATION }} # ← NEW
```

### Required GitHub Secrets

The workflow now expects these secrets to be configured:

1. ✅ `APP_STORE_CONNECT_API_KEY_ID` - Already set
2. ✅ `APP_STORE_CONNECT_API_ISSUER_ID` - Already set
3. ✅ `APP_STORE_CONNECT_API_KEY_CONTENT` - Already set
4. ✅ `FASTLANE_TEAM_ID` - Already set
5. ⏳ `MATCH_PASSWORD` - **Needs to be added** (password used when running `fastlane match init`)
6. ⏳ `MATCH_GIT_BASIC_AUTHORIZATION` - **Needs to be added** (base64 encoded `username:token` for certificates repo)

### How to Add Missing Secrets

```bash
# After running fastlane match init locally and creating password:
gh secret set MATCH_PASSWORD --repo pauljroma/linear-bootstrap

# For certificates repo access:
# Create GitHub token with repo access, then:
echo -n "username:ghp_xxxxx" | base64
gh secret set MATCH_GIT_BASIC_AUTHORIZATION --repo pauljroma/linear-bootstrap
```

### What This Enables

- CI can download certificates from private repo
- Build and sign without manual intervention
- Fully automated TestFlight deployment

### Next Steps

Ready for ACP-111: Document the complete deployment runbook
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-110 as Done")

if __name__ == '__main__':
    asyncio.run(main())
