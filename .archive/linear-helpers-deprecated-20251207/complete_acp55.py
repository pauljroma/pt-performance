#!/usr/bin/env python3
"""
Complete ACP-55: Deployment Documentation
"""
import asyncio
import os
import sys
from dotenv import load_dotenv

load_dotenv()

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from linear_client import LinearClient

async def get_done_state_id(client, issue_id):
    """Get Done state ID"""
    query = """
    query Issue($issueId: String!) {
        issue(id: $issueId) {
            id
            team {
                states {
                    nodes {
                        id
                        type
                    }
                }
            }
        }
    }
    """
    data = await client.query(query, {"issueId": issue_id})
    states = data.get("issue", {}).get("team", {}).get("states", {}).get("nodes", [])
    done_state = next((s for s in states if s['type'] == 'completed'), None)
    return done_state['id'] if done_state else None

async def main():
    api_key = os.getenv('LINEAR_API_KEY')
    project_id = 'd86e35fb091b'

    async with LinearClient(api_key) as client:
        issues = await client.get_project_issues(project_id)
        acp55 = next((i for i in issues if i['identifier'] == 'ACP-55'), None)
        
        if not acp55:
            print('❌ ACP-55 not found')
            return
        
        print(f'Found: {acp55["identifier"]} - {acp55["title"]}')
        
        done_state_id = await get_done_state_id(client, acp55['id'])
        
        completion_comment = """✅ **Comprehensive Deployment Documentation Created**

**Created**: `docs/DEPLOYMENT_GUIDE.md`

**Sections Covered**:

1. **Prerequisites** - All required accounts and tools
2. **Supabase Database Setup** - Complete schema deployment guide
   - Project setup
   - Migration deployment
   - Database seeding
   - Auth configuration
   - RLS verification
3. **iOS App Deployment** - TestFlight and App Store
   - Xcode configuration
   - Build process
   - TestFlight beta testing
   - Production release steps
4. **Agent Service Deployment** - Three deployment options
   - Railway (recommended)
   - Docker
   - Direct Node.js
5. **Environment Variables Reference** - Complete reference table
6. **Monitoring & Health Checks** - Production monitoring
7. **Rollback Procedures** - Emergency rollback for all components
8. **Security Checklist** - Production security requirements

**Related Documentation**:
- `docs/RUNBOOK_ZERO_TO_DEMO.md` - Step-by-step demo setup
- `docs/runbooks/RUNBOOK_DATA_SUPABASE.md` - Database operations
- `docs/runbooks/RUNBOOK_MOBILE_SWIFTUI.md` - iOS development
- `docs/runbooks/RUNBOOK_AGENT_BACKEND.md` - Agent service operations

All acceptance criteria met:
✅ Supabase setup guide
✅ iOS app TestFlight deployment steps
✅ Agent service deployment (3 options: Railway, Docker, Node.js)
✅ Environment variable reference
✅ Monitoring and health checks
✅ Rollback procedures
✅ Security checklist
"""
        
        await client.update_issue_status(acp55['id'], done_state_id)
        await client.add_issue_comment(acp55['id'], completion_comment)
        
        print('✅ ACP-55 Complete!')

if __name__ == '__main__':
    asyncio.run(main())
