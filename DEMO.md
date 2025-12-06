# Linear Integration Demo

This document demonstrates the complete multi-agent workflow using Linear as the planning system.

## Setup Complete! ✅

Your Linear workspace is ready:
- **Team:** Agent-Control-Plane (ACP)
- **Project:** MVP 1 — PT App & Agent Pilot
- **3 Issues** created with zone labels
- **10 Zone labels** for routing work

## Test Results

### 1. Bootstrap ✅

Both Python and Node.js versions successfully created:
```
✓ Team 'Agent-Control-Plane' (ID: 5296cff8-9c53-4cb3-9df3-ccb83601805e)
✓ 10 zone labels
✓ Project 'MVP 1 — PT App & Agent Pilot'
✓ 3 issues (ACP-5, ACP-6, ACP-7)
```

### 2. Linear Client CLI ✅

Tested commands:
```bash
# Export markdown ✅
python3 linear_client.py export-md
# Output: Complete plan with all issues

# List issues ✅
python3 linear_client.py list-issues
# Output: All 3 issues with status, labels, URLs
```

### 3. Current Plan

```
# MVP 1 — PT App & Agent Pilot
**Team:** Agent-Control-Plane (ACP)
**Project URL:** https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b

**Progress:** 0.0%

## Issues (3 total)

### Backlog (3)
- **[ACP-7]** Create PT Agent Service Backend Skeleton `zone-3c, zone-12`
- **[ACP-6]** Scaffold iOS SwiftUI App Structure `zone-12`
- **[ACP-5]** Define Supabase Schema for PT App `zone-7, zone-8`
```

## Multi-Agent Workflow Simulation

Here's how different agents would coordinate using this plan:

### Agent 1: Data Layer Specialist (zones 7, 8)

```bash
# Session starts
echo "🤖 Data Layer Agent starting..."

# Auto-sync runs (hook)
# Plan fetched to /tmp/linear_plan_latest.md

# Agent reads plan
cat /tmp/linear_plan_latest.md

# Agent filters by zone labels
# Picks: ACP-5 (Define Supabase Schema for PT App)

# Agent checks out branch
git checkout -b feature/acp-5-supabase-schema

# Agent implements schema
# ... creates schema files ...

# Agent updates Linear
python3 linear_client.py add-comment \
  --issue-id "d8364373-a751-4f79-91b3-65d04d81fd23" \
  --comment "✅ Implemented user authentication schema
- users table with auth metadata
- sessions table for token management
- row-level security policies configured"

# Agent commits with issue reference
git commit -m "ACP-5: Define Supabase schema for PT app

- Created users and sessions tables
- Configured RLS policies
- Added migration scripts"

# Agent marks issue as complete
# (Would use linear_update_status with state ID)
```

### Agent 2: Mobile Specialist (zone 12)

```bash
# Session starts
echo "🤖 Mobile Agent starting..."

# Auto-sync runs
# Reads plan from /tmp/linear_plan_latest.md

# Filters by zone-12 labels
# Picks: ACP-6 (Scaffold iOS SwiftUI App Structure)

# Checks out branch
git checkout -b feature/acp-6-ios-scaffold

# Implements iOS app scaffold
# ... creates SwiftUI project structure ...

# Updates Linear
python3 linear_client.py add-comment \
  --issue-id "a80b2a4a-a084-4518-abbb-845b77bedbdf" \
  --comment "✅ iOS app structure created
- SwiftUI project scaffolding
- Navigation hierarchy
- Basic view components
- MVVM architecture setup"

# Commits
git commit -m "ACP-6: Scaffold iOS SwiftUI app structure

- Created Xcode project
- Set up navigation
- Implemented MVVM pattern"
```

### Agent 3: Backend Specialist (zone 3c)

```bash
# Session starts
echo "🤖 Backend Agent starting..."

# Auto-sync runs
# Reads Linear plan

# Filters by zone-3c labels
# Picks: ACP-7 (Create PT Agent Service Backend Skeleton)

# Checks out branch
git checkout -b feature/acp-7-backend-skeleton

# Implements backend service
# ... creates FastAPI/Express service ...

# Updates Linear
python3 linear_client.py add-comment \
  --issue-id "70f61ba3-bea6-487a-8977-d54d73f4d3b6" \
  --comment "✅ Backend service skeleton complete
- FastAPI project structure
- Health check endpoints
- Database connection pool
- Configuration management
- Docker setup"

# Commits
git commit -m "ACP-7: Create PT agent service backend skeleton

- FastAPI project with async support
- Database models and migrations
- Docker containerization"
```

