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
        acp80 = next((i for i in issues if i['identifier'] == 'ACP-80'), None)
        
        print(f'Found: {acp80["identifier"]} - {acp80["title"]}')
        
        done_state_id = await get_done_state_id(client, acp80['id'])
        
        completion_comment = """✅ **Program Builder with Protocol Selector - COMPLETE**

**Created SwiftUI Components**:
1. `Models/Protocol.swift` - Therapy protocol model with 3 sample protocols
   - ThrowingOnRamp (8 weeks, 4 phases)
   - Post-Op Shoulder Rehab (12 weeks, 4 phases)
   - General Strength Foundation (6 weeks, 3 phases)

2. `Components/ProtocolSelector.swift` - Protocol picker with info card
   - Dropdown showing all available protocols
   - "None (Custom)" option for custom programs
   - Info card showing phases, duration, requirements

3. `Views/ProgramBuilderView.swift` - Main program creation UI
   - Program name input
   - Protocol selector
   - Phase list with add/delete
   - Constraint validation display
   - Create/Cancel actions

4. `ViewModels/ProgramBuilderViewModel.swift` - Business logic
   - Protocol loading (currently sample data, ready for Supabase)
   - Phase management with protocol constraints
   - Real-time validation
   - Constraint enforcement (min/max phases)

**Features Implemented**:
✅ Protocol dropdown shows available protocols
✅ Selecting protocol auto-populates phases
✅ Phase editor respects protocol constraints
✅ Min/max phase enforcement
✅ Validation errors shown clearly
✅ Can create custom program without protocol
✅ Delete phases (if protocol allows)
✅ Phase reordering after deletion

**Sample Protocols Include**:
- Throwing On-Ramp: 4 phases, strict progression, no phase skipping
- Shoulder Rehab: 4-5 phases, post-surgical constraints
- Strength Foundation: 3-4 phases, flexible duration

**Next Steps** (for production):
- Wire to Supabase `protocol_templates` table
- Add session/exercise editors within phases
- Implement patient assignment flow
- Add protocol preview/detail view

Files ready to build and test in Xcode!
"""
        
        await client.update_issue_status(acp80['id'], done_state_id)
        await client.add_issue_comment(acp80['id'], completion_comment)
        
        print('✅ ACP-80 Complete!')

if __name__ == '__main__':
    asyncio.run(main())
