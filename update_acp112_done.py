#!/usr/bin/env python3
"""Mark ACP-112 as Done"""

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

    issue_id = "08d103e4-aa14-4fbf-9861-4ce68ffb0bef"  # ACP-112
    
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

### Workspace Cleanup

Archived 46 deprecated Linear helper scripts to:
`.archive/linear-helpers-deprecated-20251207/`

### What Was Archived

- **Agent helpers** (12 files): agent1_*.py, agent2_*.py, agent3_*.py
- **Completion scripts** (10 files): complete_*.py
- **Creation scripts** (3 files): create_*.py
- **Deployment scripts** (6 files): deploy_*.py
- **Query scripts** (5 files): get_*.py, find_*.py
- **Update scripts** (10 files): update_*.py, move_*.py

Total: 46 scripts moved to archive

### What Remains

Active scripts kept in root:
- `linear_client.py` - Core Linear API client
- `linear_bootstrap.py` - Main bootstrap
- `check_linear_status.py` - Status checker
- `check_schema.py` - Schema validation
- `test_*.py` - Test scripts
- `verify_migrations.py` - Migration verification
- `mcp_server.py` - MCP server

### Documentation

Created `.archive/linear-helpers-deprecated-20251207/README.md` documenting:
- What each category of scripts did
- Why they were archived
- How to restore if needed
- Safe deletion timeline (30-60 days)

### Result

✨ Clean workspace with only actively used scripts
📁 Deprecated scripts safely archived with documentation
🧹 From 57 Python files → 8 active files
"""
        
        await client.add_issue_comment(issue_id, comment)
        print("✅ Marked ACP-112 as Done")

if __name__ == '__main__':
    asyncio.run(main())
