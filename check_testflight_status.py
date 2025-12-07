#!/usr/bin/env python3
"""Check TestFlight issues status"""

import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient

TESTFLIGHT_IDS = {
    "ACP-107": "75b01a22-3867-4a96-b1ec-07215e90af8a",
    "ACP-108": "b7feee7e-5227-4b06-a6ef-229f0cd2db2a",
    "ACP-109": "9ac628f3-6ad0-4e99-9553-64c7abd24e66",
    "ACP-110": "56c41e97-1626-460a-ad96-a5d9dc2e0c33",
    "ACP-111": "20f655e4-6d56-40d0-bc63-6f79404b4922",
    "ACP-112": "08d103e4-aa14-4fbf-9861-4ce68ffb0bef",
}

async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set')
        return

    async with LinearClient(api_key) as client:
        print("\n" + "="*80)
        print("✅ TESTFLIGHT ISSUES - COMPLETION STATUS")
        print("="*80 + "\n")
        
        for identifier, issue_id in TESTFLIGHT_IDS.items():
            issue = await client.get_issue_by_id(issue_id)
            if issue:
                print(f"{identifier}: {issue['state']['name']}")
                print(f"  {issue['title'][:70]}")
                print()

if __name__ == '__main__':
    asyncio.run(main())
