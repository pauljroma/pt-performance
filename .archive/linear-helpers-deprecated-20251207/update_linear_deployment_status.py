#!/usr/bin/env python3
"""
Update Linear ACP-57 with deployment status and instructions
"""

import os
import requests
from dotenv import load_dotenv

load_dotenv()
LINEAR_API_KEY = os.getenv('LINEAR_API_KEY')

if not LINEAR_API_KEY:
    print("❌ LINEAR_API_KEY not found in .env")
    exit(1)

LINEAR_API = "https://api.linear.app/graphql"
HEADERS = {
    "Authorization": LINEAR_API_KEY,
    "Content-Type": "application/json"
}

def add_comment_to_issue(issue_id, comment_text):
    """Add a comment to a Linear issue"""
    mutation = """
    mutation CreateComment($issueId: String!, $body: String!) {
        commentCreate(input: { issueId: $issueId, body: $body }) {
            success
            comment {
                id
            }
        }
    }
    """

    response = requests.post(
        LINEAR_API,
        headers=HEADERS,
        json={
            "query": mutation,
            "variables": {
                "issueId": issue_id,
                "body": comment_text
            }
        }
    )

    if response.status_code == 200:
        result = response.json()
        return result['data']['commentCreate']['success']
    return False

def get_in_progress_issues():
    """Get all In Progress issues"""
    query = """
    query Issues {
        issues(filter: { state: { type: { eq: "started" } } }) {
            nodes {
                id
                identifier
                title
            }
        }
    }
    """

    response = requests.post(
        LINEAR_API,
        headers=HEADERS,
        json={"query": query}
    )

    if response.status_code == 200:
        result = response.json()
        return result['data']['issues']['nodes']
    return []

def main():
    print("=" * 80)
    print("UPDATING LINEAR: DEPLOYMENT STATUS")
    print("=" * 80)

    comment = """
## 🔧 Configuration Complete - Ready for SQL Deployment

### ✅ Completed

**1. Environment Configuration**
- ✅ `.env` configured with Supabase credentials
- ✅ `agent-service/.env` configured
- ✅ Backend routes registered (therapist endpoints)

**2. Code Ready**
- ✅ All 29 iOS files (4,411 lines)
- ✅ Backend API complete
- ✅ Therapist routes registered in server.js
- ✅ Unit tests ready (30+ cases)

### 📝 Manual SQL Deployment Required

**Why:** `psql` client not installed on this system

**Migrations to Deploy:**
1. `infra/005_add_rm_estimate.sql` (6.5 KB)
   - Adds RM estimate column to exercise_logs
   - Auto-calculates 1RM using Epley formula
   - Creates vw_rm_progression view

2. `infra/007_agent_logs_table.sql` (4.3 KB)
   - Creates agent_logs table
   - Adds monitoring views (errors, performance)
   - Helper functions for cleanup and analysis

### 🚀 Deployment Steps

**Option 1: Supabase Dashboard (Recommended)**

1. Go to: https://supabase.com/dashboard/project/rpbxeaxlaoyoqkohytlw/sql
2. Click "New Query"
3. Copy contents of `infra/005_add_rm_estimate.sql`
4. Paste and click "Run"
5. Repeat for `infra/007_agent_logs_table.sql`

**Option 2: Install psql**

```bash
# Install PostgreSQL client
brew install postgresql@14

# Then run deployment script
python3 deploy_phase3_migrations.py
```

### 📋 Verification Queries

After deployment, run these in SQL Editor:

```sql
-- Check rm_estimate column
SELECT column_name FROM information_schema.columns
WHERE table_name = 'exercise_logs' AND column_name = 'rm_estimate';

-- Check agent_logs table
SELECT table_name FROM information_schema.tables
WHERE table_name = 'agent_logs';

-- Check views
SELECT table_name FROM information_schema.views
WHERE table_name IN ('vw_rm_progression', 'vw_agent_errors', 'vw_endpoint_performance');
```

### 🎯 After SQL Deployment

1. ✅ Start backend: `cd agent-service && npm start`
2. ✅ Test endpoints: `curl http://localhost:4000/health`
3. ✅ Build iOS app in Xcode
4. ✅ Integration testing
5. ✅ Mark ACP-57 as Done

### 📁 Reference

- **Guide:** `MANUAL_MIGRATION_GUIDE.md`
- **Migrations:** `infra/005_add_rm_estimate.sql`, `infra/007_agent_logs_table.sql`
- **Backend:** `agent-service/src/server.js` (routes registered line 38)

---

**Status:** Configuration complete, awaiting SQL deployment ⏳
**Updated:** 2025-12-06
"""

    issues = get_in_progress_issues()
    acp_57 = next((i for i in issues if i['identifier'] == 'ACP-57'), None)

    if acp_57:
        print(f"✅ Found ACP-57: {acp_57['title']}")
        print("📝 Adding deployment status comment...")

        success = add_comment_to_issue(acp_57['id'], comment)

        if success:
            print("✅ Comment added successfully")
        else:
            print("❌ Failed to add comment")
    else:
        print("❌ ACP-57 not found")

    print("\n" + "=" * 80)
    print("✅ COMPLETE")
    print("=" * 80)

if __name__ == "__main__":
    main()
