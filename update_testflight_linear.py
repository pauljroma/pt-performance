#!/usr/bin/env python3
"""Update Linear with TestFlight progress"""

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

    # ACP-107 issue ID
    issue_id = "75b01a22-3867-4a96-b1ec-07215e90af8a"
    
    async with LinearClient(api_key) as client:
        comment = """## 🔄 Build In Progress

**Latest Status**: Build running with correct API key secrets!

### What Was Fixed

1. ✅ Updated `APP_STORE_CONNECT_API_KEY_ID` to `9S37GWGW49`
2. ✅ Updated `APP_STORE_CONNECT_API_KEY_CONTENT` with correct base64 key
3. ✅ Removed hardcoded `api_key_path` from Matchfile (was causing file not found error)
4. ✅ Build now getting past API key validation and into match certificate download

### Current Build

- Run ID: 20001743744
- Triggered: Via push (commit b8029f0)
- Status: In Progress
- URL: https://github.com/pauljroma/pt-performance/actions/runs/20001743744

### Progress

- ✅ API key validated successfully
- ⏳ Fastlane match downloading certificates
- ⏳ Building app
- ⏳ Uploading to TestFlight

Will update when build completes...
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Updated ACP-107 with build progress")

if __name__ == '__main__':
    asyncio.run(main())
