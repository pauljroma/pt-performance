#!/usr/bin/env python3
"""
Check Linear Project Status
Query current state of all issues in the PT Performance Platform MVP project.
"""

import asyncio
import os
import sys
from collections import defaultdict
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient


async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    if not api_key:
        print('❌ ERROR: LINEAR_API_KEY not set in .env')
        return

    # Project ID from handoff doc
    project_id = 'd86e35fb091b'

    async with LinearClient(api_key) as client:
        # Get all issues
        issues = await client.get_project_issues(project_id)

        if not issues:
            print('No issues found in project')
            return

        # Group by state
        by_state = defaultdict(list)
        for issue in issues:
            state = issue['state']['name']
            by_state[state].append(issue)

        # Group by phase (from labels)
        phase1_issues = []
        phase2_issues = []
        other_issues = []

        for issue in issues:
            labels = [l['name'] for l in issue['labels']['nodes']]
            zone_labels = [l for l in labels if l.startswith('zone-')]

            # Phase 1: zone-7, zone-8, zone-10b
            if any(z in zone_labels for z in ['zone-7', 'zone-8', 'zone-10b']):
                phase1_issues.append(issue)
            # Phase 2: zone-3c, zone-4b
            elif any(z in zone_labels for z in ['zone-3c', 'zone-4b']):
                phase2_issues.append(issue)
            else:
                other_issues.append(issue)

        # Print summary
        print('=' * 80)
        print('🎯 PT PERFORMANCE PLATFORM - LINEAR PROJECT STATUS')
        print('=' * 80)
        print()

        print(f'📊 Total Issues: {len(issues)}')
        print()

        print('📈 Issues by State:')
        for state in sorted(by_state.keys()):
            print(f'  {state}: {len(by_state[state])} issues')
        print()

        # Phase 1 breakdown
        print('🔵 PHASE 1: Data Layer (zone-7, zone-8, zone-10b)')
        print(f'  Total: {len(phase1_issues)} issues')
        phase1_by_state = defaultdict(list)
        for issue in phase1_issues:
            phase1_by_state[issue['state']['name']].append(issue)

        for state in sorted(phase1_by_state.keys()):
            print(f'  {state}: {len(phase1_by_state[state])}')
            for issue in phase1_by_state[state]:
                labels = [l['name'] for l in issue['labels']['nodes']]
                zone_labels = [l for l in labels if l.startswith('zone-')]
                print(f'    {issue["identifier"]}: {issue["title"][:60]}... [{", ".join(zone_labels)}]')
        print()

        # Phase 2 breakdown
        print('🟢 PHASE 2: Backend Intelligence (zone-3c, zone-4b)')
        print(f'  Total: {len(phase2_issues)} issues')
        phase2_by_state = defaultdict(list)
        for issue in phase2_issues:
            phase2_by_state[issue['state']['name']].append(issue)

        for state in sorted(phase2_by_state.keys()):
            print(f'  {state}: {len(phase2_by_state[state])}')
        print()

        # Other phases
        print('🟡 OTHER PHASES')
        print(f'  Total: {len(other_issues)} issues')
        other_by_state = defaultdict(list)
        for issue in other_issues:
            other_by_state[issue['state']['name']].append(issue)

        for state in sorted(other_by_state.keys()):
            print(f'  {state}: {len(other_by_state[state])}')
        print()

        print('=' * 80)
        print('🎯 RECOMMENDATION: What to Swarm Next')
        print('=' * 80)
        print()

        # Analyze what to do next
        phase1_backlog = len(phase1_by_state.get('Backlog', []))
        phase1_todo = len(phase1_by_state.get('Todo', []))
        phase1_in_progress = len(phase1_by_state.get('In Progress', []))
        phase1_done = len(phase1_by_state.get('Done', []))

        if phase1_done == len(phase1_issues):
            print('✅ Phase 1 is COMPLETE!')
            print('📝 Next Action: Launch Phase 2 swarm (Backend Intelligence)')
            print()
            print('Command:')
            print('/swarm-it "Execute Phase 2: Backend Intelligence')
            print('Use 3 agents in parallel.')
            print('Agent 1: Core endpoints (ACP-88, ACP-60, ACP-68)')
            print('Agent 2: PT Assistant (ACP-89, ACP-81, ACP-72)')
            print('Agent 3: Flags & PCRs (ACP-100, ACP-101, ACP-102, ACP-90, ACP-66)')
            print('Target: 6-8 hours total."')
        elif phase1_in_progress > 0:
            print('⏳ Phase 1 is IN PROGRESS')
            print(f'  {phase1_done}/{len(phase1_issues)} tasks complete')
            print(f'  {phase1_in_progress} tasks in progress')
            print()
            print('📝 Next Action: Monitor current agents and help complete remaining tasks')
        elif phase1_backlog > 0 or phase1_todo > 0:
            print('🚀 Phase 1 is READY TO START')
            print(f'  {phase1_backlog + phase1_todo} tasks in backlog/todo')
            print()
            print('📝 Next Action: Launch Phase 1 swarm')
            print()
            print('Command:')
            print('/swarm-it "Execute Phase 1: Data Layer')
            print('Use 3 agents in parallel.')
            print('Agent 1: Schema (ACP-83, ACP-69, ACP-79)')
            print('Agent 2: Views (ACP-85, ACP-64, ACP-70)')
            print('Agent 3: Seed (ACP-84, ACP-67, ACP-86)')
            print('Coordinate via Linear comments.')
            print('Target: 6-8 hours total."')
        else:
            print('⚠️  Phase 1 status unclear')
            print('Please review Linear project manually')

        print()
        print('=' * 80)


if __name__ == '__main__':
    asyncio.run(main())
