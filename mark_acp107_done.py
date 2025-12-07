#!/usr/bin/env python3
"""Mark ACP-107 as Done"""

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

### Fastlane Match Configuration

All fastlane match setup is complete and ready for use:

1. ✅ **Matchfile configured** (ios-app/PTPerformance/fastlane/Matchfile)
   - Certificates repo: https://github.com/pauljroma/apple-certificates.git
   - Storage mode: git (encrypted)
   - App identifier: com.ptperformance.app
   - Type: appstore

2. ✅ **Fastfile updated** (ios-app/PTPerformance/fastlane/Fastfile)
   - Uses `match(type: "appstore")` for certificate download
   - Configured with App Store Connect API
   - Build and sign with match provisioning profile

3. ✅ **GitHub Actions configured** (.github/workflows/ios-testflight.yml)
   - MATCH_PASSWORD env variable added
   - MATCH_GIT_BASIC_AUTHORIZATION env variable added
   - Ready to download certificates in CI

### What Was Completed

- Fastlane match infrastructure fully configured
- Xcode project switched to manual signing
- GitHub Actions workflow updated
- Comprehensive documentation created
- Deprecated scripts archived

### Remaining Manual Steps

The following steps require local execution with user credentials:

1. **Run match init** (one-time):
   ```bash
   cd ios-app/PTPerformance
   bundle exec fastlane match appstore --readonly false
   ```

2. **Add GitHub secrets**:
   - MATCH_PASSWORD (from step 1)
   - MATCH_GIT_BASIC_AUTHORIZATION (GitHub token)

These are documented in ios-app/TESTFLIGHT_RUNBOOK.md

### All 6 TestFlight Issues Complete

- ✅ ACP-107: Fastlane match configuration
- ✅ ACP-108: Manual code signing
- ✅ ACP-109: Build verification setup
- ✅ ACP-110: GitHub Actions configuration
- ✅ ACP-111: Documentation runbook
- ✅ ACP-112: Workspace cleanup

Commit: 5a243bf - "feat(testflight): Complete TestFlight deployment pipeline setup"
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-107 as Done")

if __name__ == '__main__':
    asyncio.run(main())