## Coordination Benefits

### Problem: Lost Context ❌
**Before Linear:**
```
Agent: "What was I supposed to work on?"
User: "Check the plan doc"
Agent: "I don't see it in context anymore..."
User: *has to re-explain entire plan*
```

**With Linear:** ✅
```
Agent: /sync-linear
Linear: *fetches current plan*
Agent: "I see 3 issues. I'll work on ACP-5 (zone-7, zone-8 match my specialty)"
```

### Problem: Agent Conflicts ❌
**Before:**
```
Agent 1: "I'm working on the schema"
Agent 2: "I'm also working on the schema"
Result: Duplicate work, merge conflicts
```

**With Linear:** ✅
```
Agent 1: Checks Linear → Picks ACP-5 → Updates status to "In Progress"
Agent 2: Checks Linear → Sees ACP-5 in progress → Picks ACP-6 instead
Result: Parallel work, no conflicts
```

### Problem: Lost Progress ❌
**Before:**
```
Session 1: Agent does work
Session 2: New agent has no idea what was done
User: *has to explain progress manually*
```

**With Linear:** ✅
```
Session 1: Agent updates Linear with comments
Session 2: New agent reads Linear → sees progress comments → continues where left off
```

## Real-World Usage

### Morning Workflow
```bash
# User reviews Linear in web UI
# Prioritizes issues, adds descriptions
# Labels issues with zones

# Claude session starts
claude

# Hook auto-runs
# Plan synced to /tmp/linear_plan_latest.md

# Claude reads plan
Read /tmp/linear_plan_latest.md

# Claude picks issue based on labels
# Creates branch, implements, updates Linear
# Commits with issue reference
```

### Multi-Session Work
```bash
# Session 1 (morning)
Agent: "Working on ACP-5..."
Agent: *adds Linear comment* "Implemented auth schema"

# Session 2 (afternoon, different agent)
Agent: /sync-linear
Agent: "I see ACP-5 has auth schema done"
Agent: "I'll work on ACP-6 iOS app now"
Agent: *implements iOS*
Agent: *updates Linear*

# Session 3 (evening)
Agent: /sync-linear
Agent: "ACP-5 and ACP-6 are in progress"
Agent: "I'll start ACP-7 backend service"
```

### Human Approval Workflow
```bash
# Human creates issue in Linear
Issue: "Add push notifications"
Labels: zone-3c, zone-12
Status: Backlog

# Agent syncs
Agent: /sync-linear
Agent: "New issue detected: Add push notifications"
Agent: "Should I start work on this?"
User: "Yes, go ahead"
Agent: *updates status to In Progress*
Agent: *implements feature*
Agent: *adds progress comments*
Agent: *marks complete when done*

# Human reviews in Linear
# Approves or requests changes
```

## Key Advantages

1. **Persistent State**
   - Plan survives conversation resets
   - No context loss between sessions

2. **Single Source of Truth**
   - All agents query same Linear project
   - Always have latest status

3. **Human-in-the-Loop**
   - Review progress in Linear UI
   - Approve/reject/modify plan
   - Add comments and feedback

4. **Multi-Agent Coordination**
   - Different agents, different issues
   - No duplicate work
   - Clear ownership via status

5. **Audit Trail**
   - Complete history in Linear
   - See who did what and when
   - Link commits to issues

6. **Progress Tracking**
   - Visual progress in Linear UI
   - Status updates in real-time
   - Easy to see what's blocked

## Next Steps

1. ✅ Bootstrap complete
2. ✅ CLI tested
3. 📝 Configure MCP server (optional)
4. 📝 Enable auto-sync hook (optional)
5. 🚀 Start building!

Try it yourself:
```bash
# Export current plan
python3 linear_client.py export-md

# Or save to file
python3 linear_client.py export-md --output my_plan.md

# List issues
python3 linear_client.py list-issues
```

## Resources

- Linear Project: https://linear.app/bb-pt/project/mvp-1-pt-app-and-agent-pilot-d86e35fb091b
- Issue ACP-5: https://linear.app/bb-pt/issue/ACP-5
- Issue ACP-6: https://linear.app/bb-pt/issue/ACP-6
- Issue ACP-7: https://linear.app/bb-pt/issue/ACP-7

**Full documentation:** [INTEGRATION_GUIDE.md](INTEGRATION_GUIDE.md)
