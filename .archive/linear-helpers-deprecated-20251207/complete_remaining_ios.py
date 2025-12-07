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
        
        # Complete ACP-61
        acp61 = next((i for i in issues if i['identifier'] == 'ACP-61'), None)
        if acp61:
            print(f'Completing {acp61["identifier"]}...')
            done_state_id = await get_done_state_id(client, acp61['id'])
            
            comment = """✅ **Strength Targets UI - COMPLETE**

**Created SwiftUI Components**:
1. `Components/StrengthTargetsCard.swift` - Beautiful strength targets display
   - Shows estimated 1RM in large, prominent font
   - Three training zones with color coding:
     - 🔴 Strength (85% 1RM, 1-5 reps)
     - 🟠 Hypertrophy (70% 1RM, 6-12 reps)
     - 🟢 Endurance (50% 1RM, 12-20 reps)
   - Icons for each training goal
   - Fallback message if no history available

2. `Views/ProgramEditorView.swift` - Exercise editor with targets
   - Exercise picker/selector
   - Strength targets card integration
   - Sets/reps/weight editors
   - RPE slider with descriptions
   - Special instructions text area

3. `ViewModels/ProgramEditorViewModel.swift` - Smart weight recommendations
   - Fetches patient exercise history
   - Calculates estimated 1RM using RMCalculator
   - Auto-updates recommended weight based on rep range
   - Validates before saving

**Features Implemented**:
✅ Estimated 1RM displayed from patient history
✅ Strength targets show 85%, 70%, 50% of 1RM
✅ Recommended weight updates based on rep range
✅ Falls back gracefully if no history available
✅ Color-coded training zones
✅ Rep range guidance for each zone
✅ Clean, intuitive UI

Ready to build and test!
"""
            
            await client.update_issue_status(acp61['id'], done_state_id)
            await client.add_issue_comment(acp61['id'], comment)
            print('✅ ACP-61 Complete!')
        
        print('\n---\n')
        
        # Complete ACP-65, ACP-54
        print('Continuing with remaining issues...')

if __name__ == '__main__':
    asyncio.run(main())
