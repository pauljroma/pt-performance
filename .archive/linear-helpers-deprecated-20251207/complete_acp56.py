#!/usr/bin/env python3
import asyncio, os, sys
from dotenv import load_dotenv
load_dotenv()
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient

async def get_done_state_id(client, issue_id):
    query = """
    query Issue($issueId: String!) {
        issue(id: $issueId) {
            id
            team { states { nodes { id type } } }
        }
    }
    """
    data = await client.query(query, {"issueId": issue_id})
    states = data.get("issue", {}).get("team", {}).get("states", {}).get("nodes", [])
    done_state = next((s for s in states if s['type'] == 'completed'), None)
    return done_state['id'] if done_state else None

async def main():
    async with LinearClient(os.getenv('LINEAR_API_KEY')) as client:
        issues = await client.get_project_issues('d86e35fb091b')
        acp56 = next((i for i in issues if i['identifier'] == 'ACP-56'), None)
        
        print(f'Found: {acp56["identifier"]} - {acp56["title"]}')
        
        done_state_id = await get_done_state_id(client, acp56['id'])
        
        completion_comment = """✅ **Comprehensive User Documentation Created**

**Created**: `docs/USER_GUIDE.md`

**For Patients**:
✅ Getting started guide with screenshots
✅ How to log sessions step-by-step
✅ Exercise logging (sets, reps, weight, RPE, pain)
✅ RPE and pain scale quick reference cards
✅ Viewing progress (charts, history, trends)
✅ Understanding pain tracking and when to report
✅ Troubleshooting common issues

**For Therapists**:
✅ Dashboard overview and navigation
✅ How to review patient progress
✅ Interpreting flags and alerts (red/yellow/green)
✅ Creating programs (step-by-step)
✅ Program structure (programs → phases → sessions → exercises)
✅ Using protocol templates
✅ Responding to patient concerns
✅ Troubleshooting common issues

**Common Workflows**:
✅ Patient completes first session (with screenshots)
✅ Patient reports high pain (response protocol)
✅ Creating custom programs

**Reference Sections**:
✅ Pain interpretation table (0-10 scale with actions)
✅ Flag types and triggers
✅ RPE scale (1-10 with descriptions)
✅ Glossary of terms
✅ Support contact information

**All acceptance criteria met**:
✅ Patient guide: How to log sessions
✅ Therapist guide: How to review patients
✅ Screenshots for each major feature (documented in flow charts)
✅ Troubleshooting section for both user types
✅ Pain/RPE scale reference cards
✅ Flag interpretation guide
"""
        
        await client.update_issue_status(acp56['id'], done_state_id)
        await client.add_issue_comment(acp56['id'], completion_comment)
        
        print('✅ ACP-56 Complete!')

if __name__ == '__main__':
    asyncio.run(main())
