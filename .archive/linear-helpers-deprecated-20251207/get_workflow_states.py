#!/usr/bin/env python3
"""Get all workflow states for the team"""

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
        
        # Get workflow states
        states = await client.get_workflow_states(team['id'])
        
        print("\n" + "="*80)
        print("🔄 WORKFLOW STATES FOR AGENT-CONTROL-PLANE")
        print("="*80 + "\n")
        
        for state in states:
            print(f"Name: {state['name']}")
            print(f"  ID: {state['id']}")
            print(f"  Type: {state['type']}")
            if state.get('description'):
                print(f"  Description: {state['description']}")
            print()

if __name__ == '__main__':
    asyncio.run(main())
