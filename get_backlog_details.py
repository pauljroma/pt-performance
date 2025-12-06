#!/usr/bin/env python3
"""
Get detailed info on the 11 backlog issues
"""
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
        print('❌ ERROR: LINEAR_API_KEY not set in .env')
        return

    project_id = 'd86e35fb091b'

    async with LinearClient(api_key) as client:
        issues = await client.get_project_issues(project_id)

        if not issues:
            print('No issues found')
            return

        # Filter to backlog only
        backlog = [i for i in issues if i['state']['name'] == 'Backlog']

        print('='*80)
        print(f'📝 BACKLOG ISSUES ({len(backlog)} total)')
        print('='*80)
        print()

        for issue in sorted(backlog, key=lambda x: x['identifier']):
            labels = [l['name'] for l in issue['labels']['nodes']]
            zone_labels = [l for l in labels if l.startswith('zone-')]

            print(f'{issue["identifier"]}: {issue["title"]}')
            print(f'  Zones: {", ".join(zone_labels) if zone_labels else "none"}')
            if issue.get('description'):
                desc = issue['description'][:200].replace('\n', ' ')
                print(f'  Description: {desc}...')
            print()

if __name__ == '__main__':
    asyncio.run(main())
