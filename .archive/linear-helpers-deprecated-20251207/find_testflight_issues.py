#!/usr/bin/env python3
"""Find TestFlight issues in Linear workspace"""

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

    async with LinearClient(api_key) as client:
        # Get team
        team = await client.get_team_by_name("Agent-Control-Plane")
        if not team:
            print('❌ Team not found')
            return
        
        # Get all issues for the team
        query = """
        query TeamIssues($teamId: String!) {
            team(id: $teamId) {
                issues(first: 200) {
                    nodes {
                        id
                        identifier
                        title
                        state {
                            id
                            name
                            type
                        }
                        project {
                            id
                            name
                        }
                    }
                }
            }
        }
        """
        
        data = await client.query(query, {"teamId": team['id']})
        all_issues = data.get('team', {}).get('issues', {}).get('nodes', [])
        
        # Filter for TestFlight issues
        testflight_issues = [i for i in all_issues if 'TESTFLIGHT' in i['title']]
        
        print("\n" + "="*80)
        print(f"🔍 FOUND {len(testflight_issues)} TESTFLIGHT ISSUES")
        print("="*80 + "\n")
        
        for issue in testflight_issues:
            print(f"{issue['identifier']}: {issue['title'][:70]}")
            print(f"  State: {issue['state']['name']} ({issue['state']['type']})")
            if issue.get('project'):
                print(f"  Project: {issue['project']['name']}")
            else:
                print(f"  Project: None")
            print(f"  ID: {issue['id']}")
            print()
        
        # Also check backlog state count
        backlog_issues = [i for i in all_issues if i['state']['type'] == 'backlog']
        print(f"\n📊 Total issues in Backlog state: {len(backlog_issues)}")

if __name__ == '__main__':
    asyncio.run(main())
